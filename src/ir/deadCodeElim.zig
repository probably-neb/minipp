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

pub fn deadCodeElim(ir: *IR) !void {
    var arena_alloc = std.heap.ArenaAllocator.init(ir.alloc);
    var alloc = arena_alloc.allocator();
    defer arena_alloc.deinit();

    for (ir.funcs.items.items) |*fun| {
        markDeadCode(alloc, fun) catch |err| {
            std.debug.print("Error: {any}\n", .{err});
        };
    }
}

pub fn markDeadCode(alloc: Alloc, function: *const Function) !void {
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
        var workingList = try alloc.alloc(bool, function.insts.len);
        @memset(workingList, false);
        break :workingList workingList;
    };
    var critMarkList = critMarkList: {
        var critMarkList = try alloc.alloc(bool, function.insts.len);
        @memset(critMarkList, false);
        break :critMarkList critMarkList;
    };
    const insts = &function.insts;
    // const regs = &function.regs;

    for (function.bbs.items()) |bb| {
        for (bb.insts.items()) |bbinstID| {
            const inst = insts.get(bbinstID).*;
            if (inst.op == .Ret or
                inst.op == .Call or
                inst.op == .Load)
            {
                critMarkList[bbinstID] = true;
                workingList[bbinstID] = true;
            }
        }
    }

    // clearWorkingList:
    //     for (workingList)
    for (0..instrunctionCount) |i| {
        if (workingList[i]) {
            std.debug.print("workingList: {any}\n", .{workingList[i]});
            std.debug.print("insts: {any}\n", .{insts.get(@intCast(i))});
        }
    }
    // std.debug.print("workingList: {any}\n", .{workingList});
    // std.debug.print("critMarkList: {any}\n", .{critMarkList});
    // std.debug.print("insts: {any}\n", .{insts});
}

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
    try deadCodeElim(&ir);
}
