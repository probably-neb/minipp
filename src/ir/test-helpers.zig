const std = @import("std");
const log = @import("../log.zig");

/// A union of different ways to pass LLVM code to `expectLLVMOutput`
pub const LLVMCode = union(enum) {
    /// a single string containing the LLVM code
    /// i.e. the output of `ir.stringify()`
    str: []const u8,
    /// a path to the LLVM file.
    /// WARN: Will be based on the cwd of the user when the test is run
    /// so make sure you are in the right directory when you run `zig test`
    file_path: []const u8,
    /// an array of lines, each line being a string
    /// NOTE: this is a wee bit tricky to get initialized in zig,
    /// but can be nicer than having the `\\` string literals
    /// especially when you want to comment individual lines
    /// to make one of these in zig, you can do
    ///
    /// ```zig
    /// const lines = LLVMCode{
    ///    .lines = &[_][]const u8{
    ///        "define i32 @main() {",
    ///        "  ret i32",
    ///        "}",
    /// };
    /// ```
    lines: []const []const u8,
};

/// Compiles the given LLVM code and runs it with the given input (if not null).
/// Then checks the output against the passeed expected output using
/// `std.testing.expectEqualStrings`
/// If the test fails, the input, output, and expected output are saved to files in `/tmp/minipp/{random name}`
/// Note however that if the writes to the input,output, etc files fail,
/// they will print to log.err that they failed but not return an error
/// (so they don't overwrite the error from the test case failing)
/// again, slap a `errdefer log.print()` somewhere to see if they are failing
///
/// The tmp dir is deleted at the end of the test if the test succeeded
/// If the test fails, the tmp dir is not deleted so you can inspect the files
/// NOTE: to see what tmp dir was used, slap a `defer log.print()` somewhere
/// as all of the prints are done using `log.{trace|err}`
///
/// The LLVM code can be passed in in multiple ways, see `LLVMCode`
/// for details
pub fn expectLLVMOutput(alloc: std.mem.Allocator, code: LLVMCode, inputs: ?[]const u8, expected_output: []const u8) !void {

    // path holds the parent tmp dir path
    // we copy it into other buffers also of MAX_PATH_BYTES len
    // so we can use it to build up paths
    // we also use it to delete the tmp dir at the end,
    // and to store the .ll file path
    // to avoid another copy, stack array, etc
    var path: [std.fs.MAX_PATH_BYTES]u8 = undefined;

    // mktmp will set this to the length of the path it creates
    // this is used to append filenames to the path
    // in our copies of path that correspond to
    // input, output, bin, etc
    var tmp_dir_len: usize = 0;
    var tmpdir = try mktmp(&path, &tmp_dir_len);
    // close error even if we fail because of an error
    errdefer tmpdir.close();

    path[tmp_dir_len] = '/';
    tmp_dir_len += 1;
    // a slice of everything in path after the tmp dir
    // i.e. writing "foo" to [0..3] of file_path
    // will result in path being `/tmp/minipp/{random name}/foo`
    var file_path = path[tmp_dir_len..];
    const out_ll = "out.ll";
    log.trace("input path={s}\n", .{path[0..tmp_dir_len]});

    switch (code) {
        .str => |str| {
            file_path = file_path[0..out_ll.len];
            @memcpy(file_path, out_ll);
            const ll_tmp = try tmpdir.createFile(file_path, .{ .truncate = true });
            defer ll_tmp.close();
            _ = try ll_tmp.write(str);
        },
        .file_path => |fp| {
            file_path = file_path[0..fp.len];
            @memcpy(file_path, fp);
        },
        .lines => |lines| {
            file_path = file_path[0..out_ll.len];
            @memcpy(file_path, out_ll);

            const ll_tmp = try tmpdir.createFile(file_path, .{ .truncate = true });
            defer ll_tmp.close();
            for (lines) |line| {
                _ = try ll_tmp.write(line);
                _ = try ll_tmp.write("\n");
            }
        },
    }

    // the slice of path containing the tmp dir and the out.ll file
    // name at the end
    // i.e. the absolute path to the input llvm ir file
    const ll_path = path[0 .. tmp_dir_len + file_path.len];

    // get index of last `.` in path (i.e. right before .ll)
    // so that we can copy the ll path into other buffers,
    // and overwrite the .ll with a different extension
    // while maintining the path + file stem
    const dot_i = std.mem.lastIndexOfScalar(u8, ll_path, '.') orelse unreachable;

    errdefer {
        // write input to file on error
        if (inputs) |input_contents| {
            const inpath = inpath: {
                var inpath: [std.fs.MAX_PATH_BYTES]u8 = undefined;
                @memcpy(inpath[0..ll_path.len], ll_path);
                const dot_input = ".input";
                @memcpy(inpath[dot_i..][0..dot_input.len], dot_input);

                break :inpath inpath[0 .. dot_i + dot_input.len];
            };
            std.fs.cwd().writeFile(inpath, input_contents) catch {
                log.err("failed to write input file: {s}\n", .{inpath});
            };
        }
    }

    errdefer {
        // write expected output to file on error
        const expected = expected: {
            var expected: [std.fs.MAX_PATH_BYTES]u8 = undefined;
            @memcpy(expected[0..ll_path.len], ll_path);
            const dot_expected = ".expected";
            @memcpy(expected[dot_i..][0..dot_expected.len], dot_expected);
            break :expected expected[0 .. dot_i + dot_expected.len];
        };
        std.fs.cwd().writeFile(expected, expected_output) catch {
            log.err("failed to write expected output file: {s}\n", .{expected});
        };
    }

    const binpath = binpath: {
        var binpath: [std.fs.MAX_PATH_BYTES]u8 = undefined;
        @memcpy(binpath[0..ll_path.len], ll_path);
        break :binpath binpath[0..dot_i];
    };

    // run da clang
    {
        const argv = [_][]const u8{
            "clang",
            ll_path,
            "-o",
            binpath,
        };
        log.trace("{s} {s} {s} {s}\n", .{ argv[0], argv[1], argv[2], argv[3] });
        var clang = std.process.Child.init(&argv, alloc);
        const res = try clang.spawnAndWait();
        switch (res) {
            .Exited => |status| {
                if (status != 0) {
                    return error.AhShitHereWeGoAgain;
                }
            },
            else => |err| {
                log.err("{any}\n", .{err});
                return error.AhShitHereWeGoAgain;
            },
        }
    }

    var stdout_buf = std.ArrayList(u8).init(alloc);
    defer stdout_buf.deinit();
    // run da bin
    const output = output: {
        log.trace("RUNNING {s}\n", .{binpath});

        var bin = std.process.Child.init(&[_][]const u8{binpath}, alloc);
        // setting these to .Pipe will cause `.spawn()`
        // to create pipes for the childs stdin, stdout, stderr
        bin.stdout_behavior = .Pipe;
        bin.stderr_behavior = .Pipe;
        bin.stdin_behavior = .Pipe;

        var stderr_buf = std.ArrayList(u8).init(alloc);
        // we won't use this
        defer stderr_buf.deinit();

        try bin.spawn();

        // if inputs, write them now so the infile gets them,
        // then immediately close the file so the bin does not hang
        if (inputs) |input_contents| {
            log.trace("sending input:\n{s}\n", .{input_contents});
            _ = try bin.stdin.?.write(input_contents);
            // WARN: IMPORTANT if you don't send a null byte scanf will hang
            _ = try bin.stdin.?.write(&[_]u8{0});
        }
        // infile_w.close();

        try bin.collectOutput(&stdout_buf, &stderr_buf, 50 * 1024);
        const term = try bin.wait();

        switch (term) {
            .Exited => |status| {
                if (status != 0) {
                    log.err("stdout:\n{s}\n", .{stdout_buf.items});
                    log.err("stderr:\n{s}\n", .{stderr_buf.items});
                    log.err("status: {d}\n", .{status});
                    return error.AhShitHereWeGoAgain;
                }
            },
            else => |err| {
                log.err("{any}\n", .{err});
                return error.AhShitHereWeGoAgain;
            },
        }
        break :output stdout_buf.items;
    };

    errdefer {
        // save output to file on error (i.e. failed the test)
        const outpath = outpath: {
            var outpath: [std.fs.MAX_PATH_BYTES]u8 = undefined;

            @memcpy(outpath[0..ll_path.len], ll_path);
            const dot_output = ".output";
            @memcpy(outpath[dot_i..][0..dot_output.len], dot_output);
            break :outpath outpath[0 .. dot_i + dot_output.len];
        };
        std.fs.cwd().writeFile(outpath, output) catch {
            log.err("failed to save output to output file: {s}\n", .{outpath});
        };
    }

    errdefer {
        const tmpdir_path = path[0..tmp_dir_len];
        log.trace("output:\n{s}\n", .{output});
        log.trace("tmpdir path={s}\n", .{tmpdir_path});
    }

    try std.testing.expectEqualStrings(
        expected_output,
        output,
    );

    // cleanup tmp dir if we succeeded

    // close before we delete it
    const tmpdir_path = path[0..tmp_dir_len];
    tmpdir.close();
    try std.fs.cwd().deleteTree(tmpdir_path);
}

