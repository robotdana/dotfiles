# source ./bash_support.sh

function git_untracked(){
  git ls-files --others --exclude-standard | escape_spaces
}

function git_track_untracked(){
  if [[ ! -z "$(git_untracked)" ]]; then
    echodo git add -N $(git_untracked)
  fi
}

function git_untrack_new_blank() {
  local newblank=$(git diff --cached --numstat --no-renames --diff-filter=A | awk -F'\t' '/^0\t0\t/ { print $3 }' | escape_spaces)
  if [[ ! -z "$newblank" ]]; then
    echodo git reset -- $newblank
  fi
}

function git_modified(){
  git diff --name-only HEAD --diff-filter=ACM ${@/#/\*}
}

function git_modified_with_line_numbers(){
  for file in $(git_modified $*); do git blame -fs -M -C ..HEAD "$file"; done | awk -F' ' '/^0+ / {print $2 ":" $3+0}'
}

function git_conflicts_with_line_numbers(){
  git_status_filtered UU | xargs grep -nHoE -m 1 '^<{6}|={6}|>{6}' | cut -d: -f1-2 | escape_spaces
}

function git_handle_conflicts {
  # store merge flags
  cp .git/MERGE_MSG /tmp/conflict_MERGE_MSG
  if [[ -e .git/MERGE_HEAD ]]; then
    local merge_head=$(cat .git/MERGE_HEAD)
  fi

  # prepare working directory for interactive add
  git_prepare_content_conflicts
  git_prepare_their_deletions
  git_prepare_our_deletions

  # interactive add
  git_track_untracked
  git add -p

  # clean up un-added
  git_untrack_new_blank

  git stash save --keep-index --include-untracked --quiet
  comm -12 <(git_status_filtered ?? | sort) <(git_status_filtered 'D ' | sort) | xargs rm

  # restore merge flags
  cp /tmp/conflict_MERGE_MSG .git/MERGE_MSG
  if [[ ! -z "$merge_head" ]]; then
    echo -e $merge_head > .git/MERGE_HEAD
  fi
}

function git_status_filtered() {
  git status --porcelain | grep -F "$* " | colrm 1 3 | quote_lines
}

function git_prepare_content_conflicts() {
  git_open_conflicts
  git_status_filtered UU | xargs git add
}

function git_prepare_their_deletions() {
  local conflicted=$(git_status_filtered UD | quote_lines)
  if [[ ! -z "$conflicted" ]]; then
    git rm $conflicted
    git reset --quiet -- $conflicted # so we can interactively add the removal in the git add conflicts step
  fi
}

function git_prepare_our_deletions() {
  local conflicted=$(git_status_filtered DU | quote_lines)
  if [[ ! -z "$conflicted" ]]; then
    git add $conflicted
    git reset --quiet -- $conflicted # so we can interactively re-add in the git add conflicts step
    git add -N $conflicted
  fi
}

function git_open_conflicts() {
  local active_conflicts=( $(git_conflicts_with_line_numbers) )
  if (( ${#active_conflicts[@]} > 0 )); then
    code -w ${active_conflicts[@]/#/-g } && git_open_conflicts
  fi
}

function git_purge {
  git_autostash git_purge_on_master
}

function git_purge_on_master {
  git checkout master
  echodo git fetch -qp origin $(git_branch_local_and_remote)
  git reset --hard --quiet origin/master

  git_purge_merged
  git_purge_rebase_merged
  git_purge_only_tracking

  case $(git_current_repo) in
    marketplacer) cc_menu_remove_purged;;
  esac
}

function git_purge_rebase_merged() {
  for branch in $(git_non_release_branch_list); do
    local message=( $(git show -s --pretty="%at %aE %s" "$branch") )
    if [[ ! -z "$(git log --since="${message[0]}" --author="${message[1]}" --pretty="%at %aE %s" master | grep -F "$(echo ${message[@]})")" ]]; then
      echodo git branch -D "$branch"
    fi
  done
}

function git_purge_merged() {
  for branch in $(git_non_release_branch_list --merged master); do
    echodo git branch -d "$branch"
  done
}

function git_purge_only_tracking() {
  local only_tracking=$(comm -13 <( git_non_release_branch_list | sed 's/^/origin\//' ) <( git_non_release_branch_list -r ))
  if [[ ! -z $only_tracking ]]; then
    echodo git branch -rD $only_tracking
  fi
}

function git_non_release_branch() {
  if (git_current_branch | grep -qEx $(git_release_branch_match)); then
    echoerr "can't do that on a release branch"
  fi
}

function git_no_tracking {
  comm -23 <( git_non_release_branch_list ) <( git_non_release_branch_list -r  | sed 's/origin\///')
}

# `git_current_branch [optional_prefix]` the current branch name possibly with a prefix
function git_current_branch() {
  git_branch_name HEAD
}

function git_branch_name() {
  git rev-parse --symbolic-full-name --abbrev-ref "$1" 2>/dev/null
}

function git_prompt_current_branch() {
  local branch
  branch=$(git_current_branch)
  if [[ $branch == 'HEAD' ]]; then
    branch=$(git branch --format='%(refname:short)' --contains HEAD 2>/dev/null | grep -Evx "($(git_release_branch_match)|\\(HEAD detached at.*)")
    branch="$branch[$(git rev-parse --short HEAD 2>/dev/null)]"
  fi
  [[ ! -z $branch ]] && echo "$1$branch"
}

function git_current_repo() {
  basename "$(git config --get remote.origin.url 2>/dev/null)" .git
}

# TODO: if it's not found just pass it through so I could e.g. use HEAD
# or pass it to $(git rev-parse --short) and try again
function find_sha() {
  local commits=()
  while IFS= read -r line; do
    commits+=( "$line" )
  done < <(git_log_oneline master 2>/dev/null | grep -E -e '^\e\[(\d;?)+m'"$*" -e "\\e\\[0m[^\[]*$*")

  if (( ${#commits[@]} > 1 )); then
    echoerr "Multiple possible commits found:"
    for commit in "${commits[@]}"; do
      echo -e "$commit" >&2
    done
    return ${#commits[@]}
  elif (( ${#commits[@]} == 0 )); then
    echoerr "Commit not found:"
    gbl >&2 2>/dev/null
    return 1
  else
    echo "${commits[0]}" | cut -d' ' -f1 | strip_color
  fi
}

function git_reword() {
  if [[ -z "$1" ]]; then
    git_rebasable_quick HEAD^ && echodo git commit --amend
  else
    local commit
    commit=$(find_sha $*)
    if (( $? < 1 )); then
      git_rebasable_quick "$commit^" && git_rebase_noninteractively reword $commit
    else
      return 1
    fi
  fi
}

function git_fetch_and_checkout() {
  git fetch origin "$1"
  git checkout "$1"
}

function git_log_oneline {
  ( echo_grey git log --oneline $(git_log_range "$1") )>&2
  if [[ "$1" != "$(git_current_branch)" ]]; then
    local commits_in_origin=$(echo -e $(git log --format="%h" $(git_log_range "$1" HEAD origin/) 2>/dev/null))
    local commit_in_origin_condition='index("'$commits_in_origin'", $2) > 0'
  else
    local commit_in_origin_condition="1==1"
  fi

  git log --format="%b§%h§%s" $(git_log_range "$1") | awk -F'§' '{
    if ($0 ~ "^$") {
      # do nothing
    } else if ($1 != "" ) {
      body = body " " $1
    } else {
      if('"$commit_in_origin_condition"') {
        printf "%s", "'$C_AQUA'"
      } else {
        printf "%s", "'$C_GREEN'"
      }
      printf "%s%s%s", $2, " '$C_RESET'", substr($3, 0, 50); if (substr($3, 51, 1) != "") { printf "%s", "…" }

      if (body != "") {
        printf "%s%s", "'$C_GREY'",  substr(body, 0, 70); if (substr(body, 71, 1) != "") { printf "%s", "…" }
      }

      body=""

      print "\033\[0m"
    }
  }'
}

function git_rebase_noninteractively {
  local new_task=$1
  local sha=$2
  GIT_SEQUENCE_EDITOR="sed -i '' s/^pick\ $sha\ /$new_task\ $sha\ /" git rebase --interactive --autosquash --autostash "$sha^" >/dev/null 2>/dev/null
}
function git_squash_branch {
  GIT_EDITOR=: GIT_SEQUENCE_EDITOR="sed -i '' 1\ \!\ \ s/^pick\ /squash\ /" git rebase --interactive --autosquash --autostash master
}

function git_log_range() {
  local from="$(git_branch_name "$1")"
  local to="$(git_branch_name ${2:-HEAD})"
  local prefix="$3"
  [[ "$from" != "$(git_current_branch)" ]] && echo "$prefix$from".."$prefix$to"
}

function git_branch_list() {
  git branch --list --format="%(refname:short)" $*
}

function git_branch_local_only() {
  comm -23 <( git_branch_list ) <( git_remote_branch_list )
}

function git_branch_local_and_remote() {
  comm -12 <( git_branch_list ) <( git_remote_branch_list )
}

function git_remote_branch_list() {
  git ls-remote --heads -q | colrm 1 59
}

function git_release_branch_list() {
  git_branch_list "$@" | grep -Ex "$(git_release_branch_match)"
}

function git_non_release_branch_list() {
  git_branch_list "$@" | grep -Evx "$(git_release_branch_match)"
}

function git_force_pull_release_branches() {
  local branches;
  branches=$(git_release_branch_list -r | cut -d'/' -f 2-)
  if [[ ! -z "$branches" ]]; then
    echodo git fetch --force origin $branches
  fi
}

function git_release_branch_match() {
  case $(git_current_repo) in
    marketplacer) echo '(origin/)?(master$|release/.*)';;
    dotfiles)     echo 'origin/master';;
    *)            echo '(origin/)?master';;
  esac
}

# `git_rebasable` checks that no commits added since this was branched from master have been merged into release/*
# `git_rebasable commit-ish` checks that no commits added since `commit-ish` have been merged into something release-ish
function git_rebasable() {
  git_non_release_branch
  git_force_pull_release_branches
  git_rebasable_quick
}

function git_rebasable_quick() {
  git_non_release_branch
  local base=${1:-master}
  local since_base=$(git rev-list --count $(git_log_range "$base"))
  local unmerged_since_base=$(git rev-list --count $(git_release_branch_list --all | sed 's/$/..HEAD/'))
  if (( $since_base > $unmerged_since_base )); then
    echoerr some commits were merged to a release branch, only merge from now on
  fi
}

function git_rebase_i() {
  GIT_SEQUENCE_EDITOR=: echodo git rebase --interactive --autosquash --autostash "$@" || grc
}

function git_system() {
  local path=$(git rev-parse --show-toplevel)
  if [[ "$path" == $HOME/.gem ]] || [[ "$path" == $HOME/Library ]] || [[ "$path" != $HOME/* ]]; then
    true
  else
    false
  fi
}

function git_authors() {
  if (( $# > 0 )); then
    git_authors | grep -i "$@"
  else
    git shortlog -sen | cut -f2
  fi
}

function git_status_clean() {
  if [[ -z "$(git status --porcelain 2>/dev/null)" ]]; then
    true
  else
    false
  fi
}

function git_head_pushed() {
  if [[ "$(git rev-parse origin/$(git_current_branch) 2>/dev/null)" == "$(git rev-parse HEAD 2>/dev/null)" ]]; then
    true
  else
    false
  fi
}

function git_status_color() {
  if git_status_clean; then
    if git_head_pushed; then
      echo -en "$C_AQUA"
    else
      echo -en "$C_GREEN"
    fi
  else
    echo -en "$C_YELLOW"
  fi
}

function git_changed_files() {
  git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD
}

function git_file_changed() {
  git_changed_files | grep -xE "$1"
}

function git_unstage() {
  local has_staged=$(git diff --cached --numstat --no-renames | grep -Ev "^0\t0\t")
  if [[ ! -z "$has_staged" ]]; then
    echodo git reset --quiet -- && git_track_untracked
  fi
}

function git_stash() {
  git_untrack_new_blank && echodo git stash -u "$@"
}

function git_autostash {
  local current_branch="$(git_current_branch)"
  if ! git_status_clean; then
    git_untrack_new_blank
    echodo git stash save --include-untracked --quiet "fake autostash"
    local did_stash="1"
  fi

  echodo "$@"
  local outcome=$?

  echodo git checkout $current_branch
  if [[ $did_stash == "1" ]]; then
    echodo git stash pop --quiet
  fi
  return $outcome
}

function git_uncommit() {
  echodo git reset --quiet HEAD^
}
function git_fake_auto_stash() {
  if [[ ! -z "$(git diff)$(git ls-files --others --exclude-standard)" ]]; then
    if [[ ! -z "$(git diff --cached)" ]]; then
      git commit --no-verify --quiet --message "Temp (fake autostash index)"
      git_untrack_new_blank
      echodo git stash save --include-untracked --quiet "fake autostash"
      git reset --soft HEAD^ --quiet
    else
      echodo git stash save --include-untracked --quiet "fake autostash"
    fi
  fi
}

function git_fake_auto_stash_pop() {
  while [[ "$(git stash list -n 1)" = "stash@{0}: On $(git_current_branch): fake autostash" ]]; do
    echodo git add .
    echodo git stash apply --index --quiet
    local conflicts=$(git grep -lE '^<{6}|>{6}' | quote_lines)
    if [[ ! -z "$conflicts" ]]; then
      echodo git checkout --theirs $conflicts
    fi
    echodo git stash drop --quiet
    echodo git reset --quiet --
  done
}

function git_undo () {
  local revision=${1:-1}
  git_autostash echodo git reset --hard HEAD@{$revision}
}

function github_path () {
  local remote=${1:-origin}
  local git_url=$(git remote get-url $remote)

  git_url="${git_url/git@github.com:/https://github.com/}"
  echo ${git_url%%.git}
}

function git_pr () {
  open $(github_path)/compare/$(git_current_branch)?expand=1
}

function git_has_upstream () {
  git remote get-url upstream &>/dev/null
}

function git_branch_fork_point () {
  git merge-base --fork-point master
}

function github_file {
  open $(github_path)/tree/$(git_current_branch)/$1
}

function github_file_master {
  open $(github_path)/tree/master/$1
}

function git_last_rebase {
  git log -n 1 $(git merge-base master HEAD) --format=%cr
}

function git_reset_branch {
  echodo git fetch origin release/test-$1 master
  echodo git checkout release/test-$1
  echodo git reset --hard origin/master
  echodo git push --force origin release/test-$1
  echodo git checkout -
}
