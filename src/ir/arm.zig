pub const std = @import("std");
const log = @import("../log.zig");
const utils = @import("../utils.zig");
const Ast = @import("../ast.zig");

const IR = @import("ir_phi.zig");
const Phi = @import("phi.zig");
const Stringify = @import("stringify_arm.zig");

pub const Arm = @This();

pub const Imm = IR.StrID;

pub var IMM_NAME: IR.StrID = undefined;

program: Program,
alloc: std.mem.Allocator,
irBBtoARMBB: std.AutoHashMap(IR.BasicBlock.ID, BasicBlock.ID),
armBBtoIRBB: std.AutoHashMap(BasicBlock.ID, IR.BasicBlock.ID),

pub fn init(alloc: std.mem.Allocator) Arm {
    return Arm{
        .program = Program{
            .functions = std.ArrayList(Function).init(alloc),
            .insts = std.ArrayList(Inst).init(alloc),
            .globals = std.ArrayList(IR.StrID).init(alloc),
            .regs = std.ArrayList(Reg).init(alloc),
            .alloc = alloc,
        },
        .alloc = alloc,
        .irBBtoARMBB = std.AutoHashMap(IR.BasicBlock.ID, BasicBlock.ID).init(alloc),
        .armBBtoIRBB = std.AutoHashMap(BasicBlock.ID, IR.BasicBlock.ID).init(alloc),
    };
}

pub const SelectedReg = enum {
    X0,
    X1,
    X2,
    X3,
    X4,
    X5,
    X6,
    X7,
    X8,
    X9,
    X10,
    X11,
    X12,
    X13,
    X14,
    X15,
    X16,
    X17,
    X18,
    X19,
    X20,
    X21,
    X22,
    X23,
    X24,
    X25,
    X26,
    X27,
    X28,
    X29,
    X30,
    SP,
    none,
    pub fn fromInt(n: usize) SelectedReg {
        switch (n) {
            0 => return .X0,
            1 => return .X1,
            2 => return .X2,
            3 => return .X3,
            4 => return .X4,
            5 => return .X5,
            6 => return .X6,
            7 => return .X7,
            8 => return .X8,
            9 => return .X9,
            10 => return .X10,
            11 => return .X11,
            12 => return .X12,
            13 => return .X13,
            14 => return .X14,
            15 => return .X15,
            16 => return .X16,
            17 => return .X17,
            18 => return .X18,
            19 => return .X19,
            20 => return .X20,
            21 => return .X21,
            22 => return .X22,
            23 => return .X23,
            24 => return .X24,
            25 => return .X25,
            26 => return .X26,
            27 => return .X27,
            28 => return .X28,
            29 => return .X29,
            30 => return .X30,
            else => return .none,
        }
    }
};

pub const Reg = struct {
    id: ID, // the id of the register within the register list in the program
    name: IR.StrID, // the name of the register
    // kind: RegKind, this could be useed for vector type beat
    inst: ?Inst.ID, // the ID of the instruction that defines this register
    spillIndex: ?u32 = null, // the index of the register in the stack frame
    irID: IR.Register.ID,
    selection: SelectedReg = .none,
    pub const ID = usize;
};

pub const OperandKind = enum {
    Reg,
    Imm,
    MemReg, // addr = Xn
    MemImm, // addr = Xn + imm
    MemPostInc, // addr = Xn, Xn = Xn + imm
    MemPreInc, // Xn = Xn + imm, addr = Xn
    MemGlobal, // addr = global
    Label,
    invalid_,
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

    pub const Default = Operand{ .kind = .invalid_, .reg = undefined, .imm = undefined, .label = undefined };

    pub fn asOpReg(reg: Reg) Operand {
        return Operand{ .kind = .Reg, .reg = reg, .imm = undefined, .label = IR.InternPool.NULL };
    }

    pub fn asOpImm(imm: Imm) Operand {
        return Operand{ .kind = .Imm, .imm = imm, .reg = undefined, .label = IR.InternPool.NULL };
    }

    pub fn asOpMemReg(reg: Reg) Operand {
        return Operand{ .kind = .MemReg, .reg = reg, .imm = undefined, .label = IR.InternPool.NULL };
    }

    pub fn asOpMemImm(reg: Reg, imm: Imm) Operand {
        return Operand{ .kind = .MemImm, .reg = reg, .imm = imm, .label = IR.InternPool.NULL };
    }

    pub fn asOpMemPostInc(reg: Reg, imm: Imm) Operand {
        return Operand{ .kind = .MemPostInc, .reg = reg, .imm = imm, .label = IR.InternPool.NULL };
    }

    pub fn asOpMemPreInc(reg: Reg, imm: Imm) Operand {
        return Operand{ .kind = .MemPreInc, .reg = reg, .imm = imm, .label = IR.InternPool.NULL };
    }

    pub fn asMemGlobal(reg: Reg) Operand {
        return Operand{ .kind = .MemGlobal, .reg = reg, .imm = undefined, .label = IR.InternPool.NULL };
    }

    pub fn asOpLabel(label: BasicBlock.ID) Operand {
        return Operand{ .kind = .Label, .label = label, .reg = undefined, .imm = undefined };
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

    pub fn getMemGlobal(operand: Operand) Operand {
        utils.assert(operand.kind == OperandKind.MemGlobal, "The operand {any} was not a memory global, but was requested as one", .{operand});
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
    invalid_,
};

pub const Operation = enum {
    NEG, // rd = - op2
    ADD, // rd = rn + op2
    SUB, // rd = rn - op2
    MUL, // rd = rn * op2
    DIV, // rd = rn / op2
    AND, // rd = rn & op2
    ORR, // rd = rn | op2
    EOR, // rd = rn ^ op2
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
    RET, // PC = {xn}
    PRINT_THIS_LOL,
    // there are more operations, but these are the ones we will use
};

pub const Inst = struct {
    oper: Operation,
    /// The resulting register
    rd: Reg,
    op1: Operand = Operand.Default,
    op2: Operand = Operand.Default,
    id: ID,

    signed: bool = true,
    width: u32 = 64,
    cc: ConditionCode = .invalid_,
    pub const ID = usize;

    pub const PrintThisLol = struct {
        string: IR.StrID,

        pub fn toInst(inst: PrintThisLol) Inst {
            return Inst{ .rd = undefined, .oper = .PRINT_THIS_LOL, .op1 = Operand.asOpImm(inst.string) };
        }

        pub fn get(inst: Inst) PrintThisLol {
            return PrintThisLol{ .string = Operand.getImm(inst.op1) };
        }
    };

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

    pub const Orr = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        pub fn toInst(inst: Orr) Inst {
            return Inst{ .oper = .ORR, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2 };
        }
        pub fn get(inst: Inst) Orr {
            return Orr{ .rd = inst.rd, .rn = inst.op1.getReg(), .op2 = inst.op2 };
        }
    };

    pub const Eor = struct {
        rd: Reg,
        rn: Reg,
        op2: Operand,
        pub fn toInst(inst: Eor) Inst {
            return Inst{ .oper = .EOR, .rd = inst.rd, .op1 = Operand.asOpReg(inst.rn), .op2 = inst.op2 };
        }
        pub fn get(inst: Inst) Eor {
            return Eor{ .rd = inst.rd, .rn = inst.op1.getReg(), .op2 = inst.op2 };
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
        label: IR.StrID,
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

    pub const STR = struct {
        rt: Reg,
        addr: Operand,
        signed: bool,
        pub fn toInst(inst: STR) Inst {
            return Inst{ .oper = .STR, .rd = inst.rt, .op1 = inst.addr, .signed = inst.signed };
        }
        pub fn get(inst: Inst) STR {
            return STR{ .rt = inst.rd, .addr = inst.op1.getAMem(), .signed = inst.signed };
        }
    };

    pub const Neg = struct {
        rd: Reg,
        op1: Operand,
        signed: bool,
        pub fn toInst(inst: Neg) Inst {
            return Inst{ .oper = .NEG, .rd = inst.rd, .op1 = inst.op1, .signed = inst.signed };
        }
        pub fn get(inst: Inst) Neg {
            return Neg{ .rd = inst.rd, .op1 = inst.op1, .signed = inst.signed };
        }
    };

    pub const Ret = struct {
        pub fn toInst() Inst {
            return Inst{ .oper = .RET, .rd = undefined, .op1 = Operand.asOpReg(Reg{ .id = 30, .name = IMM_NAME, .inst = undefined, .irID = undefined }) };
        }
        pub fn get() Ret {
            return Ret{};
        }
    };
    pub fn print_this_lol(strVal: IR.StrID, id: Inst.ID) Inst {
        return Inst{ .rd = undefined, .oper = .PRINT_THIS_LOL, .op1 = Operand.asOpImm(strVal), .id = id };
    }

    pub inline fn add(rd: Reg, rn: Reg, op2: Operand, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .ADD, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .signed = signed, .id = id };
    }

    pub inline fn sub(rd: Reg, rn: Reg, op2: Operand, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .SUB, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .signed = signed, .id = id };
    }

    pub inline fn and_(rd: Reg, rn: Reg, op2: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .AND, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .id = id };
    }

    // need to add id as function param to this function and into the result as with add and sub, and_
    pub inline fn orr(rd: Reg, rn: Reg, op2: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .ORR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .id = id };
    }

    pub inline fn eor(rd: Reg, rn: Reg, op2: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .EOR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .id = id };
    }

    pub inline fn asr(rd: Reg, rn: Reg, op2: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .ASR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .id = id };
    }

    pub inline fn lsl(rd: Reg, rn: Reg, op2: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .LSL, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .id = id };
    }

    pub inline fn lsr(rd: Reg, rn: Reg, op2: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .LSR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2, .id = id };
    }

    pub inline fn mov(rd: Reg, op1: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .MOV, .rd = rd, .op1 = op1, .id = id };
    }

    pub inline fn cmp(rd: Reg, op1: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .CMP, .rd = rd, .op1 = op1, .id = id };
    }

    pub inline fn mul(rd: Reg, rn: Reg, rm: Reg, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .MUL, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = Operand.asOpReg(rm), .signed = signed, .id = id };
    }

    pub inline fn div(rd: Reg, rn: Reg, rm: Reg, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .DIV, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = Operand.asOpReg(rm), .signed = signed, .id = id };
    }

    pub inline fn b(label: BasicBlock.ID, id: Inst.ID) Inst {
        return Inst{ .oper = .B, .op1 = Operand.asOpLabel(label), .id = id, .rd = undefined };
    }

    pub inline fn bcc(label: BasicBlock.ID, cc: ConditionCode, id: Inst.ID) Inst {
        return Inst{ .oper = .Bcc, .op1 = Operand.asOpLabel(label), .cc = cc, .id = id, .rd = undefined };
    }

    pub inline fn bl(label: IR.StrID, id: Inst.ID) Inst {
        return Inst{ .oper = .BL, .op1 = Operand.asOpLabel(label), .id = id, .rd = undefined };
    }

    pub inline fn ldp(rt: Reg, rt2: Reg, addr: Operand, id: Inst.ID) Inst {
        return Inst{ .oper = .LDP, .rd = rt, .op2 = Operand.asOpReg(rt2), .op1 = addr, .id = id };
    }

    pub inline fn ldr(rt: Reg, addr: Operand, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .LDR, .rd = rt, .op1 = addr, .signed = signed, .id = id };
    }

    pub inline fn stp(rt: Reg, rt2: Reg, addr: Operand, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .STP, .op1 = addr, .op2 = Operand.asOpReg(rt2), .rd = rt, .signed = signed, .id = id };
    }

    pub inline fn str(rt: Reg, addr: Operand, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .STR, .rd = rt, .op1 = addr, .signed = signed, .id = id };
    }

    pub inline fn neg(rd: Reg, op2: Operand, signed: bool, id: Inst.ID) Inst {
        return Inst{ .oper = .NEG, .rd = rd, .op2 = op2, .signed = signed, .id = id };
    }

    pub inline fn ret(id: Inst.ID) Inst {
        return Inst{ .oper = .RET, .rd = undefined, .id = id };
    }
};