/// Create a temporary directory in /tmp/minipp/{random name}
/// Random name is generated from the current time in milliseconds
/// /tmp/minipp is created if it does not exist
/// expects buf to be a [std.fs.MAX_PATH_BYTES]u8
/// writes the path of the tmp dir created to buf
/// sets path_len to the length of the path
/// and retuns the opened Dir object
fn mktmp(buf: []u8, path_len: *usize) !std.fs.Dir {
    const slash_tmp = "/tmp/";
    @memcpy(buf[0..slash_tmp.len], slash_tmp);
    const slash_minipp = "minipp/";
    @memcpy(buf[slash_tmp.len .. slash_tmp.len + slash_minipp.len], slash_minipp);
    const minipp_dir_path = buf[0 .. slash_tmp.len + slash_minipp.len];

    var minipp_dir = std.fs.openDirAbsolute(minipp_dir_path, .{}) catch |err| err: {
        switch (err) {
            error.FileNotFound => {
                // create if it does not exist
                break :err try std.fs.cwd().makeOpenPath(minipp_dir_path, .{});
            },
            else => return err,
        }
    };
    defer minipp_dir.close();

    var minipp_tmp_dir_path = buf[slash_tmp.len + slash_minipp.len ..];
    var random = std.rand.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    const rand_int = random.next();
    _ = rand_int;
    const rand_int_buf = std.fmt.bufPrintIntToSlice(minipp_tmp_dir_path, random.next(), 10, .upper, .{});
    const dir_path = minipp_tmp_dir_path[0..rand_int_buf.len];
    const dir = try minipp_dir.makeOpenPath(dir_path, .{});
    path_len.* = slash_tmp.len + slash_minipp.len + dir_path.len;
    return dir;
}

