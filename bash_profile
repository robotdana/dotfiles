# ALIASES FOREVER
alias ls="ls -FG"

alias resource="source ~/.bash_profile && echo \"••• RELOADED PROFILE •••\""
alias rehosts="dscacheutil -flushcache && sudo killall mDNSResponder && echo \"••• RELOADED HOSTS •••\""

alias sbash="subl -nw ~/.dotfiles/marketplacer.sh ~/.gitconfig ~/.gemrc ~/.bash_profile && resource"
alias snginx='subl -nw /usr/local/etc/nginx/nginx.conf && nginx -s reload && echo "••• RELOADED CONFIG •••"'
alias shosts='subl -nw /etc/hosts && rehosts && echo "••• RELOADED HOSTS •••"'

alias publickey='pbcopy < ~/.ssh/id_rsa.pub && echo "••• COPIED TO CLIPBOARD •••"'

alias redis_clear='echo "FLUSHALL" | redis-cli'
alias restart_mysql='brew services restart mysql'

alias block="~/.dotfiles/scripts/block.sh"
alias unblock="~/.dotfiles/scripts/unblock.sh"

alias default_latest_ruby="ls ~/.rubies | grep ruby- | sort -t- -k2,2 -n | tail -1 | cut -d '/' -f 1 > ~/.ruby-version"

# # # # # # # # #
# TERMINAL FUN  #

function gbash(){
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

alias gcp="gc && gp"
alias gcpp="gc && gpp"
alias ga="git trackuntracked && git add -p && git untracknewblank"
alias gac="gc"
alias current_branch="git rev-parse --symbolic-full-name --abbrev-ref HEAD 2>/dev/null"
function gwip(){
  git trackuntracked &&
  SKIP=RuboCop,ScssLint,EsLint git commit -am 'wip'
  gp
}

function gc() {
  if [ -z "$1" ]; then
    ga && git commit --verbose
  else
    ga && git commit -m $1
  fi
}

function gpp(){
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

function gfp(){
  if [ -z "$1" ]; then
    local remote="origin"
  else
    local remote=$1
  fi
  local branch=$(current_branch)
  git push -f $remote $branch
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

function gr(){
  local branch=$(current_branch)
  local target=$1
  git checkout $target && gl && git checkout $branch && git rebase --interactive --autosquash $target
}

alias grm="gr master"
alias grc="git add . && git rebase --continue"

# # # # # # # # # #
# Rails Shortcuts #

function rc(){
  title "Console"
  (bundle exec rails console) && title 'Terminal'
}

function rg(){
  bundle exec rails generate $*;
}

function rf(){
  title "Foreman"
  bundle exec foreman start;
}

function rgm(){
  subl -nw $(rg migration $* | tail -1 | colrm 1 16) && be rails db:migrate
}

function rfs(){
  ports_respond 3808 || ttab -G rf
  rs $* 3808
}

function rs(){
  if [ -z "$1" ]; then
    local port=3000
  else
    local port=$((3000 + $1))
  fi
  if [ -z "$2" ]; then
    local host="localhost"
  else
    local host="$2.lvh.me"
  fi
  kill_port $port
  title "Rails Server:$port"
  wait_for_port_then "open -g http://$host:$port" $port ${@:3}
  (bundle exec rails server -p $port --pid=tmp/pids/server$port.pid -b 0.0.0.0) && title 'Terminal';
}

function rt(){
  title "Rspec"
  bundle exec rspec $*
  title "! Rspec complete"
}

function be(){
  bundle exec $*
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
# NPM :(  #

alias npm_exec='PATH=$(npm bin):$PATH'
function ne(){
  npm_exec $*
}
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

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
