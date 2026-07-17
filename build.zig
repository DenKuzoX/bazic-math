const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // const lib = b.addLibrary(.{
    //     .name = "bazic_math",
    //     .root_module = lib_mod,
    // });
    // b.installArtifact(lib);

    const test_step = b.step("test", "Run library tests");

    const root_tests = b.addTest(.{.root_module = lib_mod});
    const run_root_tests = b.addRunArtifact(root_tests);
    test_step.dependOn(&run_root_tests.step);
}
