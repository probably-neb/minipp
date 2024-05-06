const std = @import("std");
const IR = @import("./ir.zig");
const utils = @import("../utils.zig");

const Alloc = std.mem.Allocator;

const INDENT = "  ";

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

const Pair = struct {
    a: []const u8,
    b: []const u8,
    num: ?i128 = null,

    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        _ = try writer.write(self.a);
        _ = try writer.write(self.b);
        if (self.num) |n| {
            try writer.print("{}", .{n});
        }
    }
};

fn pair(a: []const u8, b: []const u8) Pair {
    return Pair{ .a = a, .b = b };
}

fn just(a: []const u8) Pair {
    return Pair{ .a = a, .b = "" };
}

fn pair_num(a: []const u8, num: anytype) Pair {
    return Pair{ .a = a, .b = "", .num = @intCast(num) };
}

fn triple_num(a: []const u8, b: []const u8, num: anytype) Pair {
    return Pair{ .a = a, .b = b, .num = @intCast(num) };
}

pub fn stringify(ir: *const IR, alloc: Alloc) ![]const u8 {
    var buf = Buf.init(alloc);

    // TODO: stringify types + globals
    for (ir.funcs.items.items) |*fun| {
        try buf.fmt("define {} @{s}(", .{ stringify_type(ir, fun.returnType), ir.getIdent(fun.name) });
        // TODO: args
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
                .Cmp => |cmp| {
                    _ = cmp;

                    // The condition of a cmp
                    // Placed in `Op` struct for namespacing
                    // pub const Cond = enum { Eq, Lt, Gt, GtEq, LtEq };
                    utils.todo("cmp", .{});
                },

                // br i1 <cond>, label <iftrue>, label <iffalse>
                .Br => |br| {
                    _ = br;
                    utils.todo("br", .{});
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
                .Gep => |gep| {
                    _ = gep;
                    utils.todo("gep", .{});
                },

                // Invocation
                // `<result> = call <ty> <fnptrval>(<args>)`
                // newer:
                // `<result> = call <ty> <fnval>(<args>)`
                .Call => |call| {
                    _ = call;
                    utils.todo("call", .{});
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
                .Bitcast => |bitcast| {
                    _ = bitcast;
                    utils.todo("bitcast", .{});
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

pub fn stringify_type(ir: *const IR, ty: IR.Type) Pair {
    switch (ty) {
        .bool => return just("i1"),
        .int => return just("i64"),
        .void => return just("void"),
        .strct => |nameID| return pair("struct ", ir.getIdent(nameID)),
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

pub fn stringify_ref(ir: *const IR, fun: *const IR.Function, ref: IR.Ref) Pair {
    switch (ref.kind) {
        .local => return stringify_reg(ir, fun, ref.i),
        .global => return pair("@", ir.getIdent(ref.name)),
        .label => return stringify_label_ref(ref.i),
        // FIXME: i don't like that it's getIdent semantically
        // really it's just that everything is interned
        .immediate => return pair("", ir.getIdent(ref.name)),
    }
}

pub fn stringify_reg(ir: *const IR, fun: *const IR.Function, regID: IR.Register.ID) Pair {
    const reg = fun.regs.get(regID);
    switch (reg.name) {
        IR.InternPool.NULL => return pair_num("%", reg.inst),
        // IR.InternPool.TRUE, IR.InternPool.ONE => return pair_num("%", 1),
        // IR.InternPool.FALSE, IR.InternPool.ZERO => return pair_num("%", 0),
        else => return triple_num("%", ir.getIdent(reg.name), reg.inst),
    }
}

pub fn stringify_label(label: IR.BasicBlock.ID) Pair {
    if (label == IR.Function.entryBBID) {
        return just("entry");
    } else if (label == IR.Function.exitBBID) {
        return just("exit");
    }
    return pair_num("", label);
}

pub fn stringify_label_ref(label: IR.BasicBlock.ID) Pair {
    if (label == IR.Function.entryBBID) {
        return just("label %entry");
    } else if (label == IR.Function.exitBBID) {
        return just("label %exit");
    }
    return pair_num("label %", label);
}
