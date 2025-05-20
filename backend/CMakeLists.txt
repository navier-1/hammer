cmake_minimum_required(VERSION 3.25)

# TODO: consider making this configurable from yaml
# set(CMAKE_SKIP_COMPILER_TESTS TRUE)

# set(CMAKE_C_COMPILER_FORCED TRUE CACHE INTERNAL "")
# set(CMAKE_C_COMPILER_WORKS  TRUE CACHE INTERNAL "")

# set(CMAKE_CXX_COMPILER_FORCED TRUE CACHE INTERNAL "")
# set(CMAKE_CXX_COMPILER_WORKS  TRUE CACHE INTERNAL "")

# =======================[ Resolve directories ]===========================

# Configured by installer script
set(HAMMER_DIR @@HAMMER_INSTALL_DIR@@)

# Should think about it carefully, but I don't think we can get here without it being defined
if (NOT DEFINED PROJECT_DIR)
    set(PROJECT_DIR "$ENV{PWD}")
endif()

# This contains the .cmake configuration files prepared by the front-end
# by transpiling the Yaml configuration.
set(CONFIG_DIR "${PROJECT_DIR}/.configure/.reserved")
get_filename_component(Project ${PROJECT_DIR} NAME)
set(PROJECT_NAME ${Project})

# =======================[ Declare project ]===========================
# TODO: make the languages configurable
project (${PROJECT_NAME} LANGUAGES C CXX)
set(C_STANDARD   11)
set(CXX_STANDARD 17)

# Propagate compiler and build type settings to submodules
set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE})
set(CMAKE_C_STANDARD ${C_STANDARD})
set(CMAKE_CXX_STANDARD ${CXX_STANDARD})

set(CMAKE_C_STANDARD_REQUIRED   True)
set(CMAKE_CXX_STANDARD_REQUIRED True)
set(CMAKE_CXX_EXTENSIONS OFF)

# =======================[ Load TARGETS list ]===========================
set(CMAKE_INSTALL_LIBDIR ${CMAKE_BINARY_DIR}) # Solves some submodule issues

include(${CONFIG_DIR}/targets.cmake)


# This is a little pork-around until I actually figure out how to conditionally import it when needed
#include(GoogleTest)
include(${CONFIG_DIR}/submodules.cmake)

#    [===============================================================================]
#      The rest of this script is executed once for each and every target to build! 
#    [===============================================================================]

                                foreach(TARGET IN LISTS TARGETS)

set(CMAKE_BUILD_TYPE "" CACHE INTERNAL "Build type hidden from ccmake")
include(${CONFIG_DIR}/${TARGET}_settings.cmake)

if(EXISTS ${HAMMER_DIR}/toolchains/${TOOLCHAIN}/toolchain.cmake)
    include(${HAMMER_DIR}/toolchains/${TOOLCHAIN}/toolchain.cmake)
endif()

# TODO: do the same for the profile

set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release")

if(DEFINED INTERACTIVE)
    set(STOP_CONFIGURATION OFF CACHE INTERNAL "" FORCE)
    
    include(${HAMMER_DIR}/utility_scripts/configuration_support.cmake)

    if(${STOP_CONFIGURATION})
        set(STOP_CONFIGURATION OFF)
        return()
    endif()

endif()

# =======================[ Halt for preconfig ]===========================
# Avoids cache pollution and gives immediately some variables to configure.
if(NOT DEFINED PRECONFIG_DONE)
    message(STATUS "Preconfiguration is complete. Adjust configuration variables, then generate the build script.")
    set(PRECONFIG_DONE ON CACHE INTERNAL "Mark preconfiguration as done. Set to ON to skip preconfiguration.")
    return() # End configuration here
#else()
#    set(PRECONFIG_DONE "${PRECONFIG_DONE}" CACHE INTERNAL "Suppress unused warning")
#    mark_as_advanced(PRECONFIG_DONE)
endif()


# =======================[ Cross compilation support ]===========================
# TODO: rendere questo configurabile nella pagina principale,
# ma mettendo in chiaro che funziona solo se usi Zig come compilatore.
#set(ZIG_TARGET_ARCH "x86_64")
#set(ZIG_TARGET_OS   "linux")
#set(ZIG_TARGET_ABI  "gnu")
#set(ZIG_TARGET_TRIPLET "${ZIG_TARGET_ARCH}-${ZIG_TARGET_OS}-${ZIG_TARGET_ABI}" CACHE STRING "This is going to be a hit.")

