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
pub fn sccp(alloc: Alloc, ir: *const IR, fun: *const Function) !SCCPRes {
    var reachable = exec: {
        var reachable = try alloc.alloc(bool, @intCast(fun.bbs.len));
        @memset(reachable, false);
        break :exec reachable;
    };
    var values = values: {
        const numValues: usize = @intCast(fun.regs.len);
        var values = try alloc.alloc(Value, numValues);
        @memset(values, Value.undef());
        break :values values;
    };
    var bbWL = bbwl: {
        var bbwl = ArrayList(BBID).init(alloc);
        try bbwl.append(Function.entryBBID);
        break :bbwl bbwl;
    };
    var ssaWL = ArrayList(SSAEdge).init(alloc);

    const insts = &fun.insts;
    const regs = &fun.regs;

    main_loop: while (bbWL.items.len > 0) {
        if (bbWL.popOrNull()) |bbID| {
            if (reachable[bbID]) {
                // in this context means we already handled the block
                // updates to values in this block will be handled by
                // ssaWL
                continue :main_loop;
            }
            reachable[bbID] = true;

            const bb = fun.bbs.get(bbID);
            const phiInstructionIDs = bb.phiInsts.items;
            const instructionIDs = bb.insts.items();

            for (phiInstructionIDs) |phiInstID| {
                // visit_phi [x := phi(y, z)] -> Value[x] = y /\ z
                const inst = insts.get(phiInstID).*;
                utils.assert(inst.op == .Phi, "phi inst not phi??? ({s} instead) wtf dylan!\n", .{@tagName(inst.op)});
                const phi = Inst.Phi.get(inst);

                const res = phi.res;
                utils.assert(res.kind == .local, "phi res not local is {s}\n", .{@tagName(res.kind)});

                // WARN: these are supposed to be evaluated
                // simultaneously (i.e. results of one would not impact others)
                // but I can't think of a case where the result is
                // different than just going one by one
                // and we shouldn't get cases where one depends on another
                var value: Value = values[res.i];
                for (phi.entries.items) |option| {
                    // TODO: assert not depending on phi in same bb
                    const ref = option.ref;
                    const optionValue = ref_value(ir, ref, values);
                    value = meet(value, optionValue);
                }
                utils.assert(res.kind == .local, "inst res is local got {any}\n", .{res});
                const reg = regs.get(res.i);
                values[reg.id] = value;
                try add_reachable_uses_of(fun, reg, &ssaWL, reachable);
            }

            for (instructionIDs) |instID| {
                const inst = insts.get(instID).*;
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
                            try bbWL.append(ifthen);
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
                if (try eval(ir, inst, values)) |inst_value| {
                    utils.assert(!std.meta.eql(inst.res, Ref.default), "inst with value has no res {any}\n", .{inst});
                    const res = inst.res;
                    utils.assert(res.kind == .local, "inst res is local got {any}\n", .{res});
                    const reg = regs.get(res.i);
                    values[reg.id] = inst_value;
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
            const new_res_val = try eval(ir, inst, values) orelse {
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
            try add_reachable_uses_of(fun, reg, &ssaWL, reachable);
        }
    }

    return .{
        .values = values,
        .reachable = reachable,
    };
}

inline fn has_res(op: OpCode) bool {
    return switch (op) {
        .Br, .Jmp, .Store, .Ret, .Param => false,
        else => true,
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
                    const r = lhs_val.value;
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

            if (lhs.state != .constant or rhs.state != .constant) {
                return meet(lhs, rhs);
            }
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
        // already handled, should be skipped by parent
        .Phi => null,
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
    return switch (ref.kind) {
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
}

pub const Value = struct {
    state: State = State.undef,
    constant: ?Constant = null,

    pub const State = enum { undef, unknown, constant };
    pub const Constant = struct {
        value: i64,
        kind: Kind,

        pub const Kind = enum {
            i64,
            i1,
        };
    };
    pub const ID = IR.Register.ID;

    fn is_int(self: Value, int: i64) bool {
        // TODO: Check if kind is i64?
        if (self.constant) |c| {
            return c.value == int;
        }
        return false;
    }

    fn is_bool(self: Value, bul: bool) bool {
        // TODO: Check if kind is i1?
        if (self.constant) |c| {
            const bul_int: usize = @intCast(@intFromBool(bul));
            return c.value == bul_int;
        }
        return false;
    }

    inline fn constant(value: Constant) Value {
        return Value{ .state = .constant, .constant = value };
    }

    inline fn const_int(value: i64) Value {
        return Value{ .state = .constant, .constant = .{ .value = value, .kind = .i64 } };
    }

    inline fn const_bool(value: bool) Value {
        return Value{ .state = .constant, .constant = .{ .value = @intCast(@intFromBool(value)), .kind = .i1 } };
    }

    inline fn const_of(value: i64, kind: Constant.Kind) Value {
        return Value{ .state = .constant, .constant = .{ .value = value, .kind = kind } };
    }

    inline fn undef() Value {
        return Value{ .state = .undef };
    }

    inline fn unknown() Value {
        return Value{ .state = .unknown };
    }
};

/// A usage of a register we updated the value of
/// A member of the SSA edge worklist
/// NOTE: we didn't necessarily update the value to a constant
const SSAEdge = struct {
    bb: BBID,
    instID: InstID,
};

/// Push reachable usages of a register to the ssa worklist
fn add_reachable_uses_of(fun: *const Function, reg: Register, ssaWL: *ArrayList(SSAEdge), reachable: []const bool) !void {
    const start = ssaWL.items.len;
    _ = start;
    try add_reachable_uses_of_reg_from_bb(fun, reg, reg.bb, ssaWL, reachable);
    // TODO: filter repeat offenders from start -> end
    // by setting them to null
}

/// The inner function of reachable_uses_of
/// Pushes all uses
fn add_reachable_uses_of_reg_from_bb(fun: *const Function, reg: Register, bbID: BBID, ssaWL: *ArrayList(SSAEdge), reachable: []const bool) !void {
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

    // following loop assumes the current bb is reachable
    // if we are checking it
    utils.assert(reachable[bbID], "reachable_uses_of_reg_from_bb expects the bb it is checking to be reachable\n", .{});

    var inst: Inst = undefined;
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
    utils.assert(inst.isCtrlFlow(), "block does not end with ctrl flow statement (or possibly block is empty)\n", .{});

    switch (inst.op) {
        // no more blocks to check from ret
        .Ret => {},
        .Jmp => {
            const jmp = Inst.Jmp.get(inst);
            if (reachable[jmp.dest]) {
                return try add_reachable_uses_of_reg_from_bb(
                    fun,
                    reg,
                    jmp.dest,
                    ssaWL,
                    reachable,
                );
            }
        },
        .Br => {
            const br = Inst.Br.get(inst);
            if (reachable[br.iftrue]) {
                try add_reachable_uses_of_reg_from_bb(
                    fun,
                    reg,
                    br.iftrue,
                    ssaWL,
                    reachable,
                );
            }
            if (reachable[br.iffalse]) {
                return try add_reachable_uses_of_reg_from_bb(
                    fun,
                    reg,
                    br.iffalse,
                    ssaWL,
                    reachable,
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

fn sccp_all_funs(ir: *const IR) !void {
    const funs = ir.funcs.items.items;
    for (funs) |*fun| {
        _ = try sccp(testAlloc, ir, fun);
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

test "sccp.removes-never-taken-if" {
    log.empty();
    errdefer log.print();

    try expectResultsInIR(
        \\fun main() void {
        \\  int a;
        \\  if (false) {
        \\    a = 1;
        \\  } else {
        \\    a = 2;
        \\  }
        \\}
    , .{
        "define void @main() {",
        "entry:",
        "  %a = alloca i64",
        "  store i64 2, i64* %a",
        "  br label %exit",
        "exit:",
        "  ret void",
        "}",
    }, .{
        .{ "main", .{.sccp} },
    });
}

// test "sccp.removes-nested-never-ran-while" {
//     log.empty();
//     errdefer log.print();
//     try expectResultsInIR(
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
//     , .{
//         "define void @main() {",
//         "entry:",
//         "  %a = alloca i64",
//         "  store i64 2, i64* %a",
//         "  br label %exit",
//         "exit:",
//         "  ret void",
//         "}",
//     }, .{
//         .{ "main", .{.sccp} },
//     });
// }