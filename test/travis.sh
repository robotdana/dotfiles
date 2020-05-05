#!/usr/bin/env bash

# we assume this is checked out to ~/.dotfiles
ln -s $PWD ~/.dotfiles

# install bats things
mkdir ./bats-plugins
git clone --depth 1 https://github.com/ztombol/bats-support ./bats-plugins/bats-support
git clone --depth 1 https://github.com/ztombol/bats-assert ./bats-plugins/bats-assert
git clone --depth 1 https://github.com/ztombol/bats-file ./bats-plugins/bats-file
export BATS_PLUGINS_DIR=$PWD/bats-plugins

# i need my hooks
git config --global core.hooksPath '~/.dotfiles/hooks'

# run some tests
bats test/*.bats