#set(VCPKG_TARGET_TRIPLET "x64-linux")
#set(CMAKE_TRIPLET "x86_64-linux-gnu")

#set(ZIG_TARGET_TRIPLET_FLAG "-target" ${ZIG_TARGET_TRIPLET})
#set(ZIG_LINK_RUNTIME "c" CACHE STRING "Choose between zig and c")
# Dato che è binario posso fare anche di lui un menù a tendina che consente di selezionare uno o l'altro runtime.

# =======================[ WASM compilation support ]===========================
# TODO: 99% certain the best course of action is to throw this option out 
# and simply treat WASM as any other Zig target

#option(COMPILE_WASM OFF)
#if(COMPILE_WASM)
#   set(ZIG_TARGET_TRIPLET "wasm32-freestanding")
#    # C flag in zig file (use zig toolchain for convenience)
#endif()

# ========================[ Import source files ]=======================
# This imports the list of globbed dirs and individual files to compile;
# the SRC_FILES list is defined here, with the isolated files already present.

# if (EXISTS ${CONFIG_DIR}/${TARGET}_dependencies_include.cmake)
#     include(${CONFIG_DIR}/${TARGET}_dependencies_include.cmake)
# endif()

include(${CONFIG_DIR}/${TARGET}_sources.cmake)

# Now we add the files from the globbed dirs (There should be a more CMake way to do this...)
foreach(MODULE_DIR ${${TARGET}_GLOBBED_DIRS})
    # TODO: remove the hardcoding, making it recognize certain extensions based on the target's specified languages.
    file(GLOB_RECURSE MODULE_SOURCES CONFIGURE_DEPENDS
        "${SRC_DIR}/${MODULE_DIR}/*.c"
        "${SRC_DIR}/${MODULE_DIR}/*.cpp"
    )
    list(APPEND ${TARGET}_SRC_FILES ${MODULE_SOURCES})
endforeach()

# =======================[ Declare artifact ]===========================
# This is set by the {TARGET}_settings.cmake file

if (${TARGET}_ARTIFACT_TYPE STREQUAL "executable")
    add_executable(${TARGET} ${${TARGET}_SRC_FILES} ${ZIG_OBJECTS})
    set(${TARGET}_PREFIX "")
    set(${TARGET}_SUFFIX ${CMAKE_EXECUTABLE_SUFFIX})
elseif (${TARGET}_ARTIFACT_TYPE STREQUAL "static library")
    add_library(${TARGET} STATIC ${${TARGET}_SRC_FILES} ${ZIG_OBJECTS})
    set(${TARGET}_PREFIX ${CMAKE_STATIC_LIBRARY_PREFIX})
    set(${TARGET}_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX})
elseif (${TARGET}_ARTIFACT_TYPE STREQUAL "shared library")
    add_library(${TARGET} SHARED ${${TARGET}_SRC_FILES} ${ZIG_OBJECTS})
    set(${TARGET}_PREFIX ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(${TARGET}_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX})
else()
    message(FATAL_ERROR "Unknown artifact type: ${${TARGET}_ARTIFACT_TYPE}")
endif()

# This ${TARGET}_BINARY can be used to link one target against another.
set(${TARGET}_BINARY "${CMAKE_CURRENT_BINARY_DIR}/bin/${${TARGET}_PREFIX}${TARGET}${${TARGET}_SUFFIX}")

set_target_properties(${TARGET} PROPERTIES C_STANDARD ${C_STANDARD} CXX_STANDARD ${CXX_STANDARD}) # TODO: remove hardcoding


# =======================[ Load target dependencies ]===========================
if(EXISTS "${CONFIG_DIR}/${TARGET}_dependencies_shared.cmake")
    include(${CONFIG_DIR}/${TARGET}_dependencies_include.cmake)
    include(${CONFIG_DIR}/${TARGET}_dependencies_shared.cmake)
    include(${CONFIG_DIR}/${TARGET}_dependencies_static.cmake)
    include(${CONFIG_DIR}/${TARGET}_dependencies_system.cmake)
endif()

# TODO: integrate vcpkg set(VCPKG_LIBRARIES  ${VCPKG_LIBRARIES} CACHE STRING "List of vcpkg-managed libraries")
# TODO: conan

# =======================[ Load advanced vars ]===========================
# TODO: many of these can probably be marked as local so that they won't show up regardless.
# include(${CONFIG_DIR}/hidden_vars.cmake)

# =======================[ Validate inputs ]===========================
# TODO: rewrite this! A lot of the logic has changed.
# include(${HAMMER_DIR}/utility_scripts/input_validation.cmake)


