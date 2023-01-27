#!/bin/bash

script_under_test=web.sh

# Import test framework
. testing.sh
testing_begins $0 $script_under_test

# Import dependencies
. local.sh

# Import the functions under test
. $script_under_test

#
# Tests
#

url="https://www.debian.org/"
page=$(get_url $url)
echo $?

# Finished testing
testing_ends $0 $script_under_test