/// @param name The name we use everywhere else to refer to test suite tests (i.e. bert, Fibonacci, etc)
/// @param ext The extension of the file to embed - defaults to `mini`
pub fn embedTestSuiteFile(comptime name: []const u8, comptime ext_opt: ?[]const u8) []const u8 {
    comptime {
        const ext = ext_opt orelse ".mini";
        const path = "../../test-suite/tests/milestone2/benchmarks/" ++ name ++ "/" ++ name ++ "." ++ ext;
        return @embedFile(path);
    }
}

const Arena = struct {
    alloc: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    pub fn new(alloc: std.mem.Allocator) Arena {
        var arena = std.heap.ArenaAllocator.init(alloc);
        return Arena{ .alloc = arena.allocator(), .arena = arena };
    }

    pub fn deinit(self: *Arena) void {
        self.arena.deinit();
    }
};

pub fn compile_stack(parentAlloc: std.mem.Allocator, code: []const u8) !@import("ir.zig").IR {
    var frontendArena = std.heap.ArenaAllocator.init(parentAlloc);
    defer frontendArena.deinit();
    var alloc = frontendArena.allocator();

    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(code, alloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, code, alloc);
    const ast = try @import("../ast.zig").initFromParser(parser);
    const ir = try @import("stack.zig").generate(parentAlloc, &ast);
    return ir;
}

pub fn compile_phi(parentAlloc: std.mem.Allocator, code: []const u8) !@import("ir_phi.zig").IR {
    var frontendArena = std.heap.ArenaAllocator.init(parentAlloc);
    defer frontendArena.deinit();
    var alloc = frontendArena.allocator();

    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(code, alloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, code, alloc);
    const ast = try @import("../ast.zig").initFromParser(parser);
    const ir = try @import("phi.zig").generate(parentAlloc, &ast);
    return ir;
}

test "stack" {
    log.empty();
    errdefer log.printWithPrefix(@typeName(@This()));

    const mini =
        \\fun main() int {
        \\  int in;
        \\  in = read;
        \\  print in endl;
        \\  return 0;
        \\}
    ;
    const ir = try compile_stack(std.heap.page_allocator, mini);
    const llvm = try ir.stringify_cfg(std.heap.page_allocator, .{ .header = true });
    try expectLLVMOutput(std.heap.page_allocator, .{ .str = llvm }, "1", "1\n");
}
