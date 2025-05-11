find_package(Python REQUIRED)
    
if(NOT (ARTIFACT_TYPE STREQUAL "static library"))
    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        set(python_script "${OBFUSCATION_DIR}/win_encrypt_and_patch.py")
    else()
        set(python_script "${OBFUSCATION_DIR}/nix_encrypt_and_patch.py")
    endif()
else()
    set(python_script "${OBFUSCATION_DIR}/static_lib_encrypt_and_patch.py")
endif()

if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    if(ARTIFACT_TYPE STREQUAL "executable")
        set(OUTPUT_EXTENSION ".exe")
    elseif(ARTIFACT_TYPE STREQUAL "static library")
        set(OUTPUT_EXTENSION ".lib")
    elseif(ARTIFACT_TYPE STREQUAL "shared library")
        set(OUTPUT_EXTENSION ".dll")
    endif()
    set(OUTPUT_PREFIX "")
else(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    if(ARTIFACT_TYPE STREQUAL "executable")
        set(OUTPUT_EXTENSION "")
        set(OUTPUT_PREFIX "")
    elseif(ARTIFACT_TYPE STREQUAL "static library")
        set(OUTPUT_EXTENSION ".a")
        set(OUTPUT_PREFIX "lib")
    elseif(ARTIFACT_TYPE STREQUAL "shared library")
        set(OUTPUT_EXTENSION ".so")
        set(OUTPUT_PREFIX "lib")
    endif()
endif()

if(ARTIFACT_TYPE STREQUAL "static library")
    # In case of static library, we could not make the linking step work
    # without modifying the binary in-place, so we do it in-place for static library
    set(OBFUSCATED_ARTIFACT "${CMAKE_CURRENT_BINARY_DIR}/bin/${OUTPUT_PREFIX}${PROJECT_NAME}${OUTPUT_EXTENSION}")
else()
    set(OBFUSCATED_ARTIFACT "${CMAKE_CURRENT_BINARY_DIR}/bin/${OUTPUT_PREFIX}${PROJECT_NAME}_obfuscated${OUTPUT_EXTENSION}")
endif()

add_custom_target(
    obfuscate_binary ALL
    COMMAND ${CMAKE_COMMAND} -E echo "Running obfuscation script..."

    COMMAND ${Python_EXECUTABLE}
        ${python_script}
        "$<TARGET_FILE:${PROJECT_NAME}>"
        "${CMAKE_CURRENT_BINARY_DIR}/output.map"
        "${OBFUSCATED_ARTIFACT}"
        "${OBFUSCATION_DIR}/target_pairs.txt"
        "${license_path}"


    DEPENDS ${PROJECT_NAME}

    COMMAND ${CMAKE_COMMAND} -E echo "Post-build obfuscation completed."
)