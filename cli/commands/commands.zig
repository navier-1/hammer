const std = @import("std");

const mod_new = @import("new.zig");
const mod_init = @import("init.zig");
const mod_help = @import("help.zig");
const mod_clean = @import("clean.zig");
const mod_build = @import("_build.zig");
const mod_config = @import("config.zig");

const hNew = mod_new.hNew;
const hInit = mod_init.hInit;
const hHelp = mod_help.hHelp;
const hBuild = mod_build.hBuild;
const hClean = mod_clean.hClean;
const hConfig = mod_config.hConfig;
const hAutoConfig = mod_config.hAutoConfig;

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
    .{ .name = "clean",      .handler = &hClean,      .help = "Cleans the build directory of its contents", .category = "project"},

    // General (consider making the macro-area a further field of the Command type)
    // .{.name = "docs", .handler = , .help = ""},
    .{ .name = "help", .handler = &hHelp, .help = "Prints detailed guide to commands", .category = "utilities"},
    // .{.name = "install",   .handler = , .help = ""},
    // .{.name = "update",    .handler = , .help = ""},
    // .{.name = "uninstall", .handler = , .help = ""},
};

pub fn printCommands() anyerror!void {
    try std.io.getStdOut().writer().print("Available commands:\n\n", .{});
    for (commands) |cmd| {
        try std.io.getStdOut().writer().print("{s: <10} - {s}\n", .{ cmd.name, cmd.help });
    }
}
