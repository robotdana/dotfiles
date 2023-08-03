source ~/.dotfiles/functions/bash_support.sh

load './test_helper/bats-support/load'
load './test_helper/bats-assert/load'
load './test_helper/bats-file/load'

function setup_git() {
  rm -rf ~/.git-test-repo
  mkdir ~/.git-test-repo
  cd ~/.git-test-repo || exit
  git init -b main
}

function reset_to_first_commit() {
  cd ~/.git-test-repo || exit

  run git rebase --abort
  run git merge --abort
  run git reset --hard HEAD --
  git checkout --quiet main --
  echo git branch --list
  if [[ ! -z "$(git branch --list | grep -Fv '* main')" ]]; then
    echodo git branch -D $(git branch --list | grep -Fv '* main')
  fi
  git reset --hard "$(git log --reverse --format="%H" | head -n 1)" --
  git clean -fd
  git stash clear

  assert_git_status_clean
  assert_git_stash_empty

  run git log --format="%s"
  assert_output "Initial commit"

  assert_equal "$(ls -1A | grep -Fv .git)" "$(git show --pretty="" --name-only HEAD | sort)"
}

function assert_git_status_clean {
  run git status --long
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

def bar(unused_keyword: true)
  puts true
  puts true
  puts true
  puts true
  puts true
  puts true
  puts true
  puts true
  puts true
end"
}

function auto_bad_rb(){
  echo "def foo()

    puts true

  end"
}


