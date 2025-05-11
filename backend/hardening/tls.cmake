# Thread-Local Storage

#[[
The -ftls-model flag specifies how the thread-local storage is implemented and accessed.

Different models have different performance and memory characteristics:
    global-dynamic: The default model where TLS variables are stored in the global address space,
        but each thread accesses them via a special per-thread data pointer.
    local-dynamic: TLS variables are stored in a thread-specific segment, and each thread dynamically
        allocates its own TLS space.
    initial-exec: TLS variables are allocated at thread creation, and each thread has a direct reference
        to its own variables. This model can be faster but uses more memory.
    local-exec: Similar to initial-exec, but variables are placed in a local segment specific to each thread.
]]

# TODO: Implement switching between the possible models.

if(TLS)
    message(WARNING "THIS FEATURE HAS NOT BEEN CHECKED.")
    message(STATUS "Applying Thread-Local Storage flag.")

    target_compile_options(${PROJECT_NAME} PRIVATE -ftls-model=local-exec)
    target_link_options(   ${PROJECT_NAME} PRIVATE -ftls-model=local-exec)

endif()
