function cc_menu_item_server_url {
  local branch="${1:-"$(git_current_branch)"}"

  if [[ -f .travis.yml ]]; then
    cc_menu_travis_url "$branch"
  elif [[ -f .buildkite/pipeline.yml ]]; then
    cc_menu_buildkite_url "$branch"
  fi
}

function cc_menu_travis_url {
  local repo=$(git_current_repo_with_org)
  local branch="${1:-"$(git_current_branch)"}"

  echo "https://api.travis-ci.com/repos/$repo/cc.xml?branch=$branch"
}

function cc_menu_buildkite_url {
  local branch=${1:-"$(git_current_branch)"}
  local access_token=$(buildkite_access_token)
  if [[ ! -z "$access_token" ]]; then
    access_token="&access_token=$access_token"
  fi

  echo "https://cc.buildkite.com/$(buildkite_org_slug)/$(buildkite_pipeline_slug).xml?branch=$branch$access_token"
}

function cc_menu_add {
  local branch="${1:-"$(git_current_branch)"}"

  if [[ ! -z "$(cc_menu_item_server_url $branch)" ]]; then
    if ! cc_menu_present "$branch"; then
      killall CCMenu 2>/dev/null
      cc_menu_add_item "$branch"
      open -g /Applications/CCMenu.app
    fi
  fi
}

function cc_menu_remove {
  local branch="${1:-"$(git_current_branch)"}"

  if cc_menu_present "$branch"; then
    killall CCMenu 2>/dev/null
    cc_menu_remove_item "$branch"
    open -g /Applications/CCMenu.app
  fi
}

function cc_menu_remove_purged {
  cc_menu_remove_branches $(comm -23 <(cc_menu_list | sort) <(git branch --format="$(git_current_repo) : %(refname:short)" | sort) | cut -d: -f2)
}

function cc_menu_project_name {
  curl "$(cc_menu_item_server_url "$branch")" 2>/dev/null | xmllint --xpath "string(//Projects/Project/@name)" -
}

function cc_menu_github_actions_server {
  ( cd ~/.dotfiles/locals/github-cctray && chruby 3.0.0 && bundle exec rackup -p 45454 -D config.ru && wait_for_ports 45454 )
}

function cc_menu_github_actions_server_restart {
  kill_port 45454 && cc_menu_github_actions_server
}

function cc_menu_add_item {
  local repo="$(git_current_repo)"
  local branch="${1:-"$(git_current_branch)"}"

  defaults write net.sourceforge.cruisecontrol.CCMenu Projects -array-add "
    {
      displayName = \"$repo : $branch\";
      projectName = \"$(cc_menu_project_name "$branch")\";
      serverUrl = \"$(cc_menu_item_server_url "$branch")\";

    }
  "
}

function cc_menu_remove_item {
  local repo="$(git_current_repo)"
  local branch="${1:-"$(git_current_branch)"}"

  defaults write net.sourceforge.cruisecontrol.CCMenu Projects "$(ruby --disable-all -e 'puts ARGF.read.sub(/
    \{\n
    \s*displayName\s=\s"#{Regexp.escape("'"$repo"'")}\s:\s#{Regexp.escape("'"$branch"'")}";\n
    \s*projectName\s=\s"[^"]+";\n
    \s*serverUrl\s=\s"[^"]+";\n
    \s*\},?\n?/x,
  "")' <(defaults read net.sourceforge.cruisecontrol.CCMenu Projects))"
}

function cc_menu_present {
  local branch="${1:-"$(git_current_branch)"}"
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -qF "displayName = \"$(git_current_repo) : $branch\";"
}

function cc_menu_init {
  killall CCMenu 2>/dev/null
  defaults write net.sourceforge.cruisecontrol.CCMenu Projects '()'
}

function cc_menu_remove_branches {
  killall CCMenu 2>/dev/null
  for branch in "$@"; do
    cc_menu_remove_item "$branch"
  done
  open -g /Applications/CCMenu.app
}

function cc_menu_list {
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -F "displayName = " | cut -f 2 -d\"
}
