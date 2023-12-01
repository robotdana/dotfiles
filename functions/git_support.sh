# echo "required git_support"
# source ./bash_support.sh

function git_untracked(){
  git ls-files --others --exclude-standard | escape_spaces
}

function git_can_autostash {
  git_untrack_new_unstaged

  if [[ ! -z "$(git_untracked)" ]]; then
    echoerr "There are untracked files, can't autostash to rebase"
    echoerr "Use git_stash_only_untracked"
    false
  fi
}

function git_track_untracked(){
  if [[ ! -z "$(git_untracked)" ]]; then
    echodo git add -N $(git_untracked)
  fi
}

# TODO: more tests
function git_untrack_new_unstaged() {
  local newblank=$(git diff --numstat --no-renames --diff-filter=A | awk -F'\t' '/^[0-9]+\t0\t/ { print $3 }' | escape_spaces)
  if [[ ! -z "$newblank" ]]; then
    echodo git reset -- $newblank
  fi
}

function git_modified(){
  git diff --name-only HEAD --diff-filter=ACM -- "${@/#/*}"
}

function git_modified_head(){
  git diff --name-only HEAD^..HEAD --diff-filter=ACM -- "${@/#/*}"
}

function git_modified_with_line_numbers(){
  for file in $(git_modified $*); do git blame -fs -M -C ..HEAD "$file"; done | awk -F' ' '/^0+ / {print $2 ":" $3+0}'
}

function git_conflicts_with_line_numbers(){
  git_status_filtered UU | xargs grep -nHoE -m 1 '^<{6}|={6}|>{6}' | cut -d: -f1-2 | escape_spaces
}

function git_handle_conflicts {
  if [[ -e .git/MERGE_MSG ]]; then
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
    git_untrack_new_unstaged

    git stash save --keep-index --include-untracked --quiet
    comm -12 <(git_status_filtered ?? | sort) <(git_status_filtered 'D ' | sort) | xargs rm

    # restore merge flags
    cp /tmp/conflict_MERGE_MSG .git/MERGE_MSG
    if [[ ! -z "$merge_head" ]]; then
      echo -e $merge_head > .git/MERGE_HEAD
    fi
  else
    true
  fi
}

function git_autolint() {
  echo git_autolint
  exitstatus=0
  git_autolint_prettier "$@" || exitstatus=$(( $exitstatus + $? ))
  git_autolint_stylelint "$@" || exitstatus=$(( $exitstatus + $? ))
  git_autolint_eslint "$@" || exitstatus=$(( $exitstatus + $? ))
  git_autolint_rubocop "$@" || exitstatus=$(( $exitstatus + $? ))
  git_autolint_spellr "$@" || exitstatus=$(( $exitstatus + $? ))
  git_autolint_rails_annotate "$@" || exitstatus=$(( $exitstatus + $? ))
  git_autolint_rails_chusaku "$@" || exitstatus=$(( $exitstatus + $? ))
  echo $exitstatus
  return $exitstatus
}

function git_autolint_head {
  echo git_autolint_head
  git_rebase_exec HEAD^ git_autolint git_commit_during_rebase
}

function git_autolint_branch {
  git_rebase_exec $(git_branch_fork_point) git_autolint git_commit_during_rebase
}

function git_commit_during_rebase {
  echo git_commit_during_rebase
  ga &&
  ( git_status_clean ||
    git commit --no-edit --no-verify 2>/dev/null ||
    ( git_find_sha HEAD && git commit --amend --no-edit --no-verify )
  ) && ( git_status_clean || git_stash )
}

function git_autolint_prettier {
  if [[ -f .prettierrc ]]; then
    js_files=$(git_modified_head .js .jsx .ts .tsx)
    if [[ ! -z "$js_files" ]]; then
      echodo node_modules/.bin/prettier --write $js_files
      on_dirty "$@"
    fi
  fi
}

function git_autolint_stylelint {
  if [[ -f .stylelintrc ]]; then
    style_files=$(git_modified_head .ts .tsx)
    if [[ ! -z "$style_files" ]]; then
      echodo node_modules/.bin/stylelint $style_files
    fi
  fi
}

function git_autolint_eslint {
  if [[ -f .eslintrc ]] || [[ -f .eslintrc.js ]]; then
    js_files=$(git_modified_head .js .jsx .ts .tsx)
    if [[ ! -z $js_files ]]; then
      echodo node_modules/.bin/eslint --fix $js_files
      on_dirty "$@"
    fi
  fi
}

