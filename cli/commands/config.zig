// Deve controllare se esiste già un CML.txt; se esiste usa quello

// Se non esiste, controlla se esiste la cartella .config; se non c'è warna di errore ed esce

// Se c'è config, usa il CML.txt del back-end
const std = @import("std");

const process = @import("../utils/process.zig");
const parsing = @import("../utils/parsing.zig");
const configuration = @import("../configuration.zig");
const transpile = @import("../utils/transpile.zig");

const run = process.run;
const checkFlag = parsing.checkFlag;

const ConfigParams = struct {
    build_dir: [:0]const u8,
    build_system: [:0]const u8,
    cml_dir: [:0]const u8,
    //config_program: [:0]const u8,
};

fn config(args: [][:0]u8) anyerror!ConfigParams {
    const cwd = std.fs.cwd();

    // Setup default configuration vars
    var build_dir: [:0]const u8 = "./build";
    var build_system: [:0]const u8 = "\"Ninja\"";
    var cml_dir: [:0]const u8 = configuration.InstallDir;

    // CMakeLists.txt may or may not exist in the project dir - check
    var cml: ?std.fs.File = null;
    cml = cwd.openFile("CMakeLists.txt", .{}) catch |err| switch (err) {
        error.FileNotFound => null,
        else => return err,
    };

    // TODO: probably can omit the cml variable entirely, and place the openDir() call here.
    if (cml) |_| {
        cml_dir = ".";
        cml.?.close();
    } else {
        // implying there has to be the hammer .configure/ directory; TODO: handle error if missing
        var config_dir = cwd.openDir(".configure", .{}) catch {
            try std.io.getStdOut().writer().print("Failed to open the configuration folder. Try running:\n  hammer init\n", .{});
            std.process.exit(1);
        };
        defer config_dir.close();

        const reserved_dir: ?std.fs.Dir = cwd.openDir(".configure/.reserved", .{}) catch |err| switch (err) {
            error.FileNotFound => null,
            else => return err,
        };

        // Same as above
        if (reserved_dir) |_| {
            try cwd.deleteTree(".configure/.reserved");
        }

        try cwd.makePath(".configure/.reserved");

        // Calls the C code that compiles the cmake files for the back-end from the yaml configuration
        try transpile.transpileConf(args);
    }

    if (args.len > 0) {
        // build_dir = checkFlag("-B", args) orelse build_dir;
        if (args[0][0] != '-') // should be a valid name
            build_dir = args[0];

        build_system = checkFlag("-G", args) orelse build_system;
        cml_dir = checkFlag("-S", args) orelse cml_dir;
    }

    const conf: ConfigParams = .{
        .build_dir = build_dir,
        .build_system = build_system,
        .cml_dir = cml_dir,
    };

    // Note: this returns a copy of the struct to the caller
    return conf;
}

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
var gpallocator = gpa.allocator();
fn buildCommand(allocator: std.mem.Allocator, conf: *const ConfigParams, args: []const [:0]u8) ![][:0]const u8 {
    var list = std.ArrayList([:0]const u8).init(allocator);
    try list.append("ccmake");
    try list.append("-B");
    try list.append(conf.build_dir);
    try list.append("-G");
    try list.append(conf.build_system);
    try list.append("-S");
    try list.append(conf.cml_dir);

    // Note: no, only the hConfig() call defines this
    try list.append("-DINTERACTIVE=ON");

    // Append all strings from args
    for (args) |arg| {
        try list.append(arg);
    }

    return try list.toOwnedSlice();
}

pub fn hConfig(args: [][:0]u8) anyerror!void {
    const conf = try config(args);

    const build_args = try buildCommand(gpallocator, &conf, args);
    try run(build_args);
    gpallocator.free(build_args);
}

pub fn hAutoConfig(args: [][:0]u8) anyerror!void {
    const conf = try config(args);

    try run(&.{ "cmake", "-B", conf.build_dir, "-G", conf.build_system, "-S", conf.cml_dir, "-DPRECONFIG_DONE=ON" });
}
