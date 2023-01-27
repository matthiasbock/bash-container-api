#
# This file contains various Debian-specific functions,
# primarily to manage the installed packages in a container.
#
# Note:
# Requires functions from local.sh and web.sh.
#

function container_debian_install_packages()
{
	local pkgs=$*
	local pkgs=$(echo -n $pkgs | sed -e "s/  / /g")
	local count=$(echo -n $pkgs | wc -w)
	if [ $count == 0 ]; then
		return 0
	fi
  if [ "$apt_update_complete" == "" ]; then
    echo "Updating package lists..."
    container_exec $container_name apt-get -q update
    export apt_update_complete=1
  fi
	echo "Installing $count packages ..."
	$container_cli exec -it -u root $container_name apt-get -q install -y $pkgs
	if [ $? != 0 ]; then
		echo "Package installation with apt-get failed. Re-trying with aptitude ..."
		$container_cli exec -it -u root $container_name aptitude -q install $pkgs
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
    container_add_file "$container_name" "$filename" "$pkg_archive" \
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


#
# Retrieve a list of download URLs for a package
#
# Usage:
#  get_debian_package_download_urls lynx
#  get_debian_package_download_urls lynx buster
#  get_debian_package_download_urls lynx bullseye amd64
#
# @return 0 when at least one URL was found and the URLs on stdout
# @return 1 when no URL could be found
#
function get_debian_package_download_urls() {
  local default_release="stable"
  local default_arch="amd64"

  # One argument provided
  local package_name="$1"

  # Two arguments provided
  if [ "$2" != "" ]; then
    local debian_release="$1"
  else
    local debian_release="$default_release"
  fi

  # Three arguments provided
  if [ "$3" != "" ]; then
    local target_architecture="$2"
  else
    local target_architecture="$default_arch"
  fi

  # Fetch the package's page, which (hopefully) contains some download links
  local url="https://packages.debian.org/$debian_release/$target_architecture/$package_name/download"
  local page=$(get_page $url) || return 1;
  # The page cannot be empty
  [[ "$page" != "" ]] || return 1;

  # Apply regular expressions to extract download URLs
  urls=$(
          grep -E ".*<li>.*<a .*href=\"http.*$package.*\.deb\".*>.*<\/a>.*<\/li>.*" - <<< "$page" \
        | sed -e "s/.*\"\(http.*\)\".*/\1/g" \
        | cut -d\" -f2
        )
  # An empty list indicates a non-existent package
  [[ "$urls" != "" ]] || return 1;

  # Return results
  echo $urls
  return 0
}


#
# Download a Debian package into the host's package archive folder
#
# Usage:
#  container_debian_install_with_dpkg my_container bash
#  container_debian_install_with_dpkg my_container bash buster
#  container_debian_install_with_dpkg my_container bash bullseye amd64
#
# @return 0 and the full path to the downloaded package on stdout
# @return 1 upon errors
#
function debian_download_package() {
  local package_name="$1"
  local debian_release="$2"
  local target_architecture="$3"

  # Fetch URLs for package file download
  local urls=$(get_debian_package_download_urls $package_name $debian_release $target_architecture)
  [[ "$urls" != "" ]] || return 1

  # Work out the target filename
  local url=$(echo $urls | head -n1)
  local filename=$(basename url)
  if is_set path_apt_package_cache; then
    local cache=$path_apt_package_cache
  else
    local cache="/var/cache/apt/archives"
  fi
  local filepath="$cache/$filename"

  # Download file
  mkdir -p $cache || return 1
  [[ -d $cache ]] || return 1
  get_file $filepath $urls
  [[ $? == 0 ]] || return 1
  [[ -f $filepath ]] || return 1

  # Return full path to downloaded package
  echo $filepath
  return 0
}


#
# Download and install a package without invoking apt or apt-get
#
# Usage:
#  container_debian_download_package_and_install my_container bash
#  container_debian_download_package_and_install my_container bash buster
#  container_debian_download_package_and_install my_container bash bullseye amd64
#
function container_debian_download_package_and_install()
{
  local container_name="$1"
  local package_name="$2"
  local debian_release="$3"
  local target_architecture="$4"

  # Download the requested package
  filename=$(debian_download_package $package_name $debian_release $target_architecture)
  [[ $? == 0 ]] || return 1
  [[ "$filename" != "" ]] || return 1
  [[ -f "$filename" ]] || return 1

  # Copy the file to the container
  container_add_file $container_name $filename $filename
  container_test -f $filename || return 1

  # Install package inside container
  container_exec $container_name dpkg -i $filename
  return $?
}


function container_debian_install_build_dependencies()
{
  local container_name="$1"
  local package_name="$2"

  # TODO: Check if container is up; start/stop if necessary
  container_exec $container_name apt-get -q update || return 1
  container_exec $container_name apt-get -q build-dep -y $package_name || return 1
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
	#$container_cli exec -it -u root -w /root "$container_name" apt-get autoremove -y --allow-remove-essential
	echo "Package removal complete."
}
