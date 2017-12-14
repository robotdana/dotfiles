# source ./git_support.sh

function prompt_dirty_branch() {
  local branch=$(git_current_branch)
  git_status_clean || ( [ $branch ] && echo ":$branch" )
}

function prompt_clean_branch() {
  git_status_clean && echo :$(git_current_branch)
}

function prompt_context() {
  case $(git_current_repo) in
    "marketplacer") echo "($(short_vertical))";;
    *);;
  esac
}

function title() {
  local title=${*:-Terminal}
  printf "\033]0;%s\007" "$title $(prompt_context)"
}
