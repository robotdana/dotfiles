# `jeks` jekyll server
# start a jekyll server, then open the home page
# TODO: start guard at the same time
function jeks(){
  echodo kill_port 4000
  title "Server:4000"
  wait_for_port_then "echodo open -g http://localhost:4000" 4000
  echodo bundle exec jekyll serve --incremental && title
}
