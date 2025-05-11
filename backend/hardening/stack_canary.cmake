# Related flags: -fstack-protector, -fstack-protector-strong, -fstack-protector-all, -Wstack-protector

# -fstack-protector : add stack canaries to functions with at least 8 bytes of stack buffer
#   and that contain alloca() (dynamic stack allocations)

#   Note:
#
#   alloca() stands for "alloc automatic", and essentially allocates by adjusting the stack pointer at
#   runtime. Provided that the allocation is not too big, this is much more efficient that running malloc()
#   Additionally, it does not require free(), since the cleanup is handled by the collapse of the stack
#   frame when the function returns.
#
#   gcc, clang and MSVC all support alloca(), despite it not being part of ANSI C or ISO C.

# -fstack-protector-strong : expands the application of canaries to functions that contain:
#   - arrays of any size
#   - references to local variables whose address is taken
#   - functions with local variables that require dynamic initialization

# -fstack-protector-all : protect every function, regardless of stack usage or other criteria

# Note: these options introduce growing overhead.

# -Wstack-protector tells the compiler to warn the developer if it decides not to give a stack canary to
# a function (e.g. because that function does not have a stack buffer)
# e.g. " warning: stack protector not protecting myFunction: no local frame has address taken [-Wstack-protector] "

if(CANARY_BASIC)
    message(STATUS "Applying basic stack canary flags.")

    set(  CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -fstack-protector -Wstack-protector")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector -Wstack-protector")

endif()

if(CANARY_STRONG)
    message(STATUS "Applying strong stack canary flags.")

    set(  CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -fstack-protector-strong -Wstack-protector")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-strong -Wstack-protector")

endif()

if(CANARY_ALL)
    message(STATUS "Applying stack canary to all functions.")

    set(  CMAKE_C_FLAGS   "${CMAKE_C_FLAGS} -fstack-protector-all")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fstack-protector-all")

endif()

