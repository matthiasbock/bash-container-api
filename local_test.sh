#!/bin/bash

script_under_test=local.sh

# Import test framework
. testing.sh
testing_begins $0 $script_under_test

# Import the functions under test
. $script_under_test

#
# Tests
#

# Test is_set
echo -n "is_set returns true: "
export TEST="123"
if is_set TEST; then
  echo "Success"
else
  echo "Failed"
fi

echo -n "is_set returns false: "
unset TEST
if ! is_set TEST; then
  echo "Success"
else
  echo "Failed"
fi

# bash is available, as it is the shell used to run this test
echo -n "is_program_available returns true: "
if is_program_available bash; then
  echo "Success"
else
  echo "Failed"
fi

# There's no such program
echo -n "is_program_available returns false: "
if ! is_program_available theehee; then
  echo "Success"
else
  echo "Failed"
fi

# Finished testing
testing_ends $0 $script_under_test
