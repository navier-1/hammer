find_program(WIX_EXECUTABLE wix)
if(NOT WIX_EXECUTABLE)
    message(WARNING "Wix executable not found - MSI installer cannot be created without. Will attempt to download with dotnet CLI.
    [Refer to guides/Packaging.txt]")

    execute_process(
        COMMAND ${PACKAGING_DIR}/install_wix.sh
        WORKING_DIRECTORY ${PROJECT_DIR}
    )

endif()
mark_as_advanced(WIX_EXECUTABLE)


message(STATUS "Checking for wix extensions...")
execute_process(
    COMMAND ${PACKAGING_DIR}/setup_wix.sh
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
message(STATUS "Wix extensions ok.")


set(CPACK_WIX_VERSION 4) # Default is v3 (deprecated)
set(CPACK_WIX_ARCHITECTURE "${CPACK_PACKAGE_ARCHITECTURE}") # Prima era "x64"
set(CPACK_WIX_PRODUCT_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION}")
set(CPACK_WIX_PRODUCT_GUID "${PRODUCT_GUID}")
set(CPACK_WIX_UPGRADE_GUID "${UPGRADE_GUID}")

# They should be png (supports transparency)
set(CPACK_WIX_UI_BANNER    "${RESOURCES}/installer_banner.png")        # Recommended: 493×58  pixels, 20% opacity
set(CPACK_WIX_UI_DIALOG    "${RESOURCES}/installer_background.png")    # Recommended: 493x312 pixels, 30% opacity 

# This is optional. Generate it here: https://convertico.com/
set(CPACK_WIX_PRODUCT_ICON "${RESOURCES}/product_logo.ico")

#[[ [Not working] Provide user prompt to add install dir to PATH
configure_file(
    ${PACKAGING_DIR}/add_to_PATH.wxs.in
    ${CPACK_OUTPUT_DIR}/add_to_PATH.wxs
    @ONLY
)
set(CPACK_WIX_WXS_FILE "${CPACK_OUTPUT_DIR}/new_add_to_PATH.wxs")
]]

set(CPACK_WIX_PACKAGE_FILE_NAME "${CPACK_PACKAGE_FILE_BASE_NAME}.msi")