alias ls="ls -FG"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'
bind Space:magic-space

export PATH=/usr/local/heroku/bin:/usr/local/bin:/usr/local/sbin:/usr/local/lib/node:$PATH
export EDITOR='/usr/local/bin/subl -nw'
export GUI_EDITOR=$EDITOR
export JAVA_HOME="/Library/Internet\\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home"

source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh

source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/hosts_support.sh
source ~/.dotfiles/functions/prompt_support.sh
source ~/.dotfiles/functions/server_support.sh
source ~/.dotfiles/functions/marketplacer_support.sh

source ~/.dotfiles/functions/git_aliases.sh
source ~/.dotfiles/functions/dotfiles_aliases.sh
source ~/.dotfiles/functions/rails_aliases.sh
source ~/.dotfiles/functions/jekyll_aliases.sh
source ~/.dotfiles/functions/webpack_aliases.sh
source ~/.dotfiles/functions/marketplacer_aliases.sh


export PS1="\[$C_BLUE\]\w\[$C_AQUA\]\$(prompt_context)\[$C_BLUE\]\[$C_RED\]\$(prompt_dirty_branch)\[$C_GREEN\]\$(prompt_clean_branch)\[$C_BLUE\]» \[$C_RESET\]"

