const std = @import("std");
const Alloc = std.mem.Allocator;

const str = []const u8;

const LineIter = std.mem.SplitIterator(u8, .scalar);

pub fn generate(alloc: Alloc, llvm_ir: str) !str {
    var buf = Buf.init(alloc);
    var lines: LineIter = std.mem.splitScalar(u8, llvm_ir, '\n');

    try buf.write("digraph CFG {\n");
    try buf.write("  node [shape=rectangle];\n");
    try buf.write("  labeljust=l;\n");
    try buf.write("  labelloc=t;\n");
    try buf.write("\n");

    while (lines.next()) |line| {
        if (extract_fn_name(line)) |fn_name| {
            try gen_function(&buf, fn_name, &lines);
            continue;
        }
    }

    try buf.write("}\n");

    return buf.get_contents();
}

fn gen_function(buf: *Buf, fn_name: str, lines: *LineIter) !void {
    const indent = "      ";

    try buf.write("  subgraph cluster_");
    try buf.write(fn_name);
    try buf.write(" {\n");
    try buf.write(indent);
    try buf.write("label = \"");
    try buf.write(fn_name);
    try buf.write("\";\n");
    try buf.write("  labeljust=l;\n");

    const MommysLittleHelper = struct {
        fn get_next_label(line_iter: *LineIter) !str {
            const label_line = @This().next_non_empty(line_iter) orelse return error.ExpectedBBLabel;
            return extract_bb_label(label_line) orelse return error.ExpectedBBLabel;
        }
        fn next_non_empty(line_iter: *LineIter) ?str {
            while (line_iter.next()) |line| {
                if (line.len == 0 or std.mem.allEqual(u8, line, ' ')) {
                    continue;
                }
                return line;
            }
            return null;
        }
        fn print_bb_start(b: *Buf, fname: str, label: str) !void {
            try b.write(indent);
            try @This().print_bb_id(b, fname, label);
            try b.write(" [labeljust=l, label=\"");
            try b.write(label);
            try b.write(":\\n");
        }
        fn print_bb_end(b: *Buf) !void {
            try b.write("\"];\n");
        }

        fn print_bb_id(b: *Buf, fname: str, s: str) !void {
            try b.write("\"");
            try b.write(fname);
            try b.write(".");
            try b.write(s);
            try b.write("\"");
        }
    };

    const entry_label = try MommysLittleHelper.get_next_label(lines);
    try MommysLittleHelper.print_bb_start(buf, fn_name, entry_label);

    var cur_bb_label = entry_label;
    var line_no: usize = 0;
    while (MommysLittleHelper.next_non_empty(lines)) |line| : (line_no += 1) {
        const is_end_fn = is_end_fn: {
            const ends_with_squirly = std.mem.endsWith(u8, line, "}");
            const up_to_squirly = std.mem.sliceTo(line, '}');
            const is_space_to_squirly = std.mem.allEqual(u8, up_to_squirly, ' ');
            break :is_end_fn ends_with_squirly and is_space_to_squirly;
        };
        if (is_end_fn) {
            try MommysLittleHelper.print_bb_end(buf);
            try buf.write("  }\n");
            break;
        }
        try buf.write(line);
        try buf.write("\\n");
        if (extract_branch_labels(line)) |bbs| {
            try MommysLittleHelper.print_bb_end(buf);
            const is_cond_branch = bbs[1] != null;
            inline for (bbs, 0..) |maybe_bb, i| {
                if (maybe_bb) |bb| {
                    try buf.write(indent);
                    try MommysLittleHelper.print_bb_id(buf, fn_name, cur_bb_label);
                    try buf.write(" -> ");
                    try MommysLittleHelper.print_bb_id(buf, fn_name, bb);
                    if (is_cond_branch) {
                        try buf.write(" [label=\"");
                        try buf.write(if (i == 0) "then" else "else");
                        try buf.write("\"]");
                    }
                    try buf.write(";\n");
                }
            }

            const next_label = try MommysLittleHelper.get_next_label(lines);
            cur_bb_label = next_label;
            try MommysLittleHelper.print_bb_start(buf, fn_name, next_label);
            continue;
        }
    }
}

fn extract_fn_name(line: str) ?str {
    if (std.mem.lastIndexOf(u8, line, "{") == null) {
        return null;
    }
    const end = std.mem.lastIndexOf(u8, line, "(") orelse return null;
    const start = (std.mem.lastIndexOf(u8, line[0..end], "@") orelse return null) + 1;
    return line[start..end];
}

fn extract_bb_label(line: str) ?str {
    const end = std.mem.lastIndexOf(u8, line, ":") orelse return null;
    return std.mem.trimLeft(u8, line[0..end], " ");
}

