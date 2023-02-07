#!/bin/bash

script_under_test=src/control.sh

# Import test framework
set -e
. src/testing.sh
testing_begins $0 $script_under_test

# Import the functions under test
. $script_under_test
set +e

echo "Testing get_container_names..."
names=$(get_container_names)
test_eval $?

# container_exists
# container_create
# container_remove

# container_start
# container_is_running
# container_stop

# container_exec

# Finished testing
testing_ends $0 $script_under_test
