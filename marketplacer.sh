export VERTICAL='bikeexchange'

alias jslint='./node_modules/.bin/eslint --quiet --ext .jsx,.js webpack/app webpack/entry webpack/lib webpack/test webpack/vendor'

alias missing_verticals='comm -13 <(verticals | colrm 1 10 | sort | uniq) <(marketplacer verticals | sort)'
alias sverticals="subl -nw ~/.dotfiles/locals/verticals"

function short_vertical() {
  vertical_row $* | colrm 5 | tr -d " "
}
function long_vertical() {
  vertical_row $* | colrm 1 10
}

function vertical_row() {
  if (($# == 1)); then
    local vertical=$1
  else
    local vertical=$VERTICAL
  fi
  verticals | grep -e "^$vertical \| $vertical$" | head -n 1
}

function vertical_server() {
  vertical_row $* | colrm 1 5 | colrm 5
}

function verticals() {
  cat ~/.dotfiles/locals/verticals
}

function v(){
  cd $MARKETPLACER_PATH
  local vertical=$(long_vertical $1)
  if [ -z "$vertical" ]; then
    echo "No such vertical"
  else
    vv $vertical
  fi
  title Terminal
}

function rtp(){
  PRECOMPILE_WEBPACK=true rt $*
}

function vv() {
  echo "••• updated \$VERTICAL to $1 •••"
  export VERTICAL=$1
}

function vdb() {
  (( $# == 1 )) && v $1
  yes | m database update $VERTICAL
}
function vdbi() {
  vdb $*
  rails db:migrate
}

function vdbrs() {
  vdb $*
  vrs $*
}

function vdbrc() {
  vdb $*
  vrc $*
}

function vrc() {
  (( $# > 0 )) && v $1
  if (( $# == 2 )); then
    remote_console $2
  else
    rc
  fi
}

function remote_console() {
  if [ "$1" = "prod" ]; then
    local server=$(vertical_server)
  elif [ "$1" = "staging" ]; then
    local server=$(vertical_server)-staging
  else
    local server=$1
  fi
  title "Console $1"
  $MARKETPLACER_PATH/script/console $server $VERTICAL && title "Terminal"
}

function vrs() {
  if (( $# == 1 )); then
    v $1
    vrs
  elif (( $# == 0 )); then
    ports_respond 3808 || ttab -G rf
    rs $(verticals | colrm 1 10 | grep -n -m 1 $VERTICAL | colrm 2) $VERTICAL 3808 1080 6379
  else
    local current_dir=$PWD
    for vertical in "$@"
    do
      ttab -G "cd $current_dir && vrs $vertical"
    done
  fi
}
