const std = @import("std");
const log = @import("log.zig");
const utils = @import("utils.zig");

const Flag = struct {
    long: []const u8,
};

const FLAGS_MAP = std.ComptimeStringMap(ArgKind, .{
    .{ "-stack", .{ .mode = .stack } },
    .{ "-phi", .{ .mode = .phi } },
    .{ "-opt", .{ .mode = .opt } },
    .{ "-dot", .dotfile },
    .{ "-o", .outfile },
    .{ "-out", .outfile },
    .{ "-i", .infile },
    .{ "-in", .infile },
    .{ "-input", .infile },
});

const MAX_FILE_SIZE: usize = 2 << 30; // 2 GB

const ArgKind = union(enum) {
    mode: Args.Mode,
    dotfile,
    outfile,
    infile,
};

const Args = struct {
    mode: Mode,
    dotfile: ?[]const u8,
    outfile: []const u8,
    infile: []const u8,

    pub const DEFAULT = Args{
        .mode = Mode.stack,
        .dotfile = null,
        .outfile = "",
        .infile = "",
    };

    pub const Mode = enum {
        stack,
        phi,
        opt,
    };
};

fn parse_args() !Args {
    var args: Args = Args.DEFAULT;
    var argsIter = std.process.args();
    // skip program name
    _ = argsIter.skip();
    while (argsIter.next()) |arg| {
        const argDef = blk: {
            const argDef = FLAGS_MAP.get(arg);
            if (argDef) |nnarg| {
                break :blk nnarg;
            }
            log.err("Unrecognized flag: {s}\n", .{arg});
            return error.UnrecognizedFlag;
        };

        switch (argDef) {
            .mode => |mode| {
                // NOTE: this causes subsequent flags to overwrite
                // previous ones
                args.mode = mode;
            },
            .outfile => {
                const outfile = argsIter.next() orelse {
                    log.err("Expected an argument after {s}\n", .{arg});
                    return error.ExpectedArg;
                };
                args.outfile = outfile;
            },
            .infile => {
                const infile = argsIter.next() orelse {
                    log.err("Expected an argument after {s}\n", .{arg});
                    return error.ExpectedArg;
                };
                args.infile = infile;
            },
            .dotfile => {
                const dotfile = argsIter.next() orelse {
                    log.err("Expected an argument after {s}\n", .{arg});
                    return error.ExpectedArg;
                };
                args.dotfile = dotfile;
            },
        }
    }
    if (args.infile.len == 0) {
        log.err("No input file provided\n", .{});
        return error.NoInputFile;
    }
    return args;
}

pub fn main() !void {
    errdefer log.print();
    const args = try parse_args();
    log.trace("{s} {s} -> {s}\n", .{ @tagName(args.mode), args.infile, args.outfile });
    try run(args.mode, args.infile, args.outfile, args.dotfile);
}

pub fn run(mode: Args.Mode, infilePath: []const u8, outfilePath: []const u8, dotfilePath: ?[]const u8) !void {
    const alloc = std.heap.page_allocator;

    var backendArena = std.heap.ArenaAllocator.init(alloc);
    defer backendArena.deinit();
    var backendAlloc = backendArena.allocator();

    // run the frontend;
    const ir = ir: {
        var frontendArena = std.heap.ArenaAllocator.init(alloc);
        defer frontendArena.deinit();
        var frontendAlloc = frontendArena.allocator();

        const ast = ast: {
            const input = try std.fs.cwd().readFileAlloc(frontendAlloc, infilePath, MAX_FILE_SIZE);

            const tokens = try @import("lexer.zig").Lexer.tokenizeFromStr(input, frontendAlloc);
            const parser = try @import("parser.zig").Parser.parseTokens(tokens, input, frontendAlloc);
            const ast = try @import("ast.zig").initFromParser(parser);
            try @import("sema.zig").ensureSemanticallyValid(&ast);

            break :ast ast;
        };

        switch (mode) {
            .stack => {
                const ir = try @import("ir/stack.zig").generate(backendAlloc, &ast);
                break :ir try ir.stringify_cfg(backendAlloc, .{
                    .header = true,
                });
            },
            .phi => {
                const phi = try @import("ir/phi.zig").generate(backendAlloc, &ast);
                break :ir try phi.stringify_cfg(backendAlloc, .{
                    .header = true,
                });
            },
            // TODO: should probably break sooner than this instead
            // of blue-balling the user
            .opt => utils.todo("Optimization", .{}),
        }
    };

    if (outfilePath.len == 0) {
        var writer = std.io.getStdOut().writer();
        _ = try writer.write(ir);
    } else {
        try std.fs.cwd().writeFile(outfilePath, ir);
        // TODO: run clang if user asks for it
    }

    if (dotfilePath) |path| {
        log.info("Writing dot to {s}\n", .{path});
        const dot_str = try @import("dot.zig").generate(backendAlloc, ir);
        try std.fs.cwd().writeFile(path, dot_str);
    }
}
