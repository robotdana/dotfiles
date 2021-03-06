alias ls="ls -FG"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

set +H

export PYENV_SHELL=bash
export PATH="$HOME/.cargo/bin:/Users/dana/.pyenv/shims:/usr/local/heroku/bin:/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH"
export EDITOR='/usr/local/bin/code --wait'
export GUI_EDITOR=$EDITOR
export GPG_TTY=$(tty)
export BASH_SILENCE_DEPRECATION_WARNING=1

if [[ -f /usr/local/opt/chruby/share/chruby/chruby.sh ]]; then
  source /usr/local/opt/chruby/share/chruby/chruby.sh
  source /usr/local/opt/chruby/share/chruby/auto.sh
fi

if [ -f ~/.cargo/env ]; then
  source /Users/dana/.cargo/env
fi

source ~/.dotfiles/locals/secrets.sh
source ~/.dotfiles/functions/nvm_support.sh
source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/hosts_support.sh
source ~/.dotfiles/functions/prompt_support.sh
source ~/.dotfiles/functions/server_support.sh
source ~/.dotfiles/functions/cc_menu_support.sh
source ~/.dotfiles/functions/rails_support.sh
source ~/.dotfiles/functions/less_support.sh

source ~/.dotfiles/functions/git_aliases.sh
source ~/.dotfiles/functions/git_alias_completion.sh
source ~/.dotfiles/functions/dotfiles_aliases.sh
source ~/.dotfiles/functions/rails_aliases.sh
source ~/.dotfiles/functions/jekyll_aliases.sh
source ~/.dotfiles/functions/webpack_aliases.sh

PROMPT_COMMAND="maybe_update_terminal_cwd; resource_if_modified_since $(last_bash_profile_modification); check_untested_bash_profile; nvm_use_node_version"

export PATH="$HOME/.cargo/bin:$PATH"

if [ -f /usr/local/bin/direnv ]; then
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

export PS2="\[$C_PINK\]» \[$C_RESET\]"
export PS1="\[\$(last_command_style)\]\[$C_PINK\]\w\[$C_LIGHT_PINK\]\$(ruby_version_prompt)\[\$(git_status_color)\]\$(git_prompt_current_ref :)$PS2"
