
set(CPACK_NUGET_FILE_LIST 
    ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.dll
    ${CMAKE_BINARY_DIR}/bin/${PROJECT_NAME}.lib
    ${RESOURCES}/readme
)

set(CPACK_NUGET_FILES
    "lib/netstandard2.0/${PROJECT_NAME}.dll"
    "lib/netstandard2.0/${PROJECT_NAME}.lib"
    "readme"
)

set(CPACK_NUGET_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_BASE_NAME}.nupkg")
set(CPACK_NUGET_README_FILE "${RESOURCES}/readme")
