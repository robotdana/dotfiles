#!/bin/bash

set -e

source ~/.dotfiles/functions/bash_support.sh

echodo ln -sf ~/.dotfiles/Brewfile ~/Brewfile
echodo ln -sf ~/.dotfiles/Brewfile.lock.json ~/Brewfile.lock.json
echodo ln -sf ~/.dotfiles/bashrc ~/.bashrc
echodo ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
echodo ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
echodo ln -sf ~/.dotfiles/gitignore ~/.gitignore
echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
echodo ln -sf ~/.dotfiles/irbrc ~/.irbrc
echodo mkdir -p ~/.ssh
echodo ln -sf ~/.dotfiles/ssh_config ~/.ssh/config
echodo mkdir -p ~/.bundle
echodo ln -sf ~/.dotfiles/bundle_config ~/.bundle/config
echodo ln -sf ~/.dotfiles/mycnf ~/.my.cnf
echodo mkdir -p ~/.dotfiles/locals

ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap homebrew/cask
brew tap homebrew/cask-fonts
brew install mas

~/.dotfiles/scripts/update.sh
