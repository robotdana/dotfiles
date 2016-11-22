export VERTICAL='bikeexchange'

alias jslint='./node_modules/.bin/eslint --quiet --ext .jsx,.js webpack/app webpack/entry webpack/lib webpack/test webpack/vendor'

alias missing_verticals='comm -13 <(printf "%s\n" $VERTICALS | cut -d: -f2 | sort | uniq) <(marketplacer verticals | sort)'

function short_vertical() {
  if (($# == 1)); then
    local vertical=$1
  else
    local vertical=$VERTICAL
  fi
  printf '%s\n' $VERTICALS | grep ":$vertical$" | cut -d: -f1 | head -n 1
}
function long_vertical() {
  printf '%s\n' $VERTICALS | grep "^$1:" | cut -d: -f2 | head -n 1
}

function v(){
  vv $(long_vertical $1)
}

function rtp(){
  PRECOMPILE_WEBPACK=true rt $*
}

function vv() {
  export VERTICAL=$1
}

function vdb() {
  (( $# == 1 )) && v $1
  yes | m database update $VERTICAL
  rake db:migrate index:reindex
}

function update_db() {
  vdb $*
}

function vdbrs() {
  vdb $*
  vrs $*
}

function vrc() {
  (( $# == 1 )) && v $1
  rc
}
function vrs() {
  if (( $# == 1 )); then
    v $1
    vrs
  elif (( $# == 0 )); then
    rfs $(m verticals | awk "/$VERTICAL/{ print NR-1; exit }") $VERTICAL
  else
    local current_dir=$PWD
    for vertical in "$@"
    do
      tab "cd $current_dir && vrs $vertical"
    done
  fi
}
