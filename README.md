# bash-container-library

A shell toolkit for container creation and manipulation
as well as image creation and registry upload.
The repository is intended for inclusion
in container recipes written as bash scripts.

## Usage

The library is included by
sourcing *include.sh*.

Example:

~~~
#!/bin/bash

# Choose podman as container interface (optional)
CONTAINER_CLI=podman

# Add an argument to every invokation of 'podman run' (optional)
CONTAINER_CLI_RUN_ARGS="--cgroup-manager=cgroupfs"

# Source the container library
. lib/bash-container-library/include.sh

# Print the names of all present containers
container_names=$(get_container_names)
echo $container_names
~~~

## Backends

As backend,
i.e. command used for container manipulation,
docker and podman are supported.
The backend can be set via the *CONTAINER_CLI* environment variable.
Unless explicitly set otherwise, podman is being used,
which allows for container manipulation
by unprivileged users
as well as
in unprivileged environments and containers.

## Reference

Some functions return content and do so via stdout.
If such functions print other messages,
such as for progress monitoring or debugging,
then these messages are printed to stderr.
Functions can be silenced,
e.g. by piping their output to */dev/null*.
Functions will not exit script execution (i.e. call *exit*),
but return error codes.
Upon success, zero is returned and
a greater value upon errors,
respectively.
Error handling is left to the function callers.
