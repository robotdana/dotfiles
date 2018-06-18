#!/usr/bin/env bats

load helper

source ~/.dotfiles/functions/git_support.sh

function setup() {
  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    rm -rf ~/.git-test-repo
    mkdir ~/.git-test-repo
    cd ~/.git-test-repo || exit
    git init
    echo "#TODO" > readme.txt
    git add readme.txt
    git commit --no-verify -m "initial commit"
  else
    reset_to_first_commit
  fi
}

@test "git commit nothing doesn't stash" {
  echo a > a
  run git commit -m "nothing"
  assert_failure
  run git log --format=%s
  assert_output "initial commit"
  assert_equal "$(cat a)" "a"
}

@test "git_fake_auto_stash" {
  echo a > a
  echo b > b
  git_fake_auto_stash
  assert_file_not_exist a
  assert_file_not_exist b
  assert_git_status_clean
  run git stash list
  assert_output "stash@{0}: On master: fake autostash"
}

@test "git_fake_auto_stash_pop" {
  echo a > a
  echo b > b
  git_fake_auto_stash
  git stash list
  git_fake_auto_stash_pop
  assert_equal "$(cat a)" "a"
  assert_equal "$(cat b)" "b"
  run git_untracked
  assert_output "a
b"
}

@test "amend cleans up" {
  echo a > a
  git add .
  git commit --no-verify -m "Original commit"
  git commit --amend -m "Amended commit"
  echo b > b
  git add .
  git commit --amend -m "Amended commit with b"
  assert_equal "$(cat a)" "a"
  assert_equal "$(cat b)" "b"
  assert_git_status_clean
  assert_git_stash_empty
  run git log --format=%s
  assert_output "Amended commit with b
initial commit"
}
