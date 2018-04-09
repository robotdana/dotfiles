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
