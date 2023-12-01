# echo "required bash_support"

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
  str=$'\033[0;90m'
  space=''
  for string in "$@"; do
    str="$str$space"

    if [[ -z "$string" ]]; then
      str="$str''"
    elif [[ "$string" =~ \'|\"|\ |\&|\{|\}|\(|\)|\[|\]|\$|\<|\>|\||\;|$'\n' ]]; then
      if [[ "$string" =~ \' ]]; then
        str="$str"\""${string//\"/\\\"}"\"
      else
        str="$str"\'"$string"\'
      fi
    else
      str="$str$string"
    fi

    space=" "
  done

  echo -e "$str\033[0m" >&2
  "$@"
}

function prompt_version {
  [[ -e Gemfile ]] && echo {r${RUBY_VERSION%.*}}
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
