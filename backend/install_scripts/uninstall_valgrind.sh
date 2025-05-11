#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This command must be run as root." >&2
   exit 1
fi

apt remove valgrind
apt autoremove
