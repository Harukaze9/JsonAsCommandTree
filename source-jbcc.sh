# ================== special json keys ====================== #
__jbcc_exec_key="__exec"
__jbcc_comp_key="__comp_"
__jbcc_default_key="__default"
# ================================================ #

# =============== load script's paths ==================== #
# Use script's location as the root directory
if [ -n "$BASH_VERSION" ]; then
  __jbcc_root_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd) # for bash
elif [ -n "$ZSH_VERSION" ]; then
  __jbcc_root_dir=$(dirname ${0}) # for zsh
else
  # path retrieval may fail (depending on the shell's specifications)
  __jbcc_root_dir=$(dirname ${0})
fi

__jbcc_log_path="${__jbcc_root_dir}/jbcc.log"
__jbcc_config_path="${__jbcc_root_dir}/config.json"
__jbcc_sources_dir="${__jbcc_root_dir}/source"
__jbcc_generated_dir="${__jbcc_root_dir}/generated"

# ================================================ #

__jbcc_source_each_json_commands() {
  local sources_from_dir=`ls ${__jbcc_root_dir}/commands/*.json | tr '\n' ' '`
  local sources_from_config=`jq -r ".sources[]" ${__jbcc_config_path} | tr '\n' ' '`
  eval "local source_json_files=(${sources_from_dir} ${sources_from_config})"
  find ${__jbcc_generated_dir} -name "*.sh" -type f -delete
  for source_json in "${source_json_files[@]}"
  do
    local basename=$(basename "${source_json}" .json)
    local temp_filename="${__jbcc_generated_dir}/jbcc_${basename}.sh"
    sed -e "s/%__jbcc_function_name%/${basename}/g" -e "s#%__jbcc_source_json_path%#${source_json}#g" ~/code/JsonBasedCommandCompletion/jbcc.sh  > ${temp_filename}
    source ${temp_filename}
  done
}

__jbcc_source_each_json_commands

# =============== extensions (optional) =======================
# loads __jbcc_store: a simple jq wrapper command
source "${__jbcc_root_dir}/extension/store_extension.sh"
# ==============================================================