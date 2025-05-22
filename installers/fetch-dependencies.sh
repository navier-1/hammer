#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This command must be run as root." >&2
   exit 1
fi

set -e

apt update -y
apt install curl libyaml-dev make cmake cmake-curses-gui cmake-qt-gui -y

# Install CYaml
git clone https://github.com/tlsa/libcyaml.git
cd libcyaml

make
make install
cd ..

# Install zig
curl -O https://ziglang.org/builds/zig-linux-x86_64-0.15.0-dev.552+bc2f7c754.tar.xz
tar -xf zig-linux-x86_64-0.15.0-dev.552+bc2f7c754.tar.xz

mv zig-linux-x86_64-0.15.0-dev.552+bc2f7c754 /usr/local/zig
ln -s /usr/local/zig/zig /usr/local/bin/zig

# Cleanup
rm zig-linux-x86_64-0.15.0-dev.552+bc2f7c754.tar.xz
rm -rf zig-linux-x86_64-0.15.0-dev.552+bc2f7c754
rm -rf libcyaml