function git_autolint_rubocop {
  if [[ -f .rubocop.yml ]]; then
    rb_files=$(git_modified_head .rb .jbuilder .builder Gemfile .rake Rakefile .gemspec)

    if [[ ! -z $rb_files ]]; then
      be_rubocop_autocorrect_all --force-exclusion --color $rb_files && on_dirty "$@"
    fi
  fi
}

function git_autolint_rails_annotate {
  if [[ -f Gemfile.lock ]] && grep -Fq annotate Gemfile.lock; then
    rb_files=$(git_modified_head db/schema.rb)

    if [[ ! -z $rb_files ]]; then
      bundle exec annotate && on_dirty "$@"
    fi
  fi
}

function git_autolint_rails_chusaku {
  if [[ -f Gemfile.lock ]] && grep -Fq chusaku Gemfile.lock; then
    rb_files=$(git_modified_head app/controllers/**/*.rb config/routes*)

    if [[ ! -z $rb_files ]]; then
      bundle exec chusaku && on_dirty "$@"
    fi
  fi
}

function git_autolint_spellr {
  if [[ -f .spellr.yml ]]; then
    echodo be spellr -i $(git_modified_head) && on_dirty "$@"
  fi
}

function on_dirty {
  git_status_clean || (( $# >= 1 )) && "$@"
}

function git_status_filtered() {
  git status --porcelain | grep -F "$* " | colrm 1 3 | escape_spaces
}

# TODO: test
function git_prepare_content_conflicts() {
  git_open_conflicts
  git_status_filtered UU | xargs git add
}

# Tested
function git_prepare_their_deletions() {
  local conflicted=$(git_status_filtered UD | escape_spaces)
  if [[ ! -z "$conflicted" ]]; then
    git rm $conflicted
    git reset --quiet -- $conflicted # so we can interactively add the removal in the git add conflicts step
  fi
}

# Tested
function git_prepare_our_deletions() {
  local conflicted=$(git_status_filtered DU | escape_spaces)
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

function git_automain {
  current_branch="$(git_current_branch)"
  git checkout "$(git_main_branch)"
  "$@"
  git checkout $current_branch
}
# TODO: test
function git_purge {
  git_autostash git_automain git_purge_on_main
}

function git_purge_all {
  local current_dir=$PWD
  for repo in $(eval ls -1d $PROJECT_DIRS); do
    cd "$repo" && [[ -d .git ]] && cc_menu_repo_present && echo "Purging $repo" && ( git purge || exit 1 )
  done
  cd "$current_dir"
}

# TODO: test
function git_purge_on_main {
  git checkout "$(git_main_branch)"
  echodo git fetch -qp origin $(git_branch_local_and_remote)
  git reset --hard --quiet origin/"$(git_main_branch)"

  git_purge_merged
  git_purge_rebase_merged
  git_purge_only_tracking

  cc_menu_remove_purged
}

# TODO: test
function git_purge_rebase_merged() {
  for branch in $(git_non_release_branch_list); do
    local message=( $(git show -s --pretty="%at %aE %s" "$branch") )
    if [[ ! -z "$(git log --since="${message[0]}" --author="${message[1]}" --pretty="%at %aE %s" "$(git_main_branch)" | grep -F "$(echo ${message[@]})")" ]]; then
      echodo git branch -D "$branch"
    fi
  done
}

# TODO: test
function git_purge_merged() {
  for branch in $(git_non_release_branch_list --merged "$(git_main_branch)"); do
    echodo git branch -d "$branch"
  done
}

# TODO: test
function git_purge_only_tracking() {
  local only_tracking=$(comm -13 <( git_non_release_branch_list | sed 's/^/origin\//' ) <( git_non_release_branch_list -r ))
  if [[ ! -z $only_tracking ]]; then
    echodo git branch -rD $only_tracking
  fi
}


function git_non_release_branch() {
  if (git_current_branch | grep -qEx $(git_release_branch_match)); then
    echoerr "can't do that on a release branch"
    exit 1
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
  ref=$(git rev-parse --symbolic-full-name --abbrev-ref "$1" 2>/dev/null)
  [[ -z "$ref" ]] && echo "$1" || echo "$ref"
}

function git_current_repo() {
  local remote=${1:-origin}
  basename "$(git config --get remote.$remote.url 2>/dev/null)" .git
}

function git_current_repo_org {
  local remote=${1:-origin}
  basename "$(dirname "$(git config --get remote.$remote.url)")" | cut -d: -f2
}
function git_current_repo_with_org {
  local remote=${1:-origin}
  echo "$(git_current_repo_org $remote)/$(git_current_repo $remote)"
}

# TODO: test
function git_find_sha() {
  local val="${*:-HEAD}"
  if git rev-parse --verify --quiet "$val" 1>/dev/null; then
    val=$(git rev-parse --short "$val")
  fi

  local root
  if git_rebasing; then
    root=$(git_rebase_onto)
  else
    root="$(git_main_branch)"
  fi

  local commits=()
  while IFS= read -r line; do
    commits+=( "$line" )
  done < <(git_log_oneline "$root" 2>/dev/null | grep -E -e '^([^\sm]+m)?'"$val" -e '\s.*'"$val")
  if (( ${#commits[@]} > 1 )); then
    echoerr "Multiple possible commits found:"
    for commit in "${commits[@]}"; do
      echo -e "$commit" >&2
    done
    return ${#commits[@]}
  elif (( ${#commits[@]} == 0 )); then
    echoerr "Commit "$*" not found in branch:"
    gbl >&2 2>/dev/null
    return 1
  else
    echo "${commits[0]}" | cut -d' ' -f1 | strip_color
  fi
}

function git_stash_only_untracked {
  if [[ ! -z "$(git_untracked)" ]]; then
    if [[ ! -z "$(git diff HEAD --diff-filter=ACM --name-only)" ]]; then
      git stash --quiet &&
      git stash -u &&
      git stash pop stash@{1} --quiet &&
      git rev-parse stash
    else
      git_stash
    fi
  else
    false
  fi
}

# Tested
function git_reword() {
  local commit
  commit=$(git_find_sha $*)
  if (( $? < 1 )); then
    if git_rebasable "$commit^"; then
      if [[ "$commit" == "$(git rev-parse --short HEAD)" ]]; then
        git commit --amend
      else
        git_rebase_noninteractively reword $commit
      fi
    fi
  else
    return 1
  fi
}

function git_get() {
  git fetch origin "$1" && git checkout "$1"
}

function git_fetch_merge {
  git fetch origin "$1" && git merge --no-edit origin/"$1"
}

# TODO: test
function git_log_oneline {
  ( echo_grey git log --oneline $(git_log_range "$1") )>&2
  local commits_in_origin=$(echo -e $(git log --format="%h" $(git merge-base --fork-point $(git_remote_main_branch)) 2>/dev/null))
  local commit_in_origin_condition='index("'$commits_in_origin'", $2) > 0'

  git log --format="%b%n§%h§%s§%cr" $(git_log_range "$1") | awk -F'§' '{
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
      printf "%s%s%s%s%s", $2, " '$C_RESET'", $3, " \033[2m", $4

      if (body != "") {
        gsub("\r", "", body)
        printf "%s%s", "'$C_GREY'\033[2m", body
      }

      body=""

      print "\033[0m"
    }
  }'
}

function git_rebase_noninteractively {
  local new_task=$1
  local sha=$2
  git_can_autostash && GIT_SEQUENCE_EDITOR="sed -i.~ s/^pick\ $sha\ /$new_task\ $sha\ /" git rebase --interactive --autosquash --autostash "$sha^" >/dev/null 2>/dev/null
}

function git_squash_branch {
  git_can_autostash && GIT_EDITOR=: GIT_SEQUENCE_EDITOR="sed -i.~ 1\ \!\ \ s/^pick\ /squash\ /" git rebase --interactive --autosquash --autostash "$(git_main_branch)"
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

function git_branch_rm {
  local branch=${1:-$(git_current_branch)}
  if [[ "$1" == "$(git_current_branch)" ]]; then
    git_stash
    echodo git checkout "$(git_main_branch)"
  fi

  echodo git branch -D "$branch"
  echodo git branch -Dr origin/"$branch" upstream/"$branch"
  cc_menu_remove "$branch"
}
function git_branch_D {
  git_branch_rm "$@"
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
    dotfiles)     echo 'origin/main';;
    '')           echo 'NOMATCH';;
    *)            echo '(origin/)?(master|main|trunk|primary)';;
  esac
}

function git_rebasable() {
  ! git_rebasing && git_non_release_branch
}

function git_rebase_i() {
  git_can_autostash && (
    GIT_SEQUENCE_EDITOR=: echodo git rebase --interactive --autosquash --autostash "$@"
  )
}

function git_rebasing {
  [[ -d "$(git rev-parse --git-path rebase-merge)" ]] ||
    [[ -d "$(git rev-parse --git-path rebase-apply)" ]]
}

function git_rebase_onto {
  cat $(git rev-parse --git-path rebase-merge/onto) $(git rev-parse --git-path rebase-apply/onto) 2>/dev/null
}

function git_rebase_exec {
  git_can_autostash && (
    git_rebase_i --exec="bash -cl '${*:2}'" "$1" --reschedule-failed-exec
  )
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
    git_authors | grep -Fi ${@/#/-e } | awk '$0="Co-Authored-By: "$0'
  else
    git shortlog -sen | cut -f2
  fi
}

function git_main_branch() {
  git_branch_list | grep -Fx -e master -e main -e trunk -e primary -e gh-pages -e develop
}

function git_unstaged_binary_files() {
  git diff --numstat | grep -q '\-\t-'
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

function git_changed_files_after_merge() {
  git diff-tree -r --name-only --no-commit-id ORIG_HEAD HEAD
}

function git_file_changed_after_merge() {
  git_changed_files_after_merge | grep -xE "$1"
}

function git_unstage() {
  local has_staged=$(git diff --cached --numstat --no-renames | grep -Ev "^0\t0\t")
  if [[ ! -z "$has_staged" ]]; then
    echodo git reset --quiet -- && git_track_untracked
  fi
}

function git_stash() {
  echo git_stash
  git_untrack_new_unstaged &&
    echodo git stash -u "$@" --quiet &&
    git rev-parse --short stash
}

function git_autostash {
  if git_status_clean; then
    "$@"
  else
    local stash_sha="$(git_stash)"
    echo "Autostash: $stash_sha"
    if "$@"; then
      git stash apply $stash_sha
    else
      git stash apply $stash_sha
      false
    fi
  fi
}

function git_uncommit() {
  echodo git reset --quiet HEAD^
}

function git_undo () {
  local revision=${1:-1}
  git_autostash echodo git reset --hard HEAD@{$revision}
}

function github_path () {
  local remote=${1:-origin}
  local git_url="$(git remote get-url $remote)"

  git_url="${git_url/git@github.com:/https://github.com/}"
  echo ${git_url%%.git}
}

function bitbucket_path () {
  local remote=${1:-origin}
  local git_url="$(git remote get-url $remote)"

  git_url="${git_url/git@bitbucket.org:/https://bitbucket.org/}"
  echo ${git_url%%.git}
}

function git_pr () {
  local remote=${1:-origin}
  local git_url="$(git remote get-url $remote)"
  if [[ "$git_url" = *github* ]]; then
    echodo open "$(github_path)/compare/$(git_current_branch)?expand=1"
  elif [[ "$git_url" = *bitbucket* ]]; then
    echodo open "$(bitbucket_path)/pull-requests/new?source=$(git_current_branch)"
  fi
}

function github_actions_url () {
  echo $(github_path)/actions?query=branch:$(git_current_branch)
}

function git_ci () {
  local cc_menu_url="$(cc_menu_project_url)"
  if [[ ! -z "$cc_menu_url" ]]; then
    echodo open "$cc_menu_url"
  else
    echodo open "$(github_actions_url)"
  fi
}


function git_has_upstream () {
  git remote get-url upstream &>/dev/null
}

function git_branch_fork_point () {
  git merge-base --fork-point "$(git_main_branch)"
}

function github_file {
  open "$(github_path)/tree/$(git_current_branch)/$1"
}

function github_file_main {
  open "$(github_path)/tree/$(git_main_branch)/$1"
}

function github_commit {
  open "$(github_path)/commit/$1"
}

function git_last_rebase {
  git log -n 1 $(git merge-base "$(git_main_branch)" HEAD) --format=%cr
}


function git_pickaxe {
  git --no-pager log -p -S"$1" "${@:2}"
}

function git_pickaxe_b {
  git --no-pager log -p -G'(\b|_)'"$1"'(\b|_)' "${@:2}"
}

function restart_gpg {
  gpgconf --kill gpg-agent
}


function git_update_submodules {
  git submodule update --init --merge --remote --recursive
}
