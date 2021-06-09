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
  bundler_version=$(tail -n 1 Gemfile.lock)
  gem install bundler "${bundler_version/#/--version=}"
  bundle
}
