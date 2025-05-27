# The purpose of this module is to add runtime dependencies in the build directory, so that executable's may be run for quick tests.
# TODO: consider if perhaps we're not better off performing this operation on the CLI side.

if (DEFINED ${TARGET}_SHARED_LIBS)

    get_target_property(output_dir ${TARGET} RUNTIME_OUTPUT_DIRECTORY)

    foreach(shared_lib ${${TARGET}_SHARED_LIBS})

        if(CMAKE_SYSTEM_NAME STREQUAL "Windows")

            # Fuck you Microsoft let me create symlinks
            add_custom_command(
                TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_if_different "${shared_lib}" "${output_dir}"
            )

        else()

            get_filename_component(lib_name "${shared_lib}" NAME)
            set(symlink_path "${output_dir}/${lib_name}")

            add_custom_command(
                TARGET ${TARGET} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E create_symlink
                    "${output_dir}" "${symlink_path}"
                
                COMMENT "Creating symlink to ${libname} in ${output_dir}" # TODO: not sure printing this is a great idea.
            )

        endforeach()
    endif()

endif()
