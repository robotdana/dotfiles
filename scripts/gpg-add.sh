#!/bin/bash

# modified based on https://gist.githubusercontent.com/ellsclytn/a1f243de19b206cf3dedfd30c9f26651/raw/89964fadec43b7d9155ba838a3b96fc1c0a11892/gpg-setup.sh


INFO='\033[1;32m'
NC='\033[0m'

GNUPG_DIR="$HOME/.gnupg"

function info() {
  echo -e "${INFO}$1${NC}"
}

info "Installing GPG tools..."
brew install gpg2 gnupg pinentry-mac

info "GPG tools installed. Configuring them..."

if [[ ! -d "$GNUPG_DIR" ]]; then
  mkdir "$GNUPG_DIR"
fi

if [[ ! -f "$GNUPG_DIR/gpg-agent.conf" ]]; then
  touch "$GNUPG_DIR/gpg-agent.conf"
fi

echo "pinentry-program /usr/local/bin/pinentry-mac" >> "$GNUPG_DIR/gpg-agent.conf"

if [[ ! -f "$GNUPG_DIR/gpg.conf" ]]; then
  touch "$GNUPG_DIR/gpg.conf"
fi

echo "use-agent" >> "$GNUPG_DIR/gpg.conf"

if [[ -f "$HOME/.bashrc" ]]; then
  echo "export GPG_TTY=\`tty\`" >> "$HOME/.bashrc"
  source "$HOME/.bashrc"
fi

if [[ -f "$HOME/.zshrc" ]]; then
  echo "export GPG_TTY=\`tty\`" >> "$HOME/.zshrc"
  source "$HOME/.zshrc"
fi

chmod 700 "$HOME/.gnupg"

info "Configured."

echo "What's your key .asc path"
read KEY_PATH

echo "What's you key ID"
read KEY_ID

gpg --import $KEY_PATH
echo "enter:
> trust
> 5
> y
> quit"
gpg --edit-key $KEY_ID
