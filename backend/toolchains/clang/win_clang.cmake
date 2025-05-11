# Compile on Windows w/ Clang compiler
# Note: requires Ninja generator. Otherwise, Visual Studio will
# force MSVC. Setting Ninja in these files does not work:
# *the user needs to add -G "Ninja" when configuring the project.*


set(CMAKE_C_COMPILER   "clang.exe"    CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER "clang++.exe"  CACHE STRING "" FORCE)
set(CMAKE_LINKER       "lld-link.exe" CACHE STRING "" FORCE)

# TODO: there is definitely a better place to put this, if this is even something we'll want
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_VERSION 10)
set(CMAKE_C_COMPILER_TARGET   x86_64-pc-windows-msvc CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER_TARGET x86_64-pc-windows-msvc CACHE STRING "" FORCE)

set(CMAKE_RC_COMPILER "C:/Program Files (x86)/Windows Kits/10/bin/10.0.22621.0/x64/rc.exe")
set(CMAKE_RC_COMPILER_INIT rc)

