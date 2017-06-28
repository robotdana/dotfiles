# ALIASES FOREVER
alias ls="ls -FG"

alias resource="source ~/.bash_profile && echo \"••• RELOADED PROFILE •••\""
alias rehosts="dscacheutil -flushcache && sudo killall mDNSResponder && echo \"••• RELOADED HOSTS •••\""

alias sdot="subl -nw ~/.dotfiles/marketplacer.sh ~/.gitconfig ~/.gemrc ~/.bash_profile && resource"
alias snginx='subl -nw /usr/local/etc/nginx/nginx.conf && nginx -s reload && echo "••• RELOADED CONFIG •••"'
alias shosts='subl -nw /etc/hosts && rehosts && echo "••• RELOADED HOSTS •••"'

alias publickey='pbcopy < ~/.ssh/id_rsa.pub && echo "••• COPIED TO CLIPBOARD •••"'

alias redis_clear='echo "FLUSHALL" | redis-cli'
alias restart_mysql='brew services restart mysql'

alias block="~/.dotfiles/scripts/block.sh"
alias unblock="~/.dotfiles/scripts/unblock.sh"

alias default_latest_ruby="ls ~/.rubies | grep ruby- | sort -t- -k2,2 -n | tail -1 | cut -d '/' -f 1 > ~/.ruby-version"

# `restart_mysql` I kept typing these arguments in the wrong sequence.
alias restart_mysql='(brew services restart mysql) && wait_for_mysql'
alias wait_for_mysql='until ( mysql_works ); do sleep 1; done'
alias mysql_works='echo "\q" | mysql 2>/dev/null'

function restart_mysql_if_crashed() {
  mysql_works || restart_mysql
}

# # # # # # # # #
# TERMINAL FUN  #

function gdot(){
  local current_dir=$PWD
  cd ~/.dotfiles
  gc
  cd $current_dir
}

# stepping up and down through history with some text already written does a search instead
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

# Set the title of the current tab
function title {
  printf "\033]0;%s\007" "••• $1 $(__dir_context) •••"
}

function ttabs(){
  local current_dir=$PWD
  for tab_command in "$@"
  do
    ttab -G 'cd $current_dir && $tab_command'
  done
}

# # # # # # # # #
# GIT SHORTCUTS #

source ~/.dotfiles/locals/git-completion.bash

alias ga="git trackuntracked && git add -p && git untracknewblank"
alias current_branch="git rev-parse --symbolic-full-name --abbrev-ref HEAD 2>/dev/null"

function gb() {
  glm && git checkout -b $*
}

function gbl() {
  if [ -z "$1" ]; then
    local parent="master"
  else
    local parent=$1
  fi
  git log --oneline $parent..HEAD
}

function gwip(){
  local branch=$(current_branch)
  if [ "$branch" = "master" ]; then
    echo '••• Tried to push wip to master •••'
  else
    git add .
    local last_commit=$(git log -n 1 --pretty=format:%s)
    if [[ $last_commit = 'wip [skip ci]' ]]; then
      SKIP=RuboCop,ScssLint,EsLint gcf
      gpf
    else
      SKIP=RuboCop,ScssLint,EsLint git commit -am 'wip [skip ci]'
      gp
    fi
  fi
}

function gcf() {
  if [ -z "$1" ]; then
    rebasable HEAD^ && ga && git commit --amend --no-edit
  else
    rebasable $1^ && ga && git commit --fixup $1 && GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash --autostash $1^
  fi
}

function gc() {
  if [ -z "$1" ]; then
    ga && git commit --verbose
  else
    ga && git commit -m "$*"
  fi
}

function glp(){
  if [ -z "$1" ]; then
    local remote="origin"
  else
    local remote=$1
  fi
  local branch=$(current_branch)
  gl $remote && git push $remote $branch
}

function gp(){
  if [ -z "$1" ]; then
    local remote="origin"
  else
    local remote=$1
  fi
  local branch=$(current_branch)
  git push $remote $branch
}

function gpf(){
  if [ -z "$1" ]; then
    local remote="origin"
  else
    local remote=$1
  fi
  local branch=$(current_branch)
  if [ "$branch" = "master" ]; then
    echo '••• Tried to force push master •••'
  else
    git push --force $remote $branch
  fi
}

