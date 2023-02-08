
#
# When the container is given a list of Python packages
# via it's environment variables, install them.
#
# variables:
#   PIP_INSTALL_FROM: "requirements.txt"
#   PIP_INSTALL: "numpy"
#

# Call pip to install packages from requirements.txt
if [ "$PIP_INSTALL_FROM" != "" ]; then
  if [ -f "$PIP_INSTALL_FROM" ]; then
    echo "Installing Python packages from \"$PIP_INSTALL_FROM\"..."
    pip3 install -r "$PIP_INSTALL_FROM"
    echo "Installation from \"$PIP_INSTALL_FROM\" complete."
  else
    echo "Warning: File not found: \"$PIP_INSTALL_FROM\"."
  fi
fi

# Call pip to install an explicit list of packages
if [ "$PIP_INSTALL" != "" ]; then
  echo "Installing Python packages: $(echo $PIP_INSTALL)"
  pip3 install $PIP_INSTALL
  echo "Finished installing Python packages."
fi

# Add symlink to pytest, if missing
if [ -e /usr/bin/pytest-3 ] && [ ! -e /usr/bin/pytest ] && [ ! -e $HOME/.local/bin/pytest ]; then
  if [ "$(id -u)" == 0 ]; then
    ln -s /usr/bin/python-3 /usr/bin/pytest
  else
    if [ "$HOME" != "" ]; then
      mkdir -p $HOME/.local/bin
      ln -s /usr/bin/pytest-3 $HOME/.local/bin/pytest
    fi
  fi
fi
