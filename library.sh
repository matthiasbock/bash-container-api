
#
# Source this file in your bash script
# in order to gain container mangement capabilities.
#

export container_cli="$(which podman)"

cd $(realpath $(dirname "${BASH_SOURCE[0]}"))
source networking.sh
source images.sh
source volumes.sh
source containers.sh
source utils.sh
source debian.sh
