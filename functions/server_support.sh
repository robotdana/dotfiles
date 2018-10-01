function port_offset() {
  local base=${1:-3000}
  local offset=${2:-0}
  echo $(( $base + $offset ))
}

function local_host_name() {
  if [ ! -z "$1" ]; then
    echo "$1".lvh.me
  else
    echo localhost
  fi
}

function ports_respond(){
  local respond=true
  for port in "$@"; do
    if [[ ! $(lsof -ti :"$port") ]]; then
      local respond=false
    fi
  done
  $respond
}

function wait_for_ports(){
  until ( ports_respond "$@" ); do sleep 1; done
}

function wait_for_port_then(){
  local cmd=$1
  local ports="${@:2}"
  ( wait_for_ports $ports && eval $cmd 2>/dev/tty & ) >/dev/null
}

function kill_port() {
  for port in "$@"; do
    lsof -ti :"$port" | xargs kill -9
  done
}

function snginx(){
  echodo $EDITOR /usr/local/etc/nginx/nginx.conf && echodo nginx -s reload
}
