#!/usr/bin/env bats

load helper

source ~/.dotfiles/functions/git_support.sh
source ~/.dotfiles/functions/bash_support.sh
source ~/.dotfiles/functions/git_aliases.sh
if [[ -f /usr/local/opt/chruby/share/chruby/chruby.sh ]]; then
  source /usr/local/opt/chruby/share/chruby/chruby.sh
fi

function setup() {
  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    setup_git
    if declare -fF chruby >/dev/null; then
      chruby 2.7.0
    fi

    run ruby -v
    assert_output --partial "ruby 2.7"
    gem install bundler

    echo "
      source 'https://rubygems.org'
      gem 'rubocop', '1.0.0'
    " > Gemfile
    touch Gemfile.lock
    echo "
      AllCops:
        NewCops: enable
    " > .rubocop.yml
    bundle
    bundle lock --add-platform universal-darwin-20
    bundle lock --add-platform x86_64-darwin-18
    git add .
    git commit --no-verify -m "Initial commit"
  else
    reset_to_first_commit
    if declare -fF chruby >/dev/null; then
      chruby 2.7.0
    fi
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

  git add .
  grce

  assert_git_status_clean
  assert_git_stash_empty
  refute git_rebasing
}

# this doesn't run rubocop because there are untracked files
@test "partial add pass rubocop hook" {
  good_rb > foo.rb
  bad_rb > bar.rb
  git add foo.rb
  ( yes q | gc "Pass rubocop" ) || true
  refute git_rebasing
  run git_untracked
  assert_output "bar.rb"
  assert_git_stash_empty
  bad_rb > baz.rb
  assert_equal "$(cat bar.rb)" "$(cat baz.rb)"
}

# this doesn't run rubocop because there are untracked files
@test "partial add fail rubocop hook" {
  good_rb > foo.rb
  bad_rb > bar.rb
  git add bar.rb
  git status
  ( yes q | gc "Fail rubocop" ) || true
  refute git_rebasing
  git stash -u
  good_rb > bar.rb
  git add .
  gcf
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
  yes q | gc "Pass rubocop"
  refute git_rebasing
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(bad_rb)"
}

@test "patch add fail rubocop hook" {
  bad_rb > foo.rb
  git add foo.rb
  good_rb >> foo.rb
  ( yes q | gc "Fail rubocop" ) || true
  assert git_rebasing
  good_rb > foo.rb
  git add foo.rb
  grce
  refute git_rebasing
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(good_rb)"
}

@test "patch add conflict fail rubocop hook" {
  bad_rb > foo.rb
  git add foo.rb
  good_rb > foo.rb
  echo "CONFLICT = false" >> foo.rb
  ( yes q | gc "Fail rubocop" ) || true
  assert git_rebasing
  good_rb > foo.rb
  echo "CONFLICTED = true" >> foo.rb
  git add foo.rb
  grce
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
