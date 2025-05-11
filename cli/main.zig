const std = @import("std");
const InstallDir = @import("configuration.zig").InstallDir;
const mod_commands = @import("commands/commands.zig");
const commands = mod_commands.commands;
const printCommands = mod_commands.printCommands;

const stdout = std.io.getStdOut().writer();
// const allocator = std.heap.page_allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub fn main() !void {
    const args = std.process.argsAlloc(allocator) catch {
        try stdout.print("Failed to allocate memory for CLI arguments.\n", .{});
        return;
    };
    const argc: usize = args.len;

    if (argc == 1) {
        try stdout.print("Usage: hammer [command] [options]\n", .{});
        try printCommands();
        return;
    }

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
}
