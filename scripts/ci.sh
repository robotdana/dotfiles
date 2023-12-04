#!/usr/bin/env bash

# we assume this is checked out to ~/.dotfiles
ln -s $PWD ~/.dotfiles
env
~/.dotfiles/scripts/install.sh
. ~/.bash_profile
git config --global commit.gpgsign false
ruby -v
ruby -e 'puts `env`'
bundle exec rspec
