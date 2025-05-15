const std = @import("std");


pub fn getFlagValue(args: []const [:0]const u8, flag: []const u8) ?[:0]const u8 {
    for (args, 0..args.len) |arg, i| { // TODO: make this args.len - 1
        if (std.mem.eql(u8, arg, flag)) {
            return args[i+1];
        }
    }

    return null;
}


pub fn getFlag(args: []const []u8, flag: []const u8) bool {
    for (args) |arg| {
        if (std.mem.startsWith(u8, arg, flag)) {
            return true;
        }
    }
    return false;
}
