const std = @import("std");
const IR = @import("./ir.zig");
const utils = @import("../utils.zig");

const Alloc = std.mem.Allocator;

const INDENT = "  ";

// TODO: add option to include decls or not
// to make testing easier, or just filter them out
// when testing
// FIXME: determine if a user defined function named malloc, free, etc
// should be allowed, I vote if llvm allows it we probably should too
// (i.e. llvm allows defining the function and declaring it, possibly with different signatures)
// it would be really annoying to check for the overide when lowering to ir, so I haven't done that
// yet
// in fact, that's worth a second fixme
// FIXME: check for overides when accessing non-user-defined globals
const DECLS =
    \\ declare i8* @malloc(i32)
    \\ declare void @free(i8*)
    \\ declare i32 @printf(i8*, ...)
    \\ declare i32 @scanf(i8*, ...)
    \\ @.println = private unnamed_addr constant [5 x i8] c"%ld\0A\00", align 1
    \\ @.print = private unnamed_addr constant [5 x i8] c"%ld \00", align 1
    \\ @.read = private unnamed_addr constant [4 x i8] c"%ld\00", align 1
    \\ @.read_scratch = common global i32 0, align 4
;

const Buf = struct {
    str: std.ArrayList(u8),
    alloc: Alloc,

    fn init(alloc: Alloc) Buf {
        return Buf{
            .str = std.ArrayList(u8).init(alloc),
            .alloc = alloc,
        };
    }

    fn write(self: *Buf, str: []const u8) !void {
        try self.str.appendSlice(str);
    }

    fn fmt(self: *Buf, comptime fmt_str: []const u8, args: anytype) !void {
        const writer = self.str.writer();
        try std.fmt.format(writer, fmt_str, args);
        // const count = try std.fmt.count(fmt, args);
        // try self.str.ensureUnusedCapacity(@intCast(count));
        // const buf = self.str.unusedCapacitySlice();
        // try std.fmt.bufPrint(buf, fmt, args);
        // // see the docs, writing directly to the internal arraylist buffer does
        // // not update the length
        // self.str.items.len += count;
    }
};

const Rope = struct {
    a: []const u8,
    b: []const u8,
    num: ?i128 = null,
    num_before_b: bool = false,
    is_ptr: bool = false,

    // zig will use this to format the struct
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        _ = try writer.write(self.a);
        if (self.num) |n| {
            if (self.num_before_b) {
                try writer.print("{d}", .{n});
                _ = try writer.write(self.b);
            } else {
                _ = try writer.write(self.b);
                try writer.print("{d}", .{n});
            }
        } else {
            _ = try writer.write(self.b);
        }
        if (self.is_ptr) {
            _ = try writer.write("*");
        }
    }

    fn pair(a: []const u8, b: []const u8) Rope {
        return Rope{ .a = a, .b = b };
    }

    fn just(a: []const u8) Rope {
        return Rope{ .a = a, .b = "" };
    }

    fn just_num(num: anytype) Rope {
        return Rope{ .a = "", .b = "", .num = @intCast(num) };
    }

    fn str_num(a: []const u8, num: anytype) Rope {
        return Rope{ .a = a, .b = "", .num = @intCast(num) };
    }

    fn str_str_num(a: []const u8, b: []const u8, num: anytype) Rope {
        return Rope{ .a = a, .b = b, .num = @intCast(num) };
    }

    fn str_num_str(a: []const u8, num: anytype, b: []const u8) Rope {
        return Rope{ .a = a, .b = b, .num = @intCast(num), .num_before_b = true };
    }

    fn ptr(s: Rope) Rope {
        var r = s;
        r.is_ptr = true;
        return r;
    }

    fn ptr_if(s: Rope, cond: bool) Rope {
        var r = s;
        r.is_ptr = cond;
        return r;
    }

    fn not_ptr(s: Rope) Rope {
        var r = s;
        r.is_ptr = false;
        return r;
    }
};

