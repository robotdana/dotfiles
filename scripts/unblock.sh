#!/bin/bash
if [ "$1" == "" ]; then
  echo "Usage:"
  echo "unblock twitter.com facebook.com"
  echo "stops redirecting twitter.com & facebook.com to localhost"
  exit 1
fi

for url in "$@"; do
  cat /etc/hosts | sed -e "/$url/d" | sudo tee /etc/hosts &>/dev/null
done
dscacheutil -flushcache
sudo killall mDNSResponder
