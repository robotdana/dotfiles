eval "$(rbenv init - bash)"

function install_bundler {
  gem install --no-doc --silent --norc bundler:"$(echo $(tail -n 1 Gemfile.lock))"
}
