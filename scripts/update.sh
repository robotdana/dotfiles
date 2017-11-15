#!/bin/bash

# TODO: extract these into another file, and import into bash_profile & here
function echodo(){
  ( echo -e "\033[1;90m$*\033[1;39m" )>/dev/tty
  eval $*
}
function echoerr(){
  ( echo -e "\033[1;31m$*\033[1;39m" )>/dev/tty
  return 1
}

# get ttab
echodo curl https://raw.githubusercontent.com/mklement0/ttab/stable/bin/ttab > ~/.dotfiles/locals/ttab
if [[ $(wc -l ~/.dotfiles/locals/ttab | awk -F' ' '{print $1}') = "1" ]]; then
  echoerr "ttab didn't download correctly"
  exit 1
fi
echodo chmod +x ~/.dotfiles/locals/ttab
echodo ln -sf ~/.dotfiles/locals/ttab /usr/local/bin/ttab

# get git-completion
echodo curl "https://raw.githubusercontent.com/git/git/v$(/usr/bin/git --version | grep -oE " [0-9\.]+ " | tr -d ' ')/contrib/completion/git-completion.bash" > ~/.dotfiles/locals/git-completion.bash
if [[ $(wc -l ~/.dotfiles/locals/git-completion.bash | awk -F' ' '{print $1}') = "1" ]]; then
  echoerr "git-completion didn't download correctly"
  exit 1
fi
source ~/.bash_profile
