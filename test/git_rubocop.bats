#!/usr/bin/env bats

load helper

source ~/.dotfiles/functions/git_support.sh

function setup() {
  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    setup_git
    echo 'gem "rubocop"' > Gemfile
    echo '#' > .rubocop.yml
    bundle --quiet
    git add .
    git commit --no-verify -m "initial commit"
  else
    reset_to_first_commit
  fi
}

@test "pass rubocop hook" {
  good_rb > foo.rb
  good_rb > bar.rb
  git add .
  git commit -m "pass rubocop"
  assert_git_status_clean
  assert_git_stash_empty
}

@test "fail rubocop hook" {
  bad_rb > foo.rb
  bad_rb > bar.rb
  git add .
  run git commit -m "fail rubocop"
  assert_cleaned_output "bundle exec rubocop --parallel --force-exclusion --color bar.rb foo.rb
Inspecting 2 files
CC

Offenses:

bar.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning.
foo.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning.

2 files inspected, 2 offenses detected"
  run git diff --cached --name-only
  assert_line "bar.rb"
  assert_line "foo.rb"
  assert_git_stash_empty

  good_rb > foo.rb
  good_rb > bar.rb

  git add .

  git commit -m "pass rubocop"

  assert_git_status_clean
  assert_git_stash_empty
}

@test "partial add pass rubocop hook" {
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
  good_rb > foo.rb
  bad_rb > bar.rb
  git add bar.rb
  run git commit -m "fail rubocop"
  assert_cleaned_output "git stash save --include-untracked --quiet 'fake autostash'
bundle exec rubocop --parallel --force-exclusion --color bar.rb
Inspecting 1 file
C

Offenses:

bar.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning.

1 file inspected, 1 offense detected"
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
  bad_rb > foo.rb
  git add foo.rb
  good_rb >> foo.rb
  run git commit -m "fail rubocop"
  assert_cleaned_output "git stash save --include-untracked --quiet 'fake autostash'
bundle exec rubocop --parallel --force-exclusion --color foo.rb
Inspecting 1 file
C

Offenses:

foo.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning.

1 file inspected, 1 offense detected"
  good_rb > foo.rb
  git add foo.rb
  git commit -m "pass rubocop"
  assert_equal "$(cat foo.rb)" "$(good_rb)
$(good_rb)"
}

@test "patch add conflict fail rubocop hook" {
  bad_rb > foo.rb
  git add foo.rb
  good_rb > foo.rb
  echo "CONFLICT = false" >> foo.rb
  run git commit -m "fail rubocop"
  assert_cleaned_output "git stash save --include-untracked --quiet 'fake autostash'
bundle exec rubocop --parallel --force-exclusion --color foo.rb
Inspecting 1 file
C

Offenses:

foo.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning.

1 file inspected, 1 offense detected"
  good_rb > foo.rb
  echo "CONFLICTED = true" >> foo.rb
  git add foo.rb
  git commit -m "pass rubocop"

  run git log --format="%s"
  assert_output "pass rubocop
initial commit"
  assert_git_stash_empty
  assert_equal "$(cat foo.rb)" "$(good_rb)
CONFLICT = false"
}
