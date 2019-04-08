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
    cc_menu_initialize $(cc_menu_list "$branch" | quote_lines)
  fi
}

function cc_menu_remove_purged {
  cc_menu_initialize $(comm -12 <( cc_menu_list | sort ) <( git_non_release_branch_list | sort ) | quote_lines | cc_menu_branches_with_timestamps | sort -k 2 | cut -d' ' -f 1)
}

function cc_menu_add_item {
  local branch="$1"
  local project_name=${2:-Marketplacer ($branch)}
  local server_url=${3:-https://cc.buildkite.com/marketplacer/marketplacer.xml?access_token=$CC_BUILDKITE_TOKEN&branch=$branch}

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
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -qF "Marketplacer ($branch)"
}

function cc_menu_initialize {
  killall CCMenu
  defaults write net.sourceforge.cruisecontrol.CCMenu Projects '()'
  cc_menu_add_item master
  cc_menu_add_item 3rd-party "third party services" "https://cc.buildkite.com/marketplacer/third-party-services.xml?access_token=$CC_BUILDKITE_TOKEN"
  cc_menu_add_item "$(cc_menu_separator)" "$(cc_menu_separator)" "$(cc_menu_separator)"
  for branch in "$@"; do
    cc_menu_add_item "$branch"
  done
  open -g /Applications/CCMenu.app
}

function cc_menu_list {
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep displayName | tr -d '",;' | colrm 1 22 | grep -vF -e master -e deploys -e "$(cc_menu_separator)" -e "3rd-party" $(echo "${@/#/-e }")
}

function cc_menu_separator {
  echo "--------------------"
}

function cc_menu_branches_with_timestamps {
  while read -r line; do
    echo "$line $(git log --format="%at" master..$line | tail -n 1)"
  done
}

function ci {
  local branch=${1:-$(git_current_branch)}
  open "https://buildkite.com/marketplacer/marketplacer/builds?branch=$branch"
}

function deploys {
  local branch=${1:-$(git_current_branch)}
  open "https://buildkite.com/marketplacer/deploys/builds?branch=$branch"
}