# =======================[ Run git support ]===========================
# This feature is currently inactive. Not sure what to do with it.

# if(NOT DEFINED GIT_CONFIGURED)
#     include(${HAMMER_DIR}/git/GitConfig.cmake)
#     set(GIT_CONFIGURED ON CACHE BOOL "Git configuration has been performed.")
#     mark_as_advanced(GIT_CONFIGURED)
# endif()

# =======================[ Load codeQL ]===========================
# This feature is currently inactive.

# if(USE_CODEQL)
#    include(${HAMMER_DIR}/codeQL/setup_codeql.cmake)
#endif()

# =======================[ Configuration message ]===========================
# TODO: change this now that cross-compilation is 100% zig managed

if(NOT CMAKE_CROSSCOMPILING)
    message(STATUS "*** Configuring ${${TARGET}_ARTIFACT_TYPE} \"${TARGET}\" for ${CMAKE_HOST_SYSTEM_NAME} ***")
else()
    message(STATUS "*** Cross compiling ${${TARGET}_ARTIFACT_TYPE} \"${TARGET}\" ***")

  message(STATUS "Target triple: ${CMAKE_C_COMPILER_TARGET}")
  message(STATUS "C cross-compiler: ${CMAKE_C_COMPILER}")
  message(STATUS "C++ cross-compiler: ${CMAKE_CXX_COMPILER}")
  message(STATUS "Linker: ${CMAKE_LINKER}")
  message(STATUS "Assembler: ${CMAKE_ASM_COMPILER}")
  message(STATUS "Archiver: ${CMAKE_AR}")
  message(STATUS "NM tool: ${CMAKE_NM}")
  message(STATUS "Ranlib: ${CMAKE_RANLIB}")
  message(STATUS "System root: ${CMAKE_SYSROOT}")

  message(STATUS "\n [WARNING] Make sure that the compilation profile you specified is correct; using an incorrect profile might result in cryptic errors at compile time.")

  message(STATUS "\n* * * * * * * * * * * * * * * * * * *")
endif()

# =======================[ Install vcpkg deps ]===========================
# TODO: implement

#set(DEPENDENCIES_DIR "${PROJECT_DIR}/dependencies")
#set(VCPKG_MANIFEST "${DEPENDENCIES_DIR}/vcpkg.json")
#if(EXISTS "${VCPKG_MANIFEST}")

#    message(STATUS "Detected VCPKG manifest file.")

#    set(VCPKG_DIR "${HAMMER_DIR}/vcpkg")
#    include(${VCPKG_DIR}/vcpkg_install_libs.cmake)
#endif()

# =======================[ Install Conan deps ]===========================
# TODO: implement


# =======================[ Versioning ]===========================
# TODO: there has to be a cleaner way. What do big players do?
# message(STATUS "Project version = ${CMAKE_PROJECT_VERSION}")
# configure_file(${HAMMER_DIR}/configure/version.h.in ${PROJECT_DIR}/include/version.h)


# =======================[ Export commands ]===========================
# Creates a compile_commands.json with the exact commands and flags passed to the compiler.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)


# =======================[ Obfuscation support ]===========================
# This feature is not yet implemented.
# TODO: @Marco riusciamo a non usare tutta openssl?

#if(OBFUSCATE)
#  list(APPEND WIN_STATIC_LIBS "libcrypto.lib" "libssl.lib")
#  list(APPEND WIN_SHARED_LIBS "libcrypto-3-x64.dll" "libssl-3-x64.dll")
#
#  list(APPEND NIX_SHARED_LIBS "libcrypto.so" "libssl.so")
#endif()


# =======================[ Identify source files ]===========================
# TODO: @Marco non mi piace troppo come si complica questa parte se si offusca. Praticamente ti costringe a usare dei file
# sorgente diversi da quelli originali. Riusciamo a trovare un modo di integrarlo in modo più modulare?


#if(OBFUSCATE)
#    set(OBFUSCATION_DIR ${HAMMER_DIR}/obfuscation)
#    message(STATUS "Adding obfuscation sources from ${OBFUSCATION_DIR}")
#    file(GLOB_RECURSE OBF_SRC_FILES CONFIGURE_DEPENDS "${OBFUSCATION_DIR}/src/*.c" "${OBFUSCATION_DIR}/src/*.cpp")
#    list(APPEND SRC_FILES ${OBF_SRC_FILES})
#elseif(SRC_AUTODETECT)


