// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

const std = @import("std");
const hAutoConfig = @import("config.zig").hAutoConfig;
const hBuild = @import("_build.zig").hBuild;

/// Runs autoconfig (configuration with no user interaction) + build
pub fn hAutoBuild(args: [][:0]u8) anyerror!void {
    try hAutoConfig(args);
    try hBuild(args);
}