pub fn stringify(ir: *const IR, alloc: Alloc) ![]const u8 {
    var buf = Buf.init(alloc);

    // TODO: stringify types + globals
    for (ir.funcs.items.items) |*fun| {
        try buf.fmt("define {} @{s}(", .{ stringify_type(ir, fun.returnType), ir.getIdent(fun.name) });
        for (fun.params.items, 0..) |param, i| {
            try buf.fmt("{any} %{s}", .{ stringify_type(ir, param.type), ir.getIdent(param.name) });
            if (i + 1 != fun.params.items.len) {
                try buf.write(", ");
            }
        }
        try buf.write(") {\n");

        var iter = fun.instIter();

        var curBB: IR.BasicBlock.ID = IR.Function.entryBBID;
        try buf.fmt("{}:\n", .{stringify_label(curBB)});

        while (iter.next()) |inst| {
            // handle printing the basic block label
            switch (inst.op) {
                // No result reg
                .Store, .Ret, .Br, .Jmp => {},
                else => {
                    const reg = fun.regs.get(inst.res.i);
                    if (reg.bb != curBB) {
                        curBB = reg.bb;
                        try buf.fmt("{}:\n", .{stringify_label(curBB)});
                    }
                },
            }
            // handle printing the instruction
            try buf.write(INDENT);
            switch (inst.op) {
                // Arithmetic
                // <result> = add <ty> <op1>, <op2>
                // <result> = mul <ty> <op1>, <op2>
                // <result> = sdiv <ty> <op1>, <op2>
                // <result> = sub <ty> <op1>, <op2>
                // Boolean
                // <result> = and <ty> <op1>, <op2>
                // <result> = or <ty> <opi>, <op2>
                // <result> = xor <ty> <opl>, <op2>
                .Binop => {
                    const binop = IR.Inst.Binop.get(inst);
                    const opName = switch (binop.op) {
                        .Add => "add",
                        .Mul => "mul",
                        .Div => "sdiv",
                        .Sub => "sub",
                        .And => "and",
                        .Or => "or",
                        .Xor => "xor",
                    };
                    try buf.fmt("{any} = {s} {any} {any}, {any}", .{
                        stringify_ref(ir, fun, binop.register),
                        opName,
                        stringify_type(ir, binop.returnType),
                        stringify_ref(ir, fun, binop.lhs),
                        stringify_ref(ir, fun, binop.rhs),
                    });
                    // pub const Binop = enum { Add, Mul, Div, Sub, And, Or, Xor };
                },

                // Comparison and Branching
                // <result> = icmp <cond> <ty> <op1>, <op2> ; @.g., <cond> = eq
                .Cmp => {
                    const cmp = IR.Inst.Cmp.get(inst);
                    const cond = switch (cmp.cond) {
                        .Eq => "eq",
                        .NEq => "ne",
                        .Gt => "gt",
                        .GtEq => "ge",
                        .Lt => "lt",
                        .LtEq => "le",
                    };
                    try buf.fmt("{any} = icmp {s} {any} {any}, {any}", .{
                        stringify_ref(ir, fun, cmp.res),
                        cond,
                        stringify_type(ir, cmp.opTypes),
                        stringify_ref(ir, fun, cmp.lhs),
                        stringify_ref(ir, fun, cmp.rhs),
                    });
                },

                // br i1 <cond>, label <iftrue>, label <iffalse>
                .Br => {
                    const br = IR.Inst.Br.get(inst);
                    try buf.fmt("br i1 {any}, {any}, {any}", .{
                        stringify_ref(ir, fun, br.on),
                        stringify_label_ref(br.iftrue),
                        stringify_label_ref(br.iffalse),
                    });
                },
                // `br label <dest>`
                // I know I know this isn't the actual name,
                // but this is what it means and
                // I dislike Mr. Lattner's design decision
                .Jmp => {
                    const jmp = IR.Inst.Jmp.get(inst);
                    try buf.fmt("br {}", .{stringify_label_ref(jmp.dest)});
                },

                // Loads & Stores
                // `<result> = load <ty>* <pointer>`
                // newer:
                // `<result> = load <ty>, <ty>* <pointer>`
                .Load => {
                    const load = IR.Inst.Load.get(inst);
                    // using the old one because it's shorter
                    // and idk what the second type is for
                    try buf.fmt("{} = load {}* {}", .{
                        stringify_ref(ir, fun, load.res),
                        stringify_type(ir, load.ty),
                        stringify_ref(ir, fun, load.ptr),
                    });
                },
                // `store <ty> value, <ty>* <pointer>`
                .Store => {
                    const store = IR.Inst.Store.get(inst);
                    try buf.fmt("store {} {}, {}* {}", .{
                        stringify_type(ir, store.fromType),
                        stringify_ref(ir, fun, store.from),
                        stringify_type(ir, store.ty),
                        stringify_ref(ir, fun, store.to),
                    });
                },
                // GEP
                // `<result> = getelementptr <ty>* <ptrval>, i1 0, i32 <index>`
                // newer:
                // `<result> = getelementptr <ty>, <ty>* <ptrval>, i1 0, i32 <index>`
                .Gep => {
                    const gep = IR.Inst.Gep.get(inst);
                    try buf.fmt("{} = getelementptr {}, {}* {}, i1 0, {} {}", .{
                        stringify_ref(ir, fun, gep.res),
                        stringify_type(ir, gep.baseTy).not_ptr(),
                        // cannot be double pointer, so we put the star in ourselves
                        stringify_type(ir, gep.ptrTy).not_ptr(),
                        stringify_ref(ir, fun, gep.ptrVal),
                        stringify_type(ir, gep.index.type),
                        stringify_ref(ir, fun, gep.index),
                    });
                },

                // Invocation
                // `<result> = call <ty> <fnptrval>(<args>)`
                // newer:
                // `<result> = call <ty> <fnval>(<args>)`
                .Call => {
                    const call = IR.Inst.Call.get(inst);
                    try buf.fmt("{} = call {} {}(", .{
                        stringify_ref(ir, fun, call.res),
                        stringify_type(ir, call.retTy),
                        stringify_ref(ir, fun, call.fun),
                    });
                    for (call.args, 0..) |arg, i| {
                        try buf.fmt("{} {}", .{
                            stringify_type(ir, arg.type),
                            stringify_ref(ir, fun, arg),
                        });
                        if (i + 1 < call.args.len) {
                            try buf.write(", ");
                        }
                    }
                    try buf.write(")");
                },
                // `ret void`
                // `ret <ty> <value>`
                .Ret => {
                    const ret = IR.Inst.Ret.get(inst);
                    if (ret.ty == .void) {
                        try buf.write("ret void");
                    } else {
                        try buf.fmt("ret {} {}", .{
                            stringify_type(ir, ret.ty),
                            stringify_ref(ir, fun, ret.val),
                        });
                    }
                },
                // Allocation
                // `<result> = alloca <ty>`
                .Alloc => {
                    const alloca = IR.Inst.Alloc.get(inst);
                    try buf.fmt("{} = alloca {}", .{
                        stringify_ref(ir, fun, alloca.res),
                        stringify_type(ir, alloca.ty),
                    });
                },

                // Miscellaneous
                // `<result> = bitcast <ty> <value> to <ty2> ; cast type`
                .Bitcast => {
                    const bitcast = IR.Inst.Misc.get(inst);
                    try buf.fmt("{} = bitcast {}* {} to {}", .{
                        stringify_ref(ir, fun, bitcast.res),
                        stringify_type(ir, bitcast.fromType),
                        stringify_ref(ir, fun, bitcast.from),
                        stringify_type(ir, bitcast.toType),
                    });
                },
                // `<result> = trunc <ty> <value> to <ty2> ; truncate to ty2`
                .Trunc => |trunc| {
                    _ = trunc;
                    utils.todo("trunc", .{});
                },
                // `<result> = zext <ty> <value> to <ty2> ; zero-extend to ty2`
                .Zext => |zext| {
                    _ = zext;
                    utils.todo("zext", .{});
                },
                // `<result> = phi <ty> [<value 0>, <label 0>] [<value 1>, <label 1>]`
                .Phi => |phi| {
                    _ = phi;
                    utils.todo("phi", .{});
                },
            }
            try buf.write("\n");
        }
        try buf.write("}\n\n");
    }

    return buf.str.items;
}