# =======================[ Unity build ]===========================
# This feature is currently inactive.
# Compile everything into 1 source file, avoiding the linker entirely.
# TODO: change the logic here. Could be done by the front-end!

#if(UNITY_BUILD)
#    message(STATUS "Creating a unity build file.")

#    set(UNITY_SRC_FILE "${CMAKE_BINARY_DIR}/UnityBuild.cpp") # TODO: gestire anche il caso di progetti C
#    file(WRITE ${UNITY_SRC_FILE} "")
#    foreach(SRC ${SRC_FILES})
#        file(APPEND ${UNITY_SRC_FILE} "#include \"${SRC}\"\n")
#    endforeach()

    # Replace SOURCE_FILES with UNITY_SRC_FILE
#    set(SRC_FILES ${UNITY_SRC_FILE})
#endif()

# =======================[ Compile Zig sources ]===========================

#if(CMAKE_C_COMPILER MATCHES ".*/?zig$")
#    include(${HAMMER_DIR}/zig/compile_zig.cmake)
#endif()

# =======================[ Link dependencies ]===========================
# Link vcpkg libs  # TODO: add some way of specifying if they link to main proj or test binary

# TODO: add local and conan dependencies here.
#if(EXISTS "${VCPKG_MANIFEST}")
#    include(${VCPKG_DIR}/vcpkg_link_libs.cmake)
#endif()

# =======================[ Compile with codeQL to generate DB ]===========================
# if(USE_CODEQL)
#    include(${HAMMER_DIR}/codeQL/codeql_compilation.cmake)
# endif()

# =======================[ Specify target dirs ]===========================
# TODO: this is not quite working as intended
set_target_properties(${TARGET} PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin
    ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin
)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/bin)
set(ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}")


# =======================[ Check compilation profile ]===========================
# TODO: rewrite this cleaner!

if(DEFINED PROFILE AND NOT PROFILE STREQUAL "")
    set(PROFILE_FILE "${TOOLCHAIN_DIR}/${TOOLCHAIN}/profiles/${PROFILE}")

    if(EXISTS "${PROFILE_FILE}")
        include("${PROFILE_FILE}")
    else()
        message(WARNING "Compilation profile file not found: ${PROFILE_FILE}")
    endif()
endif()

# TODO: move to bottom
mark_as_advanced(CMAKE_CONFIGURATION_TYPES)
mark_as_advanced(CMAKE_C_COMPILER)
mark_as_advanced(CMAKE_C_COMPILER_TARGET)
mark_as_advanced(CMAKE_CXX_COMPILER)
mark_as_advanced(CMAKE_CXX_COMPILER_TARGET)


# =======================[ Last obfuscation step ]===========================
# @Marco
#if(OBFUSCATE)
#  target_include_directories(${PROJECT_NAME} PUBLIC ${OBFUSCATION_DIR}/include)
#  target_include_directories(${PROJECT_NAME} PUBLIC ${OBFUSCATION_DIR}/openssl)
#  target_include_directories(${PROJECT_NAME} PUBLIC ${OBFUSCATION_DIR})
#  set(OSSL_LIB_PATH         "${OBFUSCATION_DIR}/openssl/bin")
#endif()

# =======================[ Add includes to target ]===========================

target_include_directories(${TARGET} PRIVATE ${${TARGET}_INCLUDE_DIRS})

# if(USING_VCPKG)
#    include(${VCPKG_DIR}/vcpkg_link_libs.cmake)
# endif()

# =======================[ Check for precompiled headers ]===========================
# TODO: make this work
# file(GLOB PCH_HEADERS "${PROJECT_DIR}/include/*pch.h*")
# foreach(header IN LISTS PCH_HEADERS)
#     get_filename_component(header_name ${header} NAME)
#     message(STATUS "Located header file to precompile: ${header_name}")
# endforeach()

# =======================[ Linting ]===========================
# TODO: I suspect this is not where we'll want to enforce the language standards
# set_target_properties(${TARGET} PROPERTIES C_STANDARD ${C_STANDARD} CXX_STANDARD ${CXX_STANDARD})

# Propagate compiler and build type settings to submodules
#set(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE})
#set(CMAKE_C_STANDARD ${C_STANDARD})
#set(CMAKE_CXX_STANDARD ${CXX_STANDARD})

#set(CMAKE_C_STANDARD_REQUIRED   True)
#set(CMAKE_CXX_STANDARD_REQUIRED True)
#set(CMAKE_CXX_EXTENSIONS OFF)

#if(LINT)
#    include(${HAMMER_DIR}/lint/configure_linter.cmake)
#endif()

