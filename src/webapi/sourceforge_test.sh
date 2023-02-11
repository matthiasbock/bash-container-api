#!/bin/bash

script_under_test=src/webapi/sourceforge.sh

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
# TODO

# Finished testing
testing_ends $0 $script_under_test
