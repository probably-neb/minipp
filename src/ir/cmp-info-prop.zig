const std = @import("std");
const Alloc = std.mem.Allocator;
const ArrayList = std.ArrayList;
pub const BitSet = std.bit_set.DynamicBitSetUnmanaged;

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

const Dominance = @import("dominance.zig").Dominance;
const genDominance = @import("dominance.zig").genLazyDominance;

const IMMEDIATE_FALSE = IR.InternPool.FALSE;
const IMMEDIATE_TRUE = IR.InternPool.TRUE;
const IMMEDIATE_ZERO = IR.InternPool.ZERO;
const IMMEDIATE_ONE = IR.InternPool.ONE;

const Values = []Value;

pub const SCCPRes = struct {
    /// a LUT where values[reg.id] indicates
    /// the computed value of the register
    /// if it is constant the inst+reg should be removed and
    /// downstream uses should be updated
    values: []Value,
    /// a LUT where reachable[bb.id] indicates
    /// if the block is reachable or can be removed
    reachable: []bool,
    pub fn empty() SCCPRes {
        return .{
            .values = undefined,
            .reachable = undefined,
        };
    }

    pub fn eq(self: SCCPRes, other: SCCPRes) bool {
        if (self.values.len != other.values.len) {
            return false;
        }
        if (self.reachable.len != other.reachable.len) {
            return false;
        }
        for (self.values, 0..) |val, i| {
            if (!val.eq(other.values[i])) {
                return false;
            }
        }
        for (self.reachable, 0..) |reach, i| {
            if (reach != other.reachable[i]) {
                return false;
            }
        }
        return true;
    }
};
/// Sparse Conditional Constant Propagation
// TODO: make this run on a single function
////
/// PSUEDOCODE:
///
/// ⊤ := undefined
/// ⊥ := unknown (i.e. result of operation on undefined)
/// !(⊤ | ⊥) := constant
///
/// SSAWorklist = ∅
/// CFGWorklist = {entry}
/// for each block b
///     mark b as unreachable
///     for each op
///         Value(op) = ⊤
/// while CFGWorkList != ∅  SSAWorkList != ∅
///     if b := CFGWorklist.pop()
///         reachable[b] = true
///         for phi in b
///             visit_phi
///         for op in b
///             values(op) = eval_op
///     if <u,v> := SSAWorklist.pop()
///         // u := def, v := use
///         o := res of inst using v
///         if value[o] != ⊥
///             t <- eval_op
///             if t != value[o]
///                 value[o] = t
///                 for each ssa edge e := <o, x>
///                     if reachable[block of x]
///                         SSAWorklist.push(e)
///
/// visit_phi [x := phi(y, z)] -> Value[x] = y /\ z
/// eval_op [x := y op z] -> if value[y] != ⊥ & value(z) != ⊥ then value[x] <- interp y op z
/// eval_branch [cbr r1 -> b1,b2] ->
///     if r1 = ⊥ or r1 = true
///         if !reachable[b1]
///             CFGWorklist.push(b1)
///     if r1 = ⊥ or r1 = false
///         if !reachable[b2]
///             CFGWorklist.push(b2)
/// eval_jmp [jmp b1] ->
///     if !reachable[b1]
///         CFGWorklist.push(b1)
pub fn cmp_prop(alloc: Alloc, ir: *const IR, fun: *const Function) !SCCPRes {
    var reachable = exec: {
        var reachable = try alloc.alloc(bool, @intCast(fun.bbs.len + fun.bbs.removed));
        @memset(reachable, false);
        break :exec reachable;
    };
    var values = values: {
        const numValues: usize = @intCast(fun.regs.len);
        var values = try alloc.alloc(Value, numValues);
        @memset(values, Value.undef());
        break :values values;
    };
    var cmp_info = cmp_info: {
        var cmp_info = try alloc.alloc(?CmpInfo, @intCast(fun.regs.len));
        @memset(cmp_info, null);
        break :cmp_info cmp_info;
    };
    var bbWL = bbwl: {
        var bbwl = ArrayList(BBID).init(alloc);
        try bbwl.append(Function.entryBBID);
        break :bbwl bbwl;
    };
    var ssaWL = ArrayList(SSAEdge).init(alloc);

    const dominance = try genDominance(ir, fun);

    const insts = &fun.insts;
    const regs = &fun.regs;

    std.debug.print("starting\n", .{});
    main_loop: while (bbWL.items.len > 0 or ssaWL.items.len > 0) {
        if (bbWL.popOrNull()) |bbID| {
            // std.debug.print("BBID={d}\n", .{bbID});
            if (reachable[bbID]) {
                // in this context means we already handled the block
                // updates to values in this block will be handled by
                // ssaWL
                continue :main_loop;
            }
            reachable[bbID] = true;

            const bb = fun.bbs.get(bbID);
            const instructionIDs = bb.insts.items();
            // const phiInstructionIDs = bb.phiInsts.items;
            //
            // for (phiInstructionIDs) |phiInstID| {
            //     // visit_phi [x := phi(y, z)] -> Value[x] = y /\ z
            //     const inst = insts.get(phiInstID).*;
            //     utils.assert(inst.op == .Phi, "phi inst not phi??? ({s} instead) wtf dylan!\n", .{@tagName(inst.op)});
            //     const phi = Inst.Phi.get(inst);
            //
            //     const res = phi.res;
            //     utils.assert(res.kind == .local, "phi res not local is {s}\n", .{@tagName(res.kind)});
            //
            //     // WARN: these are supposed to be evaluated
            //     // simultaneously (i.e. results of one would not impact others)
            //     // but I can't think of a case where the result is
            //     // different than just going one by one
            //     // and we shouldn't get cases where one depends on another
            //     const phi_entries = phi.entries.items;
            //     const value = if (phi_entries.len == 1) single: {
            //         break :single ref_value(ir, phi_entries[0].ref, values);
            //     } else if (phi_entries.len == 0) none: {
            //         // FIXME: is this logically sound?
            //         break :none Value.undef();
            //     } else len_gt_1: {
            //         var value: Value = ref_value(ir, phi_entries[0].ref, values);
            //         for (phi_entries[1..]) |option| {
            //             // TODO: assert not depending on phi in same bb
            //             const ref = option.ref;
            //             const optionValue = ref_value(ir, ref, values);
            //             value = meet(value, optionValue);
            //         }
            //         break :len_gt_1 value;
            //     };
            //     utils.assert(res.kind == .local, "inst res is local got {any}\n", .{res});
            //     const reg = regs.get(res.i);
            //     values[reg.id] = value;
            //     try add_reachable_uses_of(fun, reg, &ssaWL, reachable);
            // }

            for (instructionIDs) |instID| {
                const inst = insts.get(instID).*;
                if (inst.op == .Phi) {
                    // visit_phi [x := phi(y, z)] -> Value[x] = y /\ z
                    utils.assert(inst.op == .Phi, "phi inst not phi??? ({s} instead) wtf dylan!\n", .{@tagName(inst.op)});
                    const phi = Inst.Phi.get(inst);

                    const res = phi.res;
                    utils.assert(res.kind == .local, "phi res not local is {s}\n", .{@tagName(res.kind)});

                    // WARN: these are supposed to be evaluated
                    // simultaneously (i.e. results of one would not impact others)
                    // but I can't think of a case where the result is
                    // different than just going one by one
                    // and we shouldn't get cases where one depends on another
                    const phi_entries = phi.entries.items;
                    const value = if (phi_entries.len == 1) single: {
                        break :single ref_value(ir, phi_entries[0].ref, values);
                    } else if (phi_entries.len == 0) none: {
                        // FIXME: is this logically sound?
                        break :none Value.undef();
                    } else len_gt_1: {
                        var value: Value = ref_value(ir, phi_entries[0].ref, values);
                        for (phi_entries[1..]) |option| {
                            // TODO: assert not depending on phi in same bb
                            const ref = option.ref;
                            const optionValue = ref_value(ir, ref, values);
                            value = meet(value, optionValue);
                        }
                        break :len_gt_1 value;
                    };
                    utils.assert(res.kind == .local, "inst res is local got {any}\n", .{res});
                    const reg = regs.get(res.i);
                    values[reg.id] = value;
                    try add_reachable_uses_of(fun, reg, &ssaWL, reachable);
                }
                if (inst.op == .Br) {
                    const br = Inst.Br.get(inst);
                    const on = ref_value(ir, br.on, values);

                    const ifthen = br.iftrue;
                    const ifelse = br.iffalse;

                    if (on.state == .unknown or on.is_bool(true)) {
                        if (!reachable[ifthen]) {
                            try bbWL.append(ifthen);
                        }
                    }
                    if (on.state == .unknown or on.is_bool(false)) {
                        if (!reachable[ifelse]) {
                            try bbWL.append(ifelse);
                        }
                    }
                    continue;
                }
                if (inst.op == .Jmp) {
                    const jmp = Inst.Jmp.get(inst);
                    const to = jmp.dest;
                    if (!reachable[to]) {
                        try bbWL.append(to);
                    }
                    continue;
                }
                if (try eval(ir, inst, values)) |orig_inst_value| {
                    utils.assert(!std.meta.eql(inst.res, Ref.default), "inst with value has no res {any}\n", .{inst});
                    var inst_value = orig_inst_value;
                    if (inst.op == .Cmp) {
                        inst_value = try apply_cmp_info(ir, fun, &dominance, inst, values, cmp_info, inst_value);
                    }
                    const res = inst.res;
                    utils.assert(res.kind == .local, "inst res is local got {any}\n", .{res});
                    const reg = regs.get(res.i);
                    values[reg.id] = inst_value;
                    // print out the instruction and the new value
                    // std.debug.print("inst {any} -> {any}\n", .{ inst, inst_value });
                    try add_reachable_uses_of(fun, reg, &ssaWL, reachable);
                }
            }
        }
        // if <u,v> := SSAWorklist.pop()
        //     // u := def, v := use
        //     o := res of inst using v
        //     if value[o] != ⊥
        //         t <- eval_op
        //         if t != value[o]
        //             value[o] = t
        //             for each ssa edge e := <o, x>
        //                 if reachable[block of x]
        //                     SSAWorklist.push(e)
        if (ssaWL.popOrNull()) |ssaEdge| {
            const bb = ssaEdge.bb;
            _ = bb;
            const instID = ssaEdge.instID;
            const inst = insts.get(instID).*;
            if (!has_res(inst.op)) {
                continue :main_loop;
            }
            const res = inst.res;
            const res_val = ref_value(ir, res, values);
            if (res_val.state == .unknown) {
                // FIXME: should probably still apply cmp info here

                // cannot assume we can know the unknowable things
                // of generations past
                // such is life
                // r/im15andthisisdeep
                continue :main_loop;
            }
            var new_res_val = try eval(ir, inst, values) orelse {
                utils.impossible(
                    \\result of ssa edge eval is null, this should have been handled in the prechecks right???
                    \\inst={any}
                ,
                    .{inst},
                );
            };
            if (inst.op == .Cmp) {
                new_res_val = try apply_cmp_info(ir, fun, &dominance, inst, values, cmp_info, new_res_val);
            }
            if (std.meta.eql(res_val, new_res_val)) {
                // no new info
                continue :main_loop;
            }
            utils.assert(res.kind == .local, "inst res is local got {any}\n", .{res});
            const reg = regs.get(res.i);
            values[reg.id] = new_res_val;
            // dbg_new_val(ir, fun, reg, new_res_val);

            try add_reachable_uses_of(fun, reg, &ssaWL, reachable);
        }
    }

    // never remove entry and exit
    reachable[fun.exitBBID] = true;
    reachable[Function.entryBBID] = true;

    return .{
        .values = values,
        .reachable = reachable,
    };
}

