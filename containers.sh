#
# This file contains functions for creation and control of containers.
#


function update_containers()
{
	export containers=$($container_cli container ls -a --format "{{.Names}}" | awk '{ print $1 }')
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
	local container="$1"
	if [ "$(echo "$containers" | fgrep "$container")" == "" ]; then
		return 1;
	fi
	return 0;
}


function create_container()
{
	local container="$1"
	# Containers may be constructed differently. Using the referenced constructor.
	local constructor="$2"
	echo -n "Creating container '$container' ... "
	if ! container_exists "$container"; then
		$constructor
		local retval=$?
		if [ $retval == 0 ]; then
			sleep 1
		else
			echo "Container constructor exited with a non-zero return value $retval."
		fi
		if ! container_exists "$container"; then
			echo "Error: Failed to create container '$container'."
			return 1
		fi
		echo "done."
	else
		echo "already exists. Skipping."
	fi
	return 0
}


function container_start()
{
	local container="$1"
	echo -n "Starting container '$container' ... "
	if [ "$container" == "" ]; then
		echo "Error: Container name/ID is empty. Aborting."
		return 1
	fi
	if ! container_exists "$container"; then
		echo "Container '$container' not found. Aborting"
		return 1
	fi
	$container_cli container start "$container"
	sleep 1
	echo "Done."
}


function container_stop()
{
  local container_name="$1"
  # TODO: Only stop if running
  $container_cli container stop "$container_name"
  # TODO: Report success/failure
}


function container_commit()
{
	local container_name="$1"
  local image_name="$2"
  local tag="$3"
  # TODO: ugly; better use bash arrays
  local config="$4 $5 $6 $7 $8 $9 ${10}"

	echo -n "Committing container '$container_name' as image 'localhost/$image_name:$tag' ... "
	if ! container_exists "$container_name"; then
		echo "not found. Skipping."
		return 1;
	fi
  echo ""

	if image_exists "localhost/$container_name"; then
		$container_cli image rm "localhost/$container_name"
	fi

  local config_args=""
  for arg in $config; do
    config_args="$config_args -c $arg"
  done
	export COMMIT_ID=$($container_cli commit --pause $config_args "$container_name")
	echo "Commit id: $COMMIT_ID"

  echo "Tagging as 'localhost/$image_name:$tag' ..."
	$container_cli tag "$COMMIT_ID" "$image_name:$tag"

  echo "Done."
}


function container_remove()
{
	local container="$1"
	if [ "$1" == "" ]; then return 0; fi
	echo -n "Removing container '$container' ... "
	if ! container_exists $container; then
		echo "not found. Skipping."
		return 1;
	fi

  # TODO: Only if container is rnunning:
	$container_cli container stop $container

	$container_cli container rm $container
  # TODO: Verify container removal

	echo "done."
}
