#
# This file contains various Debian-specific functions,
# primarily to manage the installed packages in a container.
#
# Note:
# Requires functions from local.sh and web.sh.
#

#
# Call apt in a container to install Debian packages by name
#
function container_debian_install_packages() {
  local container_name="$1"
	local pkgs=$(echo -n "${@:2}" | sed -e "s/  / /g")

  # Make sure, container exists and is running
  # TODO: implement:
  # ensure_container_running $container_name || return $?

  # Silently return, when no package arguments were given
	if [ "$pkgs" == "" ]; then
		return 0
	fi

  #
  # Consider it a mistake, when we arrive here
  # before any package list was downloaded
  # and attempt a package list update once.
  #

  #
  # TODO: apt_update_complete = count the number of list files in /var/...?/apt/lists/...
  #

  if [ "$apt_update_complete" == "" ]; then
    echo "Updating package lists..."
    container_exec $container_name apt-get -q update
    apt_update_complete=1
  fi

  # Proceed with package installation
  local count=$(echo -n $pkgs | wc -w)
	echo "Installing $count packages ..."

  # Try apt-get
  container_exec $container_name apt-get -q install -y $pkgs
	[[ $? == 0 ]] && { echo "Installation successful."; return 0; }

  # Try apt
	echo "Warning: Installation with apt-get failed."
  echo "Re-trying with apt..."
	container_exec $container_name apt -q install -y $pkgs
  [[ $? == 0 ]] && { echo "Installation successful."; return 0; }

  # Try aptitude
  echo "Warning: Installation with apt failed."
  echo "Re-trying with aptitude..."
	container_exec $container_name aptitude -q install -y $pkgs
  [[ $? == 0 ]] && { echo "Installation successful."; return 0; }

  # Try one after another
  echo "Warning: Installation with aptitude failed."
  echo "Re-trying one package after another..."
  for pkg in $pkgs; do
    if [ "$pkg" == "" ]; then
      continue
    fi
    container_exec $container_name apt-get -q install -y $pkg \
    || { local retval=$?; echo "Error: Installation failed (exit code $retval)."; return $retval; }
  done
  echo "Installation successful."
}


#
# Load a list of Debian packages by name or filename
#
# Default path to look for bundle files is ./debian/package-bundles/
#
function container_debian_install_package_bundles() {
  local container_name="$1"
	local package_bundles="${@:2}"

  # Silently return, when no bundle arguments were given
  if [ "$package_bundles" == "" ]; then
    return 0
  fi

  # Compile a list of packages from the given bundles
  local pkgs=""
	for bundle in $package_bundles; do
    # Argument is a filename?
    if [ ! -f $bundle ]; then
      local filename="$assets_dir/debian/package-bundles/$bundle.list"
      # Argument is a bundle name?
      if [ -f $filename ]; then
        bundle="$filename"
      else
        echo "Error: Package bundle not found: \"$bundle\"" >&2
        return 1
      fi
    fi

	  echo -n "Loading package bundle: \"$bundle\": "
    add="$(cat "$bundle")" || {
      echo "Error: Failed to load package bundle from \"$bundle\"." >&2
      return 2
    }
    echo "$(echo $add | wc -w) package(s)."
	  local pkgs="$pkgs $add"
	done

  # Silently return, when package bundles are empty
  if [ "$pkgs" == "" ]; then
    return 0
  fi

  echo -e "Installing additional packages:\n$pkgs"
	container_debian_install_packages $container_name $pkgs || return $?
  echo "ok."
}


#
# Download a Debian package from a given URL and
# attempt to install it in the container
# (without installing any possible dependencies)
#
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
    local debian_release="$2"
  else
    local debian_release="$default_release"
  fi

  # Three arguments provided
  if [ "$3" != "" ]; then
    local target_architecture="$3"
  else
    local target_architecture="$default_arch"
  fi

  # Fetch the package's page, which (hopefully) contains some download links
  local url="https://packages.debian.org/$debian_release/$target_architecture/$package_name/download"
  echo "Fetching $url ..." >&2
  local page=$(get_page $url) || { echo "Error: get_page() failed." >&2; return 2; }

  # The page cannot be empty
  [[ "$page" != "" ]] || { echo "Error: Page is empty." >&2; return 3; }

  # Apply regular expressions to extract download URLs
  urls=$(
          grep -E ".*<li>.*<a .*href=\"http.*$package.*\.deb\".*>.*<\/a>.*<\/li>.*" - <<< "$page" \
        | sed -e "s/.*\"\(http.*\)\".*/\1/g" \
        | cut -d\" -f2
        )
  # An empty list indicates a non-existent package
  [[ "$urls" != "" ]] || { echo "Error: Failed to parse any URLs from page." >&2; return 4; }

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
  local retval=$?
  [[ $retval == 0 ]] || return $retval
  [[ "$urls" != "" ]] || { echo "Error: Failed get any URLs." >&2; return 5; }

  # Work out the target filename
  local url=$(echo $urls | cut -d" " -f1)
  # local cache="/var/cache/apt/archives"
  local cache="/tmp"
  local filename=$(basename $url)
  [[ "$filename" != "" ]] || { echo "Error: Failed to work out target filename." >&2; return 6; }
  local filepath="$cache/$filename"

  # Download file
  mkdir -p $cache || return 7
  [[ -d $cache ]] || return 8
  get_file "$filepath" $urls &> /dev/null
  [[ $? == 0 ]] || { echo "Error: File download failed." >&2; return 9; }
  [[ -f $filepath ]] || return 10

  # Return full path to downloaded package
  echo $filepath
  return 0
}


#
# Download and install a package by name
# but without invoking apt or apt-get
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
  local retval=$?
  [[ $retval == 0 ]] || return $retval
  [[ "$filename" != "" ]] || return 11
  [[ -f "$filename" ]] || return 12

  # Copy the file to the container
  container_add_file $container_name $filename $filename
  container_test $container_name -f $filename || { echo "Error: Failed to add file to container." >&2; return 13; }

  # Install package inside container
  container_exec $container_name dpkg -i $filename
  return $?
}


function container_debian_install_build_dependencies()
{
  local container_name="$1"
  local package_name="$2"

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
