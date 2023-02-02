#!/bin/bash

cd $(dirname $(realpath $0))

apt-cache search GnuPG keyring | cut -d " " -f 1 | fgrep -- -keyring > keyrings.list