fn dbg_new_val(ir: *const IR, fun: *const Function, reg: Reg, val: Value) void {
    std.debug.print("{s} <- [{?any}]\n", .{
        std.mem.trim(u8, @import("stringify_phi.zig").stringify_inst_to_str(
            reg.inst,
            ir,
            fun,
            fun.bbs.get(reg.bb).*,
        ) catch unreachable, "\n"),
        val.constant,
    });
}

const CmpInfo = struct {
    /// The comparison operator used
    cond: OpCode.Cond,
    /// The register result of the operand
    /// Will always be a register (.kind == .local)
    res: Ref,
    /// The operand we now know the value of
    reg: Ref,
    /// The value of the other operand
    /// i.e. if op is .Eq then reg is this value
    val: Ref,
    // if true -> reg = rhs, val = lhs
    // else    -> reg = lhs, val = rhs
    rev: bool,
    ifthenBB: BBID,
    ifelseBB: BBID,

    fn lhs(self: CmpInfo) Ref {
        return if (self.rev) self.val else self.reg;
    }
    fn rhs(self: CmpInfo) Ref {
        return if (self.rev) self.reg else self.val;
    }
};

fn apply_cmp_info(ir: *const IR, fun: *const Function, dom: *const Dominance, inst: Inst, values: []const Value, cmp_info: []?CmpInfo, value: Value) !Value {
    utils.assert(inst.op == .Cmp, "cannot apply non cmp cmp info ya dunce\n", .{});
    const cmp = Inst.Cmp.get(inst);
    const lhs = ref_value(ir, cmp.lhs, values);
    const rhs = ref_value(ir, cmp.rhs, values);

    const lhsConst = lhs.state == .constant;
    const rhsConst = rhs.state == .constant;

    if (lhsConst and rhsConst) {
        // case handled by eval
        return value;
    }
    // now we cook
    const cmpResReg = fun.regs.get(cmp.res.i);
    const curBBID = cmpResReg.bb;

    const cmpLhsCmpInfo = if (cmp.lhs.kind == .local) cmp_info[cmp.lhs.i] else null;
    const cmpRhsCmpInfo = if (cmp.rhs.kind == .local) cmp_info[cmp.rhs.i] else null;

    utils.assert(!(cmpLhsCmpInfo != null and cmpRhsCmpInfo != null), "both sides of cmp have cmpinfo??\n", .{});
    // std.debug.print("cmpLhsCmpInfo = {any}\n", .{cmpLhsCmpInfo});
    // std.debug.print("cmpRhsCmpInfo = {any}\n", .{cmpRhsCmpInfo});
    if (cmpLhsCmpInfo orelse cmpRhsCmpInfo) |cmpInfo| {
        const implications = cmp_info_implications_on_subsequent_cmp(ir, cmpInfo, cmp, values);
        if (implications.ifthen) |ifthen| {
            if (dom.isDominatedBy(curBBID, cmpInfo.ifthenBB)) {
                return Value.const_bool(ifthen);
            }
        }
        if (implications.ifelse) |ifelse| {
            if (dom.isDominatedBy(curBBID, cmpInfo.ifelseBB)) {
                return Value.const_bool(ifelse);
            }
        }
    }

    const cmpBBCtrlFlow = get_bb_ctrl_flow(fun, curBBID);
    // FIXME: handle case where cmp not used in br by setting ifthenBB and ifelseBB to the res bb
    if (inst_uses_reg(cmpBBCtrlFlow, cmpResReg) and cmpBBCtrlFlow.op != .Ret and (lhsConst or rhsConst)) {
        utils.assert(cmpBBCtrlFlow.op == .Br, "if ctrl flow uses reg and is not a return it should be a branch not {s}\n", .{@tagName(cmpBBCtrlFlow.op)});
        utils.assert(utils.xor(lhsConst, rhsConst), "case where both sides const not handled???\n", .{});

        const br = Inst.Br.get(cmpBBCtrlFlow);

        const cmpInfo = if (lhsConst) CmpInfo{
            .cond = cmp.cond,
            .res = inst.res,
            .reg = cmp.rhs,
            .val = cmp.lhs,
            .rev = true,
            .ifthenBB = br.iftrue,
            .ifelseBB = br.iffalse,
        } else CmpInfo{
            .cond = cmp.cond,
            .res = inst.res,
            .reg = cmp.lhs,
            .val = cmp.rhs,
            .rev = false,
            .ifthenBB = br.iftrue,
            .ifelseBB = br.iffalse,
        };
        std.debug.print("cmp info = {any}\n", .{cmpInfo});
        if (cmpInfo.reg.kind == .local) {
            std.debug.print("setting cmpInfo\n", .{});
            cmp_info[cmpInfo.reg.i] = cmpInfo;
        }
    }
    return meet(lhs, rhs);
}

