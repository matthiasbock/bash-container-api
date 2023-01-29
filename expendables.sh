
#
# Functions for dealing with superfluous files inside containers
#

#
# This function reads a list of expendable files and folders from a given file.
#
function container_expendables_import()
{
  local expendables_list="$1"

  export container_expendables=$(cat "$expendables_list" | sed -ze "s/\n/ /g")
}


#
# This function removes the given files and folders from the container.
#
function container_expendables_delete()
{
  local container_name="$1"
  local container_expendables="${@:2}"

  echo "Deleting expendable files from container..."
  if [ "$container_expendables" == "" ]; then
    echo "Warning: No expendable files and folders specified. Skipping."
    return 0
  fi

  # TODO: Check, if container is running
  #container_start $container_name
  #container_stop $container_name

  container_exec $container_name find $container_expendables -type f -exec rm -fv {} \; 2>/dev/null || true
  echo "Done."
}
