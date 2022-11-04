#!/bin/bash

# copied from https://gist.githubusercontent.com/ellsclytn/a1f243de19b206cf3dedfd30c9f26651/raw/89964fadec43b7d9155ba838a3b96fc1c0a11892/gpg-setup.sh

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

echo "pinentry-program $(which pinentry-mac)" >> "$GNUPG_DIR/gpg-agent.conf"

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

echo "What's your full name (this must match your git config)?"
read FULL_NAME

echo "What's your email (this must match your git config)?"
read EMAIL

echo "Key-Type: 1" > keygen-config
echo "Key-Length: 4096" >> keygen-config
echo "Name-Real: $FULL_NAME" >> keygen-config
echo "Name-Email: $EMAIL" >> keygen-config
echo "Expire-Date: 0" >> keygen-config

gpg --batch --gen-key keygen-config

KEY_ID=$(gpg --list-keys --with-colons --keyid-format LONG $EMAIL | awk -F: '/pub:/ {print $5}')

rm keygen-config

info "GPG Key created. Key ID $KEY_ID. Configuring git..."

git config --global user.signingkey $KEY_ID
git config --global commit.gpgsign true

info "Git configured. All your commits will is be signed. Your public key is below. Go paste it into GitHub at https://github.com/settings/gpg/new"

gpg --armor --export $KEY_ID
