const std = @import("std");
const process = @import("../utils/process.zig");
const search = @import("../utils/search-filesystem.zig");

const revSearch = search.revSearch;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

pub fn hBuild(args: [][:0]u8) anyerror!void {

    var build_dir: [:0]const u8 = undefined;

    if (args.len > 0) {
        if (args[0][0] != '-') // should be a valid name
            build_dir = args[0];
    } else {        
        const target: [:0]const u8 = ".configure"; // TODO: read the configuration dir from (heh) configuration, or set in build script.
        const project_dir = try revSearch(allocator, target);
        build_dir = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{project_dir, "build"});
        // if MEM_FREE
        allocator.free(project_dir);
    }

    // TODO: pass any further args from the user (e.g. -j16 for Make); this is the same as what is done in the config command
    try process.run(&.{"cmake","--build", build_dir});

    // if MEM_FREE...
    allocator.free(build_dir);
}
