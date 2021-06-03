#
# This file contains functions for creation and control of containers.
#


function update_containers()
{
	export containers=$($container_cli container ls -a --format "{{.Names}}" | awk '{ print $1 }')
}


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


# TODO container_stop


function container_commit()
{
	local container_name="$1"
	echo -n "Committing container '$container_name' ... "
	if ! container_exists "$container_name"; then
		echo "not found. Skipping."
		return 1;
	fi
	if image_exists "localhost/$container_name"; then
		$container_cli image rm "localhost/$container_name"
	fi
	local tag=$($container_cli commit "$container_name")
	echo "Commit id: $tag"
	$container_cli tag "$tag" "$container_name"
	echo "Tagged as '$container_name'. Done."
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
	$container_cli container stop $container &> /dev/null
	$container_cli container rm $container &> /dev/null
	echo "done."
}