pub const BasicBlock = struct {
    name: []const u8,
    incomers: std.ArrayList(*BasicBlock),
    outgoers: [2]?*BasicBlock,
    insts: std.ArrayList(Inst.ID),
    id: ID,
    pub const ID = usize;

    pub fn init(name: []const u8, id: ID, alloc: std.mem.Allocator) BasicBlock {
        return BasicBlock{
            .name = name,
            .incomers = std.ArrayList(*BasicBlock).init(alloc),
            .outgoers = [_]?*BasicBlock{ null, null },
            .insts = std.ArrayList(Inst.ID).init(alloc),
            .id = id,
        };
    }
    pub fn isIncomerSelfRef(self: *BasicBlock, func: *Function, incomer: *BasicBlock) !bool {
        var selfID = self.id;
        // map of visited blocks
        var visited = std.AutoHashMap(BasicBlock.ID, bool).init(func.program.alloc);
        defer visited.deinit();
        var stack = std.ArrayList(*BasicBlock).init(func.program.alloc);
        defer stack.deinit();
        try stack.append(incomer);
        while (stack.items.len != 0) {
            var block = stack.orderedRemove(0);
            if (block.id == selfID) {
                return true;
            }
            if (visited.contains(block.id)) {
                continue;
            }
            try visited.put(block.id, true);
            for (block.incomers.items) |incomer2| {
                try stack.append(incomer2);
            }
        }
        return false;
    }
};

pub const PhiSave = struct {
    instID: IR.Function.InstID,
    func: *IR.Function,
    armFunc: *Function,
    armBlock: *BasicBlock,
};

