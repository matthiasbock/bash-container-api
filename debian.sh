#
# This file contains various Debian-specific functions,
# primarily to manage the installed packages in a container.
#

function container_debian_install_packages()
{
	local pkgs=$*
	local pkgs=$(echo -n $pkgs | sed -e "s/  / /g")
	local count=$(echo -n $pkgs | wc -w)
	if [ $count == 0 ]; then
		return 0
	fi
	echo "Installing $count packages ..."
	$container_cli exec -it -u root $container_name apt-get install -y $pkgs
	if [ $? != 0 ]; then
		echo "That failed. Trying with aptitude instead of apt ..."
		$container_cli exec -it -u root $container_name aptitude install $pkgs
	fi

#if [ "$pkgs" != "" ]; then
#      for pkg in $pkgs; do
#              $container_cli exec -it $container_name apt-get install -y $pkg
#      done
#fi
}


function container_debian_install_package_bundles()
{
	local package_bundles=$*
	local pkgs=""
	for bundle in $package_bundles; do
	       echo "Adding package bundle: \"$bundle\""
	       local pkgs="$pkgs $(cat $common/package-bundles/$bundle.list)"
	done
	container_debian_install_packages $pkgs
}


function container_debian_install_package_list_from_file()
{
	local pkgs=$(echo -n $(cat $1))
	container_debian_install_packages $pkgs
}


function container_debian_install_package_from_url()
{
  local container_name="$1"
  local url="$2"
  local filename="$(basename $url)"
  local retval=0
  local pkg_archive="/var/cache/apt/archives/"

  # Download file
  echo "Installing package $filename from $url ..."
  wget --progress=dot "$url" -O "$filename" \
   || { echo "File download failed. Package installation failed."; retval=1; }

  # Insert file into container
  if [ $retval == 0 ]; then
    container_add_file "$container_name" root "$filename" "$pkg_archive" \
     || { echo "Failed to add downloaded file to container."; retval=1; }
  fi
  rm -f "$filename"

  # Invoke dpkg to install it
  if [ $retval == 0 ]; then
    $container_cli exec -it -u root -w "$pkg_archive" "$container_name" dpkg -i --force-depends "$filename" \
     || { echo "dpkg returned an error."; retval=1; }
     $container_cli exec -t -u root -w "$pkg_archive" "$container_name" rm -f "$filename"
  fi

  # Inform about the success of the procedure
  if [ $retval == 0 ]; then
    echo "Package installation was successful."
  else
    echo "Package installation failed."
  fi
  return $retval
}


function blacklist_packages()
{
	config="/etc/apt/preferences"
	for pkg in $*; do
		stanza="Package: $pkg\nPin: release *\nPin-Priority: -1\n\n"
		# TODO
	done
}


function purge_force_depends()
{
	$container_cli exec -it -u root -w /root "$container_name" dpkg --force-depends purge $*
}


function remove_packages()
{
	local pkgs=$*
	echo "Removing $(echo $pkgs | wc -w) packages ..."
	$container_cli exec -it -u root -w /root "$container_name" apt-get purge -y --allow-remove-essential $pkgs
	$container_cli exec -it -u root -w /root "$container_name" apt-get autoremove -y --allow-remove-essential
	echo "Package removal complete."
}
