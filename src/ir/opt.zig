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
const CmpProp = @import("./cmp-info-prop.zig");

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

fn sccp(ir: *IR, fun: *Function) !bool {
    var arena = std.heap.ArenaAllocator.init(fun.alloc);
    defer arena.deinit();
    var alloc = arena.allocator();

    var info = try SCCP.sccp(alloc, ir, fun);

    const allReachable = for (fun.bbs.ids()) |bbID| {
        if (!info.reachable[bbID]) {
            // std.debug.print("found unreachable bb ID={d} label={s}\n", .{ bbID, fun.bbs.get(bbID).name });
            break false;
        }
    } else true;
    const noneConstant = for (info.values) |value| {
        if (value.state == .constant) {
            // std.debug.print("found constant={any}\n", .{value});
            break false;
        }
    } else true;
    if (allReachable and noneConstant) {
        return false;
    } else {
        // std.debug.print("running sccp\nnoneConstant={}\nallReachable={any}\n", .{ noneConstant, allReachable });
    }
    // update all of the registers
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
            // FIXME: made change to phi here, this could be wrong
            change_use_of_reg(fun, ir, use.bb, bb, inst, reg.*, ref);
        }
        remove_reg(fun, reg.*);
    }

    // update all of the phi nodes
    // track if a change has been made
    // while changes
    // for each one that has a entry that points to a non-reachable block, remove the block,
    //  if the phi node only has one entry, replace all uses of the phi node with the value of the entry
    //  remove the phi node
    //  mark change
    //  break
    var changes: bool = true;
    while (changes) {
        // std.debug.print("running phi node cleanup\n", .{});
        changes = false;
        for (fun.bbs.ids()) |bbID_1| {
            if (!info.reachable[bbID_1]) continue;
            // std.debug.print("running phi node cleanup for bb {d}\n", .{bbID_1});
            var bb = fun.bbs.get(bbID_1);
            // var newInsts = IR.BasicBlock.List.init(fun.alloc);
            for (bb.insts.items(), 0..) |instID, instIDX| {
                // std.debug.print("WATCH WHAT I'm ABOUT TO DO TO {d} @{d} from bbID={d} {any}\n", .{ instID, instIDX, bbID_1, bb.insts.items() });
                // defer std.debug.print("LOOK WHAT I DID TO {d} @{d} from bbID={d} {any}\n", .{ instID, instIDX, bbID_1, bb.insts.items() });
                const inst = fun.insts.get(instID);
                if (inst.op != .Phi) {
                    // try newInsts.append(instID);
                    continue;
                }
                // std.debug.print("running phi node cleanup for inst {d}\n", .{instID});

                var bbInsts = &bb.insts.list;
                var bbLen = &bb.insts.len;

                var phi = Inst.Phi.get(inst.*);
                var phiReg = fun.regs.getPtr(phi.res.i);
                var entries = phi.entries;
                var entries_changes: bool = true;
                var entreies_changed: bool = false;
                // remove any entries that point to a non-reachable block
                while (entries_changes) {
                    // std.debug.print("running phi node cleanup for inst {d} with entries {any}\n", .{ instID, entries.items });
                    entries_changes = false;
                    for (entries.items, 0..) |entry, entryI| {
                        if (!info.reachable[entry.bb]) {
                            // remove the entry
                            // std.debug.print("removing entry {d} from phi node {d} in block {d}\n", .{ entryI, instID, bbID_1 });
                            entries_changes = true;
                            _ = entries.orderedRemove(entryI);
                            entreies_changed = true;
                            break;
                        }
                    }
                }
                phi.entries = entries;
                fun.insts.set(instID, phi.toInst());
                if (entreies_changed) {
                    changes = true;
                    break;
                }

                if (entries.items.len == 0) {
                    // remove the phi node
                    //_ = fun.insts.remove(instID);
                    // std.debug.print("removing empty phi node {d} in block {d}\n", .{ instID, bbID_1 });
                    _ = bbInsts.*.orderedRemove(instIDX);
                    bbLen.* -= 1;
                    // bb.*.insts.remove(@intCast(instIDX));
                    changes = true;
                    break;
                } else if (entries.items.len == 1) {
                    // std.debug.print("replacing phi node {d} in block {d} with entry {any}\n", .{ instID, bbID_1, entries.items[0].ref });
                    // replace all uses of the phi node with the value of the entry
                    const ref = &entries.items[0].ref;
                    try replace_all_uses(fun, ir, phiReg, ref.*, info.reachable);
                    // remove the phi node
                    // _ = fun.insts.remove(instID);
                    utils.assert(std.mem.indexOfScalar(BBID, bb.insts.items(), instID) != null, "bb has no inst {d}\n", .{instID});
                    // std.debug.print("WATCH ME REMOVE {d} @{d} from bbID={d} {any}\n", .{ instID, instIDX, bbID_1, bb.insts.items() });
                    _ = bbInsts.*.orderedRemove(instIDX);
                    bbLen.* -= 1;
                    // bb.*.insts.remove(@intCast(instIDX));
                    changes = true;
                    break;
                } else {
                    // std.debug.print("inst {d} has {d} entries\n", .{ instID, entries.items.len });
                    // try newInsts.append(instID);
                }
                if (changes) break;
            }
            // bb.insts.deinit();
            // bb.insts = newInsts;
            if (changes) break;
        }
    }

    // for (fun.bbs.ids()) |bbID| {
    //     const bb = fun.bbs.get(bbID);
    //     std.debug.print("LOOK WHAT I DID TO {d} @{d} from bbID={d} {any}\n", .{ bbID, bb.insts.items() });
    // }

    // relink all of the basic blocks based off their jumps or branhces
    for (fun.bbs.ids()) |bbID| {
        fun.bbs.get(bbID).outgoers[0] = null;
        fun.bbs.get(bbID).outgoers[1] = null;
        fun.bbs.get(bbID).reinitIncomers(fun);
    }

    for (fun.bbs.ids()) |bbID| {
        if (!info.reachable[bbID]) continue;
        var bb = fun.bbs.get(bbID);
        var instID: ?IR.Function.InstID = null;
        for (bb.insts.items()) |instID_| {
            instID = instID_;
        }
        if (instID == null) continue;
        var inst = fun.insts.get(instID.?);
        if (!inst.isCtrlFlow()) continue;

        if (inst.op == .Br) {
            var br = Inst.Br.get(inst.*);
            var ifTrueBB = fun.bbs.get(br.iftrue);
            var ifFalseBB = fun.bbs.get(br.iffalse);
            bb.outgoers[0] = br.iftrue;
            bb.outgoers[1] = br.iffalse;
            try ifTrueBB.incomers.append(bbID);
            try ifFalseBB.incomers.append(bbID);
        } else if (inst.op == .Jmp) {
            var jmp = Inst.Jmp.get(inst.*);
            var jmpBB = fun.bbs.get(jmp.dest);
            bb.outgoers[0] = jmp.dest;
            try jmpBB.incomers.append(bbID);
        } else if (inst.op == .Ret) {
            // do nothing
        } else {
            utils.todo("unexpected control flow instruction {s}\n", .{@tagName(inst.op)});
        }
    }

    // remove every non reachable block from the function
    var changed: bool = true;
    while (changed) {
        changed = false;
        for (fun.bbs.ids()) |bbID| {
            if (!info.reachable[bbID]) {
                // std.debug.print("removing unreachable block {d}\n", .{bbID});
                // try remove_block_edges(fun, bbID);
                _ = fun.bbs.remove(bbID);
                changed = true;
                break;
            }
        }
    }

    return true;
}

