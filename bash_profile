alias ls="ls -FG"

bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'

set +H
shopt -s histappend

export PATH="$HOME/.dotfiles/bin:$PATH"
export GPG_TTY=$(tty)
export BASH_SILENCE_DEPRECATION_WARNING=1

. ~/.dotfiles/functions/track_bash_profile_dependency
track_source ~/.dotfiles/functions/functionify
track_functionify_q initialize source_if_exists
initialize code
initialize node
initialize brew
initialize rust
initialize python
initialize ruby
initialize php
initialize direnv

# needs to be after these other things which mess with path
export PATH="$HOME/.dotfiles/bin:$PATH"

track_source ~/.dotfiles/functions/colors

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

track_source ~/.dotfiles/locals/secrets

export PS2='\[\033[1K\r$(prompt_base_style)\]» \[\033]0m\]'
export PS1='\[\033[1K\r$(prompt_base_style)\]\w\[\033[38;5;205m\]$(prompt_version)\[$(prompt_git_color)\]$(prompt_git)\[\033[38;5;199m\]» \[\033[0m\]'

track_and_resource
