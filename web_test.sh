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

# This page exists
echo -n "Fetching an existing URL:    "
url="https://www.debian.org/"
page=$(get_url $url)
test_eval $?

echo -n "Another way to evaluate:     "
page=$(get_url $url)
[[ $? == 0 ]]
test_eval $?

echo -n "Yet another way to evaluate: "
page=$(get_url $url)
if [[ $? == 0 ]]; then
  pass
else
  fail
fi

echo -n "The page is not empty:       "
[[ $page != "" ]]
test_eval $?

echo -n "Another way to evaluate:     "
if [[ "$(get_url $url)" != "" ]]; then
  pass
else
  fail
fi

echo -n "Yet another way to evaluate: "
if [ "$(get_url $url)" != "" ]; then
  pass
else
  fail
fi

echo -n "Fetching an invalid URL:     "
url="https://www.theehee.org/"
page=$(get_url $url)
[[ $? != 0 ]]
test_eval $?

echo -n "The page is empty:           "
[[ $page == "" ]]
test_eval $?

# Finished testing
testing_ends $0 $script_under_test
