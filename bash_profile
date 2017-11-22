source ~/.dotfiles/locals/bash.sh

alias ls="ls -FG"

# `resource` reload bash profile
function resource(){
  echodo source ~/.bash_profile
}

# `rehosts` reload hosts file and clear caches
function rehosts(){
  echodo "dscacheutil -flushcache && sudo killall mDNSResponder"
}

function cdot() {
  if [[ $(current_repo) = "dotfiles" ]]; then
    echodo cd $OLDPWD
  else
    echodo cd ~/.dotfiles
  fi
}

# `sdot` edit select few dotfiles that have high churn, reload profile when they are closed.
function sdot() {
  echodo subl -nw ~/.dotfiles/marketplacer.sh ~/.bash_profile && resource
}

function ldot() {
  ( cdot && gl ) && resource
}

function gdot() {
  ( cdot && gc $* && gp )
}

# `snginx` edit the nginx config file & reload the config when closed.
function snginx(){
  echodo "subl -nw /usr/local/etc/nginx/nginx.conf && nginx -s reload"
}

# `shosts` edit the hosts file, reload hosts when it is closed
function shosts(){
  echodo subl -nw /etc/hosts && rehosts
}

function gauthors(){
  echodo "git shortlog -sen && git shortlog -secn"
}

function quote_lines(){
  while read line; do
    echo "\"$line\""
  done
}

function y(){
  echodo kill_port 3808
  echodo "ttab -G 'yarn start; exit'"
}

function yf(){
  echodo kill_port 3808
  echodo "ttab -G 'yarn && yarn start; exit'"
}

function prefix_relative_path(){
  while read line; do
    echo "./$line"
  done
}

# assign the newest ruby installed on the system to users ruby.
alias default_latest_ruby="ls ~/.rubies | grep ruby- | sort -t- -k2,2 -n | tail -1 | cut -d '/' -f 1 > ~/.ruby-version"
alias block="~/.dotfiles/scripts/block.sh"
alias unblock="~/.dotfiles/scripts/unblock.sh"

function new_mysql() {
  echodo docker run --name m-mysql -p '3306:3306' -e MYSQL_ROOT_PASSWORD=root mysql:5.7 --character-set-server=utf8mb4
}

# # # # # # # # #
# TERMINAL FUN  #

# stepping up and down through history with some text already written does a search instead
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# `title "Title"` Set the title of the current tab, including the vertical and some flowery bits
function title {
  printf "\033]0;%s\007" "••• $1 $(__dir_context) •••"
}

# `ttabs "command" "command2" "command3"...` open new tab to run each command
function ttabs(){
  local current_dir=$PWD
  for tab_command in "$@"
  do
    echodo ttab -G "\"cd $current_dir && $tab_command\""
  done
}

function echodo(){
  ( echo -e "\033[1;90m$*\033[1;39m" )>/dev/tty
  eval $*
}

function echoerr(){
  ( echo -e "\033[1;31m$*\033[1;39m" )>&2
  return 1
}

# # # # # # # # #
# GIT SHORTCUTS #

source ~/.dotfiles/locals/git-completion.bash

function git_track_untracked(){
  local untracked=$(git status --untracked=all --porcelain | grep -e "^??" | colrm 1 3 | prefix_relative_path | quote_lines)
  if [[ ! -z "$untracked" ]]; then
    echodo git add -N $untracked
  fi
}

function git_untrack_new_blank() {
  local newblank=$(git diff --cached --numstat --no-renames | grep -E "^0\t0\t" | cut -f 3 | prefix_relative_path | quote_lines)
  if [[ ! -z "$newblank" ]]; then
    echodo git reset $newblank
  fi
}

function git_conflicts() {
  git ls-files -u | awk '{print $4}' | sort -u | prefix_relative_path | quote_lines
}

function git_conflicts_with_line_numbers(){
  git_conflicts | xargs grep -nHo '<<<<<<<' | sed 's/:<<<<<<<//' | quote_lines
}

