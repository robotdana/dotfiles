function v(){
  local maybe_vertical=$1
  if [[ ! -z $maybe_vertical ]]; then
    local vertical=$(long_vertical "$maybe_vertical")
    if [ -z "$vertical" ]; then
      echoerr "No such vertical"
    elif [[ "$vertical" != "$CURRENT_VERTICAL" ]]; then
      echodo export CURRENT_VERTICAL="$vertical" && title Terminal
    fi
  fi
}

function vdl() {
  v "$@" && ( yes | echodo DISABLE_MARKETPLACER_CLI_PRODUCTION_CHECK=1 m database update $CURRENT_VERTICAL ) && VERTICAL=$CURRENT_VERTICAL rails_migrate_soft
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
    v "$1" && echodo VERTICAL=$CURRENT_VERTICAL bundle exec rails db:migrate
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
    v "$1" && vertical_remote_console "$2"
  else
    prepare_app
    v "$1" && rc
  fi
}

function vrs() {
  local vertical="$1"

  prepare_app_with_webkit
  rs 0 "$(long_vertical "$vertical" | tr _ -)"
}
function vrsf() {
  kill_port 3000
  vrs "$@"
}

function vrt() {
  if [[ "$*" == *"/features/"* ]] || [[ "$*" == *"/controllers/"* ]]; then
    prepare_app_with_webkit
  else
    prepare_app
  fi
  JAVASCRIPT_DRIVER=selenium rt "$@"
}

function vrtn() {
  vrt --next-failure $(cat .buildkite-failures)
}

function vrtl() {
  rm spec/examples.txt
  buildkite_failures
  vrtn
}

function vrts() {
  tail -n +2 .buildkite-failures | tee .buildkite-failures &>/dev/null
  vrt --next-failure
}

function cdm() {
  cd ~/M/marketplacer
}