fn cmp_prop(ir: *IR, fun: *Function) !bool {
    var arena = std.heap.ArenaAllocator.init(fun.alloc);
    defer arena.deinit();
    var alloc = arena.allocator();

    var info = try CmpProp.cmp_prop(alloc, ir, fun);

    const allReachable = for (fun.bbs.ids()) |bbID| {
        if (!info.reachable[bbID]) {
            // std.debug.print("found unreachable bb ID={d} label={s}\n", .{ bbID, fun.bbs.get(bbID).name });
            break false;
        }
    } else true;
    const noneConstant = for (info.values) |value| {
        if (value.state == .constant) {
            // std.debug.print("found constant={any}\n", .{value});
            break false;
        }
    } else true;
    if (allReachable and noneConstant) {
        return false;
    } else {
        // std.debug.print("running sccp\nnoneConstant={}\nallReachable={any}\n", .{ noneConstant, allReachable });
    }
    // update all of the registers
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
            // FIXME: made change to phi here, this could be wrong
            change_use_of_reg(fun, ir, use.bb, bb, inst, reg.*, ref);
        }
        remove_reg(fun, reg.*);
    }

    // update all of the phi nodes
    // track if a change has been made
    // while changes
    // for each one that has a entry that points to a non-reachable block, remove the block,
    //  if the phi node only has one entry, replace all uses of the phi node with the value of the entry
    //  remove the phi node
    //  mark change
    //  break
    var changes: bool = true;
    while (changes) {
        // std.debug.print("running phi node cleanup\n", .{});
        changes = false;
        for (fun.bbs.ids()) |bbID_1| {
            if (!info.reachable[bbID_1]) continue;
            // std.debug.print("running phi node cleanup for bb {d}\n", .{bbID_1});
            var bb = fun.bbs.get(bbID_1);
            // var newInsts = IR.BasicBlock.List.init(fun.alloc);
            for (bb.insts.items(), 0..) |instID, instIDX| {
                // std.debug.print("WATCH WHAT I'm ABOUT TO DO TO {d} @{d} from bbID={d} {any}\n", .{ instID, instIDX, bbID_1, bb.insts.items() });
                // defer std.debug.print("LOOK WHAT I DID TO {d} @{d} from bbID={d} {any}\n", .{ instID, instIDX, bbID_1, bb.insts.items() });
                const inst = fun.insts.get(instID);
                if (inst.op != .Phi) {
                    // try newInsts.append(instID);
                    continue;
                }
                // std.debug.print("running phi node cleanup for inst {d}\n", .{instID});

                var bbInsts = &bb.insts.list;
                var bbLen = &bb.insts.len;

                var phi = Inst.Phi.get(inst.*);
                var phiReg = fun.regs.getPtr(phi.res.i);
                var entries = phi.entries;
                var entries_changes: bool = true;
                var entreies_changed: bool = false;
                // remove any entries that point to a non-reachable block
                while (entries_changes) {
                    // std.debug.print("running phi node cleanup for inst {d} with entries {any}\n", .{ instID, entries.items });
                    entries_changes = false;
                    for (entries.items, 0..) |entry, entryI| {
                        if (!info.reachable[entry.bb]) {
                            // remove the entry
                            // std.debug.print("removing entry {d} from phi node {d} in block {d}\n", .{ entryI, instID, bbID_1 });
                            entries_changes = true;
                            _ = entries.orderedRemove(entryI);
                            entreies_changed = true;
                            break;
                        }
                    }
                }
                phi.entries = entries;
                fun.insts.set(instID, phi.toInst());
                if (entreies_changed) {
                    changes = true;
                    break;
                }

                if (entries.items.len == 0) {
                    // remove the phi node
                    //_ = fun.insts.remove(instID);
                    // std.debug.print("removing empty phi node {d} in block {d}\n", .{ instID, bbID_1 });
                    _ = bbInsts.*.orderedRemove(instIDX);
                    bbLen.* -= 1;
                    // bb.*.insts.remove(@intCast(instIDX));
                    changes = true;
                    break;
                } else if (entries.items.len == 1) {
                    // std.debug.print("replacing phi node {d} in block {d} with entry {any}\n", .{ instID, bbID_1, entries.items[0].ref });
                    // replace all uses of the phi node with the value of the entry
                    const ref = &entries.items[0].ref;
                    try replace_all_uses(fun, ir, phiReg, ref.*, info.reachable);
                    // remove the phi node
                    // _ = fun.insts.remove(instID);
                    utils.assert(std.mem.indexOfScalar(BBID, bb.insts.items(), instID) != null, "bb has no inst {d}\n", .{instID});
                    // std.debug.print("WATCH ME REMOVE {d} @{d} from bbID={d} {any}\n", .{ instID, instIDX, bbID_1, bb.insts.items() });
                    _ = bbInsts.*.orderedRemove(instIDX);
                    bbLen.* -= 1;
                    // bb.*.insts.remove(@intCast(instIDX));
                    changes = true;
                    break;
                } else {
                    // std.debug.print("inst {d} has {d} entries\n", .{ instID, entries.items.len });
                    // try newInsts.append(instID);
                }
                if (changes) break;
            }
            // bb.insts.deinit();
            // bb.insts = newInsts;
            if (changes) break;
        }
    }

    // for (fun.bbs.ids()) |bbID| {
    //     const bb = fun.bbs.get(bbID);
    //     std.debug.print("LOOK WHAT I DID TO {d} @{d} from bbID={d} {any}\n", .{ bbID, bb.insts.items() });
    // }

    // relink all of the basic blocks based off their jumps or branhces
    for (fun.bbs.ids()) |bbID| {
        fun.bbs.get(bbID).outgoers[0] = null;
        fun.bbs.get(bbID).outgoers[1] = null;
        fun.bbs.get(bbID).reinitIncomers(fun);
    }

    for (fun.bbs.ids()) |bbID| {
        if (!info.reachable[bbID]) continue;
        var bb = fun.bbs.get(bbID);
        var instID: ?IR.Function.InstID = null;
        for (bb.insts.items()) |instID_| {
            instID = instID_;
        }
        if (instID == null) continue;
        var inst = fun.insts.get(instID.?);
        if (!inst.isCtrlFlow()) continue;

        if (inst.op == .Br) {
            var br = Inst.Br.get(inst.*);
            var ifTrueBB = fun.bbs.get(br.iftrue);
            var ifFalseBB = fun.bbs.get(br.iffalse);
            bb.outgoers[0] = br.iftrue;
            bb.outgoers[1] = br.iffalse;
            try ifTrueBB.incomers.append(bbID);
            try ifFalseBB.incomers.append(bbID);
        } else if (inst.op == .Jmp) {
            var jmp = Inst.Jmp.get(inst.*);
            var jmpBB = fun.bbs.get(jmp.dest);
            bb.outgoers[0] = jmp.dest;
            try jmpBB.incomers.append(bbID);
        } else if (inst.op == .Ret) {
            // do nothing
        } else {
            utils.todo("unexpected control flow instruction {s}\n", .{@tagName(inst.op)});
        }
    }

    // remove every non reachable block from the function
    var changed: bool = true;
    while (changed) {
        changed = false;
        for (fun.bbs.ids()) |bbID| {
            if (!info.reachable[bbID]) {
                // std.debug.print("removing unreachable block {d}\n", .{bbID});
                // try remove_block_edges(fun, bbID);
                _ = fun.bbs.remove(bbID);
                changed = true;
                break;
            }
        }
    }

    return true;
}

