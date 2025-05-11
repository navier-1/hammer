# clang compilation on linux
set(CMAKE_C_COMPILER   "clang"   CACHE STRING "C compiler" FORCE)
set(CMAKE_CXX_COMPILER "clang++" CACHE STRING "C++ compiler" FORCE)
set(CMAKE_LINKER       "clang++" CACHE STRING "Linker" FORCE)

set(CMAKE_C_COMPILER_ID   "Clang" CACHE INTERNAL "") 
set(CMAKE_CXX_COMPILER_ID "Clang" CACHE INTERNAL "")

