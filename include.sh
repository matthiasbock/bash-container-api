#
# Include this file in your bash script
# in order to make use of this library.
#

#
# This file may be included from a path-sensitive context,
# therefore we must return to where we came from when we're done here.
#
old_workdir="$(realpath "$(pwd)")"

# Move to this file's location
include_sh="${BASH_SOURCE[0]}"
bash_container_library="$(dirname "$include_sh")"
bash_container_library="$(realpath "$bash_container_library")"
cd "$bash_container_library"

# Include some helper functions operating locally
. src/utils/local.sh
. src/utils/web.sh

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

# Finally, make sure a tool for container manipulation is defined
if ! is_set container_cli; then
  if is_program_available podman; then
    container_cli="$(which podman)"
    echo "Using $container_cli for container manipulation."
  elif is_program_available docker; then
    container_cli="$(which docker)"
    echo "Using $container_cli for container manipulation."
  else
    # Should not be left empty, in case the container functions are called regardless.
    container_cli="podman"
    echo "Error: No program for container manipulation is available."
  fi
fi

# Return to original location
cd "$old_workdir"
unset old_workdir
