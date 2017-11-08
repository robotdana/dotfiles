#!/bin/bash

curl https://raw.githubusercontent.com/mklement0/ttab/stable/bin/ttab > ~/.dotfiles/locals/ttab
chmod +x ~/.dotfiles/locals/ttab
ln -sf ~/.dotfiles/locals/ttab /usr/local/bin/ttab
