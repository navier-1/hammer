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
