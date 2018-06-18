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

@test "quote_array" {
  assert_equal "$(quote_array '1')" "1 "
  assert_equal "$(quote_array '1 and 2')" "'1 and 2' "
  assert_equal "$(quote_array "don't")" "\"don't\" "
  assert_equal "$(quote_array "(whatever)")" "'(whatever)' "
  assert_equal "$(quote_array "")" "'' "

  assert_equal "$(quote_array 1 '1 and 2')" "1 '1 and 2' "
  assert_equal "$(quote_array "don\'t" "(whatever)")" "\"don\'t\" '(whatever)' "
  assert_equal "$(quote_array "" "" -- "")" "'' '' -- '' "
}
