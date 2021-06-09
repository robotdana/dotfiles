# `rc` rails console
function rc(){
  title 'Console'
  echodo rails console
  title
}

# `rg <generate command>` rails generate
function rg(){
  echodo rails generate "$@"
}

# `rgm <new migration>` rails generate migration
# run rails generate <new migration>, open the migration file, migrate the database.
function rgm(){
  local filename=$(rg migration "$@" | awk '/db\/migrate/ {print $2}')
  if [[ ! -z $filename ]]; then
    echodo code -w "$filename"
    if [[ -s $filename ]]; then
      echodo rails db:migrate
    else
      echodo rm "$filename"
    fi
  fi
}


# `rs [<port offset>] [<host>] [<path>]` rails server
# start a rails server on <port offset> or 3000
# once it's ready, open <host>.lvh.me:<port>/<path>
function rs(){
  local port=$(port_offset 3000 "$1")
  local host=$(local_host_name "$2")
  local path="$3"

  # echodo kill_port $port
  wait_for_port_then "echodo open -g http://$host:$port$path" $port

  title "Server:$port"
  echodo rails server -p $port --pid=tmp/pids/server"$port".pid -b 0.0.0.0
  title
}

function be(){
  echodo bundle exec "$@"
}

# `rt [<test files>]` shortcut for rspec.
function rt(){
  echodo bundle exec rspec --format documentation "$@"
}

function rtr() {
  rt --failure-exit-code 2 "$@"
  [[ "$?" != "1" ]] && rtr "$@"
}

function rtn(){
  rt --next-failure "$@"
}

function rtc {
  git_track_untracked
  local files=$(git_modified_with_line_numbers _spec.rb)
  [[ ! -z $files ]] && rt $* $files
}

function hrt {
  killchrome
  NO_HEADLESS=1 rt "$@"
  killchrome
}
