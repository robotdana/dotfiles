#!/bin/bash

set -e

export PATH="$HOME/.dotfiles/bin:$PATH"

echodo ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
echodo ln -sf ~/.dotfiles/bashrc ~/.bashrc
echodo ln -sf ~/.dotfiles/Brewfile ~/Brewfile
echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
echodo ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
echodo ln -sf ~/.dotfiles/gitignore ~/.gitignore
echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
echodo ln -sf ~/.dotfiles/irbrc ~/.irbrc
echodo ln -sf ~/.dotfiles/finicky.js ~/.finicky.js
echodo ln -sf ~/.dotfiles/vimrc ~/.vimrc
echodo mkdir -p ~/.ssh
echodo ln -sf ~/.dotfiles/ssh_config ~/.ssh/config
echodo mkdir -p ~/.bundle
echodo ln -sf ~/.dotfiles/bundle_config ~/.bundle/config
echodo ln -sf ~/.dotfiles/mycnf ~/.my.cnf
echodo ln -sf ~/.ruby-version ~/.ruby-version
echodo mkdir -p ~/.dotfiles/locals
echodo touch ~/.dotfiles/locals/secrets


if [[ -z "$CI" ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew tap homebrew/cask
  brew tap homebrew/cask-fonts
  brew install mas
fi

. ~/.dotfiles/scripts/update.sh

open monokai.terminal/Monokai.terminal
defaults write com.apple.Terminal Shell -string /bin/bash
defaults write com.apple.Terminal "Default Window Settings" -string Monokai
defaults write com.apple.Terminal "Man Page Window Settings" -string Monokai
defaults write com.apple.Terminal "Startup Window Settings" -string Monokai
