function cc_menu_initialize {
  cc_menu_replace 'marketplacer:master' 'spellr:main' 'leftovers:main' 'fast_ignore:main' 'tty_string:main' 'dotfiles:main'
}
function cc_menu_item_project_name {
  local repo=${1:-"$(git_current_repo)"}
  local branch=${2:-"$(git_current_branch)"}
  case $repo in
    marketplacer) echo "Marketplacer ($branch)";;
    spellr | dotfiles | fast_ignore | tty_string | leftovers) echo "robotdana/$repo";;
  esac
}

function cc_menu_item_server_url {
  local repo=${1:-"$(git_current_repo)"}
  local branch=${2:-"$(git_current_branch)"}

  case $repo in
    marketplacer) echo "https://cc.buildkite.com/marketplacer/marketplacer.xml?access_token=$CC_BUILDKITE_TOKEN&branch=$branch";;
    spellr | dotfiles | fast_ignore | tty_string | leftovers) echo "https://api.travis-ci.com/repos/robotdana/$repo/cc.xml?branch=$branch";;
  esac
}

function cc_menu_add {
  local branch="${1:-$(git_current_branch)}"
  if ! cc_menu_present "$branch"; then
    killall CCMenu 2>/dev/null
    cc_menu_add_item "$(git_current_repo)" "$branch"
    open -g /Applications/CCMenu.app
  fi
}

function cc_menu_remove {
  local branch="${1:-$(git_current_branch)}"
  if cc_menu_present "$branch"; then
    killall CCMenu 2>/dev/null
    cc_menu_remove_item "$(git_current_repo)" "$branch"
    open -g /Applications/CCMenu.app
  fi
}

function cc_menu_remove_purged {
  cc_menu_remove_list $(comm -23 <(cc_menu_list | sort) <(git branch --format="$(git_current_repo) : %(refname:short)" | sort) | grep -F "$(git_current_repo) :" | tr -d ' ')
}

function cc_menu_add_item {
  local repo="${1:-"$(git_current_repo)"}"
  local branch="${2:-"$(git_current_branch)"}"

  defaults write net.sourceforge.cruisecontrol.CCMenu Projects -array-add "
    {
      displayName = \"$repo : $branch\";
      projectName = \"$(cc_menu_item_project_name "$repo" "$branch")\";
      serverUrl = \"$(cc_menu_item_server_url "$repo" "$branch")\";

    }
  "
}

function cc_menu_remove_item {
  local repo="${1:-"$(git_current_repo)"}"
  local branch="${2:-"$(git_current_branch)"}"

  cc_menu_replace $(cc_menu_list | grep -vF "$repo : $branch" | tr -d ' ')
}

function cc_menu_present {
  local branch="${1:-"$(git_current_branch)"}"
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -qF "displayName = \"$(git_current_repo) : $branch\";"
}

function cc_menu_replace {
  killall CCMenu 2>/dev/null
  defaults write net.sourceforge.cruisecontrol.CCMenu Projects '()'
  for repo_branch in "$@"; do
    repo=${repo_branch%:*}
    branch=${repo_branch#*:}
    cc_menu_add_item "$repo" "$branch"
  done
  open -g /Applications/CCMenu.app
}

function cc_menu_remove_list {
  killall CCMenu 2>/dev/null
  for repo_branch in "$@"; do
    repo=${repo_branch%:*}
    branch=${repo_branch#*:}
    cc_menu_remove_item "$repo" "$branch"
  done
  open -g /Applications/CCMenu.app
}

function cc_menu_list {
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -F "displayName = " | cut -f 2 -d\"
}
