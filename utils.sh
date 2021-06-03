#
# This file contains functions for the manipulation of existing containers.
#

function container_set_hostname()
{
	local container="$1"
	local hostname="$2"
	$container_cli exec -t -u root -w /etc "$container" /bin/bash -c "echo \"$hostname\" > hostname"
}


function container_create_user(parameter)
{
  $container_cli exec -t -u root "$container_name" /bin/bash -c "mkdir -p /home/$user && useradd -d /home/$user -s /bin/bash $user"
}


#
# Adds a file to the container and changes ownership to the specified user
#
function container_add_file()
{
  # TODO: Evaluate argument: File or folder?
#  $path
#  if [ $path last character is "/" ]
#    local fullpath="${path}$(basename $filename)"
#  else
#    if folder exists in container
#  fi

  local container_name="$1"
  local
  $container_cli cp "$filename" "$container_name:$fullpath"
  $container_cli exec -t "$container_name" bash -c "chown -R $user.$user $fullpath"
}


function container_minimize()
{
	local container="$1"
	$container_cli exec -t -u root -w /root "$container" bash -c "find /tmp/ /var/lock/ /var/log/ /var/mail/ /var/run/ /var/spool /var/tmp/ /usr/share/doc/ /usr/share/man/ -type f -exec rm -fv {} \; ; rm -fv /root/.bash_history /home/$user/.bash_history; apt-get autoremove -y --allow-remove-essential" || :
}
