find_program(CLANG_TIDY NAMES clang-tidy)

if(NOT CLANG_TIDY)
    message(FATAL_ERROR "Clang-tidy not found. Cannot procede with linting.")
endif()
mark_as_advanced(CLANG_TIDY)

set(LINTING_RUNTIME_DIR ${CMAKE_CURRENT_BINARY_DIR}/lint)
file(MAKE_DIRECTORY ${LINTING_RUNTIME_DIR})
set(LOG_FILE "${LINTING_RUNTIME_DIR}/report.log")

configure_file(
    ${HAMMER_DIR}/lint/clang-tidy.in
    ${LINTING_RUNTIME_DIR}/.clang-tidy
    @ONLY
)

# Will be passed to linter
string(REPLACE ";" " " CLANG_TIDY_SRC_FILES "${SRC_FILES}")
string(REPLACE ";" " " CLANG_TIDY_INCLUDE_DIRS "${INCLUDE_DIRS}")

# Create the post-build script
configure_file(
    ${HAMMER_DIR}/lint/run_clang_tidy.sh.in
    ${LINTING_RUNTIME_DIR}/run_clang_tidy.sh
    @ONLY
)

file(CHMOD ${LINTING_RUNTIME_DIR}/run_clang_tidy.sh
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                GROUP_EXECUTE GROUP_READ
                WORLD_EXECUTE WORLD_READ
    )

message(STATUS "Created linter script.")
