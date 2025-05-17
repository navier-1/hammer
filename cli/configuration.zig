// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

// TODO: configure from the install script, like the CMakeLists.txt
// TODO: also figure out how to share it with the C Yaml module
pub const InstallDir: [:0]const u8 = "/usr/local/lib/hammer";

//const num_config_files = 4;
pub const config_files = [_][]const u8{
    "settings.yml",
    "defines.yml",
    "dependencies.yml",
    "sources.yml",
    //"hidden.yml",
};

// TODO: figure out how to do this from the build system
pub const release_memory: bool = false;


// --- Remote update variables ---

pub const remote_url = "https://github.com/rtyley/small-test-repo.git" ;    //  ->  "https://github.com/Navier1/hammer.git";

pub const tmp_dir = "/tmp/test-clone";

pub const install_script = "install";