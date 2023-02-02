
#
# Include this file in your bash script
# in order to make use of this library.
#

#
# This file may be included from a path-sensitive context,
# therefore we must return to where we came from when we're done here.
#
oldpath="$(realpath "$(pwd)")"

# Move to this file's location
cd $(realpath $(dirname "${BASH_SOURCE[0]}"))

# Include some helper functions operating locally
. local.sh
. web.sh

# Include functions for container manipulation
. control.sh
. volumes.sh
. images.sh
. networking.sh
. user.sh
. utils.sh
. debian.sh
. dependencies.sh
. expendables.sh

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
cd "$oldpath"
unset oldpath
