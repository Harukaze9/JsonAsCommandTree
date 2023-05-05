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

count=0
for source_json in `jq -r ".sources[]" ${__jbcc_root_dir}/config.json`
do
  echo "source ${source_json}"
  __jbcc_source_json_path=$source_json
  # cat ${__jbcc_root_dir}/jbcc.sh | sed 
  # source ${__jbcc_root_dir}/jbcc.sh
  local basename=$(basename "${__jbcc_source_json_path}" .json)
  local temp_filename="${__jbcc_root_dir}/jbcc_${basename}.sh"
  # sed "s/%__jbcc_function_name%/${basename}/g" ~/code/JsonBasedCommandCompletion/jbcc.sh > ${temp_filename}
  # sed "s/%__jbcc_source_json_path%/${basename}/g" ~/code/JsonBasedCommandCompletion/jbcc.sh > ${temp_filename}
  sed "s/%__jbcc_function_name%/${basename}/g" ~/code/JsonBasedCommandCompletion/jbcc.sh | sed "s#%__jbcc_source_json_path%#${__jbcc_source_json_path}#g" > ${temp_filename}
  # sed "s/%__jbcc_source_json_path%/${__jbcc_source_json_path}/g"  ~/code/JsonBasedCommandCompletion/jbcc.sh > ${temp_filename}
  # sed "s/%__jbcc_function_name%/${basename}/g" ~/code/JsonBasedCommandCompletion/jbcc.sh | sed "s/%__jbcc_source_json_path%/${__jbcc_source_json_path}/g" > ${temp_filename}
  echo "write file to ${temp_filename}"
  source ${temp_filename}
done

# =============== option (load extensions) =======================

# loads __jbcc_store: a simple jq wrapper command
source "${__jbcc_root_dir}/extension/store_extension.sh"

# loads cdd: super useful short facade command of 'jj goto xxx'
source "${__jbcc_root_dir}/extension/cdd_extension.sh"

# ==============================================================