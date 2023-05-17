__jact_store_show()
{
    local description=$1
    local category=$2

    echo "=====[ $description ]====="
    jq -r ".${category} | to_entries[] | \"\(.key): \(.value)\"" ~/.jact/store.json
    echo "=========================="
}

__jact_store()
{
    local __jact_store_path=~/.jact/store.json
    local OPTIND
    while getopts "c:k:v:o:d:e:" option; do
    case $option in
        c)
        local arg_category="$OPTARG"
        ;;
        k)
        local arg_key="$OPTARG"
        ;;
        v)
        local arg_value="$OPTARG"
        ;;
        o)
        local arg_operation="$OPTARG"
        ;;
        d)
        local arg_description="$OPTARG"
        ;;
        *)
        echo "Invalid options specified. only [c, k, v, o, d] is acceptable"
        return 1
        ;;
    esac
    done

    if [ -z "$arg_category" ]; then
        echo "Error: -c is empty"
        return 1
    fi

    if [ -z "$arg_operation" ]; then
        echo "Error: -o is empty"
        return 1
    fi

    if [ -z "$arg_description" ]; then
        local arg_description=$arg_category
    fi

    # create store.json if not exist
    if ! [[ -f ${__jact_store_path} ]]; then
        echo "store.json is not found. created store.json at: ${__jact_store_path}"
        echo '{}' > ${__jact_store_path}
    fi

    # create category key if not already exist
    if [[ `jq ".${arg_category}" $__jact_store_path` == "null" ]]; then
        local result=`jq ".${arg_category} = {}" $__jact_store_path`
        if [[ -n ${result} ]]; then
            echo -E $result > $__jact_store_path
            echo "successfully added store category: \"${arg_category}\""
        else
            echo "jq error occured";
        fi
    fi

    case $arg_operation in
        add)
        local result=`jq ".${arg_category}.\"${arg_key}\" = \"${arg_value}\"" $__jact_store_path`
        if [[ -n ${result} ]]; then
            echo -E $result > $__jact_store_path
            echo "successfully added: \"${arg_key}\" (${arg_value})"
            __jact_store_show $arg_description $arg_category
        else
            echo "jq error occured";
        fi
        ;;
        remove)
        local result=`jq "del(.${arg_category}.\"${arg_key}\")" $__jact_store_path`
        if [[ -n ${result} ]]; then
            echo -E $result > $__jact_store_path
            echo "successfully removed: \"${arg_key}\""
            __jact_store_show $arg_description $arg_category
        else
            echo "jq error occured";
        fi
        ;;
        list)
        __jact_store_show $arg_description $arg_category
        ;;
        complement)
        echo `jq -r ".${arg_category} | keys[] " ${__jact_store_path} | xargs echo`
        ;;
        get)
        echo `jq -r ".${arg_category}.\"${arg_key}\"" ${__jact_store_path}`
        ;;
        create)
        # create category key if not already exist
        if [[ `jq ".${arg_category}" $__jact_store_path` == "null" ]]; then
            local result=`jq ".${arg_category} = {}" $__jact_store_path`
            if [[ -n ${result} ]]; then
                echo -E $result > $__jact_store_path
                echo "successfully added store category: \"${arg_category}\""
                __jact_store_show $arg_description $arg_category
            else
                echo "jq error occured";
            fi
        fi
        ;;
        *)
        echo "Usage: $0 [-c arg_a] [-b arg_b] [-f]"
        return 1
        ;;
    esac
}
