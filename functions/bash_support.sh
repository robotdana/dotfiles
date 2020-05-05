C_RED=$'\033[38;5;125m'
C_GREEN=$'\033[38;5;48m'
C_YELLOW=$'\033[38;5;227m'
C_BLUE=$'\033[1;34m'
C_AQUA=$'\033[1;36m'
C_GREY=$'\033[0;90m'
C_PINK=$'\033[38;5;199m'
C_RESET=$'\033[0m'
C_LIGHT_PINK=$'\033[38;5;205m'

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
function echo_pink(){
  echo -e "$C_PINK$@$C_RESET"
}

# `resource` reload bash profile
function resource(){
  echodo source ~/.bash_profile
}

function resource_if_modified_since(){
  if (( $1 < $(last_bash_profile_modification) )) ; then
    resource
  fi
}

function last_bash_profile_modification(){
  stat -f %m ~/.dotfiles/{bash_profile,functions/*.sh,locals/*} | sort -rn | head -n 1 || 0
}

function maybe_update_terminal_cwd {
  # Terminal.app has this function: no-one else does
  type -t update_terminal_cwd >/dev/null && update_terminal_cwd
}

# TODO: Test
function escape_spaces() {
  sed -E 's/([^\]) /\1\\ /g'
}

# TODO: Test
function escape_brackets() {
  sed -E 's/([^\])([()])/\1\\\2/g'
}

# Tested
function quote_lines() {
  while read -r line; do
    echo -e $(quote "$line")
  done
}

function last_command_style() {
  if (( $? == 0 )); then
    echo -en "\033[1m"
  else
    echo -en "\033[2m"
  fi
}

# Tested
function quote_array() {
  local space=""
  for string in "$@"; do
    echo -en "$space"
    quote "$string"
    space=" "
  done
  echo ""
}

# Tested
function quote() {
  if (( $# > 0 )); then
    local string=$*
    if [[ -z "$string" ]]; then
      echo -en '""'
    elif [[ "$string" = *"'"* ]]; then
      echo -en \""$(echo -en "$string" | sed -E 's/(["$])/\\\1/g')\""
    elif [[ "$string" =~ \ |\(|\)|\[|\]|\$ ]]; then
      echo -en "'$string'"
    else
      echo -en "$string"
    fi
  fi
}

# TODO: make this work with xargs
# TODO: Test
function echodo(){
  ( echo_grey $(quote_array "$@") )>&2
  eval $(quote_array "$@")
}

function echoerr(){
  ( echo_red $* )>&2
  return 1
}

function alias_frequency() {
  history | sed -E "s/ *[0-9]+\*? *[0-9 :-]+ *//" | sort | uniq -c | sort -rn | head -50
}

# TODO: test
function strip_color() {
  if (( $# == 0 )); then
    sed -E "/^[[:cntrl:]]\\[1;90m.*[[:cntrl:]]\\[0m$/d;s/([[:cntrl:]]\\[[0-9]{1,3}(;[0-9]{1,3})*m)//g"
  else
    echo -e "$@" | strip_color
  fi
}

function bt() {
  if (( $# == 0 )); then
    ( cd ~/.dotfiles/test && command bats *.bats )
    if (( $? == 0 )); then
      echo $(last_test_modification) > ~/.dotfiles/test/.last_successful_test
    fi
  else
    ( cd ~/.dotfiles/test && command bats ${@/%/.bats} )
  fi
  cd $PWD
}

function last_test_modification {
  stat -f %m ~/.dotfiles/{functions/bash_support.sh,functions/git_*.sh,test/*.bats,test/helper.bash} | sort -rn | head -n 1 || 0
}

function check_untested_bash_profile {
  if (( $(cat ~/.dotfiles/test/.last_successful_test) < $(last_test_modification) )); then
    echoerr "Don't forget to run bash tests (bt)"
  fi
}


function ruby_version_prompt {
  if [ -f Gemfile ]; then
    echo "{r$(ruby --version | cut -d' ' -f 2 | cut -d. -f 1,2)}"
  fi
}

alias default_latest_ruby="ls ~/.rubies | grep ruby- | sort -t- -k2,2 -n | tail -1 | cut -d '/' -f 1 > ~/.ruby-version"

function clear_all {
  printf '\33c\e[3J'
}
