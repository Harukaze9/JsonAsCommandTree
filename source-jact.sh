# ================== special json keys ====================== #
__jact_exec_key="__exec"
__jact_comp_key="__"
__jact_default_key="__default"
# ================================================ #

# =============== load script's paths ==================== #
# Use script's location as the root directory
if [ -n "$BASH_VERSION" ]; then
  __jact_root_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd) # for bash
elif [ -n "$ZSH_VERSION" ]; then
  __jact_root_dir=$(dirname ${0}) # for zsh
else
  # path retrieval may fail (depending on the shell's specifications)
  __jact_root_dir=$(dirname ${0})
fi

__jact_log_path="${__jact_root_dir}/jact.log"
__jact_config_path="${__jact_root_dir}/config.json"
__jact_generated_dir="${__jact_root_dir}/generated"
__jact_source_dir="${__jact_root_dir}/source"

# ================================================ #


# ============  load commands from json ========================== #
__jact_source_each_json_commands() {
  find ${__jact_generated_dir} -name "*.sh" -type f -delete
  for source_json in `find "${__jact_source_dir}" -maxdepth 1 \( -type f -o -type l \) -name "*.json" `
  do
    local basename=$(basename "${source_json}" .json)
    local temp_filename="${__jact_generated_dir}/jact_${basename}.sh"
    sed -e "s/%__jact_function_name%/${basename}/g" -e "s#%__jact_source_json_path%#${source_json}#g" ${__jact_root_dir}/jact.sh  > ${temp_filename}
    source ${temp_filename}
  done
}

__jact_source_each_json_commands

# =============== source scripts =======================
for source_script in `find "${__jact_source_dir}" -maxdepth 1 \( -type f -o -type l \) -name "*.sh" `
do
source "${source_script}"
done
# ==============================================================