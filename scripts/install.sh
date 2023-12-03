#!/bin/bash

set -e

~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/bashrc ~/.bashrc
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/Brewfile ~/Brewfile
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/gitignore ~/.gitignore
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/irbrc ~/.irbrc
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/finicky.js ~/.finicky.js
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/vimrc ~/.vimrc
~/.dotfiles/bin/echodo mkdir -p ~/.ssh
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/ssh_config ~/.ssh/config
~/.dotfiles/bin/echodo mkdir -p ~/.bundle
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/bundle_config ~/.bundle/config
~/.dotfiles/bin/echodo ln -sf ~/.dotfiles/mycnf ~/.my.cnf
~/.dotfiles/bin/echodo ln -sf ~/.ruby-version ~/.ruby-version
~/.dotfiles/bin/echodo mkdir -p ~/.dotfiles/locals
~/.dotfiles/bin/echodo touch ~/.dotfiles/locals/secrets


if [[ -z "$CI" ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew tap homebrew/cask
  brew tap homebrew/cask-fonts
  brew install mas
fi

~/.dotfiles/scripts/update.sh

open monokai.terminal/Monokai.terminal
defaults write com.apple.Terminal Shell -string /bin/bash
defaults write com.apple.Terminal "Default Window Settings" -string Monokai
defaults write com.apple.Terminal "Man Page Window Settings" -string Monokai
defaults write com.apple.Terminal "Startup Window Settings" -string Monokai