function git_open_conflicts() {
  local active_conflicts=$(git_conflicts_with_line_numbers)
  if [[ ! -z "$active_conflicts" ]]; then
    echodo subl -nw $active_conflicts && git_open_conflicts
  fi
}

function git_add_conflicts() {
  # TODO: sometimes the conflict is one is deleted, and I want deletion.
  echodo git add $(git_conflicts)
}

function git_purge() {
  glm
  echodo git fetch -p
  local local_merged=$(git branch --merged | colrm 1 2 | grep -Ev '^(master|release/.*|demo/.*)$' | quote_lines)
  local remote_tracking_merged=$(git branch -r --merged | colrm 1 2 | grep -Ev '^origin/(master|release/.*|demo/.*)$' | quote_lines)
  if [[ ! -z "$local_merged" ]]; then
    echodo git branch -d $local_merged
  fi
  if [[ ! -z "$remote_tracking_merged" ]]; then
    echodo git branch -rd $remote_tracking_merged
  fi
}


# `ga` interactive add, including new files
function ga() {
  git_track_untracked && echodo git add -p && git_untrack_new_blank
}

# `current_branch` the current branch name
function current_branch() {
  git rev-parse --symbolic-full-name --abbrev-ref HEAD 2>/dev/null
}

function current_repo() {
  basename $(git config --get remote.origin.url 2>/dev/null) .git
}

function gbn() {
  glm && echodo git checkout -b $*
}

function gb() {
  echodo git checkout $*
}
__git_complete gb __git_complete_refs

function gbb() {
  gb -
}

function gbm() {
  gb master
}

# `gbl` list commits added to this branch since forked from master
# `gbl branch` list commits added to this branch since forked from the given branch
# `gbl branch filename` list commits that change this file since forked from the given branch.
function gbl() {
  local other_branch=${1:-master}
  local branch=$(current_branch)
  local filename=$2
  if [ "$branch" = "$other_branch" ]; then
    echodo git log --oneline -- $filename
  else
    echodo git log --oneline $other_branch..HEAD -- $filename
  fi
}
__git_complete gbl __git_complete_refs

# `gwip` will commit everything carelessly with the message `wip`
function gwip(){
  local branch=$(current_branch)
  if [ "$branch" = "master" ]; then
    echoerr Tried to push wip to master
  else
    echodo "git add ."
    echodo "OVERCOMMIT_DISABLE=1 git commit -m 'wip [skip ci]'"
  fi
}
function gwipp() {
  gwip && gp
}

# `gcf` amends the last commit
# `gcf commit-ish` fixups that commit & rebase
function gcf() {
  local commit=$1
  if [ -z "$commit" ]; then
    git_rebasable HEAD^ && ga && echodo git commit --amend --no-edit
  else
    git_rebasable $commit^ && ga && echodo git commit --fixup $commit && echodo GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash --autostash $commit^
  fi
}

# `gc` add with patches patch, then open an editor for a commit message
# `gc message goes here without quotes` will add patch, then commit with that message.
function gc() {
  if [ -z "$1" ]; then
    ga && echodo git commit --verbose
  else
    ga && echodo "git commit -m \"$*\""
  fi
}

# `glp` will pull and push the current branch to origin
# `glp remote` will pull and push the current branch to the given remote
function glp(){
  gl $* && gp $*
}
__git_complete glp __git_complete_remote_or_refspec

# `gp` will push the current branch to origin
# `gp remote` will push the current branch to the given remote
function gp(){
  local remote=${1:-origin}
  local branch=$(current_branch)
  echodo git push $remote $branch
}
__git_complete gp __git_complete_remote_or_refspec

# `gpf` will force push the current branch to origin
# `gpf remote` will force push the current branch to the given remote
function gpf(){
  local remote=${1:-origin}
  local branch=$(current_branch)
  if [ "$branch" = "master" ]; then
    echoerr Tried to force push master
  else
    echodo git push --force $remote $branch
  fi
}
__git_complete gpf __git_complete_remote_or_refspec

