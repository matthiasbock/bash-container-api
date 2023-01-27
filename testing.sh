
#
# Common functions for testing
#

function testing_begins() {
  local test_script="$(basename $1)"
  local script_under_test="$(basename $2)"

  echo "-------------------------------------------"
  echo "$test_script: Begin testing $script_under_test ..."
  # set -e
  # set -o errtrace # Enable the err trap, code will get called when an error is detected
  # trap "echo ERROR: There was an error in ${FUNCNAME-main context}, details to follow" ERR

  # set -x
}

function testing_ends() {
  # set +x
  set +e
  local test_script="$(basename $1)"
  local script_under_test="$(basename $2)"

  echo "$test_script: Testing $script_under_test completed."
  echo "-------------------------------------------"
}
