function cdot() {
  echodo cd ~/.dotfiles
}

function edot {
  echodo code -n ~/.dotfiles
}

function ldot() {
  ( cdot && gl )
}

function gdot() {
  ( cdot && gcp "$*" )
}

function rdot() {
  ( cdot && echodo git reset --hard HEAD )
}
