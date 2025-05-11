# The _FORTIFY_SOURCE define replaces some libC function interfaces, so that linking occurs against
# hardened versions of memcpy(), strcpy(), snprintf() etc.
#
# Note: unless an optimization level of at least 2 is used, this define will be ignored.
# i.e. compile in release with -O2 or -O3
#
# TODO: figure out why it's not being applied

if(FORTIFY_1 OR FORTIFY_2)

    message(STATUS "Applying fortify defines.")

    if(FORTIFY_1)
        set(  CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -D_FORTIFY_SOURCE=1")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_FORTIFY_SOURCE=1")
    else()
        set(  CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -D_FORTIFY_SOURCE=2")
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D_FORTIFY_SOURCE=2")
    endif()

endif()