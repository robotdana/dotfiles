#!/usr/bin/env bats

load helper

@test "test git_fake_auto_stash" {
  git_test_init
  echo a > a
  echo b > b
  git_fake_auto_stash
  assert_file_not_exist a
  assert_file_not_exist b
  assert_git_status_clean
  run git stash list
  assert_output "stash@{0}: On master: fake autostash"
}

@test "test git_fake_auto_stash_pop" {
  git_test_init
  echo a > a
  echo b > b
  git_fake_auto_stash
  git_fake_auto_stash_pop
  assert_equal "$(cat a)" "a"
  assert_equal "$(cat b)" "b"
  run git_untracked
  assert_line "a"
  assert_line "b"
}

@test "git_test_amend" {
  git_test_init
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

@test "pass rubocop hook" {
  git_test_init_rubocop
  good_rb > foo.rb
  good_rb > bar.rb
  git add .
  git commit -m "pass rubocop"
  assert_git_status_clean
  assert_git_stash_empty
}

@test "fail rubocop hook" {
  git_test_init_rubocop
  bad_rb > foo.rb
  bad_rb > bar.rb
  git add .
  run git commit -m "fail rubocop"
  assert_cleaned_output "bar.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning."
  run git diff --cached --name-only
  assert_line "bar.rb"
  assert_line "foo.rb"
  assert_git_stash_empty

  good_rb > foo.rb
  good_rb > bar.rb

  yes | gc "pass rubocop"

  assert_git_status_clean
  assert_git_stash_empty
}

@test "partial add pass rubocop hook" {
  git_test_init_rubocop
  good_rb > foo.rb
  bad_rb > bar.rb
  git add foo.rb
  git commit -m "pass rubocop"
  run git_untracked
  assert_output "bar.rb"
  assert_git_stash_empty
  bad_rb > baz.rb
  assert_equal "$(cat bar.rb)" "$(cat baz.rb)"
}

@test "partial add fail rubocop hook" {
  git_test_init_rubocop
  good_rb > foo.rb
  bad_rb > bar.rb
  git add bar.rb
  run git commit -m "fail rubocop"
  assert_cleaned_output "bar.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning."
  run git diff --cached --name-only
  assert_output "bar.rb"
  run git_untracked
  assert_output ""
  good_rb > bar.rb

  git add bar.rb
  git commit -m "pass rubocop"

  run git_untracked
  assert_output "foo.rb"
}

@test "patch add pass rubocop hook" {
  git_test_init_rubocop
  good_rb > foo.rb
  git add foo.rb
  bad_rb >> foo.rb
  run git diff --cached --name-only
  assert_output "foo.rb"
  run git diff --name-only
  assert_output "foo.rb"
  git commit -m "pass rubocop"
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(bad_rb)"
}

@test "patch add fail rubocop hook" {
  git_test_init_rubocop
  bad_rb > foo.rb
  git add foo.rb
  good_rb >> foo.rb
  run git commit -m "fail rubocop"
  assert_cleaned_output "foo.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning."
  good_rb > foo.rb
  git add foo.rb
  git commit -m "pass rubocop"
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(good_rb)"
}
