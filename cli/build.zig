const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "hammer",
        .root_source_file = b.path("main.zig"),
        .target = b.standardTargetOptions(.{}),
        //.optimize = b.standardReleaseOptions(),
    });

    const c_flags = [_][]const u8{
        "-std=c11",
        "-static", // embed yaml & cyaml in the binary

        // "-DMEM_FREE", // Optional: free memory, or don't to get more speed
    };

    exe.linkLibC();
    exe.addIncludePath(b.path("utils/"));
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/config.c"), .flags = &c_flags });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/sources.c"), .flags = &c_flags });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/defines.c"), .flags = &c_flags });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/settings.c"), .flags = &c_flags });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/transpile.c"), .flags = &c_flags });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/toolchain.c"), .flags = &c_flags });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/dependencies.c"), .flags = &c_flags });

    exe.linkSystemLibrary("cyaml");
    exe.linkSystemLibrary("yaml");

    b.installArtifact(exe);
}
