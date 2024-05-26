pub const std = @import("std");
const log = @import("../log.zig");
const utils = @import("../utils.zig");

const IR = @import("ir_phi.zig");

pub const Arm = @This();

pub const Imm = IR.StrID;

pub const Reg = struct {
    id: ID, // the id of the register within the register list in a bloack
    name: IR.StrID, // the name of the register
    // kind: RegKind, this could be useed for vector type beat
    inst: Inst.ID, // the ID of the instruction that defines this register
    pub const ID = usize;
};

pub const OperandKind = enum {
    Reg,
    Imm,
    MemReg, // addr = Xn
    MemImm, // addr = Xn + imm
    MemPostInc, // addr = Xn, Xn = Xn + imm
    MemPreInc, // Xn = Xn + imm, addr = Xn
    Label,
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
    pub fn asOpReg(reg: Reg) Operand {
        return Operand{ .kind = .Reg, .reg = reg };
    }

    pub fn asOpImm(imm: Imm) Operand {
        return Operand{ .kind = .Imm, .imm = imm };
    }

    pub fn asOpMemReg(reg: Reg) Operand {
        return Operand{ .kind = .MemReg, .reg = reg };
    }

    pub fn asOpMemImm(reg: Reg, imm: Imm) Operand {
        return Operand{ .kind = .MemImm, .reg = reg, .imm = imm };
    }

    pub fn asOpMemPostInc(reg: Reg, imm: Imm) Operand {
        return Operand{ .kind = .MemPostInc, .reg = reg, .imm = imm };
    }

    pub fn asOpMemPreInc(reg: Reg, imm: Imm) Operand {
        return Operand{ .kind = .MemPreInc, .reg = reg, .imm = imm };
    }

    pub fn asOpLabel(label: BasicBlock.ID) Operand {
        return Operand{ .kind = .Label, .label = label };
    }

    pub fn getReg(operand: Operand) Reg {
        utils.assert(operand.kind == OperandKind.Reg, "The operand {any} was not a register, but was requested as one", .{operand});
        return operand.reg;
    }

    pub fn getImm(operand: Operand) Imm {
        utils.assert(operand.kind == OperandKind.Imm, "The operand {any} was not an immediate, but was requested as one", .{operand});
        return operand.imm;
    }

    pub fn getMemReg(operand: Operand) Reg {
        utils.assert(operand.kind == OperandKind.MemReg, "The operand {any} was not a memory register, but was requested as one", .{operand});
        return operand.reg;
    }

    pub fn getMemImm(operand: Operand) Operand {
        utils.assert(operand.kind == OperandKind.MemImm, "The operand {any} was not a memory immediate, but was requested as one", .{operand});
        return operand;
    }

    pub fn getMemPostInc(operand: Operand) Operand {
        utils.assert(operand.kind == OperandKind.MemPostInc, "The operand {any} was not a memory post increment, but was requested as one", .{operand});
        return operand;
    }

    pub fn getMemPreInc(operand: Operand) Operand {
        utils.assert(operand.kind == OperandKind.MemPreInc, "The operand {any} was not a memory pre increment, but was requested as one", .{operand});
        return operand;
    }

    pub fn getLabel(operand: Operand) BasicBlock.ID {
        utils.assert(operand.kind == OperandKind.Label, "The operand {any} was not a label, but was requested as one", .{operand});
        return operand.label;
    }

    pub fn getAMem(operand: Operand) Operand {
        utils.assert(operand.kind == OperandKind.MemImm or operand.kind == OperandKind.MemPostInc or operand.kind == OperandKind.MemPreInc or operand.kind == OperandKind.MemReg, "The operand {any} was not a memory operand, but was requested as one", .{operand});
        return operand;
    }
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
    NEG, // rd = - op2
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
    rd: Reg = Reg.default,
    op1: Operand,
    op2: Operand,
    id: ID,

    signed: bool = true,
    width: u32 = 64,
    cc: ConditionCode,
    pub const ID = usize;

    // helpers to construct the instructions
    pub const Add = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        signed: bool,

        pub fn toInst(inst: Add) Inst {
            return Inst{ .oper = .ADD, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2, .signed = inst.signed };
        }

        pub fn get(inst: Inst) Add {
            return Add{ .rd = inst.rd, .rn = inst.op1.getReg(), .op2 = inst.op2, .signed = inst.signed };
        }
    };

    pub const Sub = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        signed: bool,
        pub fn toInst(inst: Sub) Inst {
            return Inst{ .oper = .SUB, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2, .signed = inst.signed };
        }
        pub fn get(inst: Inst) Sub {
            return Sub{ .rd = inst.rd, .rn = inst.op1.getReg(), .op2 = inst.op2, .signed = inst.signed };
        }
    };

    pub const And = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        pub fn toInst(inst: And) Inst {
            return Inst{ .oper = .AND, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2 };
        }
        pub fn get(inst: Inst) And {
            return And{ .rd = inst.rd, .rn = inst.op1.getReg(), .op2 = inst.op2 };
        }
    };

    pub const Asr = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        pub fn toInst(inst: Asr) Inst {
            return Inst{ .oper = .ASR, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2 };
        }
        pub fn get(inst: Inst) Asr {
            return Asr{ .rd = inst.rd, .rn = inst.op1.getReg(), .op2 = inst.op2 };
        }
    };

    pub const Lsl = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        pub fn toInst(inst: Lsl) Inst {
            return Inst{ .oper = .LSL, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2 };
        }
        pub fn get(inst: Inst) Lsl {
            return Lsl{ .rd = inst.rd, .rn = inst.op1.getReg(), .op2 = inst.op2 };
        }
    };

    pub const Lsr = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        pub fn toInst(inst: Lsr) Inst {
            return Inst{ .oper = .LSR, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2 };
        }
        pub fn get(inst: Inst) Lsr {
            return Lsr{ .rd = inst.rd, .rn = inst.op1.getReg, .op2 = inst.op2 };
        }
    };

    // note that if it is an immediate that is being moved in, then the type of the operand will be Imm
    pub const Mov = struct {
        rd: Reg,
        op1: Operand,
        pub fn toInst(inst: Mov) Inst {
            return Inst{ .oper = .MOV, .rd = inst.rd, .op1 = inst.op1 };
        }
        pub fn get(inst: Inst) Mov {
            return Mov{ .rd = inst.rd, .op1 = inst.op1 };
        }
    };

    // NOTE: the reference guide uses op2, however this will be easier as it is consistent with the other unops that are falsely constructed
    pub const Cmp = struct {
        rd: Reg,
        op1: Operand,
        pub fn toInst(inst: Cmp) Inst {
            return Inst{ .oper = .CMP, .rd = inst.rd, .op1 = inst.op1 };
        }
        pub fn get(inst: Inst) Cmp {
            return Cmp{ .rd = inst.rd, .op1 = inst.op1 };
        }
    };

    pub const MUL = struct {
        rd: Reg,
        rn: Reg,
        rm: Reg,
        pub fn toInst(inst: MUL) Inst {
            return Inst{ .oper = .MUL, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = Operand.asOpReg(inst.rm) };
        }
        pub fn get(inst: Inst) MUL {
            return MUL{ .rd = inst.rd, .rn = inst.op1.getReg(), .rm = inst.op2.getReg() };
        }
    };

    pub const Div = struct {
        rd: Reg,
        rn: Reg,
        rm: Reg,
        signed: bool,
        pub fn toInst(inst: Div) Inst {
            return Inst{ .oper = .DIV, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = Operand.asOpReg(inst.rm), .signed = inst.signed };
        }
        pub fn get(inst: Inst) Div {
            return Div{ .rd = inst.rd, .rn = inst.op1.getReg(), .rm = inst.op2.getReg(), .signed = inst.signed };
        }
    };

    pub const B = struct {
        label: BasicBlock.ID,
        pub fn toInst(inst: B) Inst {
            return Inst{ .oper = .B, .op1 = Operand.asOpLabel(inst.label) };
        }
        pub fn get(inst: Inst) B {
            return B{ .label = Operand.getLabel(inst.op1) };
        }
    };

    pub const Bcc = struct {
        label: BasicBlock.ID,
        cc: ConditionCode,
        pub fn toInst(inst: Bcc) Inst {
            return Inst{ .oper = .Bcc, .op1 = Operand.asOpLabel(inst.label), .cc = inst.cc };
        }
        pub fn get(inst: Inst) Bcc {
            return Bcc{ .label = Operand.getLabel(inst.op1), .cc = inst.cc };
        }
    };

    pub const BL = struct {
        label: BasicBlock.ID,
        pub fn toInst(inst: BL) Inst {
            return Inst{ .oper = .BL, .op1 = Operand.asOpLabel(inst.label) };
        }
        pub fn get(inst: Inst) BL {
            return BL{ .label = Operand.getLabel(inst.op1) };
        }
    };

    pub const LDP = struct {
        rt: Reg,
        rt2: Reg,
        addr: Operand,
        pub fn toInst(inst: LDP) Inst {
            return Inst{ .oper = .LDP, .rd = inst.rt, .op2 = Operand.asOpReg(inst.rt2), .op1 = inst.addr };
        }
        pub fn get(inst: Inst) LDP {
            return LDP{ .rt = inst.rd, .rt2 = inst.op2.getReg(), .addr = inst.op1.getAMem() };
        }
    };

    // can also be LDUR the sign extended version
    pub const LDR = struct {
        rt: Reg,
        addr: Operand,
        signed: bool,
        pub fn toInst(inst: LDR) Inst {
            return Inst{ .oper = .LDR, .rd = inst.rt, .op1 = inst.addr, .signed = inst.signed };
        }
        pub fn get(inst: Inst) LDR {
            return LDR{ .rt = inst.rd, .addr = inst.op1.getAMem(), .signed = inst.signed };
        }
    };

    pub const STP = struct {
        rt: Reg,
        rt2: Reg,
        addr: Operand,
        signed: bool,
        pub fn toInst(inst: STP) Inst {
            return Inst{ .oper = .STP, .op1 = inst.addr, .op2 = Operand.asOpReg(inst.rt2), .rd = inst.rt, .signed = inst.signed };
        }
        pub fn get(inst: Inst) STP {
            return STP{ .rt = inst.rd, .rt2 = inst.op2.getReg(), .addr = inst.op1.getAMem(), .signed = inst.signed };
        }
    };

    pub const Neg = struct {
        rd: Reg,
        op2: Operand,
        signed: bool,
        pub fn toInst(inst: Neg) Inst {
            return Inst{ .oper = .NEG, .rd = inst.rd, .op2 = inst.op2, .signed = inst.signed };
        }
        pub fn get(inst: Inst) Neg {
            return Neg{ .rd = inst.rd, .op2 = inst.op2, .signed = inst.signed };
        }
    };

    pub inline fn add(rd: Reg, rn: Reg, op2: Operand, signed: bool) Inst {
        return Inst{ .oper = .ADD, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .signed = signed };
    }

    pub inline fn sub(rd: Reg, rn: Reg, op2: Operand, signed: bool) Inst {
        return Inst{ .oper = .SUB, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .signed = signed };
    }

    pub inline fn and_(rd: Reg, rn: Reg, op2: Operand) Inst {
        return Inst{ .oper = .AND, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2 };
    }

    pub inline fn asr(rd: Reg, rn: Reg, op2: Operand) Inst {
        return Inst{ .oper = .ASR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2 };
    }

    pub inline fn lsl(rd: Reg, rn: Reg, op2: Operand) Inst {
        return Inst{ .oper = .LSL, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2 };
    }

    pub inline fn lsr(rd: Reg, rn: Reg, op2: Operand) Inst {
        return Inst{ .oper = .LSR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2 };
    }

    pub inline fn mov(rd: Reg, op1: Operand) Inst {
        return Inst{ .oper = .MOV, .rd = rd, .op1 = op1 };
    }

    pub inline fn cmp(rd: Reg, op1: Operand) Inst {
        return Inst{ .oper = .CMP, .rd = rd, .op1 = op1 };
    }

    pub inline fn mul(rd: Reg, rn: Reg, rm: Reg) Inst {
        return Inst{ .oper = .MUL, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = Operand.asOpReg(rm) };
    }

    pub inline fn div(rd: Reg, rn: Reg, rm: Reg, signed: bool) Inst {
        return Inst{ .oper = .DIV, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = Operand.asOpReg(rm), .signed = signed };
    }

    pub inline fn b(label: BasicBlock.ID) Inst {
        return Inst{ .oper = .B, .op1 = Operand.asOpLabel(label) };
    }

    pub inline fn bcc(label: BasicBlock.ID, cc: ConditionCode) Inst {
        return Inst{ .oper = .Bcc, .op1 = Operand.asOpLabel(label), .cc = cc };
    }

    pub inline fn bl(label: BasicBlock.ID) Inst {
        return Inst{ .oper = .BL, .op1 = Operand.asOpLabel(label) };
    }

    pub inline fn ldp(rt: Reg, rt2: Reg, addr: Operand) Inst {
        return Inst{ .oper = .LDP, .rd = rt, .op2 = Operand.asOpReg(rt2), .op1 = addr };
    }

    pub inline fn ldr(rt: Reg, addr: Operand, signed: bool) Inst {
        return Inst{ .oper = .LDR, .rd = rt, .op1 = addr, .signed = signed };
    }

    pub inline fn stp(rt: Reg, rt2: Reg, addr: Operand, signed: bool) Inst {
        return Inst{ .oper = .STP, .op1 = addr, .op2 = Operand.asOpReg(rt2), .rd = rt, .signed = signed };
    }

    pub inline fn neg(rd: Reg, op2: Operand, signed: bool) Inst {
        return Inst{ .oper = .NEG, .rd = rd, .op2 = op2, .signed = signed };
    }
};

