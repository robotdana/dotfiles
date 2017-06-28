export VERTICAL='bikeexchange'

alias jslint='./node_modules/.bin/eslint --quiet --ext .jsx,.js webpack/app webpack/entry webpack/lib webpack/test webpack/vendor'

alias sverticals="subl -nw ~/.dotfiles/locals/verticals"
alias vertical_rows="cat ~/.dotfiles/locals/verticals"
alias short_verticals="vertical_rows | colrm 5 | tr -d ' '"
alias long_verticals="vertical_rows | colrm 1 23"

alias missing_verticals='comm -13 <(long_verticals | sort ) <(marketplacer verticals | sort)'

function short_vertical() {
  vertical_row $* | colrm 5 | tr -d " "
}

function long_vertical() {
  vertical_row $* | colrm 1 23
}

function vertical_row() {
  if (($# == 1)); then
    local vertical=$1
  else
    local vertical=$VERTICAL
  fi
  vertical_rows | grep -e "^$vertical \| $vertical$" | head -n 1
}

function vertical_prod_server() {
  vertical_row $* | colrm 1 5 | colrm 13
}
function vertical_staging_server() {
  ${$(vertical_row $*)[2]} # | colrm 1 18 | colrm 13
}

function v(){
  local maybe_vertical=$1
  if [[ ! -z $maybe_vertical ]]; then
    cd $MARKETPLACER_PATH
    local vertical=$(long_vertical $maybe_vertical)
    if [ -z "$vertical" ]; then
      echo "No such vertical"
    else
      echo "••• updated \$VERTICAL to $vertical •••"
      export VERTICAL=$vertical
      title Terminal
    fi
  fi
}

function vdl() {
  restart_mysql_if_crashed
  v $1
  yes | m database update $VERTICAL
  restart_mysql_if_crashed
  vrds
  restart_mysql_if_crashed
}

function vrd() {
  restart_mysql_if_crashed
  v $*
  rd
  restart_mysql_if_crashed
}

function vrds(){
  restart_mysql_if_crashed
  v $*
  rds
  restart_mysql_if_crashed
}

function vrc() {
  (( $# > 0 )) && v $1
  if (( $# == 2 )); then
    remote_console $2
  else
    restart_mysql_if_crashed
    rc
    restart_mysql_if_crashed
  fi
}

function remote_console() {
  if [ "$1" = "prod" ]; then
    local server=$(vertical_prod_server)
  elif [ "$1" = "staging" ]; then
    local server=$(vertical_staging_server)
  elif [ "$1" = "office" ]; then
    local server="office.int"
  else
    local server=$1
  fi
  title "Console $1"
  $MARKETPLACER_PATH/script/console $server $VERTICAL && title "Terminal"
}

function vertical_line_number() {
  local number=$(long_verticals | grep -n -m 1 $VERTICAL | tr -d ":$VERTICAL")
  if [[ -z "$number" ]]; then
    echo "0"
  else
    echo "$(($number - 1))"
  fi
}

function vrs() {
  local path=$2
  local vertical_or_path=$1

  if [ -z $path ]; then
    if [[ $vertical_or_path =~ ^/.* ]]; then
      local path=$vertical_or_path
      local vertical_or_path=""
    else
      local path="/"
    fi
  fi
  v $vertical_or_path

  restart_mysql_if_crashed
  ports_respond 3808 || ttab -G rf
  rs $(vertical_line_number) $VERTICAL $path 3808 1080 6379
  restart_mysql_if_crashed
}
