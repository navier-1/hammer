# Compile on Windows with MSVC
set(CMAKE_C_COMPILER   "cl.exe"   CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER "cl.exe"   CACHE STRING "" FORCE)
set(CMAKE_LINKER       "link.exe" CACHE STRING "" FORCE)

# Set the system to Windows with MSVC
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_VERSION 10)

# Set the C and C++ target compilers for MSVC (x64 target platform)
set(CMAKE_C_COMPILER_TARGET   x86_64-pc-windows-msvc CACHE STRING "" FORCE)
set(CMAKE_CXX_COMPILER_TARGET x86_64-pc-windows-msvc CACHE STRING "" FORCE)

# Set the resource compiler (RC) for MSVC
set(CMAKE_RC_COMPILER "C:/Program Files (x86)/Windows Kits/10/bin/10.0.22621.0/x64/rc.exe")
set(CMAKE_RC_COMPILER_INIT rc)
