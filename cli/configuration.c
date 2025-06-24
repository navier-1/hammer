/* 
To customize your build, edit this file.

Copyright (c) 2025
Licensed under the GPLv3 — see LICENSE file for details.
*/
#include "configuration.h"


// Building
const char* backend = "cmake";              // cmake, bash
const char* gui_program = "ccmake";         // ccmake, cmake-gui, other, NULL
const char* default_build_dir = "build";    // some valid name
const char* default_build_system = "make";  // make, Ninja, NULL (if using the compiler directly)
const char* override_flag = "--override";   // used to ignore the repo's build script in favor of your own

// These may be changes or set to null
const char* default_autoconfig_flags[] = {
    "-DPRECONFIG_DONE=ON",
    "-DINTERACTIVE=OFF",
    "--no-warn-unused-cli"
};

const char* default_config_flags[] = {
    "-DINTERACTIVE=ON",
    "--no-warn-unused-cli"
};


// Tinkering options
const int release_memory = 0;
const char* remote_url = "https://github.com/navier-1/hammer";
const char* install_script = "install";
const char* tmp_dir = "./tmp_dir";
