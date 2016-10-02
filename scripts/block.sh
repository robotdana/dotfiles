#!/bin/bash

if [ "$1" == "" ]; then
  echo "Usage:"
  echo "block twitter.com facebook.com"
  echo "redirects twitter.com & facebook.com to localhost"
  exit 1
fi
for url in "$@"; do
  cat /etc/hosts | grep $url &>/dev/null
  if [[ $? == 0 ]]; then
    echo "Already blocking $url"
  else
    echo "127.0.0.1 $url www.$url" | sudo tee -a /etc/hosts &>/dev/null
  fi
done
dscacheutil -flushcache
