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
# Test fetching Debian package download URLs
#

# This should return a bunch of URLs
echo -n "Requesting an existing package:    "
urls=$(get_debian_package_download_urls lynx)
test_eval $?

# Such a program does not exist
echo -n "Requesting a non-existent package: "
urls=$(get_debian_package_download_urls theehee)
[[ $? != 0 ]]
test_eval $?

#
# Test Debian package download
#
echo -n "Download an existing package:      "
rm -f /tmp/*.deb
path=$(debian_download_package lynx)
test_eval $?
rm -f /tmp/*.deb

echo -n "Download a non-existent package:   "
rm -f /tmp/*.deb
path=$(debian_download_package theehee)
[[ $? != 0 ]]
test_eval $?
rm -f /tmp/*.deb

# Finished testing
testing_ends $0 $script_under_test
