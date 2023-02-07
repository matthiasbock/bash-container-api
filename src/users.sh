

#
# Within the specified container create a user with the specified name
#
# Usage: container_create_user my_container username [optional: group1 group2 ...]
#
# @return 0  upon success
# @return 1  upon errors
#
function container_create_user()
{
  local container_name="$1"
  local username="$2"
  local groups="${@:3}"

  # TODO: Implement setting a custom UID:GID

  shell="/bin/bash"
  home="/home/$username"

  # Check if the user already exists
  uid=$(container_exec $container_name id $username | fgrep uid)
  if [ "$uid" != "" ]; then
    echo "Creating user $username: Already exists. Skipping."
  else
    echo -n "Creating user $username with home at $home ... "

    # In case a group named $username already exists, add the new user to it.
    add_to_group=""
    gid=$(container_exec $container_name getent group $group)
    if [ "$gid" != "" ]; then
      add_group="-g $group"
    fi

    # Create a user and a group named $username
    container_exec $container_name mkdir -p $home || return 1
    container_exec $container_name useradd -d $home -s $shell $add_to_group $username || return 1
    container_exec $container_name chown -R $username.$username $home || return 1
    echo "ok."
  fi

  # Adding user to groups
  if [ "$groups" != "" ]; then
    # Make sure the requested groups exist
    container_create_groups $container_name $groups

    # Add user to one group after another
    for group in $groups; do
      echo -n "Adding $username to group $group ... "
      container_exec $container_name usermod -aG $group $username
      echo "ok."
    done
    echo "Done."
  fi

  return 0
}


#
# Within the specified container create the specified groups
#
# Usage: container_create_groups my_container group1 group2 ...
#
# @return 0  upon success
# @return 1  upon errors
#
function container_create_groups()
{
  local container_name="$1"
  local groups="${@:2}"

  # For each group argument:
  for group in $groups; do
    # Check if group exists...
    gid=$(container_exec $container_name getent group $group)
    if [ "$gid" != "" ]; then
      echo "Group exists: $group"
    else
      # ...otherwise create it:
      echo -n "Creating group $group ... "
      container_exec $container_name groupadd -f $group || return 1
      echo "ok."
    fi
  done
  return 0
}
