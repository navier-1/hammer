set(CMAKE_BUILD_TYPE "Debug" CACHE INTERNAL "Should be changed via the profile files!" FORCE)

set(CMAKE_C_FLAGS   "-O0")
set(CMAKE_CXX_FLAGS "-O0")


# If we compile for a browser, don't use 'wasm32-wasi', which is for CLI-like apps; use wasm32-unknown-unknown
if(COMPILE_WASM)
    set(CMAKE_C_FLAGS   "${CMAKE_C_FLAGS}   --target=wasm32-freestanding -nostdlib -Wl,--no-entry -Wl,--export-all")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --target=wasm32-freestanding -nostdlib -Wl,--no-entry -Wl,--export-all")
endif()

# GUIDA ALLA SELEZIONE DEL RUNTIME
# Per *impedire* l'uso del C runtime:
#    - il codice C va compilato con -fno-pie oppure -fno-builtin
#
# Per impedire l'uso dello Zig runtime:
#    - il codice zig va compilato con --no-std
#    - *se c'è un main.zig, lo devi esplicitamente linkare a libC con: --library c *
#           * se non lo fai, il compilatore vede che hai main() di zig e linka automaticamente allo zig runtime *
#           * questo probabilmente causerà un errore di doppia definizione del simbolo _start *
# TODO: meglio usare target_compile_options() e target_link_options() per fare CMake moderno...

# Used internally
set(ZIG_FLAGS "-O Debug --no-std")

set(CMAKE_EXE_LINKER_FLAGS "-target ${ZIG_TARGET_TRIPLET}")