pub const Function = struct {
    name: IR.StrID,
    blocks: std.ArrayList(BasicBlock),
    insts: std.ArrayList(Inst.ID),
    phiSave: std.ArrayList(PhiSave),
    spilledNum: u32,
    id: ID,
    program: *Program,
    params: std.ArrayList(Reg),
    pub const ID = usize;

    pub fn init(program: *Program, name: IR.StrID, id: ID) Function {
        return Function{
            .name = name,
            .blocks = std.ArrayList(BasicBlock).init(program.alloc),
            .insts = std.ArrayList(Inst.ID).init(program.alloc),
            .params = std.ArrayList(Reg).init(program.alloc),
            .phiSave = std.ArrayList(PhiSave).init(program.alloc),
            .spilledNum = 0,
            .id = id,
            .program = program,
        };
    }

    pub fn addBlockBetween(self: *Function, arm: *Arm, src: *BasicBlock, dest: *BasicBlock) !*BasicBlock {
        var bb_ = BasicBlock.init("tweener", self.blocks.items.len, self.program.alloc);
        try self.blocks.append(bb_);
        var bb = &self.blocks.items[bb_.id];
        var srcIRID = arm.armBBtoIRBB.get(src.id).?;
        try arm.armBBtoIRBB.put(bb.id, srcIRID);
        // go through te dest's incomers and replace the src with the new block
        for (dest.incomers.items, 0..) |incomerBlock, ibIDX| {
            if (incomerBlock.id == src.id) {
                dest.incomers.items[ibIDX] = bb;
            }
        }

        // now the harder part, replace the outgoers of the src block with the new block, and replace the branch / jmp with the new block
        for (src.outgoers, 0..) |outgoerBlock, obIDX| {
            if (outgoerBlock != null) {
                if (outgoerBlock.?.id == dest.id) {
                    src.outgoers[obIDX] = bb;
                    for (src.insts.items) |instID| {
                        var inst = &self.program.insts.items[instID];
                        if (inst.oper == .B or inst.oper == .Bcc) {
                            if (inst.op1.kind == .Label and inst.op1.label == dest.id) {
                                inst.op1 = Operand.asOpLabel(bb.id);
                            }
                        }
                    }
                }
            }
        }
        // now add a B to the dest block
        var bInst = Inst.b(dest.id, self.program.insts.items.len);
        try self.addInst(bInst, bb);
        return bb;
    }

    pub fn addParams(self: *Function, ir: *IR, func: *IR.Function) !void {
        _ = ir;
        for (func.params.items) |param| {
            var reg = Reg{ .id = self.program.regs.items.len, .name = param.name, .inst = null, .irID = 0xDEADBEEF };
            try self.program.addReg(reg);
            try self.params.append(reg);
        }
    }

    pub fn addInst(func: *Function, inst: Inst, bb: *BasicBlock) !void {
        if (inst.id != func.program.insts.items.len) {
            return std.debug.panic("The instruction {d} was not the next instruction in the function", .{inst.id});
        }
        // FIXME: possiblt add the panic if the regs inside the inst are wrong too
        try func.insts.append(inst.id);
        try func.program.insts.append(inst);
        try bb.insts.append(inst.id);
    }

    pub fn ensureBothReg(self: *Function, ir: *IR, bb: *BasicBlock, o1: *Operand, o2: *Operand) !void {
        const name = ir.internIdent("_");
        switch (o1.kind) {
            .Reg => {
                switch (o2.kind) {
                    .Reg => {
                        return;
                    },
                    .Imm => {
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = self.program.insts.items.len, .irID = o2.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o2.imm), self.program.insts.items.len);
                        try self.addInst(movInst, bb);
                        o2.* = Operand.asOpReg(reg);
                    },
                    else => {
                        return std.debug.panic("The second operand {any} was not a register", .{o2});
                    },
                }
            },
            .Imm => {
                switch (o2.kind) {
                    .Reg => {
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = self.program.insts.items.len, .irID = o1.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm), self.program.insts.items.len);
                        try self.addInst(movInst, bb);
                        o1.* = Operand.asOpReg(reg);
                        return;
                    },
                    .Imm => {
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = self.program.insts.items.len, .irID = o1.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm), self.program.insts.items.len);
                        try self.addInst(movInst, bb);
                        o1.* = Operand.asOpReg(reg);

                        reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = self.program.insts.items.len, .irID = o2.imm };
                        try self.program.addReg(reg);
                        movInst = Inst.mov(reg, Operand.asOpImm(o2.imm), self.program.insts.items.len);
                        try self.addInst(movInst, bb);
                        o2.* = Operand.asOpReg(reg);
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {any} was not a register", .{o2});
                    },
                }
            },
            else => {
                return std.debug.panic("The first operand {any} was not a register", .{o1});
            },
        }
    }

    pub fn ensureImmOrAtLeastOneRegNoSwap(self: *Function, armBB: *BasicBlock, ir: *IR, o1: *Operand, o2: *Operand) !void {
        const name = ir.internIdent("_");
        // check if the operands are registers or immediates
        switch (o1.kind) {
            .Reg => {
                switch (o2.kind) {
                    .Reg => {
                        return;
                    },
                    .Imm => {
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {any} was not a register or immediate", .{o2});
                    },
                }
            },
            .Imm => {
                var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = self.program.insts.items.len, .irID = o1.imm };
                try self.program.addReg(reg);
                var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm), self.program.insts.items.len);
                try self.addInst(movInst, armBB);
                o1.* = Operand.asOpReg(reg);
                switch (o2.kind) {
                    .Reg => {
                        return;
                    },
                    .Imm => {
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {any} was not a register or immediate", .{o2});
                    },
                }
            },
            else => {
                return std.debug.panic("The first operand {any} was not a register or immediate", .{o1});
            },
        }
    }
    pub fn ensureImmOrAtLeastOneReg(self: *Function, ir: *IR, bb: *BasicBlock, o1: *Operand, o2: *Operand) !void {
        const name = ir.internIdent("_");
        // check if the operands are registers or immediates
        switch (o1.kind) {
            .Reg => {
                switch (o2.kind) {
                    .Reg => {
                        return;
                    },
                    .Imm => {
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {any} was not a register or immediate", .{o2});
                    },
                }
            },
            .Imm => {
                switch (o2.kind) {
                    .Reg => {
                        // swap the operands's values
                        var temp = o1.*;
                        o1.* = o2.*;
                        o2.* = temp;
                        return;
                    },
                    .Imm => {
                        // we need to create an instruction to mv o1 into a register, then change the operand to a register
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = self.program.insts.items.len, .irID = o1.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm), self.program.insts.items.len);
                        try self.addInst(movInst, bb);
                        o1.* = Operand.asOpReg(reg);
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {any} was not a register or immediate", .{o2});
                    },
                }
            },
            else => {
                return std.debug.panic("The first operand {any} was not a register or immediate", .{o1});
            },
        }
    }
};

pub const Program = struct {
    functions: std.ArrayList(Function),
    globals: std.ArrayList(IR.StrID),
    insts: std.ArrayList(Inst),
    regs: std.ArrayList(Reg),
    alloc: std.mem.Allocator,
    pub const ID = usize;

    pub fn addReg(program: *Program, reg: Reg) !void {
        if (reg.id != program.regs.items.len) {
            return std.debug.panic("The register {any} was not the next register in the program", .{reg.id});
        }
        try program.regs.append(reg);
    }

    pub fn getOpfromIR(self: *Program, func: *IR.Function, ref: IR.Ref, instID: ?usize) !Operand {
        switch (ref.kind) {
            .local => {
                var irReg = func.regs.get(ref.i);
                var name = irReg.name;
                var reg = Reg{ .id = self.regs.items.len, .name = name, .inst = instID, .irID = ref.i };
                try self.addReg(reg);
                return Operand.asOpReg(reg);
            },
            .param => {
                var reg = Reg{ .id = self.regs.items.len, .name = ref.name, .inst = instID, .irID = 0xDEADBEEF };
                try self.addReg(reg);
                return Operand.asOpReg(reg);
            },
            .global => {
                var reg = Reg{ .id = self.regs.items.len, .name = ref.name, .inst = instID, .irID = ref.i };
                try self.addReg(reg);
                return Operand.asMemGlobal(reg);
            },
            .immediate, .immediate_u32 => {
                return Operand.asOpImm(ref.i);
            },
            else => {
                std.debug.panic("The ref {any} was not expected in the program", .{ref});
            },
        }
        std.debug.panic("The ref {any} was not expected in the program", .{ref});
    }
};

pub fn gen_program(ir: *IR) !Arm {
    var arm = Arm.init(ir.alloc);
    try arm.program.insts.append(undefined);
    _ = try gen_globals(ir, &arm);
    _ = try gen_functions(ir, &arm);
    return arm;
}

pub fn gen_globals(ir: *IR, arm: *Arm) !bool {
    for (ir.globals.items.items) |item| {
        try arm.program.globals.append(item.name);
    }
    try arm.program.globals.append(ir.internIdent("_read_scratch"));
    return false;
}

pub fn gen_functions(ir: *IR, arm: *Arm) !bool {
    for (ir.funcs.items.items) |*func| {
        try arm.program.functions.append(Function.init(&arm.program, func.name, arm.program.functions.items.len));
    }

    for (ir.funcs.items.items, 0..) |*func, armFuncIDX| {
        var armFunc = &arm.program.functions.items[armFuncIDX];
        try armFunc.addParams(ir, func);
        _ = try gen_function(arm, armFunc, ir, func);
    }
    return false;
}

