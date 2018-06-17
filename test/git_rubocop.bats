#!/usr/bin/env bats

load helper

function setup() {
  if [[ "$BATS_TEST_NUMBER" -eq "1" ]]; then
    rm -rf ~/.git-test-repo
    mkdir ~/.git-test-repo
    cd ~/.git-test-repo || exit
    git init
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
  assert_cleaned_output "bar.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning."
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
  assert_cleaned_output "foo.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning."
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
  assert_cleaned_output "foo.rb:4:1: C: Layout/EmptyLinesAroundMethodBody: Extra empty line detected at method body beginning."
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
