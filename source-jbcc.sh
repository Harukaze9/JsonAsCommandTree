# ================== special json keys ====================== #
__jbcc_exec_key="__exec"
__jbcc_comp_key="__"
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
__jbcc_generated_dir="${__jbcc_root_dir}/generated"
__jbcc_source_dir="${__jbcc_root_dir}/source"

# ================================================ #


# ============  load commands from json ========================== #
__jbcc_source_each_json_commands() {
  find ${__jbcc_generated_dir} -name "*.sh" -type f -delete
  for source_json in `find "${__jbcc_source_dir}" \( -type f -o -type l \) -maxdepth 1 -name "*.json" `
  do
    local basename=$(basename "${source_json}" .json)
    local temp_filename="${__jbcc_generated_dir}/jbcc_${basename}.sh"
    sed -e "s/%__jbcc_function_name%/${basename}/g" -e "s#%__jbcc_source_json_path%#${source_json}#g" ~/code/JsonBasedCommandCompletion/jbcc.sh  > ${temp_filename}
    source ${temp_filename}
  done
}

__jbcc_source_each_json_commands

# =============== source scripts =======================
for source_script in `find "${__jbcc_source_dir}/" \( -type f -o -type l \) -maxdepth 1 -name "*.sh" `
do
source "${source_script}"
done
# ==============================================================