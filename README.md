# bash-container-library

A toolkit with functions for container creation and manipulation
as well as image creation and upload to container registries,
implemented as bash scripts.

## Usage

In order to make use
of the functions in this library,
you need to include the main script,
which in turn will include all source files:

~~~
#!/bin/bash

. lib/bash-container-library/include.sh

container_names=$(container_ls)
echo $container_names
~~~

## Backends

The default backend is podman.
This allows for container creation within unpriviledged containers.
The backend can be changed by setting the *$container_cli* variable.

## Reference

Most functions return 0 upon success and a greater value upon errors.
Some functions return the respective requested content via stdout.
In general, functions shall not exit script execution
but return error codes
and leave proper handling to their respective caller.
