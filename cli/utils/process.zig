// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

const std = @import("std");

const allocator = std.heap.page_allocator;
const process   = std.process.Child;

// Spawn a subprocess
pub fn run(args: []const [:0]const u8) !void {
    var child = process.init(args, allocator);

    child.stdin_behavior  = .Inherit;
    child.stdout_behavior = .Inherit;
    child.stderr_behavior = .Inherit;

    try child.spawn();
    _ = try child.wait(); // returns exit status
}
