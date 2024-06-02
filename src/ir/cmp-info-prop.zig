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

const Dominance = @import("dominance.zig");

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
                if (try eval(ir, inst, values, cmp_info)) |inst_value| {
                    utils.assert(!std.meta.eql(inst.res, Ref.default), "inst with value has no res {any}\n", .{inst});
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
                // cannot assume we can know the unknowable things
                // of generations past
                // such is life
                // r/im15andthisisdeep
                continue :main_loop;
            }
            const new_res_val = try eval(ir, inst, values, cmp_info) orelse {
                utils.impossible(
                    \\result of ssa edge eval is null, this should have been handled in the prechecks right???
                    \\inst={any}
                ,
                    .{inst},
                );
            };
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

inline fn has_res(op: OpCode) bool {
    return switch (op) {
        .Br, .Jmp, .Store, .Ret, .Param => false,
        else => true,
    };
}

const CmpInfo = struct {
    /// The comparison operator used
    op: OpCode.Cond,
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

    // Propogates the information from this cmpInfo
    // placed in the struct to identify it as only related to CmpInfo
    // Mutates []Value based on cmpInfo
    // fn propogate(self: @This(), ir: *const IR, fun: *const Function, values: *[]Value) void {
    //     _ = values;
    //     utils.assert(self.res.kind == .local, "ref is not local\n", .{});
    //     const reg = fun.regs.get(self.res.i);
    //     const bb = fun.bbs.get(reg.bb);
    //     if (!end_of_bb_uses_ref_to_reg(bb, self.res)) {
    //         log.trace("now this is wierd, bb where cmpInfo was derived does not use result of cmp in branch");
    //         return;
    //     }
    //     // TODO: find first meeting point or exit
    //     //  then -> for each block in each path, identitify
    //     //          common sub expressions or uses of the value
    //     //          and update values accordingly
    //     //  PERF: if value not in a phi at that location we can repeat
    //     const cmp = cmp: {
    //         const inst = bb.insts.list.getLastOrNull() orelse {
    //             utils.impossible("bb has no insts\n", .{});
    //         };
    //         break :cmp Inst.Cmp.get(inst);
    //     };
    //     const propAlloc = fun.alloc;
    //     const dominance = Dominance.genLazyDominance(ir, fun);
    //     const joinPoints = join: {
    //         // var because setIntersection will update the self param in place
    //         var ifThenDomFront = bb_dom_front_to_bitset(propAlloc, fun, cmp.iftrue, dominance.domFront);
    //
    //         const ifElseDomFront = bb_dom_front_to_bitset(propAlloc, fun, cmp.iffalse, dominance.domFront);
    //         defer ifElseDomFront.deinit();
    //
    //         ifThenDomFront.setIntersection(ifElseDomFront);
    //         break :join ifThenDomFront;
    //     };
    //     _ = joinPoints;
    // }
};

const DomFront = @TypeOf(@field(Dominance.Dominance, "domFront"));

/// Returns the dom front for bb as a bitset
fn bb_dom_front_to_bitset(alloc: Alloc, fun: *const Function, bb: BBID, dom_front: *const DomFront) BitSet {
    const num_bbs = fun.bbs.len + fun.bbs.removed;
    var bs = BitSet.init(alloc, num_bbs);
    if (dom_front.get(bb)) |df| {
        for (df) |dfBBID| {
            bs.set(dfBBID);
        }
    }
    return bs;
}

fn is_same_comparison(inst: Inst, info: CmpInfo) bool {
    if (inst.op != .Cmp) {
        return false;
    }
    const cmp = Inst.Cmp.get(inst);

    if (cmp.op != info.op) {
        return false;
    }
    // compare kinds
    if (!pair_is_equal(Ref.Kind, info.val.kind, info.reg.kind, cmp.lhs.kind, cmp.rhs.kind)) {
        return false;
    }
    // compare ids
    if (!pair_is_equal(Ref.ID, info.val.i, info.reg.i, cmp.lhs.i, cmp.rhs.i)) {
        return false;
    }
    return true;
}

