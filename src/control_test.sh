#!/bin/bash

script_under_test=src/control.sh

# Import test framework
set -e
. src/testing.sh
testing_begins $0 $script_under_test

# Import the functions under test
. src/constants.sh
. src/utils/local.sh
. src/cli.sh 2>/dev/null
. $script_under_test
set +e

container_cli=podman
container_name="bash-container-library-test"
podman stop "$container_name" &>/dev/null
podman remove "$container_name" &>/dev/null

echo "Testing container creation... "
container_create $container_name docker.io/debian:bullseye-slim amd64
test_eval $?

echo -n "Testing get_container_names()... "
names=$(get_container_names)
test_eval $?

echo -n "Testing container_exists()... "
container_exists $container_name
test_eval $?

echo -n "Attempting to start container... "
container_start $container_name
test_eval $?

echo -n "Testing container_is_running()... "
container_is_running $container_name
test_eval $?

echo "Executing a command in the container... "
container_exec $container_name echo "Echo is run from inside the container."
test_eval $?

echo -n "Attempting to stop container... "
container_stop $container_name
test_eval $?

echo "Testing container removal... "
container_remove $container_name
test_eval $?

# Finished testing
testing_ends $0 $script_under_test
