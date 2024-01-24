alias ls="ls -FG"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

set +H
shopt -s histappend

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$HOME/.dotfiles/bin:$PYENV_ROOT/bin:$HOME/.cargo/bin:/usr/local/opt:/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH"
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

if [[ ! -z "$(which pyenv)" ]]; then
  eval "$(pyenv init -)"
fi

source $(brew --prefix chruby)/share/chruby/chruby.sh
source $(brew --prefix chruby)/share/chruby/auto.sh

# needs to be after these other things which mess with path
export PATH="$HOME/.dotfiles/bin:$PATH"

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

if [[ -f ~/.phpbrew/bashrc ]]; then
  source ~/.phpbrew/bashrc
fi

. ~/.dotfiles/functions/track_bash_profile_dependency
track_source ~/.dotfiles/functions/colors
track_source ~/.dotfiles/functions/functionify

# have functions for things i call _all the time_
track_functionify_q echodo echodont echoerr be

# have functions for things called by prompt
track_functionify_q prompt_base_style
track_functionify_q prompt_version
track_functionify_q prompt_git_color git_status_clean
track_functionify_q prompt_git git_branch_name
#
# some thing just work better as functions
track_functionify_q resource # as a function it won't reset history

export PS2='\[\033[1K\r$(prompt_base_style)\]» \[\033]0m\]'
export PS1='\[\033[1K\r$(prompt_base_style)\]\w\[\033[38;5;205m\]$(prompt_version)\[$(prompt_git_color)\]$(prompt_git)\[\033[38;5;199m\]» \[\033[0m\]'

track_and_resource
