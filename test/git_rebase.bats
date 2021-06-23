#!/usr/bin/env bats

load helper

source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/git_aliases.sh

function setup() {

  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    setup_git
    echo "#TODO" > readme.txt
    git add readme.txt
    git commit --no-verify -m "Initial commit"
  else
    reset_to_first_commit
  fi
}


@test "git reword" {
  git checkout -b branch
  echo a > a
  git add .
  git commit -m "Commit message to be changed"
  echo b > b
  git add .
  git commit -m "Commit message to remain"
  run git_find_sha to be changed
  assert_output $(git rev-parse --short HEAD^)
  GIT_EDITOR="sed -i.~ s/to\ be\ changed/was\ changed/" \
    run git_reword "to be changed"
  assert_output ""
  run git log -s --format=%s
  assert_output "Commit message to remain
Commit message was changed
Initial commit"
}
