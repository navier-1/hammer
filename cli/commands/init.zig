// Controlla se esiste .config; se non esiste la crea

// Se mancano alcuni dei file .yml che si aspetta, li aggiunge

// Se esiste un CML.txt nella cartella corrente, deve avvertire
// che per usare questa configurazione deve usare
//    $ hammer config --override-cml
const std = @import("std");
const allocator = std.heap.page_allocator;

const configuration = @import("../configuration.zig");
const InstallDir = configuration.InstallDir;
const config_files = configuration.config_files;

// Note to self:
// don't think in terms of raw strings for paths like in C;
// use the std.fs.Dir class and its methods


pub fn hInit(args: [][:0]u8) anyerror!void {

    var target_dir = std.fs.cwd();

    var needs_cleanup = false;
    if (args.len > 0) {
        target_dir = try target_dir.openDir(args[0], .{});
        needs_cleanup = true;
    }

    try target_dir.makePath(".configure");
    try target_dir.makePath(".configure/.reserved"); // The cmake files that are derived from the yaml configuration are placed here

    var init_dir = try target_dir.openDir(".configure", .{});
    defer init_dir.close();

    const cwd = std.fs.cwd();
    const install_dir = try cwd.openDir(InstallDir, .{});
    const config_dir  = try install_dir.openDir("project_config", .{});

    // TODO: rewrite so there is a bit more comptime (all src files are known at comptime)
    for (config_files) |config_file| {
        var src = try config_dir.openFile(config_file, .{});
        defer src.close();
        
        var dst = try init_dir.createFile(config_file, .{});
        defer dst.close();

        const src_size = try src.getEndPos();
        _ = try src.copyRange(0, dst, 0, src_size);
    }

    if (needs_cleanup)
        target_dir.close();

    return;
}
