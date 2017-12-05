[ $MVERTICAL ] || export MVERTICAL=bikeexchange
unset VERTICAL
VERTICAL_FILE=~/.dotfiles/locals/verticals

function vertical_rows() {
  cat $VERTICAL_FILE
}

function edit_verticals() {
  $EDITOR $VERTICAL_FILE
}

function missing_verticals() {
  comm -13 <(vertical_rows | awk -F' *: *' '{print $2}' | sort ) <(marketplacer verticals | sort)
}

function vertical_row_number() {
  vertical_field 'NR-1' $*
}

function short_vertical() {
  vertical_field '$1' $*
}

function long_vertical() {
  vertical_field '$2' $*
}

function vertical_prod_server() {
  vertical_field '$3' $*
}

function vertical_staging_server() {
  vertical_field '$4' $*
}

function vertical_demo_server() {
  vertical_field '$5' $*
}

function vertical_field() {
  local vertical=${2:-$MVERTICAL}
  local column=$1
  vertical_rows | awk -F' *: *' "/^$vertical|: $vertical/ {print $column; count++; if(count=1) exit}"
}

function vertical_remote_console() {
  local server=$1

  case $server in
    "prod") local host=$(vertical_prod_server);;
    "demo") local host=$(vertical_demo_server);;
    "staging") local host=$(vertical_staging_server);;
    "office") local host="office.int";;
    *) local host=$server;;
  esac

  if [[ -z "$host" ]]; then
    echoerr "No $server server set up for $MVERTICAL"
  else
    title "Console $server" && echodo script/console $host $MVERTICAL
  fi
}

function prepare_app_with_webkit() {
  ys
  prepare_app
  wait_for_ports 3808
}

function prepare_app() {
  ( ports_respond 3306 || echodo docker start m-mysql & )
  ( ports_respond 6379 || brew services start redis & )
  pgrep sidekiq >/dev/null || echodo "ttab -G 'title Sidekiq; bundle exec sidekiq; exit'"
  ( ports_respond 1080 || echodo mailcatcher & )
  wait_for_ports 3306 1080 6379
}

function reindex() {
  echodo "rails r 'ES::Indexer.reindex_all'"
}