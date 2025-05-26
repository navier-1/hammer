
find_program(VALGRIND "valgrind")
if(NOT VALGRIND)
    message(FATAL_ERROR "\n [ERROR] Valgrind not found.\n  Try: $ sudo apt-get install valgrind \n")
endif()
mark_as_advanced(VALGRIND)


if(ARTIFACT_TYPE STREQUAL "executable")
    set(VALGRIND_TARGET ${PROJECT_NAME})
    set(VALGRIND_DIR    ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
elseif(TEST)
    set(VALGRIND_TARGET ${testexe})
    set(VALGRIND_DIR    ${TEST_RUNTIME_DIR})
else()
    return() # nothing to call valgrind on
endif()



set(VALGRIND_COMMANDS "")
set(VALGRIND_FLAGS "")
set(GTEST_FLAGS "")

if(VALGRIND_OUTPUT_XML)
    set(VALGRIND_FLAGS "${VALGRIND_FLAGS} --xml=yes --xml-file=report.xml ")
endif()


if(TEST)
    set(GTEST_FLAGS " ${GTEST_FLAGS} -- --gtest_filter=-*Performance*:*performance*:*Stress*:*stress*")

    if(VALGRIND_OUTPUT_XML)
        set(GTEST_FLAGS "${GTEST_FLAGS} \\> /dev/null")
    endif()
endif()


if(VALGRIND_MEMCHECK)
    list(APPEND VALGRIND_COMMANDS "valgrind --leak-check=full ${VALGRIND_FLAGS} --error-exitcode=1 --show-leak-kinds=all --track-origins=yes $<TARGET_FILE:${VALGRIND_TARGET}> ${GTEST_FLAGS}")
endif()

if(VALGRIND_CACHE_PROFILING)
    list(APPEND VALGRIND_COMMANDS "valgrind --tool=cachegrind ${VALGRIND_FLAGS} $<TARGET_FILE:${VALGRIND_TARGET}> ${GTEST_FLAGS}")
endif()

if(VALGRIND_CALLGRAPH_PROFILING)
    list(APPEND VALGRIND_COMMANDS "valgrind --tool=callgrind ${VALGRIND_FLAGS} $<TARGET_FILE:${VALGRIND_TARGET}> ${GTEST_FLAGS}")
endif()

if(VALGRIND_HEAP_PROFILING)
    list(APPEND VALGRIND_COMMANDS "valgrind --tool=massif ${VALGRIND_FLAGS} $<TARGET_FILE:${VALGRIND_TARGET}> ${GTEST_FLAGS}")
endif()

if(VALGRIND_DETECT_RC)
    list(APPEND VALGRIND_COMMANDS "valgrind --tool=helgrind ${VALGRIND_FLAGS} $<TARGET_FILE:${VALGRIND_TARGET}> ${GTEST_FLAGS}")
endif()

# Convert the list into a single string (separate commands by newlines)
string(REPLACE ";" "\n" VALGRIND_COMMANDS "${VALGRIND_COMMANDS}")

# message(FATAL_ERROR "VALGRIND_COMMANDS : ${VALGRIND_COMMANDS}")

# Generate a bash script to run the enabled Valgrind tools
set(VALGRIND_SCRIPT  ${VALGRIND_DIR}/run_valgrind.sh)

if(EXISTS ${VALGRIND_SCRIPT})
    file(REMOVE ${VALGRIND_SCRIPT})
endif()

#file(WRITE ${VALGRIND_SCRIPT} "#!/bin/bash\n\n")

add_custom_target(ValgrindScript ALL
    COMMAND rm -f ${VALGRIND_SCRIPT}
    COMMAND touch ${VALGRIND_SCRIPT}
    COMMAND echo "'#!/bin/bash'" >> ${VALGRIND_SCRIPT}
    COMMAND echo "" >> ${VALGRIND_SCRIPT}
    COMMAND echo "${VALGRIND_COMMANDS}" >> ${VALGRIND_SCRIPT}
    COMMAND chmod +x ${VALGRIND_SCRIPT}
    DEPENDS ${VALGRIND_TARGET}
#    COMMENT "Generating Valgrind script..."
)



message(STATUS "Will create a bash script to use Valgrind tools in the executable's runtime directory.")
