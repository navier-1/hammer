#!/bin/bash

# vcpkg Installation Script for Linux
# License: MIT (https://github.com/microsoft/vcpkg/blob/master/LICENSE.txt)

set -e  # Exit on error

VCPKG_DIR="$HOME/.vcpkg"
VCPKG_URL="https://github.com/microsoft/vcpkg.git"

# Check if vcpkg is installed
if [ -d "$VCPKG_DIR" ]; then
    echo "vcpkg is already installed in $VCPKG_DIR."
    exit 1
fi

# Check for git (required)
if ! command -v git &> /dev/null; then
    echo "Error: git is required."
    exit 3
fi

# Notify user about the MIT License
echo "vcpkg is licensed under the MIT License."
echo "By using vcpkg, you agree to its terms:"
echo "  https://github.com/microsoft/vcpkg/blob/master/LICENSE.txt"
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 4
fi

# Clone and bootstrap vcpkg
echo "Installing vcpkg to $VCPKG_DIR..."
git clone "$VCPKG_URL" "$VCPKG_DIR"
cd "$VCPKG_DIR"
./bootstrap-vcpkg.sh

ln -s "$VCPKG_DIR/vcpkg" $HOME/.local/bin/vcpkg

# Verify
if vcpkg --version &> /dev/null; then
    echo ""
    echo "Success! vcpkg is now available for the user."
else
    echo "Error: vcpkg installation failed." >&2
    exit 5
fi
