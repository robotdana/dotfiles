# echo "required hosts_support"
function rehosts(){
  echodo dscacheutil -flushcache && echodo sudo killall mDNSResponder
}

function shosts(){
  echodo $EDITOR /etc/hosts && rehosts
}

# TODO: move these to functions
alias block="~/.dotfiles/scripts/block.sh"
alias unblock="~/.dotfiles/scripts/unblock.sh"
