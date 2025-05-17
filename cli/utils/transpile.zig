// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.


/// This module provides calls the C code that performs transpilation from the Yaml project configuration files to CMake.
const std = @import("std");


// C function
extern fn transpileAllConfig(argc: c_int, argv: [*c][*c]u8) c_int;


/// Transpiles all the yaml configuration files into CMake
pub fn transpileConf(args: [][:0]u8) anyerror!void {

    // C-comprehensible allocator
    var allocator = std.heap.page_allocator;


    // Allocate space for the argv array (array of pointers)
    const argv: [][*c]u8 = try allocator.alloc([*c]u8, args.len);
    defer allocator.free(argv);

    for (args, 0..) |arg, i| {
        argv[i] = @ptrCast(arg.ptr);
    }

    const err = transpileAllConfig(@intCast(args.len), argv.ptr);
    if (err != 0) {
        std.process.exit(1); // The error messages are printed by the C module
    }
}
