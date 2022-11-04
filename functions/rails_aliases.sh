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
  if [[ -z "which bundle" ]]; then
    echodo "$@"
  else
    bundle --quiet && echodo bundle exec "$@"
  fi
}

function be_rubocop_autocorrect_all {
  if [[ -z "$(be rubocop --help | grep -F -e --autocorrect-all)" ]]; then
    be rubocop -A "$@"
  else
    be rubocop -a "$@"
  fi
}

function brake(){
  be rake "$@"
}

# `rt [<test files>]` shortcut for rspec.
function rt(){
  be rspec --format documentation "$@"
}

function rcu(){
  be cucumber "$@"
}

function rcur(){
  rcu -p ci "$@"
  rcur "$@"
}

function rtr() {
  rt --failure-exit-code 2 "$@"
  [[ "$?" != "1" ]] && rtr "$@"
}

function loop {
  _loop_with_count 1 0 "$@"
}

function _loop_with_count {
  echo_aqua "Iteration $1"
  echodo "${@:3}"
  if (( $? == 0 )); then
    local successes=$(( $2 + 1 ))
  else
    local successes=$2
  fi
  echo_grey "Success rate: $successes/$1"
  sleep 1 && _loop_with_count $(( $1 + 1 )) $successes "${@:3}"
}

function _loop_with_count_fail_fast_with_max {
  echo_aqua "Iteration $1"
  echodo "${@:3}"
  if (( $? == 0 )); then
    echo_grey "Success rate: $1/$1"
  else
    echo_grey "Success rate: $(( $1 - 1 ))/$1"
    return 1
  fi

  if (( $1 >= $2 )); then
    return 0
  else
    sleep 1 && _loop_with_count_fail_fast_with_max $(( $1 + 1 )) $2 "${@:3}"
  fi
}

function loopN {
  _loop_with_count_fail_fast_with_max 1 "$@"
}

function rtn(){
  rt --next-failure "$@"
}

function crt {
  echo_grey COVERAGE=1 MIN_COVERAGE=100
  COVERAGE=1 MIN_COVERAGE=100 rt "$@" || echodo open coverage/index.html
}

function rtc {
  git_track_untracked
  local files=$(git_modified_with_line_numbers _spec.rb)
  [[ ! -z $files ]] && rt $* $files
}
