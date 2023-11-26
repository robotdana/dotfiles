#!/usr/bin/env bash

launchagents=(~/.dotfiles/LaunchAgents/*)

for agent in "${launchagents[@]##*/}"; do
  cat ~/.dotfiles/LaunchAgents/$agent | sed s^'$HOME'^$HOME^g | sed s^'$PATH'^$PATH^g > ~/Library/LaunchAgents/$agent
  echo launchctl unload "~/Library/LaunchAgents/$agent"
  echo launchctl load "~/Library/LaunchAgents/$agent"
done
