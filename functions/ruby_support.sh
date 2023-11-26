if [[ -f /usr/local/opt/chruby/share/chruby/chruby.sh ]]; then
  source /usr/local/opt/chruby/share/chruby/chruby.sh
  source /usr/local/opt/chruby/share/chruby/auto.sh
fi

# source $(brew --prefix)/opt/asdf/libexec/asdf.sh

if [[ -f /opt/homebrew/opt/chruby/share/chruby/chruby.sh ]]; then
  source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
  source /opt/homebrew/opt/chruby/share/chruby/auto.sh
fi

function reinstall_ruby {
  [[ -z "$(type chruby 2>/dev/null)" ]] && echoerr "chruby is missing" && return 1
  which -s ruby-install || ( echoerr "ruby-install is missing" && return 1 )

  ruby_path=$(which ruby)

  if [[ ! "$ruby_path" = *.rubies* ]]; then
    echoerr "existing ruby isn't installed with chruby" && return 1
  fi

  chruby_identifier=$(chruby | grep '\*' | cut -d' ' -f3)

  rm -rf "${ruby_path%/bin/ruby}"
  ruby-install "$chruby_identifier"
  install_bundler
  bundle
}

function install_bundler {
  gem install --no-doc --silent --norc bundler:"$(echo $(tail -n 1 Gemfile.lock))"
}

function reload_chruby {
  export RUBIES=( $(command ls -d1 ~/.rubies/*) )
  chruby
}
