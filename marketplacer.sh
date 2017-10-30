export VERTICAL='bikeexchange'
alias sverticals="subl -nw ~/.dotfiles/locals/verticals"
alias vertical_rows="cat ~/.dotfiles/locals/verticals"

alias missing_verticals='comm -13 <(long_verticals | sort ) <(marketplacer verticals | sort)'

function short_vertical() {
  vertical_row $* | awk -F':' '{print $2}' | tr -d ' '
}

function long_vertical() {
  vertical_row $* | awk -F':' '{print $3}' | tr -d ' '
}

function vertical_row_number() {
  vertical_row $* | awk -F':' '{print $1}' | tr -d ' '
}

function vertical_prod_server() {
  vertical_row $1 | awk -F':' '{print $4}' | tr -d ' '
}
function vertical_staging_server() {
  vertical_row $1 | awk -F':' '{print $5}' | tr -d ' '
}
function vertical_demo_server() {
  vertical_row $1 | awk -F':' '{print $6}' | tr -d ' '
}

function vertical_row() {
  if (($# == 1)); then
    local vertical=$1
  else
    local vertical=$VERTICAL
  fi
  vertical_rows | grep -n -m 1 -e "$vertical\|: $vertical\s" | head -n 1
}


function v(){
  local maybe_vertical=$1
  if [[ ! -z $maybe_vertical ]]; then
    cd $MARKETPLACER_PATH
    local vertical=$(long_vertical $maybe_vertical)
    if [ -z "$vertical" ]; then
      echoerr "No such vertical"
    elif [[ "$vertical" != "$VERTICAL" ]]; then
      echodo export VERTICAL=$vertical && title Terminal
    fi
  fi
}

function vdl() {
  v $1
  echodo "yes | DISABLE_MARKETPLACER_CLI_PRODUCTION_CHECK=1 m database update $VERTICAL"
  rds
}
function vdlr() {
  vdl $*
  reindex_all
}
function reindex_all() {
  echodo "rails r 'ES::Indexer.reindex_all'"
}


function vrd() {
  v $*
  rd
}

function vrds(){
  v $*
  rds
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
    local server=$(vertical_prod_server)
  elif [ "$1" = "demo" ]; then
    local server=$(vertical_demo_server)
  elif [ "$1" = "staging" ]; then
    local server=$(vertical_staging_server)
  elif [ "$1" = "office" ]; then
    local server="office.int"
  else
    local server=$1
  fi

  if [[ -z "$server" ]]; then
    echoerr "No $1 server set up for $VERTICAL"
  else
    title "Console $1" && echodo script/console $server $VERTICAL
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
      local vertical=$vertical_or_path
      local path="/"
    fi
  fi

  ports_respond 3808 || echodo "ttab -G 'title Webpack && yarn start'"
  ports_respond 1080 || echodo "ttab -G 'title Mailcatcher && mailcatcher'"
  ports_respond 6379 || echodo "ttab -G 'title Sidekiq && bundle exec sidekiq'"
  v $vertical && rs $((($(vertical_row_number) - 1))) $VERTICAL $path 3808 1080 6379
}
