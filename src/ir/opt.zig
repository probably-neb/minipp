const std = @import("std");
const Alloc = std.mem.Allocator;
const ArrayList = std.ArrayList;

const utils = @import("../utils.zig");
const log = @import("../log.zig");
const DefUse = @import("./def-use.zig");

const IR = @import("./ir_phi.zig");
const Function = IR.Function;
const BasicBlock = IR.BasicBlock;
const BBID = BasicBlock.ID;
const Inst = IR.Inst;
const InstID = Function.InstID;
const Register = IR.Register;
const Reg = Register;
const RegID = Register.ID;
const Ref = IR.Ref;
const OpCode = IR.Op;

const SCCP = @import("./sccp.zig");

pub fn optimize_program(ir: *IR) !void {
    const funcs = ir.funcs.items.items;
    for (funcs) |*func| {
        try optimize_function(func);
    }
}

pub fn optimize_function(fun: *Function) !void {
    _ = fun;
}

fn sccp(ir: *IR, fun: *Function) !void {
    var arena = std.heap.ArenaAllocator.init(ting.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const info = try SCCP.sccp(alloc, ir, fun);
    log.trace("sccp info:\n{any}\n", .{info});
    // FIXME: handle updates here

    for (info.values, 0..) |value, regID_usize| {
        if (value.state != .constant) continue;

        const regID: RegID = @intCast(regID_usize);
        var reg = fun.regs.getPtr(regID);
        const constant = value.constant.?;

        const ref = sccp_const_to_ref(constant);
        const uses_list = try DefUse.uses_of(alloc, fun, reg.*);
        const uses = uses_list.items;

        for (uses) |use| {
            const instID = use.instID;
            var inst = fun.insts.get(instID);
            change_use_of_reg(ir, inst, reg.*, ref);
        }

        remove_reg(fun, reg.*);
    }

    try remove_unreachable_blocks(fun, info.reachable);
}

fn sccp_const_to_ref(value: SCCP.Value.Constant) Ref {
    return switch (value.kind) {
        .i1 => if (value.value != 0) Ref.immTrue() else Ref.immFalse(),
        .i64 => if (value.value < std.math.maxInt(u32)) Ref.immu32(@as(u32, @intCast(value.value)), .int) else {
            utils.todo("i64 constant too large for Ref.immu32... Need to intern\n", .{});
        },
    };
}

fn remove_reg(fun: *Function, reg: Reg) void {
    const bbID = reg.bb;
    var bb = fun.bbs.get(bbID);

    const instID = reg.inst;
    const idx: u32 = @intCast(std.mem.indexOfScalar(InstID, bb.insts.items(), instID) orelse {
        utils.impossible("could not find instruction {d} in bb {s}\n", .{
            instID,
            bb.name,
        });
    });
    bb.insts.remove(idx);
    // FIXME: how to remove reg?
}

fn change_use_of_reg(ir: *const IR, inst: *Inst, reg: Reg, ref: Ref) void {
    switch (inst.op) {
        .Binop => {
            var binop = Inst.Binop.get(inst.*);
            if (refers_to_reg(binop.lhs, reg)) {
                binop.lhs = ref;
                inst.* = binop.toInst();
            } else if (refers_to_reg(binop.rhs, reg)) {
                binop.rhs = ref;
                inst.* = binop.toInst();
            }
            unreachable;
        },
        .Cmp => {
            var cmp = Inst.Cmp.get(inst.*);
            if (refers_to_reg(cmp.lhs, reg)) {
                cmp.lhs = ref;
                inst.* = cmp.toInst();
            } else if (refers_to_reg(cmp.rhs, reg)) {
                cmp.rhs = ref;
                inst.* = cmp.toInst();
            }
            unreachable;
        },
        .Zext, .Sext, .Trunc, .Bitcast => {
            var misc = Inst.Misc.get(inst.*);
            if (refers_to_reg(misc.from, reg)) {
                misc.from = ref;
                inst.* = misc.toInst();
            }
            unreachable;
        },
        .Load => {
            var load = Inst.Load.get(inst.*);
            if (refers_to_reg(load.ptr, reg)) {
                load.ptr = ref;
                inst.* = load.toInst();
            }
            unreachable;
        },
        .Gep => {
            var gep = Inst.Gep.get(inst.*);
            if (refers_to_reg(gep.ptrVal, reg)) {
                gep.ptrVal = ref;
                inst.* = gep.toInst();
            } else if (refers_to_reg(gep.index, reg)) {
                gep.index = ref;
                inst.* = gep.toInst();
            }
            unreachable;
        },
        .Call => {
            var call = Inst.Call.get(inst.*);
            for (call.args) |*arg| {
                if (refers_to_reg(arg.*, reg)) {
                    arg.* = ref;
                    return;
                }
            }
            unreachable;
        },
        .Phi => {
            var phi = Inst.Phi.get(inst.*);
            for (phi.entries.items) |*entry| {
                if (refers_to_reg(entry.*.ref, reg)) {
                    entry.ref = ref;
                    return;
                }
            }
            utils.impossible("phi {any} does not refer to reg {any}\nitems={any}\n", .{ phi, reg, phi.entries.items });
        },
        .Ret => {
            var ret = Inst.Ret.get(inst.*);
            if (refers_to_reg(ret.val, reg)) {
                ret.val = ref;
                inst.* = ret.toInst();
            }
            unreachable;
        },
        .Store => {
            var store = Inst.Store.get(inst.*);
            if (refers_to_reg(store.from, reg)) {
                store.from = ref;
                inst.* = store.toInst();
            } else if (refers_to_reg(store.to, reg)) {
                store.to = ref;
                inst.* = store.toInst();
            }
            unreachable;
        },
        .Br => {
            var br = Inst.Br.get(inst.*);
            if (refers_to_reg(br.on, reg)) {
                switch (ref.kind) {
                    .immediate_u32 => {
                        inst.* = Inst.jmp(
                            Ref.label(
                                if (ref.i != 0) br.iftrue else br.iffalse,
                            ),
                        );
                    },
                    .immediate => {
                        const val = ir.parseInt(ref.i) catch unreachable;
                        inst.* = Inst.jmp(
                            Ref.label(
                                if (val != 0) br.iftrue else br.iffalse,
                            ),
                        );
                    },
                    else => {
                        br.on = ref;
                        inst.* = br.toInst();
                    },
                }
                return;
            }
            unreachable;
        },
        // no registers
        .Alloc, .Param, .Jmp => {},
    }
}

fn refers_to_reg(ref: Ref, reg: Reg) bool {
    return switch (ref.kind) {
        .local => ref.i == reg.id,
        else => false,
    };
}

fn remove_unreachable_blocks(fun: *Function, reachable: []bool) !void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    for (bbs.items(), 0..) |bb, id| {
        const bbID = bbs.ids.items[id];
        std.debug.print("bb {d} incomers: {any}\n", .{ bbID, bb.incomers.items });
        std.debug.print("bb {d} outgoers: {any}\n", .{ bbID, bb.outgoers });
    }

    utils.assert(@as(usize, @intCast(bbs.len)) == reachable.len, "mismatch in block count", .{});
    for (reachable, 0..) |r, i| {
        const stringify_label = @import("stringify_phi.zig").stringify_label;
        std.debug.print("{s} - {any}\n", .{ stringify_label(fun, bbs.ids.items[i]), r });
    }
    for (reachable, 0..) |is_reachable, bbID_usize| {
        const bbID: BBID = bbs.ids.items[bbID_usize];
        const bb = bbs.get(bbID);

        if (is_reachable) {
            continue;
        }

        if (bb.incomers.items.len > 0) {
            utils.assert(bb.outgoers[0] != null, "FUCK - have to handle case where removing bb has no outgoers\n", .{});
            utils.assert(bb.outgoers[1] == null, "FUCK - have to handle case where removing bb has 2 outgoers\n", .{});

            const outgoer = bb.outgoers[0].?;

            var outgoerBB = bbs.get(outgoer);
            // link parent to child
            for (bb.incomers.items) |incomer| {
                var incomerBB = bbs.get(incomer);
                var incomerBRID = (ptr_to_last(InstID, incomerBB.insts.list.items) orelse unreachable).*;
                var incomerBR = insts.get(incomerBRID);

                std.debug.print("incomer={d} op={s}\n", .{ incomer, @tagName(incomerBR.*.op) });

                switch (incomerBR.*.op) {
                    .Br => {
                        var br = Inst.Br.get(incomerBR.*);
                        std.debug.print("correcting br:\n{any}\n{d}\n", .{ br, outgoer });
                        if (br.iftrue == bbID) {
                            br.iftrue = outgoer;
                        } else if (br.iffalse == bbID) {
                            br.iffalse = outgoer;
                        }
                        incomerBR.* = br.toInst();
                    },
                    .Jmp => {
                        var jmp = Inst.Jmp.get(incomerBR.*);
                        jmp.dest = outgoer;
                        std.debug.print("correcting jmp:\n{any}\n{d}\n", .{ jmp, outgoer });
                        incomerBR.* = jmp.toInst();
                    },
                    else => unreachable,
                }
                std.mem.replaceScalar(?BBID, &incomerBB.outgoers, bbID, outgoer);
                std.mem.replaceScalar(BBID, outgoerBB.incomers.items, bbID, incomer);
            }
            bb.incomers.clearAndFree();
            bb.*.outgoers[0] = null;
        }

        // FIXME: assert the registers in the block are never used
        // or are in a phi if so remove them from phi entries
        // bbs.remove(bbID);
    }
    for (bbs.items(), 0..) |bb, id| {
        const bbID = bbs.ids.items[id];
        std.debug.print("bb {d} incomers: {any}\n", .{ bbID, bb.incomers.items });
        std.debug.print("bb {d} outgoers: {any}\n", .{ bbID, bb.outgoers });
        std.debug.print("br = {any}\n", .{(insts.get((ptr_to_last(BBID, bb.insts.list.items) orelse unreachable).*)).*});
    }

    for (reachable, 0..) |is_reachable, i| {
        if (is_reachable) continue;
        // std.debug.print("i-{d} ids-{d} bbID-{d}\n", .{ id, bbs.ids.items[id], bbID });
        // std.debug.print("i-{d} bbID-{d}\n", .{ id, bbID });

        // if (id == 5) bbs.remove(bbID);
        _ = bbs.orderedRemove(@intCast(i));
    }
}

