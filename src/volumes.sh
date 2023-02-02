#
# This file contains functions for volume management.
#


function update_volumes()
{
	export volumes=$($container_cli volume ls --format "{{.Name}}" | sed -ze "s/\n/ /g")
}


function volume_exists()
{
	update_volumes
	local name="$1"
	if [ "$(echo "$volumes" | fgrep "$name")" == "" ]; then
		return 1;
	fi
	return 0;
}


function create_volume()
{
	local volume="$1"
	echo -n "Creating volume '$volume' ... "
	if ! volume_exists "$volume"; then
		$container_cli volume create "$volume" &> /dev/null
		echo "done."
	else
		echo "already exists. Skipping."
	fi
}
