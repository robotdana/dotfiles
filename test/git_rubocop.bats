#!/usr/bin/env bats
source ~/.dotfiles/functions/git_aliases.sh
source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/chruby_support.sh

load helper


function setup() {
  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    setup_git
    cp ~/.dotfiles/.ruby-version .ruby-version

    echo "
      source 'https://rubygems.org'
      gem 'rubocop', '1.0.0'
    " > Gemfile
    echo "
      AllCops:
        NewCops: enable
    " > .rubocop.yml
    bundle install
    bundle lock --add-platform universal-darwin-20
    bundle lock --add-platform x86_64-darwin-18
    git add .
    git commit --no-verify -m "Initial commit"
  else
    reset_to_first_commit
  fi
}

@test "pass rubocop hook" {
  good_rb > foo.rb
  good_rb > bar.rb
  git add .
  gc "Pass rubocop"
  assert_git_status_clean
  assert_git_stash_empty
}

@test "fail rubocop hook" {
  bad_rb > foo.rb
  bad_rb > bar.rb
  git add .
  run gc "Fail rubocop"
  # pause for correction
  assert_failure
  assert git_rebasing

  good_rb > foo.rb
  good_rb > bar.rb

  echo yy | grc

  assert_git_status_clean
  assert_git_stash_empty
  refute git_rebasing
}

@test "autocorrect rubocop hook" {
  auto_bad_rb > foo.rb
  auto_bad_rb > bar.rb

  yes y | gc "Auto rubocop"
  refute git_rebasing

  assert_git_status_clean
  refute git_rebasing
  assert_equal "$(cat foo.rb)" "$(good_rb)"
  assert_equal "$(cat bar.rb)" "$(good_rb)"
}

@test "partial add pass rubocop hook" {
  bad_rb > bar.rb
  good_rb > foo.rb
  ( echo ny | gc "Pass rubocop" ) || true
  # this doesn't run rubocop because there are untracked files
  refute git_rebasing
  run git_untracked
  assert_output "bar.rb"

  # manually lint
  git_stash_only_untracked
  run git_autolint_head

  refute git_rebasing

  git stash pop
  run git_untracked
  assert_output "bar.rb"
}

@test "partial add fail rubocop hook" {
  bad_rb > bar.rb
  good_rb > foo.rb
  ( echo yn | gc "Fail rubocop" ) || true
  # this doesn't run rubocop because there are untracked files
  refute git_rebasing
  run git_untracked
  assert_output "foo.rb"

  # manually lint
  git_stash_only_untracked
  run git_autolint_head

  # pause for correction
  assert_failure
  assert git_rebasing

  good_rb > bar.rb
  echo y | grc

  refute git_rebasing

  git stash pop
  run git_untracked
  assert_output "foo.rb"
}

@test "partial add autocorrect rubocop hook" {
  auto_bad_rb > bar.rb
  good_rb > foo.rb
  ( echo yn | gc "Auto rubocop" ) || true
  # this doesn't run rubocop because there are untracked files
  refute git_rebasing
  run git_untracked
  assert_output "foo.rb"

  # manually lint
  git_stash_only_untracked
  yes y | git_autolint_head
  refute git_rebasing

  git stash pop
  run git_untracked
  assert_output "foo.rb"
}

@test "patch add pass rubocop hook" {
  good_rb > foo.rb
  git add foo.rb
  bad_rb >> foo.rb
  run git diff --cached --name-only
  assert_output "foo.rb"
  run git diff --name-only
  assert_output "foo.rb"
  echo n | gc "Pass rubocop"
  refute git_rebasing
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(bad_rb)"
}

@test "patch add fail rubocop hook" {
  bad_rb > foo.rb
  git add foo.rb
  good_rb >> foo.rb
  run git diff --cached --name-only
  assert_output "foo.rb"
  run git diff --name-only
  assert_output "foo.rb"
  ( echo n | gc "Fail rubocop" ) || true
  assert git_rebasing
  good_rb > foo.rb
  echo y | grc
  refute git_rebasing
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(good_rb)"
}

@test "patch add autocorrect rubocop hook" {
  auto_bad_rb > foo.rb
  git add foo.rb
  echo "# comment" >> foo.rb
  run git diff --cached --name-only
  assert_output "foo.rb"
  run git diff --name-only
  assert_output "foo.rb"
  yes y | gc "Auto rubocop"
  refute git_rebasing
  assert_equal "$(cat foo.rb)" "$(good_rb)
# comment"
}

@test "patch add conflict fail rubocop hook" {
  bad_rb > foo.rb
  git add foo.rb
  good_rb > foo.rb
  echo "CONFLICT = false" >> foo.rb
  ( echo q | gc "Fail rubocop" ) || true
  assert git_rebasing
  good_rb > foo.rb
  echo "CONFLICTED = true" >> foo.rb
  echo y | grc
  refute git_rebasing

  run git log --format="%s"
  assert_output "Fail rubocop
Initial commit"
  # assert_git_stash_empty
  assert_equal "$(cat foo.rb)" "$(good_rb)
<<<<<<< Updated upstream
CONFLICTED = true
||||||| constructed merge base
=======
CONFLICT = false
>>>>>>> Stashed changes"
}
