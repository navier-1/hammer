# Mark memory regions as non-executable. Cannot be overriden by mprotect()

if(NX_STACK)
    message(STATUS "Marking stack non-executable.")

    if(ARTIFACT_TYPE STREQUAL "executable")
       set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -z noexecstack")
    elseif(ARTIFACT_TYPE STREQUAL "shared library")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -z noexecstack")
    endif()

endif()

if(NX_HEAP)
    message(STATUS "Marking heap non-executable.")

    if(ARTIFACT_TYPE STREQUAL "executable")
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -z noexecheap")
    elseif(ARTIFACT_TYPE STREQUAL "shared library")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -z noexecheap")
    endif()

endif()
