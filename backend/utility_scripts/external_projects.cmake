############################
# Target external projects #
# (like subprojects, but   #
# not managed by CMake )   #
############################

set(EXTERNAL_PROJECTS_FILE "${CMAKE_CURRENT_SOURCE_DIR}/dependencies/external.cmake")

if(EXISTS ${EXTERNAL_PROJECTS_FILE})
    include(ExternalProject)
    message(STATUS "Including external subprojects specified in dependencies/external.cmake")
    include(${EXTERNAL_PROJECTS_FILE})
endif()