
#
# Functions to manage container images
#


#
# Return a list of local images
#
function get_image_names() {

  # Make sure, container CLI is configured
  verify_container_cli || return $?

  # Call container CLI to list all images
	local images=$($container_cli image ls -a --format "{{.Repository}}:{{.Tag}}" | sed -E "s/<none>:<none>//g" -E "s/\w+/ /g")
  local retval=$?
  [[ $retval == 0 ]] || return $ERROR_COMMAND_FAILED

  echo $images
}


#
# Determine whether an image with the given name or ID is locally available
#
function image_is_available() {

	local image_name="$1"

  # Check argument
  [[ "$image_name" != "" ]] || return $ERROR_MISSING_ARGUMENT

  # List all local images
	local image_names=$(get_image_names || return $?)

  #
  # Use regular expression to determine
  # whether the given image is among the listed images
  #
  [[ "$image_names" =~ "$image_name" ]]
  return $?
}


#
# Download or udpate a local container image
#
function image_pull() {

  local image_uri="$1"

  # TODO

  $container_cli image pull $image_uri >&2
  return $?
}


#
# Push a local container image to its repository
#
function image_push() {

  local image_id="$1"
  local repository="$2"

  # TODO

  $container_cli image push $image_id $repository >&2
  return $?
}


#
# Pack all files and folder below the given path
# into an image with the given name and tag
#
function image_create_from_folder() {

  local image_name="$1"
  local path="$2"

  # Make sure, the container CLI is configured
  verify_container_cli || return $?

  # Do not overwrite existing images
  if image_is_available "$image_name"; then
    echo "Error: An image named \"$image_name\" already exists." >&2
    return $ERROR_IMAGE_AVAILABLE
  fi

  # TODO: No tag after the semicolon defaults to tag "latest"

  # Make sure, the specified path exists
  if [ "$path" == "" ] || [ ! -d "$path" ]; then
    echo "Error: Folder not found: \"$path\"." >&2
    return $ERROR_ILLEGAL_ARGUMENT
  fi

  # Import folder as new image
  local commit_id=$(cd "$path" && tar -cf - . | $container_cli import - "$image_name")
  local retval=$?
  [[ $retval == 0 ]] || return $retval

  # Verify image creation
  image_is_available "$image_name"
  return $?
}


#
# Commit a given (existing) container as a pushable Docker image
#
# CAVEAT: Configuration strings with spaces are NOT supported and will break the config.
#
function image_create_from_container() {

	local container_name="$1"
  local image_id="$2"
  local config="${@:3}"

  # Passing config items as arguments to -c command line switch
  local commit_args=""
  if [ "$config" != "" ]; then
    for arg in $config; do
      commit_args="$commit_args -c $arg"
    done
  fi

	if ! container_exists "$container_name"; then
		echo "Error: Commit failed: Container \"$container_name\" not found." >&2
		return $ERROR_CONTAINER_NOT_FOUND;
	fi

  # Overwrite existing images without asking
	if image_is_available "localhost/$container_name"; then
		$container_cli image rm "localhost/$container_name" \
    || return $ERROR_IMAGE_AVAILABLE
	fi

  # Commit
  echo "Committing container \"$container_name\"... " >&2
	local commit_id=$($container_cli commit --pause $commit_args "$container_name" || return $ERROR_COMMAND_FAILED)
	echo "Image commited with ID: $commit_id"

  # Tag
  echo "Tagging commit as \"$image_id\"..." >&2
	$container_cli tag "$commit_id" "$image_id" || return $ERROR_COMMAND_FAILED
  echo "Image tagged." >&2
}


#
# Unpack the given image into the given folder
#
function image_unpack() {

  local image_id="$1"
  local workdir="$2"

  # Pull the image if it's not available locally
  if ! image_is_available $image_id; then
    image_pull $image_id || return $?
  fi

  # TODO

  # CAVEAT: non-root users can only do this in an unshare environment
  $container_cli save --format=oci-dir -o $workdir $image_id
}


#
# Merge the filesystems of two or more images into one
#
function images_merge() {

  local target_image="$1"
  local source_images="${@:2}"

  # TODO: checks

  # Save all source images as tarballs
  local tar_files=""
  for image_id in $source_images; do
    # Pull the image if it's not available locally
    if ! image_is_available $image_id; then
      image_pull $image_id || return $?
    fi

    # Save image to folder
    local filename="$(basename $image_id)"
    local folder="$workdir/$filename"
    $container_cli save --format=oci-dir -o $folder $image_id

    # Find the tar file with filesystem
    # TODO: $folder ...
    tar_files="$tar_files $tar_file"
  done

  # Concatenate all tarballs
  # TODO

  # Create new image from tarball
  # TODO

  # Tag new image
  # TODO
}
