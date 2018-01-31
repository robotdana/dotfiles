# source ./bash_support.sh

function git_track_untracked(){
  local untracked=$(git status --untracked=all --porcelain | grep -e "^??" | cut -d' ' -f2 | escape_spaces)
  if [[ ! -z "$untracked" ]]; then
    echodo git add -N $untracked
  fi
}

function git_untrack_new_blank() {
  local newblank=$(git diff --cached --numstat --no-renames | grep -E "^0\t0\t" | cut -f3 | escape_spaces)
  if [[ ! -z "$newblank" ]]; then
    echodo git reset $newblank
  fi
}

function git_conflicts() {
  git ls-files -u | awk '{print $4}' | sort -u | escape_spaces
}

function git_conflicts_with_line_numbers(){
  git_conflicts | xargs grep -nHoE '^<{6}|={6}|>{6}' | cut -d: -f1-2 | escape_spaces
}

function git_modified(){
  git diff --name-only --cached --diff-filter=ACM
}

function git_modified_with_line_numbers(){
  git_modified | while read -r line; do
    git blame -fsw -M -C -- $line | awk -F' ' '/^0+ / {print $2 ":" $3+0}'
  done
}

function rubocop_only_changed_lines(){
  local files=$(git_modified "*.rb")
  if [[ ! -z "$files" ]]; then
    echodo bundle exec rubocop --color $files | echodo "grep --after-context=2 -E \"$(git_modified_with_line_numbers | tr "\n" '|' | sed 's/.$//' | sed 's/:/\.[^:\]\*:/g')\""
  fi
}

function git_open_conflicts() {
  local active_conflicts=$(git_conflicts_with_line_numbers)
  if [[ ! -z "$active_conflicts" ]]; then
    echodo git_edit $active_conflicts && git_open_conflicts
  fi
}

function git_add_conflicts() {
  echodo git add $(git_conflicts)
}

function git_edit() {
  $(git config core.editor) $*
}

function git_purge() {
  glm
  echodo git fetch -p

  local local_merged=$(git_non_release_branch_list --merged)
  [ ! -z "$local_merged" ] && echodo git branch -d $local_merged
  local tracking_merged=$(git_non_release_branch_list -r --merged)
  [ ! -z "$tracking_merged" ] && echodo git branch -rd $tracking_merged
}

function git_non_release_branch() {
  if [[ ! -z "$(git_release_branch_list | grep -Fx $(git_current_branch))" ]]; then
    echoerr "can't do that on a release branch"
  fi
}

# `current_branch` the current branch name
function git_current_branch() {
  git rev-parse --symbolic-full-name --abbrev-ref HEAD 2>/dev/null
}

function git_current_repo() {
  basename "$(git config --get remote.origin.url 2>/dev/null)" .git
}

function git_log_range() {
  local from=$1
  local to=${2:-HEAD}
  [[ "$from" != "$(git_current_branch)" ]] && echo $from..$to
}

function git_branch_list() {
  git branch --all --list --format="%(refname:short)" $*
}

function git_release_branch_list() {
  git_branch_list $* | grep -Ex "$(git_release_branch_match)"
}

function git_non_release_branch_list() {
  git_branch_list $* | grep -Evx "$(git_release_branch_match)"
}

function git_release_branch_match() {
  case $(git_current_repo) in
    marketplacer) echo '(origin/)?(master$|release/.*|demo/.*)';;
    dotfiles)     echo 'origin/master';;
    *)            echo '(origin/)?master';;
  esac
}

# `git_rebasable` checks that no commits added since this was branched from master have been merged into release/* demo/*
# `git_rebasable commit-ish` checks that no commits added since `commit-ish` have been merged into something release-ish
function git_rebasable() {
  git_non_release_branch
  local base=${1:-master}
  local since_base=$(git rev-list --count $base..HEAD)
  local unmerged_since_base=$(git rev-list --count $(git_release_branch_list | sed 's/$/..HEAD/'))
  if (( $since_base > $unmerged_since_base )); then
    echoerr some commits were merged to a demo or release branch, only merge from now on
  fi
}

function git_authors() {
  echodo "git shortlog -sen && git shortlog -secn"
}

function git_status_clean() {
  git diff --quiet HEAD &>/dev/null
}

function git_changed_files() {
  git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD
}

function git_file_changed() {
  git_changed_files | grep -xE "$1"
}


function git_autostash() {
  git stash save --include-untracked --quiet --keep-index -- MANUAL AUTOSTASH
}

function git_autostash_pop() {
  if [[ "$(git stash list -n 1)" == "stash@{0}: On $(git_current_branch): MANUAL AUTOSTASH" ]]; then
    git stash pop --quiet
  fi
}
