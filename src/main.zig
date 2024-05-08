const std = @import("std");
const log = @import("log.zig");
const utils = @import("utils.zig");

const Flag = struct {
    long: []const u8,
};

const FLAGS_MAP = std.ComptimeStringMap(Args.Mode, .{
    .{ "-stack", Args.Mode.stack },
    .{ "-ssa", Args.Mode.ssa },
    .{ "-opt", Args.Mode.opt },
    .{ "-dot", Args.Mode.dot },
    .{ "-o", Args.Mode.outfile },
    .{ "-out", Args.Mode.outfile },
});

const MAX_FILE_SIZE: usize = 10 << 30; // 10 GB

const ArgKind = union(enum) {
    mode: Args.Mode,
    outfile: []const u8,
    infile: []const u8,
};

const Args = struct {
    mode: Mode,
    outfile: []const u8,
    infile: []const u8,

    pub const Mode = enum {
        stack,
        ssa,
        opt,
        dot,
    };
};

const DEFAULT_ARGS = Args{
    .mode = Args.Mode.stack,
    .outfile = "out.ll",
    .infile = "",
};

fn parse_args() !Args {
    var args: Args = undefined;
    const argsIter = std.process.args();
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
            .outfile => |outfile| {
                args.outfile = outfile;
            },
            .infile => |infile| {
                args.infile = infile;
            },
        }
    }
    if (args.infile.len == 0) {
        log.err("No input file provided\n");
        return error.NoInputFile;
    }
    return args;
}

pub fn main() !void {
    const args = try parse_args();
    _ = args;
}

pub fn run(mode: Args.Mode, infilePath: []const u8, outfilePath: []const u8) !void {
    errdefer log.print();

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
            const ast = @import("ast.zig").initFromParser(parser);
            try @import("sema.zig").typeCheck(ast);

            break :ast ast;
        };

        switch (mode) {
            .stack => {
                const ir = try @import("ir/stack.zig").generate(backendAlloc, &ast);
                break :ir try ir.stringify(backendAlloc);
            },
            .dot => utils.todo("Dot generation", .{}),
            // TODO: should probably break sooner than this instead
            // of blue-balling the user
            .ssa => utils.todo("SSA IR generation", .{}),
            .opt => utils.todo("Optimization", .{}),
        }
    };

    try std.fs.cwd().writeFile(outfilePath, ir);

    // TODO: run clang if user asks for it
}
