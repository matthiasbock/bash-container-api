
#
# This function flattens the given container's history,
# i.e. makes it look as if it was created from scratch.
# This is accomplished by exporting the container's content
# and re-importing it as a new container replacing the original one.
#
function container_flatten()
{
  local container_name="$1"

  if !container_exists $container_name; then
    echo "Error: Failed to flatten container $container_name: Container not found."
    return 1
  fi

  if container_is_running $container_name; then
    container_stop $container_name
  fi

  # TODO: Export container as archive
  # TODO: Delete container
  # TODO: Re-import container (without history) from archive
}
