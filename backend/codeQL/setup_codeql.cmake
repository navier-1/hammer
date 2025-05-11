
# check if codeQL is installed
find_program(CODEQL_EXE codeql)
if(NOT CODEQL_EXE)
    message(WARNING "Could not locate codeql binary. Will attempt to run installation script.")

    find_program(WGET wget)
    if(NOT WGET)
        message(FATAL_ERROR "The codeQL installation script requires wget - install it and re-run.")
    endif()


    # Creates a temporary wrapper script
    file(GENERATE OUTPUT ${CMAKE_BINARY_DIR}/run_interactive.sh
        CONTENT "exec < /dev/tty; exec > /dev/tty; ${HAMMER_DIR}/codeQL/install_codeql.sh"
        FILE_PERMISSIONS OWNER_EXECUTE
    )

    execute_process(
        COMMAND ${CMAKE_BINARY_DIR}/run_interactive.sh
        WORKING_DIRECTORY ${PROJECT_DIR}
        COMMAND_ECHO STDOUT  # Show live output
    )

endif()



