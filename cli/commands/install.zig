// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.
const std = @import("std");
const process = @import("../utils/process.zig");
const configuration = @import("../configuration.zig");

const stdout = std.io.getStdOut().writer();

const Tool = struct {
    name: []const u8,
    help: []const u8,
};

const available_tools = &[_]Tool {
    . { .name = "codeql", .help = "A static analysis tool that creates a queryable DB for you source code."}
};

fn printTools() anyerror!void {
    try stdout.print("Available tools:\n", .{});
    for (available_tools) |tool| {
        try stdout.print("{s: <6} - {s}\n", .{tool.name, tool.help});
    }
    try stdout.print("\n", .{});
}

// TODO: build the list of possible installers at comptime
// const installation_scripts = inline for(available_tools) |tool| {
//     configuration.InstallDir ++ "install_" ++ tool;
// };

pub fn hInstall(args: [][:0]u8) anyerror!void {

    if (args.len == 0) {
        try stdout.print("Usage: hammer install <tool>\n\n", .{});
        try printTools();
        return;
    }

    for (available_tools) |tool| {
        if (std.mem.eql(u8, args[0], tool.name)) {
            try stdout.print("Found available tool: {s}\n", .{tool.name});
            // Simply call the appropriate installer script.
            //try process.run();
            return;
        }
    }
    try stdout.print("No such tool: {s}\n", .{args[0]});
    try printTools();
}


