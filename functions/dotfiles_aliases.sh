function cdot() {
  echodo cd ~/.dotfiles
}

# not whitespace files friendly
function edot {
  if (( $# > 0 )); then
    files=( $(grep -rn "${@/#/-e }" ~/.dotfiles | cut -f1,2 -d:) )
  fi
  echodo code ${files[@]/#/-g } -n ~/.dotfiles
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
