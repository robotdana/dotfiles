function git_test_good_rb() {
  echo "# frozen_string_literal: true

def foo
  true
end"
}

function git_test_bad_rb(){
  echo "# frozen_string_literal: true

def bar

  true
end"
}

function git_test_init(){
  echo_green $@
  echodo rm -rf ~/.git-test-repo
  echodo mkdir ~/.git-test-repo
  echodo cd ~/.git-test-repo
  echodo git init
  echodo 'echo "#TODO" > readme.txt'
  echodo git add readme.txt
  echodo git commit --no-verify -m "initial commit"
}

function git_test_init_rubocop(){
  git_test_init $*
  echodo "echo 'gem \"rubocop\"' > Gemfile"
  echodo bundle --quiet
  echodo 'echo > .rubocop.yml'
  echodo git add .
  echodo git commit -m "add rubocop"
}

function git_test_fake_stash(){
  git_test_init git_test_fake_stash
  git_test_good_rb > foo.rb
  git_test_good_rb > bar.rb
  git_fake_stash

  if [[ -s foo.rb ]] && [[ -s bar.rb ]]; then
    echoerr "didn't remove added files"
  fi

  git_status_clean || echoerr "branch is not clean"

  if [[ -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is empty"
  fi
}

function git_test_fake_stash_pop(){
  git_test_init git_test_fake_stash_pop
  git_test_good_rb > foo.rb
  git_test_good_rb > bar.rb
  git_fake_stash
  git_fake_stash_pop
  if [[ ! -z "$(comm -3 foo.rb <( git_test_good_rb ))" ]] && [[ ! -z "$(comm -3 bar.rb <( git_test_good_rb ))" ]]; then
    echoerr "didn't restore added files"
  fi

  git_status_clean && echoerr "branch is not dirty"

  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi
}

function git_test_pass_rubocop(){
  git_test_init_rubocop git_test_pass_rubocop
  git_test_good_rb > foo.rb
  git_test_good_rb > bar.rb
  echodo git add .
  gc "pass rubocop"
  git_status_clean || echoerr "branch is not clean"
  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi
}

function git_test_fail_rubocop(){
  git_test_init_rubocop git_test_fail_rubocop
  git_test_bad_rb > foo.rb
  git_test_bad_rb > bar.rb
  echodo git add .
  gc "fail rubocop" 2>&1
  git_status_clean && echoerr "branch is clean"
  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi

  git_test_good_rb > foo.rb
  git_test_good_rb > bar.rb

  echodo git add .
  gc "pass rubocop"

  git_status_clean || echoerr "branch is dirty"
  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi
}

function git_test_partial_add_pass_rubocop(){
  git_test_init_rubocop git_test_partial_add_pass_rubocop
  git_test_good_rb > foo.rb
  git_test_bad_rb > bar.rb
  echodo git add foo.rb
  echodo git commit -m "pass rubocop"
  git_status_clean && echoerr "branch is not dirty"
  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi
  if [[ ! -z "$(comm -3 bar.rb <( git_test_bad_rb ))" ]]; then
    echoerr "didn't restore added files"
  fi
}

function git_test_partial_add_fail_rubocop(){
  git_test_init_rubocop git_test_partial_add_fail_rubocop
  git_test_good_rb > foo.rb
  git_test_bad_rb > bar.rb
  echodo git add bar.rb
  echodo git commit -m "fail rubocop"
  git_status_clean && echoerr "branch is not dirty"
  if [[ -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is empty"
  fi
  if [[ -s foo.rb ]]; then
    echoerr "restored stash"
  fi

  git_test_good_rb > bar.rb

  echodo git add bar.rb
  echodo git commit -m "pass rubocop"

  git_status_clean && echoerr "branch is not dirty"
  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi
}

function git_test_patch_add_pass_rubocop(){
  git_test_init_rubocop git_test_patch_add_pass_rubocop
  git_test_good_rb > foo.rb
  echodo git add foo.rb
  git_test_bad_rb >> foo.rb
  echodo git commit -m "pass rubocop"
  git_status_clean && echoerr "branch is not dirty"
  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi
  git_test_good_rb > baz.rb
  git_test_bad_rb >> baz.rb
  if [[ ! -z "$(comm -3 foo.rb baz.rb)" ]]; then
    echoerr "didn't restore added files"
  fi
  echodo rm baz.rb
}

function git_test_patch_add_fail_rubocop(){
  git_test_init_rubocop git_test_patch_add_fail_rubocop
  git_test_bad_rb > foo.rb
  echodo git add foo.rb
  git_test_good_rb >> foo.rb
  echodo git commit -m "fail rubocop"
  git_status_clean && echoerr "branch is not dirty"
  if [[ -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is empty"
  fi
  git_test_good_rb > foo.rb
  echodo git add foo.rb
  echodo git commit -m "pass rubocop"
  if [[ ! -z "$(git_fake_stash_list)" ]]; then
    echoerr "fake stash is not empty"
  fi
  git_test_good_rb > baz.rb
  git_test_good_rb >> baz.rb
  if [[ ! -z "$(comm -3 foo.rb baz.rb)" ]]; then
    echoerr "didn't restore added files"
  fi
  echodo rm baz.rb
}

function git_test(){
  ( git_test_fake_stash )
  ( git_test_fake_stash_pop )
  ( git_test_pass_rubocop )
  ( git_test_fail_rubocop )
  ( git_test_partial_add_pass_rubocop )
  ( git_test_partial_add_fail_rubocop )
  ( git_test_patch_add_pass_rubocop )
  ( git_test_patch_add_fail_rubocop )
}