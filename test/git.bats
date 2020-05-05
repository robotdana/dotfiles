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

@test "git commit nothing doesn't stash" {
  echo a > a
  run git commit -m "nothing"
  assert_failure
  run git log --format=%s
  assert_output "Initial commit"
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
  git commit -m "Original commit"
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
Initial commit"
}

@test "resolve merge conflict: theirs deleted: keep ours" {
  echo 'text' > file1
  git add file1
  git commit -m "Commit 1"
  git checkout -b "branch2"
  rm file1
  echo 'something' > file2
  git add file1 file2
  git commit -m "Commit 2"
  git checkout master
  echo 'amended text' > file1
  git add file1
  git commit -m "Commit 3"
  run git merge branch2
  assert_output "CONFLICT (modify/delete): file1 deleted in branch2 and modified in HEAD. Version HEAD of file1 left in tree.
Automatic merge failed; fix conflicts and then commit the result."
  yes n | run gmc
  run git log --format=%s -n 1
  assert_output "Merge branch 'branch2'"
  assert_file_exist file1
  assert_file_exist file2
  run cat file1
  assert_output 'amended text'
}

@test "resolve merge conflict: ours deleted: delete ours" {
  echo 'text' > file1
  git add file1
  git commit -m "Commit 1"
  git checkout -b "branch2"
  echo 'amended text' > file1
  echo 'something' > file2
  git add file1 file2
  git commit -am "Commit 2"
  git checkout master
  rm file1
  git commit -am "Commit 3"
  run git merge branch2
  assert_output "CONFLICT (modify/delete): file1 deleted in HEAD and modified in branch2. Version branch2 of file1 left in tree.
Automatic merge failed; fix conflicts and then commit the result."
  yes n | run gmc
  assert_file_not_exist file1
  assert_file_exist file2
  assert_equal "$(git show --format="%s" HEAD)" "Merge branch 'branch2'"
}

@test "resolve merge conflict: ours deleted: keep theirs" {
  echo 'text' > file1
  git add file1
  git commit -m "Commit 1"
  git checkout -b "branch2"
  echo 'amended text' > file1
  git add file1
  git commit -m "Commit 2"
  git checkout master
  rm file1
  echo 'something' > file2
  git add file1 file2
  git commit -m "Commit 3"
  run git merge branch2
  assert_output "CONFLICT (modify/delete): file1 deleted in HEAD and modified in branch2. Version branch2 of file1 left in tree.
Automatic merge failed; fix conflicts and then commit the result."
  yes | run gmc
  assert_file_exist file1
  assert_file_exist file2
  run git log --format=%s -n 1
  assert_output "Merge branch 'branch2'"
  run cat file1
  assert_output 'amended text'
}

@test "resolve merge conflict: theirs deleted: delete ours" {
  echo 'text' > file1
  git add file1
  git commit -m "Commit 1"
  git checkout -b "branch2"
  rm file1
  git commit -am "Commit 2"
  git checkout master
  echo 'amended text' > file1
  git add file1
  git commit -m "Commit 3"
  run git merge branch2
  assert_output "CONFLICT (modify/delete): file1 deleted in branch2 and modified in HEAD. Version HEAD of file1 left in tree.
Automatic merge failed; fix conflicts and then commit the result."
  yes | run gmc
  assert_file_not_exist file1
  run git show --format="%s" HEAD
  assert_output "Merge branch 'branch2'"
}
