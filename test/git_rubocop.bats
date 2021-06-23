#!/usr/bin/env bats

load helper

source ~/.dotfiles/functions/git_support.sh
source /usr/local/opt/chruby/share/chruby/chruby.sh

function setup() {
  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    setup_git
    chruby 2.7.0

    run ruby -v
    assert_output --partial "ruby 2.7.0"
    gem install bundler

    echo "
      source 'https://rubygems.org'
      gem 'rubocop', '1.0.0'
    " > Gemfile
    echo "
      AllCops:
        NewCops: enable
    " > .rubocop.yml
    bundle --quiet
    git add .
    git commit --no-verify -m "Initial commit"
  else
    reset_to_first_commit
    chruby 2.7.0
  fi
}

@test "pass rubocop hook" {
  good_rb > foo.rb
  good_rb > bar.rb
  git add .
  git commit -m "Pass rubocop"
  assert_git_status_clean
  assert_git_stash_empty
}

@test "fail rubocop hook" {
  bad_rb > foo.rb
  bad_rb > bar.rb
  git add .
  run git commit -m "Fail rubocop"
  assert_cleaned_output "bundle exec rubocop -a --force-exclusion --color --fail-level=C --display-only-fail-level-offenses bar.rb foo.rb
Inspecting 2 files
WW

Offenses:

bar.rb:4:3: W: Lint/AmbiguousBlockAssociation: Parenthesize the param str { true } to make sure that the block will be associated with the str method call.
  puts str { true }
  ^^^^^^^^^^^^^^^^^
foo.rb:4:3: W: Lint/AmbiguousBlockAssociation: Parenthesize the param str { true } to make sure that the block will be associated with the str method call.
  puts str { true }
  ^^^^^^^^^^^^^^^^^

2 files inspected, 2 offenses detected"
  run git diff --cached --name-only
  assert_line "bar.rb"
  assert_line "foo.rb"
  assert_git_stash_empty

  good_rb > foo.rb
  good_rb > bar.rb

  git add .

  git commit -m "Pass rubocop"

  assert_git_status_clean
  assert_git_stash_empty
}

@test "partial add pass rubocop hook" {
  good_rb > foo.rb
  bad_rb > bar.rb
  git add foo.rb
  git commit -m "Pass rubocop"
  run git_untracked
  assert_output "bar.rb"
  assert_git_stash_empty
  bad_rb > baz.rb
  assert_equal "$(cat bar.rb)" "$(cat baz.rb)"
}

@test "partial add fail rubocop hook" {
  good_rb > foo.rb
  bad_rb > bar.rb
  git add bar.rb
  run git commit -m "Fail rubocop"
  assert_cleaned_output "git stash save --include-untracked --quiet 'fake autostash'
bundle exec rubocop -a --force-exclusion --color --fail-level=C --display-only-fail-level-offenses bar.rb
Inspecting 1 file
W

Offenses:

bar.rb:4:3: W: Lint/AmbiguousBlockAssociation: Parenthesize the param str { true } to make sure that the block will be associated with the str method call.
  puts str { true }
  ^^^^^^^^^^^^^^^^^

1 file inspected, 1 offense detected"
  run git diff --cached --name-only
  assert_output "bar.rb"
  run git_untracked
  assert_output ""
  good_rb > bar.rb

  git add bar.rb
  git commit -m "Pass rubocop"

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
  git commit -m "Pass rubocop"
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(bad_rb)"
}

@test "patch add fail rubocop hook" {
  bad_rb > foo.rb
  git add foo.rb
  good_rb >> foo.rb
  run git commit -m "Fail rubocop"
  assert_cleaned_output "git stash save --include-untracked --quiet 'fake autostash'
bundle exec rubocop -a --force-exclusion --color --fail-level=C --display-only-fail-level-offenses foo.rb
Inspecting 1 file
W

Offenses:

foo.rb:4:3: W: Lint/AmbiguousBlockAssociation: Parenthesize the param str { true } to make sure that the block will be associated with the str method call.
  puts str { true }
  ^^^^^^^^^^^^^^^^^

1 file inspected, 1 offense detected"
  good_rb > foo.rb
  git add foo.rb
  git commit -m "Pass rubocop"
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(good_rb)"
}

@test "patch add conflict fail rubocop hook" {
  bad_rb > foo.rb
  git add foo.rb
  good_rb > foo.rb
  echo "CONFLICT = false" >> foo.rb
  run git commit -m "Fail rubocop"
  assert_cleaned_output "git stash save --include-untracked --quiet 'fake autostash'
bundle exec rubocop -a --force-exclusion --color --fail-level=C --display-only-fail-level-offenses foo.rb
Inspecting 1 file
W

Offenses:

foo.rb:4:3: W: Lint/AmbiguousBlockAssociation: Parenthesize the param str { true } to make sure that the block will be associated with the str method call.
  puts str { true }
  ^^^^^^^^^^^^^^^^^

1 file inspected, 1 offense detected"
  good_rb > foo.rb
  echo "CONFLICTED = true" >> foo.rb
  git add foo.rb
  git commit -m "Pass rubocop"

  run git log --format="%s"
  assert_output "Pass rubocop
Initial commit"
  assert_git_stash_empty
  assert_equal "$(cat foo.rb)" "$(good_rb)
CONFLICT = false"
}
