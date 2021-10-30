load helper


function test_can_do_the_thing() {
  echoerr "No"
  exit 1
}

function test_do_the_thing() {
  test_can_do_the_thing
  echo "do the thing"
}

@test "echoerr" {
  run test_do_the_thing
  assert_failure
  assert_output "$(echo_red No)"
}

@test "quote_item" {
  # basic
  assert_equal "$(quote 1)" "1"
  assert_equal "$(quote '1')" "1"
  assert_equal "$(quote "1")" "1"

  # empty string
  assert_equal "$(quote "")" '""'

  # no arg
  assert_equal "$(quote)" ""

  # prefer single quotes
  assert_equal "$(quote 1 and 2)" "'1 and 2'"
  assert_equal "$(quote "1 and 2")" "'1 and 2'"
  assert_equal "$(quote '1 an'd 2)" "'1 and 2'"
  assert_equal "$(quote \(whatever\))" "'(whatever)'"
  assert_equal "$(quote '(whatever)')" "'(whatever)'"
  assert_equal "$(quote '[whatever]')" "'[whatever]'"
  assert_equal "$(quote 'whatever]')" "'whatever]'"
  assert_equal "$(quote 'what)ever]')" "'what)ever]'"
  assert_equal "$(quote 'what) ever')" "'what) ever'"
  assert_equal "$(quote 'what<ever')" "'what<ever'"
  assert_equal "$(quote 'what>ever')" "'what>ever'"
  assert_equal "$(quote 'what

  ever')" "'what

  ever'"

  assert_equal "$(quote '$dance')" "'\$dance'"
  assert_equal "$(quote '"$dance"')" "'\"\$dance\"'"

  # prefer not escaping single quotes.
  # this requires escaping ",$
  assert_equal "$(quote don\'t)" "\"don't\""


  assert_equal "$(quote "\"don't\"")" "\"\\\"don't\\\"\""
  assert_equal "$(quote "\"\$dance'\"")" "\"\\\"\\\$dance'\\\"\""

  # I never want history expansion
  # so I `set +H` in bash_profile
  # so I don't need to escape `!`
  assert_equal "$(quote "don't !")" "\"don't !\""
}
@test "quote_array" {
  assert_equal "$(quote_array 1 '1 and 2')" "1 '1 and 2'"
  assert_equal "$(quote_array "don\'t" "(whatever)")" "\"don\'t\" '(whatever)'"
  assert_equal "$(quote_array "" "" -- "")" '"" "" -- ""'
}

@test "quote_lines" {
  assert_equal "$(echo '1
  2
  3' | quote_lines)" "1
2
3"
  assert_equal "$(echo '1 2 3
  4
  5' | quote_lines)" "'1 2 3'
4
5"
}
