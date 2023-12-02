#!/usr/bin/env bash

# we assume this is checked out to ~/.dotfiles
ln -s $PWD ~/.dotfiles
~/.dotfiles/scripts/install.sh
git config --global commit.gpgsign false
