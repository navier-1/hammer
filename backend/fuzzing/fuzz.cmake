message(STATUS "Will create fuzzing executable to test the shared library.")

set(FUZZING_DIR "${PROJECT_DIR}/fuzzing")
if(NOT EXISTS ${FUZZING_DIR})
    message(FATAL_ERROR "Failed to locate fuzzing/ dir - cannot create fuzzing executable.\n")
endif()

file(GLOB_RECURSE FUZZER_SRC CONFIGURE_DEPENDS
    "${FUZZING_DIR}/*.cpp"
    "${FUZZING_DIR}/*.c"
)

set(fuzzexe "fuzz_${PROJECT_NAME}")

add_executable(${fuzzexe} ${FUZZER_SRC})
target_include_directories(${fuzzexe} PRIVATE "${PROJECT_DIR}/include")
target_link_libraries(${fuzzexe} PRIVATE ${PROJECT_NAME})

target_compile_options(${fuzzexe} PRIVATE
    -fsanitize=fuzzer
    -fsanitize=address
)

target_link_options(${fuzzexe} PRIVATE
    -fsanitize=fuzzer
    -fsanitize=address
)
