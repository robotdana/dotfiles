#!/usr/bin/env bash

# we assume this is checked out to ~/.dotfiles
ln -s $PWD ~/.dotfiles
echo 'ci.sh env:'
env
~/.dotfiles/scripts/install.sh
echo 'ci.sh after install.sh env:'
env
. ~/.bash_profile
echo 'ci.sh after source bash_profile env:'
env
git config --global commit.gpgsign false
ruby -v
echo 'what ruby thinks env is:'
ruby -e 'puts `env`'
bundle exec rspec
