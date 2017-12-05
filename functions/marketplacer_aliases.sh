function v(){
  local maybe_vertical=$1
  if [[ ! -z $maybe_vertical ]]; then
    local vertical=$(long_vertical $maybe_vertical)
    if [ -z "$vertical" ]; then
      echoerr "No such vertical"
    elif [[ "$vertical" != "$MVERTICAL" ]]; then
      echodo export MVERTICAL=$vertical && title Terminal
    fi
  fi
}

function vdl() {
  v $* && echodo "yes | DISABLE_MARKETPLACER_CLI_PRODUCTION_CHECK=1 m database update $MVERTICAL" && VERTICAL=$MVERTICAL rds
}

function vtl() {
  script/localeapp_pull.sh
}

function vrc() {
  if (( $# == 2 )); then
    v $1 && vertical_remote_console $2
  else
    v $1 && VERTICAL=$MVERTICAL rc
  fi
}

function vrs() {
  local path="$2"
  local vertical_or_path="$1"

  if [[ -z "$path" ]]; then
    if [[ "$vertical_or_path" =~ ^/.* ]]; then
      local path="$vertical_or_path"
      local vertical=""
    else
      local path="/"
      local vertical=$vertical_or_path
    fi
  fi
  prepare_app_with_webkit
  v $vertical && VERTICAL=$MVERTICAL rs $(vertical_row_number) $(long_vertical | tr _ -) $path
}

function vrt() {
  if [[ "$*" == *"/features/"* ]]; then
    prepare_app_with_webkit
  else
    prepare_app
  fi
  rt $*
}
