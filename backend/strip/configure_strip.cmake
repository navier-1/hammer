find_program(LLVM_STRIP llvm-strip)
    
if(NOT LLVM_STRIP)
    message(FATAL_ERROR "llvm-strip not found. Cannot strip output binary.")
endif()

message(STATUS "Binary will be stripped using llvm-strip.")

if(OBFUSCATE)
    set(STRIP_TARGET ${OBFUSCATED_ARTIFACT})
    set(STRIP_DEPEND obfuscate_binary)
else()
    set(STRIP_TARGET $<TARGET_FILE:${PROJECT_NAME}>)
    set(STRIP_DEPEND ${PROJECT_NAME})
endif()

get_filename_component(STRIP_TARGET_NAME ${STRIP_TARGET} NAME)

add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/stripped_binary_marker
    COMMAND ${LLVM_STRIP} --strip-all ${STRIP_TARGET}
    COMMAND ${CMAKE_COMMAND} -E touch ${CMAKE_CURRENT_BINARY_DIR}/stripped_binary_marker
    DEPENDS ${STRIP_DEPEND}  # Ensures it waits for the post-build task
    COMMENT "Stripping binary with llvm-strip"
)

# Ensure the stripping task runs after the post-build task
add_custom_target(
    ${PROJECT_NAME}_strip_binary ALL
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/stripped_binary_marker
)