if(EXISTS "${PROJECT_DIR}/subprojects" AND IS_DIRECTORY "${PROJECT_DIR}/subprojects")
else() # TODO: pulire con un NOT
    return() # exit this file
endif()

file(GLOB SUBDIRS RELATIVE
    ${PROJECT_DIR}/subprojects 
    ${PROJECT_DIR}/subprojects/*
)

foreach(subdir ${SUBDIRS})
    set(SUBPROJECT_DIR ${PROJECT_DIR}/subprojects/${subdir})
    if(IS_DIRECTORY ${SUBPROJECT_DIR} AND EXISTS ${SUBPROJECT_DIR}/CMakeLists.txt)
        message(STATUS "Processing subproject: ${subdir}")
        
        # Use a unique binary directory for each subproject
        set(SUBPROJECT_BINARY_DIR ${CMAKE_BINARY_DIR}/${subdir})
        
        # Add the subdirectory
        add_subdirectory(${SUBPROJECT_DIR} ${SUBPROJECT_BINARY_DIR})
        
        # Only process if the subproject creates a target
        if(TARGET ${subdir})
            # Include directories (if needed)
            target_include_directories(${PROJECT_NAME} PRIVATE 
                $<TARGET_PROPERTY:${subdir},INTERFACE_INCLUDE_DIRECTORIES>)
            
            # Link libraries only if they are actually required
            message(STATUS "Linking subproject target: ${subdir}")
            target_link_libraries(${PROJECT_NAME} PRIVATE ${subdir})
        endif()
    endif()
endforeach()