const std = @import("std");
const IR = @import("./ir_phi.zig");
const utils = @import("../utils.zig");
const Arm = @import("arm.zig");

const Alloc = std.mem.Allocator;

pub const INDENT = "    ";

const Buf = struct {
    str: std.ArrayList(u8),
    alloc: Alloc,

    fn init(alloc: Alloc) Buf {
        return Buf{
            .str = std.ArrayList(u8).init(alloc),
            .alloc = alloc,
        };
    }

    fn write(self: *Buf, str: []const u8) !void {
        try self.fmt("{s}", .{str});
    }

    fn fmt(self: *Buf, comptime fmt_str: []const u8, args: anytype) !void {
        const string = try std.fmt.allocPrint(self.alloc, fmt_str, args);
        defer self.alloc.free(string);
        for (string) |c| {
            try self.str.append(c);
        }
    }
};

/// A struct to help with printing/formatting the IR
/// Basically ultra specific rope data structure (hence the name)
/// that accounts only for the cases we encounter when printing IR
/// Mainly for avoiding having to do manual string concatenation/allocation
/// by allowing variable parts to be variable and constant parts to be constant
const Rope = struct {
    // some (possibly empty) (possibly variable i.e. not const) string
    // will always be printed first
    a: []const u8,
    // another (possibly empty) (possibly variable i.e. not const) string
    // will always be printed after `a`. see num_before_b to understand how
    // it will be printed with respect to num
    b: []const u8,
    // an optionally null number to print. will only be printed if it is not null
    // an i128 just so it has enough room for anything that would fit in a i64
    // plus some (a lot of) wiggle room just in case idk
    num: ?i128 = null,
    // decides wether to print num then print b or vice versa.
    // useful because sometimes the number goes at the end i.e.
    // named result registers (`%{name}{instruction number}` ex. `%foo3`) where:
    //  a := "%"
    //  b := {name}
    //  num := {instruction number}
    // or alternatively
    // in array types (`[ {len} x {type} ]` ex. `[ 4 x i32 ]`) where
    //  a := "[ "
    //  b := " x i32 ]" or " x i8 ]" depending on {type}
    //  num  := {len}
    //  in this case we can use the num_before_b flag to get the correct format
    num_before_b: bool = false,
    // decides wether to print a pointer symbol (*) after
    // everything else is printed
    // used in the `.ptr()` and `.not_ptr()` methods to control
    // whether something has a pointer postfix or not i.e.
    // in bitcast:
    //   the from type is always a pointer, so it has a *,
    //   but we always assume i8s and structs are pointers,
    //   (i.e. `stringify_type(IR.Type.i8) => Rope.just("i8").ptr()`)
    //   so we call `.not_ptr()` on it and put the * in the format string
    //   so things that are already pointers don't become double pointers
    //   and things that aren't pointers become pointers
    // another useful example is the `gep` instruction:
    //   the basis type (first type param which will be used to do ptr arithmetic)
    //   is the only place a struct is not a pointer type but its actual type
    //   therefore we can just call `.not_ptr()` on the basis type and have
    //   everything work out
    // also note that having it in a bool allows multiple call sites to call `.ptr()`
    // on a rope and have it only result in a single * postfix
    is_ptr: bool = false,

    // zig will use this to format the struct
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        _ = try writer.write(self.a);
        if (self.num) |n| {
            if (self.num_before_b) {
                try writer.print("{d}", .{n});
                _ = try writer.write(self.b);
            } else {
                _ = try writer.write(self.b);
                try writer.print("{d}", .{n});
            }
        } else {
            _ = try writer.write(self.b);
        }
        if (self.is_ptr) {
            _ = try writer.write("*");
        }
    }

    /// print `{a}{b}`
    fn pair(a: []const u8, b: []const u8) Rope {
        return Rope{ .a = a, .b = b };
    }

    /// print `{a}`
    fn just(a: []const u8) Rope {
        return Rope{ .a = a, .b = "" };
    }

    /// print `{num}`
    fn just_num(num: anytype) Rope {
        return Rope{ .a = "", .b = "", .num = @intCast(num) };
    }

    /// print `{a}{num}`
    fn str_num(a: []const u8, num: anytype) Rope {
        return Rope{ .a = a, .b = "", .num = @intCast(num) };
    }

    /// print `{a}{b}{num}`
    fn str_str_num(a: []const u8, b: []const u8, num: anytype) Rope {
        return Rope{ .a = a, .b = b, .num = @intCast(num) };
    }

    /// print `{a}{num}{b}`
    fn str_num_str(a: []const u8, num: anytype, b: []const u8) Rope {
        return Rope{ .a = a, .b = b, .num = @intCast(num), .num_before_b = true };
    }

    /// takes a rope and returns a new rope with `is_ptr` set to true
    fn ptr(s: Rope) Rope {
        var r = s;
        r.is_ptr = true;
        return r;
    }

    /// takes a rope and returns a new rope with `is_ptr` set to false
    fn not_ptr(s: Rope) Rope {
        var r = s;
        r.is_ptr = false;
        return r;
    }

    /// takes a rope and returns a new rope with `is_ptr` set to `cond`
    fn ptr_if(s: Rope, cond: bool) Rope {
        var r = s;
        r.is_ptr = cond;
        return r;
    }

    /// like ptr_if except only sets is_ptr to true if cond is true
    /// i.e. does nothing if cond is false. Used to ensure a value is a pointer
    /// if some condition is true without changing its pointereyness
    /// if the condition doesn't hold
    fn ensure_ptr_if(s: Rope, cond: bool) Rope {
        var r = s;
        if (cond) {
            r.is_ptr = true;
        }
        return r;
    }
};

