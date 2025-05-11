#!/bin/bash

g++ -std=c++17 -fsanitize=address -g -o hammer   frontend/src/configure.cpp frontend/src/main.cpp frontend/src/hammer.cpp frontend/src/directories.cpp frontend/src/utils.cpp frontend/src/pathUtils.cpp -Ifrontend/include
