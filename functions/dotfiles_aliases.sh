function cdot() {
  if [[ $(git_current_repo) = "dotfiles" ]]; then
    echodo cd $OLDPWD
  else
    echodo cd ~/.dotfiles
  fi
}

# `sdot` edit select few dotfiles that have high churn, reload profile when they are closed.
function sdot() {
  echodo $EDITOR ~/.dotfiles/functions/* ~/.bash_profile; resource
}

function ldot() {
  ( cdot && glr )
}

function gdot() {
  ( cdot && gc $* && gp )
}
