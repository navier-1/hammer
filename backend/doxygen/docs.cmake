set(DOCS_FOLDER_IN     ${HAMMER_DIR}/doxygen)
set(DOCS_FOLDER_OUT    ${CMAKE_CURRENT_BINARY_DIR}/documentation)

find_package(Doxygen)
if(NOT DOXYGEN_FOUND)
    message(WARNING "Failed to locate Doxygen - no documentation can be made.") # TODO: consider spawning installation script
else()

    message(STATUS "Located Doxygen - configuring for documentation.")
    set(DOXYGEN_IN  ${DOCS_FOLDER_IN}/Doxyfile.in)
    set(DOXYGEN_OUT ${DOCS_FOLDER_OUT}/Doxyfile)

    configure_file(${DOXYGEN_IN} ${DOXYGEN_OUT} @ONLY)

    add_custom_target(doxygen_${PROJECT_NAME} ALL
        COMMAND ${DOXYGEN_EXECUTABLE} ${DOXYGEN_OUT}
        WORKING_DIRECTORY ${DOCS_FOLDER}
        COMMENT "Generating API documentation with Doxygen"
            VERBATIM)

endif()
