# Zig compilation on linux
set(CMAKE_C_COMPILER          "zig" CACHE STRING "C compiler" FORCE)
set(CMAKE_C_COMPILER_ARG1     "cc"  CACHE STRING "Zig required arg" FORCE)

set(CMAKE_CXX_COMPILER        "zig" CACHE STRING "C++ compiler" FORCE)
set(CMAKE_CXX_COMPILER_ARG1   "c++" CACHE STRING "Zig required arg" FORCE)

set(CMAKE_LINKER              "zig" CACHE STRING "Linker" FORCE)
