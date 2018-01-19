function port_offset() {
  local base=${1:-3000}
  local offset=${2:-0}
  echo $(( $base + $offset ))
}

function local_host_name() {
  if [ $1 ]; then
    echo $1.lvh.me
  else
    echo localhost
  fi
}

function ports_respond(){
  local respond=true
  for port in "$@"; do
    if [[ ! $(lsof -ti :$port) ]]; then
      local respond=false
    fi
  done
  $respond
}

function socks_exist(){
  local respond=true
  for sock in "$@"; do
    if [[ ! -S $* ]]; then
      local respond=false
    fi
  done
  $respond
}

function wait_for_ports(){
  until ( ports_respond $* ); do sleep 1; done
}

function wait_for_socks(){
  until ( socks_exist $* ); do sleep 1; done
}

function wait_for_port_then(){
  local cmd=$1
  local ports=${@:2}
  ( wait_for_ports $ports && eval $cmd & ) >/dev/null
}

function wait_for_sock_then(){
  local cmd=$1
  local socks=${@:2}
  ( wait_for_socks $socks && eval $cmd & ) >/dev/null
}

function kill_port() {
  local port=$1
  lsof -ti :$port | xargs kill -9
}

function snginx(){
  echodo "$EDITOR /usr/local/etc/nginx/nginx.conf && nginx -s reload"
}
