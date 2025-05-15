const std = @import("std");
const release_memory = @import("../configuration.zig").release_memory;


/// Searches the filesystem from the cwd upwards, looking for the directory with the
/// configuration files that would make this a Hammer-managed project.
/// This allows configuring and building the project from anywhere within the repo.
pub fn revSearch(allocator: std.mem.Allocator, target: [:0]const u8) anyerror![:0]const u8 {   
    
    const start_dir: []const u8 = try std.fs.cwd().realpathAlloc(allocator, ".");

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
            if(release_memory) { allocator.free(dir_path_buf); allocator.free(start_dir); }
            return error.NotFound;
        };

        if (std.mem.eql(u8, dir_path, parent)) {
            if (release_memory) { allocator.free(dir_path_buf); allocator.free(start_dir);}
            return error.NotFound; // reached root
        }

        // Allocate new path
        const new_path_buf = try allocator.dupeZ(u8, parent);
        if (release_memory) { allocator.free(dir_path_buf); allocator.free(start_dir); } // Free old
        dir_path_buf = new_path_buf;  // Replace with new
        dir_path = dir_path_buf;
    }
} 



