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
__jbcc_sources_directory_path="${__jbcc_root_dir}/source"

if [ ! -e ${__jbcc_source_json_path} ]; then
  echo "not found json command source at: ${__jbcc_source_json_path}"
  return
fi
# ================================================ #

local sources_from_dir=`ls ${__jbcc_root_dir}/commands/*.json | tr '\n' ' '`
local sources_from_config=`jq -r ".sources[]" ${__jbcc_root_dir}/config.json | tr '\n' ' '`
eval "local source_json_files=(${sources_from_dir} ${sources_from_config})"
for source_json in "${source_json_files[@]}"
do
  echo "source is [${source_json}]"
  local basename=$(basename "${source_json}" .json)
  local temp_filename="${__jbcc_root_dir}/jbcc_${basename}.sh"
  sed "s/%__jbcc_function_name%/${basename}/g" ~/code/JsonBasedCommandCompletion/jbcc.sh | sed "s#%__jbcc_source_json_path%#${source_json}#g" > ${temp_filename}
  source ${temp_filename}
done

# =============== option (load extensions) =======================
# loads __jbcc_store: a simple jq wrapper command
source "${__jbcc_root_dir}/extension/store_extension.sh"
# ==============================================================