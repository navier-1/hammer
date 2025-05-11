################################
# RELocation Read Only (RELRO) #
################################
# In partial RELRO, the non-PLT part of the GOT section (.got from readelf output) is read only,
# but .got.plt is still writeable. Whereas in complete RELRO, the entire GOT (.got and .got.plt both)
# is marked as read-only.
#
# The -z,now flag provides full RELRO.

if(RELRO_FULL OR RELRO_PARTIAL)
    message(STATUS "Applying RELRO flags.")

    if(RELRO_FULL)
        set(FULL_FLAG ",-z,now")
    else()
        set(FULL_FLAG "")
    endif()

    if(ARTIFACT_TYPE STREQUAL "executable")
       set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-z,relro${FULL_FLAG}")
    elseif(ARTIFACT_TYPE STREQUAL "shared library")
        set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,-z,relro${FULL_FLAG}")
    endif()
endif()
