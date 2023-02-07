#!/bin/bash

script_under_test=src/utils/web.sh

# Import test framework
set -e
. src/testing.sh
testing_begins $0 $script_under_test

# Import dependencies
. src/utils/local.sh

# Import the functions under test
. $script_under_test
set +e

#
# Test function get_page()
#
echo -n "Fetching an existing URL:    "
url="https://www.debian.org/"
page=$(get_page $url 2>/dev/null)
test_eval $?

echo -n "Another way to evaluate:     "
page=$(get_page $url 2>/dev/null)
[[ $? == 0 ]]
test_eval $?

echo -n "Yet another way to evaluate: "
page=$(get_page $url 2>/dev/null)
if [[ $? == 0 ]]; then
  pass
else
  fail
fi

echo -n "The page is not empty:       "
[[ $page != "" ]]
test_eval $?

echo -n "Another way to evaluate:     "
if [[ "$(get_page $url 2>/dev/null)" != "" ]]; then
  pass
else
  fail
fi

echo -n "Yet another way to evaluate: "
if [ "$(get_page $url 2>/dev/null)" != "" ]; then
  pass
else
  fail
fi

echo -n "Fetching an invalid URL:     "
url="https://www.theehee.org/"
page=$(get_page $url 2>/dev/null)
[[ $? != 0 ]]
test_eval $?

echo -n "The page is empty:           "
[[ $page == "" ]]
test_eval $?

#
# Test function get_file()
#
echo -n "Download an existing Debian package:   "
filepath="/tmp/libncursesw6_6.2+20201114-2_amd64.deb"
rm -f $filepath
url="http://ftp.de.debian.org/debian/pool/main/n/ncurses/libncursesw6_6.2+20201114-2_amd64.deb"
get_file $filepath $url &>/dev/null
test_eval $?

echo -n "Request a non-existent Debian package: "
filepath="/tmp/libncursesw6_6.2+20201114-2_amd64.deb"
rm -f $filepath
url="http://ftp.de.debian.org/debian/pool/main/n/ncurses/libncursesw12345_amd64.deb"
get_file $filepath $url &>/dev/null
[[ $? != 0 ]]
test_eval $?

# Finished testing
testing_ends $0 $script_under_test
