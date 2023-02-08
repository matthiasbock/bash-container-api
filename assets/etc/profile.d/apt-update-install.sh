
#
# If there is no package cache or
# the package cache is older than APT_UPDATE_INTERVAL in days,
# and a sources.list is present,
# update the package list.
#
DEBIAN_FRONTEND="noninteractive"

# Get package lists
lists=""
if [ "$APT_UPDATE_INTERVAL" != "" ]; then
  # Files modified less than n*24h ago
  lists=$(find /var/lib/apt/lists/ -type f -mtime -$APT_UPDATE_INTERVAL -name "*_Packages" 2>/dev/null)
else
  if [ "$APT_INSTALL" != "" ] || [ "$APT_INSTALL_FROM" != "" ]; then
    # Any file
    lists=$(find /var/lib/apt/lists/ -type f -name "*_Packages" 2>/dev/null)
  fi
fi

# No (recently modified) lists found
if [ "$lists" == "" ]; then
  if [ $(id) != 0 ] && [ "$(which sudo)" == "" ]; then
    echo "Warning: sudo is required to update package lists, but missing (install with \"apt install sudo\")."
  else
    # Update package lists
    sudo apt-get update -q
  fi
fi
unset lists

#
# When the container is given a list of Debian/Ubuntu packages
# via it's environment variables, install them.
#
# variables:
#   APT_INSTALL_FROM: "dependencies.txt"
#   APT_INSTALL: "wget"
#
if [ "$APT_INSTALL_FROM" != "" ]; then
  if [ -f "$APT_INSTALL_FROM" ]; then
    APT_INSTALL="$APT_INSTALL $(cat "$APT_INSTALL_FROM")"
  else
    echo "Warning: File not found: \"$APT_INSTALL_FROM\"."
  fi
fi

# Append pip to the list of packages to be installed, if needed
if [ "$PIP_INSTALL" != "" ] || [ "$PIP_INSTALL_FROM" != "" ]; then
  APT_INSTALL="$APT_INSTALL python3-pip"
fi

# Install the given list of Debian/Ubuntu packages
if [ "$APT_INSTALL" != "" ]; then
  if [ $(id) != 0 ] && [ "$(which sudo)" == "" ]; then
    echo "Warning: sudo is required to install package dependencies, but missing (install with \"apt install sudo\")."
  else
    echo "Installing packages: $(echo $APT_INSTALL)"
    sudo apt-get -q install -y --no-install-suggests --no-install-recommends $APT_INSTALL;
    echo "Finished installing packages."
  fi
fi
