file(GLOB_RECURSE ZIG_SOURCES CONFIGURE_DEPENDS "${SRC_DIR}/*.zig")

foreach(zig_src ${ZIG_SOURCES})

    get_filename_component(zig_name ${zig_src} NAME_WE)
    set(obj_file ${CMAKE_CURRENT_BINARY_DIR}/${zig_name}.o) # TODO: siamo sicuri che vadano qui?

    if(zig_name STREQUAL "main")
        message(STATUS "Located Zig main. Will link to C runtime.")
        set(ZIG_LINK_RUNTIME_FLAG "--library" ${ZIG_LINK_RUNTIME})   # letteralmente: --library c oppure --library zig
    endif()

    add_custom_command(
        OUTPUT ${obj_file}
        COMMAND zig build-obj ${zig_src} ${ZIG_FLAGS} ${ZIG_TARGET_TRIPLET_FLAG} ${ZIG_LINK_RUNTIME_FLAG}
        DEPENDS ${zig_src}
        COMMENT "Compiling: ${zig_src}"
    )

    list(APPEND ZIG_OBJECTS ${obj_file})

    if(ZIG_LINK_RUNTIME_FLAG)
        unset(ZIG_LINK_RUNTIME_FLAG)
    endif()

endforeach()