# `gl` will pull the current branch from origin
# `gl remote` will pull the current branch from the given remote
function gl(){
  local remote=${1:-origin}
  local branch=${2:-$(current_branch)}
  echodo git pull --no-edit $remote $branch
}
__git_complete gl __git_complete_remote_or_refspec

# git pull force
function glf() {
  local remote=${1:-origin}
  local branch=${2:-$(current_branch)}
  echodo git fetch && echodo git reset --hard $remote/$branch
}
__git_complete glf __git_complete_remote_or_refspec

# `glm` switch to master & pull from origin
function glm() {
  gb master && gl
}

# `gm branch` will merge the target branch `branch` into the current branch
function gm(){
  local target=$1
  gb $target && gl && gbb && echodo git merge $target --no-edit
}
__git_complete gm __git_complete_refs

# `gmm` will merge master into the current branch
alias gmm="gm master"

# to be called during a merge
# `gmc` load the merge conflicts into an editor, then once files are closed from the editor commit the merge.
function gmc {
  git_open_conflicts && git_add_conflicts && echodo "OVERCOMMIT_DISABLE=1 git commit --no-edit"
}

# `git_rebasable` checks that no commits added since this was branched from master have been merged into release/* demo/*
# `git_rebasable commit-ish` checks that no commits added since `commit-ish` have been merged into something release-ish
function git_rebasable() {
  local base=${1:-master}
  # TODO, forcepull all demo, release/, and master branches. then compare
  # compares commits_since_base to commits_to_release. if there are no commits in common allow rebasing
  if [[ ! -z "$(comm -12 <( git log --format=%H $base..HEAD | sort ) <( git log --format=%H $(git branch --list --all --no-color {demo/*,release/*,master} | colrm 1 2) --not master | sort ))" ]]; then
    echoerr some commits were merged to a demo or release branch, only merge from now on
  fi
}

# `gr target_branch` gets the latest version of the target branch & rebases on top of that
function gr() {
  local target=$1
  git_rebasable $target && gb $target && gl && gbb && GIT_SEQUENCE_EDITOR=: echodo git rebase --interactive --autosquash --autostash $target
}
__git_complete gr __git_complete_refs

# `grm` gets the latest version of master & rebases on top of that
alias grm="GIT_SEQUENCE_EDITOR=: gr master"

# to be called during a rebase
# `grc` load the rebase conflicts into an editor, then once files are saved from the editor continue the rebase.
function grc() {
  git_open_conflicts && git_add_conflicts && echodo git rebase --continue
}

# # # # # # # # # #
# Rails Shortcuts #

# `rd` migrate the database
function rd() {
  echodo bundle exec rake db:migrate
}

# `rc` open a rails console
function rc(){
  echodo rails console && title 'Terminal'
}

# `rg whatever would get passed to rails generate` run rails generate
function rg(){
  echodo rails generate $*
}

# `rgm MigrationName` open the migration file, then when the file is closed, run the migration.
function rgm(){
  local filename=$(rg migration $* | awk '/db\/migrate/ {print $2}')
  if [[ ! -z $filename ]]; then
    echodo subl -nw $filename && rd
  fi
}

# `rf` start foreman.
function rf(){
  title "Foreman"
  echodo bundle exec foreman start
}

# `rfs [arguments that would be passed to rs]`, start foreman if needed & start a rails server, waiting for webpack.
function rfs(){
  ports_respond 3808 || echodo ttab -G rf
  rs $* 3808
}

# `rds` migrate the database, but skip the schema dump
function rds(){
  SKIP_SCHEMA_DUMP=1 rd && gb db/schema.rb
}

# `rdt` migrate the test database, but skip the schema dump
function rdt(){
  RAILS_ENV=test rd && gb db/schema.rb
}

function rails_port(){
  local number=${1:-0}
  echo $((3000 + $number))
}

function localhost_name_from(){
  if [ -z "$1" ]; then
    echo localhost
  else
    echo $1.lvh.me
  fi
}

