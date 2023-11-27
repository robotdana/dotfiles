source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_support.sh
export PS2="\[$C_PINK\]» \[$C_RESET\]"
export PS1="\$(last_command_style)$C_PINK\w\$(prompt_version)\$(prompt_git)$PS2"
export GPG_TTY=$(tty)
