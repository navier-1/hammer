# Cache parameters from project_defaults.cmake
set(VERSION "${VERSION}" CACHE INTERNAL "Project version")
set(ARTIFACT_TYPE "${ARTIFACT_TYPE}" CACHE STRING "Type of artifact (executable/shared library/static library)")
set(C_STANDARD "${C_STANDARD}" CACHE STRING "C standard (e.g., 11, 17)")
set(CXX_STANDARD "${CXX_STANDARD}" CACHE STRING "C++ standard (e.g., 17, 20)")

# Load user dependencies.
# TODO: create a ${TARGET}_dependencies_list.cmake file, so that the dependencies can be displayed correctly to the user
# Otherwise the only way to find out if the dependencies.yml is configured well it to try and build, and then get a linker error.
# include(${CONFIG_DIR}/${TARGET}_dependencies_list.cmake)


# --- Some ccmake/cmake-gui support --- #
#set(UPDATE_SUBMODULES      OFF                                  CACHE BOOL "Check submodules during build")
#set(INSTALL_GTEST          OFF                                  CACHE BOOL "Enable GTest installation")
#set(BUILD_GMOCK            OFF CACHE BOOL "Builds the googlemock subproject" )
#set(GTEST_HAS_ABSL         OFF CACHE BOOL "Use Abseil and RE2. Requires Abseil and RE2 to be separately added to the build.")
#set(gtest_build_tests      OFF CACHE BOOL "" )
#set(gtest_build_samples    OFF CACHE BOOL "" )
#set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

#set(CMAKE_TESTING_ENABLED OFF)

# Prevent CTest from creating directories.
#set(CMAKE_CTEST_AUTODISCOVERY_TIMEOUT 0)

#set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")
set_property(CACHE ARTIFACT_TYPE    PROPERTY STRINGS "executable" "static library" "shared library")

# (may want to rename these, since it seems that 'toolchain' typically refers to something else)
# Toolchain files menu (make toggle options from files under toolchains/ dir)

# =================[ Get list of available toolchains ]======================#


set(TOOLCHAIN_DIR "${HAMMER_DIR}/toolchains")

# Get full paths of entries in the directory
file(GLOB TOOLCHAIN_DIRS RELATIVE "${TOOLCHAIN_DIR}" "${TOOLCHAIN_DIR}/*")

set(AVAILABLE_TOOLCHAINS "")
foreach(dir ${TOOLCHAIN_DIRS})
    if(IS_DIRECTORY "${TOOLCHAIN_DIR}/${dir}")
        list(APPEND AVAILABLE_TOOLCHAINS "${dir}")
    endif()
endforeach()

# This sets the default that will be displayed in the graphical configuration, and constrains the
# toolchain to be one of the available ones in the back-end.
# The CLI provides the add-toolchain command to expand this set with custom compilers and linkers.
list(GET AVAILABLE_TOOLCHAINS 0 FIRST_TOOLCHAIN)
set(TOOLCHAIN ${FIRST_TOOLCHAIN} CACHE STRING "Toolchain to use")
set_property(CACHE TOOLCHAIN PROPERTY STRINGS ${AVAILABLE_TOOLCHAINS})

# This variable keeps track of the last set toolchain to detect changes
set(LAST_TOOLCHAIN "${TOOLCHAIN}" CACHE INTERNAL "Last toolchain used to refresh profiles")
if (NOT DEFINED PROFILE)
    set(PROFILE "${FIRST_PROFILE}" CACHE STRING "Compilation profile file to use." FORCE)
endif()


set(AVAILABLE_PROFILES "")
set(PROFILES_DIR ${TOOLCHAIN_DIR}/${TOOLCHAIN}/profiles)

if (EXISTS ${PROFILES_DIR})

    file(GLOB PROFILE_FILES RELATIVE "${TOOLCHAIN_DIR}" "${PROFILES_DIR}/*")

    foreach(full_path ${PROFILE_FILES})
        get_filename_component(profile_name "${full_path}" NAME)
        list(APPEND AVAILABLE_PROFILES "${profile_name}")
    endforeach()

    # Get first profile file
    list(GET AVAILABLE_PROFILES 0 FIRST_PROFILE)
    #set(PROFILE "${FIRST_PROFILE}" CACHE STRING "Compilation profile file to use." FORCE)
    set_property(CACHE PROFILE PROPERTY STRINGS ${AVAILABLE_PROFILES})
endif()


if(DEFINED LAST_TOOLCHAIN)
    set(_LAST_TOOLCHAIN "${LAST_TOOLCHAIN}")
else()
    set(_LAST_TOOLCHAIN "")
endif()



if(NOT _LAST_TOOLCHAIN STREQUAL LAST_TOOLCHAIN)
    set(LAST_TOOLCHAIN "${TOOLCHAIN}" CACHE INTERNAL "Last toolchain used to refresh profiles")
    set(STOP_CONFIGURATION ON)
endif()

