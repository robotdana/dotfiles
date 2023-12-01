source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_support.sh

export PS2="\[$COLOR_PINK\]» \[$COLOR_RESET\]"
export PS1="\$(last_command_style)$COLOR_PINK\w\$(prompt_version)\[\$(prompt_git_color)\]\$(prompt_git)$PS2"
export GPG_TTY=$(tty)