fn get_bb_ctrl_flow(fun: *const Function, bbID: BBID) Inst {
    const bb = fun.bbs.get(bbID);
    const ctrlFlowInstID = bb.insts.list.getLastOrNull() orelse {
        utils.impossible("bb has no insts\n", .{});
    };
    const ctrlFlow = fun.insts.get(ctrlFlowInstID).*;
    return ctrlFlow;
}

fn is_same_comparison(cmp: Inst.Cmp, info: CmpInfo, values: []const Value) bool {
    const cmpLhs = cmp.lhs;
    const cmpRhs = cmp.rhs;
    const infoLhs = info.lhs();
    const infoRhs = info.rhs();

    const condsEqual = cmp.cond == info.cond;
    const kindsEqual = cmpLhs.kind == infoLhs.kind and cmpRhs.kind == infoRhs.kind;
    // const idsEqual = cmpLhs.i == infoLhs.i and cmpRhs.i == infoRhs.i;
    const valuesEqual = ref_values_equal(cmpLhs, infoLhs, values) and ref_values_equal(cmpRhs, infoRhs, values);

    // std.debug.print("cmp = {any}\ninfo = {any}\ncondsEqual={} kindsEqual={} valuesEqual={}\n", .{ cmp, info, condsEqual, kindsEqual, valuesEqual });

    return condsEqual and kindsEqual and valuesEqual;
}

