#!/bin/bash

script_under_test=src/webapi/github.sh

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
echo -n "Get account info: "
github_get_public_info_json matthiasbock
test_eval $?

echo -n "Get account type: "
github_get_account_type matthiasbock
test_eval $?

echo -n "is_github_user() returns true: "
is_github_user matthiasbock
test_eval $?

echo -n "is_github_user() returns false: "
is_github_user thinserver
[[ $? != 0 ]]
test_eval $?

echo -n "is_github_organization() returns true: "
is_github_organization thinserver
test_eval $?

echo -n "is_github_organization() returns false: "
is_github_organization matthiasbock
[[ $? != 0 ]]
test_eval $?

echo -n "Get repository JSON: "
github_get_public_repos_json thinserver
test_eval $?

echo -n "Get repositories: "
github_get_public_repos thinserver
test_eval $?

# Finished testing
testing_ends $0 $script_under_test
