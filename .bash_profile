C_GREEN="\e[1;32m"
C_RED="\e[1;31m"
C_YELLOW="\e[0;33m"
C_RESET="\e[0m"
C_AQUA="\e[1;36m"
C_BLUE="\e[1;34m"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

alias gs="git status"
alias gc="gs && git add -A && git commit --verbose"
alias gcp="gc && gp"
alias gcpp="gc && gpp"

alias current_branch=" git branch 2>/dev/null | grep '^*' | colrm 1 2 "

function gc(){
  if [ -z "$1" ]; then
    gs && git add -A && git commit --verbose
  else
    gs && git add -A && git commit -m "$1"
  fi
}
function gpp(){
  if [ -z "$1" ]; then
    local remote="origin"
  else
    local remote=$1
  fi
  local branch=$(current_branch)
  git pull $remote $branch && git push $remote $branch
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

function gl(){
  if [ -z "$1" ]; then
    local remote="origin"
  else
    local remote=$1
  fi
  local branch=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
  git pull $remote $branch
}

alias migrate="bundle exec rake db:migrate db:test:prepare"

alias rc="bundle exec rails console"
function rg(){
  bundle exec rails generate $*;
}
function rgm(){
  $GUI_EDITOR $(rg migration $* | tail -1 | colrm 1 16)
}
function rs(){
  if [ -z "$1" ]; then
    local port=3000
  else
    local port=$((3000 + $1))
  fi
  bundle exec rails server -p $port --pid=tmp/pids/server$1.pid;
}
function rsd(){
  if [ -z "$1" ]; then
    local port=3000
  else
    local port=$((3000 + $1))
  fi
    bundle exec rails server -p $port --pid=tmp/pids/server$port.pid --debugger;
}
function rk(){
  bundle exec rake $*;
}
function gb(){
  git branch $1 2> /dev/null || git checkout $1
}
alias keys="tail -n +1 -- ~/.ssh/*.pub"

alias s="$GUI_EDITOR"
alias ss="$GUI_EDITOR ./"
#
alias ls="ls -FG"

source ~/.git-completion.bash

PATH=/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH
#
# alias start_vmware="sudo /Library/Application\ Support/VMware\ Fusion/boot.sh --restart"
alias resource="source ~/.bash_profile && echo \"••• RELOADED PROFILE •••\""
alias start_mysql="mysql.server start"
alias start_postgres="pg_ctl -D /usr/local/var/postgres93 -l /usr/local/var/postgres93/server.log -m immediate restart"
alias start_elasticsearch="elasticsearch -D es.config=/usr/local/opt/elasticsearch/config/elasticsearch.yml -p /tmp/elasticsearch.pid"
alias start_nginx="sudo nginx"
alias start_redis="redis-server /usr/local/etc/redis.conf"
alias start_teg="start_nginx && start_elasticsearch && start_redis && start_mysql && foreman start"

alias shosts='sudo $EDITOR /etc/hosts && dscacheutil -flushcache && echo "••• RELOADED HOSTS •••"'
alias sbash="$EDITOR ~/.bash_profile && resource"
alias publickey='pbcopy < ~/.ssh/id_rsa.pub && echo "••• COPIED TO CLIPBOARD •••"'

function __git_dirty_branch {
  git diff --quiet HEAD &>/dev/null;
  if [[ $? == 1 ]]; then
    local branch=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
    [[ $branch ]] && echo ":$branch"
  fi
}
function __git_clean_branch {
  git diff --quiet HEAD &>/dev/null;
  if [[ $? != 1 ]]; then
    local branch=$(git branch 2>/dev/null | grep '^*' | colrm 1 2)
    [[ $branch ]] && echo ":$branch"
  fi
}

export PS1="\[$C_BLUE\]\w\[$C_RED\]\$(__git_dirty_branch)\[$C_GREEN\]\$(__git_clean_branch)\[$C_BLUE\]» \[$C_RESET\]"

if [[ -a $HOME/.rvm ]]; then
  [[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm
fi
if [[ -a $HOME/.rbenv ]]; then
  eval "$(rbenv init -)"
fi

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
export GUI_EDITOR='/usr/local/bin/atom'
export EDITOR='/usr/local/bin/atom -wn'
source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh
export ATOM_PATH="/Applications"
export JAVA_HOME=/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home
