#
# This functions in this file manage container images.
#


function update_images()
{
	export images=$($container_cli image ls -a --format "{{.Repository}}:{{.Tag}}")
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

function image_create_from_folder()
{
  local path="$1"
  #local uri="$2"
  local tag="$2"

  # Import folder as new image
  COMMIT_ID=$(cd "$path" && sudo tar -cf - . | podman import - "$tag")

  # Add a tag to the new image
  #$container_cli tag "$COMMIT_ID" "$tag"
}
