// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

// TODO: 
// - If any of the .yml files are missing (e.g. accidentally deleted) they are re-added
// - if a CMakeLists.txt exists in the target directory, it should warn the user that 
//   if they want to use the Hammer back-end in that directory they will have to run
//   $ hammer config --override ; without that flag, the project's CMakeLists.txt takes precedence

const std = @import("std");
const allocator = std.heap.page_allocator;

const configuration = @import("../configuration.zig");
const InstallDir = configuration.InstallDir;
const config_files = configuration.config_files;

// Note to self:
// don't think in terms of raw strings for paths like in C;
// use the std.fs.Dir class and its methods

pub fn hInit(args: [][:0]u8) anyerror!void {

    var target_dir = std.fs.cwd();

    var needs_cleanup = false;
    if (args.len > 0) {
        target_dir = try target_dir.openDir(args[0], .{});
        needs_cleanup = true;
    }

    try target_dir.makePath(".configure");
    try target_dir.makePath(".configure/.reserved"); // The cmake files that are derived from the yaml configuration are placed here

    var init_dir = try target_dir.openDir(".configure", .{});
    defer init_dir.close();

    const cwd = std.fs.cwd();
    const install_dir = try cwd.openDir(InstallDir, .{});
    const config_dir  = try install_dir.openDir("project_config", .{});

    // TODO: rewrite so there is a bit more comptime (all src files are known at comptime)
    for (config_files) |config_file| {
        var src = try config_dir.openFile(config_file, .{});
        defer src.close();
        
        var dst = try init_dir.createFile(config_file, .{});
        defer dst.close();

        const src_size = try src.getEndPos();
        _ = try src.copyRange(0, dst, 0, src_size);
    }

    if (needs_cleanup)
        target_dir.close();

    return;
}
