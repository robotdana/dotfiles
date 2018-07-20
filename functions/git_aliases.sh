# source ./git_support.sh

# `ga` git add
# interactively add, including new files
# TODO: cope with binary files
function ga() {
  git_track_untracked
  git_status_clean || echodo git add -p
}

# `gbn <new branch name>` git branch new
# creates a branch named <new branch name> based on latest master
# and switches to it.
function gbn() {
  if [[ "$*" == "dana/"* ]]; then
    local new_branch_name=$*
  else
    local new_branch_name=dana/$*
  fi
  glm
  echodo git checkout -b "$new_branch_name" master
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

# `gbm` git branch master
# switches to master
function gbm() {
  gb master
}

# `gbl [<base branch>]` git branch log
# list commits added to this branch since forked from <base branch> or master.
function gbl() {
  local base_branch=${1:-master}
  echodo git log --oneline $(git_log_range "$base_branch")
}

# `gbf <filename> [<base branch>]` git branch file
# shows commits modifying <filename> since this branch forked from <base_branch> or master.
function gbf() {
  local filename=$1
  local base_branch=${2:-master}
  echodo git log --oneline --follow --patch $(git_log_range "$base_branch") -- "$filename"
}

# `gwip` git wip
# commit everything carelessly with the message `wip`
function gwip(){
  git_non_release_branch && echodo git add . && echodo git commit --no-verify -m "WIP [skip ci]"
}

# `gwipp` git wip
# commit everything carelessly with the message `wip`, then push
function gwipp() {
  gwip && gp
}

function gunwip() {
  if [[ "$(git log --format="%an | %s" -n 1)" == "Dana Sherson | WIP [skip ci]" ]]; then
    git uncommit
    git unstage
  fi
}

# `gcf [<commit>]` git commit fix
# fixups <commit> or the last commit & rebases
function gcf() {
  local commit=$(find_sha $*)
  if [ -z "$commit" ]; then
    git_rebasable_quick HEAD^ && ga && echodo git commit --amend --no-edit
  else
    git_rebasable_quick "$commit^" && ga && echodo git commit --fixup "$commit" && git_rebase_i "$commit^"
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
  if [ -z "$1" ]; then
    ga && echodo git commit --verbose
  else
    ga && echodo git commit -m "$*"
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


# `gp [<remote>] [<options>]` git push
# push the current branch to <remote> or origin
function gp(){
  local remote=${1:-origin}
  local branch=$(git_current_branch)
  local options=${@:2}
  echodo git push $options "$remote" "$branch"
}


# `gpf [<remote>]` git push force
# force push the current branch to <remote> or origin
function gpf(){
  local remote=${1:-origin}
  git_non_release_branch && gp "$remote" --force-with-lease
}

# `gl [<remote>] [<branch>]` git pull
# pull <branch> or the current branch from <remote> or origin
function gl(){
  local remote=${1:-origin}
  local branch=${2:-$(git_current_branch)}
  echodo git pull --no-edit "$remote" "$branch"
}

# `glf [<remote>] [<branch>]` git pull force
# force pull <branch> or the current branch from <remote> or origin
function glf() {
  local remote=${1:-origin}
  local branch=${2:-$(git_current_branch)}
  echodo git fetch "$remote" "$branch" && echodo git reset --hard "$remote"/"$branch"
}

# `glr [<remote>] [<branch>]` git pull rebase
# rebase pull <branch> or the current branch from <remote> or origin
function glr() {
  local remote=${1:-origin}
  local branch=${2:-$(git_current_branch)}
  echodo git fetch "$remote" "$branch" && gr "$remote"/"$branch"
}

# `glm` git pull master
# switch to master and pull
function glm() {
  gb master && gl master
}

# `gm <branch>` git merge
# merge the latest of <branch> or master into the current branch
# TODO: allow merging directly from any origin
function gm() {
  local branch=${1:-master}
  echodo git fetch origin "$branch" && echodo git merge origin/"$branch" --no-edit
}

function gmm() {
  gm master
}

# `gmc` git merge conflicts
# load the merge conflicts into the editor, then once the issues are resolved, commit the merge.
# TODO: only allow to run during a merge
function gmc() {
  git_handle_conflicts
  echodo git commit --no-verify --no-edit
}

# `gr [<branch or commit>]` git rebase
# rebase the current branch against <branch or commit> or latest master
# TODO: if it's a commit, don't checkout the latest
# TODO: don't switch branches if you don't have to
function gr() {
  local base=${1:-master}
  gb "$base" && gl && gbb && git_rebase_i "$base"
}

function grm() {
  gr master
}

# `grc` git rebase conflicts
# load the rebase conflicts into an editor, then once issues are resolved, continue the rebase.
# TODO: only allow to run during a rebase
function grc() {
  git_handle_conflicts
  GIT_EDITOR=true echodo git rebase --continue
}

function gs() {
  git status
}

function gt() {
  git_untrack_new_blank && git stash -u "$@"
}

function gbt() {
  gbc bundle exec rspec --format documentation --fail-fast "$@"
}

# TODO: do in bash -c land so i have my aliases.
function gbc() {
  if echodo "$@"; then
    echo_green HEAD passes
  else
    echodo git bisect reset # TODO: don't do this if you're not bisecting so there's no error
    echodo git bisect start
    echodo git bisect bad
    echodo git checkout "$(git log --format=%H master..HEAD | tail -n 1)"
    if echodo "$@"; then
      echodo git bisect good
      echodo git bisect run "$@"
      echodo git bisect reset
    else
      echodo git bisect reset
      echoerr 'This whole branch fails'
    fi
  fi
}
