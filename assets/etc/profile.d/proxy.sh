
#
# If a proxy is configured via environment variables,
# automatically adjust the configuration of some programs accordingly:
# - apt client
# - git client
# - docker client
# - gpg client
#
# Note:
# apt configuration requires sudo with NOPASSWD for the current user.
# docker configuration requires jq to be installed.
#

#
# The respective environment variables may
# be provided as upper or lower case,
# that should not make a difference.
#
if [ "${http_proxy:+set}" == set ]; then
  export HTTP_PROXY=${http_proxy}
elif [ "${HTTP_PROXY:+set}" == set ]; then
  export http_proxy=${HTTP_PROXY}
fi
if [ "${https_proxy:+set}" == set ]; then
  export HTTPS_PROXY=${https_proxy}
elif [ "${HTTPS_PROXY:+set}" == set ]; then
  export https_proxy=${HTTPS_PROXY}
fi
if [ "${ftp_proxy:+set}" == set ]; then
  export FTP_PROXY=${ftp_proxy}
elif [ "${FTP_PROXY:+set}" == set ]; then
  export ftp_proxy=${FTP_PROXY}
fi
if [ "${no_proxy:+set}" == set ]; then
  export NO_PROXY=${no_proxy}
elif [ "${NO_PROXY:+set}" == set ]; then
  export no_proxy=${NO_PROXY}
fi

#
# Add missing variables
#
if [ "${HTTP_PROXY:+set}" != set ] && [ "${HTTPS_PROXY:+set}" == set ]; then
  export HTTP_PROXY=${HTTPS_PROXY}
  export http_proxy=${HTTPS_PROXY}
fi
if [ "${HTTPS_PROXY:+set}" != set ] && [ "${HTTP_PROXY:+set}" == set ]; then
  export HTTPS_PROXY=${HTTP_PROXY}
  export https_proxy=${HTTP_PROXY}
fi
if [ "${FTP_PROXY:+set}" != set ] && [ "${HTTP_PROXY:+set}" == set ]; then
  export FTP_PROXY=${HTTP_PROXY}
  export ftp_proxy=${HTTP_PROXY}
fi

#
# Make sure, apt uses the proxy to access Debian package archives.
#
unset sudo
if [ "$(which sudo)" != "" ]; then
  # sudo is installed.
  sudo="$(which sudo)"
elif [ "$USER" == "root" ]; then
  # sudo is not installed, but root doesn't need it anyway.
  sudo=""
fi
if [ "${sudo:+set}" != set ]; then
  echo "Warning: Unable to configure apt. Non-root users need sudo, which is not available (install with \"apt install sudo\")."
else
  APT_PROXY_CONF="/etc/apt/apt.conf.d/10proxy.conf"
  $sudo mkdir -p $(dirname ${APT_PROXY_CONF})
  $sudo rm -f ${APT_PROXY_CONF}

  # Proxy for package archives accessed via HTTP
  if [ "${HTTP_PROXY:+set}" == set ]; then
    echo "Acquire::http::Proxy \"${HTTP_PROXY}\";" | $sudo tee ${APT_PROXY_CONF}
  fi

  # Proxy for package archives accessed via HTTPS
  if [ "${HTTPS_PROXY:+set}" == set ]; then
    echo "Acquire::https::Proxy \"${HTTPS_PROXY}\";" | $sudo tee -a ${APT_PROXY_CONF}
  fi

  # Proxy for package archives accessed via FTP
  if [ "${FTP_PROXY:+set}" == set ]; then
    echo "Acquire::ftp::Proxy \"${FTP_PROXY}\";" | $sudo tee -a ${APT_PROXY_CONF}
  fi
fi
unset sudo

#
# If git is installed,
# configure proxy used to access git repositories.
#
if [ "$(which git)" != "" ]; then
  # Proxy for git repositories accessed via HTTP
  if [ "${HTTP_PROXY:+set}" == set ]; then
    git config --global http.proxy "${HTTP_PROXY}"
  fi

  # Proxy for git repositories accessed via HTTPS
  if [ "${HTTPS_PROXY:+set}" == set ]; then
    git config --global https.proxy "${HTTPS_PROXY}"
  fi
fi

#
# If docker and jq are installed,
# configure proxy to access docker container registries.
#
if [ "$(which docker)" != "" ]; then
  if [ "$(which jq)" == "" ]; then
    echo "Warning: Unable to configure docker. jq is not available (install with \"apt install jq\")."
  else
    DOCKER_CONFIG="$HOME/.docker/config.json"

    # If no docker config is present, create an empty one.
    mkdir -p $(dirname ${DOCKER_CONFIG})
    if [ ! -e ${DOCKER_CONFIG} ]; then
      echo "{}" > ${DOCKER_CONFIG}
    fi

    # Proxy for docker container respositories accessed via HTTP
    if [ "${HTTP_PROXY:+set}" == set ]; then
      cat ${DOCKER_CONFIG} \
      | jq --indent 2 ".proxies.default.httpProxy=\"${HTTP_PROXY}\"" \
      | tee ${DOCKER_CONFIG}
    fi

    # Proxy for docker container respositories accessed via HTTPS
    if [ "${HTTPS_PROXY+set}" == set ]; then
      cat ${DOCKER_CONFIG} \
      | jq --indent 2 ".proxies.default.httpsProxy=\"${HTTPS_PROXY}\"" \
      | tee ${DOCKER_CONFIG}
    fi

    # Proxy exceptions
    if [ "${NO_PROXY:+set}" == set ]; then
      cat ${DOCKER_CONFIG} \
      | jq --indent 2 ".proxies.default.noProxy=\"${NO_PROXY}\"" \
      | tee ${DOCKER_CONFIG}
    fi
  fi
fi

#
# If GnuPG is installed, configure it to use the proxy for keyserver interaction
#
if [ "$(which gpg)" != "" ]; then
  if [ "$HOME" == "" ] && [ "$GNUPGHOME" == "" ]; then
    echo "Warning: Unable to configure GnuPG. gpg is available, but neither HOME nor GNUPGHOME are set."
  else
    # Determine config directory and filename
    if [ "$GNUPGHOME" == "" ]; then
      GNUPGHOME="$(realpath "$HOME")/.gnupg"
    fi
    GPGCONF="$GNUPGHOME/gpg.conf"

    # Create config directory and file
    mkdir -p "$GNUPGHOME"
    touch "$GPGCONF"

    # Remove existing proxy settings
    sed -E "s/http-proxy [^\n]*//" -i "$GPGCONF"

    # Append proxy setting
    echo >> "$GPGCONF"
    echo "http-proxy $HTTP_PROXY" >> $GPGCONF

    # Strip protocol from proxy setting
    sed -E "s/http-proxy http:\/\/([^\n]*)/http-proxy \1/g" -i "$GPGCONF"
  fi
fi
