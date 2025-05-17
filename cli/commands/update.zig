// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.
const std = @import("std");
const process = @import("../utils/process.zig");
const configuration = @import("../configuration.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();


/// This function fetches the most recent code from the remote url
/// specified in configuration.zig (TODO: make it part of build.zig)
/// and starts a build + install.
/// 
/// Note: this entire function presumes bash and should be rethought for windows.
/// Make it truly portable.
pub fn hUpdate(_: [][:0]u8) anyerror!void {
    // Repo is cloned under /tmp/ without sticky bit (so it may be deleted by anyone)
    const fetch_command = &[_][:0]const u8{
        "git", "clone", "--depth", "1", configuration.remote_url, configuration.tmp_dir,
    };
    try process.run(fetch_command);

    const install_command = &[_][:0]const u8{configuration.installer_path};
    try process.run(install_command);
}
