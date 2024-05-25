pub const std = @import("std");
const log = @import("../log.zig");
const utils = @import("../utils.zig");

const IR = @import("ir.zig");

pub const Imm = IR.StrID;

pub const Reg = struct {
    id: ID, // the id of the register within the register list in a bloack
    name: IR.StrID, // the name of the register
    // kind: RegKind, this could be useed for vector type beat
    inst: Inst.ID, // the ID of the instruction that defines this register
    bb: BasicBlock.ID, // the ID of the basic block that contains the instruction

    pub const ID = usize;
};

pub const OperandKind = enum {
    Reg,
    Imm,
    MemReg, // addr = Xn
    MemImm, // addr = Xn + imm
    MemPostInc, // addr = Xn, Xn = Xn + imm
    MemPreInc, // Xn = Xn + imm, addr = Xn
};

// for the branch instructions
// the offset is the offset from the current PC
// we will not really be needing this (shocker)
// so the label will be used instead
pub const Operand = struct {
    kind: OperandKind,
    reg: Reg,
    imm: Imm,
    label: BasicBlock.ID,
    // also can be thought of in this format
    // mem: struct {
    //     base: Reg,
    //     offset: Imm,
    // },
};

pub const ConditionCode = enum {
    EQ, // Z == 1
    NE, // Z == 0
    GE, // N == V
    LE, // Z == 1 or N != V
    GT, // Z == 0 and N == V
    LT, // N != V
    // not covered in class, but useful
    CS, // C == 1
    CC, // C == 0
    MI, // N == 1
    PL, // N == 0
    VS, // V == 1
    VC, // V == 0
    HI, // C == 1 and Z == 0
    LS, // C == 0 or Z == 1
    AL, // always
};

pub const Operation = enum {
    ADD, // rd = rn + op2
    SUB, // rd = rn - op2
    MUL, // rd = rn * op2
    DIV, // rd = rn / op2
    AND, // rd = rn & op2
    ASR, // rd = rn >> op2
    LSL, // rd = rn << op2
    CMP, // rd - op2
    MOV, // rd = op2
    B, // PC = PC +- rel(27:2):O2
    Bcc, // if(cc) PC = PC +- rel(27:2):O2
    BL, // X30 = PC + 4; PC = PC +- rel(27:2):O2
    LDP, // rt2:rt = [addr]_{2N}
    LDR, // rt = [addr]_{N}
    STP, // [addr]_{2N} = rt2:rt
    STR, // [addr]_{N} = rt
    // there are more operations, but these are the ones we will use
};

pub const Inst = struct {
    oper: Operation,
    /// The resulting register
    res: Reg = Reg.default,
    op1: Operand,
    op2: Operand,
    op3: Operand,
    id: ID,

    signed: bool = true,
    width: u32 = 64,
    cc: ConditionCode,

    pub const ID = usize;
};

pub const BasicBlock = struct {
    name: []const u8,
    incomers: std.ArrayList(BasicBlock.ID),
    outgoers: [2]?BasicBlock.ID,
    insts: std.ArrayList(Inst.ID),
    id: ID,
    pub const ID = usize;
};
