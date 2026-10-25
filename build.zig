const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const spirv = b.addModule("spirv", .{
        .root_source_file = b.path("src/spirv/root.zig"),
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "jzspv-dis",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/disasm.zig"),

            .target = target,
            .optimize = optimize,
        }),
    });

    exe.root_module.addImport("spirv", spirv);

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    run_cmd.addPassthruArgs();
}
