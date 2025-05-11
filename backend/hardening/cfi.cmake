# Enable Control-Flow Integrity that makes.
#
# -fcf-protection: This flag enables Control Flow Protection (CFP), which prevents control
#   flow attacks (like ROP) by adding metadata to the program and enforcing checks at runtime to
#   ensure that control flows only to legitimate targets.
#
#   Compile-time: The compiler emits additional instructions to enforce checks
#   (e.g., Intel CET (Control-flow Enforcement Technology) instructions, such as endbr64 or endbr32).
#
#   Runtime: The processor must support and have CET enabled for the protection to be enforced. Without
#   hardware support or proper runtime configuration, the additional instructions might be ignored or cause errors.
#
# -flto: This flag enables Link-Time Optimization (LTO), which allows the compiler to perform optimizations
#   across the entire program, enabling more aggressive security features such as CFI.
#

if(CFI)

    message(STATUS "Enabling Control-Flow Integrity checks.")

    target_compile_options(${PROJECT_NAME} PRIVATE
        -fcf-protection
        -flto
        -fsanitize=cfi
        -fvisibility=default
        )
    target_link_options(${PROJECT_NAME} PRIVATE
        -flto
        -fsanitize=cfi
        )

    if(TEST)
        message(WARNING "\nCFI has not yet been thoroughly tested for test executables.\n")
        target_compile_options(${testexe} PRIVATE
            -fcf-protection
            -flto
            -fsanitize=cfi
            -fvisibility=default
            )
        target_link_options(${testexe} PRIVATE
            -flto
            -fsanitize=cfi
            )
    endif()

endif()
