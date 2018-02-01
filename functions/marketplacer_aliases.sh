function v(){
  local maybe_vertical=$1
  if [[ ! -z $maybe_vertical ]]; then
    local vertical=$(long_vertical $maybe_vertical)
    if [ -z "$vertical" ]; then
      echoerr "No such vertical"
    elif [[ "$vertical" != "$CURRENT_VERTICAL" ]]; then
      echodo export CURRENT_VERTICAL=$vertical && title Terminal
    fi
  fi
}

function vdl() {
  v $* && echodo "yes | DISABLE_MARKETPLACER_CLI_PRODUCTION_CHECK=1 m database update $CURRENT_VERTICAL" && VERTICAL=$CURRENT_VERTICAL rails_migrate_soft
}

function vdt() {
  rdt
}

function vds() {
  rails_migrate_all_soft
}

function vd() {
  title 'Migrating'
  if (( $# == 1 )); then
    v $1 && echodo "VERTICAL=$CURRENT_VERTICAL bundle exec rails db:migrate"
  else
    rails_migrate_all
  fi
  title
}

function vtl() {
  script/localeapp_pull.sh
}

function vrc() {
  if (( $# == 2 )); then
    v $1 && vertical_remote_console $2
  else
    prepare_app
    v $1 && rc
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
  v $vertical && rs $(vertical_row_number) $(long_vertical | tr _ -) $path
}

function vrt() {
  if [[ "$*" == *"/features/"* ]] || [[ "$*" == *"/controllers/"* ]]; then
    prepare_app_with_webkit
  else
    prepare_app
  fi
  rt $*
}

function vrtn() {
  vrt --next-failure $*
}

function vrtl() {
  local failures=$(buildkite_failures)
  if [[ ! -z "$failures" ]]; then
    rm spec/examples.txt
    vrt $failures
  fi
}
