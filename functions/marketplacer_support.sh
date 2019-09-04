[ $CURRENT_VERTICAL ] || export CURRENT_VERTICAL=bikeexchange

function verticals_with_databases() {
  comm -12 <( yq -r 'keys | sort | join("\n")' ~/M/marketplacer/config/verticals.yml ) <( mysql -e "SHOW DATABASES;" --skip-column-names | sort )
}

function locale_row {
  yq -r 'map_values(.locale | tostring | split("-") as $locale | if $locale[2] == "be" then $locale[2]+$locale[1] else $locale[2] end | tostring | ascii_downcase)' ~/M/marketplacer/config/verticals.yml | grep -F -e "\"$1\""
}

function short_vertical() {
  locale_row "$@" | cut -d: -f 2  | tr -d '", '
}

function long_vertical() {
  locale_row "$@" | cut -d: -f 1 | tr -d '", '
}

function vertical_prod_server() {
  vertical_server 'primary' "$@"
}

function vertical_staging_server() {
  vertical_server 'staging' "$@"
}

function vertical_standby_server() {
  vertical_server 'standby' "$@"
}

function vertical_server() {
  local vertical=${2:-$CURRENT_VERTICAL}
  local server=$1
  basename -s '.teg.io.json' $(grep "\"$vertical\":" -l ~/M/operations/chef/nodes/*$server*.json)
}

function vertical_remote_console() {
  local server=$1

  case $server in
    "prod") local host="$(vertical_prod_server)";;
    "staging") local host="$(vertical_staging_server)";;
    "office") local host="office-mt.private";;
    "cabal") local host="test-cabal.private";;
    "heart") local host="test-heart.private";;
    "rocket") local host="test-rocket.private";;
    *) local host=$server;;
  esac

  if [[ -z "$host" ]]; then
    echoerr "No $server server set up for $CURRENT_VERTICAL"
  else
    title "Console $server" && echodo script/console $host marketplacer
  fi
}

function prepare_app_with_yarn() {
  ports_respond 3808 || ys
  prepare_app
  wait_for_ports 3808
}

function prepare_app_docker() {
  echodo docker-compose stop db worker search cache
  echodo ttab -G "title MySQL; bundle exec docker-compose up db; exit" 2>/dev/null
  sleep 0.1s
  echodo ttab -G "title Redis; bundle exec docker-compose up worker; exit" 2>/dev/null
  sleep 0.1s
  echodo ttab -G "title Elasticsearch; bundle exec docker-compose up search; exit" 2>/dev/null
  sleep 0.1s
  echodo ttab -G "title Memcached; bundle exec docker-compose up cache; exit" 2>/dev/null
}

function prepare_app_mailcatcher {
  echodo kill_port 1080
  echodo mailcatcher
}

function prepare_app() {
  ports_respond 3306 6379 11211 9200 || prepare_app_docker
  pgrep sidekiq >/dev/null || echodo ttab -G "title Sidekiq; bundle exec sidekiq; exit" 2>/dev/null
  ( ports_respond 1080 || prepare_app_mailcatcher & )
  wait_for_ports 3306 1080 6379 11211 9200
}

function reindex() {
  echodo rails multitenant:reindex
}

function buildkite_failures() {
  local failures=$(m build failures)
  echo "$failures" | head -n 2 >/dev/tty
  echo "$failures" | awk -F'[\033 ]' '/^\033\[31mrspec / { print $3 }' | tr -d "'" > .buildkite-failures
}

function buildkite {
  [[ -f bin/build-urls ]] && open -g $(bin/build-urls)
}

function reset_raptor {
  git_autostash reset_raptor_clean
}

function reset_raptor_clean {
  echodo git checkout release/test-raptor
  echodo git reset --hard origin/master
  echodo git push --force --no-verify origin release/test-raptor
}
