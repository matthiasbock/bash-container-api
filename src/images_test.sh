#!/bin/bash

script_under_test=src/images.sh

# Import test framework
set -e
. src/testing.sh
testing_begins $0 $script_under_test

# Import the functions under test
. $script_under_test
set +e

container_cli=podman
image_name="docker.io/library/debian:bullseye-slim"
podman image rm "$image_name" &>/dev/null

# TODO: test get_image_names

# TODO: test image_is_available

# TODO: test image_pull

# TODO: test image_create_from_folder

# TODO: test image_create_from_container

# Finished testing
testing_ends $0 $script_under_test
