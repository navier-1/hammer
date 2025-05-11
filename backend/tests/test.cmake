set(TEST_SRC_DIR ${PROJECT_DIR}/tests)
# TODO: check if exist, warn and create otherwise

if(NOT ARTIFACT_TYPE STREQUAL "executable")

  if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
      set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
  endif()

  # Ensure that GTest is only compiled once! (only relevant for recursive subprojects)
  if(${PROJECT_DIR} STREQUAL ${PROJECT_DIR})
      add_subdirectory(${HAMMER_DIR}/external/googletest)
  endif()

  set(TEST_RUNTIME_DIR ${CMAKE_CURRENT_BINARY_DIR}/tests)
  set(DATA_DIRECTORY "${TEST_SRC_DIR}/data")

  file(MAKE_DIRECTORY ${TEST_RUNTIME_DIR})

  set(testexe test_${PROJECT_NAME})
  add_executable(${testexe})
  target_link_options(${testexe} PRIVATE "-fuse-ld=lld")

  target_include_directories(${testexe} PRIVATE ${HAMMER_DIR}/external/googletest/googletest/include)
  if(BUILD_GMOCK)
      target_include_directories(${testexe} PRIVATE ${HAMMER_DIR}/external/googletest/googlemock/include)
  endif()

  target_link_libraries(
      ${testexe} PRIVATE

      ${PROJECT_NAME}
      gtest
      gtest_main
  )

  if(SRC_AUTODETECT)
      file(GLOB_RECURSE TEST_SRC_FILES CONFIGURE_DEPENDS "${TEST_SRC_DIR}/*.c" "${TEST_SRC_DIR}/*.cpp")
  elseif(SRC_SPECIFY_MODULES)

      if(NOT EXISTS "${TEST_SRC_DIR}/test_modules.cmake")
          message(FATAL_ERROR "\nTo specify the compilation modules, you must provide a file 'test_modules.cmake' under the tests/ directory. That file must contain:\n set(TEST_MODULES \"module_name_1\" \"module_name_2\") ")
      endif()

      include(${TEST_SRC_DIR}/test_modules.cmake)
      set(TEST_SRC_FILES)

      foreach(MODULE_DIR ${TEST_MODULES})
          file(GLOB_RECURSE MODULE_SOURCES CONFIGURE_DEPENDS
              "${TEST_SRC_DIR}/${MODULE_DIR}/*.c"
              "${TEST_SRC_DIR}/${MODULE_DIR}/*.cpp"
          )

          list(APPEND TEST_SRC_FILES ${MODULE_SOURCES})
      endforeach()

      list(APPEND TEST_SRC_FILES "${TEST_SRC_DIR}/main.cpp")

  elseif(SRC_SPECIFY_FILES)
    if(NOT EXISTS "${TEST_SRC_DIR}/test_source_files.cmake")
        message(FATAL_ERROR "\nTo specify the compilation targets, you must provide a file 'test_source_files.cmake' under the tests/ directory. That file must contain:\n set(TEST_SRC_FILES \"file.cpp\" \"file2.c\") ")
    endif()
    
    include(${TEST_SRC_DIR}/test_source_files.cmake)
  endif()


  if(OBFUSCATE)
      file(GLOB_RECURSE OBF_TEST_SRC_FILES CONFIGURE_DEPENDS "${OBFUSCATION_DIR}/tests/*.c" "${OBFUSCATION_DIR}/tests/*.cpp")
      target_sources(${testexe} PRIVATE  ${OBF_TEST_SRC_FILES})
      target_include_directories(${testexe} PRIVATE ${OBFUSCATION_DIR}/include)
      add_dependencies(${testexe} obfuscate_binary)
  else()
      target_sources(${testexe} PRIVATE ${TEST_SRC_FILES})
  endif()

  set_target_properties(${testexe} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${TEST_RUNTIME_DIR} )

  # root folder from which to search for test files (mp3, jpeg, etc.)
  target_compile_definitions(${testexe} PRIVATE DATA_DIR="${DATA_DIRECTORY}") 

  if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
      message(STATUS "Will copy runtime binaries to ${TEST_RUNTIME_DIR}")
      foreach(shared_lib ${${PROJECT_NAME}_RUNTIME_LIBS_PATH})
          add_custom_command(
              TARGET ${testexe} POST_BUILD
              COMMAND ${CMAKE_COMMAND} -E copy_if_different "${shared_lib}" "${TEST_RUNTIME_DIR}"
          )
      endforeach()

  else()
      message(STATUS "Will create symlinks to dependencies in testing directory.")
      foreach(shared_lib ${${PROJECT_NAME}_RUNTIME_LIBS_PATH})
          get_filename_component(shared_lib_basename ${shared_lib} NAME)

          add_custom_command(
              TARGET ${testexe} POST_BUILD
              COMMAND ${CMAKE_COMMAND} -E create_symlink "${shared_lib}" "${TEST_RUNTIME_DIR}/${shared_lib_basename}"
          )
      endforeach()
  endif()

  set_target_properties(${testexe} PROPERTIES BUILD_RPATH ${TEST_RUNTIME_DIR})
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
      # Find shared libraries next to the executable
      set(CMAKE_BUILD_RPATH_USE_ORIGIN TRUE)
  endif()

  if(OBFUSCATE)
      # Copy project library in test runtime, only after post-build script
      add_custom_command(
          TARGET obfuscate_binary POST_BUILD
          COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "${OBFUSCATED_ARTIFACT}"
              "${TEST_RUNTIME_DIR}/${OUTPUT_PREFIX}${PROJECT_NAME}${OUTPUT_EXTENSION}"
      )
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
      # Copy project library in test runtime
      add_custom_command(
          TARGET ${PROJECT_NAME} POST_BUILD
          COMMAND ${CMAKE_COMMAND} -E copy_if_different
              "$<TARGET_FILE:${PROJECT_NAME}>"
              "${TEST_RUNTIME_DIR}"
      )
  endif()

else()
  # No test, but as a courtesy the script still copies runtime dependencies in the runtime folder.
  message(STATUS "Will copy runtime binaries to ${CMAKE_CURRENT_BINARY_DIR}")
  foreach(shared_lib ${${PROJECT_NAME}_RUNTIME_LIBS_PATH})
      add_custom_command(
          TARGET ${PROJECT_NAME} POST_BUILD
          COMMAND ${CMAKE_COMMAND} -E copy_if_different "${shared_lib}" "${CMAKE_CURRENT_BINARY_DIR}"
      )
  endforeach()

endif()