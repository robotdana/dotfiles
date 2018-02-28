
function rails_migrate_all_task_name {
  case $(git_current_repo) in
    marketplacer) echo 'multitenant:db:migrate';;
    *)            echo 'db:migrate';;
  esac
}

function rails_migrate_all {
  echodo bundle exec rails $(rails_migrate_all_task_name)
  echodo RAILS_ENV=test bundle exec rails db:migrate
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
