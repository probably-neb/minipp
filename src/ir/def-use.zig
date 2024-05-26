const std = @import("std");
const Alloc = std.mem.Allocator;
const ArrayList = std.ArrayList;

const utils = @import("../utils.zig");
const log = @import("../log.zig");

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

const IMMEDIATE_FALSE = IR.InternPool.FALSE;
const IMMEDIATE_TRUE = IR.InternPool.TRUE;
const IMMEDIATE_ZERO = IR.InternPool.ZERO;
const IMMEDIATE_ONE = IR.InternPool.ONE;

/// A usage of a register we updated the value of
/// A member of the SSA edge worklist
/// NOTE: we didn't necessarily update the value to a constant
pub const RegUsage = struct {
    bb: BBID,
    instID: InstID,
};

/// Push reachable usages of a register to the ssa worklist
pub fn uses_of(alloc: Alloc, fun: *const Function, reg: Reg) !ArrayList(RegUsage) {
    var visited = try alloc.alloc(bool, @intCast(fun.bbs.len));
    defer alloc.free(visited);
    @memset(visited, false);

    var uses = ArrayList(RegUsage).init(alloc);
    try uses_of_in_bb(fun, reg, reg.bb, &uses, visited);
    return uses;
}

/// The inner function of reachable_uses_of
/// Pushes all uses
fn uses_of_in_bb(fun: *const Function, reg: Register, bbID: BBID, uses: *ArrayList(RegUsage), visited: []bool) !void {
    visited[bbID] = true;
    const bb = fun.bbs.get(bbID);
    const insts = &fun.insts;
    var instructionIDs = bb.insts.items();
    if (reg.bb == bbID) {
        // use slice from reg inst to end of bb
        const regInstID = reg.inst;
        const regInstIndex = std.mem.indexOfScalar(BBID, instructionIDs, regInstID) orelse {
            utils.impossible(
                "register {any} in bb {s} inst does not point to an inst in the bb.\ninst={d}\nbb inst IDS={any}\ninst={any}\n",
                .{ reg, bb.name, reg.inst, instructionIDs, fun.insts.get(regInstID) },
            );
        };
        utils.assert(
            regInstIndex + 1 < instructionIDs.len,
            "regInstIndex is last index in bb. Last inst in bb should be control flow not register assignment\nbb={s}\ninst={any}\n",
            .{ bb.name, instructionIDs[regInstIndex] },
        );
        instructionIDs = instructionIDs[regInstIndex + 1 ..];
    }

    var inst: Inst = undefined;
    instLoop: for (instructionIDs) |instID| {
        inst = insts.get(instID).*;
        if (!inst_uses_reg(inst, reg)) {
            continue :instLoop;
        }
        const usage = RegUsage{
            .bb = bbID,
            .instID = instID,
        };
        try uses.append(usage);
    }
    utils.assert(inst.isCtrlFlow(), "block does not end with ctrl flow statement (or possibly block is empty)\n", .{});

    switch (inst.op) {
        // no more blocks to check from ret
        .Ret => {},
        .Jmp => {
            const jmp = Inst.Jmp.get(inst);
            if (!visited[jmp.dest]) {
                return try uses_of_in_bb(
                    fun,
                    reg,
                    jmp.dest,
                    uses,
                    visited,
                );
            }
        },
        .Br => {
            const br = Inst.Br.get(inst);
            if (!visited[br.iftrue]) {
                try uses_of_in_bb(
                    fun,
                    reg,
                    br.iftrue,
                    uses,
                    visited,
                );
            }
            if (!visited[br.iffalse]) {
                return try uses_of_in_bb(
                    fun,
                    reg,
                    br.iffalse,
                    uses,
                    visited,
                );
            }
        },
        else => unreachable,
    }
}

fn inst_uses_reg(inst: Inst, reg: Reg) bool {
    return switch (inst.op) {
        .Binop => {
            const binop = Inst.Binop.get(inst);
            return either_refers_to_reg(binop.lhs, binop.rhs, reg);
        },
        .Cmp => {
            const cmp = Inst.Cmp.get(inst);
            return either_refers_to_reg(cmp.lhs, cmp.rhs, reg);
        },
        .Zext, .Sext, .Trunc, .Bitcast => {
            const misc = Inst.Misc.get(inst);
            return refers_to_reg(misc.from, reg);
        },
        .Load => {
            const load = Inst.Load.get(inst);
            return refers_to_reg(load.ptr, reg);
        },
        .Gep => {
            const gep = Inst.Gep.get(inst);
            return either_refers_to_reg(gep.ptrVal, gep.index, reg);
        },
        .Call => {
            const call = Inst.Call.get(inst);
            for (call.args) |arg| {
                if (refers_to_reg(arg, reg)) {
                    return true;
                }
            }
            return false;
        },
        .Phi => {
            const phi = Inst.Phi.get(inst);
            for (phi.entries.items) |entry| {
                if (refers_to_reg(entry.ref, reg)) {
                    return true;
                }
            }
            return false;
        },
        .Ret => {
            const ret = Inst.Ret.get(inst);
            return refers_to_reg(ret.val, reg);
        },
        .Store => {
            const store = Inst.Store.get(inst);
            return either_refers_to_reg(store.from, store.to, reg);
        },
        .Br => {
            const br = Inst.Br.get(inst);
            return refers_to_reg(br.on, reg);
        },
        // no registers
        .Alloc, .Param, .Jmp => false,
    };
}

fn refers_to_reg(ref: Ref, reg: Reg) bool {
    return switch (ref.kind) {
        .local => ref.i == reg.id,
        else => false,
    };
}

/// Thanks zig lsp for putting stuff past 120 characters
inline fn either_refers_to_reg(a: Ref, b: Ref, reg: Reg) bool {
    return refers_to_reg(a, reg) or refers_to_reg(b, reg);
}
