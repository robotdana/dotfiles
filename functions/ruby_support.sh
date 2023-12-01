# echo "required ruby_support"
# echo "$HOME"
source $(brew --prefix chruby)/share/chruby/chruby.sh
source $(brew --prefix chruby)/share/chruby/auto.sh

function install_bundler {
  gem install --no-doc --silent --norc bundler:"$(echo $(tail -n 1 Gemfile.lock))"
}

# ruby-install 3.2.2
function ruby-install {
  local version=${1:-$(cat .ruby-version)}
  if [[ -z "$version" ]]; then
    echoerr "No version given"
  else
    mkdir -p ~/.rubies
    echodo ruby-build $1 "$HOME/.rubies/$1" && echo_green "Install succeeded, restart the shell to use" && exit 0
  fi
}
