function mysql_new() {
  echodo docker run --name m-mysql -p '3306:3306' -e MYSQL_ROOT_PASSWORD=root mysql:5.7 --character-set-server=utf8mb4
}
function mysql_start() {
  echodo docker start m-mysql
}
