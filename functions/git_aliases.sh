# echo "required git_aliases"
# source ./git_support.sh

# `ga` git add
# interactively add, including new files
# TODO: cope with binary files
function ga() {
  if git_unstaged_binary_files; then
    git_track_untracked
    echodo git add -p
    echoerr "There are binary files that require adding manually"
    git status
    false
  else
    git_track_untracked
    git_status_clean || echodo git add -p
  fi
}

# `gbn <new branch name>` git branch new
# creates a branch named <new branch name> based on latest main branch
# and switches to it.
function gbn() {
  if [[ "$*" == "dana/"* ]]; then
    local new_branch_name=$*
  else
    local new_branch_name=dana/$*
  fi
  glm
  echodo git checkout -b "$new_branch_name" "$(git_main_branch)"
}

# `gb <branch>` git branch
# switches to branch <branch>
function gb() {
  echodo git checkout "$@"
}

# `gbb` git branch back
# switches to previous branch
function gbb() {
  gb -
}

# `gbm` git branch main
# switches to main branch
function gbm() {
  gb "$(git_main_branch)"
}

# `gbl [<base branch>]` git branch log
# list commits added to this branch since forked from <base branch> or main branch.
function gbl() {
  local base_branch=${1:-"$(git_main_branch)"}
  git_log_oneline "$base_branch" | more -eRSF
}

# `gbf <filename> [<base branch>]` git branch file
# shows commits modifying <filename> since this branch forked from <base_branch> or main branch.
function gbf() {
  local filename=$1
  local base_branch=${2:-"$(git_main_branch)"}
  echodo git log --oneline --follow --patch $(git_log_range "$base_branch") -- "$filename"
}

function gbs {
  git show $(find_sha "$*")
}

# `gwip` git wip
# commit everything carelessly with the message `wip`
function gwip(){
  git_non_release_branch && echodo git add . && echodo git commit --no-verify -m "WIP"
}

# `gwipp` git wip
# commit everything carelessly with the message `wip`, then push
function gwipp() {
  gwip && gp
}

# TODO: test
function gunwip() {
  if [[ "$(git log --format="%an | %s" -n 1)" == "Dana Sherson | WIP"* ]]; then
    git uncommit && gunwip
  fi
}

function gg() {
  git_get $1
}

function gcr {
  git_reword $*
}

# `gcf [<commit>]` git commit fix
# fixups <commit> or the last commit & rebases
# TODO: test
function gcf() {
  local commit
  commit=$(git_find_sha $*)
  if (( $? < 1 )); then
    if git_rebasable "$commit^" && ga; then
      echodo git commit --fixup "$commit" && ( ! git_rebasing && git_autolint_head && git_rebase_i "$commit^" )
    fi
  else
    return 1
  fi
}

function gcfp() {
  gcf "$*" && gpf
}
function gcpf() {
  gcfp "$*"
}

# `gc [<message>]` git commit
# patch add, then commit with <message> or open editor for a message
function gc() {
  if (( $# == 0 )); then
    ga && echodo git commit --verbose && ( git_rebasing || git_autolint_head )
  else
    ga && echodo git commit -m "$*" && ( git_rebasing || git_autolint_head )
  fi
}

# `gcp [<message>]` git commit push
# patch add, then commit with <message> or open editor for a message, then push
function gcp() {
  gc "$*" && gp
}

# `glp [<remote>]` git pull push
# pull then push the current branch to <remote> or origin
function glp(){
  gl "$@" && gp "$@"
}

# `grp [<remote>]` git pull push
# pull using rebase, then push the current branch to <remote> or origin
function grp(){
  glr "$@" && gp "$@"
}

function grmp(){
  grm && gpf
}
function grpf(){
  grmp
}
function grmpf(){
  grmp
}


# `gp [<remote>] [<options>]` git push
# push the current branch to <remote> or origin
function gp(){
  local remote=${1:-origin}
  local branch=$(git_branch_name)
  local options=${@:2}
  if [[ "$branch" == "$(git_branch_name)" && "$remote" == "origin" ]]; then
    local set_upstream="--set-upstream"
  fi
  echodo git push $options $set_upstream "$remote" "$branch"

  if [[ ! -z "$(cc_menu_item_server_urls)" ]]; then
    cc_menu_add
  fi
}


# `gpf [<remote>]` git push force
# force push the current branch to <remote> or origin
function gpf(){
  local remote=${1:-origin}
  git_non_release_branch && gp "$remote" --force-with-lease
}

function gpr(){
  gp && git_pr
}

function gpfr() {
  gpf && git_pr
}

# `gl [<remote>] [<branch>]` git pull
# pull <branch> or the current branch from <remote> or origin
function gl(){
  local remote=${1:-origin}
  local branch=${2:-$(git_branch_name)}
  echodo git pull --no-edit "$remote" "$branch"
}

# `glf [<remote>] [<branch>]` git pull force
# force pull <branch> or the current branch from <remote> or origin
function glf() {
  local remote=${1:-origin}
  local branch=${2:-$(git_branch_name)}
  echodo git fetch "$remote" "$branch" && echodo git reset --hard "$remote"/"$branch"
}

# `glm` git pull main
# switch to main branch and pull
function glm() {
  gb "$(git_main_branch)" && gl
}

# `gm <branch>` git merge
# merge the latest of <branch> or main branch into the current branch
# TODO: allow merging directly from any origin
function gm() {
  local branch=${1:-"$(git_main_branch)"}
  echodo git fetch origin "$branch" && echodo git merge origin/"$branch" --no-edit
}

function gmm() {
  gm "$(git_main_branch)"
}

# `gmc` git merge conflicts
# load the merge conflicts into the editor, then once the issues are resolved, commit the merge.
# TODO: only allow to run during a merge
# TODO: more tests
function gmc() {
  git_handle_conflicts
  echodo git commit --no-verify --no-edit
}

# `gr [<branch or commit>]` git rebase
# rebase the current branch against <branch or commit> or latest main branch
# TODO: if it's a commit, don't checkout the latest
# TODO: don't switch branches if you don't have to
function gr() {
  local base=${1:-"$(git_main_branch)"}
  gb "$base" && gl && gbb && git_rebase_i "$base"
}

function grm() {
  if git_has_upstream; then
    git_non_release_branch && gb "$(git_main_branch)" && glf upstream && gp && gbb && git_rebase_i "$(git_main_branch)"
  else
    gr
  fi
}

# `grc` git rebase conflicts
# load the rebase conflicts into an editor, then once issues are resolved, continue the rebase.
# TODO: only allow to run during a rebase
# TODO: more tests
function grc() {
  if git_rebasing; then
    git_handle_conflicts &&
      git_commit_during_rebase &&
      GIT_EDITOR=true echodo git rebase --continue
  else
    echoerr "Not rebasing"
  fi
}

function grcr {
  grc || grcr
}

# git rebase branch
function grb() {
  git_can_autostash && (
    git rebase --interactive --autostash --autosquash $(git_branch_fork_point) || grc
  )
}
function gbr() {
  grb "$@"
}

function gs() {
  [[ -e .git/MERGE_HEAD ]] && git merge --abort
  git_stash "$@"
}

# TODO: test
function git_bisect_branch() {
  if echodo "$@"; then
    echo_green HEAD passes
  else
    echodo git bisect reset # TODO: don't do this if you're not bisecting so there's no error
    echodo git bisect start
    echodo git bisect bad
    echodo git checkout "$(git_branch_fork_point)"
    if echodo "$@"; then
      echodo git bisect good
      git bisect run bash -cl "echodo $*"
      echodo git bisect reset
    else
      echodo git bisect reset
      echoerr 'This whole branch fails'
    fi
  fi
}

function git_bisect() {
  if echodo "${@:2}"; then
    echo_green HEAD passes
  else
    echodo git bisect reset # TODO: don't do this if you're not bisecting so there's no error
    echodo git bisect start
    echodo git bisect bad
    echodo git checkout "$1"
    if echodo "${@:2}"; then
      echodo git bisect good
      git bisect run bash -cl "echodo ${@:2}"
      echodo git bisect reset
    else
      echodo git bisect reset
      echoerr 'This whole branch fails'
    fi
  fi
}

function gd {
  git diff $*
}
function gdm {
  gd "$(git_main_branch)"
}
function gdpf {
  gd origin/$(git_branch_name)..HEAD
}
