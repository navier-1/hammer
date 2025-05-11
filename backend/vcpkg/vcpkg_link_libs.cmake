
# Find the installed packages and get their paths

foreach(lib ${VCPKG_LIBRARIES})
    # Convert kebab-case to snake_case (nlohmann-json → nlohmann_json)
    string(REPLACE "-" "_" target_name "${lib}")

    find_package(${target_name} REQUIRED)
    target_link_libraries(${PROJECT_NAME} PRIVATE ${target_name}::${target_name})

    # This should also handle include directories.
endforeach()

# Hiding unnecessary vars for cleanliness
include(${VCPKG_DIR}/vcpkg_hidden_vars.cmake)

