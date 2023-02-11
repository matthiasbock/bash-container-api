
#
# Functions to interface with Sourceforge's REST API
#
# Links:
# * https://sourceforge.net/p/forge/documentation/API/
#   * https://sourceforge.net/p/forge/documentation/Allura%20API/
#   * https://sourceforge.net/p/forge/documentation/Download%20Stats%20API/
#   * https://sourceforge.net/p/forge/documentation/Using%20the%20Release%20API/
#
sourceforge_sh="$(realpath "${BASH_SOURCE[0]}")"
cwd="$(dirname "$sourceforge_sh")"

# Source dependencies
if [ "$web_sh" == "" ]; then
 . "$cwd/../utils/web.sh"
fi
unset cwd


# TODO
