const std = @import("std");


var gpa = std.heap.GeneralPurposeAllocator(.{}){};


/// Searches the filesystem from the cwd upwards, looking for the directory with the
/// configuration files that would make this a Hammer-managed project.
/// This allows configuring and building the project from anywhere within the repo.


pub fn revSearch(allocator: std.mem.Allocator, target: [:0]const u8) anyerror![:0]const u8 {

   
    
    const start_dir: []const u8 = try std.fs.cwd().realpathAlloc(allocator, ".");
    //defer allocator.free(start_dir); // TODO: if free memory etc.

    var dir_path_buf = try allocator.dupeZ(u8, start_dir);
    var dir_path: [:0]const u8 = dir_path_buf; // safe coercion

    while (true) {
        var dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true });
        defer dir.close();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            if (std.mem.eql(u8, entry.name, target)) {
                return dir_path; // Ownership passed to caller
            }
        }

        const parent = std.fs.path.dirname(dir_path) orelse {
            //allocator.free(dir_path_buf);
            return error.NotFound;
        };

        if (std.mem.eql(u8, dir_path, parent)) {
            //allocator.free(dir_path_buf);
            return error.NotFound; // reached root
        }

        // Allocate new path
        const new_path_buf = try allocator.dupeZ(u8, parent);
        //allocator.free(dir_path_buf); // Free old
        dir_path_buf = new_path_buf;  // Replace with new
        dir_path = dir_path_buf;
    }
} 



