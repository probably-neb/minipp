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

const stringify_label = @import("stringify_phi.zig").stringify_label;

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
    // log.trace("sccp info:\n{any}\n", .{info});
    // FIXME: handle updates here

    for (info.values, fun.regs.items.items) |value, reg| {
        std.debug.print("{s} [{?any}]\n", .{
            try @import("stringify_phi.zig").stringify_inst_to_str(
                reg.inst,
                ir,
                fun,
                fun.bbs.get(reg.bb).*,
            ),
            value.constant,
        });
    }
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
            var bb = fun.bbs.get(use.bb);
            change_use_of_reg(ir, bb, inst, reg.*, ref);
        }

        remove_reg(fun, reg.*);
    }
    try remove_unreachable_blocks(alloc, ir, fun, info.reachable);
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

fn change_use_of_reg(ir: *const IR, bb: *BasicBlock, inst: *Inst, reg: Reg, ref: Ref) void {
    switch (inst.op) {
        .Binop => {
            var binop = Inst.Binop.get(inst.*);
            if (refers_to_reg(binop.lhs, reg)) {
                binop.lhs = ref;
                inst.* = binop.toInst();
                return;
            } else if (refers_to_reg(binop.rhs, reg)) {
                binop.rhs = ref;
                inst.* = binop.toInst();
                return;
            }
            unreachable;
        },
        .Cmp => {
            var cmp = Inst.Cmp.get(inst.*);
            if (refers_to_reg(cmp.lhs, reg)) {
                cmp.lhs = ref;
                inst.* = cmp.toInst();
                return;
            } else if (refers_to_reg(cmp.rhs, reg)) {
                cmp.rhs = ref;
                inst.* = cmp.toInst();
                return;
            }
            unreachable;
        },
        .Zext, .Sext, .Trunc, .Bitcast => {
            var misc = Inst.Misc.get(inst.*);
            if (!refers_to_reg(misc.from, reg)) {
                misc.from = ref;
                inst.* = misc.toInst();
                return;
            }
            unreachable;
        },
        .Load => {
            var load = Inst.Load.get(inst.*);
            if (refers_to_reg(load.ptr, reg)) {
                load.ptr = ref;
                inst.* = load.toInst();
                return;
            }
            unreachable;
        },
        .Gep => {
            var gep = Inst.Gep.get(inst.*);
            if (refers_to_reg(gep.ptrVal, reg)) {
                gep.ptrVal = ref;
                inst.* = gep.toInst();
                return;
            } else if (refers_to_reg(gep.index, reg)) {
                gep.index = ref;
                inst.* = gep.toInst();
                return;
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
                return;
            }
            unreachable;
        },
        .Store => {
            var store = Inst.Store.get(inst.*);
            if (refers_to_reg(store.from, reg)) {
                store.from = ref;
                inst.* = store.toInst();
                return;
            } else if (refers_to_reg(store.to, reg)) {
                store.to = ref;
                inst.* = store.toInst();
                return;
            }
            unreachable;
        },
        .Br => {
            var br = Inst.Br.get(inst.*);
            if (refers_to_reg(br.on, reg)) {
                var not_taken: ?BBID = null;
                switch (ref.kind) {
                    .immediate_u32 => {
                        var newDest: BBID = undefined;
                        if (ref.i != 0) {
                            newDest = br.iftrue;
                            not_taken = br.iffalse;
                        } else {
                            newDest = br.iffalse;
                            not_taken = br.iftrue;
                        }
                        inst.* = Inst.jmp(Ref.label(newDest));
                    },
                    .immediate => {
                        var newDest: BBID = undefined;
                        const val = ir.parseInt(ref.i) catch unreachable;
                        if (val != 0) {
                            newDest = br.iftrue;
                            not_taken = br.iffalse;
                        } else {
                            newDest = br.iffalse;
                            not_taken = br.iftrue;
                        }
                        inst.* = Inst.jmp(Ref.label(newDest));
                    },
                    else => {
                        br.on = ref;
                        inst.* = br.toInst();
                    },
                }
                if (not_taken) |removed_outgoer_id| {
                    remove_bb_from_outgoers(bb, removed_outgoer_id);
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

fn remove_unreachable_blocks(alloc: Alloc, ir: *const IR, fun: *Function, reachable: []bool) !void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    // for (bbs.items(), bbs.ids()) |bb, bbID| {
    //     std.debug.print("BEFOR bb [{d}] {s} incomers: {any}\n", .{ bbID, bb.name, bb.incomers.items });
    //     std.debug.print("BEFOR bb [{d}] {s} outgoers: {any}\n", .{ bbID, bb.name, bb.outgoers });
    // }
    save_dot_to_file(ir, "pre_remove_edges.dot") catch {};

    utils.assert(@as(usize, @intCast(bbs.len)) == reachable.len, "mismatch in block count", .{});
    for (reachable, 0..) |r, i| {
        const bbID = bbs.ids()[i];
        std.debug.print("[{d}] {s} - {any}\n", .{ bbID, stringify_label(fun, bbID), r });
    }
    for (reachable, bbs.ids()) |is_reachable, bbID| {
        if (is_reachable) {
            continue;
        }

        try remove_block_edges(fun, bbID);
        const bb = bbs.get(bbID);
        bb.incomers.clearAndFree();
        bb.*.outgoers = [_]?BBID{ null, null };
    }
    for (bbs.items(), bbs.ids()) |bb, bbID| {
        std.debug.print("AFTER bb [{d}] {s} incomers: {any}\n", .{ bbID, bb.name, bb.incomers.items });
        std.debug.print("AFTER bb [{d}] {s} outgoers: {any}\n", .{ bbID, bb.name, bb.outgoers });
        std.debug.print("br = {any}\n", .{(insts.get((ptr_to_last(BBID, bb.insts.list.items) orelse unreachable).*)).*});
    }

    save_dot_to_file(ir, "post_remove_edges.dot") catch {};

    var ids = try alloc.alloc(BBID, reachable.len);
    @memcpy(ids, bbs.ids());

    for (reachable, ids) |is_reachable, bbID| {
        if (is_reachable) {
            continue;
        }
        // std.debug.print("i-{d} ids-{d} bbID-{d}\n", .{ id, bbs.ids.items[id], bbID });
        // std.debug.print("i-{d} bbID-{d}\n", .{ id, bbID });

        // if (id == 5) bbs.remove(bbID);
        // std.debug.print("WATCH ME DELETE {d}\n", .{bbID});
        std.debug.print("[{d}] {s} - {any}\n", .{ bbID, stringify_label(fun, bbID), is_reachable });
        _ = bbs.remove(bbID);
    }

    save_dot_to_file(ir, "post_remove_unreachable.dot") catch {};
}

fn remove_block_edges(fun: *Function, bbID: BBID) !void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    const bb = bbs.get(bbID);
    // brute_force_remove_block_edges(fun, bbID);
    // brute_force_remove_phi_entires_referencing_dead_bb(fun, bbID);

    if (bb_num_outgoers(bb) == 2) {
        std.debug.print("removing bb {s} with 2 outgoers {any} and these incomers {any}\n", .{ bb.name, bb.outgoers, bb.incomers.items });
        var self_ref: BBID = undefined;
        if (is_self_ref(fun, bbID, bb.outgoers[0].?)) {
            std.debug.print("self ref detected at 0 ={?d} in {s}\n", .{ bb.outgoers[0], bb.name });
            self_ref = bb.outgoers[0].?;
            // const outgoer = bbs.get(outgoerID);
            // remove_bb_from_incomers(outgoer, bbID);
            // remove_bb_from_outgoers(outgoer, bbID);
        } else if (is_self_ref(fun, bbID, bb.outgoers[1].?)) {
            std.debug.print("self ref detected at 1 ={?d} in {s}\n", .{ bb.outgoers[1], bb.name });
            self_ref = bb.outgoers[1].?;
        } else {
            utils.impossible("FUCK - have to handle case where bb [{d}] {s} has 2 outgoers and neither are self ref\n", .{ bbID, stringify_label(fun, bbID) });
            return;
        }
        // brute_force_remove_block_edges(fun, bbID);
        // brute_force_remove_phi_entires_referencing_dead_bb(fun, bbID);
        utils.assert(bb.incomers.items.len == 1, "FUCK - HOW TO HANDLE bb {s} with 2 outgoers and not 1 incomer\n", .{bb.name});
        const incomer = bb.incomers.items[0];
        var incomerBB = bbs.get(incomer);
        var incomerBRID = (ptr_to_last(InstID, incomerBB.insts.list.items) orelse unreachable).*;
        var incomerBR = insts.get(incomerBRID);
        for (bb.outgoers) |_outgoer| {
            const outgoer = _outgoer.?;
            var outgoerBB = bbs.get(outgoer);
            std.debug.print("incomer={d} op={s}\n", .{ incomer, @tagName(incomerBR.*.op) });

            if (outgoer == self_ref) {
                // self_ref could be self (bbID) or some other bb ID that
                // eventually loops around

                // remove phis just in case self_ref != self
                try remove_phi_entires_in_children_of_dead_bb(fun, bb, bbID);
                // remove bb from incomers of outgoer (could be self)
                remove_bb_from_incomers(outgoerBB, bbID);
                // remove bb from outgoers of incomer (could be self)
                remove_bb_from_outgoers(incomerBB, bbID);
                remove_bb_from_outgoers(bb, self_ref);
                const selfBRID = (ptr_to_last(InstID, bb.insts.list.items) orelse unreachable).*;
                var selfBR = insts.get(selfBRID);
                _ = replace_branches_to_with(selfBR, self_ref, bbID);
            } else {
                _ = replace_branches_to_with(incomerBR, bbID, outgoer);
                replace_bb_in_outgoers_with(incomerBB, bbID, outgoer);
                replace_bb_in_incomers_with(outgoerBB, bbID, incomer);
                remove_bb_from_outgoers(incomerBB, bbID);
                remove_bb_from_outgoers(outgoerBB, bbID);
                try remove_phi_entires_in_children_of_dead_bb(fun, bb, bbID);
            }
        }
        return;
    }
    if (bb.incomers.items.len > 0) {
        utils.assert(bb_num_outgoers(bb) != 0, "FUCK - have to handle case where removing bb has no outgoers\n", .{});
        utils.assert(bb_num_outgoers(bb) != 2, "FUCK - FELL THROUGH this case should be handled above\n", .{});

        const outgoer = if (bb.outgoers[0]) |out| out else if (bb.outgoers[1]) |out| out else unreachable;

        var outgoerBB = bbs.get(outgoer);
        _ = outgoerBB;
        // link parent to child
        for (bb.incomers.items) |incomer| {
            var incomerBB = bbs.get(incomer);
            var incomerBRID = (ptr_to_last(InstID, incomerBB.insts.list.items) orelse unreachable).*;
            var incomerBR = insts.get(incomerBRID);

            std.debug.print("incomer={d} op={s}\n", .{ incomer, @tagName(incomerBR.*.op) });

            _ = replace_branches_to_with(incomerBR, bbID, outgoer);
            // replace_bb_in_outgoers_with(incomerBB, bbID, outgoer);
            // replace_bb_in_incomers_with(outgoerBB, bbID, incomer);
        }
        try remove_phi_entires_in_children_of_dead_bb(fun, bb, bbID);
    } else if (bb_num_outgoers(bb) < 2) {
        try remove_phi_entires_in_children_of_dead_bb(fun, bb, bbID);
        for (bb.outgoers) |maybe_outgoerID| {
            if (maybe_outgoerID == null) continue;
            const outgoerID = maybe_outgoerID.?;
            const outgoer = bbs.get(outgoerID);
            remove_bb_from_incomers(outgoer, bbID);
        }
    }
}

fn remove_bb_from_incomers(fromBB: *BasicBlock, toRemoveBBID: BBID) void {
    const entries = &fromBB.incomers;
    var i: usize = 0;
    while (i < entries.items.len) {
        const incomerID = entries.items[i];
        if (incomerID == toRemoveBBID) {
            _ = entries.swapRemove(i);
        } else {
            i += 1;
        }
    }
}

fn remove_bb_from_outgoers(fromBB: *BasicBlock, toRemoveBBID: BBID) void {
    std.debug.print("removing {d} from outgoers of {s} {any}\n", .{ toRemoveBBID, fromBB.name, fromBB.outgoers });
    const outgoers = &fromBB.outgoers;
    for (outgoers) |*outgoerID| {
        if (outgoerID.* != null and outgoerID.* == toRemoveBBID) {
            outgoerID.* = null;
        }
    }
    std.debug.print("outgoers after removing {d} from {s} = {any}\n", .{ toRemoveBBID, fromBB.name, fromBB.outgoers });
}

fn remove_phi_entires_in_children_of_dead_bb(fun: *Function, bb: *BasicBlock, bbID: BBID) !void {
    var visited = try fun.alloc.alloc(bool, @intCast(fun.bbs.len));
    defer fun.alloc.free(visited);
    @memset(visited, false);
    visited[bbID] = true;
    remove_phi_entires_in_children_of_dead_bb_inner(fun, bb, bbID, visited);
}
fn remove_phi_entires_in_children_of_dead_bb_inner(fun: *Function, bb: *BasicBlock, bbID: BBID, visited: []bool) void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    for (bb.outgoers, 0..) |maybe_outgoerID, outgoer_index| {
        if (maybe_outgoerID == null) continue;
        const outgoerID = maybe_outgoerID.?;
        if (!bbs.list.contains(outgoerID)) {
            log.warn("outgoer {d} not found in bbs but in {s} outgoers\n", .{ outgoerID, stringify_label(fun, bbID) });
            bb.*.outgoers[outgoer_index] = null;
            continue;
        }
        var outgoer = bbs.get(outgoerID);
        for (outgoer.insts.items()) |instID| {
            const inst = insts.get(instID);
            if (inst.op != .Phi) {
                continue;
            }
            var phi = Inst.Phi.get(inst.*);
            const entries = &phi.entries;
            var i: usize = 0;
            while (i < entries.items.len) {
                const entry = entries.items[i];
                if (entry.bb == bbID) {
                    std.debug.print("[{d}] {s} removing entry referencing {s}\n", .{
                        outgoerID,
                        stringify_label(fun, outgoerID),
                        stringify_label(fun, bbID),
                    });
                    _ = entries.orderedRemove(i);
                } else {
                    i += 1;
                }
            }
            inst.* = phi.toInst();
        }
        std.debug.print("removed phis from [{d}] {s}\n", .{ outgoerID, outgoer.name });
        if (!visited[outgoerID]) {
            visited[outgoerID] = true;
            remove_phi_entires_in_children_of_dead_bb_inner(fun, outgoer, bbID, visited);
        }
    }
}

fn brute_force_remove_block_edges(fun: *Function, badBBID: BBID) void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;
    _ = insts;

    for (bbs.ids()) |bbID| {
        const bb = bbs.get(bbID);
        std.debug.print("removing {d} from incomers of {s} {any}\n", .{ badBBID, bb.name, bb.incomers.items });
        remove_bb_from_incomers(bb, badBBID);
        remove_bb_from_outgoers(bb, badBBID);
    }
}

fn brute_force_remove_phi_entires_referencing_dead_bb(fun: *Function, badBBID: BBID) void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    for (bbs.items(), bbs.ids()) |*bb, bbID| {
        for (bb.insts.items()) |instID| {
            const inst = insts.get(instID);
            if (inst.op != .Phi) {
                continue;
            }
            var phi = Inst.Phi.get(inst.*);
            const entries = &phi.entries;
            var i: usize = 0;
            while (i < entries.items.len) {
                const entry = entries.items[i];
                if (entry.bb == badBBID) {
                    std.debug.print("[{d}] {s} brute force removing entry referencing {s}\n", .{
                        bbID,
                        stringify_label(fun, bbID),
                        stringify_label(fun, badBBID),
                    });
                    _ = entries.orderedRemove(i);
                } else {
                    i += 1;
                }
            }
            inst.* = phi.toInst();
        }
    }
    // std.debug.print("removed phis from [{d}] {s}\n", .{ outgoerID, outgoer.name });
    // if (!visited[outgoerID]) {
    //     visited[outgoerID] = true;
    //     remove_phi_entires_in_children_of_dead_bb_inner(fun, outgoer, bbID, visited);
    // }
}

