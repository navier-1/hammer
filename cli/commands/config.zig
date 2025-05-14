// Deve controllare se esiste già un CML.txt; se esiste usa quello

// Se non esiste, controlla se esiste la cartella .config; se non c'è warna di errore ed esce

// Se c'è config, usa il CML.txt del back-end
const std = @import("std");

const process = @import("../utils/process.zig");
const parsing = @import("../utils/parsing.zig");
const configuration = @import("../configuration.zig");
const transpile = @import("../utils/transpile.zig");
const search = @import("../utils/search-filesystem.zig");

const run = process.run;
const checkFlag = parsing.checkFlag;
const revSearch = search.revSearch;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = gpa.allocator();

const ConfigParams = struct {
    build_dir: [:0]const u8,
    build_system: [:0]const u8,
    cml_dir: [:0]const u8,
    project_dir: [:0]const u8,
    //config_program: [:0]const u8, // Would probably be better placed in configuration.zig
};

fn config(args: [][:0]u8) anyerror!ConfigParams {
    const cwd = std.fs.cwd();

    // Setup default configuration vars
    var build_dir: [:0]const u8 = "./build";
    var build_system: [:0]const u8 = "Ninja";
    var cml_dir: [:0]const u8 = configuration.InstallDir;

    // CMakeLists.txt may or may not exist in the project dir - check
    // TODO: Perform a revParse on this, too? So even traditional projects can be built from within the repository.
    var cml: ?std.fs.File = null;
    cml = cwd.openFile("CMakeLists.txt", .{}) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };

    var project_dir: [:0]const u8 = undefined;

    // TODO: probably can omit the cml variable entirely, and place the openDir() call here.
    if (cml) |_| {
        cml_dir = ".";
        cml.?.close();

        project_dir = try allocator.dupeZ(u8, cml_dir);
    } else {
        // Reverse search from pwd for the configuration directory
        
        // TODO: read the configuration dir from (heh) configuration, or set in build script.
        const target: [:0]const u8 = ".configure";
        project_dir = revSearch(allocator, target) catch |err| switch (err) {
            error.NotFound => {
                try std.io.getStdOut().writer().print("Failed to locate configuration directory '{s}'.\nTry going to the top level and run:\nhammer init\n.", .{target});
                std.process.exit(0);
            },
            else => return err,
        }; // This dynamically allocated string will be released at the very end, after configuration.

        // --- Create compilation dir ---
        const reserved_dir_path = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{project_dir, ".configure/.reserved"});

        if (cwd.access(reserved_dir_path, .{})) |_| {
            try cwd.deleteTree(reserved_dir_path);
        } else |err| switch (err) {
            error.FileNotFound => {},
            else => return err,
        }

        try cwd.makePath(reserved_dir_path);

        // Add the located dir to the args for the C module
        const transpile_args_len = 2 + args.len;
        var transpile_args = try allocator.alloc([:0]u8, transpile_args_len);
        defer allocator.free(transpile_args);

        transpile_args[0] = try allocator.dupeZ(u8, "--config");
        transpile_args[1] = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{project_dir, ".configure"});

        for (args, 0..args.len) |arg, i| {
            transpile_args[2 + i] = arg;
        }


        // Calls the C code that loads the yaml configuration files and generates cmake files for the back-end.
        try transpile.transpileConf(transpile_args);
    }

    if (args.len > 0) {
        if (args[0][0] != '-') // should be a valid name
            build_dir = args[0];

        build_system = checkFlag("-G", args) orelse build_system;
        cml_dir = checkFlag("-S", args) orelse cml_dir;
    }

    const conf: ConfigParams = .{
        .build_dir = build_dir,
        .build_system = build_system,
        .cml_dir = cml_dir,
        .project_dir = project_dir,
    };

    // TODO: add the equivalent code to omit this if compiling with no memory freeing.
    // config_flag.free(transpile_args[0]);

    // Note: this returns a copy of the struct to the caller
    return conf;
}

fn buildCommand(list: *std.ArrayList([:0]const u8), conf: *const ConfigParams, args: []const [:0]u8) !void {
    const set_project_dir = try std.fmt.allocPrintZ(allocator, "-DPROJECT_DIR={s}", .{conf.project_dir});
    try list.append(set_project_dir);

    try list.append("-B");

    // TODO: Q: will this fuck me up on Windows? A: 100%
    const build_dir = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{conf.project_dir, "build"});
    try list.append(build_dir);
    //try list.append(conf.build_dir);

    try list.append("-G");
    try list.append(conf.build_system);
    try list.append("-S");
    try list.append(conf.cml_dir);


    // Append any further args for CMake
    for (args) |arg| {
        try list.append(arg);
    }
}

pub fn hConfig(args: [][:0]u8) anyerror!void {

    // TODO: this should modify args in some way, and remove the consumed args (e.g. -G "Ninja"),
    // or they'll be passed twice
    const conf = try config(args);

    var build_args = std.ArrayList([:0]const u8).init(allocator);
    defer build_args.deinit();

    // TODO: make the GUI/TUI program configurable
    try build_args.append("ccmake");
    try build_args.append("-DINTERACTIVE=ON");
    try buildCommand(&build_args, &conf, args);

    const arglist = try build_args.toOwnedSlice();
    try run(arglist);

    allocator.free(conf.project_dir); // This free might be causing problems
}

pub fn hAutoConfig(args: [][:0]u8) anyerror!void {
    const conf = try config(args);

    var build_args = std.ArrayList([:0]const u8).init(allocator);
    defer build_args.deinit();

    try build_args.append("cmake");
    try build_args.append("-DPRECONFIG_DONE=ON");
    try build_args.append("-DINTERACTIVE=OFF");
    try buildCommand(&build_args, &conf, args);
    try build_args.append("--no-warn-unused-cli");

    const arglist = try build_args.toOwnedSlice();
    try run(arglist);

    //allocator.free(conf.project_dir);
}
