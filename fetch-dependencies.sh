#!/bin/bash
set -e

if command -v apt >/dev/null 2>&1; then
    PACMAN="sudo apt"
    CONFIRM="-y"
    PACKAGES="curl libyaml-dev make"
elif command -v brew >/dev/null 2>&1; then
    PACMAN="brew"
    CONFIRM=""
    PACKAGES="curl libyaml make"
else
    echo "This script has not been tested yet for your system - consider editing it by hand, it is quite short."
    return -1
fi

$PACMAN update $CONFIRM
$PACMAN install $CONFIRM $PACKAGES

echo "Installing CYaml..."
git clone https://github.com/tlsa/libcyaml.git

cd libcyaml
make
sudo make install # TODO: reinstall if already present
cd ..

rm -rf libcyaml

