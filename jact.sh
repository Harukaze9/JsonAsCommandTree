# %__jact_function_name% and %__jact_source_json_path% will be replaced when generating temporary scripts.

# util func to explore json content
_make_path_%__jact_function_name%()
(
  local static_path="." # current key path of source json
  local params=()
  local source_json_path=%__jact_source_json_path%
  for arg in "$@"
  do
    local cand_static_path=`echo ${static_path}.\"${arg}\"  | sed "s/\.\././g"`
    echo "cand static path is ${cand_static_path}, arg is ${arg}"  | ${__jact_logger_path}
    if [ $arg = "--add" ] || [ $arg = "--remove" ] || [ $arg = "--list" ] || [ $arg = "--copy" ]; then
      params+="\'${arg}\' "
      echo $source_json_path $static_path "Operation" $params
      return 0;
    elif [[ -n `jq "try(${cand_static_path}) | select(type==\"string\")" ${source_json_path}` ]]; then
      source_json_path=`jq -r ${cand_static_path} ${source_json_path}`
      
      if [[ "${source_json_path:0:1}" != "/"  && "${source_json_path:0:1}" != "~" ]]; then
        local rpath="."
        if [ -L "%__jact_source_json_path%" ]; then
          rpath=`dirname $(readlink %__jact_source_json_path%)`
        else
          rpath=`dirname %__jact_source_json_path%`
        fi
        source_json_path="${rpath}/$source_json_path"
      fi

      source_json_path=`echo $source_json_path | sed "s|^~/|$HOME/|g"`
      static_path="."
    elif [[ `jq "try(${static_path}) | has(\"${arg}\")" ${source_json_path}` == "true" ]]; then
      static_path=${cand_static_path}
      echo "static path is ${static_path}" | ${__jact_logger_path}
    elif [[ `jq "try(${static_path}) | has(\"__exec\")" ${source_json_path}` == "true" ]]; then
      params+="\'${arg}\' "
      echo "params is ${params}" | ${__jact_logger_path}
    else
      echo "else... ${arg}" | ${__jact_logger_path}
      echo $source_json_path
      return 0;
    fi
  done

  echo $source_json_path $static_path "Regular" $params
)

_get_command_by_arguments_%__jact_function_name%() {
  local args=("$@")

  command_keys=(
    "${__jact_exec_key}"
    "${__jact_exec_key}2"
    "${__jact_exec_key}3"
    )

  for command_key in $command_keys; do
    local jq_filter=`echo ${static_path}.${command_key} | sed "s/\.\././g"`
    local command_body=`jq -r ${jq_filter} ${source_json_path}`
    if [[ $command_body != "null" ]]; then
      local index=0
      while [[ "$command_body" == *"{${index}}"* ]]; do
        ((index++))
      done

      if [[ "$index" -eq "$#" ]]; then
      # replace {N} tag
      local count=0
      for element in "${args[@]}"; do
        arg=`echo $element | sed "s/'//g"`
        command_body=`echo $command_body | sed "s#{${count}}#${arg}#g"` # use '#' as a sed seperator.
        ((count++))
      done
      echo "command body is... " $command_body | ${__jact_logger_path}
      echo $command_body
      return;
      fi
    fi
    echo "command key is ${command_key} and index is ${index}" | ${__jact_logger_path}
  done

  echo "null"
}

# main func
%__jact_function_name%() {
  echo "jact original input is $@" | ${__jact_logger_path}
  local static_path params source_json_path command_type hoge
  read source_json_path static_path command_type params <<< $(_make_path_%__jact_function_name% "$@")
  eval "param_array=($params)" # create array by single quoted words

  local raw_static_path="%__jact_function_name% ${@:1:$#-${#param_array[@]}}" # space separated static path to display in CLI text

  # Perform special operations (--add, --remove, --list) or display error if static_path is not found.
  if [[ $command_type != "Regular" ]]; then
    bash ${__jact_root_dir}/jact-helper.sh "$source_json_path" "$raw_static_path" "$@"
    return 1;
  fi

  local command_body=`_get_command_by_arguments_%__jact_function_name% $param_array`

  echo "returned value is ${command_body}" | ${__jact_logger_path}

  if [[ $command_body == "null" ]]; then
    local jq_filter=`echo ${static_path}.${__jact_exec_key} | sed "s/\.\././g"`
    local command_body=`jq -r ${jq_filter} ${source_json_path}`
    if [[ $command_body != "null" ]]; then
      echo "JACT Error: arguments number is invalid for [${raw_static_path}]\nexecution command format is: \"`jq -r ${jq_filter} ${source_json_path}`\""
    else
      echo "JACT Error: No command defined for execution: [${raw_static_path}]"
      local sub_commands=`jq -r "${static_path} | keys[]" ${source_json_path} | grep -v "^_" | sed 's/^/\t/'`
      if [[ -n $sub_commands ]]; then
        echo "However [${raw_static_path}] contains `echo {$sub_commands} | wc -l` subcommands. (Use '--list' for details.) \n${sub_commands}"
      fi
    fi
    return 1
  fi

  # replace {SELF} tag
  if [[ $command_body =~ "\{SELF\}" ]]; then
    local command_basename=`basename %__jact_source_json_path% .json`
    command_body=`echo $command_body | sed "s#{SELF}#${command_basename}#g"` # use '#' as a sed seperator.
  fi

  eval ${command_body}
}

