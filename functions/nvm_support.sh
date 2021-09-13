export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

function nvm_use_node_version {
  if [[ -f .node-version ]]; then
    local new_version=$(<.node-version)
  elif [[ -f .tool-versions ]]; then
    local new_version=$(grep -F nodejs .tool-versions | cut -f2 -d' ')
  fi

  if [[ ! -z "$new_version" ]]; then
    local current_version=$(nvm current)
    if [[ "v$new_version" != "$current_version" ]]; then
      echodo nvm use $new_version
    fi
  fi
}
