// TODO: passare dallo script di build!
pub const InstallDir: [:0]const u8 = "/usr/local/lib/hammer";

const num_config_files = 4;
pub const config_files: [num_config_files][]const u8 = .{
    "settings.yml",
    "defines.yml",
    "dependencies.yml",
    "sources.yml",
    //"hidden.yml",
};
