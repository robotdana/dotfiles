#!/usr/bin/env bats

source ~/.dotfiles/functions/bash_support.sh

function echodo(){
  echo $(quote_array "$@")
  eval $(quote_array "$@")
}

source ~/.dotfiles/functions/git_support.sh

TEST_BREW_PREFIX="$(brew --prefix)"
source "${TEST_BREW_PREFIX}/lib/bats-support/load.bash"
source "${TEST_BREW_PREFIX}/lib/bats-assert/load.bash"
source "${TEST_BREW_PREFIX}/lib/bats-file/load.bash"

function git_test_init() {
  rm -rf ~/.git-test-repo
  mkdir ~/.git-test-repo
  cd ~/.git-test-repo
  git init
  echo "#TODO" > readme.txt
  git add readme.txt
  git commit --no-verify -m "initial commit"
}

function git_test_init_rubocop() {
  git_test_init
  echo 'gem "rubocop"' > Gemfile
  bundle --quiet
  echo > .rubocop.yml
  git add .
  git commit -m "add rubocop"
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
