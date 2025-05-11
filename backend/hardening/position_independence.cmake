# The flags for Linux PIE are:
#
# -fPIC: compiler flag to generate Position Indipendent Code (for libraries)
#
# -fPIE: compiler flag to compile code that is assumed to end up in a Position Indipendent Executable
#
# -pie : linker flag that tells it to compile a Position Indipendent Executable


if(PIE)

    message(STATUS "Applying position indipendence flags.")

    set(CMAKE_POSITION_INDEPENDENT_CODE ON)

    if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
        # /DYNAMICBASE for ASLR on Windows (MSVC and Clang support natively)
        # only the linker needs to know its making a position independent binary.
        set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,/DYNAMICBASE")
    elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")

        if(ARTIFACT_TYPE STREQUAL "executable")
            set(  CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -fPIE")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIE")
            set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pie")
        elseif(ARTIFACT_TYPE STREQUAL "shared library")
            set(  CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -fPIC")
            set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")

        endif()

    endif()
endif()

