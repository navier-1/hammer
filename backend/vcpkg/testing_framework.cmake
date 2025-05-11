# The only difference is that I'll need to link a framework to the testing executable

# TODO: swap with generic framework, e.g. Catch2
find_package(GTest QUIET)
if(NOT GTest_FOUND)
    # Fallback to vcpkg installation
    execute_process(
        COMMAND ${VCPKG} install gtest --triplet=${VCPKG_TARGET_TRIPLET}
        RESULT_VARIABLE result
    )
    
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "Failed to install GTest via vcpkg")
    endif()
    
    # Retry finding
    find_package(GTest REQUIRED)
endif()



target_link_libraries(${testexe} PRIVATE GTest::GTest)

