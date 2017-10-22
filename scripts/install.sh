#!/bin/bash

set -e

ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
ln -sf ~/.dotfiles/gemrc ~/.gemrc
ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/gitignore ~/.gitignore
ln -sf ~/.dotfiles/gemrc ~/.gemrc
ln -sf ~/.dotfiles/irbrc ~/.irbrc
if [ -d ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/ ]; then
	mv ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/ ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User.bak
fi
ln -sf ~/.dotfiles/SublimePackages ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

if [ ! -d ~/.dotfiles/locals ]; then
	mkdir ~/.dotfiles/locals
fi

if [ ! -e ~/.dotfiles/locals/bash.sh ]; then
  cp ~/.dotfiles/locals.example/bash.sh ~/.dotfiles/locals/bash.sh
fi
if [ ! -e ~/.dotfiles/locals/verticals ]; then
  cp ~/.dotfiles/locals.example/verticals ~/.dotfiles/locals/bash.sh
fi

curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash > ~/.dotfiles/locals/git-completion.bash
curl https://raw.githubusercontent.com/mklement0/ttab/stable/bin/ttab > ~/.dotfiles/locals/ttab

chmod +x ~/.dotfiles/locals/ttab
ln -sf ~/.dotfiles/locals/ttab /usr/local/bin/ttab
source ~/.bash_profile && echo '••• finished •••'

