# This sub-script configures the project folder, using functions provided by GitUtils.cmake
# Roughly speaking, the script goes like this:
#
# 1. locate git (necessary for submodules)
# 2. Check if the cwd is inside a git project
# 3. If no, it creates a local git repo.
#    If yes, it checks that it is not the buildSystem's original git folder
#    so that the user is actually tracking their own project insted of the build system.
#    If the git repo is the user's, it continues transparently.


include(${HAMMER_DIR}/git/GitUtils.cmake)

find_program(GIT_EXECUTABLE git)
set(GIT_EXECUTABLE ${GIT_EXECUTABLE} CACHE INTERNAL "")
mark_as_advanced(GIT_EXECUTABLE)

if(NOT GIT_EXECUTABLE)
    message(WARNING "Could not locate git.")
    return()
endif()

checkIfGitRepo(IS_GIT_REPO)

getGitRoot(GIT_ROOT)
getGitRepo(${GIT_ROOT} HAS_REMOTE REPO_URL)

checkIfSubmodulesPresent()
