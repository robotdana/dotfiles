#!/bin/bash

set -e

source ~/.dotfiles/functions/bash_support.sh

echodo ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
echodo ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
echodo ln -sf ~/.dotfiles/gitignore ~/.gitignore
echodo ln -sf ~/.dotfiles/gemrc ~/.gemrc
echodo ln -sf ~/.dotfiles/irbrc ~/.irbrc
if [ -d ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/ ]; then
	echodo mv ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/ ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User.bak
fi
ln -sf ~/.dotfiles/SublimePackages ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

if [ ! -d ~/.dotfiles/locals ]; then
	echodo mkdir ~/.dotfiles/locals
fi

if [ ! -e ~/.dotfiles/locals/bash.sh ]; then
  echodo cp ~/.dotfiles/locals.example/bash.sh ~/.dotfiles/locals/bash.sh
fi
if [ ! -e ~/.dotfiles/locals/verticals ]; then
  echodo cp ~/.dotfiles/locals.example/verticals ~/.dotfiles/locals/verticals
fi

./update.sh