pub fn gen_function(arm: *Arm, armFunc: *Function, ir: *IR, func: *IR.Function) !bool {
    // naively create all of the basic blocks

    var irBBtoARMBB = std.AutoHashMap(IR.BasicBlock.ID, BasicBlock.ID).init(ir.alloc);
    var armBBtoIRBB = std.AutoHashMap(BasicBlock.ID, IR.BasicBlock.ID).init(ir.alloc);
    for (func.bbs.items(), func.bbs.ids()) |block, bbID| {
        var bb = BasicBlock{
            .name = block.name,
            .id = armFunc.blocks.items.len,
            .incomers = std.ArrayList(*BasicBlock).init(arm.alloc),
            .outgoers = [_]?*BasicBlock{ null, null },
            .insts = std.ArrayList(Inst.ID).init(arm.alloc),
        };
        var nameNew = std.ArrayList(u8).init(arm.alloc);
        for (bb.name) |c| {
            if (c == '.') {
                try nameNew.append('_');
            } else {
                try nameNew.append(c);
            }
        }
        bb.name = try nameNew.toOwnedSlice();
        try armFunc.blocks.append(bb);
        try irBBtoARMBB.put(bbID, bb.id);
        try armBBtoIRBB.put(bb.id, bbID);
    }

    // link the blocks together
    for (func.bbs.items(), 0..) |block, armBBID| {
        var bbIncomers = block.incomers;
        var bbOutgoers = block.outgoers;

        // for the incomers
        for (bbIncomers.items) |incomer| {
            const armInBBID = irBBtoARMBB.get(incomer).?;
            var inccomerBBPtr = &armFunc.blocks.items[armInBBID];
            try armFunc.blocks.items[armBBID].incomers.append(inccomerBBPtr);
        }
        // for the outgoers
        for (bbOutgoers, 0..) |outgoer, i| {
            if (outgoer == null) {
                armFunc.blocks.items[armBBID].outgoers[i] = null;
                continue;
            }
            const armOutBBID = irBBtoARMBB.get(outgoer.?).?;
            armFunc.blocks.items[armBBID].outgoers[i] = &armFunc.blocks.items[armOutBBID];
        }
    }
    arm.irBBtoARMBB = irBBtoARMBB;
    arm.armBBtoIRBB = armBBtoIRBB;

    // generate the instructions within them
    for (func.bbs.items(), 0..) |block, i| {
        var armBlock = &armFunc.blocks.items[i];
        _ = try gen_block(arm, ir, func, armFunc, block, armBlock);
    }

    // go through and clean up the phi nodes
    for (armFunc.phiSave.items) |phiSave| {
        var aBPhi = phiSave.armBlock;
        var phiInst = func.insts.get(phiSave.instID).*;
        var phi = IR.Inst.Phi.get(phiInst);
        var phiRes = phi.res;

        var newNameStr = std.ArrayList(u8).init(ir.alloc);
        var phiResStr = ir.getIdent(phiRes.name);
        for (phiResStr) |c| {
            try newNameStr.append(c);
        }
        try newNameStr.append('_');
        var tmp = phiRes.i;
        while (tmp != 0) {
            try newNameStr.append(@intCast((tmp % 10) + 48));
            tmp /= 10;
        }
        var newName = ir.internIdent(try newNameStr.toOwnedSlice());

        // for every entry in the phi node
        //  - find corresponding arm block -> check if its within aBPhi's incomers
        for (phi.entries.items) |phiEntry| {
            var irBB = phiEntry.bb;
            var ref = phiEntry.ref;
            var found: bool = false;
            var incomer: *BasicBlock = aBPhi;
            for (aBPhi.incomers.items) |incomer_| {
                // std.debug.print("Checking if incomer {any} is equal to {any}\n", .{ irBB, incomer_ });
                if (irBB == arm.armBBtoIRBB.get(incomer_.id).?) {
                    found = true;
                    incomer = incomer_;
                    break;
                }
            }
            if (!found) {
                utils.impossible("On Inserting phi node:\nThe incomer block was not found in the arm block's incomers", .{});
            }

            // check if it is self referential
            if (try aBPhi.isIncomerSelfRef(phiSave.armFunc, incomer)) {
                // add a block between them
                incomer = try phiSave.armFunc.addBlockBetween(arm, incomer, aBPhi);
            }

            // create a new name for the incoming value

            // resulting reg
            var reg = Reg{ .id = arm.program.regs.items.len, .name = newName, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF };
            try arm.program.addReg(reg);
            var fromOp = try arm.program.getOpfromIR(phiSave.func, ref, null);
            var movInst = Inst.mov(reg, fromOp, arm.program.insts.items.len);
            try arm.program.insts.append(movInst);

            // find place in the block to insert the instruction (and the function for that matter)
            var lastIndex: usize = 0;
            var nextIndex: usize = 0;
            for (incomer.insts.items, 0..) |instID, idX| {
                var inst = &arm.program.insts.items[instID];
                if (inst.oper == .B or inst.oper == .Bcc) {
                    nextIndex = idX;
                    break;
                }
                if (inst.oper == .CMP or inst.oper == .RET) {
                    nextIndex = idX;
                    break;
                }
                lastIndex = idX;
            }

            var nextLastInstId = incomer.insts.items[nextIndex];
            // find in the function
            var funcIndex: usize = 0;
            for (phiSave.armFunc.insts.items, 0..) |instID, idX| {
                if (instID == nextLastInstId) {
                    funcIndex = idX;
                    break;
                }
            }
            try phiSave.armFunc.insts.insert(funcIndex, movInst.id);
            try incomer.insts.insert(nextIndex, movInst.id);
        }

        // now move from new name to old name inside of the block
        var fromReg = Reg{ .id = arm.program.regs.items.len, .name = newName, .inst = null, .irID = 0xDEADBEEF };
        try arm.program.addReg(fromReg);
        var toReg = Reg{ .id = arm.program.regs.items.len, .name = phiRes.name, .inst = arm.program.insts.items.len, .irID = phiRes.i };
        try arm.program.addReg(toReg);
        var movInst = Inst.mov(toReg, Operand.asOpReg(fromReg), arm.program.insts.items.len);
        try arm.program.insts.append(movInst);
        var instIDBB = aBPhi.insts.items[0];
        try aBPhi.insts.insert(0, movInst.id);
        // find in the function
        var funcIndex: usize = 0;
        for (phiSave.armFunc.insts.items, 0..) |instID, idX| {
            if (instID == instIDBB) {
                funcIndex = idX;
                break;
            }
        }
        try phiSave.armFunc.insts.insert(funcIndex, movInst.id);
    }

    // create mov from every param to a register of the index
    // get the first basic block in the function
    var firstBB = armFunc.blocks.items[0];
    for (armFunc.params.items, 0..) |param, i| {
        // var paramOperand = Operand.asOpReg(param);
        var reg = Reg{ .id = arm.program.regs.items.len, .name = param.name, .inst = null, .irID = 0xDEADBEEF };
        reg.selection = SelectedReg.fromInt(i);
        try arm.program.addReg(reg);
        var movInst = Inst.mov(param, Operand.asOpReg(reg), arm.program.insts.items.len);
        try arm.program.insts.append(movInst);
        // find in the function the first instruction
        try firstBB.insts.insert(0, movInst.id);
        try armFunc.insts.insert(0, movInst.id);
    }

    // go through all of the instructions in the function, and make a map from their instruction ID to the register id
    // track all of the non irID registers, and add them to a list

    var instToReg = std.AutoHashMap(IR.Function.InstID, Reg.ID).init(ir.alloc);
    var instToSelection = std.AutoHashMap(IR.Function.InstID, SelectedReg).init(ir.alloc);
    var unnamedRegs = std.AutoHashMap(IR.StrID, SelectedReg).init(ir.alloc);
    var spillIndex = std.AutoHashMap(usize, ?u32).init(ir.alloc);
    var spillUnamedRegs = std.AutoHashMap(usize, ?u32).init(ir.alloc);
    var unnamedMap = std.AutoHashMap(Reg.ID, ?bool).init(ir.alloc);
    var counter: usize = 14;
    for (armFunc.insts.items) |instID| {
        if (counter == 16) counter = 18;
        var inst = &arm.program.insts.items[instID];
        // if instToReg does not contain the inst.rd.id, add it
        if (inst.rd.irID == 0xDEADBEEF) {
            if (counter <= 27) {
                try spillUnamedRegs.put(inst.rd.name, null);
                if (!unnamedRegs.contains(inst.rd.name)) {
                    try unnamedRegs.put(inst.rd.name, SelectedReg.fromInt(counter));
                    counter += 1;
                }
            } else {
                std.debug.print("Spilling registername {any} with val {any}\n", .{ inst.rd.irID, inst.rd.name });
                try spillUnamedRegs.put(inst.rd.name, armFunc.spilledNum);
                armFunc.spilledNum += 1;
            }
        } else if (!instToReg.contains(inst.rd.irID)) {
            if (counter <= 27) {
                try spillIndex.put(inst.rd.irID, null);
                try instToReg.put(inst.rd.irID, inst.rd.id);
                try instToSelection.put(inst.rd.irID, SelectedReg.fromInt(counter));
                counter += 1;
            } else {
                std.debug.print("Spilling register {any} with val {any}\n", .{ inst.rd.irID, inst.rd.name });
                try spillIndex.put(inst.rd.irID, armFunc.spilledNum);
                armFunc.spilledNum += 1;
            }
        }
    }

    // go back through the instructions and set the selection of the registers
    for (armFunc.insts.items) |instID| {
        var inst = &arm.program.insts.items[instID];
        if (inst.rd.irID == 0xDEADBEEF and inst.rd.selection == .none) {
            inst.rd.selection = unnamedRegs.get(inst.rd.name) orelse .none;
            try unnamedMap.put(inst.rd.id, null);
        } else if (inst.rd.selection == .none) {
            inst.rd.selection = instToSelection.get(inst.rd.irID) orelse .none;
        }

        if (inst.op1.reg.irID == 0xDEADBEEF and inst.op1.reg.selection == .none) {
            inst.op1.reg.selection = unnamedRegs.get(inst.op1.reg.name) orelse .none;
            try unnamedMap.put(inst.op1.reg.id, null);
        } else if (inst.op1.reg.selection == .none) {
            inst.op1.reg.selection = instToSelection.get(inst.op1.reg.irID) orelse .none;
        }

        if (inst.op2.reg.irID == 0xDEADBEEF and inst.op2.reg.selection == .none) {
            try unnamedMap.put(inst.op2.reg.id, null);
            inst.op2.reg.selection = unnamedRegs.get(inst.op2.reg.name) orelse .none;
        } else if (inst.op2.reg.selection == .none) {
            inst.op2.reg.selection = instToSelection.get(inst.op2.reg.irID) orelse .none;
        }
        inst.rd.spillIndex = null;
        inst.op2.reg.spillIndex = null;
        inst.op1.reg.spillIndex = null;
    }

    // go through and assign spillage
    for (armFunc.insts.items) |instID| {
        var inst = &arm.program.insts.items[instID];
        // check if its in the unnamedMap
        if (inst.rd.selection == .none) {
            if (unnamedMap.contains(inst.rd.id)) {
                inst.rd.spillIndex = spillUnamedRegs.get(inst.rd.name) orelse null;
            } else {
                inst.rd.spillIndex = spillIndex.get(inst.rd.irID) orelse null;
            }
        }
        if (inst.op1.reg.selection == .none) {
            if (unnamedMap.contains(inst.op1.reg.id)) {
                inst.op1.reg.spillIndex = spillUnamedRegs.get(inst.op1.reg.name) orelse null;
            } else {
                inst.op1.reg.spillIndex = spillIndex.get(inst.op1.reg.irID) orelse null;
            }
        }
        if (inst.op2.reg.selection == .none) {
            if (unnamedMap.contains(inst.op2.reg.id)) {
                inst.op2.reg.spillIndex = spillUnamedRegs.get(inst.op2.reg.name) orelse null;
            } else {
                inst.op2.reg.spillIndex = spillIndex.get(inst.op2.reg.irID) orelse null;
            }
        }
    }

    // // go through and make the regs ids correct or throw errors!.. or we also could not?!
    // // go through the insts and collet all the assigned to reg names
    // var counter: usize = 9;
    // for (armFunc.insts.items) |instID| {
    //     var inst = &arm.program.insts.items[instID];
    //     if (!regNames.contains(inst.rd.name)) {
    //         try regNames.put(inst.rd.name, SelectedReg.fromInt(counter));
    //         counter += 1;
    //     }
    // }
    // std.debug.print("The number of registers in the function: {d}\n", .{counter});
    // for (armFunc.insts.items) |instID| {
    //     var inst = &arm.program.insts.items[instID];
    //     if (inst.rd.selection == .none) inst.rd.selection = regNames.get(inst.rd.name) orelse .none;
    //     if (inst.op1.reg.selection == .none) inst.op1.reg.selection = regNames.get(inst.op1.reg.name) orelse .none;
    //     if (inst.op2.reg.selection == .none) inst.op2.reg.selection = regNames.get(inst.op2.reg.name) orelse .none;
    // }

    return false;
}

