# `rd` rails database
function rd() {
  title 'Migrating'
  echodo bundle exec rake db:migrate
  title
}

# `rc` rails console
function rc(){
  title 'Console'
  echodo rails console
  title
}

# `rg <generate command>` rails generate
function rg(){
  echodo rails generate $*
}

# `rgm <new migration>` rails generate migration
# run rails generate <new migration>, open the migration file, migrate the database.
function rgm(){
  local filename=$(rg migration $* | awk '/db\/migrate/ {print $2}')
  if [[ ! -z $filename ]]; then
    echodo subl -nw $filename
    if [[ -s $filename ]]; then
      rd
    else
      echodo rm $filename
    fi
  fi
}

# `rds` rails database soft
# migrate the database, but skip the schema dump
function rds(){
  SKIP_SCHEMA_DUMP=1 rd && gb db/schema.rb
}

# `rdt` rails database test
# migrate the test database, and skip the schema dump
function rdt(){
  RAILS_ENV=test rd && gb db/schema.rb
}

# `rs [<port offset>] [<host>] [<path>]` rails server
# start a rails server on <port offset> or 3000
# once it's ready, open <host>.lvh.me:<port>/<path>
function rs(){
  local port=$(port_offset 3000 $1)
  local host=$(local_host_name $2)
  local path=$3

  echodo kill_port $port
  wait_for_port_then "echodo open -g http://$host:$port$path" $port

  title "Server:$port"
  echodo rails server -p $port --pid=tmp/pids/server$port.pid -b 0.0.0.0
  title
}

# `rt [<test files>]` shortcut for rspec.
function rt(){
  title "Spec"
  echodo bundle exec rspec -f d $*
  title
}