# echo "required cc_menu_support"

function cc_menu_item_server_urls {
  local branch="${1:-"$(git_branch_name)"}"

  if [[ -f .travis.yml ]]; then
    cc_menu_travis_url "$branch"
  elif [[ -f .buildkite/pipeline.yml ]]; then
    cc_menu_buildkite_url "$branch" "${@:2}"
  elif [[ -d .github/workflows ]]; then
    cc_menu_github_actions_urls "$branch"
  fi
}

function cc_menu_travis_url {
  local repo=$(git_current_repo_with_org)
  local branch="${1:-"$(git_branch_name)"}"

  echo "https://api.travis-ci.com/repos/$repo/cc.xml?branch=$branch"
}

function cc_menu_github_actions_urls {
  if [[ -z "$GITHUB_ACTIONS_TOKEN" ]]; then
    echoerr "No \$GITHUB_ACTIONS_TOKEN"
    return false
  else
    local repo=$(git_current_repo_with_org)
    local branch="${1:-"$(git_branch_name)"}"

    while IFS= read -r workflow; do
      echo "http://localhost:45454/$repo/$workflow?branch=$branch&token=$GITHUB_ACTIONS_TOKEN"
    done < <(ls -1 .github/workflows)
  fi
}

function cc_menu_buildkite_url {
  local branch=${1:-"$(git_branch_name)"}
  local access_token=${2:-"$(buildkite_access_token)"}
  if [[ ! -z "$access_token" ]]; then
    access_token="&access_token=$access_token"
  fi

  echo "https://cc.buildkite.com/$(buildkite_org_slug)/$(buildkite_pipeline_slug).xml?branch=$branch$access_token"
}

function cc_menu_add {
  local branch="${1:-"$(git_branch_name)"}"

  if [[ ! -z "$(cc_menu_item_server_urls $branch)" ]]; then
    if ! cc_menu_present "$branch"; then
      cc_menu_stop
      cc_menu_add_item "$branch"
      cc_menu
    fi
  fi
}

function cc_menu_remove {
  local branch="${1:-"$(git_branch_name)"}"

  if cc_menu_present "$branch"; then
    cc_menu_stop
    cc_menu_remove_item "$branch"
    cc_menu
  fi
}

function cc_menu_remove_purged {
  cc_menu_remove_branches $(comm -23 <(cc_menu_list | sort) <(git branch --format="$(git_current_repo) : %(refname:short)" | sort) | grep -F "$(git_current_repo) :" | cut -d: -f2)
}

function cc_menu_project_name {
  local branch="${1:-"$(git_branch_name)"}"

  curl "$(cc_menu_item_server_urls "$branch" | head -n 1)" 2>/dev/null | xmllint --xpath "string(//Projects/Project/@name)" -
}

function cc_menu_project_url {
  local branch="${1:-"$(git_branch_name)"}"

  curl "$(cc_menu_item_server_urls "$branch" | head -n 1)" 2>/dev/null | xmllint --xpath "string(//Projects/Project/@webUrl)" -
}

function cc_menu_github_actions_server_restart {
  kill_port 45454
  cc_menu
}

function cc_menu_add_item {
  local repo="$(git_current_repo)"
  local branch="${1:-"$(git_branch_name)"}"
  local project_name=$(cc_menu_project_name "$branch")

  while IFS= read -r server_url; do
    defaults write net.sourceforge.cruisecontrol.CCMenu Projects -array-add "
      {
        displayName = \"$repo : $branch$label\";
        projectName = \"$project_name\";
        serverUrl = \"$server_url\";

      }
    "
  done < <(cc_menu_item_server_urls "$branch")
}

function cc_menu_remove_item {
  local repo="$(git_current_repo)"
  local branch="${1:-"$(git_branch_name)"}"

  defaults write net.sourceforge.cruisecontrol.CCMenu Projects "$(ruby --disable-all -e 'puts ARGF.read.sub(/
    \{\n
    \s*displayName\s=\s"#{Regexp.escape("'"$repo"'")}\s:\s#{Regexp.escape("'"$branch"'")}";\n
    \s*projectName\s=\s"[^"]+";\n
    \s*serverUrl\s=\s"[^"]+";\n
    \s*\},?\n?/x,
  "")' <(defaults read net.sourceforge.cruisecontrol.CCMenu Projects))"
}

function cc_menu_present {
  local branch="${1:-"$(git_branch_name)"}"
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -qF "displayName = \"$(git_current_repo) : $branch\";"
}

function cc_menu_repo_present {
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -qF "serverUrl = \"$(cc_menu_item_server_urls '' '' | head -n 1)"
}

function cc_menu_init {
  cc_menu_stop
  defaults write net.sourceforge.cruisecontrol.CCMenu Projects '()'
}

function cc_menu_remove_branches {
  cc_menu_stop
  for branch in "$@"; do
    cc_menu_remove_item "$branch"
  done
  cc_menu
}

function cc_menu_list {
  defaults read net.sourceforge.cruisecontrol.CCMenu Projects | grep -F "displayName = " | cut -f 2 -d\"
}

function cc_menu_stop {
  killall CCMenu 2>/dev/null
}

function cc_menu {
  open -g /Applications/CCMenu.app
}
