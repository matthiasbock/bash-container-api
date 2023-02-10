#!/bin/bash

script_under_test=src/webapi/github.sh

# Import test framework
set -e
. src/testing.sh
testing_begins $0 $script_under_test

# Import dependencies
. src/utils/local.sh
. src/utils/web.sh

# Import the functions under test
. $script_under_test
set +e

#
# Tests
#
# TODO

# Finished testing
testing_ends $0 $script_under_test
