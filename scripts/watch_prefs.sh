#!/usr/bin/env bash

set -euo pipefail

domains=($(defaults domains))

before=$(mktemp -d)
for domain in ${domains[@]//,}; do
  set +e
  defaults read $domain >"$before/$domain" 2>/dev/null
  set -e
done

echo "Change preference, then hit enter"

read enter

after=$(mktemp -d)

for domain in ${domains[@]//,}; do
  set +e
  defaults read $domain >"$after/$domain" 2>/dev/null
  set -e
done

echo "The diff between defaults entries is:"

diff -r "$before" "$after"

