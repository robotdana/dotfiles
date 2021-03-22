function vrc() {
  prepare_app
  rc
}

function vrs() {
  prepare_app_with_yarn
  rs 0 marketplacer
}

function vrsf() {
  kill_port 3000
  vrs
}

function vrt() {
  if [[ "$*" == *"/features/"* ]]; then
    prepare_app_with_yarn
  else
    prepare_app
  fi
  rt "$@"
  if [[ $* == *"/features/"* ]]; then
    killchrome
  fi
}

function vrtn() {
  vrt --next-failure $(cat .buildkite-failures)
}

function cdm() {
  echodo cd ~/M/placer
}

function cdf() {
  echodo cd ~/M/facer
}

function em {
  echodo code ~/M/placer
}

function ef {
  echodo code ~/M/facer
}

function vrtc {
  local files=$(git_modified_with_line_numbers _spec.rb)
  [[ ! -z $files ]] && vrt $* $files
}

function killchrome {
  pgrep -q Google\ Chrome && echodo killall Google\ Chrome
  pgrep -q chromedriver && echodo killall chromedriver
  echodo docker-compose -f docker-compose.chrome.yml restart
}

function update_graphql {
  cdm && echodo rake 'app:graphql:update_schema['$1']' && echodo ttab 'cdm && rails s'
  cdf && echodo yarn run graphql:schema:update http://marketplacer.lvh.me:3000/graphql && echodo yarn run graphql:types:build
}
