const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "hammer",
        .root_source_file = b.path("main.zig"),
        .target = b.standardTargetOptions(.{}),
        //.optimize = b.standardReleaseOptions(),
    });

    exe.linkLibC();
    exe.addIncludePath(b.path("utils/"));
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/config.c"), .flags = &.{"-std=c11"} });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/sources.c"), .flags = &.{"-std=c11"} });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/defines.c"), .flags = &.{"-std=c11"} });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/settings.c"), .flags = &.{"-std=c11"} });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/transpile.c"), .flags = &.{"-std=c11"} });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/toolchain.c"), .flags = &.{"-std=c11"} });
    exe.addCSourceFile(.{ .file = b.path("utils/yaml/dependencies.c"), .flags = &.{"-std=c11"} });

    exe.linkSystemLibrary("cyaml");
    exe.linkSystemLibrary("yaml");

    b.installArtifact(exe);
}