fn ref_values_equal(a: Ref, b: Ref, values: []const Value) bool {
    if (a.i == b.i and a.kind == b.kind) {
        return true;
    }
    // FIXME: extend this logic to compare one sides value in values to an immediates value
    if (a.kind != .local or b.kind != .local) {
        return false;
    }
    if (values[a.i].constant == null or values[b.i].constant == null) {
        // cannot assume unknowns are equal
        return false;
    }
    return std.meta.eql(values[a.i].constant, values[b.i].constant);
}

const CmpImplications = struct {
    ifthen: ?bool = null,
    ifelse: ?bool = null,

    pub fn none() CmpImplications {
        return .{ .ifthen = null, .ifelse = null };
    }

    pub fn identity() CmpImplications {
        return .{ .ifthen = true, .ifelse = false };
    }

    pub fn inverse() CmpImplications {
        return .{ .ifthen = false, .ifelse = true };
    }

    pub fn only_true_in_ifthen() CmpImplications {
        return .{ .ifthen = true, .ifelse = null };
    }

    pub fn only_true_in_ifelse() CmpImplications {
        return .{ .ifthen = null, .ifelse = true };
    }

    pub fn only_false_in_ifthen() CmpImplications {
        return .{ .ifthen = false, .ifelse = null };
    }

    pub fn only_false_in_ifelse() CmpImplications {
        return .{ .ifthen = null, .ifelse = false };
    }
};

fn cmp_info_implications_on_subsequent_cmp(ir: *const IR, info: CmpInfo, cmp: Inst.Cmp, values: []const Value) CmpImplications {
    const condsEqual = cmp.cond == info.cond;
    const refValuesEqual = ref_values_equal(info.lhs(), cmp.lhs, values) and ref_values_equal(info.rhs(), cmp.rhs, values);
    const swapOrderEqual = ref_values_equal(info.lhs(), cmp.rhs, values) and ref_values_equal(info.rhs(), cmp.lhs, values);
    if (condsEqual and comparison_is_commutative(info.cond) and (refValuesEqual or swapOrderEqual)) {
        return CmpImplications.identity();
    }
    if (refValuesEqual and comparison_is_fuzzy_inverse_of(cmp.cond, info.cond)) {
        return CmpImplications.inverse();
    }
    if (!refValuesEqual and condsEqual) {
        // just picking one
        const cond = info.cond;
        if (std.meta.eql(info.lhs(), cmp.lhs)) {
            // variance is on rhs
            const infoVal = ref_value(ir, info.rhs(), values);
            const cmpVal = ref_value(ir, cmp.rhs, values);
            std.debug.print("info.val = {any}\ncmp.val = {any}\n", .{ infoVal, cmpVal });
            const maybe_res = eval_cmp(cond, infoVal, cmpVal);
            if (maybe_res == null) {
                return CmpImplications.none();
            }
            const res = maybe_res.?;
            std.debug.print("res = {}\n", .{res});
            return if (res) CmpImplications.only_true_in_ifthen() else CmpImplications.only_false_in_ifelse();
        }
        if (std.meta.eql(info.rhs(), cmp.rhs)) {
            // variance is on lhs
            const infoVal = ref_value(ir, info.lhs(), values);
            const cmpVal = ref_value(ir, cmp.lhs, values);
            std.debug.print("info.val = {any}\ncmp.val = {any}\n", .{ infoVal, cmpVal });
            const maybe_res = eval_cmp(cond, cmpVal, infoVal);
            if (maybe_res == null) {
                return CmpImplications.none();
            }
            const res = maybe_res.?;
            std.debug.print("res = {}\n", .{res});
            return if (res) CmpImplications.only_true_in_ifthen() else CmpImplications.only_false_in_ifelse();
        }
    }
    return CmpImplications.none();
}

fn eval_cmp(cond: OpCode.Cond, lhs: Value, rhs: Value) ?bool {
    const lhsConst = lhs.state == .constant;
    const rhsConst = rhs.state == .constant;
    if (!lhsConst or !rhsConst) {
        return null;
    }

    const l = lhs.constant.?.value;
    const r = rhs.constant.?.value;
    const res = switch (cond) {
        .Eq => l == r,
        .NEq => l != r,
        .Lt => l < r,
        .Gt => l > r,
        .GtEq => l >= r,
        .LtEq => l <= r,
    };
    return res;
}

fn comparison_is_commutative(op: OpCode.Cond) bool {
    return switch (op) {
        .Eq, .NEq => true,
        .Lt, .Gt, .GtEq, .LtEq => false,
    };
}

fn reverse_comparison(c: OpCode.Cond) OpCode.Cond {
    return switch (c) {
        // Commutative
        .Eq, .NEq => c,
        .Gt => .Lt,
        .Lt => .Gt,
        .GtEq => .LtEq,
        .LtEq => .GtEq,
    };
}

fn comparison_is_strict_inverse_of(a: OpCode.Cond, b: OpCode.Cond) bool {
    return b == switch (a) {
        .Eq => .NEq,
        .Neq => .Eq,
        .Gt => .LtEq,
        .Lt => .GtEq,
        .GtEq => .Lt,
        .LtEq => .Gt,
    };
}

fn comparison_is_fuzzy_inverse_of(a: OpCode.Cond, b: OpCode.Cond) bool {
    return switch (a) {
        .Eq => b == .NEq,
        .NEq => b == .Eq,
        .Gt => b == .Lt or b == .LtEq,
        .Lt => b == .Gt or b == .GtEq,
        .GtEq => b == .Lt,
        .LtEq => b == .Gt,
    };
}

