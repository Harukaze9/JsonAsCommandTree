# ================== config ====================== #
__jbcc_exec_key="\"__exec\""
__jbcc_comp_key="__comp_"
__jbcc_function_name="jj"
# ================================================ #

# =============== load file paths ==================== #
# Use script's location as the root directory
if [ -n "$BASH_VERSION" ]; then
  __jbcc_root_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd) # for bash
elif [ -n "$ZSH_VERSION" ]; then # for zsh
  __jbcc_root_dir=$(dirname ${0})
else
  # path retrieval may fail (depending on the shell's specifications)
  __jbcc_root_dir=$(dirname ${0})
fi

__jbcc_log_path="${__jbcc_root_dir}/jbcc.log"
__jbcc_source_json_path="${__jbcc_root_dir}/command.json" # json file that defines commands and corresponding completions
__jbcc_sources_directory_path="${__jbcc_root_dir}/source"

if [ ! -e ${__jbcc_source_json_path} ]; then
  echo "not found json command source at: ${__jbcc_source_json_path}"
  return
fi
# ================================================ #

# ====================== jbcc core function ============================
# util func to explore json content
_jbcc_make_path()
(
  local static_path=".root" # current key path of source json
  local params=()
  local source_json_path=${__jbcc_source_json_path}
  # echo "number of param is..." $#  >> ${__jbcc_log_path}
  # echo "content of param is..." $@  >> ${__jbcc_log_path}
  for arg in "$@"
  do
    # echo $source_json_path $static_path $params >> ${__jbcc_log_path}
    if [[ -n `jq "try(${static_path}.\"${arg}\") | select(type==\"string\")" ${source_json_path}` ]]; then
      source_json_path=`jq -r "${static_path}.\"${arg}\"" ${source_json_path}`
      # echo "now source_json_path is" $source_json_path >> ${__jbcc_log_path}
      # echo "apply" $__jbcc_sources_directory_path >> ${__jbcc_log_path}
      source_json_path=`echo $source_json_path | sed -e "s#__JBCC_SOURCE_DIR__#${__jbcc_sources_directory_path}#g" -e "s|^~/|$HOME/|g"`
      # echo "finally source_json_path is" $source_json_path >> ${__jbcc_log_path}
      static_path=".root"
    elif [[ `jq "try(${static_path}) | has(\"${arg}\")" ${source_json_path}` == "true" ]]; then
      static_path+=.\"${arg}\" # escape to allow hyphen
    elif [[ `jq "try(${static_path}) | has(\"__exec\")" ${source_json_path}` == "true" ]]; then
      params+="\'${arg}\' "
    else
      # echo "invalid input: static_path: ${static_path}, arg: ${arg}" >> ${__jbcc_log_path}
      return 1;
    fi
  done

  echo $source_json_path $static_path $params 
)

# main func
hoge() {
  local static_path params source_json_path
  # echo "number of param is" $# 
  # read source_json_path static_path params <<< $(_jbcc_make_path $(for i in "$@"; do echo -n "\"$i\" "; done))
  read source_json_path static_path params <<< $(_jbcc_make_path "$@")
  if [[ -z $source_json_path ]]; then
    echo "Error: no path is defined at [$@] in \"${__jbcc_source_json_path}\""
    return 1;
  fi

  local command_body=`jq -r ${static_path}.${__jbcc_exec_key} ${source_json_path}`
  local count=0
  eval "param_array=($params)" # create array by single quoted words
  # echo "param is ${params} and param_array is: ${param_array[@]} and array size is ${#param_array[@]}"
  for element in "${param_array[@]}"; do
    arg=`echo $element | sed "s/'//g"`
    # echo "try to set: [${arg}] to [${command_body}]"
    command_body=`echo $command_body | sed "s#{${count}}#${arg}#g"` # use '#' as a sed seperator.
    ((count++))
  done

  if [[ $command_body =~ "\{[0-9]\}" ]]; then
    echo "Error: arguments are not enough" # TODO: more friendly message
    return 1;
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
_jbcc_completions()
{
  COMPREPLY=()

  local static_path params source_json_path
  read source_json_path static_path params <<< $(_jbcc_make_path ${COMP_WORDS[@]:1:(COMP_CWORD-1)})
  params=`echo "$params" | tr '.' ' ' | xargs`

  local root_jq_result=`jq -r "try (${static_path} | keys[] | @sh)" ${source_json_path}`
  local trimed_jq_result=`echo $root_jq_result | sed -E "s/'__[^ ]*//g"`

  local completion_list
  if [[ -n "${trimed_jq_result// }" ]]; then
    completion_list=${trimed_jq_result}
  elif [[ ${root_jq_result[@]} =~ "__exec" ]]; then
    # echo "params  is" ${params} >> ${__jbcc_log_path}
    local param_num=`echo ${params} | wc -w | sed 's/ //g'`
    local comp_command="${__jbcc_comp_key}${param_num}"
    exec_command=`jq -r "try (${static_path}.${comp_command})" ${source_json_path}`
    # echo "query: " "jq -r \"try (${static_path}.${comp_command})\" ${source_json_path}" >> ${__jbcc_log_path}
    # echo "exec_command: " ${exec_command} >> ${__jbcc_log_path}
    if [[ ${exec_command} != "null" ]]; then
      completion_list=`eval ${exec_command}`
    fi
  fi

  COMPREPLY=( `compgen -W "${completion_list}" -- ${COMP_WORDS[COMP_CWORD]}` );
}

# bind completion function
complete -F _jbcc_completions hoge

# =======================================================================

# =============== option (load extensions) =======================

# loads __jbcc_store: a simple jq wrapper command
source "${__jbcc_root_dir}/extension/store_extension.sh"

# loads cdd: super useful short facade command of 'jj goto xxx'
source "${__jbcc_root_dir}/extension/cdd_extension.sh"

# ==============================================================
