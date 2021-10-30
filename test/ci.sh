#!/usr/bin/env bash

# we assume this is checked out to ~/.dotfiles
ln -s $PWD ~/.dotfiles

# i need my hooks
git config --global core.hooksPath '~/.dotfiles/hooks'

# run some tests
test/bats/bin/bats test/*.bats
