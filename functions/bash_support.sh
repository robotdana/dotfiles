# echo "required bash_support"
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

function last_command_style() {
  if (( $? == 0 )); then
    echo -en "\033[1m"
  else
    echo -en "\033[2m"
  fi
}

# do quotes manually here for aesthetics
# everywhere actually use the output, find another way
function echodo(){
  local space="$C_GREY"
  for string in "$@"; do
    echo -en "$space" >&2

    if [[ -z "$string" ]]; then
      echo -n "''" >&2
    elif [[ "$string" =~ \'|\"|\ |\&|\{|\}|\(|\)|\[|\]|\$|\<|\>|\||\;|$'\n' ]]; then
      if [[ "$string" =~ \' ]]; then
        echo -n \""${string//\"/\\\"}"\" >&2
      else
        echo -n \'"$string"\' >&2
      fi
    else
      echo -n "$string" >&2
    fi

    space=" "
  done
  echo -e "$C_RESET" >&2

  "$@"
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
    ( cd ~/.dotfiles/test && bats/bin/bats *.bats )
    if (( $? == 0 )); then
      echo $(last_test_modification) > ~/.dotfiles/test/.last_successful_test
    fi
  else
    ( cd ~/.dotfiles/test && bats/bin/bats ${@/%/.bats} )
  fi
  cd $PWD
}

function last_test_modification {
  stat -f %m ~/.dotfiles/{functions/bash_support.sh,functions/git_*.sh,test/*.bats,test/helper.bash} | sort -rn | head -n 1 || 0
}

function check_untested_bash_profile {
  if ( cd ~/.dotfiles && ! ( git_status_clean && git_head_pushed ) ); then
    if (( $(cat ~/.dotfiles/test/.last_successful_test) < $(last_test_modification) )); then
      echoerr "Don't forget to run bash tests (bt)"
    else
      echoerr "Don't forget to push ~/.dotfiles (gdot)"
    fi
  fi
}

function prompt_version {
  ruby_version="$(prompt_ruby_version | cut -d. -f1,2)"
  node_version="$(prompt_node_version | cut -d. -f1,2)"
  if [[ ! -z "$ruby_version" ]] && [[ ! -z "$node_version" ]]; then
    echo -ne "{r$ruby_version,n$node_version}"
  elif [[ ! -z "$ruby_version" ]]; then
    echo -ne "{r$ruby_version}"
  elif [[ ! -z "$ruby_version" ]]; then
    echo -ne "{n$node_version}"
  fi
}

function prompt_ruby_version {
  if [ -f Gemfile ]; then
    ruby --version | cut -d' ' -f 2 | cut -dp -f1
  fi
}

function prompt_node_version {
  if [ -f package.json ]; then
    nvm current | colrm 1 1 | cut -d. -f1,2
  fi
}
function prompt_git_color {
  if git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null; then
    if git_status_clean; then
      if git_head_pushed; then
        echo -ne "$C_AQUA"
      else
        echo -ne "$C_GREEN"
      fi
    else
      echo -ne "$C_YELLOW"
    fi
  else
    echo -ne "$C_WHITE"
  fi
}
function prompt_git {
  if git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null; then
    local ref
    local color

    ref=$(git_current_branch 2>/dev/null)
    if [[ $ref == 'HEAD' ]]; then
      ref=$(git branch --format='%(refname:short)' --sort=-committerdate --contains HEAD 2>/dev/null | head -n 1)
      local subref="$(git rev-parse --short HEAD 2>/dev/null)"

      if [[ ! -z $subref ]]; then
        ref="$ref[$subref]"
      fi
    fi

    echo -ne ":$ref"
  fi
}

alias default_latest_ruby="ls ~/.rubies | grep ruby- | sort -t- -k2,2 -n | tail -1 | cut -d '/' -f 1 > ~/.ruby-version"

function clear_all {
  printf '\33c\e[3J'
}

function cdp {
  cd ~/Projects/"$1"
}
function killchrome {
  killall Google\ Chrome 2>/dev/null
  killall chromedriver 2>/dev/null
}
