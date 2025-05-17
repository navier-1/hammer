# clang compilation on linux
set(CMAKE_C_COMPILER   "/usr/bin/clang"   CACHE STRING "C compiler" FORCE)
set(CMAKE_CXX_COMPILER "/usr/bin/clang++" CACHE STRING "C++ compiler" FORCE)
set(CMAKE_LINKER       "/usr/bin/clang++" CACHE STRING "Linker" FORCE)

# set(CMAKE_C_COMPILER_ID   "Clang" CACHE INTERNAL "") 
# set(CMAKE_CXX_COMPILER_ID "Clang" CACHE INTERNAL "")

# CMAKE_FORCE_C_COMPILER(${CMAKE_C_COMPILER} ${CMAKE_C_COMPILER_ID})
# CMAKE_FORCE_CXX_COMPILER(${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ID})

