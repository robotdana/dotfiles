C_RED="\033[1;31m"
C_GREEN="\033[1;32m"
C_YELLOW="\033[0;33m"
C_BLUE="\033[1;34m"
C_AQUA="\033[1;36m"
C_GREY="\033[1;90m"

C_RESET="\033[0m"

function echo_red(){
  echo -e "$C_RED$@$C_RESET"
}
function echo_green(){
  echo -e "$C_GREEN$@$C_RESET"
}
function echo_yellow(){
  echo -e "$C_YELLOW$@$C_RESET"
}
function echo_blue(){
  echo -e "$C_BLUE$@$C_RESET"
}
function echo_aqua(){
  echo -e "$C_AQUA$@$C_RESET"
}
function echo_grey(){
  echo -e "$C_GREY$@$C_RESET"
}
function echo_reset(){
  echo -e "$C_RESET$@$C_RESET"
}

# `resource` reload bash profile
function resource(){
  echodo source ~/.bash_profile
}

function resource_if_modified_since(){
  if (( $* < $(last_bash_profile_modification) )) ; then
    resource
  fi
}

function last_bash_profile_modification(){
  stat -f %m ~/.dotfiles/{bash_profile,functions/*.sh,locals/git-completion.bash} | sort -rn | head -n 1
}

function escape_spaces() {
  sed -E 's/([^\]) /\1\\ /g'
}

function escape_brackets() {
  sed -E 's/([^\])([()])/\1\\\2/g'
}

function quote_lines() {
  while read -r line; do
    echo "\"$line\""
  done
}

function quote_array() {
  for n in "$@"; do
    if [[ "$n" =~ "'" ]]; then
      echo -en "\"$n\" "
    elif [[ "$n" =~ ' ' ]] || [[ -z "$n" ]] || [[ "$n" =~ \(|\) ]]; then
      echo -en "'$n' "
    else
      echo -en "$n "
    fi
  done
  echo ""
}

function echodo(){
  ( echo_grey $(quote_array "$@") )>/dev/tty
  eval $(quote_array "$@")
}

function echoerr(){
  ( echo_red $* )>&2
  return 1
}

function alias_frequency() {
  history | sed -E "s/ *[0-9]+\*? *[0-9 :-]+ *//" | sort | uniq -c | sort -rn | head -50
}

function strip_color() {
  if (( $# == 0 )); then
    sed -E "s/[[:cntrl:]]\\[[0-9]{1,3}(;[0-9]{1,3})*m//g"
  else
    echo -e "$@" | sed -E "s/[[:cntrl:]]\\[[0-9]{1,3}(;[0-9]{1,3})*m//g"
  fi
}

alias default_latest_ruby="ls ~/.rubies | grep ruby- | sort -t- -k2,2 -n | tail -1 | cut -d '/' -f 1 > ~/.ruby-version"
