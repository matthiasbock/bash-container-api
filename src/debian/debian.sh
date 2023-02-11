#
# This file contains various Debian-specific functions,
# primarily to manage the installed packages in a container.
#
# Note:
# Uses functions from web.sh
# (as well as constants.sh and local.sh, which are implicitly included)
#
debian_sh="$(realpath "${BASH_SOURCE[0]}")"
cwd="$(dirname "$debian_sh")"

# Source dependencies
if [ "$web_sh" == "" ]; then
 . "$cwd/../utils/web.sh"
fi
unset cwd

#
# Call apt in a container to install Debian packages by name
#
function container_debian_install_packages() {
  local container_name="$1"
	local pkgs=$(echo -n "${@:2}" | sed -e "s/  / /g")

  # Make sure, container exists and is running
  # TODO: implement:
  # ensure_container_running $container_name || return $?

  # Silently quit when no package arguments were given
	[[ "$pkgs" == "" ]] && return

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
	[[ $? == 0 ]] && { echo "Installation successful."; return; }

  # Try apt
	echo "Warning: Installation with apt-get failed."
  echo "Re-trying with apt..."
	container_exec $container_name apt -q install -y $pkgs
  [[ $? == 0 ]] && { echo "Installation successful."; return; }

  # Try aptitude
  echo "Warning: Installation with apt failed."
  echo "Re-trying with aptitude..."
	container_exec $container_name aptitude -q install -y $pkgs
  [[ $? == 0 ]] && { echo "Installation successful."; return; }

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

  # Silently quit when no bundle arguments were given
  [[ "$package_bundles" == "" ]] && return

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
        return $ERROR_ILLEGAL_ARGUMENT
      fi
    fi

	  echo -n "Loading package bundle: \"$bundle\": "
    add="$(cat "$bundle")" || {
      echo "Error: Failed to load package bundle from \"$bundle\"." >&2
      return $ERROR_ASSET_NOT_FOUND
    }
    echo "$(echo $add | wc -w) package(s)."
	  local pkgs="$pkgs $add"
	done

  # Silently quit when package bundles are empty
  [[ "$pkgs" == "" ]] && return

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
  local pkg_archive="/var/cache/apt/archives/"

  # Download file
  echo "Installing package $filename from $url ..." >&2
  # TODO: use get_file
  wget --progress=dot "$url" -O "$filename"
  local retval=$?
  [[ $retval == 0 ]] || { echo "Error: File download failed."; return $retval; }

  # Insert file into container
  container_add_file "$container_name" "$filename" "$pkg_archive"
  local retval=$?
  [[ $retval == 0 ]] || { echo "Error: Failed to add downloaded file to container."; return $retval; }
  rm -f "$filename" || true

  # Invoke dpkg to install it
  container_exec $container_name dpkg -i --force-depends "$filename"
  local retval=$?
  [[ $retval == 0 ]] || { echo "Error: dpkg failed (return code $retval)."; return $ERROR_COMMAND_FAILED; }
  container_rm_file $container_name || true

  # Inform about the success of the procedure
  echo "Package installation was successful." >&2
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
  local page=$(get_page $url)
  local retval=$?
  [[ $retval == 0 ]] || { echo "Error: get_page() failed." >&2; return $retval; }

  # The page cannot be empty
  [[ "$page" != "" ]] || { echo "Error: Page is empty." >&2; return $ERROR_CRAWLER_FAILED; }

  # Apply regular expressions to extract download URLs
  urls=$(
          grep -E ".*<li>.*<a .*href=\"http.*$package.*\.deb\".*>.*<\/a>.*<\/li>.*" - <<< "$page" \
        | sed -e "s/.*\"\(http.*\)\".*/\1/g" \
        | cut -d\" -f2
        )
  # An empty list indicates a non-existent package
  [[ "$urls" != "" ]] || { echo "Error: Failed to parse any URLs from page." >&2; return $ERROR_PARSING_FAILED; }

  # Return results via stdout
  echo $urls
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
  [[ "$urls" != "" ]] || { echo "Error: Failed get any URLs." >&2; return $ERROR_ILLEGAL_ARGUMENT; }

  # Work out the target filename
  local url=$(echo $urls | cut -d" " -f1)
  # local cache="/var/cache/apt/archives"
  local cache="/tmp"
  local filename=$(basename $url)
  [[ "$filename" != "" ]] || { echo "Error: Failed to work out target filename." >&2; return $ERROR_ILLEGAL_ARGUMENT; }
  local filepath="$cache/$filename"

  # Download file
  mkdir -p $cache || return $ERROR_COMMAND_FAILED
  [[ -d $cache ]] || return $ERROR_COMMAND_FAILED
  get_file "$filepath" $urls &> /dev/null
  local retval=$?
  [[ $retval == 0 ]] || { echo "Error: File download failed." >&2; return $retval; }
  [[ -f $filepath ]] || return $ERROR_COMMAND_FAILED

  # Return full path to downloaded package via stdout
  echo $filepath
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
  [[ "$filename" != "" ]] || return $ERROR_ILLEGAL_ARGUMENT
  [[ -f "$filename" ]] || return $ERROR_ILLEGAL_ARGUMENT

  # Copy the file to the container
  container_add_file $container_name $filename $filename
  container_test $container_name -f $filename \
  || { echo "Error: Failed to add file to container." >&2; return $ERROR_COMMAND_FAILED; }

  # Install package inside container
  container_exec $container_name dpkg -i $filename
  return $?
}


function container_debian_install_build_dependencies()
{
  local container_name="$1"
  local package_name="$2"

  container_exec $container_name apt-get -q build-dep -y $package_name || return $?
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
