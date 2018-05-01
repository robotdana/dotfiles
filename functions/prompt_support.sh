# source ./git_support.sh

function prompt_dirty_branch() {
  local branch=$(git_current_branch)
  git_status_clean || ( [ $branch ] && echo ":$branch" )
}

function prompt_clean_branch() {
  git_status_clean && echo :$(git_current_branch)
}

function title() {
  printf "\\033]0;%s\\007" "${*:-Terminal}"
}
