/// This module provides calls the C code that performs transpilation from the Yaml project configuration files to CMake.
const std = @import("std");

const arr = [3]u8{1,2,3};

// const p: [*:0]const u8 = &arr;
const p: []const u8 = &arr;

// C function using CYAML library
extern fn transpileAllConfig(argc: usize, argv: [*][*:0]const u8) c_int;

// This transpiles all the configuration files from Yaml to CMake
pub fn transpileConf(args: [][:0]u8) anyerror!void {


    // const cwd = std.fs.cwd();
    // var config_dir = try cwd.openDir(".configure", .{}); // This should exist if this function is being called
    // defer config_dir.close();

    // try config_dir.makePath(".reserved"); // TODO: figure out how to make this the same as the C module's without hardcoding.
    // var target_dir = config_dir.openDir(".reserved", .{});
    // defer target_dir.close();

    // Convert [][:0]u8 to [*][*:0]const u8
    const c_argv: [*][*:0]const u8 = @ptrCast(args.ptr);

    const argc: usize = args.len;
    const err = transpileAllConfig(argc, c_argv);
    if (err != 0) {
        return; // add error to pass
    }
}
