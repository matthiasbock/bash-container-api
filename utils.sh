#
# This file contains misc functions for the manipulation of existing containers.
#

function container_set_hostname()
{
	local container="$1"
	local hostname="$2"
	$container_cli exec -t -u root -w /etc "$container" /bin/bash -c "echo \"$hostname\" > hostname"
}


function container_create_user()
{
  local container_name="$1"
  local user="$2"
  # TODO: If user does not exist already...
  $container_cli exec -t -u root "$container_name" /bin/bash -c "mkdir -p /home/$user && useradd -d /home/$user -s /bin/bash $user"
}


function container_test()
{
  local container_name="$1"
  local expr1="$2"
  local expr2="$3"

  $container_cli exec -t -u root "$container_name" /usr/bin/test $expr1 $expr2
  return $?
}


#
# Adds a file to the container and changes ownership to the specified user/group
#
function container_add_file()
{
  local container_name="$1"
  local owner="$2"
  local srcfile="$(realpath "$3")"
  local dst="$4"

  # Evaluate the destination argument
  local fname="$(basename $srcfile)"
  local fullpath
  if [ "$dst" == "" ]; then
    # Use the same path inside the container as the file has locally
    fullpath=$(realpath "$srcfile")
    echo "Warning: No destination argument was given. Assuming ${fullpath}."
  elif [ "${dst: 1}" == "." ]; then
    echo "Error: The destination in the container cannot be specified as a relative path."
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
  if container_test "$container_name" -e "$fullpath"; then
    echo "Warning: Destination file $fullpath exists. Removing...";
    container_rm_file "$container_name" "$fullpath" \
     || { echo "Failed to remove existing destination file."; return 1; }
  fi

  # Create destination folder if non-existent
  if ! container_test "$container_name" -d "$dstpath"; then
    echo "The destination path does not exist. Creating $dstpath ..."
    $container_cli exec -t -u root "$container_name" mkdir -p "$dstpath" \
     || { echo "Failed to create destination folder."; return 1; }
  fi

  # Copy the file into the container
  $container_cli cp "$srcfile" "${container_name}:${fullpath}" \
   || { echo "Error: Failed to copy file to container."; return 1; }

  # Change file ownership as requested
  $container_cli exec -t -u root "$container_name" /bin/bash -c "chown $owner \"$fullpath\"" \
   || { echo "Error: Failed to change file ownership."; return 1; }

  return 0
}


function container_rm_file()
{
  local container_name="$1"
  local filename="$2"
  $container_cli exec -t -u root "$container_name" rm -f "$filename"
  return $?
}


function container_minimize()
{
	local container="$1"
  # TODO: That's very crude. Maybe differentiate more...
	$container_cli exec -t -u root -w /root "$container" \
    bash -c "find /tmp/ /var/lock/ /var/log/ /var/mail/ /var/run/ /var/spool /var/tmp/ /usr/share/doc/ /usr/share/man/ -type f -exec rm -fv {} \; ; rm -fv /root/.bash_history /home/$user/.bash_history; apt-get autoremove -y --allow-remove-essential" || :
}
