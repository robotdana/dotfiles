source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_support.sh
export PS2="\[$C_PINK\]» \[$C_RESET\]"
export PS1="\[\$(last_command_style)\]\[$C_PINK\]\w\[$C_LIGHT_PINK\]\$(ruby_version_prompt)\[\$(git_status_color)\]\$(git_prompt_current_ref :)$PS2"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
