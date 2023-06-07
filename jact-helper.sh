source_json_path=$1
shift

args=("$@")
static_path="."
new_command=""
is_remove=0
for (( i=0; i<=$#; i++ ));
do
    arg=${args[$i]}
    if [ "$arg" = "--add" ]; then
        ((i++))
        new_command=${args[$i]}
        break
    elif [ "$arg" = "--remove" ]; then
        is_remove=1
        break
    fi
    static_path+=".\"$arg\""
done
static_path=`echo $static_path | sed 's/\.\./\./g'`

if [[ -n ${new_command} ]]; then
    new_command=$(printf "\"%s\"" "$(echo ${new_command} | sed 's/"/\\"/g')")
    result=`jq "${static_path}.__exec = ${new_command}" ${source_json_path}`
    if [[ -n $result ]]; then
    echo -E $result > $source_json_path
    fi
elif [ $is_remove = 1 ]; then
    result=`jq "del(${static_path})" ${source_json_path}`
    static_path=`echo ${static_path} | sed 's/\.[^\.]*"$//'`
    while [ -n "$static_path" ] && [ "`echo $result | jq ${static_path}`" = "{}" ]
    do
        result=`jq "del(${static_path})" ${source_json_path}`
        static_path=`echo ${static_path} | sed 's/\.[^\.]*"$//'`
    done
    echo -E $result > $source_json_path
else
    echo "JACT Error: no path is defined at [$@] in $source_json_path"
fi