// extract bb labels from br instructions
// ex.
//  br i1 %cmp, label %if.then, label %if.else -> ["if.then", "if.else"]
// br label %while.cond -> ["while.cond"]
fn extract_branch_labels(line: str) ?[2]?str {
    var parts = std.mem.splitScalar(u8, line, ' ');
    find_br: while (parts.next()) |part| {
        if (std.mem.eql(u8, "br", part)) {
            break :find_br;
        }
    } else {
        return null;
    }
    var a: str = undefined;
    var b: str = undefined;
    var found_a: bool = false;
    var found_b: bool = false;
    while (parts.next()) |part| {
        if (!std.mem.eql(u8, "label", part)) {
            continue;
        }
        const label: []const u8 = label: {
            const next = parts.next() orelse return null;
            break :label std.mem.trim(u8, next, " %,\n");
        };

        var edge: *str = if (found_a) b: {
            found_b = true;
            break :b &b;
        } else a: {
            found_a = true;
            break :a &a;
        };
        edge.* = label;
        if (found_b) {
            break;
        }
    }
    if (!found_a) {
        return null;
    }
    if (!found_b) {
        return [2]?str{ a, null };
    }
    return [2]?str{ a, b };
}

const Buf = struct {
    str: std.ArrayList(u8),
    alloc: Alloc,

    fn init(alloc: Alloc) Buf {
        return Buf{
            .str = std.ArrayList(u8).init(alloc),
            .alloc = alloc,
        };
    }

    fn write(self: *Buf, bytes: str) !void {
        try self.str.appendSlice(bytes);
    }

    fn fmt(self: *Buf, comptime fmt_str: str, args: anytype) !void {
        const writer = self.str.writer();
        try std.fmt.format(writer, fmt_str, args);
    }

    fn get_contents(self: *Buf) !str {
        return try self.str.toOwnedSlice();
    }
};

///////////
// TESTS //
///////////

fn expectIsNull(got: anytype) !void {
    if (got != null) {
        std.debug.print("Expected null, got: {any}\n", .{got});
        return error.ExpectedNull;
    }
}

test "dot.extract-fn-name" {
    const inputs = .{
        .{ "foo", "define i32 @foo(i32 %a, i32 %b) {\n" },
        .{ "a", "define i32 @a() {\n" },
        .{ "foo_bar", "define %struct.Foo @foo_bar(i32 %a, i32 %b) {\n" },
        .{ "baz3", "define i32 @baz3(i32 %a, i32 %b) {\n" },
        .{ null, "entry:\n" },
        .{ null, "if.then:\n" },
        .{ null, "if.else:\n" },
        .{ null, "if.end:   \n" },
        .{ null, "while.cond:\n" },
        .{ null, "declare i8* @malloc(i32)\n" },
        .{ null, "declare void @free(i8*\n)" },
        .{ null, "declare i32 @printf(i8*, ...\n)" },
        .{ null, "declare i32 @scanf(i8*, ...\n)" },
    };

    inline for (inputs) |in| {
        const want: ?str = in.@"0";
        const input = in.@"1";
        const got: ?str = extract_fn_name(input);
        if (want) |w| {
            try std.testing.expectEqualStrings(w, got orelse return error.GotNull);
        } else {
            try expectIsNull(got);
        }
    }
}

test "dot.extract-bb-label" {
    const inputs = .{
        .{ "entry", "entry:\n" },
        .{ "if.then", "if.then:\n" },
        .{ "if.else", "if.else:\n" },
        .{ "if.end", "if.end:   \n" },
        .{ "while.cond", "while.cond:\n" },
        .{ null, "define i32 @foo(i32 %a, i32 %b) {\n" },
        .{ null, "define i32 @a() {\n" },
    };
    inline for (inputs) |in| {
        const want: ?str = in.@"0";
        const input = in.@"1";
        const got: ?str = extract_bb_label(input);
        if (want) |w| {
            try std.testing.expectEqualStrings(w, got orelse return error.GotNull);
        } else {
            try expectIsNull(got);
        }
    }
}

test "dot.extract-branch-labels" {
    const inputs = .{
        .{ .{ "if.then", "if.else" }, "br i1 %cmp, label %if.then, label %if.else\n" },
        .{ .{ "while.cond", null }, "br label %while.cond\n" },
        .{ .{ "0", "1" }, "br i1 %cmp, label %0 , label %1\n" },
        .{ null, "define i32 @foo(i32 %a, i32 %b) {\n" },
        .{ null, "define i32 @br(i32 %a, i32 %b) {\n" },
        .{ null, "define i32 @a() {\n" },
    };
    inline for (inputs) |in| {
        const maybe_want_pair: ?[2]?str = in.@"0";
        const input = in.@"1";
        const maybe_got_pair: ?[2]?str = extract_branch_labels(input);
        if (maybe_want_pair) |want_pair| {
            const got_pair = maybe_got_pair orelse return error.GotNull;
            inline for (want_pair, got_pair) |want, got| {
                if (want) |w| {
                    const g = got orelse return error.GotNull;
                    try std.testing.expectEqualStrings(w, g);
                } else {
                    try expectIsNull(got);
                }
            }
        } else {
            try expectIsNull(maybe_got_pair);
        }
    }
}
