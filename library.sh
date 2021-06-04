
#
# Source this file in your bash script
# in order to gain container mangement capabilities.
#

export container_cli="$(which podman)"

save_pwd=$(realpath $(pwd))
cd $(realpath $(dirname "${BASH_SOURCE[0]}"))

source networking.sh
source images.sh
source volumes.sh
source containers.sh
source utils.sh
source debian.sh

cd "${save_pwd}"
