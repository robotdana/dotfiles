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
