
ln -sf ~/.dotfiles/bash_profile ~/.bash_profile
ln -sf ~/.dotfiles/gemrc ~/.gemrc
ln -sf ~/.dotfiles/gitconfig ~/.gitconfig
ln -sf ~/.dotfiles/gitignore ~/.gitignore
ln -sf ~/.dotfiles/gemrc ~/.gemrc
ln -sf ~/.dotfiles/irbrc ~/.irbrc

mkdir ~/.dotfiles/locals

if [! -e ~/.dotfiles/locals/bash.sh ]; then
  cp ~/.dotfiles/locals_bash.sh.example ~/.dotfiles/locals/bash.sh
fi
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash > ~/.dotfiles/git-completion.bash
curl https://raw.githubusercontent.com/mklement0/ttab/stable/bin/ttab > ~/.dotfiles/locals/ttab

chmod +x ~/.dotfiles/locals/ttab
ln -sf ~/.dotfiles/locals/ttab /usr/local/bin/ttab
source ~/.bash_profile && echo '••• finished •••'