pub fn gen_block(arm: *Arm, ir: *IR, func: *IR.Function, armFunc: *Function, irBlock: IR.BasicBlock, armBlock: *BasicBlock) !bool {
    var skip: bool = false;
    for (irBlock.insts.items()) |instID| {
        // std.debug.print("BLOCK irInst: {s}\n", .{@tagName(func.insts.get(instID).*.op)});
        if (skip) {
            skip = false;
            continue;
        }
        skip = try gen_inst(arm, ir, func, armFunc, irBlock, instID, armBlock);
    }
    return false;
}

pub fn gen_inst(
    arm: *Arm,
    ir: *IR,
    func: *IR.Function,
    armFunc: *Function,
    irBlock: IR.BasicBlock,
    instID: IR.Function.InstID,
    armBlock: *BasicBlock,
) !bool {
    _ = irBlock;
    var res: bool = false;
    // check if there are any instructions (there should be)
    if (func.insts.len == 0) {
        return false;
    }

    // its switching time baby
    const irInst = func.insts.get(instID).*;
    // std.debug.print("INST irInst: {s}\n", .{@tagName(irInst.op)});
    switch (irInst.op) {
        .Ret => {
            var ret = IR.Inst.Ret.get(irInst);
            switch (ret.ty) {
                .void => {
                    // if the name of the function is "main" then we need to add a ret instruction with x0 = 0
                    if (func.name == ir.internIdent("main")) {
                        var x0 = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF, .selection = SelectedReg.X0 };
                        try arm.program.addReg(x0);
                        var movInst = Inst.mov(x0, Operand.asOpImm(0), arm.program.insts.items.len);
                        try armFunc.addInst(movInst, armBlock);
                        var x8 = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF, .selection = SelectedReg.X8 };
                        try arm.program.addReg(x8);
                        var movInst2 = Inst.mov(x8, Operand.asOpImm(ir.internIdent("93")), arm.program.insts.items.len);
                        try armFunc.addInst(movInst2, armBlock);
                        var strID = ir.internIdent("svc 0");
                        var svcInst = Inst.print_this_lol(strID, arm.program.insts.items.len);
                        try armFunc.addInst(svcInst, armBlock);
                    }
                },
                else => {
                    var retOp = try arm.program.getOpfromIR(func, ret.val, null);
                    var x0 = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF, .selection = SelectedReg.X0 };
                    try arm.program.addReg(x0);
                    var movInst = Inst.mov(x0, retOp, arm.program.insts.items.len);
                    try armFunc.addInst(movInst, armBlock);
                },
            }
            var retInst = Inst.ret(arm.program.insts.items.len);
            try armFunc.addInst(retInst, armBlock);
            return true;
        },
        .Phi => {
            try armFunc.phiSave.append(PhiSave{ .instID = instID, .func = func, .armFunc = armFunc, .armBlock = armBlock });
        },
        .Binop => {
            const binopIr = IR.Inst.Binop.get(irInst);

            std.debug.print("binop: {s}\n", .{@tagName(binopIr.op)});
            switch (binopIr.op) {
                // order with two reg
                .Mul => {
                    var mulRD = try arm.program.getOpfromIR(func, binopIr.register, arm.program.insts.items.len);
                    var mulRn = try arm.program.getOpfromIR(func, binopIr.lhs, null);
                    var mulRm = try arm.program.getOpfromIR(func, binopIr.rhs, null);
                    try armFunc.ensureBothReg(ir, armBlock, &mulRn, &mulRm);
                    mulRD.reg.inst = arm.program.insts.items.len;

                    var mulInst = Inst.mul(mulRD.getReg(), mulRn.getReg(), mulRm.getReg(), true, arm.program.insts.items.len);
                    try armFunc.addInst(mulInst, armBlock);
                },
                .Div => {
                    var divRD = try arm.program.getOpfromIR(func, binopIr.register, arm.program.insts.items.len);
                    var divRn = try arm.program.getOpfromIR(func, binopIr.lhs, null);
                    var divRm = try arm.program.getOpfromIR(func, binopIr.rhs, null);
                    divRD.reg.inst = arm.program.insts.items.len;

                    try armFunc.ensureBothReg(ir, armBlock, &divRn, &divRm);
                    var divInst = Inst.div(divRD.getReg(), divRn.getReg(), divRm.getReg(), true, arm.program.insts.items.len);
                    try armFunc.addInst(divInst, armBlock);
                },
                // order with one imm
                .Sub => {
                    var subRD = try arm.program.getOpfromIR(func, binopIr.register, arm.program.insts.items.len);
                    var subRn = try arm.program.getOpfromIR(func, binopIr.lhs, null);
                    var subO2 = try arm.program.getOpfromIR(func, binopIr.rhs, null);
                    try armFunc.ensureImmOrAtLeastOneRegNoSwap(armBlock, ir, &subRn, &subO2);
                    subRD.reg.inst = arm.program.insts.items.len;

                    var subInst = Inst.sub(subRD.getReg(), subRn.getReg(), subO2, true, arm.program.insts.items.len);
                    try armFunc.addInst(subInst, armBlock);
                },
                // order does not matter
                .And, .Or, .Xor => {
                    var rd = try arm.program.getOpfromIR(func, binopIr.register, arm.program.insts.items.len);
                    var rn = try arm.program.getOpfromIR(func, binopIr.lhs, null);
                    var o2 = try arm.program.getOpfromIR(func, binopIr.rhs, null);
                    try armFunc.ensureBothReg(ir, armBlock, &rn, &o2);
                    rd.reg.inst = arm.program.insts.items.len;

                    var the_inst = switch (binopIr.op) {
                        .Add => Inst.add(rd.getReg(), rn.getReg(), o2, true, undefined),
                        .And => Inst.and_(rd.getReg(), rn.getReg(), o2, undefined),
                        .Or => Inst.orr(rd.getReg(), rn.getReg(), o2, undefined),
                        .Xor => Inst.eor(rd.getReg(), rn.getReg(), o2, undefined),
                        else => unreachable,
                    };
                    the_inst.id = arm.program.insts.items.len;
                    try armFunc.addInst(the_inst, armBlock);
                },
                .Add => {
                    var rd = try arm.program.getOpfromIR(func, binopIr.register, arm.program.insts.items.len);
                    var rn = try arm.program.getOpfromIR(func, binopIr.lhs, null);
                    var o2 = try arm.program.getOpfromIR(func, binopIr.rhs, null);
                    try armFunc.ensureImmOrAtLeastOneReg(ir, armBlock, &rn, &o2);
                    rd.reg.inst = arm.program.insts.items.len;

                    var the_inst = switch (binopIr.op) {
                        .Add => Inst.add(rd.getReg(), rn.getReg(), o2, true, undefined),
                        else => unreachable,
                    };
                    the_inst.id = arm.program.insts.items.len;
                    try armFunc.addInst(the_inst, armBlock);
                },
            }
        },
        .Cmp => {
            // just do no work, it will not be used
            // if (nextID_ == null) {
            //     return res or false;
            // }
            // var nextInst = func.insts.get(nextID_.?).*;
            const compIR = IR.Inst.Cmp.get(irInst);
            // const brIR = IR.Inst.Br.get(nextInst);
            // if (brIR.on.i != compIR.res.i) unreachable;
            // we need to add a cmp instruction
            // and then the branch instruction
            // generate the cmp
            var cmpRD = try arm.program.getOpfromIR(func, compIR.lhs, null);
            var cmpO2 = try arm.program.getOpfromIR(func, compIR.rhs, null);
            try armFunc.ensureImmOrAtLeastOneRegNoSwap(armBlock, ir, &cmpRD, &cmpO2);

            // gen cmp
            var cmpInst = Inst.cmp(cmpRD.getReg(), cmpO2, arm.program.insts.items.len);
            try armFunc.addInst(cmpInst, armBlock);
        },
        .Br => {
            var brIR = IR.Inst.Br.get(irInst);
            //
            //         // branch to the true block
            var brTrue = Operand.asOpLabel(arm.irBBtoARMBB.get(brIR.iftrue).?);
            var brFalse = Operand.asOpLabel(arm.irBBtoARMBB.get(brIR.iffalse).?);
            var brOn = brIR.on;

            switch (brOn.kind) {
                .immediate => {
                    switch (brOn.i) {
                        IR.InternPool.FALSE => {
                            var bInst = Inst.b(brFalse.getLabel(), arm.program.insts.items.len);
                            try armFunc.addInst(bInst, armBlock);
                            return res or false;
                        },
                        IR.InternPool.TRUE => {
                            var bInst = Inst.b(brTrue.getLabel(), arm.program.insts.items.len);
                            try armFunc.addInst(bInst, armBlock);
                            return res or false;
                        },
                        else => {
                            unreachable;
                        },
                    }
                },
                else => {
                    // FIXME: this is a place where erros could happen
                },
            }

            var compReg = func.regs.get(brOn.i);
            var compInst = func.insts.get(compReg.inst).*;
            switch (compInst.op) {
                .Cmp => {
                    const compIR = IR.Inst.Cmp.get(compInst);
                    const CC = switch (compIR.cond) {
                        .NEq => ConditionCode.EQ,
                        .Eq => ConditionCode.NE,
                        .Lt => ConditionCode.GE,
                        .Gt => ConditionCode.LE,
                        .LtEq => ConditionCode.GT,
                        .GtEq => ConditionCode.LT,
                    };

                    var bccInst = Inst.bcc(brFalse.getLabel(), CC, arm.program.insts.items.len);
                    try armFunc.addInst(bccInst, armBlock);
                    // jmp to the True block
                    var bInst = Inst.b(brTrue.getLabel(), arm.program.insts.items.len);
                    try armFunc.addInst(bInst, armBlock);
                    return res;
                },
                .Binop => {
                    switch (compInst.extra.op) {
                        .And => {
                            // jmp to false
                            var jumpInst = Inst.b(brFalse.getLabel(), arm.program.insts.items.len);
                            try armFunc.addInst(jumpInst, armBlock);
                        },
                        .Or => {
                            // jmp to true
                            var jumpInst = Inst.b(brTrue.getLabel(), arm.program.insts.items.len);
                            try armFunc.addInst(jumpInst, armBlock);
                        },
                        else => {
                            unreachable;
                        },
                    }
                },
                else => {
                    unreachable;
                },
            }
        },
        .Jmp => {
            const jmpIR = IR.Inst.Jmp.get(irInst);
            var jmpInst = Inst.b(jmpIR.dest, arm.program.insts.items.len);
            try armFunc.addInst(jmpInst, armBlock);
            return res or false;
        },
        .Load => {
            const loadIR = IR.Inst.Load.get(irInst);
            var loadRD = try arm.program.getOpfromIR(func, loadIR.res, arm.program.insts.items.len);
            var loadAddr = try arm.program.getOpfromIR(func, loadIR.ptr, null);
            if (loadAddr.kind == OperandKind.Reg) {
                loadAddr.kind = OperandKind.MemReg;
            }
            var loadInst = Inst.ldr(loadRD.getReg(), loadAddr, true, arm.program.insts.items.len);
            try armFunc.addInst(loadInst, armBlock);

            switch (loadIR.ptr.kind) {
                .global => {
                    // if its a global we have to load from it again! (to get the value )
                    var loadRD_mem = loadRD;
                    loadRD_mem.kind = OperandKind.MemReg;
                    loadRD.reg.inst = arm.program.insts.items.len;
                    loadInst = Inst.ldr(loadRD.getReg(), loadRD_mem, true, arm.program.insts.items.len);
                    try armFunc.addInst(loadInst, armBlock);
                },
                else => {},
            }
        },
        .Store => {
            const storeIR = IR.Inst.Store.get(irInst);
            switch (storeIR.to.kind) {
                .global => {
                    var strAdrTmp = Reg{ .id = arm.program.regs.items.len, .name = storeIR.to.name, .inst = arm.program.insts.items.len, .irID = 0xdeadbeef };
                    try arm.program.addReg(strAdrTmp);
                    var storeAddr = try arm.program.getOpfromIR(func, storeIR.to, null);
                    var loadInst = Inst.ldr(strAdrTmp, storeAddr, true, arm.program.insts.items.len);
                    try armFunc.addInst(loadInst, armBlock);
                    // we have to load the address to a register
                    var storeAdrOp = Operand.asOpMemReg(strAdrTmp);
                    var storeRT = try arm.program.getOpfromIR(func, storeIR.from, null);
                    var storeInst = Inst.str(storeRT.getReg(), storeAdrOp, true, arm.program.insts.items.len); //lololol always be signed
                    try armFunc.addInst(storeInst, armBlock);
                },
                else => {
                    var storeRT = try arm.program.getOpfromIR(func, storeIR.from, null);
                    var storeAddr = try arm.program.getOpfromIR(func, storeIR.to, null);
                    if (storeAddr.kind == OperandKind.Reg) {
                        storeAddr.kind = OperandKind.MemReg;
                    }
                    var storeInst = Inst.str(storeRT.getReg(), storeAddr, true, arm.program.insts.items.len); //lololol always be signed
                    try armFunc.addInst(storeInst, armBlock);
                },
            }
        },
        .Call => {
            // FIXME: this is not correct calling!
            const callIR = IR.Inst.Call.get(irInst);
            // do a bl inst to the function
            // the name of the function is the fun name
            var funName = callIR.fun.name;
            var funF = armFunc;
            if (funName == ir.internIdent("printf")) {
                for (callIR.args, 0..) |arg, idx| {
                    if (idx == 0) continue;
                    var emptyReg = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF };
                    emptyReg.selection = SelectedReg.fromInt(idx);
                    try arm.program.addReg(emptyReg);
                    var argOp = try arm.program.getOpfromIR(func, arg, arm.program.insts.items.len);
                    var movInst = Inst.mov(emptyReg, argOp, arm.program.insts.items.len);
                    try armFunc.addInst(movInst, armBlock);
                }
                var blInst = Inst.bl(funName, arm.program.insts.items.len);
                try armFunc.addInst(blInst, armBlock);
            } else if (funName == ir.internIdent("scanf")) {
                // todo add storing the result into the read_scratch
                for (callIR.args, 0..) |arg, idx| {
                    if (idx == 0) continue;
                    var emptyReg = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF };
                    emptyReg.selection = SelectedReg.fromInt(idx);
                    try arm.program.addReg(emptyReg);
                    var argOp = try arm.program.getOpfromIR(func, arg, arm.program.insts.items.len);
                    var movInst = Inst.mov(emptyReg, argOp, arm.program.insts.items.len);
                    try armFunc.addInst(movInst, armBlock);
                }
                var blInst = Inst.bl(funName, arm.program.insts.items.len);
                try armFunc.addInst(blInst, armBlock);
            } else if (funName == ir.internIdent("malloc")) {
                for (callIR.args, 0..) |arg, idx| {
                    if (idx > 1) break;
                    var emptyReg = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF };
                    emptyReg.selection = SelectedReg.fromInt(idx);
                    try arm.program.addReg(emptyReg);
                    var argOp = try arm.program.getOpfromIR(func, arg, arm.program.insts.items.len);
                    var movInst = Inst.mov(emptyReg, argOp, arm.program.insts.items.len);
                    try armFunc.addInst(movInst, armBlock);
                }
                var blInst = Inst.bl(funName, arm.program.insts.items.len);
                try armFunc.addInst(blInst, armBlock);
            } else if (funName == ir.internIdent("free")) {
                for (callIR.args, 0..) |arg, idx| {
                    if (idx > 1) break;
                    var emptyReg = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF };
                    emptyReg.selection = SelectedReg.fromInt(idx);
                    try arm.program.addReg(emptyReg);
                    var argOp = try arm.program.getOpfromIR(func, arg, arm.program.insts.items.len);
                    var movInst = Inst.mov(emptyReg, argOp, arm.program.insts.items.len);
                    try armFunc.addInst(movInst, armBlock);
                }
                var blInst = Inst.bl(funName, arm.program.insts.items.len);
                try armFunc.addInst(blInst, armBlock);
            } else {

                // find the function in the program that has the same name
                var funID: Function.ID = 0;
                var found: bool = false;
                for (arm.program.functions.items) |*fun| {
                    if (fun.name == funName) {
                        funID = fun.id;
                        funF = fun;
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    std.debug.print("The function {s} was not found in the program", .{ir.getIdent(funName)});
                    return false;
                }
                // create a mov inst for each param
                for (callIR.args, 0..) |irArg, idx| {
                    if (idx > 8) utils.impossible("The number of args is greater than 8", .{});
                    std.debug.print("The len args {d}\n", .{callIR.args.len});
                    std.debug.print("armFunc.params.items.len {d}\n", .{funF.params.items.len});
                    var armReg = funF.params.items[idx];
                    armReg.selection = SelectedReg.fromInt(idx);
                    var arg = try arm.program.getOpfromIR(func, irArg, arm.program.insts.items.len);
                    var movInst = Inst.mov(armReg, arg, arm.program.insts.items.len);
                    try armFunc.addInst(movInst, armBlock);
                }

                // create the bl inst
                var blInst = Inst.bl(funName, arm.program.insts.items.len);
                try armFunc.addInst(blInst, armBlock);

                // create a mov inst for the result
                // if the result is not void
                if (callIR.retTy != .void) {
                    var retReg = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = null, .irID = 0xDEADBEEF, .selection = SelectedReg.X0 };
                    try arm.program.addReg(retReg);
                    var res_ = try arm.program.getOpfromIR(func, callIR.res, arm.program.insts.items.len);
                    // var newName = std.ArrayList(u8).init(ir.alloc);
                    // for (ir.getIdent(callIR.res.name)) |c| {
                    //     try newName.append(c);
                    // }
                    // try newName.append('_');
                    // var tmp = callIR.res.i;
                    // while (tmp != 0) {
                    //     try newName.append(@intCast((tmp % 10) + 48));
                    //     tmp /= 10;
                    // }
                    // var retName = ir.internIdent(try newName.toOwnedSlice());
                    // res_.reg.name = retName;
                    var movInst = Inst.mov(res_.getReg(), Operand.asOpReg(retReg), arm.program.insts.items.len);
                    try armFunc.addInst(movInst, armBlock);
                }
            }
        },
        .Gep => {
            // this is going to be the big kahuna
            const gepIR = IR.Inst.Gep.get(irInst);
            var getPtrVal = try arm.program.getOpfromIR(func, gepIR.ptrVal, null);
            if (getPtrVal.reg.name == ir.internIdent(".println")) {
                var gepPtrName = ir.internIdent("_println");
                getPtrVal.reg.name = gepPtrName;
                var gepRD = try arm.program.getOpfromIR(func, gepIR.res, arm.program.insts.items.len);
                gepRD.reg.selection = .X0;
                var loadInst = Inst.ldr(gepRD.getReg(), getPtrVal, true, arm.program.insts.items.len);
                try armFunc.addInst(loadInst, armBlock);
            } else if (getPtrVal.reg.name == ir.internIdent(".print")) {
                var gepPtrName = ir.internIdent("_print");
                getPtrVal.reg.name = gepPtrName;
                var gepRD = try arm.program.getOpfromIR(func, gepIR.res, arm.program.insts.items.len);
                gepRD.reg.selection = .X0;
                var loadInst = Inst.ldr(gepRD.getReg(), getPtrVal, true, arm.program.insts.items.len);
                try armFunc.addInst(loadInst, armBlock);
            } else if (getPtrVal.reg.name == ir.internIdent(".read")) {
                var gepPtrName = ir.internIdent("_read");
                getPtrVal.reg.name = gepPtrName;
                var gepRD = try arm.program.getOpfromIR(func, gepIR.res, arm.program.insts.items.len);
                gepRD.reg.selection = .X0;
                var loadInst = Inst.ldr(gepRD.getReg(), getPtrVal, true, arm.program.insts.items.len);
                try armFunc.addInst(loadInst, armBlock);
            } else {
                var gepIdx = try arm.program.getOpfromIR(func, gepIR.index, null);
                // mul gepIDX by the size of the type (8)
                var imm = ir.internIdent("8");
                var immOpt = Operand.asOpImm(imm);
                try armFunc.ensureBothReg(ir, armBlock, &immOpt, &gepIdx);
                gepIdx.reg.inst = arm.program.insts.items.len;
                // do the mul
                // add a new reg for the result of the index * 8
                var mulRD = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = arm.program.insts.items.len, .irID = 0xDEADBEEF };
                try arm.program.addReg(mulRD);
                var mulInst = Inst.mul(mulRD, gepIdx.getReg(), immOpt.getReg(), false, arm.program.insts.items.len);
                try armFunc.addInst(mulInst, armBlock);
                var mulOp = Operand.asOpReg(mulRD);

                // add the ptr val and the idx
                var gepRD = try arm.program.getOpfromIR(func, gepIR.res, arm.program.insts.items.len);
                try armFunc.ensureBothReg(ir, armBlock, &getPtrVal, &gepRD);
                try armFunc.ensureBothReg(ir, armBlock, &gepRD, &mulOp);
                if (gepRD.reg.name == IR.InternPool.NULL) {
                    gepRD.reg.name = ir.internIdent("gepRD");
                }
                gepRD.reg.inst = arm.program.insts.items.len;
                var addInst = Inst.add(gepRD.getReg(), getPtrVal.getReg(), mulOp, false, arm.program.insts.items.len);
                try armFunc.addInst(addInst, armBlock);
            }
        },
        .Bitcast => {
            const miscIR = IR.Inst.Misc.get(irInst);
            var bitcastRD = try arm.program.getOpfromIR(func, miscIR.res, arm.program.insts.items.len);
            var bitcastOp = try arm.program.getOpfromIR(func, miscIR.from, null);
            bitcastRD.reg.inst = arm.program.insts.items.len;
            var movInst = Inst.mov(bitcastRD.getReg(), bitcastOp, arm.program.insts.items.len);
            try armFunc.addInst(movInst, armBlock);
        },
        .Alloc => {
            const allocIR = IR.Inst.Alloc.get(irInst);
            var printThisLolStrStart = "    sub sp, sp, #";
            var length: usize = switch (allocIR.ty) {
                .arr => blk: {
                    var arrIRLen = allocIR.ty.arr.len;
                    arrIRLen *= 8;
                    // round to nearest 16
                    var rem = arrIRLen % 16;
                    arrIRLen += switch (rem) {
                        0 => 0,
                        else => arrIRLen + 8,
                    };
                    break :blk arrIRLen;
                },
                else => 16,
            };
            var resultString = std.ArrayList(u8).init(func.alloc);
            for (printThisLolStrStart) |c| {
                try resultString.append(c);
            }
            var tmpStr = std.ArrayList(u8).init(func.alloc);
            var tmp = length;
            while (tmp != 0) {
                try tmpStr.insert(0, @intCast((tmp % 10) + 48));
                tmp /= 10;
            }
            for (tmpStr.items) |c| {
                try resultString.append(c);
            }
            try resultString.append('\n');
            var strID = ir.internIdent(try resultString.toOwnedSlice());
            var strInst = Inst.print_this_lol(strID, arm.program.insts.items.len);
            try armFunc.addInst(strInst, armBlock);
            var allocRD = try arm.program.getOpfromIR(func, allocIR.res, arm.program.insts.items.len);
            // create mov from sp to the res
            var sp = Reg{ .id = arm.program.regs.items.len, .name = IR.InternPool.NULL, .inst = null, .irID = 0xDEADBEEF, .selection = SelectedReg.SP };
            var movInst = Inst.mov(allocRD.getReg(), Operand.asOpReg(sp), arm.program.insts.items.len);
            try armFunc.addInst(movInst, armBlock);
        },
        else => {
            std.debug.print("The inst was {s}\n", .{@tagName(irInst.op)});
            return res or false;
        },
    }
    return res or false;
}

