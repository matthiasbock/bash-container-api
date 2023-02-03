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

# Include functions for local tasks
. src/utils/local.sh

# Include functions to interact with the internet
. src/utils/web.sh

# Include functions for file checksum calculation and verification
. src/utils/checksums.sh

# Define the program used for container manipualtion
. src/cli.sh

# Include essential container control functions (create, start, stop etc.)
. src/control.sh

# Include functions for the management of container volumes
. src/volumes.sh

# Include functions for the management of container images
. src/images.sh

# Include functions to customize container networking
. src/networking.sh

# Include functions to conveniently manage users and groups within a container
. src/users.sh

# Include functions to conveniently manipulate files within a container
. src/files.sh

# Include functions for convenient package installation on Debian-based containers
. src/debian/debian.sh

# Include more package installation helper functions
. src/install.sh

# Include functions for working with android images/containers
. src/android/android.sh

# Include functions for the removal of superfluous files from containers
. src/expendables.sh

# Return to original location
cd "$old_workdir"
unset old_workdir
