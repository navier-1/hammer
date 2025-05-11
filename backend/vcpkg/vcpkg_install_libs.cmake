# Note: for reasons that I'll look into some day, vcpkg configuration must go *before* the project() declaration in CMake.

set(VCPKG_INSTALL_DIR "${HOME_DIR}/.vcpkg") # I *really* don't like having this hardcoded, it depends on the installation script. Need to make it cleaner.
set(VCPKG_MANIFEST_MODE ON)
set(VCPKG_MANIFEST_DIR "${PROJECT_DIR}/dependencies")
set(CMAKE_TOOLCHAIN_FILE "${VCPKG_INSTALL_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")

find_program(VCPKG vcpkg)
set(VCPKG ${VCPKG} CACHE STRING "")
mark_as_advanced(VCPKG)

if(NOT VCPKG)
    message(FATAL_ERROR "vcpkg not found. Try installing with 'hammer install vcpkg'.")
endif()

get_filename_component(VCPKG_ROOT "${VCPKG}" DIRECTORY)


# -- Robust vcpkg.json parsing --
# Step 1: Generate the dependencies file
execute_process(
    COMMAND bash ${HAMMER_DIR}/vcpkg/parse_vcpkg.sh 
            ${VCPKG_MANIFEST_DIR} 
            ${CMAKE_BINARY_DIR}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
)

# Step 2: Include the generated file
include(${CMAKE_BINARY_DIR}/vcpkg_libraries.cmake)
#message(STATUS "VCPKG Libraries: ${VCPKG_LIBRARIES}")
# -- end json parsing --




# Note: --binarycaching makes it so that after compiling once, the binary won't be recompiled next time it's needed.
