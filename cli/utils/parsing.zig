const std = @import("std");

pub fn checkFlag(flag: []const u8, args: []const [:0]const u8) ?[:0]const u8 {
    var i: usize = 0;

    while (i < args.len - 1) : (i += 1) { // args.len - 1 because the next arg is the value
        if (std.mem.eql(u8, args[i], flag))
            return args[i + 1];
    }
    return null;
}


// pub fn get_arg(args: []const []u8, key: []const u8) ?[]const u8 {
//     for (args) |arg| {
//         if (std.mem.startsWith(u8, arg, key)) {
//             return arg[key.len..];
//         }
//     }
//     return null;
// }
