#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This command must be run as root." >&2
   exit 1
fi

apt remove llvm-14
apt autoremove
unlink /usr/local/bin/llvm-cov


