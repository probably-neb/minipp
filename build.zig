const std = @import("std");

const SourceFile = struct {
    name: []const u8,
    path: []const u8,
};
const files = [_]SourceFile{
    .{ .path = "src/ast.zig", .name = "ast" },
    .{ .path = "src/lexer.zig", .name = "lexer" },
    .{ .path = "src/parser.zig", .name = "parser" },
    .{ .path = "src/sema.zig", .name = "sema" },
    .{ .path = "src/utils.zig", .name = "utils" },
    .{ .path = "src/ir/ir.zig", .name = "stack-ir" },
    .{ .path = "src/ir/stack.zig", .name = "stack-ir-gen" },
    .{ .path = "src/ir/phi.zig", .name = "phi-ir-gen" },
    .{ .path = "src/ir/ir_phi.zig", .name = "phi-ir" },
    .{ .path = "src/ir/opt.zig", .name = "opt" },
    .{ .path = "src/ir/sccp.zig", .name = "sccp" },
    .{ .path = "src/ir/cmp-info-prop.zig", .name = "cmp-prop" },
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const build_mode = b.standardOptimizeOption(.{});

    // TODO: uncommment for when there is actually a main.zig file
    const exe = b.addExecutable(.{
        .name = "minipp",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = build_mode,
    });
    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run minipp");
    run_step.dependOn(&run_exe.step);

    // create tests for all files and a test step that runs them all
    const test_step = b.step("test", "Run Tests");
    const build_test_step = b.step("test-exe", "Build Tests");
    for (files) |file| {
        const file_tests = b.addTest(.{
            .name = file.name,
            .root_source_file = .{ .path = file.path },
            .target = target,
            .optimize = build_mode,
            .main_pkg_path = .{ .path = "./" },
        });
        const run_test = b.addRunArtifact(file_tests);
        test_step.dependOn(&run_test.step);

        const build_test = b.addInstallArtifact(file_tests, .{
            .dest_dir = .{ .override = .{ .custom = "tests" } },
        });
        build_test_step.dependOn(&build_test.step);
    }
}
