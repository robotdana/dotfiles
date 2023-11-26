#!/usr/bin/env bash
if [[ -f .rubocop.yml ]]; then
  if [[ -f .vscode/settings.json ]]; then
    existing_setting=$(jq '."[ruby]"."editor.rulers"' .vscode/settings.json)
    if [[ ! -z "$existing_setting" ]] && [[ "$1" != "--force" ]]; then
      echo 'hi'
    fi
  else
    mkdir -p .vscode
    echo '{}' > .vscode/settings.json
  fi

  settings=$(jq '."[ruby]"."editor.rulers"=['$(bundle exec rubocop --show-cops Layout/LineLength | yq .Layout/LineLength.Max)']' .vscode/settings.json)
  echo $settings > .vscode/settings.json
fi
