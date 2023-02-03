
#
# This file contains elementary containers control functions.
#


#
# Return a (space-separated) list of all containers
# present on the machine or in the userspace, respectively
#
function get_container_names()
{
	local names="$($container_cli container ls -a --format "{{.Names}}")"
  local retval=$?
  if [ $retval != 0 ]; then
    echo "Error: Failed to list container names." >&2
    return $retval
  fi
  echo $names
}


#
# Check whether a container with the given name exists locally
#
# Usage:
#   if container_exists "fabulous_container"; then echo "My container exists."; else echo "Where is my container?"; fi
#
function container_exists()
{
	update_containers
	local container_name="$1"
	if [ "$(echo "$containers" | fgrep $container_name)" == "" ]; then
		return 1;
	fi
	return 0;
}


function container_constructor_default()
{
  [[ "$container_name" != "" ]] || { echo "Error: Container name not specified."; exit 2; }
  [[ "$container_architecture" != "" ]] || { echo "Error: Container architecture not specified."; exit 3; }
  [[ "$base_image" != "" ]] || { echo "Error: Base image not specified."; exit 4; }

  # Note: It is necessary to specify -it, otherwise the container will exit prematurely.
	$container_cli create \
    -it \
    $container_networking \
    $CONTAINER_CLI_CREATE_ARGS \
		--name $container_name \
    --arch $container_architecture \
		"$base_image"
}


function create_container()
{
	local container_name="$1"
	local constructor="$2"

	echo "Creating container '$container_name'... "
	if container_exists $container_name; then
    echo "A container named $container_name already exists. Aborting."
    return 1
  fi

  if [ "$constructor" == "" ]; then
    constructor=container_constructor_default
  fi
	$constructor
	local retval=$?
	if [ $retval == 0 ]; then
		sleep 1
	else
		echo "Container constructor exited with a non-zero return value $retval."
	fi

	if ! container_exists $container_name; then
		echo "Error: Failed to create container '$container_name'."
		return 1
	fi

	echo "Container created successfully."
	return 0
}


function container_start()
{
	local container_name="$1"
	echo -n "Starting container '$container_name' ... "
	if [ "$container_name" == "" ]; then
		echo "Error: Container name/ID is empty. Aborting."
		return 1
	fi
	if ! container_exists $container_name; then
		echo "Container '$container_name' not found. Aborting"
		return 1
	fi
	$container_cli container start "$container_name"
	sleep 1
	echo "Done."
}


function container_exec()
{
  local container_name_name="$1"
  # TODO: Use a nicer way to enumerate arguments
  #local args="$2 $3 $5 $5 $6 $7 $8 $9 ${10}"
  # TODO: Start/stop container if necessary
  $container_cli exec -it -u root $container_name "${@:2}"
  return $?
}


function container_stop()
{
  local container_name_name="$1"
  # TODO: Only stop if running
  $container_cli container stop $container_name
  # TODO: Report success/failure
  return $?
}


function container_remove()
{
	local container_name="$1"
	if [ "$1" == "" ]; then return 0; fi
	echo -n "Removing container '$container_name' ... "
	if ! container_exists $container_name; then
		echo "not found. Skipping."
		return 1;
	fi

  # TODO: Only if container is rnunning:
	$container_cli container stop $container_name

	$container_cli container rm $container_name
  # TODO: Verify container removal

	echo "done."
}
