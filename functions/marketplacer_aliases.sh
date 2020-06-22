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
  cd ~/M/marketplacer
}

function em {
  code ~/M/marketplacer
}

function vrtc {
  local files=$(git_modified_with_line_numbers _spec.rb)
  [[ ! -z $files ]] && vrt $* $files
}

function killchrome {
  pgrep -q Google\ Chrome && echodo killall Google\ Chrome
  pgrep -q chromedriver && echodo killall chromedriver
}