fn eval(ir: *const IR, inst: Inst, values: []const Value) !?Value {
    if (!has_res(inst.op)) {
        return null;
    }
    return switch (inst.op) {
        .Binop => {
            const binop = Inst.Binop.get(inst);
            const lhs = ref_value(ir, binop.lhs, values);
            const rhs = ref_value(ir, binop.rhs, values);

            const op = binop.op;

            if (lhs.constant) |lhs_val| {
                if (rhs.constant) |rhs_val| {
                    // both are constants
                    const l = lhs_val.value;
                    const r = rhs_val.value;
                    const res = switch (op) {
                        .Mul => l * r,
                        .Add => l + r,
                        .Sub => l - r,
                        .And => l & r,
                        .Or => l | r,
                        .Xor => l ^ r,
                        .Div => if (r != 0) @divExact(l, r) else {
                            utils.todo("Mistew Beawd... how do i evawuwate a divison by zewo...", .{});
                        },
                    };
                    // std.debug.print("======= EVAL =======\n{d} {s} {d} = {d}\n", .{ l, @tagName(op), r, res });
                    utils.assert(
                        lhs_val.kind == rhs_val.kind,
                        "lhs_val.kind == rhs_val.kind\n {s} != {s}\n",
                        .{ @tagName(lhs_val.kind), @tagName(rhs_val.kind) },
                    );
                    return Value.const_of(res, lhs_val.kind);
                }
            }
            // TODO: unknown x undefined -> undefined

            // things we can know apriori. They mainly serve to either
            // make a constant regardless of the other operands state,
            // i.e. unknown x 0 -> 0 (not unknown)
            // or to reduce the number of unknowns by returning an undef
            // i.e. undef - 0 -> undef not unknown
            // this improves the results because there are many cases
            // where an assumption can be made for an undef but not
            // and unknown so reducing the number of unknowns is desireable
            if (lhs.is_int(0) and op == .Div) {
                return Value.const_int(0);
            }
            if ((lhs.is_int(0) or rhs.is_int(0)) and is_one_of(OpCode.Binop, op, .{ .Mul, .And })) {
                return Value.const_int(0);
            }
            if (lhs.is_int(0) and op == .Add) {
                return rhs;
            }
            if (rhs.is_int(0) and is_one_of(OpCode.Binop, op, .{ .Add, .Sub })) {
                return lhs;
            }
            const ALL_ONES: i64 = @bitCast(@as(u64, 0xFFFFFFFFFFFFFFFF));
            if ((rhs.is_int(ALL_ONES) or lhs.is_int(ALL_ONES)) and op == .Or) {
                return Value.const_int(ALL_ONES);
            }
            if (rhs.is_int(ALL_ONES) and op == .And) {
                return lhs;
            }
            if (lhs.is_int(ALL_ONES) and op == .And) {
                return rhs;
            }
            if (rhs.is_int(0) and op == .Div) {
                utils.todo("Mistew Beawd... how do i evawuwate a divison by zewo...", .{});
            }
            log.trace("unhandled binop case `{s} {?any} {s} {s} {?any}`\n", .{
                @tagName(lhs.state),
                lhs.constant,
                @tagName(op),
                @tagName(rhs.state),
                rhs.constant,
            });
            return Value.unknown();
        },
        .Cmp => {
            const cmp = Inst.Cmp.get(inst);
            const lhs = ref_value(ir, cmp.lhs, values);
            const rhs = ref_value(ir, cmp.rhs, values);

            const lhsConst = lhs.state == .constant;
            const rhsConst = rhs.state == .constant;

            if (lhsConst and rhsConst) {
                // eval
                const cond = cmp.cond;
                const l = lhs.constant.?.value;
                const r = rhs.constant.?.value;
                const res = switch (cond) {
                    .Eq => l == r,
                    .NEq => l != r,
                    .Lt => l < r,
                    .Gt => l > r,
                    .GtEq => l >= r,
                    .LtEq => l <= r,
                };
                return Value.const_bool(res);
            }

            return meet(lhs, rhs);
        },
        .Zext, .Sext, .Trunc, .Bitcast => misc: {
            // FIXME: HOW TO HANDLE.
            // Zext should be handled just by making the constant
            // an i64 from an i1
            // Sext won't be, but afaik we never use it
            // same goes for trunk,
            // bitcast I don't think we care as long as we use the right type
            // eventually
            const misc = Inst.Misc.get(inst);
            const value = ref_value(ir, misc.from, values);
            break :misc value;
        },
        // FIXME: should probably be unknown
        .Alloc, .Load => Value.undef(),
        // NOTE: could do gep ourselves but it only matters
        // for making dylans life easier with lowering
        .Gep => Value.unknown(),
        .Call => Value.unknown(),
        .Phi => {
            const phi = Inst.Phi.get(inst);
            const numEntries = phi.entries.items.len;
            if (numEntries == 0) {
                return Value.undef();
            } else if (numEntries == 1) {
                const entry = phi.entries.items[0];
                return ref_value(ir, entry.ref, values);
            } else {
                return Value.unknown();
            }
        },
        // no result registers. handled by if at top of function
        .Ret, .Store, .Param, .Br, .Jmp => unreachable,
    };
}

inline fn has_res(op: OpCode) bool {
    return switch (op) {
        .Br, .Jmp, .Store, .Ret, .Param => false,
        else => true,
    };
}

fn is_one_of(comptime T: type, needle: T, comptime haystack: anytype) bool {
    inline for (haystack) |hay| {
        if (hay == needle) {
            return true;
        }
    }
    return false;
}

/// Joins two values. using the following logic
/// a | b is unknown? -> unknown
/// a undef? -> b
/// b undef? -> a
/// a const and b const and a val == b val -> const val
/// a const and b const and a val != b val -> unknown
fn meet(a: Value, b: Value) Value {
    if (a.state == .unknown or b.state == .unknown) {
        return Value.unknown();
    }
    if (a.state == .undef) {
        return b;
    }
    if (b.state == .undef) {
        return a;
    }
    const aconst = a.constant.?;
    const bconst = b.constant.?;

    if (bconst.value == aconst.value and bconst.kind == aconst.kind) {
        return a;
    }
    // both constant -> unknown
    return Value.unknown();
}

