// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.


const std = @import("std");

const hNew = @import("new.zig").hNew;
const hHelp = @import("help.zig").hHelp;
const hInit = @import("init.zig").hInit;
const hClean = @import("clean.zig").hClean;
const hBuild = @import("_build.zig").hBuild;
const hUpdate = @import("update.zig").hUpdate;
const hInstall = @import("install.zig").hInstall;
const hAutoBuild = @import("autobuild.zig").hAutoBuild;

const config = @import("config.zig");
const hConfig = config.hConfig;
const hAutoConfig = config.hAutoConfig;

const Handler = fn (args: [][:0]u8) anyerror!void;

const Command = struct {
    name: []const u8,
    handler: *const Handler,
    help: []const u8,
    category: []const u8,
    // details: []const u8,
};

pub const commands = [_]Command{
    .{ .name = "new",        .handler = &hNew,        .help = "Setup new project directory",                .category = "project"},
    .{ .name = "init",       .handler = &hInit,       .help = "Make the cwd into a project directory",      .category = "project"},
    .{ .name = "config",     .handler = &hConfig,     .help = "Configure project (graphical CMake)",        .category = "project"}, 
    .{ .name = "autoconfig", .handler = &hAutoConfig, .help = "Configure from file (no user interaction)",  .category = "project"},
    .{ .name = "build",      .handler = &hBuild,      .help = "Build project after having configured it",   .category = "project"},
    .{ .name = "autobuild",  .handler = &hAutoBuild,  .help = "Configure + build project from config",      .category = "project"},
    .{ .name = "clean",      .handler = &hClean,      .help = "Cleans the build directory of its contents", .category = "project"},

    // General (consider making the macro-area a further field of the Command type)
    .{ .name = "help",    .handler = &hHelp,    .help = "Prints detailed guide to commands", .category = "utilities"},
    .{ .name = "update",  .handler = &hUpdate,  .help = "Update tool from remote repo",      .category = "utilities"},
    .{ .name = "install", .handler = &hInstall, .help = "Install developer tools",           .category = "utilities"},

    // .{.name = "docs", .handler = , .help = ""},
    // .{.name = "uninstall", .handler = , .help = ""},
};

pub fn printCommands() anyerror!void {
    try std.io.getStdOut().writer().print("Available commands:\n\n", .{});
    for (commands) |cmd| {
        try std.io.getStdOut().writer().print("{s: <10} - {s}\n", .{ cmd.name, cmd.help });
    }
}
