pub const std = @import("std");
const log = @import("../log.zig");

const irPhi = @import("./ir_phi.zig");

pub fn propagateConstants(function: *irPhi.Function) *irPhi.Function {
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
