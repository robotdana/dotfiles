function prepare_app_with_yarn() {
  ports_respond 3808 || ys
  prepare_app
  wait_for_ports 3808
}

function prepare_app_docker() {
  echodo docker-compose stop redis search cache mailhog db
  echodo docker-compose up -d redis search cache mailhog db
}

function prepare_app() {
  ports_respond 3306 6379 11211 9200 1025 || prepare_app_docker
  pgrep sidekiq >/dev/null || ttab bundle exec sidekiq
}

function reindex() {
  echodo rails multitenant:reindex
}

function localeapp_pull {
  script/localeapp_pull.sh
  rake translations:cache:warm_up translations:generate_js_files
  echo_green "Now empty the browser cache if there are js translations ⌥⌘E"
}