fn ptr_to_last(comptime T: type, elems: []T) ?*T {
    if (elems.len == 0) return null;
    return &elems[elems.len - 1];
}

fn change_ctrl_flow_dest(inst: *Inst) void {
    _ = inst;
}

const ting = std.testing;
const testAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try @import("../ast.zig").initFromParser(parser);
    const ir = try @import("phi.zig").generate(testAlloc, &ast);
    return ir;
}

pub const OptPass = enum {
    sccp,
};

fn save_dot_to_file(ir: *const IR, file: []const u8) !void {
    const dot = @import("../dot.zig");
    var arena = std.heap.ArenaAllocator.init(ting.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();
    try std.fs.cwd().writeFile(file, try dot.generate(alloc, try ir.stringify(alloc)));
}

// NOTE: this is pub so it can be imported from files implementing a specific pass so they can use the mutations
// defined above
pub fn expectResultsInIR(input: []const u8, expected: anytype, comptime fun_passes: anytype) !void {
    var arena = std.heap.ArenaAllocator.init(ting.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    var ir = try testMe(input);

    // Run optimization passes
    inline for (fun_passes) |fun_pass| {
        const fun_name: []const u8 = @as([]const u8, fun_pass.@"0");
        const passes = fun_pass.@"1";
        const funNameID = ir.getIdentID(fun_name) catch {
            log.err("function {s} not found in IR\n", .{fun_name});
            return error.FunctionNotFound;
        };
        var fun = ir.getFun(funNameID) catch {
            log.err("function {s} not found in IR\n", .{fun_name});
            return error.FunctionNotFound;
        };
        inline for (passes) |pass| {
            switch (pass) {
                .sccp => {
                    try sccp(&ir, &fun);
                },
                else => {
                    log.warn("unknown optimization pass: {s}\n", .{@tagName(pass)});
                },
            }
        }
    }
    try save_dot_to_file(&ir, "out.dot");
    const gotIRstr = try ir.stringify(alloc);

    // NOTE: could use multiline strings for the
    // expected value but, that makes it so you can't put
    // comments inbetween the lines
    // idk rough tradeoff

    // putting all lines in newline separated buf
    // required because as far as I can tell, writing
    // multiline strings in zig is a pain in the
    // metaphorical ass
    comptime var expectedLen: usize = 1;
    inline for (expected) |e| {
        expectedLen += e.len + 1;
    }
    var expectedStr = try alloc.alloc(u8, expectedLen);
    comptime var i: usize = 0;
    inline for (expected) |e| {
        const end = i + e.len;
        @memcpy(expectedStr[i..end], e);
        expectedStr[end] = '\n';
        i = end + 1;
    }
    // the stringify outputs an extra newline at the end.
    // this is the easier fix sue me
    expectedStr[i] = '\n';

    try ting.expectEqualStrings(expectedStr, gotIRstr);
}
