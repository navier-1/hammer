# Self contained, tiny library of CMake functions to interact with git.

function(checkIfGitRepo IS_GIT_REPO)    
    # Check if the current directory is in a Git repository
    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --is-inside-work-tree
        WORKING_DIRECTORY ${PROJECT_DIR} 
        OUTPUT_VARIABLE git_result
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )    

    # Set IS_GIT_REPO based on the result
    set(${IS_GIT_REPO} ${git_result} PARENT_SCOPE)
endfunction()


function(getGitRoot GIT_ROOT)

    execute_process(
        COMMAND ${GIT_EXECUTABLE} rev-parse --show-toplevel
        WORKING_DIRECTORY ${PROJECT_DIR}
        OUTPUT_VARIABLE _git_root
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_VARIABLE _git_error
        RESULT_VARIABLE _git_result
    )
    
    if(_git_result EQUAL 0)
        # Git command succeeded, set the result to parent scope
        set(${GIT_ROOT} "${_git_root}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "This is a git folder, but git failed to get Git root. Error: ${_git_error}")
    endif()
endfunction()


function(createGitRepo)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} init
        WORKING_DIRECTORY ${PROJECT_DIR}
        RESULT_VARIABLE _init_result
        ERROR_VARIABLE _init_error
    )

    if(_init_result EQUAL 0)
        message(WARNING "Git repository was not found, but was initialized successfully.")
    else()
        message(FATAL_ERROR "Git repo not found, and failed to initialize one: ${_init_error}")
    endif()
endfunction()



function(getGitRepo GIT_ROOT HAS_REMOTE REPO_URL)

    set(${HAS_REMOTE} FALSE PARENT_SCOPE)
    set(${REPO_URL}   ""    PARENT_SCOPE)

    execute_process(
        COMMAND ${GIT_EXECUTABLE} remote get-url origin
        WORKING_DIRECTORY ${GIT_ROOT}
        OUTPUT_VARIABLE _git_origin_url
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_VARIABLE _git_error
        RESULT_VARIABLE _git_result
    )

    if(_git_result EQUAL 0)
        set(${HAS_REMOTE} TRUE PARENT_SCOPE)
        set(${REPO_URL} "${_git_origin_url}" PARENT_SCOPE)
    else()
        message(STATUS "No remote found for repository.")
    endif()

endfunction()


function(checkIfSubmodulesPresent)
    execute_process(
        COMMAND git submodule status
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE SUBMODULE_STATUS
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    
    string(REPLACE "\n" ";" SUBMODULE_LIST "${SUBMODULE_STATUS}")
    set(MISSING_SUBMODULES FALSE)
    
    foreach(SUBMODULE ${SUBMODULE_LIST})
        string(REGEX REPLACE "^[-+ ]([0-9a-f]+) ([^ ]+).*" "\\2" SUBMODULE_PATH ${SUBMODULE})
        if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${SUBMODULE_PATH}/.git")
            message(STATUS "Submodule ${SUBMODULE_PATH} is missing")
            set(MISSING_SUBMODULES TRUE)
        endif()
    endforeach()
    
    if(MISSING_SUBMODULES)
        message(STATUS "Some submodules are missing, updating...")
        include(${HAMMER_DIR}/git/UpdateSubmodules.cmake)
    elseif(UPDATE_SUBMODULES)
        include(${HAMMER_DIR}/git/UpdateSubmodules.cmake)
    endif()
endfunction()
