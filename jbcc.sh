# %__jbcc_function_name% and %__jbcc_source_json_path% will be replaced when generating temporary scripts.

# util func to explore json content
_make_path_%__jbcc_function_name%()
(
  local static_path="." # current key path of source json
  local params=()
  local source_json_path=%__jbcc_source_json_path%
  for arg in "$@"
  do
    local cand_static_path=`echo ${static_path}.\"${arg}\"  | sed "s/\.\././g"`
    if [[ -n `jq "try(${cand_static_path}) | select(type==\"string\")" ${source_json_path}` ]]; then
      source_json_path=`jq -r ${cand_static_path} ${source_json_path}`
      
      if [[ "${source_json_path:0:1}" != "/"  && "${source_json_path:0:1}" != "~" ]]; then
        local rpath="."
        if [ -L "%__jbcc_source_json_path%" ]; then
          rpath=`dirname $(readlink %__jbcc_source_json_path%)`
        else
          rpath=`dirname %__jbcc_source_json_path%`
        fi
        source_json_path="${rpath}/$source_json_path"
      fi

      source_json_path=`echo $source_json_path | sed "s|^~/|$HOME/|g"`
      static_path="."
    elif [[ `jq "try(${static_path}) | has(\"${arg}\")" ${source_json_path}` == "true" ]]; then
      static_path=${cand_static_path}
    elif [[ `jq "try(${static_path}) | has(\"__exec\")" ${source_json_path}` == "true" ]]; then
      params+="\'${arg}\' "
    else
      return 1;
    fi
  done

  echo $source_json_path $static_path $params 
)

# main func
%__jbcc_function_name%() {
  local static_path params source_json_path
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

  # replace {N} tag
  for element in "${param_array[@]}"; do
    arg=`echo $element | sed "s/'//g"`
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
    local param_num=`echo ${params} | wc -w | sed 's/ //g'`
    local comp_command="${__jbcc_comp_key}${param_num}"
    local jq_filter=`echo ${static_path}.${comp_command} | sed "s/\.\././g"` # remvoe duplicated .
    exec_command=`jq -r "try (${jq_filter})" ${source_json_path}`
    if [[ ${exec_command} != "null" ]]; then
      completion_list=`eval ${exec_command}`
    fi
  fi

  COMPREPLY=( `compgen -W "${completion_list}" -- ${COMP_WORDS[COMP_CWORD]}` );
}

# bind completion function
complete -F __completion_%__jbcc_function_name% %__jbcc_function_name%