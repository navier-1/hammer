#!/bin/bash

# vcpkg Uninstallation Script for Linux
# Removes the vcpkg directory and cleans PATH modifications

set -e  # Exit on error

VCPKG_DIR="$HOME/.vcpkg"

# Check if vcpkg is installed
if [ ! -d "$VCPKG_DIR" ]; then
    echo "vcpkg is not installed in $VCPKG_DIR."
    exit 1
fi

# Confirm uninstallation
echo "This will remove vcpkg from $VCPKG_DIR."
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 1
fi

# Remove vcpkg directory
echo "Removing vcpkg..."
rm -rf "$VCPKG_DIR"
echo "vcpkg directory deleted."

# Remove symlink
unlink $HOME/.local/bin/vcpkg

echo "Uninstallation complete! You may need to restart your shell."