/////////////
// TESTING //
/////////////

const ting = std.testing;
const testAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try Ast.initFromParser(parser);
    const ir = try Phi.generate(testAlloc, &ast);
    return ir;
}

const ExpectedInst = struct {
    inst: IR.Inst,
    // TODO:
    // name: []const u8,
};

// TODO: consider making `IR.Function.withInsts(insts: []inst)` or similar
// that takes an array of insts and creates the function with them
// then we can compare in much more detail
fn expectIRMatches(fun: IR.Function, expected: []const Inst) !void {
    const got = try fun.getOrderedInsts(ting.allocator);
    defer ting.allocator.free(got);
    for (expected, 0..) |expectedInst, i| {
        if (i >= got.len) {
            // bro what was copilot thinking with this one
            // `try ting.expectEqualStrings("expected more insts", "got fewer insts")`;
            log.err("expected more insts. Missing:\n{any}\n", .{expected[i..]});
            // TODO: if op == Binop check extra.op on both
            return error.NotEnoughInstructions;
        }
        var gotInst = got[i];
        // NOTE: when expanding, must make sure the `res` field on the
        // expected insts are set as they won't be by the helper creator
        // functions
        ting.expectEqual(expectedInst.op, gotInst.op) catch {
            log.err("expected op: {s}, got: {s}\n", .{ @tagName(expectedInst.op), @tagName(gotInst.op) });
            log.err("expected insts:\n\n{any}\n", .{expected});
            log.err("got insts:\n\n{any}\n", .{got});
            return error.InvalidInstruction;
        };
    }
}

