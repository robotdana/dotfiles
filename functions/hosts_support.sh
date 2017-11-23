function rehosts(){
  echodo "dscacheutil -flushcache && sudo killall mDNSResponder"
}

function shosts(){
  echodo $EDITOR /etc/hosts && rehosts
}

# TODO: move these to functions
alias block="~/.dotfiles/scripts/block.sh"
alias unblock="~/.dotfiles/scripts/unblock.sh"
