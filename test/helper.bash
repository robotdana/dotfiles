source ~/.dotfiles/functions/bash_support.sh

load './test_helper/bats-support/load'
load './test_helper/bats-assert/load'
load './test_helper/bats-file/load'

function setup_git() {
  rm -rf ~/.git-test-repo
  mkdir ~/.git-test-repo
  cd ~/.git-test-repo || exit
  git init
}

function reset_to_first_commit() {
  cd ~/.git-test-repo || exit

  run git merge --abort
  run git rebase --abort
  git checkout --quiet  main --
  if [[ ! -z "$(git branch --list | grep -Fv '* main')" ]]; then
    git branch -D $(git branch --list | grep -Fv '* main')
  fi
  git reset --hard "$(git log --reverse --format="%H" | head -n 1)" --
  git clean -fd
  git stash clear

  run git status
  assert_output "On branch main
nothing to commit, working tree clean"

  run git stash list
  assert_output ""

  run git log --format="%s"
  assert_output "Initial commit"

  assert_equal "$(ls -1A | grep -Fv .git)" "$(git show --pretty="" --name-only HEAD | sort)"
}

function assert_git_status_clean {
  run git status
  assert_output "On branch main
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
  puts true
end"
}

function bad_rb(){
  echo "# frozen_string_literal: true

def bar
  puts str { true }
end"
}
