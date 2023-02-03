
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
# Check whether a container with the given name exists
#
# Usage:
#   if container_exists "fabulous_container"; then echo "My container exists."; else echo "Where is my container?"; fi
#
function container_exists()
{
  local container_name="$1"
	local container_names=$(get_container_names || return $?)
	[[ "$container_names" =~ "$container_name" ]]
  return $?
}


#
# Create a container with the given name and,
# optionally, specify which function to call as constructor
#
function container_create()
{
	local container_name="$1"
  local base_image="$2"
  local container_architecture="$3"
	local constructor="$4"

  # Check function arguments
  if [ "$container_name" == "" ]; then
    echo "Error: Container name not specified." >&2
    return 4
  fi
  if [ "$base_image" == "" ]; then
    echo "Error: Base image not specified." >&2
    return 5
  fi
  if [ "$container_architecture" == "" ]; then
    echo "Error: Container architecture not specified." >&2
    return 6
  fi

  # Make sure, a container with the same name does not exists already
  echo "Creating container '$container_name'... " >&2
	if container_exists $container_name; then
    echo "Error: A container with this name already exists." >&2
    return 1
  fi

  # Create container or call external constructor
  if [ "$constructor" != "" ]; then
    echo "Calling custom container constructor: $constructor" >&2
    $constructor $container_name $base_image $container_architecture $constructor
    local retval=$?
  	if [ $retval != 0 ]; then
  		echo "Warning: Custom container constructor exited with non-zero return code $retval." >&2
  	fi
  else
    # Note: It is necessary to specify -it, otherwise the container will not remain up after creation.
    $container_cli create \
      -it \
      $container_networking \
      $CONTAINER_CLI_CREATE_ARGS \
  		--name $container_name \
      --arch $container_architecture \
  		"$base_image" 1>&2
    local retval=$?
    if [ $retval != 0 ]; then
  		echo "Warning: Container create command exited with non-zero return code $retval." >&2
  	fi
  fi

  # Wait for the container to become ready
  sleep 1

  # Verify container creation
	if ! container_exists $container_name; then
		echo "Error: Container creation failed." >&2
		return 1
	fi
	echo "Container created successfully." >&2
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