function gl(){
  if [ -z "$1" ]; then
    local remote="origin"
  else
    local remote=$1
  fi
  local branch=$(current_branch)
  git pull --no-edit $remote $branch
}
alias glm="git checkout master && gl"

function gm(){
  local branch=$(current_branch)
  local target=$1
  git checkout $target && gl && git checkout $branch && git merge $target --no-edit
}

alias gmm="gm master"

function gmc {
  git openconflicts && git add $(git conflicts) && SKIP=RuboCop git commit --no-edit
}

function rebasable() {
  if [ -z "$1" ]; then
    local base="master"
  else
    local base=$1
  fi

  # compares commits_since_base to commits_to_office_and_staging. if there are no commits in common allow rebasing
  if [[ -z "$(comm -12 <( git log --format=%h $base..HEAD | sort ) <( git log --format=%h release/staging release/test --not master | sort ))" ]]; then
    true
  else
    echo "••• some commits were merged to staging or office, only merge from now on •••"
    false
  fi
}

function gr() {
  local branch=$(current_branch)
  local target=$1
  rebasable $target && git checkout $target && gl && git checkout $branch && git rebase --interactive --autosquash --autostash $target
}

alias grm="GIT_SEQUENCE_EDITOR=: gr master"

function grc() {
  git openconflicts && git add $(git conflicts) && git rebase --continue
}

# # # # # # # # # #
# Rails Shortcuts #

alias rd="bundle exec rake db:migrate && restart_mysql_if_crashed"

function rc(){
  rails console && title 'Terminal'
}

function rg(){
  rails generate $*;
}

function rgm(){
  subl -nw $(rg migration $* | grep db/migrate | colrm 1 16) && rd
}

function rf(){
  restart_mysql_if_crashed
  title "Foreman"
  bundle exec foreman start;
}

function rfs(){
  ports_respond 3808 || ttab -G rf
  rs $* 3808
}

function rds(){
  SKIP_SCHEMA_DUMP=1 rd && git checkout db/schema.rb
}

function rdt(){
  RAILS_ENV=test rd && git checkout db/schema.rb
}

function rails_port(){
  if [ -z "$1" ]; then
    echo "3000"
  else
    echo "$((3000 + $1))"
  fi
}

function localhost_name_from(){
  if [ -z "$1" ]; then
    echo "localhost"
  else
    echo "$1.lvh.me"
  fi
}

# `rs port1 host path port2 port3 port4...` start a rails server on port1, then after all ports are responding, open host.lvh.mepath:port1 in a browser
# `rs port` start a rails server on port1, then after the server is started, open localhost:port in a browser
# `rs` start a rails server on 3000, then after the server is started, open localhost:3000 in a browser
function rs(){
  local port=$(rails_port $1)
  local host=$(localhost_name_from $2)

  kill_port $port
  title "Rails Server:$port"
  wait_for_port_then "open -g http://$host:$port$3" $port ${@:4}

  rails server -p $port --pid=tmp/pids/server$port.pid -b 0.0.0.0 && title 'Terminal'
}

function rt(){
  title "Rspec running"
  rspec -f d $* && title "Terminal"
}

# # # # # # # #
# SERVER FUN  #
function ports_respond(){
  local respond=true
  for port in "$@"
  do
    if [ ! $(lsof -ti :$port) ]; then
      local respond=false
    fi
  done
  $respond
}

# This is probably a really bad idea
function wait_for_ports(){
  until ( ports_respond $* ); do sleep 1; done
}

# this too
function wait_for_port_then(){
  ( ( ( wait_for_ports ${@:2} ) && $($1) )>/dev/null & )2>/dev/null
}

# this three
function kill_port() {
  lsof -ti :$1 | xargs kill -9
}

function jeks(){
  title "Jekyll Server:4000"
  wait_for_port_then "open -g http://localhost:4000" 4000
  (bundle exec jekyll serve --incremental) && title 'Terminal'
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

source ~/.dotfiles/locals/bash.sh

function __dir_context {
  case $(pwd) in
    $MARKETPLACER_PATH) echo "($(short_vertical))";;
    *) echo "";;
  esac
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

PATH=/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH
export PATH="/usr/local/heroku/bin:$PATH"
export GUI_EDITOR='/usr/local/bin/subl -nw'
export EDITOR='/usr/local/bin/subl -nw'
export JAVA_HOME="/Library/Internet\\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"

source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh
