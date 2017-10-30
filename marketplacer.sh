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
  vertical_row $* | awk -F':' '{print $4}' | tr -d ' '
}
function vertical_staging_server() {
  vertical_row $* | awk -F':' '{print $5}' | tr -d ' '
}
function vertical_demo_server() {
  vertical_row $* | awk -F':' '{print $6}' | tr -d ' '
}

function vertical_row() {
  local vertical=${1:-$VERTICAL}
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
  v $* && echodo "yes | DISABLE_MARKETPLACER_CLI_PRODUCTION_CHECK=1 m database update $VERTICAL" && rds
}
function vdlr() {
  vdl $* && reindex_all
}
function reindex_all() {
  echodo "rails r 'ES::Indexer.reindex_all'"
}


function vrd() {
  v $* && rd
}

function vrds(){
  v $* && rds
}

function vrc() {
  if (( $# == 2 )); then
    v $1 && remote_console $2
  else
    v $1 && rc
  fi
}

function remote_console() {
  local server=$1

  # TODO: use case statement here.
  case $server in
    "prod") local host=$(vertical_prod_server);;
    "demo") local host=$(vertical_demo_server);;
    "staging") local host=$(vertical_staging_server);;
    "office") local host="office.int";;
    *) local host=$server;;
  esac

  if [[ -z "$host" ]]; then
    echoerr "No $server server set up for $VERTICAL"
  else
    title "Console $server" && echodo script/console $host $VERTICAL
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

  ports_respond 3808 || echodo "ttab -G 'title Webpack && yarn start'"
  ports_respond 1080 || echodo "ttab -G 'title Mailcatcher && mailcatcher'"
  ports_respond 6379 || echodo "ttab -G 'title Sidekiq && bundle exec sidekiq'"

  local row=$((($(vertical_row_number $vertical) - 1)))
  v $vertical && rs $row $VERTICAL $path 3808 1080 6379
}
