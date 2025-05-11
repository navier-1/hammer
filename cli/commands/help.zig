const std = @import("std");

const commands = @import("commands.zig").commands;
const stdout = std.io.getStdOut().writer();

pub fn hHelp(args: [][:0]u8) anyerror!void {

    if (args.len == 0) {
        try stdout.print("Project management commands:\n\n", .{});
        for (commands) |cmd| {
            if (std.mem.eql(u8, cmd.category, "project"))
                try stdout.print("{s: <10} - {s}\n", .{ cmd.name, cmd.help });

            // ...
        }
    } else { // only print the help for the requested commands

        var cmd_found: bool = undefined;
        for(args) |arg| {
            for (commands) |cmd| {
                cmd_found = false;
                if (std.mem.eql(u8, arg, cmd.name)) {
                    cmd_found = true;
                    try stdout.print("{s: <10} - {s}\n", .{ cmd.name, cmd.help });
                    break;
                }                
            }

            if (!cmd_found) {
                try stdout.print("No such command: {s}\n", .{arg});
            }

        }
    }

    return;
}


