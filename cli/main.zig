// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

const std = @import("std");
const config = @import("configuration.zig");
const LinkedList = @import("utils/linked-list.zig").LinkedList;
const mod_commands = @import("commands/commands.zig");

const InstallDir = config.InstallDir;
const release_memory = config.release_memory;

const commands = mod_commands.commands;
const printCommands = mod_commands.printCommands;

const stdout = std.io.getStdOut().writer();

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

pub fn main() !void {
    const args = std.process.argsAlloc(allocator) catch {
        try stdout.print("Failed to allocate memory for CLI arguments.\n", .{});
        return;
    };

    if (args.len == 1) {
        try stdout.print("Usage: hammer [command] [options]\n", .{});
        try printCommands();
        return;
    }

    // Local testing
    //var list = LinkedList([]u8).init(&allocator);
    //var list = try LinkedList([]u8).initFromSlice(&allocator, args);
    //try list.print();
    //const testina: []u8 = try allocator.dupe(u8, "muahahah");
    // TODO: insert() is actually behaving like a write()!
    //try list.insert(0, testina);
    //try list.remove(2);
    //try list.print();
    //list.free();

    var cmd_found = false;
    for (commands) |cmd| {
        if (std.mem.eql(u8, args[1], cmd.name)) {
            cmd_found = true;
            try cmd.handler(args[2..]); // won't pass program name and command name
            break;
        }
    }

    if (!cmd_found) {
        try stdout.print("No such command: {s}\n", .{args[1]});
        try printCommands();
    }

    // if (release_memory) {
    // deleteList()
    // }
}
