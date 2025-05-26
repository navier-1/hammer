
if(    NOT "${ARTIFACT_TYPE}" STREQUAL "executable"
   AND NOT "${ARTIFACT_TYPE}" STREQUAL "static library"
   AND NOT "${ARTIFACT_TYPE}" STREQUAL "shared library")
    message(FATAL_ERROR "ARTIFACT_TYPE must be set to one of: \"executable\", \"static library\", or \"shared library\" ")
endif()

if(OBFUSCATE AND NOT STRIP)
    message(WARNING "Overriding strip option to 'yes'. Obfuscating requires binary stripping.")
    set(STRIP yes)
endif()

if(ARTIFACT_TYPE STREQUAL "executable" AND TEST)
    message(WARNING "Overriding TEST to OFF - cannot link test executable to main project as executable.")
    set(TEST OFF)
endif()


# Valgrind checks
set(USING_VALGRIND OFF CACHE BOOL "Set by the buildsystem")
get_cmake_property(all_vars VARIABLES)
foreach(var_name ${all_vars})
    if(var_name MATCHES "^VALGRIND_")
        if(${${var_name}}) # i.e. "if var == ON"
            set(USING_VALGRIND ON CACHE BOOL "Set by the buildsystem" FORCE) # FORCE is there to dynamically update the cache
            break()
        endif()
    endif()
endforeach()
mark_as_advanced(USING_VALGRIND)

if(USING_VALGRIND)
    if(NOT ARTIFACT_TYPE STREQUAL "executable")
    if(NOT TEST)
            message(WARNING "Overriding Valgrind usage to OFF - no executables are being created.")
            set(USING_VALGRIND OFF)
    endif()
    endif()
endif()

if(USING_VALGRIND)
if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    message(WARNING "Overriding Valgrind usage to OFF - Valgrind is a collection of Linux tools, and is not available on Windows.")
    set(USING_VALGRIND OFF)
endif()
endif()



if(RELRO_FULL OR RELRO_PARTIAL)
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        message(WARNING "Overriding RELRO to OFF. RELRO is a Linux-only security feature.")
        set(RELRO_FULL    OFF)
        set(RELRO_PARTIAL OFF)      
    endif()

    if(ARTIFACT_TYPE STREQUAL "static library")
        message(WARNING "RELRO flags cannot be applied to static libraries.\nOverriding RELRO to OFF.")
        set(RELRO_FULL    OFF)
        set(RELRO_PARTIAL OFF)
    endif()

endif()

if(RELRO_FULL AND RELRO_PARTIAL)
    message(WARNING "Both partial and full RELRO were requested; full RELRO will be applied.")
    set(RELRO_FULL ON)
    set(RELRO_PARTIAL OFF)
endif()

if(FORTIFY_1 AND FORTIFY_2)
    message(WARNING "Both FORTIFY_1 and FORTIFY_2 were requested; FORTIFY_2 will be applied.")
    set(FORTIFY_1 OFF)
    set(FORTIFY_2 ON)
endif()

if(CFI)
if(NOT ARTIFACT_TYPE STREQUAL "executable")
    message(WARNING "CFI only makes sense for an execuable (?) - overriding CFI to OFF.")
    set(CFI OFF)
endif()
endif()

if(FUZZ)
    if(NOT ARTIFACT_TYPE STREQUAL "shared library")
        message(WARNING "\nFUZZ option can only be used for shared libs - fuzzer executable needs to link and test functions.\nOverriding FUZZ to OFF.\n")
        set(FUZZ OFF)
    elseif(NOT CMAKE_C_COMPILER_ID STREQUAL "Clang")
        message(WARNING "\nFuzzing is currently only supported for clang. Overriding FUZZ to OFF.")
        set(FUZZ OFF)
    endif()
endif()


set(USING_VCPKG OFF CACHE BOOL "")
if(NOT VCPKG_LIBRARIES STREQUAL "")
    set(USING_VCPKG ON CACHE BOOL "" FORCE)
else()
    mark_as_advanced(VCPKG_LIBRARIES)
endif()
mark_as_advanced(USING_VCPKG)



if(CODE_COVERAGE)
    if(NOT TEST)
        message(WARNING "Code coverage requires tests to be generated. Overriding this option to OFF.")
        set(CODE_COVERAGE OFF)
    endif()
endif()

