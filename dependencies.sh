
#
# Functions to wrap the installation of container/project dependencies
#
# Note:
# Debian package installation depends on debian.sh.
#


#
# Load a list of Debian packages from the given dependencies.txt file
# and install them in the container using apt
#
function container_install_dependencies_txt() {
  local container_name="$1"
  local dependencies_txt="$2"

  echo "Loading list of additional Debian packages from \"$dependencies_txt\"..."

  # Check if file exists
  if [ "$dependencies_txt" == "" ] || [ ! -f "$dependencies_txt" ]; then
    echo "Error: File not found."
    return 3
  fi

  # Load file
  local packages="$(cat "$dependencies_txt")"
  if [ $? != 0 ]; then
    echo "Error: Failed to read file."
    return 4
  fi
  if [ "$packages" == "" ]; then
    return 0
  fi

  # Install packages using apt
  container_debian_install_packages $container_name $packages || return $?
}


#
# Load a list of Python3 packages from the given requirements.txt
# and install them in the container using pip3
#
function container_install_requirements_txt() {
  local container_name="$1"
  local requirements_txt="$2"

  echo "Loading list of additional Python3 packages from \"$requirements_txt\"..."

  # Check if file exists
  if [ "$requirements_txt" == "" ] || [ ! -f "$requirements_txt" ]; then
    echo "Error: File not found."
    return 3
  fi

  # Load file
  local packages="$(cat "$requirements_txt")"
  if [ $? != 0 ]; then
    echo "Error: Failed to read file."
    return 4
  fi
  if [ "$packages" == "" ]; then
    return 0
  fi

  # Install one package after another
  for requirement in $requirements; do
    echo -n "Installing $requirement ..."
    container_exec $container_name pip3 install -q $requirement \
    || { echo "Error: Installation failed."; return 5; }
    echo "ok."
  done
}