fn ref_value(ir: *const IR, ref: Ref, values: []const Value) Value {
    const res = switch (ref.kind) {
        .local => values[ref.i],
        .immediate => switch (ref.type) {
            .bool => Value.const_bool(ref.i == IMMEDIATE_TRUE),
            .int => Value.const_int(ir.parseInt(ref.i) catch unreachable),
            .void => unreachable,
            else => Value.unknown(),
        },
        .immediate_u32 => Value.const_int(@intCast(ref.i)),
        .global, .param => Value.unknown(),
        ._invalid, .label => unreachable,
    };
    // if (ref.kind == .immediate) {
    //     std.debug.print("REF IMM {s} {any} {?any}\n", .{ ir.getIdent(ref.i), ref, res.constant });
    // } else if (ref.kind == .immediate_u32) {
    //     std.debug.print("REF IMM U32 {s} {any} {?any}\n", .{ ir.getIdent(ref.i), ref, res.constant });
    // }
    return res;
}

pub const Value = @import("./sccp.zig").Value;

/// A usage of a register we updated the value of
/// A member of the SSA edge worklist
/// NOTE: we didn't necessarily update the value to a constant
const SSAEdge = struct {
    bb: BBID,
    instID: InstID,
};

/// Push reachable usages of a register to the ssa worklist
fn add_reachable_uses_of(fun: *const Function, reg: Register, ssaWL: *ArrayList(SSAEdge), reachable: []const bool) !void {
    var visited = try fun.alloc.alloc(bool, @intCast(fun.bbs.len + fun.bbs.removed));
    defer fun.alloc.free(visited);
    @memset(visited, false);

    try add_reachable_uses_of_reg_from_bb(fun, reg, reg.bb, ssaWL, reachable, visited);
    // TODO: filter repeat offenders from start -> end
    // by setting them to null
}

/// The inner function of reachable_uses_of
/// Pushes all uses
fn add_reachable_uses_of_reg_from_bb(fun: *const Function, reg: Register, bbID: BBID, ssaWL: *ArrayList(SSAEdge), reachable: []const bool, visited: []bool) !void {
    visited[bbID] = true;
    // std.debug.print("WATCH ME SCCP DEEZ BBS {d}\n", .{bbID});
    const bb = fun.bbs.get(bbID);
    const insts = &fun.insts;
    var instructionIDs = bb.insts.items();
    // std.debug.print("INSTS={any}\nITEMS={any}\n", .{ bb.insts.list.items, bb.insts.items() });
    // for (instructionIDs) |instID| {
    //     std.debug.print("INST={any}\n", .{insts.get(instID).*});
    // }
    // std.debug.print("RET?={any}\n", .{insts.get(10)});
    var inst: Inst = undefined;

    if (reg.bb == bbID) {
        // use slice from reg inst to end of bb
        const regInstID = reg.inst;
        const regInstIndex = std.mem.indexOfScalar(BBID, instructionIDs, regInstID) orelse {
            utils.impossible(
                "register {any} in bb {s} inst does not point to an inst in the bb.\ninst={d}\nbb inst IDS={any}\ninst={any}\n",
                .{ reg, bb.name, reg.inst, instructionIDs, fun.insts.get(regInstID) },
            );
        };
        if (regInstIndex + 1 == instructionIDs.len) {
            inst = insts.get(reg.inst).*;
            instructionIDs = &[_]BBID{};
        } else {
            instructionIDs = instructionIDs[regInstIndex + 1 ..];
        }
    }

    // following loop assumes the current bb is reachable
    // if we are checking it
    utils.assert(reachable[bbID], "reachable_uses_of_reg_from_bb expects the bb it is checking to be reachable\n", .{});

    // std.debug.print("WATCH ME SCCP DEEZ {any}\n", .{instructionIDs});
    instLoop: for (instructionIDs) |instID| {
        inst = insts.get(instID).*;
        if (!inst_uses_reg(inst, reg)) {
            continue :instLoop;
        }
        const ssaEdge = SSAEdge{
            .bb = bbID,
            .instID = instID,
        };
        for (ssaWL.items) |existingEdge| {
            if (std.meta.eql(ssaEdge, existingEdge)) {
                continue :instLoop;
            }
        }
        try ssaWL.append(ssaEdge);
    }
    utils.assert(inst.isCtrlFlow(), "block does not end with ctrl flow statement (or possibly block is empty)\ninst={any}\n", .{inst});

    switch (inst.op) {
        // no more blocks to check from ret
        .Ret => {},
        .Jmp => {
            const jmp = Inst.Jmp.get(inst);
            if (reachable[jmp.dest] and !visited[jmp.dest]) {
                std.debug.print("WATCH ME VISIT {d}\n", .{jmp.dest});
                return try add_reachable_uses_of_reg_from_bb(
                    fun,
                    reg,
                    jmp.dest,
                    ssaWL,
                    reachable,
                    visited,
                );
            }
        },
        .Br => {
            const br = Inst.Br.get(inst);
            if (reachable[br.iftrue] and !visited[br.iftrue]) {
                std.debug.print("WATCH ME VISIT {d}\n", .{br.iftrue});
                try add_reachable_uses_of_reg_from_bb(
                    fun,
                    reg,
                    br.iftrue,
                    ssaWL,
                    reachable,
                    visited,
                );
            }
            if (reachable[br.iffalse] and !visited[br.iffalse]) {
                std.debug.print("WATCH ME VISIT {d}\n", .{br.iffalse});
                return try add_reachable_uses_of_reg_from_bb(
                    fun,
                    reg,
                    br.iffalse,
                    ssaWL,
                    reachable,
                    visited,
                );
            }
        },
        else => unreachable,
    }
}

pub fn inst_uses_reg(inst: Inst, reg: Reg) bool {
    return inst_uses_regID(inst, reg.id);
}

