pub const std = @import("std");
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

pub fn deadCodeElim(ir: *IR, print: bool) !void {
    var arena_alloc = std.heap.ArenaAllocator.init(ir.alloc);
    var alloc = arena_alloc.allocator();
    defer arena_alloc.deinit();

    for (ir.funcs.items.items) |*fun| {
        // var list = markDeadCode(alloc, fun) catch |err| {
        //     std.debug.print("Error: {any}\n", .{err});
        // };
        var list = try markDeadCode(alloc, fun);

        if (print) {
            std.debug.print("Dead code elimination for function {any}:\n", .{fun.name});
            for (fun.bbs.items()) |bb| {
                for (bb.insts.items()) |inst| {
                    if (!list[inst]) {
                        std.debug.print("  {any}\n", .{fun.insts.get(inst).*});
                    }
                }
            }
        }
    }
}

pub fn markDeadCode(alloc: Alloc, function: *const Function) ![]bool {
    // Psuedocode:
    //
    // Create a workingList which is an array of boolean values for each operation in the function (true means it is in the working list)
    // Create a criticalMarkList which is an array of booleans for each operation in the function (true means it is critical)
    // set all values in workingList and critMarkList to false
    //
    // For each opertation in the function
    //    if the operation is one of the predefined critical operations (prints, reads, etc)
    //       mark the operation as critical
    //       mark the operation as a working operation
    //
    // while the workingList is not all false
    //    op = un-mark the first marked operation in the workingList
    //    for each source operation of op
    //       if the source is not marked in the criticalMarkList
    //          mark the source operation in the criticalMarkList
    //          mark the source operation in the workingList
    const instrunctionCount = function.insts.len;
    var workingList = workingList: {
        // var workingList = try alloc.alloc(bool, function.insts.len);
        var workingList = ArrayList(InstID).init(alloc);
        // @memset(workingList, false);
        break :workingList workingList;
    };
    var critMarkList = critMarkList: {
        var critMarkList = try alloc.alloc(bool, function.insts.len);
        @memset(critMarkList, false);
        break :critMarkList critMarkList;
    };
    const insts = &function.insts;
    const regs = &function.regs;

    for (function.bbs.items()) |bb| {
        for (bb.insts.items()) |bbinstID| {
            const inst = insts.get(bbinstID).*;
            if (inst.op == .Ret or
                inst.op == .Call or
                inst.op == .Load)
            {
                critMarkList[bbinstID] = true;
                try workingList.append(bbinstID);
            }
        }
    }

    while (workingList.items.len != 0) {
        const instID = workingList.pop();
        const inst = insts.get(instID).*;
        const sources = try getSources(inst, alloc);
        for (sources.items) |source| {
            if (source < instrunctionCount) {
                const sourceID = regs.get(source).inst;
                if (!critMarkList[sourceID]) {
                    critMarkList[sourceID] = true;
                    try workingList.append(sourceID);
                }
            }
        }
    }

    // clearWorkingList:
    //     for (workingList)
    // std.debug.print("workingList: {any}\n", .{workingList});
    // std.debug.print("critMarkList: {any}\n", .{critMarkList});
    // std.debug.print("insts: {any}\n", .{insts});
    return critMarkList;
}

// take in an instruction and return an arrayList of the registerIDs that are used in the instruction
fn getSources(inst: Inst, alloc: Alloc) !ArrayList(RegID) {
    var sources = ArrayList(RegID).init(alloc);

    switch (inst.op) {
        .Binop => {
            const binop = Inst.Binop.get(inst);
            try sources.append(binop.lhs.i);
            try sources.append(binop.rhs.i);
        },
        .Cmp => {
            const cmp = Inst.Cmp.get(inst);
            try sources.append(cmp.lhs.i);
            try sources.append(cmp.rhs.i);
        },
        .Zext, .Sext, .Trunc, .Bitcast => {
            const misc = Inst.Misc.get(inst);
            try sources.append(misc.from.i);
        },
        .Load => {
            const load = Inst.Load.get(inst);
            try sources.append(load.ptr.i);
        },
        .Gep => {
            const gep = Inst.Gep.get(inst);
            try sources.append(gep.ptrVal.i);
            try sources.append(gep.index.i);
        },
        .Call => {
            const call = Inst.Call.get(inst);
            for (call.args) |arg| {
                try sources.append(arg.i);
            }
        },
        .Phi => {
            const phi = Inst.Phi.get(inst);
            for (phi.entries.items) |entry| {
                try sources.append(entry.ref.i);
            }
        },
        .Ret => {
            const ret = Inst.Ret.get(inst);
            try sources.append(ret.val.i);
        },
        .Store => {
            const store = Inst.Store.get(inst);
            try sources.append(store.from.i);
            try sources.append(store.to.i);
        },
        .Br => {
            const br = Inst.Br.get(inst);
            try sources.append(br.on.i);
        },
        // no registers
        .Alloc, .Param, .Jmp => {},
    }
    return sources;
}

const testAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try @import("../ast.zig").initFromParser(parser);
    const ir = try @import("phi.zig").generate(testAlloc, &ast);
    return ir;
}

test "deadCodeElim.compilation" {
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
    try deadCodeElim(&ir, true);
}
// test "deadCodeElim.ir_elimTest" {
//     var ir = try testMe(
//         \\fun main() void {
//         \\  int a,b;
//         \\  a = 1;
//         \\  if (param) {
//         \\     a = 2;
//         \\  }
//
//         \\  b = a;
//         \\}
//     );
//     try deadCodeElim(&ir, true);
// }
