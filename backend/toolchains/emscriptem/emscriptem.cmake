# Toolchain file for building C/C++ projects to WebAssembly using Emscripten.

# Set the C and C++ compilers to Emscripten's compilers
set(CMAKE_C_COMPILER emcc)
set(CMAKE_CXX_COMPILER em++)

set(CMAKE_AR emar)
set(CMAKE_RANLIB emranlib)

# Ensure the correct CMake system name
set(CMAKE_SYSTEM_NAME WebAssembly)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm)

# Disable the default linker flags and set Emscripten-specific ones
set(CMAKE_EXE_LINKER_FLAGS_INIT "")

# Set build output extensions
set(CMAKE_EXECUTABLE_SUFFIX ".wasm")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".wasm")

