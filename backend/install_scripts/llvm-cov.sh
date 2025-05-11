#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This command must be run as root." >&2
   exit 1
fi

apt update
apt install llvm-14
ln -s /usr/bin/llvm-cov-14 /usr/local/bin/llvm-cov