pub fn inst_uses_regID(inst: Inst, regID: RegID) bool {
    return switch (inst.op) {
        .Binop => {
            const binop = Inst.Binop.get(inst);
            return either_refers_to_regID(binop.lhs, binop.rhs, regID);
        },
        .Cmp => {
            const cmp = Inst.Cmp.get(inst);
            return either_refers_to_regID(cmp.lhs, cmp.rhs, regID);
        },
        .Zext, .Sext, .Trunc, .Bitcast => {
            const misc = Inst.Misc.get(inst);
            return refers_to_regID(misc.from, regID);
        },
        .Load => {
            const load = Inst.Load.get(inst);
            return refers_to_regID(load.ptr, regID);
        },
        .Gep => {
            const gep = Inst.Gep.get(inst);
            return either_refers_to_regID(gep.ptrVal, gep.index, regID);
        },
        .Call => {
            const call = Inst.Call.get(inst);
            for (call.args) |arg| {
                if (refers_to_regID(arg, regID)) {
                    return true;
                }
            }
            return false;
        },
        .Phi => {
            const phi = Inst.Phi.get(inst);
            for (phi.entries.items) |entry| {
                if (refers_to_regID(entry.ref, regID)) {
                    return true;
                }
            }
            return false;
        },
        .Ret => {
            const ret = Inst.Ret.get(inst);
            return refers_to_regID(ret.val, regID);
        },
        .Store => {
            const store = Inst.Store.get(inst);
            return either_refers_to_regID(store.from, store.to, regID);
        },
        .Br => {
            const br = Inst.Br.get(inst);
            return refers_to_regID(br.on, regID);
        },
        // no registers
        .Alloc, .Param, .Jmp => false,
    };
}

fn refers_to_regID(ref: Ref, regID: RegID) bool {
    return switch (ref.kind) {
        .local => ref.i == regID,
        else => false,
    };
}

/// Thanks zig lsp for putting stuff past 120 characters
inline fn either_refers_to_regID(a: Ref, b: Ref, reg: RegID) bool {
    return refers_to_regID(a, reg) or refers_to_regID(b, reg);
}
var testAlloc = std.heap.page_allocator;
const ting = std.testing;
const OPT = @import("opt.zig");
const expectResultsInIR = OPT.expectResultsInIR;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try @import("../ast.zig").initFromParser(parser);
    const ir = try @import("phi.zig").generate(testAlloc, &ast);
    return ir;
}

fn cmp_prop_all_funs(ir: *const IR) !void {
    const funs = ir.funcs.items.items;
    for (funs) |*fun| {
        _ = try cmp_prop(testAlloc, ir, fun);
    }
}

