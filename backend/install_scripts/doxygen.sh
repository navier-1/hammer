#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This command must be run as root." >&2
   exit 1
fi

apt update
apt install doxygen graphviz


