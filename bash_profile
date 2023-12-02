alias ls="ls -FG"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

set +H
shopt -s histappend

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

source $(brew --prefix chruby)/share/chruby/chruby.sh
source $(brew --prefix chruby)/share/chruby/auto.sh

source ~/.dotfiles/locals/secrets.sh

if [[ -e /usr/local/bin/direnv ]]; then
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

. ~/.dotfiles/functions/track_bash_profile_dependency
track_source ~/.dotfiles/functions/colors
track_source ~/.dotfiles/functions/functionify

# have functions for things i call _all the time_
track_functionify_q echodo echoerr echo_color be

# have functions for things called by prompt
track_functionify_q prompt_last_command_style
track_functionify_q prompt_version
track_functionify_q prompt_git_color git_status_clean git_head_pushed
track_functionify_q prompt_git git_branch_name

# some thing just work better as functions
track_functionify_q resource # as a function it won't reset history

export PS2="\[$COLOR_PINK\]» \[$COLOR_RESET\]"
export PS1="\[\$(prompt_last_command_style)$COLOR_PINK\]\w\[$COLOR_LIGHT_PINK\]\$(prompt_version)\[\$(prompt_git_color)\]\$(prompt_git)$PS2"

track_and_resource
