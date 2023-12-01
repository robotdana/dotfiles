alias ls="ls -FG"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

set +H

export COLOR_RED=$'\033[38;5;125m'
export COLOR_GREEN=$'\033[38;5;48m'
export COLOR_YELLOW=$'\033[38;5;227m'
export COLOR_BLUE=$'\033[1;34m'
export COLOR_AQUA=$'\033[1;36m'
export COLOR_GREY=$'\033[0;90m'
export COLOR_PINK=$'\033[38;5;199m'
export COLOR_RESET=$'\033[0m'
export COLOR_LIGHT_PINK=$'\033[38;5;205m'

export PATH="$HOME/.dotfiles/bin:$HOME/.cargo/bin:/usr/local/opt:/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH"
export EDITOR='code --wait'
export GUI_EDITOR=$EDITOR
export THOR_MERGE=$EDITOR' -d $1 $2'
export GPG_TTY=$(tty)
export BASH_SILENCE_DEPRECATION_WARNING=1

if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [[ -f ~/.cargo/env ]]; then
  source /Users/dana/.cargo/env
fi

source ~/.dotfiles/locals/secrets.sh
source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/node_support.sh
source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/hosts_support.sh
source ~/.dotfiles/functions/prompt_support.sh
source ~/.dotfiles/functions/server_support.sh
source ~/.dotfiles/functions/cc_menu_support.sh
source ~/.dotfiles/functions/ruby_support.sh
source ~/.dotfiles/functions/less_support.sh

source ~/.dotfiles/functions/git_aliases.sh
source ~/.dotfiles/functions/git_alias_completion.sh
source ~/.dotfiles/functions/dotfiles_aliases.sh
source ~/.dotfiles/functions/rails_aliases.sh
source ~/.dotfiles/functions/jekyll_aliases.sh
source ~/.dotfiles/functions/webpack_aliases.sh

PROMPT_COMMAND="maybe_update_terminal_cwd; resource_if_modified_since $(last_bash_profile_modification); check_untested_bash_profile; nvm_use_node_version"

if [ -d /usr/local/bin ] && [[ -f /usr/local/bin/direnv ]]; then
  # direnv hook bash. idk what it's doing but i'm sure it's fine

  _direnv_hook() {
    local previous_exit_status=$?;
    eval "$("/usr/local/bin/direnv" export bash)";
    return $previous_exit_status;
  };

  if ! [[ "${PROMPT_COMMAND:-}" =~ _direnv_hook ]]; then
    PROMPT_COMMAND="_direnv_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  fi
fi

function functionify {
  # process options

  local OPTIND=1
  local quiet
  while getopts ":q" opts; do
    case "$opts" in
      q) quiet=true; ;;
    esac
  done
  shift $((OPTIND - 1))

  # get bin path
  local path="$1"

  if [[ ! -e "$path" ]]; then
    path="$(which "$path")"
  fi

  # is it a bash file?
  local shebang="$(head -n 1 "$path")"
  if ! [[ "$shebang" =~ '#!'* ]] || \
    [[ 'bash' != "${shebang##*/}" ]] && \
    [[ '#!/usr/bin/env bash' != "$shebang" ]]; then

    echoerr "can't functionify $path, it's not a bash script"
    return 1
  fi

  local name="${path##*/}"
  unset -f "$name"

  local locals=()
  while IFS= read -r line; do
      locals+=( 'local '"${line%=}"$'\n' )
  done < <(grep -o '[a-zA-Z_][a-zA-Z_0-9]*=' "$path" | sort -u)

  eval "$name()
  {
    ${locals[@]}
    $(cat "$path")
  }"

  [[ "$quiet" != 'true' ]] && declare -f "$name"
}

functionify -q echodo
functionify -q echoerr

functionify -q prompt_version
functionify -q prompt_last_command_style
functionify -q echo_color
functionify -q git_status_clean
functionify -q git_head_pushed
functionify -q prompt_git_color
functionify -q git_branch_name
functionify -q prompt_git

export PS2="\[$COLOR_PINK\]» \[$COLOR_RESET\]"
export PS1="\[\$(prompt_last_command_style)\]\[$COLOR_PINK\]\w\[$COLOR_LIGHT_PINK\]\$(prompt_version)\[\$(prompt_git_color)\]\$(prompt_git)$PS2"