pub fn stringify_type(ir: *const IR, ty: IR.Type) Rope {
    switch (ty) {
        .bool => return Rope.just("i1"),
        .int => return Rope.just("i64"),
        .void => return Rope.just("void"),
        .strct => |nameID| return Rope.pair("%struct.", ir.getIdent(nameID)).ptr(),
        // always a pointer
        .i8 => return Rope.just("i8*"),
        .i32 => return Rope.just("i32"),
        .arr => |arr| {
            const prefix = "[ ";
            const postfix = switch (arr.type) {
                .i8 => " x i8 ]",
                .int => " x i64 ]",
            };
            return Rope.str_num_str(prefix, arr.len, postfix);
        },
        //     const name = ir.getIdent(nameID);
        //     const strct = "struct ";
        //     // catch unreachable here to make it cleaner to use in fmt args
        //     var buf = alloc.alloc(u8, strct.len + name.len) catch unreachable;
        //     @memcpy(&buf[0..strct.len], strct);
        //     @memcpy(&buf[strct.len..], name);
        //     return buf;
        // }
    }
}

pub fn stringify_ref(ir: *const IR, fun: *const IR.Function, ref: IR.Ref) Rope {
    switch (ref.kind) {
        .local => return stringify_reg(ir, fun, ref.i),
        .param => return Rope.pair("%", ir.getIdent(ref.name)),
        .global => return Rope.pair("@", ir.getIdent(ref.name)),
        .label => return stringify_label_ref(ref.i),
        // FIXME: i don't like that it's getIdent semantically
        // really it's just that everything is interned
        .immediate => return Rope.pair("", if (ref.i == IR.InternPool.NULL) "null" else ir.getIdent(ref.i)),
    }
}

pub fn stringify_reg(ir: *const IR, fun: *const IR.Function, regID: IR.Register.ID) Rope {
    const reg = fun.regs.get(regID);
    switch (reg.name) {
        IR.InternPool.NULL => return Rope.str_num("%", reg.inst),
        // IR.InternPool.TRUE, IR.InternPool.ONE => return pair_num("%", 1),
        // IR.InternPool.FALSE, IR.InternPool.ZERO => return pair_num("%", 0),
        else => return Rope.str_str_num("%", ir.getIdent(reg.name), reg.inst),
    }
}

pub fn stringify_label(label: IR.BasicBlock.ID) Rope {
    if (label == IR.Function.entryBBID) {
        return Rope.just("entry");
    } else if (label == IR.Function.exitBBID) {
        return Rope.just("exit");
    }
    return Rope.just_num(label);
}

pub fn stringify_label_ref(label: IR.BasicBlock.ID) Rope {
    if (label == IR.Function.entryBBID) {
        return Rope.just("label %entry");
    } else if (label == IR.Function.exitBBID) {
        return Rope.just("label %exit");
    }
    std.debug.print("label %{d}\n", .{label});
    return Rope.str_num("label %", label);
}