fn replace_all_uses(fun: *Function, ir: *const IR, reg: *Reg, ref: Ref, reachable: []bool) !void {
    // for each use of the register
    //  get the instruction and the basic block
    //  change the ref in the inst to the new ref
    //  remove the register
    var visited = try fun.alloc.alloc(bool, @intCast(fun.bbs.len + fun.bbs.removed));
    defer fun.alloc.free(visited);
    @memset(visited, false);
    // for every basic block in the function, check all of the instructions to see if they use the register
    for (fun.bbs.ids()) |bbID| {
        if (!reachable[bbID]) continue;
        var bb = fun.bbs.get(bbID);
        for (bb.insts.items()) |instID| {
            var inst = fun.insts.get(instID);
            if (!SCCP.inst_uses_reg(inst.*, reg.*)) continue;
            // print out the reg's block, and the ref's block
            // var regOfRef = fun.regs.get(ref.i);
            // std.debug.print("replacing all uses of reg {d} in block {d} with ref {any}\n", .{ reg.bb, bbID, regOfRef.bb, ref });
            _ = change_use_of_reg(fun, ir, bbID, bb, inst, reg.*, ref);
        }
    }
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

fn change_use_of_reg(fun: *Function, ir: *const IR, bbID: BBID, bb: *BasicBlock, inst: *Inst, reg: Reg, ref: Ref) void {
    _ = bb;
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
            if (refers_to_reg(misc.from, reg)) {
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
            var found: bool = false;
            for (phi.entries.items) |*entry| {
                if (refers_to_reg(entry.*.ref, reg)) {
                    entry.ref = ref;
                    found = true;
                }
            }
            inst.* = phi.toInst();
            if (found) return;
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
                    // remove_bb_from_outgoers(bb, removed_outgoer_id);
                    // update phi entries in the not taken branch
                    var not_taken_bb = fun.bbs.get(removed_outgoer_id);
                    try remove_bb_from_bb2_phi_entries(fun, bbID, not_taken_bb, removed_outgoer_id);
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
    _ = insts;

    // for (bbs.items(), bbs.ids()) |bb, bbID| {
    //     std.debug.print("BEFOR bb [{d}] {s} incomers: {any}\n", .{ bbID, bb.name, bb.incomers.items });
    //     std.debug.print("BEFOR bb [{d}] {s} outgoers: {any}\n", .{ bbID, bb.name, bb.outgoers });
    // }
    save_dot_to_file(ir, "pre_remove_edges.dot") catch {};

    utils.assert(@as(usize, @intCast(bbs.len)) == reachable.len, "mismatch in block count", .{});
    // for (reachable, 0..) |r, i| {
    //     const bbID = bbs.ids()[i];
    //     std.debug.print("[{d}] {s} - {any}\n", .{ bbID, stringify_label(fun, bbID), r });
    // }

    // removes the edges from blocks that are unreachable
    for (bbs.ids()) |bbID| {
        var is_reachable = reachable[bbID];
        if (is_reachable) {
            continue;
        }
        // std.debug.print("remove_unreachable: removing edges from block {s} with incomers {any} and outgoers {any}\n", .{
        //     stringify_label(fun, bbID),
        //     bbs.get(bbID).incomers.items,
        //     bbs.get(bbID).outgoers,
        // });
        try remove_block_edges(fun, bbID);
        const bb = bbs.get(bbID);
        bb.incomers.clearAndFree();
        bb.*.outgoers = [_]?BBID{ null, null };
    }
    // for (bbs.items(), bbs.ids()) |bb, bbID| {
    //     std.debug.print("AFTER bb [{d}] {s} incomers: {any}\n", .{ bbID, bb.name, bb.incomers.items });
    //     std.debug.print("AFTER bb [{d}] {s} outgoers: {any}\n", .{ bbID, bb.name, bb.outgoers });
    //     std.debug.print("br = {any}\n", .{(insts.get((ptr_to_last(BBID, bb.insts.list.items) orelse unreachable).*)).*});
    // }

    save_dot_to_file(ir, "post_remove_edges.dot") catch {};

    var ids = try alloc.alloc(BBID, reachable.len);
    @memcpy(ids, bbs.ids());

    for (ids) |bbID| {
        var is_reachable = reachable[bbID];
        if (is_reachable) {
            continue;
        }
        // std.debug.print("i-{d} ids-{d} bbID-{d}\n", .{ id, bbs.ids.items[id], bbID });
        // std.debug.print("i-{d} bbID-{d}\n", .{ id, bbID });

        // if (id == 5) bbs.remove(bbID);
        // std.debug.print("WATCH ME DELETE {d}\n", .{bbID});
        // std.debug.print("[{d}] {s} - {any}\n", .{ bbID, stringify_label(fun, bbID), is_reachable });
        _ = bbs.remove(bbID);
    }

    save_dot_to_file(ir, "post_remove_unreachable.dot") catch {};
}
fn printIncomersAndOutgoers(bb: *BasicBlock) void {
    std.debug.print("Block {s} Incomers: {any}\n", .{ bb.name, bb.incomers.items });
    std.debug.print("Block {s} Outgoers: {any}\n", .{ bb.name, bb.outgoers });
}
// given a block remove itself from its predecessors and successors, and re-link the predecessors to the successors
// removing phi entries that reference to itself,
fn remove_block_edges(fun: *Function, bbID: BBID) !void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    const bb = bbs.get(bbID);
    // brute_force_remove_block_edges(fun, bbID);
    // brute_force_remove_phi_entires_referencing_dead_bb(fun, bbID);

    if (bb_num_outgoers(bb) == 2) {
        // std.debug.print("remove_block_edges: removing bb {s} with 2 outgoers {any} and these incomers {any}\n", .{ bb.name, bb.outgoers, bb.incomers.items });
        var self_ref: BBID = undefined;
        if (try is_self_ref(fun, bbID, bb.outgoers[0].?)) {
            // std.debug.print("self ref detected at 0 ={?d} in {s}\n", .{ bb.outgoers[0], bb.name });
            self_ref = bb.outgoers[0].?;
            // const outgoer = bbs.get(outgoerID);
            // remove_bb_from_incomers(outgoer, bbID);
            // remove_bb_from_outgoers(outgoer, bbID);
        } else if (try is_self_ref(fun, bbID, bb.outgoers[1].?)) {
            // std.debug.print("self ref detected at 1 ={?d} in {s}\n", .{ bb.outgoers[1], bb.name });
            self_ref = bb.outgoers[1].?;
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
            // std.debug.print("incomer={d} op={s}\n", .{ incomer, @tagName(incomerBR.*.op) });

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
        if (bbID != fun.exitBBID and bb_num_outgoers(bb) == 0) {
            // std.debug.print("removing {d} from incomers of {s} {any}\n", .{ bbID, bb.name, bb.incomers.items });
            for (bb.incomers.items) |incomerID| {
                var incomerBB = bbs.get(incomerID);
                remove_bb_from_outgoers(incomerBB, bbID);
                remove_bb_from_incomers(bb, incomerID);
            }
            return;
        }

        utils.assert(bb_num_outgoers(bb) != 2, "FUCK - FELL THROUGH this case should be handled above\n", .{});
        // printIncomersAndOutgoers(bb);
        // std.debug.print("we only have one outgoer\n", .{});
        const outgoer = if (bb.outgoers[0]) |out| out else if (bb.outgoers[1]) |out| out else unreachable;

        var outgoerBB = bbs.get(outgoer);
        // link parent to child
        for (bb.incomers.items) |incomer| {
            var incomerBB = bbs.get(incomer);
            var incomerBRID = (ptr_to_last(InstID, incomerBB.insts.list.items) orelse unreachable).*;
            var incomerBR = insts.get(incomerBRID);

            if (try is_self_ref(fun, incomer, bbID)) {
                remove_bb_from_outgoers(incomerBB, bbID);
                continue;
            }

            // std.debug.print("incomer={d} op={s}\n", .{ incomer, @tagName(incomerBR.*.op) });

            _ = replace_branches_to_with(incomerBR, bbID, outgoer);
            // replace_bb_in_outgoers_with(incomerBB, bbID, outgoer);
            replace_bb_in_incomers_with(outgoerBB, bbID, incomer);
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
    // std.debug.print("removing {d} from outgoers of {s} {any}\n", .{ toRemoveBBID, fromBB.name, fromBB.outgoers });
    const outgoers = &fromBB.outgoers;
    for (outgoers) |*outgoerID| {
        if (outgoerID.* != null and outgoerID.* == toRemoveBBID) {
            outgoerID.* = null;
        }
    }
    // std.debug.print("outgoers after removing {d} from {s} = {any}\n", .{ toRemoveBBID, fromBB.name, fromBB.outgoers });
}

fn remove_phi_entires_in_children_of_dead_bb(fun: *Function, bb: *BasicBlock, bbID: BBID) !void {
    var visited = try fun.alloc.alloc(bool, @intCast(fun.bbs.len + fun.bbs.removed));
    defer fun.alloc.free(visited);
    @memset(visited, false);
    visited[bbID] = true;
    remove_phi_entires_in_children_of_dead_bb_inner(fun, bb, bbID, visited);
}

fn remove_phi_entires_in_children_of_dead_bb_inner(fun: *Function, bb: *BasicBlock, bbID: BBID, visited: []bool) void {
    const bbs = &fun.bbs;
    for (bb.outgoers, 0..) |maybe_outgoerID, outgoer_index| {
        if (maybe_outgoerID == null) continue;
        const outgoerID = maybe_outgoerID.?;
        if (!bbs.list.contains(outgoerID)) {
            log.warn("outgoer {d} not found in bbs but in {s} outgoers\n", .{ outgoerID, stringify_label(fun, bbID) });
            bb.*.outgoers[outgoer_index] = null;
            continue;
        }
        var outgoer = bbs.get(outgoerID);
        try remove_bb_from_bb2_phi_entries(fun, bbID, outgoer, outgoerID);
        if (!visited[outgoerID]) {
            visited[outgoerID] = true;
            remove_phi_entires_in_children_of_dead_bb_inner(fun, outgoer, bbID, visited);
        }
    }
}
pub fn remove_bb_from_bb2_phi_entries(fun: *Function, bbID: BBID, bb2: *BasicBlock, bb2ID: BBID) !void {
    _ = bb2ID;
    const insts = &fun.insts;
    for (bb2.insts.items()) |instID| {
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
                // std.debug.print("[{d}] {s} removing entry referencing {s}\n", .{
                //     bb2ID,
                //     stringify_label(fun, bb2ID),
                //     stringify_label(fun, bbID),
                // });
                _ = entries.orderedRemove(i);
            } else {
                i += 1;
            }
        }
        inst.* = phi.toInst();
    }
    // std.debug.print("removed phis from [{d}] {s}\n", .{ bb2ID, bb2.name });
}

fn brute_force_remove_block_edges(fun: *Function, badBBID: BBID) void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;
    _ = insts;

    for (bbs.ids()) |bbID| {
        const bb = bbs.get(bbID);
        // std.debug.print("removing {d} from incomers of {s} {any}\n", .{ badBBID, bb.name, bb.incomers.items });
        remove_bb_from_incomers(bb, badBBID);
        remove_bb_from_outgoers(bb, badBBID);
    }
}

fn brute_force_remove_phi_entires_referencing_dead_bb(fun: *Function, badBBID: BBID) void {
    const bbs = &fun.bbs;
    const insts = &fun.insts;

    for (bbs.items(), bbs.ids()) |*bb, bbID| {
        _ = bbID;
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
                    // std.debug.print("[{d}] {s} brute force removing entry referencing {s}\n", .{
                    //     bbID,
                    //     stringify_label(fun, bbID),
                    //     stringify_label(fun, badBBID),
                    // });
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

fn is_self_ref(fun: *const Function, selfBBID: BBID, outgoerBBID: BBID) !bool {
    var visited = try fun.alloc.alloc(bool, @intCast(fun.bbs.len + fun.bbs.removed));
    return is_self_ref_rec(fun, selfBBID, outgoerBBID, visited);
}

fn is_self_ref_rec(fun: *const Function, selfBBID: BBID, outgoerBBID: BBID, visited: []bool) bool {
    if (outgoerBBID == selfBBID) {
        return true;
    }
    if (visited[outgoerBBID]) {
        return false;
    }
    visited[outgoerBBID] = true;
    const outgoerBB = fun.bbs.get(outgoerBBID);
    for (outgoerBB.outgoers) |maybe_outgoerID| {
        if (maybe_outgoerID == null) continue;
        const outgoerOutgoerBBID = maybe_outgoerID.?;
        if (outgoerOutgoerBBID == selfBBID) {
            return true;
        }
        if (is_self_ref_rec(fun, selfBBID, outgoerOutgoerBBID, visited)) {
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

        // std.debug.print("trying to remove edges from block {s} with incomers {any} and outgoers {any}\n", .{
        //     stringify_label(fun, bbID),
        //     bb.incomers.items,
        //     bb.outgoers,
        // });
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
            // std.debug.print("skipping removing edges from block {s} because no incomers\n", .{
            //     stringify_label(fun, bbID),
            // });
            continue;
        }
        if (bb_num_outgoers(bb) == 0) {
            // std.debug.print("skipping removing edges from block {s} because no outgoers\n", .{
            //     stringify_label(fun, bbID),
            // });
            continue;
        }
        if (any_phi_depends_on_bb(fun, bbID)) {
            continue;
        }
        utils.assert(bbID != fun.exitBBID, "exit block should not be removed\n", .{});
        utils.assert(bbID != Function.entryBBID, "entry block should not be removed\n", .{});

        // std.debug.print("removing edges from block {s}\n", .{
        //     stringify_label(fun, bbID),
        // });
        // NOTE: this use of undefined is only okay because we only have 1 outgoer
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

/// WARN: this is pathologically inefficient
fn any_phi_depends_on_bb(fun: *const Function, bbID: BBID) bool {
    for (fun.bbs.items()) |bb| {
        for (bb.insts.items()) |instID| {
            const inst = fun.insts.get(instID);
            if (inst.op != .Phi) {
                continue;
            }
            var phi = Inst.Phi.get(inst.*);
            for (phi.entries.items) |entry| {
                if (entry.bb == bbID) {
                    return true;
                }
            }
        }
    }
    return false;
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
        inline for (passes, 0..) |pass, pass_no| {
            switch (pass) {
                .sccp => {
                    const changed = try sccp(&ir, fun);
                    // if (changed)
                    log.trace("sccp changed the IR in pass {d}={any}\n", .{ pass_no, changed });
                    try save_dot_to_file(&ir, "sccp.dot");
                },
                .cmp => {
                    const changed = try cmp_prop(&ir, fun);
                    // if (changed)
                    log.trace("cmp changed the IR in pass {d}={any}\n", .{ pass_no, changed });
                    try save_dot_to_file(&ir, "sccp.dot");
                },
                .empty_bb => {
                    try empty_block_removal_pass(fun);
                    try save_dot_to_file(&ir, "empty.dot");
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
        .{ "main", .{ .sccp, .sccp, .empty_bb } },
    });
}

test "no-panics-in-fib" {
    log.empty();
    errdefer log.print();
    const in = "fun fib(int n) int { if(n <= 1) { return n;} return fib(n-1) + fib(n-2);} fun main() void { int a; a = fib(20); print a endl; }";
    var ir = try testMe(in);
    try save_dot_to_file(&ir, "pre_fib.dot");
    _ = try sccp(&ir, try ir.getFun(try ir.getIdentID("fib")));
    try save_dot_to_file(&ir, "post_fib.dot");
    const str = try ir.stringify_cfg(testAlloc, .{ .header = true });
    try std.fs.cwd().writeFile("fib.ll", str);
    // std.debug.print("CHANGED={any}\n", .{changed});
    log.trace("FIB\n{s}\n", .{str});
}

fn sccp_all_funs(ir: *IR) !void {
    const funs = ir.funcs.items.items;
    for (funs) |*fun| {
        _ = try sccp(ir, fun);
    }
}

test "no-panics-in-killer-bubs" {
    log.empty();
    errdefer log.print();
    const in = @embedFile("../../test-suite/tests/milestone2/benchmarks/killerBubbles/killerBubbles.mini");
    var ir = try testMe(in);
    try save_dot_to_file(&ir, "pre_bubs.dot");
    try sccp_all_funs(&ir);

    try save_dot_to_file(&ir, "post_bubs.dot");
    const str = try ir.stringify_cfg(testAlloc, .{ .header = true });
    try std.fs.cwd().writeFile("bubs.ll", str);
    // std.debug.print("CHANGED={any}\n", .{changed});
    log.trace("KILLER BUBS\n{s}\n", .{str});
}
