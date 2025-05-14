const std = @import("std");


var gpa = std.heap.GeneralPurposeAllocator(.{}){};


/// Searches the filesystem from the cwd upwards, looking for the directory with the
/// configuration files that would make this a Hammer-managed project.
/// This allows configuring and building the project from anywhere within the repo.
pub fn revSearch(allocator: std.mem.Allocator, _target: []const u8) anyerror![]const u8 {
const start_dir = try std.fs.cwd().realpathAlloc(allocator, ".");
    defer allocator.free(start_dir); // Only free once

    const target = try allocator.dupe(u8, _target);
    defer allocator.free(target);

    var dir_path = try allocator.dupe(u8, start_dir);

    while (true) {
        var dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true });
        defer dir.close();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            if (std.mem.eql(u8, entry.name, target)) {
                return dir_path; // Ownership passed to caller
            }
        }

        const parent = std.fs.path.dirname(dir_path) orelse return error.NotFound;
        if (std.mem.eql(u8, dir_path, parent)) return error.NotFound; // reached root

        const new_path = try allocator.dupe(u8, parent);
        allocator.free(dir_path);
        dir_path = new_path;
    }
} 