test "cmp-prop.removes-nested-known-if" {
    log.empty();
    errdefer log.print();

    // FIXME: use before def instead of param
    try expectResultsInIR(
        \\fun test (int param) int {
        \\    int a, b, c, d;
        \\    a = 5 * param;
        \\    b = 2;
        \\    c = 3;
        \\    d = 0;
        \\
        \\    if (a == 1) {
        \\        b = 20;
        \\        if (a == 1) {
        \\            b = 200;
        \\            c = 300;
        \\        } else {
        \\            a = 1;
        \\            b = 2;
        \\            c = 3;
        \\        }
        \\        d = b * c;
        \\    }
        \\
        \\    return d;
        \\}
        \\fun main() void {
        \\}
    , .{
        "define i64 @test(i64 %param) {",
        "entry:",
        "  br label %body0",
        "body0:",
        "  %a11 = mul i64 5, %param",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_17 = icmp eq i64 %a11, 1",
        "  br i1 %_17, label %if.exit8, label %if.exit10",
        "if.exit8:",
        "  %d33 = mul i64 200, 300",
        "  br label %then.exit9",
        "then.exit9:",
        "  br label %if.exit10",
        "if.exit10:",
        "  %b1 = phi i64 [ 2, %if.cond1 ], [ 200, %then.exit9 ]",
        "  %a4 = phi i64 [ %a11, %if.cond1 ], [ %a11, %then.exit9 ]",
        "  %d5 = phi i64 [ 0, %if.cond1 ], [ %d33, %then.exit9 ]",
        "  %c7 = phi i64 [ 3, %if.cond1 ], [ 300, %then.exit9 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %d5",
        "}",
        "",
        "define void @main() {",
        "entry:",
        "  br label %body0",
        "body0:",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    }, .{
        .{ "test", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.removes-impossible-if" {
    // FIXME: use before def instead of param
    try expectResultsInIR(
        \\fun test (int param) int {
        \\    int a, b;
        \\    a = 5 * param;
        \\    b = 2;
        \\
        \\    if (a > 10) {
        \\        if (a < 10) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    } else {
        \\        b = 20;
        \\    }
        \\
        \\    return b;
        \\}
        \\fun main() void {
        \\}
    , .{
        "define i64 @test(i64 %param) {",
        "entry:",
        "  br label %body0",
        "body0:",
        "  %a6 = mul i64 5, %param",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_10 = icmp sgt i64 %a6, 10",
        "  br i1 %_10, label %then.exit9, label %else.exit11",
        "then.exit9:",
        "  br label %if.exit12",
        "else.exit11:",
        "  br label %if.exit12",
        "if.exit12:",
        "  %b2 = phi i64 [ 2, %then.exit9 ], [ 20, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b2",
        "}",
        "",
        "define void @main() {",
        "entry:",
        "  br label %body0",
        "body0:",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    }, .{
        .{ "test", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifthen-rhs-known" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (a < 10) {
        \\        if (a < 20) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    } else {
        \\        b = 20;
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp slt i64 %a7, 10",
        "  br i1 %_11, label %then.exit9, label %else.exit11",
        // NOTE: lack of cmp a < 20 because it is implied by a < 10
        "then.exit9:",
        "  br label %if.exit12",
        "else.exit11:",
        "  br label %if.exit12",
        "if.exit12:",
        "  %b1 = phi i64 [ 200, %then.exit9 ], [ 20, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b1",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifthen-rhs-unknown" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (a < 10) {
        \\        if (a < 5) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    } else {
        \\        b = 20;
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp slt i64 %a7, 10",
        "  br i1 %_11, label %if.cond3, label %else.exit11",
        "if.cond3:",
        // NOTE: this is the cmp that should still exist because it is not implied by a < 10
        "  %_15 = icmp slt i64 %a7, 5",
        "  br i1 %_15, label %then.exit5, label %else.exit7",
        "then.exit5:",
        "  br label %if.exit8",
        "else.exit7:",
        "  br label %if.exit8",
        "if.exit8:",
        "  %b0 = phi i64 [ 200, %then.exit5 ], [ 2, %else.exit7 ]",
        "  br label %then.exit9",
        "then.exit9:",
        "  br label %if.exit12",
        "else.exit11:",
        "  br label %if.exit12",
        "if.exit12:",
        "  %b1 = phi i64 [ %b0, %then.exit9 ], [ 20, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b1",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifelse-rhs-known" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (a < 10) {
        \\        b = 20;
        \\    } else {
        \\        if (a < 5) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp slt i64 %a7, 10",
        "  br i1 %_11, label %then.exit3, label %else.exit11",
        "then.exit3:",
        "  br label %if.exit12",
        "else.exit11:",
        // NOTE: lack of cmp a < 5 because it is implied to be false by !(a < 10)
        "  br label %if.exit12",
        "if.exit12:",
        "  %b0 = phi i64 [ 20, %then.exit3 ], [ 2, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b0",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifelse-rhs-unknown" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (a < 10) {
        \\        b = 20;
        \\    } else {
        \\        if (a < 20) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp slt i64 %a7, 10",
        "  br i1 %_11, label %then.exit3, label %if.cond5",
        "then.exit3:",
        "  br label %if.exit12",
        "if.cond5:",
        // NOTE: this is the cmp that should still exist because it is not implied by !(a < 10)
        "  %_18 = icmp slt i64 %a7, 20",
        "  br i1 %_18, label %then.exit7, label %else.exit9",
        "then.exit7:",
        "  br label %if.exit10",
        "else.exit9:",
        "  br label %if.exit10",
        "if.exit10:",
        "  %b1 = phi i64 [ 200, %then.exit7 ], [ 2, %else.exit9 ]",
        "  br label %else.exit11",
        "else.exit11:",
        "  br label %if.exit12",
        "if.exit12:",
        "  %b0 = phi i64 [ 20, %then.exit3 ], [ %b1, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b0",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifthen-lhs-known" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (10 > a) {
        // a < 10
        \\        if (20 > a) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    } else {
        // a >= 10
        \\        b = 20;
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp sgt i64 10, %a7",
        "  br i1 %_11, label %then.exit9, label %else.exit11",
        // NOTE: lack of cmp 20 > a because it is implied by a < 10
        "then.exit9:",
        "  br label %if.exit12",
        "else.exit11:",
        "  br label %if.exit12",
        "if.exit12:",
        "  %b1 = phi i64 [ 200, %then.exit9 ], [ 20, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b1",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifthen-lhs-unknown" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (10 > a) {
        // a < 10
        \\        if (5 > a) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    } else {
        // a >= 10
        \\        b = 20;
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp sgt i64 10, %a7",
        "  br i1 %_11, label %if.cond3, label %else.exit11",
        "if.cond3:",
        // NOTE: this is the cmp that should still exist because it is not implied by a < 10
        "  %_15 = icmp sgt i64 5, %a7",
        "  br i1 %_15, label %then.exit5, label %else.exit7",
        "then.exit5:",
        "  br label %if.exit8",
        "else.exit7:",
        "  br label %if.exit8",
        "if.exit8:",
        "  %b0 = phi i64 [ 200, %then.exit5 ], [ 2, %else.exit7 ]",
        "  br label %then.exit9",
        "then.exit9:",
        "  br label %if.exit12",
        "else.exit11:",
        "  br label %if.exit12",
        "if.exit12:",
        "  %b1 = phi i64 [ %b0, %then.exit9 ], [ 20, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b1",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifelse-lhs-known" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (10 > a) {
        // a < 10
        \\        b = 20;
        \\    } else {
        // a >= 10
        \\        if (5 > a) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp sgt i64 10, %a7",
        "  br i1 %_11, label %then.exit3, label %else.exit11",
        "then.exit3:",
        "  br label %if.exit12",
        "else.exit11:",
        // NOTE: lack of cmp 10 > a because it is implied to be false by !(5 > a)
        "  br label %if.exit12",
        "if.exit12:",
        "  %b0 = phi i64 [ 20, %then.exit3 ], [ 2, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b0",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}

test "cmp-prop.ifelse-lhs-unknown" {
    try expectResultsInIR(
        \\fun main () int {
        \\    int a, b;
        \\    a = 5 * b;
        \\    b = 2;
        \\
        \\    if (10 > a) {
        // a < 10
        \\        b = 20;
        \\    } else {
        // a >= 10
        \\        if (20 > a) {
        \\            b = 200;
        \\        } else {
        \\            b = 2;
        \\        }
        \\    }
        \\
        \\    return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  %b5 = alloca i64",
        "  %b6 = load i64, i64* %b5",
        "  br label %body0",
        "body0:",
        "  %a7 = mul i64 5, %b6",
        "  br label %if.cond1",
        "if.cond1:",
        "  %_11 = icmp sgt i64 10, %a7",
        "  br i1 %_11, label %then.exit3, label %if.cond5",
        "then.exit3:",
        "  br label %if.exit12",
        "if.cond5:",
        // NOTE: this is the cmp that should still exist because it is not implied by !(a < 10)
        "  %_18 = icmp sgt i64 20, %a7",
        "  br i1 %_18, label %then.exit7, label %else.exit9",
        "then.exit7:",
        "  br label %if.exit10",
        "else.exit9:",
        "  br label %if.exit10",
        "if.exit10:",
        "  %b1 = phi i64 [ 200, %then.exit7 ], [ 2, %else.exit9 ]",
        "  br label %else.exit11",
        "else.exit11:",
        "  br label %if.exit12",
        "if.exit12:",
        "  %b0 = phi i64 [ 20, %then.exit3 ], [ %b1, %else.exit11 ]",
        "  br label %exit",
        "exit:",
        "  ret i64 %b0",
        "}",
    }, .{
        .{ "main", .{ .cmp, .empty_bb } },
    });
}