// FIXME: add option to compare reverse order on one side as well
// for when op in cmp is commutative
fn pair_is_equal(comptime T: type, a1: T, b1: T, a2: T, b2: T) bool {
    const Pair = @Vector(2, T);

    const pair1 = Pair{ a1, b1 };
    const pair2 = Pair{ a2, b2 };

    return @reduce(.And, pair1 == pair2);
}

fn end_of_bb_uses_ref_to_reg(bb: *const BasicBlock, ref: Ref) bool {
    const ctrlFlow = bb.insts.list.getLastOrNull() orelse {
        utils.impossible("bb has no insts\n", .{});
    };
    utils.assert(ctrlFlow.isCtrlFlow(), "last inst in bb is not control flow\n", .{});
    utils.assert(ref.kind == .local, "ref is not local\n", .{});
    if (is_one_of(OpCode, ctrlFlow.op, .Ret, .Jmp)) {
        return false;
    }
    // we know it's a branch, but use inst_uses_regID anyway
    // so we don't duplicate logic
    return inst_uses_regID(ctrlFlow, ref.i);
}

const Set = @import("../array_hash_set.zig");

fn find_next_join_point(fun: *const Function, bb: *const BasicBlock) BBID {
    const branch = bb.insts.list.getLastOrNull() orelse {
        utils.impossible("expected branch as first input to `find_next_join_point` instead found empty block???\n", .{});
    };
    utils.assert(branch.op == .Br, "expected branch as first input to `find_next_join_point` instead found {s}???\n", .{@tagName(branch.op)});
    const Br = Inst.Br.get(branch);

    var then_set = Set(BBID).init(fun.alloc);
    try then_set.add(Br.iftrue);
    defer then_set.deinit();
    var else_set = Set(BBID).init(fun.alloc);
    try else_set.add(Br.iffalse);
    defer else_set.deinit();
    const res = find_next_join_point_inner(fun, bb) orelse utils.impossible("no join point found. Exit should always be a join point\n", .{});
    return res;
}

fn find_next_join_point_inner(fun: *const Function, then_bb: *const BasicBlock, then_set: *Set(BBID), else_bb: *const BasicBlock, else_set: *Set(BBID)) ?BBID {
    // use heuristic based on length to determine which side to recurse on
    const Group = struct {
        bb: *const BasicBlock,
        set: *Set(BBID),
        other_set: *Set(BBID),
    };
    const groups = [_]Group{
        .{ .bb = then_bb, .set = then_set, .other_set = else_set },
        .{ .bb = else_bb, .set = else_set, .other_set = then_set },
    };
    if (then_set.items.len > else_set.items.len) {
        std.mem.swap(Group, &groups[0], &groups[1]);
    }
    for (groups) |group| {
        const bb = group.bb;
        const set = group.set;
        const other_set = group.other_set;
        const ctrl_inst = bb.insts.list.getLastOrNull() orelse {
            utils.impossible("bb has no insts\n", .{});
        };
        utils.assert(ctrl_inst.isCtrlFlow(), "last inst in bb is not control flow\n", .{});

        var i = 0;
        const dests = get_ctrl_flow_dests(ctrl_inst);
        while (dests[i]) |dest| : (i += 1) {
            if (other_set.contains(dest)) {
                // found join point
                return dest;
            }
            set.add(dest);
            if (find_next_join_point_inner(fun, fun.bbs.get(dest), then_set, else_bb, else_set)) |join| {
                return join;
            }
        }
    }
    return null;
}

fn get_ctrl_flow_dests(inst: Inst) [2]?BBID {
    return switch (inst.op) {
        .Br => {
            const br = Inst.Br.get(inst);
            return .{ br.iftrue, br.iffalse };
        },
        .Jmp => {
            const jmp = Inst.Jmp.get(inst);
            return .{ jmp.dest, null };
        },
        .Ret => .{ null, null },
        else => unreachable,
    };
}

