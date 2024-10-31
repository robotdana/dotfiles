#!/bin/bash

if [[ -z "$CI" ]]; then
  brew bundle
fi

function git_version_number {
  git --version | cut -d\( -f1 | grep -oE "[0-9\.]+"
}

# get git-completion
echodo curl "https://raw.githubusercontent.com/git/git/refs/tags/v$(git_version_number)/contrib/completion/git-completion.bash" > ~/.dotfiles/locals/git-completion.bash
if [[ $(wc -l ~/.dotfiles/locals/git-completion.bash | awk -F' ' '{print $1}') = "1" ]]; then
  echoerr "git-completion didn't download correctly"
  exit 1
fi

git_update_submodules
# ( cd monokai.terminal && git remote add upstream git@github.com:stephenway/monokai.terminal.git )

# . ~/.dotfiles/scripts/install_launchagents.sh

if [[ -z "$CI" ]]; then
  ruby-install $(cat .ruby-version) $(ruby-build --list | grep '^\d')
fi