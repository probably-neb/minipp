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

pub fn markDeadCode(function: *irPhi.Function) *irPhi.Function {
    // Psuedocode:
    // Make a map of registers to (value, isConstant)
    // for each block in the function
    //    for each instruction in the block
    //        for each register in the instruction
    //            if the map[register] is a constant:
    //                replace the register with the constant
    //
    //        if the instruction is made up of constants:
    //             remove the instruction and...
    //             Set the map[register] to the constant

    return function;
}

pub 

