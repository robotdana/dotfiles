#!/usr/bin/env bats

load helper

source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/git_aliases.sh

function setup() {

  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    setup_git
    echo "#TODO" > readme.txt
    git add readme.txt
    git commit --no-verify -m "initial commit"
  else
    reset_to_first_commit
  fi
}


@test "git reword" {
  git checkout -b branch
  echo a > a
  git add .
  git commit -m "commit message to be changed"
  GIT_EDITOR="sed -i '' s/to\ be\ changed/was\ changed/" \
    run git_reword "to be changed"
  assert_output ""
  run git show -s --format=%s
  assert_output "commit message was changed"
}
