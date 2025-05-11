# Adapted from https://cliutils.gitlab.io/modern-cmake/chapters/projects/submodule.html
find_package(Git QUIET)

execute_process(COMMAND ${GIT_EXECUTABLE} submodule
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                OUTPUT_VARIABLE EXISTING_SUBMODULES
                RESULT_VARIABLE RETURN_CODE
                OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Updating git submodules:\n${EXISTING_SUBMODULES}")
execute_process(COMMAND ${GIT_EXECUTABLE} submodule update --init --recursive
                WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                RESULT_VARIABLE RETURN_CODE)
if(NOT RETURN_CODE EQUAL "0")
    message(FATAL_ERROR "Cannot update submodules. Git command failed with ${RETURN_CODE}")
endif()
message(STATUS "Git submodules updated successfully")
