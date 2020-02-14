source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_support.sh
export PS2="\[$C_PINK\]» \[$C_RESET\]"
export PS1="\[\$(last_command_style)\]\[$C_PINK\]\w\[$C_LIGHT_PINK\]\$(ruby_version_prompt)\[\$(git_status_color)\]\$(git_prompt_current_ref :)$PS2"
