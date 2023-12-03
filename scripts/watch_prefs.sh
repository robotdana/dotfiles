#!/usr/bin/env bash

set -euo pipefail

domains=($(defaults domains))

echo "Loading prefs..."
before=$(mktemp -d)
for domain in ${domains[@]//,}; do
  set +e
  defaults read $domain >"$before/$domain" 2>/dev/null
  set -e
done

echo "Change preference, then hit enter"

read enter

echo "Loading prefs..."
after=$(mktemp -d)
for domain in ${domains[@]//,}; do
  set +e
  defaults read $domain >"$after/$domain" 2>/dev/null
  set -e
done

echo "The diff between defaults entries is:"

diff -r "$before" "$after"

