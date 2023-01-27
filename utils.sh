#
# This file contains misc functions for the manipulation of existing containers.
#

function container_set_hostname()
{
	local container_name="$1"
	local hostname="$2"
	container_exec "$container_name" /bin/bash -c "echo \"$hostname\" > /etc/hostname"
  return $?
}


function container_test()
{
  local container_name="$1"
  local expr1="$2"
  local expr2="$3"

  container_exec "$container_name" /usr/bin/test $expr1 $expr2
  return $?
}


#
# Adds a file to the container and changes ownership to the specified user/group
#
function container_add_file()
{
  local container_name="$1"
  local srcfile="$(realpath "$2")"
  local dst="$3"

  if [ ! -e "$srcfile" ]; then
	echo "Error: File not found: $srcfile"
	return 1
  fi

  # Evaluate the destination argument
  local fname="$(basename $srcfile)"
  local fullpath
  if [ "$dst" == "" ]; then
    # Use the same path inside the container as the file has locally
    fullpath=$(realpath "$srcfile")
    echo "Warning: No destination argument was given. Assuming ${fullpath}."
  elif [ "${dst: 1}" == "." ]; then
    echo "Error: The file's destination within the container cannot be specified as a relative path."
    return 1
  elif [ "${dst: -1}" == "/" ]; then
    # Is a folder: append filename
    fullpath="${dst}${fname}"
  else
    if container_test "$container_name" -d "$dst"; then
      # A folder with that name exists inside the container
      fullpath="$dst/$fname"
    else
      # Assume it's a filename
      fullpath="$dst"
    fi
  fi
  dstpath=$(dirname "$fullpath")

  # Check if destination path already exists
  if container_test "$container_name" -f "$fullpath"; then
    echo -n "Warning: A file named $fullpath already exists within the container. Removing...";
    container_rm_file "$container_name" "$fullpath" \
     || { echo "failed."; echo "Error: Failed to remove existing destination file. Aborting."; return 1; }
    if container_test "$container_name" -e "$fullpath"; then
      echo "failed."
      echo "Echo: rm returned without error, nonetheless the file still exists. Aborting."
      return 1
    fi
    echo "success."
  fi

  # Create destination folder if non-existent
  if ! container_test "$container_name" -d "$dstpath"; then
    echo "Warning: The destination path $dstpath does not exist. Creating..."
    $container_cli exec -t -u root "$container_name" mkdir -p "$dstpath" \
     || { echo "Error: Failed to create destination folder. Aborting."; return 1; }
    if ! container_test "$container_name" -d "$dstpath"; then
      echo "failed."
      echo "Echo: mkdir returned without error, nonetheless the folder is still missing. Aborting."
      return 1
    fi
    echo "success."
  fi

  # Copy the file into the container
  $container_cli cp "$srcfile" "${container_name}:${fullpath}" \
   || { echo "Error: Failed to copy file to container."; return 1; }

  return 0
}


function container_rm_file()
{
  local container_name="$1"
  local filename="$2"
  # TODO: If file exists...
  container_exec "$container_name" rm -f "$filename"
  return $?
}
