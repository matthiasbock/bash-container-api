# bash-container-library

A library of shell functions
for container creation and manipulation
as well as image creation, manipulation and registry upload.
This library's primary intention
is to allow for the creation of container recipes
in the form of *bash* scripts.

## Usage

The library is intended for use in *bash* scripts.
As such it can included by sourcing *include.sh*.

~~~
#!/bin/bash
#
# My container recipe
#

# Source the container library
. bash-container-library/include.sh

# Create and set-up a container
...
~~~

After inclusion the library's functions and variables
are ready for use by the calling script.

## Variables and configuration

The behaviour of some library functions can be adjusted
by setting certain (environment) variables
before source *include.sh*.

* *CONTAINER_CLI*: Explicitly set the program to use for container manipulation (default: *podman*)
* *CONTAINER_CLI_CREATE_ARGS*: Additional arguments to pass when calling *$container_cli create*
* *CONTAINER_CLI_RUN_ARGS*: Additional arguments to pass when calling *$container_cli run*
* *BASH_CONTAINER_LIBRARY*: Explicitly set the path to this library (default: the absolute path to *include.sh*)

The library itself also sets a couple of variables,
which may be used by the caller:

* *container_cli*: The program that is being used for container manipulation
* *bash_container_library*: The absolute path to this library
* *assets_dir*: Absolute path to this library's assets folder
* *keys_dir*: Absolute path to this library's keys folder

See [CONTRIBUTING.md](./CONTRIBUTING.md) for specifics about the style
used for all code including the variables.

## Backends

The backend is the command called for container manipulation.
**docker** and **podman** are supported as backends.
The backend can be selected by setting CONTAINER_CLI (see above).
Unless explicitly set otherwise, podman is being used,
which allows for container manipulation
by unprivileged users or in unprivileged environments,
as well as within other containers,
such as CI/CD runners.

## Messages and errors

Functions that return content to the caller do so via stdout.
Such functions send all other messages
(warnings, info or debug messages)
to stderr.
To prevent functions from printing to stdout or stderr,
pipe their output to */dev/null*:

~~~
# Do not print messages from stdout:
get_container_names 1>/dev/null

# Instead of printing, store container names in a variable:
names=$(get_container_names)

# Do not print any (informational) messages:
container_create my_new_container 2>/dev/null

# Do not print anything:
container_create my_new_container &>/dev/null
~~~

Upon errors, functions will not exit script execution
(i.e. will not call *exit*),
but instead return error codes to the caller.
All functions return zero upon success
and, respectively, a value greater zero upon error.
Functions may or may not print details about the nature of the error to stderr.
Error handling i.e. evaluation of a function's return code
is left to the caller.
All possible error codes are defined in *error.sh*.

~~~
container_create my_new_container
retval=$?
if [ $retval != 0 ]; then
  echo "Container creation failed with error code $retval."
  exit $retval
fi
~~~

In case
container manipulating functions
encouter an error
and
a function named *container_error_handler* is defined,
this function is called with details about the nature of the error.

## Examples

### List the names of all containers

~~~
#!/bin/bash

# Choose podman as container interface (optional)
CONTAINER_CLI=podman

# Add an argument to every invokation of 'podman run' (optional)
CONTAINER_CLI_RUN_ARGS="--cgroup-manager=cgroupfs"

# Source the container library
. bash-container-library/include.sh

# Get the names of all present containers
container_names=$(get_container_names)

# Print them
echo $container_names
~~~

### Use docker to create a priviledged container

~~~
#!/bin/bash

# Select docker as container interface
CONTAINER_CLI=docker

# Explicitly grant superuper permissions to the new container
CONTAINER_CLI_RUN_ARGS="--privileged"
CONTAINER_CLI_CREATE_ARGS="--privileged"

# Source the container library
. bash-container-library/include.sh

# Create privileged container
container_create my_privileged_container
...
~~~
