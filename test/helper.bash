#!/usr/bin/env bats

source ~/.dotfiles/functions/bash_support.sh

function echodo(){
  echo $(quote_array "$@")
  eval $(quote_array "$@")
}

TEST_BREW_PREFIX="$(brew --prefix)"
source "${TEST_BREW_PREFIX}/lib/bats-support/load.bash"
source "${TEST_BREW_PREFIX}/lib/bats-assert/load.bash"
source "${TEST_BREW_PREFIX}/lib/bats-file/load.bash"

function reset_to_first_commit() {
  cd ~/.git-test-repo || exit

  git reset --hard "$(git log --reverse --format="%H" | head -n 1)" --
  git clean -fd
  git stash clear

  run git status
  assert_output "On branch master
nothing to commit, working tree clean"

  run git stash list
  assert_output ""

  run git log --format="%s"
  assert_output "initial commit"

  assert_equal "$(ls -1A)" ".git
$(git show --pretty="" --name-only HEAD)"
}

function assert_git_status_clean {
  run git status
  assert_output "On branch master
nothing to commit, working tree clean"
}

function assert_git_stash_empty {
  run git stash list
  assert_output ""
}

function assert_cleaned_output {
  output="$(strip_color "$output")"
  assert_output "$@"
}

function good_rb() {
  echo "# frozen_string_literal: true

def foo
  true
end"
}

function bad_rb(){
  echo "# frozen_string_literal: true

def bar

  true
end"
}
