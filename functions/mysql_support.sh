function mysql_new() {
  echodo docker run --name m-mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root mysql:5.7 --character-set-server=utf8mb4
}
function mysql_start() {
  socks_exist /var/run/docker.sock || docker_start
  wait_for_sock_then "echodo docker start m-mysql" /var/run/docker.sock
}
function docker_start() {
  echodo open --hide /Applications/Docker.app
}
