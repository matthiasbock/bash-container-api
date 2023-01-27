#!/bin/bash

script_under_test=debian.sh

# Import test framework
. testing.sh
testing_begins $0 $script_under_test

# Import dependencies
. local.sh
. web.sh

# Import the functions under test
. $script_under_test

#
# Tests
#

# This should return a bunch of URLs:
urls=$(get_debian_package_download_urls lynx)
echo $?
echo $urls

# Finished testing
testing_ends $0 $script_under_test