#!/bin/bash
set -e

#read -rp "Linux or MacOS? [linux] " OS
#OS=${OS:-"linux"}

if command -v apt-get &>/dev/null; then
    OS="Linux"
    PACMAN="sudo apt"
elif command -v brew &>/dev/null; then
    OS="macOS"
    PACMAN="brew"
else
    echo "Failed to locate a supported package manager. Currently supported: apt, brew"
fi

ZIG_URL="https://ziglang.org/builds"

# For now, Linux == debian-based
if [[ $OS == [lL][iI][nN][uU][xX] ]]; then
    OPTS="-y"
    PLATFORM_SPECIFIC_PACKAGES="ninja-build cmake cmake-curses-gui libyaml-dev"
    ZIG_BASENAME="zig-x86_64-linux-0.15.0-dev.828+3ce8d19f7"
    ZIG_TAR="$ZIG_BASENAME.tar.xz"
elif [[ $OS == [mM][aA][cC]* ]]; then
    PLATFORM_SPECIFIC_PACKAGES="ninja libyaml"
    ZIG_BASENAME="zig-x86_64-macos-0.15.0-dev.828+3ce8d19f7"
    ZIG_TAR="$ZIG_BASENAME.tar.xz"
else
    echo "Unknown OS: $OS"
    echo "Supported OSs are: Linux (Debian-based), macOS"
    exit 1
fi

$PACMAN update $OPTS
$PACMAN install \
    curl \
    make \
    $PLATFORM_SPECIFIC_PACKAGES \
    $OPTS

echo "Installing CYaml..."
if [ ! -d "$(pwd)/libcyaml" ]; then
  git clone https://github.com/tlsa/libcyaml.git
fi

cd libcyaml
make
sudo make install # TODO: reinstall if already present 
cd ..

echo "Downloading and installing Zig..."
curl -O $ZIG_URL/$ZIG_TAR
tar -xf $ZIG_TAR

mv $ZIG_TAR /usr/local/zig
sudo ln -sf /usr/local/zig/zig /usr/local/bin/zig

# Cleanup
#rm $ZIG_TAR
rm -rf $ZIG_BASENAME
rm -rf libcyaml

echo ""
echo "Done! All dependencies installed. Run the 'install' script at the top level to build and install Hammer."

