#!/bin/bash

script_under_test=src/utils/local.sh

# Import test framework
set -e
. src/testing.sh
testing_begins $0 $script_under_test

# Import the functions under test
. $script_under_test
set +e

#
# Tests
#

# Test is_set
echo -n "is_set returns true:  "
export TEST="123"
is_set TEST
test_eval $?

echo -n "is_set returns false: "
unset TEST
! is_set TEST
test_eval $?

# bash is available, as it is the shell used to run this test
echo -n "is_program_available returns true:  "
is_program_available bash
test_eval $?

# There's no such program
echo -n "is_program_available returns false: "
! is_program_available theehee
test_eval $?

# Finished testing
testing_ends $0 $script_under_test
