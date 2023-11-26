#!/bin/bash

source ~/.dotfiles/functions/bash_support.sh

if [[ -z "$CI" ]]; then
  brew bundle
fi

function git_version_number {
  git --version | cut -d\( -f1 | grep -oE "[0-9\.]+"
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
echodo curl "https://raw.githubusercontent.com/git/git/v$(git_version_number)/contrib/completion/git-completion.bash" > ~/.dotfiles/locals/git-completion.bash
if [[ $(wc -l ~/.dotfiles/locals/git-completion.bash | awk -F' ' '{print $1}') = "1" ]]; then
  echoerr "git-completion didn't download correctly"
  exit 1
fi

# get diff highlight
mkdir ~/.dotfiles/locals/diff-highlight
echodo curl "https://raw.githubusercontent.com/git/git/v$(git_version_number)/contrib/diff-highlight/DiffHighlight.pm" > ~/.dotfiles/locals/diff-highlight/DiffHighlight.pm
echodo curl "https://raw.githubusercontent.com/git/git/v$(git_version_number)/contrib/diff-highlight/diff-highlight.perl" > ~/.dotfiles/locals/diff-highlight/diff-highlight.perl
echodo curl "https://raw.githubusercontent.com/git/git/v$(git_version_number)/contrib/diff-highlight/Makefile" > ~/.dotfiles/locals/diff-highlight/Makefile

if [[ $(wc -l ~/.dotfiles/locals/diff-highlight/Makefile | awk -F' ' '{print $1}') = "1" ]]; then
  echoerr "diff highlight didn't download correctly"
  exit 1
fi

if [[ ! -d ~/.dotfiles/locals/github-cctray ]]; then
  git clone https://github.com/robotdana/github-cctray.git ~/.dotfiles/locals/github-cctray
fi
( cd ~/.dotfiles/locals/github-cctray && gl )


( cd ~/.dotfiles/locals/diff-highlight && make -f Makefile & )
ln -sf ~/.dotfiles/locals/diff-highlight/diff-highlight /usr/local/bin/diff-highlight

ruby-install ruby 3.0
ruby-install ruby 3.1
ruby-install ruby 3.2

install_launchagents.sh

resource
