#
# This functions in this file manage container images.
#


function update_images()
{
	export images=$($container_cli image ls -a --format "{{.Repository}}:{{.Tag}}" | sed -ze "s/\n/ /g")
}


function image_exists()
{
	update_images
	local name="$1"
	if [ "$(echo "$images" | fgrep "$name")" == "" ]; then
		return 1;
	fi
	return 0;
}

function create_image_from_folder()
{
  local path="$1"
  #local uri="$2"
  local tag="$2"

  # Import folder as new image
  COMMIT_ID=$(cd "$path" && sudo tar -cf - . | podman import - "$tag")

  # Add a tag to the new image
  #$container_cli tag "$COMMIT_ID" "$tag"
}


#
# Commit a given (existing) container as a pushable Docker image
#
function create_image_from_container()
{
	local container_name="$1"
  local image_name="$2"
  local tag="$3"
  # TODO: Test whether the following variable assignment works:
  local config="${@:4}"

	echo "Committing container '$container_name' as image 'localhost/$image_name:$tag'... "
	if ! container_exists "$container_name"; then
		echo "Error: Container $container_name not found. Commit failed."
		return 1;
	fi

  # Overwrite existing images without asking
	if image_exists "localhost/$container_name"; then
		$container_cli image rm "localhost/$container_name"
	fi

  # Apply
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