# completion func
__completion_%__jact_function_name%()
{
  COMPREPLY=()

  is_given_option=0
  if [[ "${COMP_WORDS[COMP_CWORD]}" == -* ]]; then
    is_given_option=1
  fi

  local static_path params source_json_path command_type
  read source_json_path static_path command_type params <<< $(_make_path_%__jact_function_name% ${COMP_WORDS[@]:1:(COMP_CWORD-1)})
  params=`echo "$params" | tr '.' ' ' | xargs`

  # echo "(completion) params are $params" | ${__jact_logger_path}
  # echo "(completion) original values are ${COMP_WORDS[@]:1:(COMP_CWORD-1)}" | ${__jact_logger_path}
  # echo "(completion) last word is ${COMP_WORDS[COMP_CWORD]}" | ${__jact_logger_path}
  # echo "(completion) static path is ${static_path}"  | ${__jact_logger_path}

  # if the path does not exist
  if [[ -z "${static_path}" ]]; then
    if [[ $is_given_option -eq 1 ]]; then
    COMPREPLY+=("--add")
    fi
    return;
  fi

  local root_jq_result=`jq -r "try (${static_path} | keys[] | @sh)" ${source_json_path}`
  local trimed_jq_result=`echo $root_jq_result | sed -E "s/'_[^ ]*//g"` # filter out words start from _

  local completion_list
  if [[ -n "${trimed_jq_result// }" ]]; then
    # case 1. if subcommands are defined
    completion_list=${trimed_jq_result}
  elif [[ ${root_jq_result[@]} =~ "__exec" ]]; then
    local param_num=`echo ${params} | wc -w | sed 's/ //g'`
    local comp_command="${__jact_comp_key}${param_num}"
    local jq_filter=`echo ${static_path}.${comp_command} | sed "s/\.\././g"` # remove duplicated .
    exec_command=`jq -r "try (${jq_filter})" ${source_json_path}`
    # echo "(completion) exec_command is ${exec_command}" | ${__jact_logger_path}
    
    if [[ ${exec_command} != "null" ]]; then
      # case2. if completion command is defined...
      # "${exec_command} is executed as a completion command" | ${__jact_logger_path}
      completion_list=`eval ${exec_command}`
    else
      # case3. if completion command is not defined
      # emulates default completion of shell
      local cur="${COMP_WORDS[COMP_CWORD]}"
      for comp in $(compgen -f -- "$cur"); do
          if [ -d "$comp" ]; then
              comp="$comp/"
          fi
          COMPREPLY+=("$comp")
      done
      if [[ $is_given_option -eq 1 ]]; then
        COMPREPLY+=("--copy")
        COMPREPLY+=("--remove")
      fi
      if [ ${#COMPREPLY[@]} -eq 1 ] && [ "${COMPREPLY[0]%/}" != "${COMPREPLY[0]}" ]; then
          # Remove space after completion of a directory. No apparent way to make it compatible between bash and zsh.
          if [ -n "$BASH_VERSION" ]; then
              compopt -o nospace
          elif [[ -n "${ZSH_VERSION}" ]]; then
              COMPREPLY=`bash -c "compgen -f -- ${COMPREPLY[0]}"`
          fi
      fi
      return
    fi
  fi

  if [[ $is_given_option -eq 1 ]]; then
    completion_list="$completion_list --list"
  fi

  COMPREPLY=( `compgen -W "${completion_list}" -- ${COMP_WORDS[COMP_CWORD]}` );
}

# bind completion function
complete -F __completion_%__jact_function_name% %__jact_function_name%