fn expectResultsInIR(input: []const u8, expected: anytype) !void {
    // NOTE: testing on the strings is really nice except when you
    // add or remove an instruction and then all the registers are off
    // this can be fixed by doing the following
    // vim command with the lines selected:
    // ```
    // :'<,'>s/[\( i\d*\) ]\@<!\(\d\+\)/\=submatch(1)+1/g
    // ```
    // replacing the `+1` after the `submatch` with `-1` if
    // you removed an instruction
    // after that all of the alloca registers will be wrong
    // (actually all references to registers defined before the new/removed line)
    // but that's probably easier to fix
    // the `[\( i\d*\) ]\@<!` part makes it so it doesn't change
    // numbers prefixed with `i` or ` ` i.e. number types
    // and indices respectively
    var arena = std.heap.ArenaAllocator.init(ting.allocator);
    defer arena.deinit();
    var alloc = arena.allocator();

    const ir = try testMe(input);
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

fn inputToIRString(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const ir = try testMe(input);
    return try ir.stringify(alloc);
}
fn inputToIRStringHeader(input: []const u8, alloc: std.mem.Allocator) ![]const u8 {
    const ir = try testMe(input);
    return try ir.stringifyWithHeader(alloc);
}

// test "arm.fibonacci" {
//     errdefer log.print();
//     const in = "fun fib(int n) int { if(n <= 1) { return n;} return fib(n-1) + fib(n-2);} fun main() void { int a; a = fib(20); print a endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
//     var ir = try testMe(in);
//     var arm = try gen_program(&ir);
//     var str2 = try Stringify.stringify(&arm, &ir, ir.alloc);
//     std.debug.print("{s}\n", .{str2});
// }

// test "arm.fibbonachi_to_int_array" {
//     errdefer log.print();
//     const in = "fun fib(int n) int { if(n <= 1) { return n;} return fib(n-1) + fib(n-2);} fun main() void { int_array a; int i; i=0; a = new int_array[20];  a[0] = 0; print a[0] endl; a[1] = 1; a[2] = 2; print a[2] endl; print a[3] endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
//     var ir = try testMe(in);
//     var arm = try gen_program(&ir);
//     var str2 = try Stringify.stringify(&arm, &ir, ir.alloc);
//     std.debug.print("{s}\n", .{str2});
// }

// test "arm.fibbonachi_to_int_array" {
//     errdefer log.print();
//     const in = "fun fib(int n) int { if(n <= 1) { return n;} return fib(n-1) + fib(n-2);} fun main() void { int_array a; int i; i=0; a = new int_array[20];  while(i<20){a[i] = fib(i); print a[i] endl; i= i +1;} print a[3] endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
//     var ir = try testMe(in);
//     var arm = try gen_program(&ir);
//     var str2 = try Stringify.stringify(&arm, &ir, ir.alloc);
//     std.debug.print("{s}\n", .{str2});
// }

// test "phi.print_first_struct" {
//     errdefer log.print();
//     const in = "struct S {int a; struct S s;}; fun main() void { int a; struct S s; struct S b; s = new S; s.s = new S; s.s.a = 5; b = s.s; a = b.a; print a endl; }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
//     var ir = try testMe(in);
//     var arm = try gen_program(&ir);
//     var str2 = try Stringify.stringify(&arm, &ir, ir.alloc);
//     std.debug.print("{s}\n", .{str2});
// }

// test "phi.swap" {
//     errdefer log.print();
//     const in = "int A, B; fun main() void { int t; A =0; B =0; t = A; while(true){ t = B; B = A + 1; A = t; print t endl;} }";
//     var str = try inputToIRStringHeader(in, testAlloc);
//     std.debug.print("{s}\n", .{str});
//     var ir = try testMe(in);
//     var arm = try gen_program(&ir);
//     var str2 = try Stringify.stringify(&arm, &ir, ir.alloc);
//     std.debug.print("{s}\n", .{str2});
// }
//

test "arm_killerBubs" {
    errdefer log.print();
    const in = @embedFile("../../test-suite/tests/milestone2/benchmarks/killerBubbles/killerBubbles.mini");
    var str = try inputToIRStringHeader(in, testAlloc);
    std.debug.print("{s}\n", .{str});
    var ir = try testMe(in);
    var arm = try gen_program(&ir);
    var str2 = try Stringify.stringify(&arm, &ir, ir.alloc);
    std.debug.print("{s}\n", .{str2});
}
