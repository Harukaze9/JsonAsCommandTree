cdd(){
    if [ $# -lt 1 ]; then
        jj goto exec "default"
    elif [ $1 = "list" ]; then
        jj goto list
    else
        jj goto exec $1
    fi
}

_cdd() {
  local _suggest_args
  case $COMP_CWORD in
  1 )
    _suggest_args=$(__jbcc_store -c goto -o complement)
  esac

  COMPREPLY=( `compgen -W "$_suggest_args" -- ${COMP_WORDS[COMP_CWORD]}` );
}

complete -F _cdd cdd