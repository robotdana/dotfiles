export NVM_DIR="$HOME/.nvm"
[ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

function nvm_use_node_version {
  if nvm --version >/dev/null 2>/dev/null; then
    if [[ -f .node-version ]]; then
      local new_version=$(<.node-version)
    elif [[ -f .tool-versions ]]; then
      local new_version=$(grep -F nodejs .tool-versions | cut -f2 -d' ')
    elif [[ -f package.json ]]; then
      local new_version=$(jq '.engines.node' -r package.json | tr -dc 0-9.)
    fi

    if [[ ! -z "$new_version" ]]; then
      local current_version=$(nvm current)
      if [[ "v$new_version" != "$current_version" ]]; then
        echodo nvm use $new_version || echodo nvm install $new_version
      fi
    fi
  fi
}
