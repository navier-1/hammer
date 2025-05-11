if(CMAKE_GENERATOR STREQUAL "Ninja" OR 
   CMAKE_GENERATOR MATCHES "Ninja.*")
    message(STATUS "Using Ninja generator - optimal configuration enabled")
else()
    message(WARNING "Non-Ninja generator detected (${CMAKE_GENERATOR}). Compilation profiling is only supported for that generator.")
    return() # exits this file
endif()


configure_file(
    ${HAMMER_DIR}/compilation_profiling/profile_compilation.sh.in
    ${CMAKE_BINARY_DIR}/profile_compilation.sh
    @ONLY
)

file(CHMOD ${CMAKE_BINARY_DIR}/profile_compilation.sh
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
                    GROUP_EXECUTE GROUP_READ
                    WORLD_EXECUTE WORLD_READ)


message(FATAL_ERROR "\nCiao, ti starai chiedendo cos'è successo. Beh, ancora non abbiamo implementato il profiling dei tempi di compilazione, quindi cortesemente disabilitala.\n")                    