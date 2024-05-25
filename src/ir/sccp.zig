const std = @import("std");
const Alloc = std.mem.Allocator;
const ArrayList = std.ArrayList;

const utils = @import("../utils.zig");

const IR = @import("./ir_phi.zig");
const Function = IR.Function;
const BasicBlock = IR.BasicBlock;
const BBID = BasicBlock.ID;
const Inst = IR.Inst;
const Register = IR.Register;
const RegID = Register.ID;
const Ref = IR.Ref;

const IMMEDIATE_FALSE = IR.InternPool.FALSE;
const IMMEDIATE_TRUE = IR.InternPool.TRUE;
const IMMEDIATE_ZERO = IR.InternPool.ZERO;
const IMMEDIATE_ONE = IR.InternPool.ONE;

const Values = []Value;

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
pub fn sccp(ir: *IR) !void {
    var arena_alloc = std.heap.ArenaAllocator.init(ir.alloc);
    var alloc = arena_alloc.allocator();
    defer arena_alloc.deinit();

    for (ir.funcs.items.items) |*fun| {
        main_loop(alloc, ir, fun) catch |err| {
            std.debug.print("Error: {any}\n", .{err});
        };
    }
}

pub fn main_loop(alloc: Alloc, ir: *const IR, fun: *const Function) !void {
    var executable = exec: {
        var executable = try alloc.alloc(bool, @intCast(fun.bbs.len));
        @memset(executable, false);
        break :exec executable;
    };
    var values = values: {
        const numValues: usize = @intCast(fun.regs.len);
        var values = try alloc.alloc(Value, numValues);
        @memset(values, Value.undef());
        break :values values;
    };
    var bbWL = bbwl: {
        var bbwl = ArrayList(BasicBlock.ID).init(alloc);
        try bbwl.append(Function.entryBBID);
        break :bbwl bbwl;
    };
    var ssaWL = ArrayList(SSAEdge).init(alloc);
    _ = ssaWL;

    const insts = &fun.insts;

    while (true) {
        if (bbWL.popOrNull()) |bbID| {
            if (executable[bbID]) {
                continue;
            }
            executable[bbID] = true;

            const bb = fun.bbs.get(bbID);
            const phiInstructionIDs = bb.phiInsts.items;

            for (phiInstructionIDs) |phiInstID| {
                // visit_phi [x := phi(y, z)] -> Value[x] = y /\ z
                const inst = insts.get(phiInstID).*;
                utils.assert(inst.op == .Phi, "phi inst not phi??? ({s} instead) wtf dylan!\n", .{@tagName(inst.op)});
                const phi = Inst.Phi.get(inst);

                const res = phi.res;
                utils.assert(res.kind == .local, "phi res not local is {s}\n", .{@tagName(res.kind)});

                var value: *Value = &values[res.i];
                _ = value;
                for (phi.entries.items) |option| {
                    const optionBB = option.bb;
                    _ = optionBB;
                    const ref = option.ref;
                    const optionValue = switch (ref.kind) {
                        .local => values[ref.i],
                        .immediate => switch (ref.type) {
                            .bool => Value.immediate(.{ .bool = ref.i == IMMEDIATE_TRUE }),
                            .int => Value.immediate(.{ .int = ir.parseInt(ref.i) catch unreachable }),
                            .void => unreachable,
                            else => Value.unknown(),
                        },
                        .immediate_u32 => Value.immediate(.{ .int = @as(i64, ref.i) }),
                        .global, .param => Value.undef(),
                        ._invalid, .label => unreachable,
                    };
                    _ = optionValue;
                }
            }
        }
    }
}

fn meet(a: *const Value, b: *const Value) Value {
    if (a.state == .unknown or b.state == .unknown) {
        return Value{ .state = .unknown };
    }
    if (a.state == .undefined) {
        return b.*;
    }
    if (b.state == .undefined) {
        return a.*;
    }
    // both constant -> unknown
    return Value{ .state = .unknown };
}

const Value = struct {
    state: State = State.undef,
    value: ?Constant = null,

    pub const State = enum { undef, unknown, constant };
    pub const Constant = union(enum) {
        int: i64,
        bool: bool,
    };
    pub const ID = IR.Register.ID;

    inline fn immediate(value: Constant) Value {
        return Value{ .state = .constant, .value = value };
    }

    inline fn undef() Value {
        return Value{ .state = .undef };
    }

    inline fn unknown() Value {
        return Value{ .state = .unknown };
    }
};

const SSAEdge = struct {
    def: Ref,
    use: Ref,
};

const testAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try @import("../ast.zig").initFromParser(parser);
    const ir = try @import("phi.zig").generate(testAlloc, &ast);
    return ir;
}

test "compilation" {
    var ir = try testMe(
        \\fun main() void {
        \\  int a;
        \\  if (true) {
        \\    while (false) {
        \\      a = 1;
        \\      a = 3;
        \\    }
        \\  }
        \\  a = 2;
        \\}
    );
    try sccp(&ir);
}
