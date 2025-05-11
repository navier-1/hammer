#!/bin/bash

echo "This script installs CodeQL, which requires accepting GitHub's EULA."
echo "View the license at: https://github.com/github/codeql-cli-binaries/blob/main/LICENSE.md"
echo ""
read -p "Do you accept the terms? [y/N] " answer

if [[ "$answer" != [Yy]* ]]; then
    echo "EULA not accepted. Exiting."
    exit 1
fi


echo "Starting installation of pre-compiled codeql binaries. Hold on tight!"
sleep 3

FILE="codeql-linux64.zip"
URL="https://github.com/github/codeql-cli-binaries/releases/latest/download/codeql-linux64.zip"

## Check if unzip is installed
if ! command -v unzip &> /dev/null
then
    echo "unzip could not be found, please install it first."
    exit
fi

## Skip download if file exists and is not empty
if [ -f "$FILE" ] && [ -s "$FILE" ]; then
  echo "'$FILE' already exists. Skipping download."
else
  echo "Downloading $FILE..."
  wget "$URL" -O "$FILE"
  # -0 forces overwrite
fi

echo "Will now unzip precompiled binaries. This will take a while."
sleep 5

unzip -q codeql-linux64.zip -d codeql-bin > /dev/null
rm ./codeql-linux64.zip

## Fetch the git repo, necessary for query packets
echo "Fetching git repo, placing it under \$HOME/.codeql"
CODEQL_DIR="$HOME/.codeql"
rm -rf $CODEQL_DIR

echo "Cloning codeql repo to $CODEQL_DIR"
mkdir $CODEQL_DIR
git clone https://github.com/github/codeql.git $CODEQL_DIR/qlpacks # TODO: MAY BE REDUNDANT!

## Installation
echo "Installing to $CODEQL_DIR"
mv codeql-bin/codeql $CODEQL_DIR
rmdir ./codeql-bin

# Install cpp pack (necessary to write and run custom queries)
PATH="$PATH:$CODEQL_DIR"

# Downloading common C++ codeql packages
echo "Installing codeql C++ packages"
sleep 1
codeql pack download codeql/ssa
codeql pack download codeql/mad
codeql pack download codeql/xml
codeql pack download codeql/util
codeql pack download codeql/cpp-all
codeql pack download codeql/tutorial
codeql pack download codeql/dataflow
codeql pack download codeql/typeflow
codeql pack download codeql/typetracking
codeql pack download codeql/rangeanalysis

# Add to PATH
echo "export PATH=\$PATH:$CODEQL_DIR" >> $HOME/.bashrc

echo "All done!"   # Add dir to PATH by placing the following line under $CODEQL_DIR"
echo "Check with: $ which codeql"


#echo "export PATH=\"\$PATH:/usr/bin/codeql"
#echo ""
#echo "Then reload the shell or simply run:"
#echo "source \$HOME/.bashrc"
