message(STATUS "Configuring package for distribution on target system.")
set(PACKAGING_DIR "${HAMMER_DIR}/packaging")

set(RESOURCES "${PROJECT_DIR}/resources")
if(NOT EXISTS ${RESOURCES})
    message(FATAL_ERROR "In order to create an installation package the system expects a 'resources/' directory at the project top level.\nCheck the one provided in the buildsystem repo.\n")
endif()

file(MAKE_DIRECTORY         "${CMAKE_BINARY_DIR}/packages")
set(CPACK_OUTPUT_DIR        "${CMAKE_BINARY_DIR}/packages")
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}/packages")


set(PACKAGE_INFO_FILE "${RESOURCES}/package_info.txt")
file(READ ${PACKAGE_INFO_FILE} PACKAGE_INFO_CONTENT)
string(REPLACE "\n" ";" PACKAGE_INFO_LINES ${PACKAGE_INFO_CONTENT})
foreach(line IN LISTS PACKAGE_INFO_LINES)
    if(NOT line STREQUAL "" AND NOT line MATCHES "^#")
        # Check if the line matches the pattern "KEY=VALUE"
        if(line MATCHES "^([A-Za-z_]+)=(.*)$")
            set(key ${CMAKE_MATCH_1})
            set(value ${CMAKE_MATCH_2})
            set(${key} "${value}" CACHE INTERNAL "" FORCE)
        endif()
    endif()
endforeach()

set(CPACK_PACKAGE_NAME     "${PACKAGE_NAME}")
set(CPACK_PACKAGE_VENDOR   "${PACKAGE_VENDOR}")
set(CPACK_PACKAGE_HOMEPAGE "${PACKAGE_HOMEPAGE}")
set(CPACK_PACKAGE_CONTACT  "${PACKAGE_CONTACT}")
set(CPACK_PACKAGE_ARCHITECTURE "${PACKAGE_ARCHITECTURE}")
set(CPACK_RESOURCE_FILE_LICENSE "${RESOURCES}/license.txt")
set(DESCRIPTION_FILE "${RESOURCES}/package_description.txt")
file(READ ${DESCRIPTION_FILE} CPACK_PACKAGE_DESCRIPTION)
set(CPACK_PACKAGE_AUTHOR "${PACKAGE_AUTHOR}")
set(CPACK_PACKAGE_FILE_BASE_NAME "${PACKAGE_NAME}_${VERSION}")

mark_as_advanced(DESCRIPTION_FILE)
mark_as_advanced(PACKAGE_NAME)
mark_as_advanced(PACKAGE_VENDOR)
mark_as_advanced(PACKAGE_ARCHITECTURE)
mark_as_advanced(PACKAGE_HOMEPAGE)
mark_as_advanced(PACKAGE_CONTACT)
mark_as_advanced(PRODUCT_GUID)
mark_as_advanced(UPGRADE_GUID)
mark_as_advanced(PACKAGE_AUTHOR)
mark_as_advanced(SUPPORT_END_DATE)

set(CPACK_PACKAGE_VERSION "${VERSION}")

message(STATUS "--- Package information ---")
message(STATUS "Package Name: ${CPACK_PACKAGE_NAME}")
message(STATUS "Package Version: ${CPACK_PACKAGE_VERSION}")
message(STATUS "Package Architecture: ${PACKAGE_ARCHITECTURE}")
message(STATUS "Package Vendor: ${CPACK_PACKAGE_VENDOR}")
message(STATUS "Package Homepage: ${CPACK_PACKAGE_HOMEPAGE}")
message(STATUS "Package Contact: ${CPACK_PACKAGE_CONTACT}")
message(STATUS "Product GUID: ${PRODUCT_GUID}")
message(STATUS "Upgrade GUID: ${UPGRADE_GUID}")
message(STATUS "Package description: ${CPACK_PACKAGE_DESCRIPTION}")
message(STATUS "Support end date: ${SUPPORT_END_DATE}")


# Add support end date
set(CPACK_PACKAGE_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION}\n\nSupport available until: {SUPPORT_END_DATE}")

# Configure package generators

if(UNIX)
    set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6 (>= 2.28)")
    set(CPACK_GENERATOR "DEB;TGZ;STGZ")
elseif(WIN32)

    include(${PACKAGING_DIR}/wix.cmake) # generates the .msi
    include(${PACKAGING_DIR}/nuget.cmake)

    set(CPACK_GENERATOR "WIX;ZIP;NuGet")
else()
    message(FATAL_ERROR "Currently no packing generator has been configured for this system. An installer cannot be created.")
endif()


# Default installation folder name
set(CPACK_PACKAGE_INSTALL_DIRECTORY "${PACKAGE_NAME}")

# ---- Specify what the should be installed ----

install(TARGETS ${PROJECT_NAME} DESTINATION bin)

install(
    DIRECTORY "${PROJECT_DIR}/include/"
    DESTINATION include
    FILES_MATCHING
    PATTERN "*.h"
    PATTERN "*.hpp"
    PATTERN "version.h" EXCLUDE
    PATTERN "Porting.h" EXCLUDE
    PATTERN "*.cmake" EXCLUDE
)

# Put runtime deps
foreach(dep_path ${${PROJECT_NAME}_RUNTIME_LIBS_PATH})
    get_filename_component(dep_name ${dep_path} NAME)
    install(FILES ${dep_path} DESTINATION bin)
endforeach()

# Now include the CPack module that procedes with the rest of the configuration.
include(CPack)

message(STATUS "After building the project, run 'cpack' under the build directory to generate packages and installers.")
