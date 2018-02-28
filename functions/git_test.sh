function git_test_init(){
  rm -rf ~/.dotfiles/locals/test
  mkdir ~/.dotfiles/locals/test
  cd ~/.dotfiles/locals/test
  git init
  git commit --no-verify -m "initial commit"
  git_fake_stash_clear
}
function git_test_init_rubocop(){
  git_test_init
  echo "gem 'rubocop'" > Gemfile
  bundle
  echo > .rubocop.yml
  git add .
  git commit --no-verify -m "add rubocop"
}

function git_test_rubocop_both() {
  git_test_init_rubocop
  echo "# frozen_string_literal: true

def something
  true
end" > foo.rb
  echo "def something


  true


end" > bar.rb
  gc "foo that should pass"
echo "

def something_else
  false
end" >> foo.rb
  gc "bar that needs filtering"
}

function git_test_rubocop_pass() {
  git_test_init_rubocop
  echo "# frozen_string_literal: true

def something
  true
end" > foo.rb
  gc "foo that should pass"
}

function git_test_rubocop_patch() {
  git_test_init_rubocop
  echo "# frozen_string_literal: true

def something
  true
end

def something_else


  false
end" > foo.rb
  gc "foo that should pass"
}