pub const BasicBlock = struct {
    name: []const u8,
    incomers: std.ArrayList(BasicBlock.ID),
    outgoers: [2]?BasicBlock.ID,
    insts: std.ArrayList(Inst.ID),
    id: ID,
    pub const ID = usize;
};

pub const Function = struct {
    name: []const u8,
    blocks: std.ArrayList(BasicBlock.ID),
    insts: std.ArrayList(Inst),
    id: ID,
    pub const ID = usize;
};

pub const Program = struct {
    functions: std.ArrayList(Function),
    insts: std.ArrayList(Inst),
    regs: std.ArrayList(Reg),
    pub const ID = usize;
};

pub fn gen_program(ir: *IR) !Arm {
    var arm = Arm{};
    _ = try gen_globals(ir, &arm);
    _ = try gen_functions(ir, arm);
}

pub fn gen_globals(ir: *IR, arm: *Arm) !bool {
    _ = arm;
    _ = ir;
}

pub fn gen_functions(ir: *IR, arm: *Arm) !bool {
    for (ir.funcs.items.items) |func| {
        _ = try gen_function(arm, ir, func);
    }
}

pub fn gen_function(arm: *Arm, ir: *IR, func: *IR.Func) !bool {
    _ = arm;
    _ = ir;
    _ = func;
}
