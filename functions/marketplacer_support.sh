[ $CURRENT_VERTICAL ] || export CURRENT_VERTICAL=bikeexchange
unset VERTICAL

function locale_row() {
  local vertical=${1:-$CURRENT_VERTICAL}
  local locale=${vertical:0:2}
  local country=${vertical:2:2}
  sed -n -e '/def locale/,/ end$/ p' ~/M/marketplacer/app/lib/site_context.rb | grep -Fi -m 1 -e "$country-$locale'" -e ":$vertical "
}

function short_vertical() {
  locale_row "$@" | awk -F" +|:|-|'" '{ if($9=="be") { print $9 tolower($8) } else { print $9 } }'
}

function long_vertical() {
  locale_row "$@" | awk -F' +|:|-' '{ print $4 }'
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

function prepare_app_with_webkit() {
  ports_respond 3808 || ys
  prepare_app
  wait_for_ports 3808
}

function prepare_app() {
  ( ports_respond 3306 6379 || docker-compose up & ) && echo ''
  pgrep sidekiq >/dev/null || echodo ttab -G "title Sidekiq; bundle exec sidekiq; exit"
  ( ports_respond 1080 || echodo mailcatcher & )
  wait_for_ports 3306 1080 6379
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

function cc_menu_add {
  local branch="${1:-$(git_current_branch)}"
  if ! cc_menu_present "$branch"; then
    killall CCMenu
    cc_menu_add_item "$branch"
    open -g /Applications/CCMenu.app
  fi
}

function cc_menu_remove {
  local branch="${1:-$(git_current_branch)}"
  if cc_menu_present "$branch"; then
    cc_menu_initialize $(cc_menu_list $branch)
  fi
}

function cc_menu_remove_purged {
  cc_menu_initialize $(comm -12 <( cc_menu_list | sort ) <( git_non_release_branch_list | sort ))
}

function cc_menu_add_item {
  local branch="$1"
  local project_name=${2:-Marketplacer - remote ($branch)}
  local server_url=${3:-https://cc.buildkite.com/marketplacer/marketplacer-remote.xml?access_token=$CC_BUILDKITE_TOKEN&branch=$branch}

  defaults write net.sourceforge.cruisecontrol.CCMenu Projects -array-add "
    {
      displayName = \"$branch\";
      projectName = \"$project_name\";
      serverUrl = \"$server_url\";
    }
  "
}

function cc_menu_present {
  local branch="$1"
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -qF "Marketplacer - remote ($branch)"
}

function cc_menu_initialize {
  killall CCMenu
  defaults write net.sourceforge.cruisecontrol.CCMenu Projects '()'
  cc_menu_add_item deploys deploys "https://cc.buildkite.com/marketplacer/deploys.xml?access_token=$CC_BUILDKITE_TOKEN"
  cc_menu_add_item master
  cc_menu_add_item "$(cc_menu_separator)" '' ''
  for branch in "$@"; do
    cc_menu_add_item "$branch"
  done
  open -g /Applications/CCMenu.app
}

function cc_menu_list {
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep displayName | tr -d '",;' | colrm 1 22 | grep -vF -e master -e deploys -e "$(cc_menu_separator)" "${@/#/-e }"
}

function cc_menu_separator {
  echo "----------------------------------------------"
}
