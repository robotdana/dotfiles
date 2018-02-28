# source ./bash_support.sh

function git_track_untracked(){
  local has_untracked=$(git status --untracked=all --porcelain | grep -e "^??")
  if [[ ! -z "$has_untracked" ]]; then
    echodo git add -N .
  fi
}

function git_untrack_new_blank() {
  local newblank=$(git diff --cached --numstat --no-renames | grep -E "^0\t0\t" | cut -f3 | quote_lines)
  if [[ ! -z "$newblank" ]]; then
    echodo git reset $newblank
  fi
}

function git_remove_empty_untracked() {
  local untracked=$(git status --untracked=all --porcelain | grep -e "^??" | colrm 1 3)
  if [[ ! -z "$untracked" ]]; then
    local untracked=$(find $untracked -size 0 | quote_lines)
    if [[ ! -z "$untracked" ]]; then
      echodo rm $untracked
    fi
  fi
}

function git_conflicts() {
  git ls-files -u | awk '{print $4}' | sort -u | escape_spaces | escape_brackets
}

function git_conflicts_with_line_numbers(){
  git_conflicts | xargs grep -nHoE '^<{6}|={6}|>{6}' | cut -d: -f1-2 | escape_spaces | escape_brackets
}

function git_modified(){
  set -- ${@/#/\"*.}
  set -- ${@/%/\"}
  eval "git diff --name-only --cached --diff-filter=ACM $@"
}

function rubocop_only_changed_lines(){
  local modified_with_line_numbers=$(for file in $(git_modified rb); do git blame -fs -M -C ..HEAD $file; done | awk -F' ' '/^0+ / {printf " -e \"" $2 "\033[0m:" $3+0 ":\""}')
  if [[ ! -z "$modified_with_line_numbers" ]]; then
    echodo bundle exec rubocop --force-exclusion --color $(git_modified rb) | eval grep -A 2 -F $modified_with_line_numbers
    if (( $? == 1 )); then
      return 0;
    fi
    return 1;
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

  gbb
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

# doesn't actually use the stash because it stashes indexed changes as well and 90% of the time I don't want that because I end up with weird merges
function git_fake_stash_dir() {
  echo .git-fake-stash/$(git_current_branch)/
}

function git_fake_stash_list() {
  ( cd $(git_fake_stash_dir); tail *.diff & ) 2>/dev/null
}

function git_fake_stash_clear() {
  rm -rf $(git_fake_stash_dir) 2>/dev/null
}

function git_fake_stash_head() {
  local dir=$(git_fake_stash_dir)
  ls $dir*.diff 2>/dev/null | sort -rh | head -n 1 || echo $dir"0.diff"
}

function git_fake_stash_next_path() {
  local dir=$(git_fake_stash_dir)
  mkdir -pv $dir
  local num=$(git_fake_stash_head)
  local num=${num#$dir}
  local num=${num%.diff}
  local new_num=$(( $num + 1 ))

  echo $dir$new_num.diff
}

function git_fake_stash() {
  git_track_untracked
  if [[ ! -z "$(git diff)" ]]; then
    local diff_path=$(git_fake_stash_next_path)
    echodo "git diff > $diff_path"
    if [[ -s $diff_path ]]; then
      echodo git apply -R $diff_path
      git_untrack_new_blank
      git_remove_empty_untracked
    fi
  fi
}

function git_fake_stash_pop() {
  local file=$(git_fake_stash_head)
  if [[ -s $file ]]; then
    untracked=$(git apply --3way --check $file 2>&1 | awk -F':' '/error: .*: does not exist in index/ {print $2}')
    if [[ ! -z "$untracked" ]]; then
      touch $untracked
      git add .
    fi
    echodo git apply --3way $file && rm $file && git_unstage && git_fake_stash_pop
  elif [[ -f $file ]]; then
    rm $file && git_fake_stash_pop
  fi
}

function git_unstage() {
  local has_staged=$(git diff --cached --numstat --no-renames | grep -Ev "^0\t0\t")
  if [[ ! -z "$has_staged" ]]; then
    echodo git reset -- && git_track_untracked
  fi
}

function git_stash() {
  git_untrack_new_blank && echodo git stash -u $*
}