fn replace_bb_in_outgoers_with(bb: *BasicBlock, from: BBID, to: BBID) void {
    std.mem.replaceScalar(?BBID, &bb.outgoers, from, to);
}

fn replace_bb_in_incomers_with(bb: *BasicBlock, from: BBID, to: BBID) void {
    std.mem.replaceScalar(BBID, bb.incomers.items, from, to);
}

fn replace_branches_to_with(inst: *Inst, from: BBID, to: BBID) bool {
    switch (inst.op) {
        .Br => {
            var br = Inst.Br.get(inst.*);
            // std.debug.print("correcting br:\n{any}\n{d}\n", .{ br, outgoer });
            if (br.iftrue == from) {
                br.iftrue = to;
                inst.* = br.toInst();
                return true;
            } else if (br.iffalse == from) {
                br.iffalse = to;
                inst.* = br.toInst();
                return true;
            }
        },
        .Jmp => {
            var jmp = Inst.Jmp.get(inst.*);
            if (jmp.dest == from) {
                jmp.dest = to;
                inst.* = jmp.toInst();
                return true;
            }
            // std.debug.print("correcting jmp:\n{any}\n{d}\n", .{ jmp, outgoer });
        },
        else => unreachable,
    }
    return false;
}

fn is_self_ref(fun: *const Function, selfBBID: BBID, outgoerBBID: BBID) bool {
    if (outgoerBBID == selfBBID) {
        return true;
    }
    const outgoerBB = fun.bbs.get(outgoerBBID);
    for (outgoerBB.outgoers) |maybe_outgoerID| {
        if (maybe_outgoerID == null) continue;
        const outgoerOutgoerBBID = maybe_outgoerID.?;
        if (outgoerOutgoerBBID == selfBBID) {
            return true;
        }
        if (is_self_ref(fun, selfBBID, outgoerOutgoerBBID)) {
            return true;
        }
    }
    return false;
}

