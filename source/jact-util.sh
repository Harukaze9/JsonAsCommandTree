__jact_util()
{
    local OPTIND
    while getopts "o:a:" option; do
    case $option in
        o)
        local arg_operation="$OPTARG"
        ;;
        a)
        local arg_a="$OPTARG"
        ;;
        *)
        echo "Invalid options specified. only [o] is acceptable"
        return 1
        ;;
    esac
    done

    # Check if $arg_operation is defined
    if [ -z "$arg_operation" ]; then
        echo "Error: arg_operation is not defined."
        return 1
    fi

    # Check if jact command is defined
    if ! command -v jact &> /dev/null; then
        echo "Error: jact command is not found."
        return 1
    fi

    case $arg_operation in
        install)
        ln -s $(realpath ${arg_a}) ${__jact_source_dir}
        __jact_util -o post-install -a ${arg_a}
        ;;
        package-install)
        local url=`jq -r ".\"${arg_a}\"" ${__jact_packages_dir}/manifest.json`
        local file_name=${__jact_source_dir}/`basename $url`;
        curl -o $file_name $url
        __jact_util -o post-install -a ${file_name}
        
        ;;
        post-install)
        source ${__jact_root_dir}/source-jact.sh
        __jact_util -o exec-oninstall-command -a $arg_a
        echo "[${arg_a}]" is installed!
        jact list
        ;;
        exec-oninstall-command)
        if [[ ${arg_a} =~ ".json" ]]; then
            r=`jq -r ".__on_install" ${arg_a}`
            if [[ $r != null ]]; then
                eval $r
                echo "finished runnning on-install command: $r"
            fi
        fi
        ;;
        *)
        echo "No implementation for operation ${arg_operation}"
        return 1
        ;;
    esac
}