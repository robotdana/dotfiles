#!/usr/bin/env bash

# we assume this is checked out to ~/.dotfiles
ln -s $PWD ~/.dotfiles

# i need my hooks
cp gitconfig ~/.gitconfig

git config --global commit.gpgsign false

# run some tests
test/bats/bin/bats test/*.bats