fn ptr_to_last(comptime T: type, elems: []T) ?*T {
    if (elems.len == 0) return null;
    return &elems[elems.len - 1];
}

fn empty_block_removal_pass(fun: *Function) !void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    var idsToRemove = std.ArrayList(BBID).init(fun.alloc);
    defer idsToRemove.deinit();

    for (bbs.ids()) |bbID| {
        const bb = bbs.get(bbID);

        std.debug.print("trying to remove edges from block {s} with incomers {any} and outgoers {any}\n", .{
            stringify_label(fun, bbID),
            bb.incomers.items,
            bb.outgoers,
        });
        if (bb.insts.len > 1) {
            continue;
        }
        utils.assert(bb.insts.len != 0, "bb [{d}] has no insts\n", .{bbID});

        const inst = insts.get(bb.insts.get(0).*);
        if (inst.op != .Jmp) {
            continue;
        }
        // the following two continues are a hack to skip entry and exit blocks
        // because entries have no incomers, and exits have no outgoers
        if (bb.incomers.items.len == 0) {
            std.debug.print("skipping removing edges from block {s} because no incomers\n", .{
                stringify_label(fun, bbID),
            });
            continue;
        }
        if (bb_num_outgoers(bb) == 0) {
            std.debug.print("skipping removing edges from block {s} because no outgoers\n", .{
                stringify_label(fun, bbID),
            });
            continue;
        }
        utils.assert(bbID != fun.exitBBID, "exit block should not be removed\n", .{});
        utils.assert(bbID != Function.entryBBID, "entry block should not be removed\n", .{});

        std.debug.print("removing edges from block {s}\n", .{
            stringify_label(fun, bbID),
        });
        try remove_block_edges(fun, bbID);
        try idsToRemove.append(bbID);
    }
    for (idsToRemove.items) |bbID| {
        bbs.remove(bbID);
    }
}

