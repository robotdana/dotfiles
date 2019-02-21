function rails_migrate_all {
  case $(git_current_repo) in
    marketplacer) local task_name='multitenant:db:migrate';;
    *)            local task_name='db:migrate';;
  esac
  echodo bundle exec rails $task_name
  [[ ! $SKIP_SCHEMA_DUMP ]] && local schema_dump='db:schema:dump'
  echodo RAILS_ENV=test bundle exec rails db:migrate $schema_dump
}

function rails_migrate_all_soft {
  mv db/schema.rb db/schema.rb.bak
  SKIP_SCHEMA_DUMP=1 rails_migrate_all
  mv db/schema.rb.bak db/schema.rb
}

function rails_migrate_soft {
  mv db/schema.rb db/schema.rb.bak
  SKIP_SCHEMA_DUMP=1 echodo bundle exec rails db:migrate
  mv db/schema.rb.bak db/schema.rb
}

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
