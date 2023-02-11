
#
# This file contains elementary containers control functions.
#
control_sh="$(realpath "${BASH_SOURCE[0]}")"
cwd="$(dirname "$control_sh")"

# Source dependencies
if [ "$constants_sh" == "" ]; then
 . "$cwd/constants.sh"
fi
if [ "$local_sh" == "" ]; then
 . "$cwd/utils/local.sh"
fi
if [ "$cli_sh" == "" ]; then
 . "$cwd/cli.sh"
fi
unset cwd

#
# Return a (space-separated) list of all containers
# present on the machine or in the userspace, respectively
#
function get_container_names() {

  # Make sure, a valid container CLI is defined
  verify_container_cli || return $?

  # Call container CLI to get a list of all containers
	local names="$($container_cli container ls -a --format "{{.Names}}")"
  local retval=$?
  if [ $retval != 0 ]; then
    echo "Error: Failed to list container names." >&2
    return $retval
  fi

  # Return list of container via stdout
  echo $names
}


#
# Determines whether a container with the given name or ID exists
#
# Example:
#   if container_exists my_fabulous_container; then
#     echo "My container is still there."
#   else
#     echo "Where did my container go?"
#   fi
#
# @return 0   Container exists
# @return 1  Container does not exist
#
function container_exists() {

  local container_name="$1"

  # List all containers
	local container_names=$(get_container_names || return $?)

  # Is the given container among the containers listed?
	[[ "$container_names" =~ "$container_name" ]]
  return $?
}


#
# Create a container with the given name and ISA,
# derived from the given base image.
# Optionally, specify which function to call as constructor.
#
function container_create() {

	local container_name="$1"
  local base_image="$2"
  local container_architecture="$3"
	local constructor="$4"

  # Check function arguments
  if [ "$container_name" == "" ]; then
    echo "Error: Container name not specified." >&2
    return $ERROR_MISSING_ARGUMENT
  fi
  if [ "$base_image" == "" ]; then
    echo "Error: Base image not specified." >&2
    return $ERROR_MISSING_ARGUMENT
  fi
  if [ "$container_architecture" == "" ]; then
    echo "Error: Container architecture not specified." >&2
    return $ERROR_MISSING_ARGUMENT
  fi

  # Make sure, a container with the same name does not exists already
	if container_exists $container_name; then
    echo "Error: A container named "$container_name" already exists." >&2
    return $ERROR_CONTAINER_EXISTS
  fi

  # Create container or call external constructor
  echo "Creating container '$container_name'... " >&2
  if [ "$constructor" != "" ]; then
    echo "Calling custom container constructor: $constructor" >&2
    $constructor $container_name $base_image $container_architecture $constructor
    local retval=$?
  	if [ $retval != 0 ]; then
  		echo "Warning: Custom container constructor exited with non-zero return code $retval." >&2
  	fi
  else
    verify_container_cli || return $?

    # TODO: Do not copy all of the current user's environment variables
    # acceptable: PATH=
    # TODO: explicitly set bash as initial command, and with --login, such that /etc/profile is sourced

    # Note: It is necessary to specify -it, otherwise the container will not remain up after creation.
    $container_cli create \
      -it \
      $CONTAINER_CLI_CREATE_ARGS \
  		--name $container_name \
      --arch $container_architecture \
  		"$base_image" 1>&2
    local retval=$?
    if [ $retval != 0 ]; then
  		echo "Warning: Container create command exited with non-zero return code $retval." >&2
  	fi
  fi

  # Verify container creation
  for timeout in $container_cli_timeout; do
    container_exists "$container_name" && break
    sleep 1
  done
	if ! container_exists $container_name; then
		echo "Error: Container creation failed." >&2
		return $ERROR_COMMAND_FAILED
	fi
	echo "Container created successfully." >&2
}


#
# Start the container with the given name or ID
#
function container_start() {

	local container_name="$1"

  # Make sure, the given container exists
  container_exists "$container_name" || return $?

  # No need to start it, if it's already running
  container_is_running "$container_name" && return $SUCCESS

  # Attempt to start container
	$container_cli container start "$container_name" >&2
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  # Verify container start
  for timeout in $container_cli_timeout; do
    container_is_running "$container_name" && break
    sleep 1
  done
  if ! container_is_running "$container_name"; then
    echo "Error: Failed to start container." >&2
    return $ERROR_CONTAINER_NOT_RUNNING
  fi
}


#
# Stop the container with the given name or ID
#
# @return 0  Container stopped successfully
# @return ERROR_CONTAINER_NOT_FOUND if there's no such container
# @return ERROR_COMMAND_FAILED if the container didn't stop
#
function container_stop() {

  local container_name="$1"

  # Make sure, the given container exists
  container_exists "$container_name" || return $?

  # No need to stop it, if it's not running
  container_is_running "$container_name" || return $SUCCESS

  # Call container CLI to stop container
  $container_cli container stop "$container_name" >&2
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  # Verify command success
  for timeout in $container_cli_timeout; do
    container_is_running "$container_name" || break
    sleep 1
  done
  if container_is_running "$container_name"; then
    echo "Error: Failed to stop container." >&2
    return $ERROR_CONTAINER_RUNNING
  fi
}


#
# Determine whether the container
# with the given name or ID is up and running
#
# @return 0  Container is running
# @return 1  Container is stopped
#
function container_is_running() {

  local container_name="$1"

  # Make sure, the given container exists
  container_exists "$container_name" || return $?

  # Retrieve the container's manifest
  local manifest=$($container_cli container inspect "$container_name" 2>&1 || return $ERROR_COMMAND_FAILED)

  # Evaluate manifest JSON using JQ
  local state=$(jq ".[0].State.Running" - <<< $manifest || return $ERROR_COMMAND_FAILED)
  [[ "$state" == "true" ]] && return 0 # true
  [[ "$state" == "true" ]] && return 1 # false
  return $ERROR_COMMAND_FAILED
}


#
# Execute the given command inside
# the container with the given name or ID
#
# @return   The commands exit code, if the container exists.
# @return ERROR_CONTAINER_NOT_FOUND otherwise
#
function container_exec() {

  local container_name="$1"
  local command="${@:2}"

  # Make sure, the given container exists
  container_exists "$container_name" || return $?

  # Skip empty commands
  [[ "$command" != "" ]] || return $ERROR_MISSING_ARGUMENT

  # Execute command inside container
  $container_cli exec -it -u root $container_name $command
  return $?
}


#
# Delete the container with the given name or ID
#
function container_remove() {

	local container_name="$1"

  # Make sure, container CLI is configured
  verify_container_cli || return $?

  # Check argument
  [[ "$container_name" != "" ]] || return $ERROR_MISSING_ARGUMENT

  # Only try to remove existing containers
  container_exists "$container_name" || return $SUCCESS

  # Stop container before removal
  if container_is_running "$container_name"; then
    $container_cli container stop $container_name || return $?
  fi
  if container_is_running "$container_name"; then
    echo "Error: Failed to stop container \"$container_name\", which is necessary before removal." >&2
    return $ERROR_CONTAINER_RUNNING
  fi

  # Call container CLI to remove container
  echo -n "Removing container \"$container_name\"... " >&2
	$container_cli container rm $container_name 1>&2

  # Verify removal success
  for timeout in $container_cli_timeout; do
    container_exists "$container_name" || break
    sleep 1
  done
  if container_exists "$container_name"; then
		echo "Error: Container removal failed." >&2
    return $ERROR_COMMAND_FAILED
	fi
	echo "Container removed successfully." >&2
}