fn bb_num_outgoers(bb: *const BasicBlock) usize {
    var num: usize = 0;
    for (bb.outgoers) |outgoer| {
        num += @intCast(@intFromBool(outgoer != null));
    }
    return num;
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
    try save_dot_to_file(&ir, "pre.dot");
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
                    try sccp(&ir, fun);
                },
                .empty_bb => {
                    try empty_block_removal_pass(fun);
                },
                else => {
                    log.warn("unknown optimization pass: {s}\n", .{@tagName(pass)});
                },
            }
        }
    }
    try save_dot_to_file(&ir, "post.dot");
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

// test "opt.sccp+empty-block=$profit" {
//     log.empty();
//     errdefer log.print();
//
//     try expectResultsInIR(
//         \\fun main() int {
//         \\  int a;
//         \\  if (false) {
//         \\    a = 1;
//         \\  } else {
//         \\    a = 2;
//         \\  }
//         \\  return a;
//         \\}
//     , .{
//         "define i64 @main() {",
//         "entry:",
//         "  br label %exit",
//         "exit:",
//         "  ret i64 2",
//         "}",
//     }, .{
//         .{ "main", .{ .sccp, .empty_bb } },
//     });
// }
//
//

test "sccp.removes-nested-never-ran-while" {
    log.empty();
    errdefer log.print();
    try expectResultsInIR(
        \\fun main() int {
        \\  int a;
        \\  a = 2;
        \\  while (false) {
        \\    a = 3;
        \\  }
        \\  return a;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  br label %exit",
        "exit:",
        "  ret i64 2",
        "}",
    }, .{
        .{ "main", .{ .sccp, .empty_bb } },
    });
}
