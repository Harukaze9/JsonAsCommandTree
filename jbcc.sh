# %__jbcc_function_name% and %__jbcc_source_json_path% will be replaced when creating temporary scripts.

# ====================== jbcc core function ============================
# util func to explore json content
_make_path_%__jbcc_function_name%()
(
  local static_path="." # current key path of source json
  local params=()
  local source_json_path=%__jbcc_source_json_path%
  # echo "number of param is..." $#  >> ${__jbcc_log_path}
  # echo "content of param is..." $@  >> ${__jbcc_log_path}
  for arg in "$@"
  do
    # echo $source_json_path $static_path $params >> ${__jbcc_log_path}
    local cand_static_path=`echo ${static_path}.\"${arg}\"  | sed "s/\.\././g"`
    if [[ -n `jq "try(${cand_static_path}) | select(type==\"string\")" ${source_json_path}` ]]; then
      source_json_path=`jq -r ${cand_static_path} ${source_json_path}`
      
      if [[ "${source_json_path:0:1}" != "/"  && "${source_json_path:0:1}" != "~" ]]; then
        local rpath="."
        if [ -L "%__jbcc_source_json_path%" ]; then
          echo "シンボリックリンクのようですね。: linkpath is ${linkpath}" >> ${__jbcc_log_path}
          rpath=`dirname $(readlink %__jbcc_source_json_path%)`
        else
          rpath=`dirname %__jbcc_source_json_path%`
        fi
        # echo "相対パスのようですね。source path is: %__jbcc_source_json_path%" >> ${__jbcc_log_path}
        # local linkpath=`readlink %__jbcc_source_json_path%`
        # echo "相対パスのようですね。: linkpath is ${linkpath}" >> ${__jbcc_log_path}
        # local rpath=`dirname $(readlink %__jbcc_source_json_path%)`
        echo "相対パスのようですね。: rpath is ${rpath}" >> ${__jbcc_log_path}
        source_json_path="${rpath}/$source_json_path"
        echo "相対パスのようですね。: sourcejsonpath is ${source_json_path}" >> ${__jbcc_log_path}
      else
        echo "相対パスではないですね。" >> ${__jbcc_log_path}
      fi

      echo "hello" >> ${__jbcc_log_path}
      source_json_path=`echo $source_json_path | sed "s|^~/|$HOME/|g"`
      # echo "finally source_json_path is" $source_json_path >> ${__jbcc_log_path}
      static_path="."
    elif [[ `jq "try(${static_path}) | has(\"${arg}\")" ${source_json_path}` == "true" ]]; then
      static_path=${cand_static_path} # escape to allow hyphen
    elif [[ `jq "try(${static_path}) | has(\"__exec\")" ${source_json_path}` == "true" ]]; then
      params+="\'${arg}\' "
    else
      # echo "invalid input: static_path: ${static_path}, arg: ${arg}" >> ${__jbcc_log_path}
      return 1;
    fi
  done
  # echo "path is: %__jbcc_source_json_path%" >> ${__jbcc_log_path}

  echo $source_json_path $static_path $params 
)

# main func
%__jbcc_function_name%() {
  local static_path params source_json_path
  # echo "number of param is" $# 
  # read source_json_path static_path params <<< $(_jbcc_make_path $(for i in "$@"; do echo -n "\"$i\" "; done))
  read source_json_path static_path params <<< $(_make_path_%__jbcc_function_name% "$@")
  if [[ -z $source_json_path ]]; then
    echo "JBCC Error: no path is defined at [$@] in \"%__jbcc_source_json_path%\""
    return 1;
  fi

  local jq_filter=`echo ${static_path}.${__jbcc_exec_key} | sed "s/\.\././g"`
  local command_body=`jq -r ${jq_filter} ${source_json_path}`

  if [[ $command_body =~ "null" ]]; then
    echo "JBCC Error: no execution command is defined at: [${static_path}]"
    return 1
  fi

  local count=0
  eval "param_array=($params)" # create array by single quoted words
  # echo "param is ${params} and param_array is: ${param_array[@]} and array size is ${#param_array[@]}"

  # replace {N} tag
  for element in "${param_array[@]}"; do
    arg=`echo $element | sed "s/'//g"`
    # echo "try to set: [${arg}] to [${command_body}]"
    command_body=`echo $command_body | sed "s#{${count}}#${arg}#g"` # use '#' as a sed seperator.
    ((count++))
  done

  # replace {SELF} tag
  if [[ $command_body =~ "\{SELF\}" ]]; then
    local command_basename=`basename %__jbcc_source_json_path% .json`
    command_body=`echo $command_body | sed "s#{SELF}#${command_basename}#g"` # use '#' as a sed seperator.
  fi

  # if arguments are not enough
  if [[ $command_body =~ "\{[0-9]\}" ]]; then
    # check default command
    local default_jq_filter=`echo ${static_path}.${__jbcc_default_key} | sed "s/\.\././g"`
    command_body=`jq -r "try(${default_jq_filter})" ${source_json_path}`

    # show error if default command is not exist
    if [[ $command_body =~ "null" ]]; then
      echo "JBCC Error: arguments are not enough" # TODO: more friendly message
      return 1;
    fi
  fi

  # echo "command body is:" ${command_body}
  # echo "params is: ${params}"
  # return
  # local exec_command=$(bash -c "printf \"${command_body}\" ${params}") # works well but cannot exec jj command...
  # local exec_command=`printf ${command_body} ${params}` # also works well...??
  # echo "exec commanad is: ${exec_command}"
  eval ${command_body}
}

# completion func
__completion_%__jbcc_function_name%()
{
  COMPREPLY=()

  local static_path params source_json_path
  read source_json_path static_path params <<< $(_make_path_%__jbcc_function_name% ${COMP_WORDS[@]:1:(COMP_CWORD-1)})
  params=`echo "$params" | tr '.' ' ' | xargs`

  local root_jq_result=`jq -r "try (${static_path} | keys[] | @sh)" ${source_json_path}`
  local trimed_jq_result=`echo $root_jq_result | sed -E "s/'_[^ ]*//g"` # filter out words start from _

  local completion_list
  if [[ -n "${trimed_jq_result// }" ]]; then
    completion_list=${trimed_jq_result}
  elif [[ ${root_jq_result[@]} =~ "__exec" ]]; then
    echo "params  is" ${params} >> ${__jbcc_log_path}
    local param_num=`echo ${params} | wc -w | sed 's/ //g'`
    local comp_command="${__jbcc_comp_key}${param_num}"
    local jq_filter=`echo ${static_path}.${comp_command} | sed "s/\.\././g"` # remvoe duplicated .
    exec_command=`jq -r "try (${jq_filter})" ${source_json_path}`
    echo "query: " "jq -r \"try (${jq_filter})\" ${source_json_path}" >> ${__jbcc_log_path}
    echo "exec_command: " ${exec_command} >> ${__jbcc_log_path}
    if [[ ${exec_command} != "null" ]]; then
      completion_list=`eval ${exec_command}`
    fi
  fi

  COMPREPLY=( `compgen -W "${completion_list}" -- ${COMP_WORDS[COMP_CWORD]}` );
}

# bind completion function
complete -F __completion_%__jbcc_function_name% %__jbcc_function_name%
# echo "complete -F __completion_%__jbcc_function_name% %__jbcc_function_name%...."

# =======================================================================