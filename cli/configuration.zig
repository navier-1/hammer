// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

// TODO: configure from the install script, like the CMakeLists.txt
// TODO: also figure out how to share it with the C Yaml module
pub const InstallDir: [:0]const u8 = "/usr/local/lib/hammer";

pub const config_files = [_][]const u8{
    "settings.yml",
    "defines.yml",
    "dependencies.yml",
    "sources.yml",
};

// TODO: figure out how to do this from the build system
pub const release_memory: bool = false;

// --- Configuration ---

pub const backend = "cmake";
pub const poor_mans_pwd = ".";
pub const gui_program = "ccmake";       // ccmake, cmake-gui
pub const default_build_dir = "build";
pub const override_flag = "--override";
pub const default_build_system = "Ninja";
pub const configuration_dir = ".configure";
pub const reserved_dir = configuration_dir ++ "/.reserved";

pub const default_autoconfig_flags = [_][:0]const u8{
    "-DPRECONFIG_DONE=ON",
    "-DINTERACTIVE=OFF",
    "--no-warn-unused-cli",
};

pub const default_config_flags = [_][:0]const u8{
    "-DINTERACTIVE=ON",
    "--no-warn-unused-cli",
};

// --- Remote updates ---

const install_script = "install";
pub const remote_url = "https://github.com/navier-1/hammer";
pub const tmp_dir = "./hammer-tmp";
pub const installer_path = tmp_dir ++ "/" ++ install_script; // comptime concatenation
