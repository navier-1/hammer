#!/bin/bash
set -e

read -rp "Linux or MacOS? [linux] " OS
OS=${OS:-"linux"}
ZIG_URL="https://ziglang.org/builds"

# For now, Linux == debian-based
if [[ $OS == [lL][iI][nN][uU][xX] ]]; then
    PACMAN="sudo apt"
    OPTS="-y"
    PLATFORM_SPECIFIC_PACKAGES="ninja-build cmake cmake-curses-gui "
    ZIG_TAR="zig-linux-x86_64-0.15.0-dev.552+bc2f7c754.tar.xz"
elif [[ $OS == [mM][aA][cC]* ]]; then
    PACMAN="brew"
    PLATFORM_SPECIFIC_PACKAGES="ninja"
    ZIG_TAR="zig-x86_64-macos-0.15.0-dev.777+6810ffa42.tar.xz"
else
    echo "Unknown OS: $OS"
    echo "Supported OSs are: Linux, macOS"
    exit 1
fi

$PACMAN update $OPTS
$PACMAN install curl libyaml make $PLATFORM_SPECIFIC_PACKAGES $OPTS

echo "Installing CYaml..."
git clone https://github.com/tlsa/libcyaml.git
cd libcyaml

make
sudo make install # TODO: reinstall if already present 
cd ..

echo "Installing Zig..."
curl -O $ZIG_URL/$ZIG_TAR
tar -xf $ZIG_TAR

mv $ZIG_TAR /usr/local/zig
ln -s /usr/local/zig/zig /usr/local/bin/zig

# Cleanup
rm zig-linux-x86_64-0.15.0-dev.552+bc2f7c754.tar.xz
rm -rf zig-linux-x86_64-0.15.0-dev.552+bc2f7c754
rm -rf libcyaml

