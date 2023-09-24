#!/bin/bash
source_json_path="$1"
raw_static_path="$2"
shift 2
args=("$@")

get_static_path() {
    local static_path="."
    for arg in "${args[@]}"; do
        case "$arg" in
            "--add" | "--remove" | "--list" | "--copy")
                break
                ;;
            *)
                static_path+=".\"$arg\""
                ;;
        esac
    done
    echo "$static_path" | sed 's/\.\./\./g'
}

handle_add() {
    local new_command_escaped=$(printf "\"%s\"" "$(echo $1 | sed 's/"/\\"/g')")
    local target_path=${2}
    [ "$target_path" == "." ] && target_path=""
    local result=$(jq "${target_path}.__exec = ${new_command_escaped}" "$source_json_path")
    echo -E "$result" > "$source_json_path"
}

handle_remove() {
    local path="$1"
    local result=$(jq "del(${path})" "$source_json_path")
    while [[ -n "$path" && "`echo $result | jq ${path}`" == "{}" ]]; do
        result=$(jq "del(${path})" "$source_json_path")
        path=$(echo "$path" | sed 's/\.[^\.]*"$//')
    done
    echo -E "$result" > "$source_json_path"
}

handle_list() {
    local list_prefix=$(echo "$raw_static_path" | sed 's/ --list//')
    echo "all executable subcommands at [$list_prefix]"
    jq "$1" "$source_json_path" | jq 'path(..) as $p | select(getpath($p)? | objects? and has("__exec")) | {($p | join(".")): (getpath($p).__exec)}' | jq -s 'add'
}

handle_copy() {
    local result=$(jq -r "$1"."__exec" "$source_json_path")
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # MacOS
        echo "$result" | pbcopy
    elif [[ "$OSTYPE" == "linux-gnu"* && -e /proc/version ]] && grep -iq microsoft /proc/version; then
        # WSL2
        echo "$result" | clip.exe
    else
        # UNIX系
        echo "$result" | xclip -selection clipboard
    fi
    echo "Copied to clipboard! [$result]"
}

main() {
    local static_path=$(get_static_path)
    local operation=""
    local new_command_value=""

    for (( i=0; i<${#args[@]}; i++ )); do
        case "${args[$i]}" in
            "--add")
                operation="add"
                new_command_value="${args[$((i+1))]}"
                ;;
            "--remove")
                operation="remove"
                ;;
            "--list")
                operation="list"
                ;;
            "--copy")
                operation="copy"
                ;;
        esac
    done

    case "$operation" in
        "add")
            handle_add "$new_command_value" "$static_path"
            ;;
        "remove")
            handle_remove "$static_path"
            ;;
        "list")
            handle_list "$static_path"
            ;;
        "copy")
            handle_copy "$static_path"
            ;;
        *)
            echo "JACT Error: no path is defined at [${raw_static_path}] in $source_json_path"
            ;;
    esac
}

main