pub fn stringify(arm: *const Arm, ir: *const IR, alloc: Alloc) ![]const u8 {
    var buf = Buf.init(alloc);

    // stringify global variables
    {
        try buf.write(INDENT);
        try buf.write(".section .data\n");
        try buf.write("_print:\n");
        try buf.write(INDENT);
        try buf.write(".string \"%ld\\00\"\n");
        try buf.write("_println:\n");
        try buf.write(INDENT);
        try buf.write(".string \"%ld\\n\"\n");
        try buf.write("_read:\n");
        try buf.write(INDENT);
        try buf.write(".string \"%ld\\00\"\n");

        for (arm.program.globals.items) |globalStrID| {
            try buf.fmt("{s}:\n", .{ir.getIdent(globalStrID)});
            try buf.write(INDENT);
            try buf.write(".quad ");
            try buf.write("0xDEADBEEF\n");
        }
    }
    try buf.write(INDENT);
    try buf.write(".section .text\n");
    try buf.write(INDENT);
    try buf.write(".global main\n");
    try buf.write(INDENT);
    try buf.write(".extern printf\n");

    // stringify functions
    for (arm.program.functions.items) |*fun| {
        // FUNCTION:
        try buf.fmt("{s}:\n", .{ir.getIdent(fun.name)});
        //     // Reserve space on the stack including space to save the original SP
        try buf.write("stp     x20, x19, [sp, #-32]!   \n");
        try buf.write(INDENT);
        try buf.write("stp     x29, x30, [sp, #16]     \n");
        try buf.write(INDENT);
        try buf.write("add     x29, sp, #16           \n");
        try buf.write(INDENT);
        // add the spill area to the stack pointer
        // calculate the size of the spill area
        var spilledMin = (1 + fun.spilledNum) * 16;
        // increase the pc by the size of the spill area
        try buf.fmt("sub sp, sp, {d}\n", .{spilledMin});
        // we are good to go

        try buf.write("stp     x27, x28, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x25, x26, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x23, x24, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x21, x22, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x17, x18, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x15, x16, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x14, x13, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x11, x12, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("stp     x10, x9, [sp, #-16]!\n");
        try buf.write(INDENT);
        try buf.write("mov x16, sp\n");
        try buf.write(INDENT);
        // strinify basic blocks
        for (fun.blocks.items) |armBB| {
            var rp = Rope.str_str_num(armBB.name, "_", armBB.id);
            buf.fmt("{s}_{s}:\n", .{ ir.getIdent(fun.name), rp }) catch unreachable;
            for (armBB.insts.items) |inst| {
                try stringify_spill_inst(arm.program.insts.items[inst], &buf, ir, fun);
            }
        }
    }

    return buf.str.items;
}

pub fn stringify_reg_comment(buf: *Buf, reg: Arm.Reg) !void {
    try buf.fmt("(R: id{any}, name{any}, inst{any}, ir{any}, sel{s})", .{ reg.id, reg.name, reg.inst, reg.irID, @tagName(reg.selection) });
}

pub fn stringify_operand_comment(buf: *Buf, op: Arm.Operand) !void {
    try buf.fmt("(O:{s}, ", .{@tagName(op.kind)});
    switch (op.kind) {
        .Reg, .MemReg, .MemGlobal => {
            try stringify_reg_comment(buf, op.reg);
        },
        .Imm, .MemImm => {
            try buf.fmt("#{any}", .{op.imm});
        },
        .MemPostInc, .MemPreInc => {
            try buf.fmt("#{any}, ", .{op.imm});
            try stringify_reg_comment(buf, op.reg);
        },
        .Label => {
            try buf.fmt("{any}", .{op.label});
        },
        else => {
            std.debug.print("operand: {any}\n", .{op});
        },
    }
    try buf.write(")");
}

pub fn stringify_spill_inst(inst: Arm.Inst, buf: *Buf, ir: *const IR, fun: *Arm.Function) !void {
    switch (inst.oper) {
        .ADD, .SUB, .MUL, .DIV, .AND, .ORR, .EOR, .ASR, .LSL => {
            // load and load 2, then store
            if (inst.op1.reg.spillIndex != null) {
                var inst1Index = inst.op1.reg.spillIndex.?;
                var spillOffset = 16 + inst1Index * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("LDR x10, [x12, #0]\n");
            }
            if (inst.op2.reg.spillIndex != null) {
                var inst2Index = inst.op2.reg.spillIndex.?;
                var spillOffset = 16 + inst2Index * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("LDR x11, [x12, #0]\n");
            }

            try stringify_inst(inst, buf, ir, fun);
            if (inst.rd.spillIndex != null) {
                var rdIndex = inst.rd.spillIndex.?;
                var spillOffset = 16 + rdIndex * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("STR x9, [x12, #0]\n");
            }
        },
        .NEG, .MOV, .LDR => {
            // load and store
            if (inst.op1.reg.spillIndex != null) {
                var inst1Index = inst.op1.reg.spillIndex.?;
                var spillOffset = 16 + inst1Index * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("LDR x10, [x12, #0]\n");
            }
            try stringify_inst(inst, buf, ir, fun);
            // store the result
            if (inst.rd.spillIndex != null) {
                var rdIndex = inst.rd.spillIndex.?;
                var spillOffset = 16 + rdIndex * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("STR x9, [x12, #0]\n");
            }
        },
        .CMP => {
            // load and load2
            if (inst.rd.spillIndex != null) {
                var inst1Index = inst.rd.spillIndex.?;
                var spillOffset = 16 + inst1Index * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("LDR x9, [x12, #0]\n");
            }
            if (inst.op1.reg.spillIndex != null) {
                var inst2Index = inst.op1.reg.spillIndex.?;
                var spillOffset = 16 + inst2Index * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("LDR x10, [x12, #0]\n");
            }
            try stringify_inst(inst, buf, ir, fun);
        },
        .STR => {
            // load and load2
            if (inst.rd.spillIndex != null) {
                var inst1Index = inst.rd.spillIndex.?;
                var spillOffset = 16 + inst1Index * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("LDR x10, [x12, #0]\n");
            }
            if (inst.op1.reg.spillIndex != null) {
                var inst2Index = inst.op1.reg.spillIndex.?;
                var spillOffset = 16 + inst2Index * 16;
                try buf.write(INDENT);
                try buf.write("ADD x12, x29, #-");
                try buf.fmt("{d}", .{spillOffset});
                try buf.write("\n");
                try buf.write(INDENT);
                try buf.write("LDR x11, [x12, #0]\n");
            }
            try stringify_inst(inst, buf, ir, fun);
        },
        else => {
            try stringify_inst(inst, buf, ir, fun);
        },
    }
}

pub fn stringify_inst(inst: Arm.Inst, buf: *Buf, ir: *const IR, fun: *Arm.Function) !void {
    try buf.write(INDENT);
    try stringify_operation(inst.oper, buf);
    // print out the buffer
    // std.debug.print("inst: {s}\n", .{buf.str.items});
    switch (inst.oper) {
        .ADD, .SUB, .MUL, .DIV, .AND, .ORR, .EOR, .ASR, .LSL => {
            try stringify_register(inst.rd, ir, buf, true, false);
            try buf.write(", ");
            try stringify_operand(inst.op1, ir, buf, fun, false, false);
            try buf.write(", ");
            try stringify_operand(inst.op2, ir, buf, fun, false, true);
            // try buf.write("; ");
            // try stringify_reg_comment(buf, inst.rd);
            // try buf.write(" = ");
            // try stringify_operand_comment(buf, inst.op1);
            // try buf.write(" ");
            // try stringify_operand_comment(buf, inst.op2);
        },
        .NEG, .CMP => {
            try stringify_register(inst.rd, ir, buf, true, false);
            try buf.write(", ");
            try stringify_operand(inst.op1, ir, buf, fun, false, false);
            // try buf.write("; ");
            // try stringify_reg_comment(buf, inst.rd);
            // try buf.write("   ");
            // try stringify_operand_comment(buf, inst.op1);
        },
        .MOV => {
            try stringify_register(inst.rd, ir, buf, true, false);
            try buf.write(", ");
            try stringify_operand(inst.op1, ir, buf, fun, false, false);
            // try buf.write("; ");
            // try stringify_reg_comment(buf, inst.rd);
            // try buf.write("   ");
            // try stringify_operand_comment(buf, inst.op1);
        },
        .Bcc => {
            try buf.write("B");
            switch (inst.cc) {
                .EQ => try buf.write("EQ"),
                .NE => try buf.write("NE"),
                .CS => try buf.write("CS"),
                .CC => try buf.write("CC"),
                .MI => try buf.write("MI"),
                .PL => try buf.write("PL"),
                .VS => try buf.write("VS"),
                .VC => try buf.write("VC"),
                .HI => try buf.write("HI"),
                .LS => try buf.write("LS"),
                .GE => try buf.write("GE"),
                .LT => try buf.write("LT"),
                .GT => try buf.write("GT"),
                .LE => try buf.write("LE"),
                .AL => try buf.write("AL"),
                else => unreachable,
            }
            try buf.write(" ");
            try stringify_operand(inst.op1, ir, buf, fun, false, false);
        },
        .B => {
            try stringify_operand(inst.op1, ir, buf, fun, false, false);
        },
        .BL => {
            // print out the function name, this is
            try buf.fmt("{s}", .{ir.getIdent(@truncate(inst.op1.label))});
        },
        .LDR => {
            try stringify_register(inst.rd, ir, buf, true, false);
            try buf.write(", ");
            try stringify_operand(inst.op1, ir, buf, fun, false, false);
            // try buf.write("; ");
            // try stringify_reg_comment(buf, inst.rd);
            // try buf.write("   ");
            // try stringify_operand_comment(buf, inst.op1);
        },
        .STR => {
            try stringify_register(inst.rd, ir, buf, false, false);
            try buf.write(", ");
            try stringify_operand(inst.op1, ir, buf, fun, false, true);
            try buf.write("; ");
            // try stringify_reg_comment(buf, inst.rd);
            // try buf.write("   ");
            // try stringify_operand_comment(buf, inst.op1);
        },
        .PRINT_THIS_LOL => {
            try buf.fmt("{s}", .{ir.getIdent(@truncate(inst.op1.imm))});
        },
        .RET => {
            try buf.write("mov sp, x16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x10, x9, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x11, x12, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x14, x13, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x15, x16, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x17, x18, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x21, x22, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x23, x24, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x25, x26, [sp], #16\n");
            try buf.write(INDENT);
            try buf.write("ldp     x27, x28, [sp], #16\n");
            try buf.write(INDENT);
            // now we can undo the spill area
            var spilledMin = (1 + fun.spilledNum) * 16;
            try buf.fmt("add sp, sp, {d}\n", .{spilledMin});
            try buf.write(INDENT);
            try buf.write("ldp     x29, x30, [sp, #16]     \n");
            try buf.write(INDENT);
            try buf.write("ldp     x20, x19, [sp], #32    \n");
            try buf.write(INDENT);
            try buf.write("ret\n");
        },
        else => unreachable,
    }
    try buf.write("\n");
}

pub fn stringify_operation(operation: Arm.Operation, buf: *Buf) !void {
    switch (operation) {
        .NEG => try buf.write("NEG "),
        .ADD => try buf.write("ADD "),
        .SUB => try buf.write("SUB "),
        .MUL => try buf.write("MUL "),
        .DIV => try buf.write("DIV "),
        .AND => try buf.write("AND "),
        .ORR => try buf.write("ORR "),
        .EOR => try buf.write("EOR "),
        .ASR => try buf.write("ASR "),
        .LSL => try buf.write("LSL "),
        .CMP => try buf.write("CMP "),
        .MOV => try buf.write("MOV "),
        .B => try buf.write("B "),
        .Bcc => {},
        .BL => try buf.write("BL "),
        .LDP => try buf.write("LDP "),
        .LDR => try buf.write("LDR "),
        .STP => try buf.write("STP "),
        .STR => try buf.write("STR "),
        .RET => try buf.write(""),
        .PRINT_THIS_LOL => {},
    }
}

pub fn stringify_register(reg: Arm.Reg, ir: *const IR, buf: *Buf, assignment: bool, alt: bool) !void {
    if (reg.spillIndex == null) {
        switch (reg.selection) {
            .none => {
                if (reg.name == IR.InternPool.NULL) {
                    try buf.fmt("R_{any}", .{reg.irID});
                } else {
                    try buf.fmt("R{s}", .{ir.getIdent(reg.name)});
                }
            },
            .X0 => try buf.write("X0"),
            .X1 => try buf.write("X1"),
            .X2 => try buf.write("X2"),
            .X3 => try buf.write("X3"),
            .X4 => try buf.write("X4"),
            .X5 => try buf.write("X5"),
            .X6 => try buf.write("X6"),
            .X7 => try buf.write("X7"),
            .X8 => try buf.write("X8"),
            .X9 => try buf.write("X9"),
            .X10 => try buf.write("X10"),
            .X11 => try buf.write("X11"),
            .X12 => try buf.write("X12"),
            .X13 => try buf.write("X13"),
            .X14 => try buf.write("X14"),
            .X15 => try buf.write("X15"),
            .X16 => try buf.write("X16"),
            .X17 => try buf.write("X17"),
            .X18 => try buf.write("X18"),
            .X19 => try buf.write("X19"),
            .X20 => try buf.write("X20"),
            .X21 => try buf.write("X21"),
            .X22 => try buf.write("X22"),
            .X23 => try buf.write("X23"),
            .X24 => try buf.write("X24"),
            .X25 => try buf.write("X25"),
            .X26 => try buf.write("X26"),
            .X27 => try buf.write("X27"),
            .X28 => try buf.write("X28"),
            .X29 => try buf.write("X29"),
            .X30 => try buf.write("X30"),
            .SP => try buf.write("SP"),
        }
    } else {
        if (assignment) {
            try buf.write("x9");
        } else {
            if (alt) {
                try buf.write("x11");
            } else {
                try buf.write("x10");
            }
        }
    }
}

pub fn stringify_operand(operand: Arm.Operand, ir: *const IR, buf: *Buf, fun: *Arm.Function, assignment: bool, alt: bool) !void {
    switch (operand.kind) {
        .Reg => {
            try stringify_register(operand.reg, ir, buf, assignment, alt);
        },
        .Imm => {
            try buf.write("#");
            try buf.fmt("{s}", .{ir.getIdent(operand.imm)});
        },
        .MemReg => {
            try buf.write("[");
            try stringify_register(operand.reg, ir, buf, assignment, alt);
            try buf.write("]");
        },
        .MemImm => {
            try buf.write("[#");
            try buf.fmt("{s}", .{ir.getIdent(operand.imm)});
            try buf.write("]");
        },
        .MemPostInc => {
            try buf.write("[");
            try stringify_register(operand.reg, ir, buf, assignment, alt);
            try buf.write("],");
            try buf.fmt("{d}", .{ir.getIdent(operand.imm)});
        },
        .MemPreInc => {
            try buf.write("[");
            try stringify_register(operand.reg, ir, buf, assignment, alt);
            try buf.fmt(", {s}", .{ir.getIdent(operand.imm)});
            try buf.write("]!");
        },
        .MemGlobal => {
            try buf.write("=");
            try buf.fmt("{s}", .{ir.getIdent(operand.reg.name)});
        },
        .Label => {
            var bb = fun.blocks.items[operand.label];
            try buf.fmt("{s}_{s}_{d}", .{ ir.getIdent(fun.name), bb.name, bb.id });
        },
        else => {
            std.debug.print("operand: {any}\n", .{operand});
        },
    }
}

pub fn stringify_reg(ir: *const IR, fun: *const IR.Function, regID: IR.Register.ID) Rope {
    // std.debug.print("regID: {d}\n", .{regID});
    if (regID == 69420) {
        return Rope.str_num("%_", 69420);
    }
    const reg = fun.regs.get(regID);
    switch (reg.name) {
        IR.InternPool.NULL => return Rope.str_num("%_", reg.inst),
        // IR.InternPool.TRUE, IR.InternPool.ONE => return pair_num("%", 1),
        // IR.InternPool.FALSE, IR.InternPool.ZERO => return pair_num("%", 0),
        else => return Rope.str_str_num("%", ir.getIdent(reg.name), reg.inst),
    }
}

pub fn stringify_label_ref(fun: *const IR.Function, label: IR.BasicBlock.ID) Rope {
    if (label == IR.Function.entryBBID) {
        return Rope.just("label %entry");
    } else if (label == fun.exitBBID) {
        return Rope.just("label %exit");
    }
    const name = fun.bbs.get(label).name;
    return Rope.str_str_num("label %", name, label - 1);
}

pub fn stringify_label_phi(fun: *const IR.Function, label: IR.BasicBlock.ID) Rope {
    if (label == IR.Function.entryBBID) {
        return Rope.just("%entry");
    } else if (label == fun.exitBBID) {
        return Rope.just("%exit");
    }
    const name = fun.bbs.get(label).name;
    return Rope.str_str_num("%", name, label - 1);
}
