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

pub fn deadCodeElim(ir: *IR, fun: *Function, print: bool) !void {
    var arena_alloc = std.heap.ArenaAllocator.init(ir.alloc);
    var alloc = arena_alloc.allocator();
    defer arena_alloc.deinit();

    var list = try markDeadCode(alloc, fun);
    for (fun.bbs.items()) |*bb| {
        var i: u32 = 0;
        while (i != bb.insts.items().len) {
            const inst = bb.insts.items()[i];
            if (!list[inst]) {
                bb.insts.remove(i);
            } else {
                i += 1;
            }
        }
    }

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
                inst.op == .Load or
                inst.op == .Br or
                inst.op == .Jmp)
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
                // .sccp => {
                //     try sccp(&ir, fun);
                // },
                // .empty_bb => {
                //     try empty_block_removal_pass(fun);
                // },
                .dead_code_elim => {
                    try deadCodeElim(&ir, fun, false);
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
        \\  int a,b,c;
        \\  a = 2;
        \\  b = a;
        \\  c = 3;
        \\  return b;
        \\}
    , .{
        "define i64 @main() {",
        "entry:",
        "  br label %body0",
        "body0:",
        "  %a2 = add i64 2, 0",
        "  br label %exit",
        "exit:",
        "  %return_reg4 = phi i64 [ %a2, %body0 ]",
        "  ret i64 %return_reg4",
        "}",
    }, .{
        .{ "main", .{.dead_code_elim} },
    });
}
