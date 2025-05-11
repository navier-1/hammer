#!/usr/bin/bash

# This is a testing script to quickly generate a new DB; it's not actually used by the buildsystem

rm -rf build
rm -rf database

cmake -B build -DUSE_CODEQL=ON -DTEST=OFF -DSRC_AUTODETECT=OFF -DSRC_SPECIFY_MODULES=ON -DPRECONFIG_DONE=ON

codeql database create ./database \
        --language=cpp \
        --threads=0 \
        --overwrite \
        --no-db-cluster \
        "--command=cmake --build ./build -j16" \
        --source-root=.

