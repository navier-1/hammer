# [Experimental] CXX compiler flags (for WebAssembly generation)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s WASM=1")

# Linker flags (for generating the modular JS and WASM output)
set(CMAKE_EXE_LINKER_FLAGS "-s MODULARIZE=1 -s EXPORT_ALL=1 --html_template=${HAMMER_DIR}/templates/template.html")
