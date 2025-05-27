// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.
const std = @import("std");

const process = @import("../utils/process.zig");
const transpile = @import("../utils/transpile.zig");
const configuration = @import("../configuration.zig");
const search = @import("../utils/search-filesystem.zig");

const list_module = @import("../utils/linked-list.zig");
const Node = list_module.Node;
const ListError = list_module.ListError;
const LinkedList = list_module.LinkedList;

const revSearch = search.revSearch;
const stdout = std.io.getStdOut().writer();
const release_memory = configuration.release_memory;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

const ConfigParams = struct {
    build_dir: [:0]const u8,
    build_system: [:0]const u8,
    cml_dir: [:0]const u8,
    project_dir: [:0]const u8,
};

/// Encapsulates the configuration logic which is shared between the config and autoconfig commands.
/// Takes a linked list to the commands, consumes some and adds some of its own.
fn config(args: *LinkedList([:0]const u8)) anyerror!ConfigParams {
    
    // Setup default configuration vars
    var cml_dir: [:0]const u8 = configuration.poor_mans_pwd;                // ditto
    var build_dir: [:0]const u8 = configuration.default_build_dir;          // TODO: why is undefined causing crashes?
    var build_system: [:0]const u8 = configuration.default_build_system;    // ditto

    var project_dir: [:0]const u8 = undefined;
    var is_cmakelists_present: bool = undefined; // TODO: think of something cleaner than this flag

    // Could consider a revParse() on this too, but for a legacy build it might be safer to keep it from the cwd only.
    const cwd = std.fs.cwd();
    if (cwd.access("CMakeLists.txt", .{})) |_| {

        // Check if the default CMakeLists should be ignored
        var idx: usize = undefined;
        var addr: *Node([:0]const u8) = undefined;

        if (args.where(configuration.override_flag, &idx, &addr)) {
            args.removeFromPtr(addr);
            is_cmakelists_present = false;
        } else {
            is_cmakelists_present = true;
        }

    } else |_| {
        is_cmakelists_present = false;
    }

    // Asssign configuration params based on existing CML.txt or on a .configure/ directory
    if (is_cmakelists_present) {        
        project_dir = configuration.poor_mans_pwd; //try allocator.dupeZ(u8, cml_dir);
        build_dir    = args.getNextValue("-B") orelse configuration.default_build_dir;    
    } else { // The configuration is fully up to Hammer

        // Reverse search from pwd for the configuration directory
        project_dir = revSearch(allocator, configuration.configuration_dir) catch |err| switch (err) {
            error.NotFound => {
                try stdout.print("Failed to locate configuration directory '{s}'.\nTry going to the top level and run:\nhammer init\n.", .{configuration.configuration_dir});
                std.process.exit(0);
            },
            else => return err,
        };

        // --- Create compilation dir ---
        try stdout.print("RevParse located this as project directory: {s}\n", .{project_dir});

        // pork-around until we figure out how to do it in Zig; I hate the hardcoding
        // const create_dirs_cmd = [][:0]const u8{"mkdir", "-p", project_dir, "/.reserved"};
        // try process.run(&create_dirs_cmd);
        try cwd.makePath(project_dir);

        const reserved_dir_path = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{project_dir, configuration.reserved_dir});

        if (cwd.access(reserved_dir_path, .{})) |_| {
            cwd.deleteTree(reserved_dir_path) catch {
                try stdout.print("Failed to delete: {s}\n\n", .{reserved_dir_path});
                return error.AccessDenied;
            };
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => return err,
        }

        try cwd.makePath(reserved_dir_path);

        // Add the located dir to the args for the C module
        const transpile_args_len = 2 + args.len;
        var transpile_args = try allocator.alloc([:0]u8, transpile_args_len);

        transpile_args[0] = try allocator.dupeZ(u8, "--config");
        transpile_args[1] = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{project_dir, configuration.configuration_dir});

        // TODO make transpile_args a list too? In any case, should pass the relevant args (and only the relevent ones) to the yaml module.

        // Calls the C code that loads the yaml configuration files and generates cmake files for the back-end.
        try transpile.transpileConf(transpile_args);

        if (release_memory) {
            allocator.free(transpile_args);
            allocator.free(reserved_dir_path);
        }
    }

    if (args.len > 0) {

        // Check if the first arg is a valid build directory name
        const first: [:0]const u8 = try args.read(0);

        if(first.len > 0 and first[0] != '-') { // i.e. not a flag
            build_dir = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{project_dir, first});
        } else {
            build_dir = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{project_dir, configuration.default_build_dir});
        }

    }

    build_system = args.getNextValue("-G") orelse configuration.default_build_system;
    cml_dir =      args.getNextValue("-S") orelse configuration.InstallDir;

    const conf: ConfigParams = .{
        .project_dir = project_dir,

        .build_dir = build_dir,
        .build_system = build_system,
        .cml_dir = cml_dir,
    };

    // Note: this returns a copy of the struct to the caller
    return conf;
}

/// Takes a linked list of strings, consumes some and appends any extra args from the cli
fn buildCommand(list: *LinkedList([:0]const u8), conf: *const ConfigParams, args: []const [:0]u8) !void {

    // Sets a CMake define used by the back-end's CMakeLists.txt
    const set_project_dir = try std.fmt.allocPrintZ(allocator, "-DPROJECT_DIR={s}", .{conf.project_dir});
    try list.append(set_project_dir);

    try list.append("-B");
    try list.append(conf.build_dir);

    try list.append("-G");
    try list.append(conf.build_system);

    try list.append("-S");
    try list.append(conf.cml_dir);

    // TODO: should consider defining a config-time array of flags to look out for; if found, some logic will be
    // performed and the flag will be removed from the args list.

    // Append any further args for CMake
    for (args) |arg| {
        if (!std.mem.eql(u8, arg, "--override")) { // this is what we call a pork-around (TODO: fix this garbage)
            try list.append(arg);
        }
    }
}

/// Takes the cli args and setups the configuration for the back-end
/// It compiles the yaml configuration files, checks for the existence of the appropriate
/// directories, and finally calls the back-end to run configuration.
pub fn hConfig(args: [][:0]u8) anyerror!void {

    var build_args = try LinkedList([:0]const u8).initFromSlice(&allocator, args);

    const conf = try config(&build_args);

    try build_args.prepend(configuration.gui_program);
    //try build_args.append("-DINTERACTIVE=ON");
    for (configuration.default_config_flags) |flag| {
        try build_args.append(flag);
    }

    try buildCommand(&build_args, &conf, args);

    const arglist: [][:0]const u8 = try build_args.toSlice(&allocator);

    try process.run(arglist);

    if (release_memory) {
        allocator.free(conf.project_dir);
        build_args.free();
    }
}

/// Pretty much the same as the hConfig() function; some args are different of course.
pub fn hAutoConfig(args: [][:0]u8) anyerror!void {

    var build_args = try LinkedList([:0]const u8).initFromSlice(&allocator, args);

    const conf = try config(&build_args);

    try build_args.prepend(configuration.backend);
    for (configuration.default_autoconfig_flags) |flag| {
        try build_args.append(flag);
    }

    // try build_args.append("-DPRECONFIG_DONE=ON");
    // try build_args.append("-DINTERACTIVE=OFF");
    // try build_args.append("--no-warn-unused-cli");
    try buildCommand(&build_args, &conf, args);

    const arglist: [][:0]const u8 = try build_args.toSlice(&allocator);

    try process.run(arglist);

    if (release_memory) {
        allocator.free(conf.project_dir);
        build_args.free();
    }
}
