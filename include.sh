#
# Include this file in your bash script
# in order to make use of this library.
#

#
# This file may be included from a path-sensitive context,
# therefore we must return to where we came from when we're done here.
#
old_workdir="$(realpath "$(pwd)")"

#
# Move to the library folder,
# so that the remaining library source files
# can be sourced using relative paths
#
if is_set BASH_CONTAINER_LIBRARY; then
  # Use explicitly provided path setting
  bash_container_library="$BASH_CONTAINER_LIBRARY"
else
  if ! is_set bash_container_library; then
    # Use the path to this file as library path
    include_sh="${BASH_SOURCE[0]}"
    bash_container_library="$(dirname "$include_sh")"
  fi
  bash_container_library="$(realpath "$bash_container_library")"
fi
cd "$bash_container_library"
assets_dir="$bash_container_library/assets"
keys_dir="$assets_dir/keys"

# Include some helper functions operating locally
. src/utils/local.sh
. src/utils/web.sh
. src/utils/checksums.sh

# Include functions for container manipulation
. src/control.sh
. src/volumes.sh
. src/images.sh
. src/networking.sh
. src/users.sh
. src/files.sh
. src/debian/debian.sh
. src/android/android.sh
. src/install.sh
. src/expendables.sh

#
# Make sure a tool for container manipulation is defined
#
if is_set CONTAINER_CLI; then
  # Use cli defined by the caller
  container_cli="$CONTAINER_CLI"
fi
if [ "$container_cli" != "" ]; then
  if [ "$container_cli" == "stub" ]; then
    # Use stub
    container_cli="container_cli_stub"
  elif ! is_program_available $container_cli; then
    echo "Warning: Configured container CLI not found: \"$container_cli\""
  fi
else
  # Guess the CLI to use
  if is_program_available podman; then
    container_cli="$(which podman)"
    echo "Using $container_cli for container manipulation."
  elif is_program_available docker; then
    container_cli="$(which docker)"
    echo "Using $container_cli for container manipulation."
  else
    # Should not be left empty, in case the container functions are called regardless.
    container_cli="container_cli_stub"
    echo "Warning: No program for container manipulation is available."
  fi
fi

# Return to original location
cd "$old_workdir"
unset old_workdir
