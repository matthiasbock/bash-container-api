#!/bin/bash

script_under_test=include.sh

# Import test framework
. src/testing.sh
testing_begins $0 $script_under_test

# Import the functions under test
echo -n "Testing import of "
. $script_under_test
test_eval $?

# That's it. Just testing, whether sourcing the include script throws any errors.

# Finished testing
testing_ends $0 $script_under_test