# =======================[ Link binaries ]===========================
# TODO: DELEGARE AL FRONT-END IL CHECK DI ESISTENZA DEI BINARI LOCALI!
# Una volta che quello usa yaml è una passeggiata.

# TODO: Perchè c'era questa differenza in come vengono linkati?
# Comunque non mi piace, va cambiata.

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
  target_link_libraries(
    ${TARGET}
    PRIVATE ${RUNTIME_LIBS}
  )
endif()

# =======================[ Load user defines ]===========================
if(EXISTS ${CONFIG_DIR}/${TARGET}_defines.cmake)
    include(${CONFIG_DIR}/${TARGET}_defines.cmake)
endif()
mark_as_advanced(CMAKE_INSTALL_PREFIX) # TODO: why was this even here?

# =======================[ Address sanitizing ]===========================
# TODO: like for binary hardening (see below) this is probably going to end up 
# in a compiler-related file that lists out compiler flags
#if(SANITIZE)
#    include(${HAMMER_DIR}/sanitize/configure_sanitizer.cmake)
#endif()

# ===========================[ Harden binary ]================================
# TODO: I suspect these files actually won't exist anymore later;
# if one can simply add new compilers and linkers via toolchain files,
# then there will need to be another format that tells us what to pass
# as flag to the compiler and linker for these functions to be performed

include(${HAMMER_DIR}/hardening/cfi.cmake)
include(${HAMMER_DIR}/hardening/fortify.cmake)
include(${HAMMER_DIR}/hardening/nx.cmake)
include(${HAMMER_DIR}/hardening/position_independence.cmake)
include(${HAMMER_DIR}/hardening/relro.cmake)
include(${HAMMER_DIR}/hardening/stack_canary.cmake)
include(${HAMMER_DIR}/hardening/tls.cmake)

# =======================[ Fetch remote deps ]===========================
# TODO: if anything, move in the dependencies portion
# This feature is currently inactive.
# include(${HAMMER_DIR}/utility_scripts/fetch_repos.cmake)


# ===========================[ Create fuzzing executable ]================================
#if(FUZZ)
#    include(${HAMMER_DIR}/fuzzing/fuzz.cmake)
#endif()

# ===========================[ Emit test coverage support ]================================
# Uses the llvm-cov tool. Adds coverage symbols to the project library and to the testing executable (to setup the coverage runtime)

#if(${TEST} AND ${CODE_COVERAGE})
#    include(${HAMMER_DIR}/tests/coverage.cmake)
#endif()

# ===========================[ Emit valgrind script ]================================
#if(USING_VALGRIND)
#    include(${HAMMER_DIR}/utility_scripts/configure_valgrind.cmake)
#endif()


# ===========================[ Setup compilation profiling ]================================
# Will come back to this
#if(COMPILATION_PROFILING)
#    include(${HAMMER_DIR}/compilation_profiling/setup_profiling.cmake)
#endif()


# ========================================================================
# ===========================[ POSTBUILD ]================================
# ==========[ binary patching, documentation, packaging ...]==============

# ===========================[ Obfuscation binary patching ]==============
#if(OBFUSCATE)
#    include(${HAMMER_DIR}/obfuscation/configure_obfuscation.cmake)
#endif()

# ===========================[ Strip binary ]================================
if(STRIP)
    include(${HAMMER_DIR}/strip/configure_strip.cmake)
endif()

# ===========================[ Generate documentation ]================================
if(DOCUMENTATION)
    include(${HAMMER_DIR}/doxygen/docs.cmake)
endif()

# =======================[ Target external projects ]===========================
# (like subprojects, but
# not managed by CMake )
#------------------------
# TODO: if anything, move this to the dependencies portion
# This feature is currently inactive.
# include(${HAMMER_DIR}/utility_scripts/external_projects.cmake)


# ===========================[ Generate installer ]================================
#if(GENERATE_INSTALLER)
#    include(${HAMMER_DIR}/packaging/emit_installer.cmake)
#endif()

# ===========================[ CodeQL usage message ]================================
# TODO: Questo va cambiato, sta al front-end fare re-routing del comando se si accorge che hai abilitato codeQL.
if(USE_CODEQL)
    message(STATUS "To compile the project and generate the CodeQL DB, run:\n\n $ cmake --build <BUILD_DIR> --target codeql \n")
endif()

                                        endforeach() # ends the foreach(TARGET) loop

                                        
                                        
# TRIAL
# TODO: link the submodule targets! But how do I know their names ex-ante?
target_link_libraries(testexe PRIVATE gtest)
