# source ./git_support.sh

function prompt_dirty_branch() {
  local branch=$(git_current_branch)
  git_status_clean || ( [ $branch ] && echo ":$branch" )
}

function prompt_clean_branch() {
  git_status_clean && echo ":$(git_current_branch)"
}

function prompt_context() {
  if [[ $(git_current_repo) = "marketplacer" ]]; then
    echo "($(short_vertical))"
  fi
}

function title() {
  echo "\033]0;${*:-Terminal} $(prompt_context)\007"
}
