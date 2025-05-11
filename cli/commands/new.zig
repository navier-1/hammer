const std = @import("std");
const init = @import("init.zig");
const configuration = @import("../configuration.zig");


pub fn hNew(args: [][:0]u8) anyerror!void {
    if (args.len == 0) {
        try std.io.getStdOut().writer().print("Usage: hammer new <PROJECT_NAME>\n", .{});
        return;
    }

    const cwd = std.fs.cwd();

    // TODO: perform some input sanitizing
    const path = args[0];

    if (cwd.openDir(path, .{})) |_| {
        std.debug.print("[Error] Directory already exists: {s}\n", .{path});
    } else |err| {
        if (err == error.FileNotFound) {
            try cwd.makePath(path);
            std.debug.print("Created project directory: {s}\n", .{path});
        } else {
            return err;
        }
    }

    var new_dir = try cwd.openDir(args[0], .{});
    defer new_dir.close();

    // Initialize repo with configuration files
    try init.hInit(args);

    try setupTemplate(new_dir);
    
    return;
}


fn setupTemplate(new_dir: std.fs.Dir) anyerror!void {
    const cwd = std.fs.cwd();

    var install_dir = try cwd.openDir(configuration.InstallDir, .{});
    defer install_dir.close();

    var config_dir  = try install_dir.openDir("project_config", .{});
    defer config_dir.close();

    var original_main = try config_dir.openFile("sample_main.c", .{});
    defer original_main.close();

    // src/
    try new_dir.makePath("src");

    var src_dir = try new_dir.openDir("src", .{});
    defer src_dir.close();

    var main = try src_dir.createFile("main.c", .{});
    defer main.close();

    const main_size = try original_main.getEndPos();
    _ = try original_main.copyRange(0, main, 0, main_size);

    // include/
    try new_dir.makePath("include");

    return;
}
