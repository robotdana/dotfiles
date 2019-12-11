alias ls="ls -FG"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

set +H

export PYENV_SHELL=bash
export PATH=/Users/dana/.pyenv/shims:/usr/local/heroku/bin:/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH
export EDITOR='/usr/local/bin/code --wait'
export GUI_EDITOR=$EDITOR
export JAVA_HOME="/Library/Internet\\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"
export GPG_TTY=$(tty)

source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh

if [[ "$(ruby -v)" == "$(chruby system && ruby -v)" ]]; then
  chruby $(chruby | grep -vF 'preview' | tail -n1 | colrm 1 3)
fi

source ~/.dotfiles/locals/secrets

source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/hosts_support.sh
source ~/.dotfiles/functions/prompt_support.sh
source ~/.dotfiles/functions/server_support.sh
source ~/.dotfiles/functions/marketplacer_support.sh
source ~/.dotfiles/functions/cc_menu_support.sh
source ~/.dotfiles/functions/rails_support.sh
source ~/.dotfiles/functions/less_support.sh

source ~/.dotfiles/functions/git_aliases.sh
source ~/.dotfiles/functions/git_alias_completion.sh
source ~/.dotfiles/functions/dotfiles_aliases.sh
source ~/.dotfiles/functions/rails_aliases.sh
source ~/.dotfiles/functions/jekyll_aliases.sh
source ~/.dotfiles/functions/webpack_aliases.sh
source ~/.dotfiles/functions/marketplacer_aliases.sh

PROMPT_COMMAND="maybe_update_terminal_cwd; resource_if_modified_since $(last_bash_profile_modification)"

export PS2="\[$C_BLUE\]» \[$C_RESET\]"
export PS1="\[$C_BLUE\]\w\[\$(git_status_color)\]\$(git_prompt_current_branch :)$PS2"

export PATH="$HOME/.cargo/bin:$PATH"