fn eval(ir: *const IR, inst: Inst, values: []const Value, cmp_info: []?CmpInfo) !?Value {
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
                    std.debug.print("======= EVAL =======\n{d} {s} {d} = {d}\n", .{ l, @tagName(op), r, res });
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
                const r = lhs.constant.?.value;
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

            if (cmp.lhs.kind == .local) {
                if (cmp_info[cmp.lhs.i]) |cmpInfo| {
                    if (std.meta.eql(ref_value(ir, cmpInfo.val, values), rhs)) {
                        if (cmpInfo.op == cmp.cond) {
                            std.debug.print("found same cmp\n", .{});
                            return Value.const_bool(true);
                        }
                    }
                }
            }

            if (lhsConst or rhsConst) {
                // looked for xor keyword, found simd
                utils.assert(@reduce(.Xor, @Vector(2, bool){ lhsConst, rhsConst }), "case where both sides const not handled???\n", .{});

                utils.assert(inst.res.kind == .local, "inst res is local got {any}\n", .{inst.res});

                const cmpInfo = if (lhsConst) CmpInfo{
                    .op = cmp.cond,
                    .res = inst.res,
                    .reg = cmp.rhs,
                    .val = cmp.lhs,
                    .rev = true,
                } else CmpInfo{
                    .op = cmp.cond,
                    .res = inst.res,
                    .reg = cmp.lhs,
                    .val = cmp.rhs,
                    .rev = false,
                };
                std.debug.print("cmp info = {any}\n", .{cmpInfo});
                if (cmpInfo.reg.kind == .local) {
                    std.debug.print("found cmpInfo\n", .{});
                    cmp_info[cmpInfo.reg.i] = cmpInfo;
                }
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

// test "compilation" {
//     log.empty();
//     errdefer log.print();
//     var ir = try testMe(
//         \\fun main() void {
//         \\  int a;
//         \\  if (true) {
//         \\    while (false) {
//         \\      a = 1;
//         \\      a = 3;
//         \\    }
//         \\  }
//         \\  a = 2;
//         \\}
//     );
//     try sccp_all_funs(&ir);
// }

// test "sccp.removes-never-taken-if" {
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
//         "  br label %body0",
//         "body0:",
//         "  br label %if.cond1",
//         "if.cond1:",
//         "  br label %else.body4",
//         "else.body4:",
//         "  br label %else.exit5",
//         "else.exit5:",
//         "  br label %if.exit6",
//         "if.exit6:",
//         "  br label %exit",
//         "exit:",
//         "  ret i64 2",
//         "}",
//     }, .{
//         .{ "main", .{.sccp} },
//     });
// }
//
// test "sccp.removes-nested-never-ran-while" {
//     log.empty();
//     errdefer log.print();
//     try expectResultsInIR(
//         \\fun main() int {
//         \\  int a;
//         \\  a = 4;
//         \\  if (true) {
//         \\    a = 1;
//         \\    while (false) {
//         \\      a = 2;
//         \\      a = 3;
//         \\    }
//         \\  }
//         \\  return a;
//         \\}
//     , .{
//         "define i64 @main() {",
//         "entry:",
//         "  br label %body0",
//         "body0:",
//         "  br label %if.cond1",
//         "if.cond1:",
//         "  br label %then.body2",
//         "then.body2:",
//         "  br label %while.cond13",
//         "while.cond13:",
//         "  br label %while.exit7",
//         "while.exit7:",
//         "  br label %then.exit8",
//         "then.exit8:",
//         "  br label %if.exit9",
//         "if.exit9:",
//         "  br label %exit",
//         "exit:",
//         "  ret i64 1",
//         "}",
//     }, .{
//         .{ "main", .{.sccp} },
//     });
// }

test "cmp-prop.removes-nested-known-if" {
    log.empty();
    errdefer log.print();

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
        "define i64 @main() {",
        "entry:",
        "  br label %body0",
        "body0:",
        "  br label %if.cond1",
        "if.cond1:",
        "  br label %else.body4",
        "else.body4:",
        "  br label %else.exit5",
        "else.exit5:",
        "  br label %if.exit6",
        "if.exit6:",
        "  br label %exit",
        "exit:",
        "  ret i64 2",
        "}",
    }, .{
        .{ "test", .{.cmp} },
    });
}