# `rs port1 host path port2 port3 port4...` start a rails server on port1, then after all ports are responding, open host.lvh.mepath:port1 in a browser
# `rs port` start a rails server on port1, then after the server is started, open localhost:port in a browser
# `rs` start a rails server on 3000, then after the server is started, open localhost:3000 in a browser
function rs(){
  local port=$(rails_port $1)
  local host=$(localhost_name_from $2)
  local path=$3
  local ports_to_wait_for=${@:4}

  echodo kill_port $port
  title "Rails Server:$port"
  wait_for_port_then "echodo open -g http://$host:$port$path" $port $ports_to_wait_for
  echodo rails server -p $port --pid=tmp/pids/server$port.pid -b 0.0.0.0 && title 'Terminal'
}

# `rt [arguments that would be passed to rspec]` shortcut for rspec.
function rt(){
  title "Rspec running"
  echodo bundle exec rspec -f d $* && title "Terminal"
}

# TODO get this working
function rtf(){
  local buildfailures=$(m build failures | grep -o -e " spec/.*" | sort)
  if [ ! -z "$1" ]; then
    local buildfailures=$(echo $buildfailures | grep -o -e " $1.*")
  fi

  if [ ! -z "$buildfailures" ]; then
    echo "••• running $(echo $buildfailures | wc -w | tr -d ' ') test(s) •••"
    rt --fail-fast "$buildfailures"
  fi
}

# # # # # # # #
# SERVER FUN  #
# `ports_respond port1 port2 port3...` returns boolean if all the ports are running a process
function ports_respond(){
  local respond=true
  for port in "$@"; do
    if [[ ! $(lsof -ti :$port) ]]; then
      local respond=false
    fi
  done
  $respond
}

# `wait_for_ports port1 port2 port3...` sleeps until all the ports are running a process
function wait_for_ports(){
  until ( ports_respond $* ); do sleep 1; done
}

# `wait_for_ports_then "command" port1 port2 port3...` runs command once all the ports are running a process.
function wait_for_port_then(){
  local cmd=$1
  local ports=${@:2}
  ( wait_for_ports $ports && eval $cmd & ) >/dev/null
}

# `kill_port port` kills the process running the given port.
function kill_port() {
  local port=$1
  lsof -ti :$port | xargs kill -9
}

# `jeks` start a jekyll server on 4000, then after the server is started, open localhost:4000 in a browser
function jeks(){
  title "Jekyll Server:4000"
  wait_for_port_then "echodo open -g http://localhost:4000" 4000
  echodo bundle exec jekyll serve --incremental && title 'Terminal'
}

# # # # # #
# Prompt  #

function __git_dirty_branch {
  git diff --quiet HEAD &>/dev/null;
  if [[ $? == 1 ]]; then
    local branch=$(current_branch)
    [[ $branch ]] && echo ":$branch"
  fi
}

function __git_clean_branch {
  git diff --quiet HEAD &>/dev/null;
  if [[ $? != 1 ]]; then
    local branch=$(current_branch)
    [[ $branch ]] && echo ":$branch"
  fi
}

function __dir_context {
  if [[ $(current_repo) = "marketplacer" ]]; then
    echo "($(short_vertical))"
  fi
}

C_GREEN="\e[1;32m"
C_RED="\e[1;31m"
C_YELLOW="\e[0;33m"
C_RESET="\e[0m"
C_AQUA="\e[1;36m"
C_BLUE="\e[1;34m"
export PS1="\[$C_BLUE\]\w\[$C_AQUA\]\$(__dir_context)\[$C_RED\]\$(__git_dirty_branch)\[$C_GREEN\]\$(__git_clean_branch)\[$C_BLUE\]» \[$C_RESET\]"

# # # # # #
# Exports #
export PATH=/usr/local/heroku/bin:/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH

source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh
chruby 2.3.1

export GUI_EDITOR='/usr/local/bin/subl -nw'
export EDITOR='/usr/local/bin/subl -nw'
export JAVA_HOME="/Library/Internet\\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"
