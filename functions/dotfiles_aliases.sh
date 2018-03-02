function cdot() {
  if [[ $(git_current_repo) = "dotfiles" ]]; then
    echodo cd "$OLDPWD"
  else
    echodo cd ~/.dotfiles
  fi
}

function sdot() {
  echodo subl -n ~/.dotfiles
}

function ldot() {
  ( cdot && gl )
}

function gdot() {
  ( cdot && gcp $* )
}

function rdot() {
  ( cdot && echodo git reset --hard HEAD )
}
