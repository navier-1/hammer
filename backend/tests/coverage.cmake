message(STATUS "Configuring for code coverage reports.")

if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    target_compile_options(${PROJECT_NAME} PRIVATE -fprofile-arcs -ftest-coverage)
    target_link_options(   ${PROJECT_NAME} PRIVATE -fprofile-arcs -ftest-coverage)

    target_compile_options(${testexe} PRIVATE -fprofile-arcs -ftest-coverage)
    target_link_options(   ${testexe} PRIVATE -fprofile-arcs -ftest-coverage)
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    target_compile_options(${PROJECT_NAME} PRIVATE -fprofile-instr-generate -fcoverage-mapping -g)
    target_link_options(   ${PROJECT_NAME} PRIVATE -fprofile-instr-generate)

    target_compile_options(${testexe} PRIVATE -fprofile-instr-generate -fcoverage-mapping -g)
    target_link_options(   ${testexe} PRIVATE -fprofile-instr-generate)
else()
    message(FATAL_ERROR "Code coverage is currently unsupported for compiler with ID: ${CMAKE_C_COMPILER_ID}")
endif()


get_target_property(PROJECT_LIB_NAME ${PROJECT_NAME} OUTPUT_NAME)

configure_file(
    ${HAMMER_DIR}/configure/generate_coverage.sh.in
    ${TEST_RUNTIME_DIR}/generate_coverage.sh
    @ONLY
)

file(CHMOD ${TEST_RUNTIME_DIR}/generate_coverage.sh
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                GROUP_EXECUTE GROUP_READ
                WORLD_EXECUTE WORLD_READ)
