set(CODEQL_DATABASE "database")

# TODO: credo che per semplicità sarebbe da fare override di TEST a OFF se viene settato USE_CODEQL a ON
# TODO: testare se il .codeqlignore sta davvero facendo qualcosa di utile

if(EXISTS "${PROJECT_DIR}/${CODEQL_DATABASE}" AND IS_DIRECTORY "${PROJECT_DIR}/${CODEQL_DATABASE}")
    message(WARNING "\n[WARN] A codeQL DB for this repo already exists - be careful.\n")
    # file(REMOVE_RECURSE "${PROJECT_DIR}/codeql-db/")
endif()

# CodeQL compilation path
message(STATUS "Configuring CodeQL build analyzer")

add_custom_target(codeql
    COMMAND ${CMAKE_COMMAND} -E echo "Creating CodeQL database from compilation commands..."
    COMMAND codeql database create ./${CODEQL_DATABASE}
        --language=cpp
        --threads=0 # one per core
        --overwrite
        --no-db-cluster   # Explicitly disables new structure
        "--command=cmake --build ${CMAKE_BINARY_DIR} -j16"
        --source-root=${PROJECT_DIR}
    WORKING_DIRECTORY ${PROJECT_DIR}
    # DEPENDS ${PROJECT_NAME}
    COMMENT "Compiling & generating CodeQL DB"
)

# Optional: Make it the default target
# set(DEFAULT_TARGET codeql-build)
