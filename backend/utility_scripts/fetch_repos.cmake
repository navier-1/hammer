#TODO: this feature is currently inactive. Figure out if vcpkg makes it obsolete (in which case, remove it) or if it should be completed.

# Could be interesting to explore to provide verifiable, non ambiguous dependency management.
# There are other ways to do it though, so this may not end up being completed unless it solves
# a problem that simpler approache cannot.


#Some dependencies support being added with find_package(), others with FetchContent.
#The project can indicate it is happy to accept a dependency by either method using the FIND_PACKAGE_ARGS option to FetchContent_Declare().
#This allows FetchContent_MakeAvailable() to try satisfying the dependency with a call to find_package() first, using the arguments after the
#FIND_PACKAGE_ARGS keyword, if any. If that doesn't find the dependency, it is built from source as described previously instead.

#[[
include(${HAMMER_DIR}/external/dependencies.cmake)
get_property(DEPENDENCIES DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY BUILDSYSTEM_TARGETS)

foreach(dependency ${DEPENDENCIES})
    # Check if the target is a library before linking
    get_target_property(TARGET_TYPE ${dependency} TYPE)
    if(TARGET_TYPE STREQUAL "static library" OR TARGET_TYPE STREQUAL "shared library" OR TARGET_TYPE STREQUAL "INTERFACE_LIBRARY")
        target_link_libraries(${PROJECT_NAME} PRIVATE ${dependency})
    endif()
endforeach()
]]