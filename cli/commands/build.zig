const std = @import("std");
const process = @import("../utils/process.zig");


pub fn hBuild(args: [][:0]u8) anyerror!void {

    var build_dir: [:0]const u8 = "./build";

    if (args.len > 0) {
        if (args[0][0] != '-') // should be a valid name
            build_dir = args[0];
    }

    // TODO: pass any further args from the user (e.g. -j16 for Make)
    try process.run(&.{"cmake","--build", build_dir});
}
