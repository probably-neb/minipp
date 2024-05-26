pub const std = @import("std");
const log = @import("../log.zig");
const utils = @import("../utils.zig");
const Ast = @import("../ast.zig");

const IR = @import("ir_phi.zig");
const Phi = @import("phi.zig");

pub const Arm = @This();

pub const Imm = IR.StrID;

program: Program,
alloc: std.mem.Allocator,

pub fn init(alloc: std.mem.Allocator) Arm {
    return Arm{
        .program = Program{
            .functions = std.ArrayList(Function).init(alloc),
            .insts = std.ArrayList(Inst).init(alloc),
            .regs = std.ArrayList(Reg).init(alloc),
        },
        .alloc = alloc,
    };
}

pub const Reg = struct {
    id: ID, // the id of the register within the register list in the program
    name: IR.StrID, // the name of the register
    // kind: RegKind, this could be useed for vector type beat
    inst: ?Inst.ID, // the ID of the instruction that defines this register
    irID: IR.Register.ID,
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

    pub inline fn orr(rd: Reg, rn: Reg, op2: Operand) Inst {
        return Inst{ .oper = .ORR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2 };
    }

    pub inline fn eor(rd: Reg, rn: Reg, op2: Operand) Inst {
        return Inst{ .oper = .EOR, .rd = rd, .op1 = Operand.asOpReg(rn), .op2 = op2 };
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

    pub inline fn str(rt: Reg, addr: Operand, signed: bool) Inst {
        return Inst{ .oper = .STR, .rd = rt, .op1 = addr, .signed = signed };
    }

    pub inline fn neg(rd: Reg, op2: Operand, signed: bool) Inst {
        return Inst{ .oper = .NEG, .rd = rd, .op2 = op2, .signed = signed };
    }
};

pub const BasicBlock = struct {
    name: []const u8,
    incomers: std.ArrayList(*BasicBlock),
    outgoers: [2]?*BasicBlock,
    insts: std.ArrayList(Inst.ID),
    id: ID,
    pub const ID = usize;

    pub fn init(name: []const u8, id: ID) BasicBlock {
        return BasicBlock{
            .name = name,
            .incomers = std.ArrayList(*BasicBlock).init(),
            .outgoers = [_]*BasicBlock{ null, null },
            .insts = std.ArrayList(Inst.ID).init(),
            .id = id,
        };
    }
};

pub const Function = struct {
    name: []const u8,
    blocks: std.ArrayList(BasicBlock),
    insts: std.ArrayList(Inst.ID),
    id: ID,
    program: *Program,
    pub const ID = usize;

    pub fn init(program: *Program, name: []const u8, id: ID) Function {
        return Function{
            .name = name,
            .blocks = std.ArrayList(BasicBlock.ID).init(program.alloc),
            .insts = std.ArrayList(Inst.ID).init(program.alloc),
            .id = id,
            .program = program,
        };
    }

    pub fn addInst(func: *Function, inst: Inst, bb: *BasicBlock) !void {
        if (inst.id != func.program.insts.items.len) {
            return std.debug.panic("The instruction {d} was not the next instruction in the function", .{inst.id});
        }
        // FIXME: possiblt add the panic if the regs inside the inst are wrong too
        try func.insts.append(inst.id);
        try func.program.insts.append(inst);
        try bb.insts.append(inst);
    }

    pub fn ensureBothReg(self: *Function, ir: *IR, bb: *BasicBlock, o1: *Operand, o2: *Operand) !void {
        _ = ir;
        switch (o1.kind) {
            .Reg => {
                switch (o2.kind) {
                    .Reg => {
                        return;
                    },
                    .Imm => {
                        const name = IR.InternPool.NULL;
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = null, .irID = o2.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o2.imm));
                        movInst.id = self.program.insts.items.len;
                        try self.addInst(movInst, bb);
                        o2.* = Operand.asOpReg(reg);
                    },
                    else => {
                        return std.debug.panic("The second operand {d} was not a register", .{o2.kind});
                    },
                }
            },
            .Imm => {
                switch (o2.kind) {
                    .Reg => {
                        const name = IR.InternPool.NULL;
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = null, .irID = o1.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm));
                        movInst.id = self.program.insts.items.len;
                        try self.addInst(movInst, bb);
                        o1.* = Operand.asOpReg(reg);
                        return;
                    },
                    .Imm => {
                        const name = IR.InternPool.NULL;
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = null, .irID = o1.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm));
                        movInst.id = self.program.insts.items.len;
                        try self.addInst(movInst, bb);
                        o1.* = Operand.asOpReg(reg);

                        reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = null, .irID = o2.imm };
                        try self.program.addReg(reg);
                        movInst = Inst.mov(reg, Operand.asOpImm(o2.imm));
                        movInst.id = self.program.insts.items.len;
                        try self.addInst(movInst, bb);
                        o2.* = Operand.asOpReg(reg);
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {d} was not a register", .{o2.kind});
                    },
                }
            },
            else => {
                return std.debug.panic("The first operand {d} was not a register", .{o1.kind});
            },
        }
    }

    pub fn ensureImmOrAtLeastOneRegNoSwap(self: *Function, ir: *IR, o1: *Operand, o2: *Operand) !void {
        _ = ir;
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
                        return std.debug.panic("The second operand {d} was not a register or immediate", .{o2.kind});
                    },
                }
            },
            .Imm => {
                const name = IR.InternPool.NULL;
                var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = null, .irID = o1.imm };
                try self.program.addReg(reg);
                var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm));
                movInst.id = self.program.insts.items.len;
                try self.addInst(movInst);
                o1.* = Operand.asOpReg(reg);
                switch (o2.kind) {
                    .Reg => {
                        return;
                    },
                    .Imm => {
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {d} was not a register or immediate", .{o2.kind});
                    },
                }
            },
            else => {
                return std.debug.panic("The first operand {d} was not a register or immediate", .{o1.kind});
            },
        }
    }
    pub fn ensureImmOrAtLeastOneReg(self: *Function, ir: *IR, bb: *BasicBlock, o1: *Operand, o2: *Operand) !void {
        _ = ir;
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
                        return std.debug.panic("The second operand {d} was not a register or immediate", .{o2.kind});
                    },
                }
            },
            .Imm => {
                switch (o2.kind) {
                    .Reg => {
                        // swap the operands's values
                        var temp = o1;
                        o1 = o2;
                        o2 = temp;
                        return;
                    },
                    .Imm => {
                        // we need to create an instruction to mv o1 into a register, then change the operand to a register
                        const name = IR.InternPool.NULL;
                        var reg = Reg{ .id = self.program.regs.items.len, .name = name, .inst = null, .irID = o1.imm };
                        try self.program.addReg(reg);
                        var movInst = Inst.mov(reg, Operand.asOpImm(o1.imm));
                        movInst.id = self.program.insts.items.len;
                        try self.addInst(movInst, bb);
                        o1.* = Operand.asOpReg(reg);
                        return;
                    },
                    else => {
                        return std.debug.panic("The second operand {d} was not a register or immediate", .{o2.kind});
                    },
                }
            },
            else => {
                return std.debug.panic("The first operand {d} was not a register or immediate", .{o1.kind});
            },
        }
    }
};

pub const Program = struct {
    functions: std.ArrayList(Function),
    insts: std.ArrayList(Inst),
    regs: std.ArrayList(Reg),
    pub const ID = usize;

    pub fn addReg(program: *Program, reg: Reg) !void {
        if (reg.id != program.regs.items.len) {
            return std.debug.panic("The register {d} was not the next register in the program", .{reg.id});
        }
        try program.regs.append(reg);
    }

    pub fn getOpfromIR(self: *Program, ref: IR.Ref, instID: ?usize) !Operand {
        switch (ref.kind) {
            .local, .param => {
                var reg = Reg{ .id = self.regs.items.len, .name = ref.name, .inst = instID, .irID = ref.id };
                try self.addReg(reg);
                return Operand.asOpReg(reg);
            },
            .global => {
                unreachable;
            },
            .immediate, .immediate_u32 => {
                return Operand.asOpImm(ref.i);
            },
            else => {
                unreachable;
            },
        }
        unreachable;
    }
};

pub fn gen_program(ir: *IR) !Arm {
    var arm = Arm.init(ir.alloc);
    try arm.program.insts.append(undefined);
    _ = try gen_globals(ir, &arm);
    _ = try gen_functions(ir, arm);
}

pub fn gen_globals(ir: *IR, arm: *Arm) !bool {
    _ = arm;
    _ = ir;
}

pub fn gen_functions(ir: *IR, arm: *Arm) !bool {
    for (ir.funcs.items.items) |func| {
        try arm.program.functions.append(Function.init(&arm.program, "main", arm.program.functions.items.len));
        var armFunc = &arm.program.functions.items[arm.program.functions.items.len - 1];
        _ = try gen_function(arm, armFunc, ir, func);
    }
}

pub fn gen_function(arm: *Arm, armFunc: *Function, ir: *IR, func: *IR.Func) !bool {
    // naively create all of the basic blocks

    var irBBtoARMBB = std.HashMap(BasicBlock.ID, BasicBlock.ID).init(ir.alloc);
    var armBBtoIRBB = std.HashMap(BasicBlock.ID, BasicBlock.ID).init(ir.alloc);
    for (func.bbs.items()) |block| {
        var bb = BasicBlock{
            .name = block.name,
            .id = armFunc.blocks.items.len,
        };
        try armFunc.blocks.items.append(bb);
        const bbID = func.bbs.order.items[bb.id];
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
                arm.blocks.items[armBBID].outgoers[i] = null;
                continue;
            }
            const armOutBBID = irBBtoARMBB.get(outgoer.?).?;
            armFunc.blocks.items[armBBID].outgoers[i] = &armFunc.blocks.items[armOutBBID];
        }
    }

    // generate the instructions within them
    for (func.bbs.items(), 0..) |block, i| {
        var armBlock = armFunc.blocks.items[i];
        _ = try gen_block(arm, ir, func, armFunc, block, armBlock);
    }

    // go through and make the regs ids correct or throw errors!
}

pub fn gen_block(arm: *Arm, ir: *IR, func: *IR.Func, armFunc: *Function, irBlock: IR.BasicBlock, armBlock: BasicBlock) !bool {
    var lastInstID: ?IR.Function.InstID = null;
    var skip: bool = false;
    for (irBlock.insts.items()) |instID| {
        if (skip) {
            lastInstID = instID;
            skip = false;
            continue;
        }
        skip = try gen_inst(arm, ir, func, armFunc, irBlock, lastInstID, instID, armBlock);
        lastInstID = instID;
    }
}

pub fn gen_inst(arm: *Arm, ir: *IR, func: *IR.Func, armFunc: *Function, irBlock: IR.BasicBlock, instID_: ?IR.Function.InstID, nextID_: ?IR.Function.InstID, armBlock: BasicBlock) !bool {
    _ = irBlock;
    if (instID_ == null) {
        return true;
    }
    var instID = instID_.?;

    // its switching time baby
    const irInst = func.insts.get(instID).?;
    switch (irInst.op) {
        .Binop => {
            const binopIr = IR.Inst.Binop.get(irInst);

            switch (binopIr.op) {
                // order with two reg
                .Mul => {
                    var mulRD = try arm.program.getOpfromIR(binopIr.register, arm.program.insts.items.len);
                    var mulRn = try arm.program.getOpfromIR(binopIr.lhs, null);
                    var mulRm = try arm.program.getOpfromIR(binopIr.rhs, null);
                    try armFunc.ensureBothReg(ir, mulRn, mulRm);

                    var mulInst = Inst.mul(mulRD.getReg(), mulRn.getReg(), mulRm.getReg());
                    mulInst.id = arm.program.insts.items.len;
                    try armFunc.addInst(mulInst, armBlock);
                },
                .Div => {
                    var divRD = try arm.program.getOpfromIR(binopIr.register, arm.program.insts.items.len);
                    var divRn = try arm.program.getOpfromIR(binopIr.lhs, null);
                    var divRm = try arm.program.getOpfromIR(binopIr.rhs, null);

                    try armFunc.ensureBothReg(ir, divRn, divRm);
                    var divInst = Inst.div(divRD.getReg(), divRn.getReg(), divRm.getReg(), true);
                    divInst.id = arm.program.insts.items.len;
                    try armFunc.addInst(divInst, armBlock);
                },
                // order with one imm
                .Sub => {
                    var subRD = try arm.program.getOpfromIR(binopIr.register, arm.program.insts.items.len);
                    var subRn = try arm.program.getOpfromIR(binopIr.lhs, null);
                    var subO2 = try arm.program.getOpfromIR(binopIr.rhs, null);
                    try armFunc.ensureImmOrAtLeastOneRegNoSwap(ir, subRn, subO2);

                    var subInst = Inst.sub(subRD.getReg(), subRn.getReg(), subO2, true);
                    subInst.id = arm.program.insts.items.len;
                    try armFunc.addInst(subInst, armBlock);
                },
                // order does not matter
                .Add, .And, .Or, .Xor => {
                    var rd = try arm.program.getOpfromIR(binopIr.register, arm.program.insts.items.len);
                    var rn = try arm.program.getOpfromIR(binopIr.lhs, null);
                    var o2 = try arm.program.getOpfromIR(binopIr.rhs, null);
                    try armFunc.ensureImmOrAtLeastOneReg(ir, rn, o2);

                    var the_inst = switch (binopIr.op) {
                        .Add => Inst.add(rd.getReg(), rn.getReg(), o2, true),
                        .And => Inst.and_(rd.getReg(), rn.getReg(), o2),
                        .Or => Inst.orr(rd.getReg(), rn.getReg(), o2),
                        .Xor => Inst.eor(rd.getReg(), rn.getReg(), o2),
                        else => unreachable,
                    };
                    the_inst.id = arm.program.insts.items.len;
                    try armFunc.addInst(the_inst, armBlock);
                },
            }
        },
        .Cmp => {
            // just do no work, it will not be used
            if (nextID_ == null) {
                return false;
            }
            var nextInst = func.insts.get(nextID_.?);
            switch (nextInst.op) {
                .Br => {
                    const compIR = IR.Inst.Cmp.get(irInst);
                    const brIR = IR.Inst.Br.get(nextInst);
                    if (brIR.on.i != compIR.res.i) unreachable;
                    // we need to add a cmp instruction
                    // and then the branch instruction
                    // generate the cmp
                    var cmpRD = try arm.program.getOpfromIR(compIR.lhs, null);
                    var cmpO2 = try arm.program.getOpfromIR(compIR.rhs, null);
                    try armFunc.ensureImmOrAtLeastOneRegNoSwap(ir, cmpRD, cmpO2);

                    // gen cmp
                    var cmpInst = Inst.cmp(cmpRD.getReg(), cmpO2);
                    cmpInst.id = arm.program.insts.items.len;
                    try armFunc.addInst(cmpInst, armBlock);

                    // branch to the true block
                    var brTrue = try arm.program.getOpfromIR(brIR.iftrue, null);
                    var brFalse = try arm.program.getOpfromIR(brIR.iffalse, null);

                    const CC = switch (compIR.cond) {
                        .Eq => ConditionCode.EQ,
                        .NEq => ConditionCode.NE,
                        .GtEq => ConditionCode.GE,
                        .LtEq => ConditionCode.LE,
                        .Gt => ConditionCode.GT,
                        .Lt => ConditionCode.LT,
                        else => unreachable,
                    };

                    var bccInst = Inst.bcc(brTrue.getLabel(), CC);
                    bccInst.id = arm.program.insts.items.len;
                    try armFunc.addInst(bccInst, armBlock);
                    // jmp to the false block
                    var bInst = Inst.b(brFalse.getLabel());
                    bInst.id = arm.program.insts.items.len;
                    try armFunc.addInst(bInst, armBlock);
                    return true;
                },
            }
        },
        .Jmp => {
            const jmpIR = IR.Inst.Jmp.get(irInst);
            var jmpInst = Inst.b(jmpIR.dest);
            jmpInst.id = arm.program.insts.items.len;
            try armFunc.addInst(jmpInst, armBlock);
            return true;
        },
        .Load => {
            const loadIR = IR.Inst.Load.get(irInst);
            var loadRD = try arm.program.getOpfromIR(loadIR.register, arm.program.insts.items.len);
            var loadAddr = try arm.program.getOpfromIR(loadIR.addr, null);
            loadAddr.kind = OperandKind.MemReg;
            var loadInst = Inst.ldr(loadRD.getReg(), loadAddr, true);
            _ = loadInst;
        },
        .Store => {
            const storeIR = IR.Inst.Store.get(irInst);
            var storeRT = try arm.program.getOpfromIR(storeIR.register, arm.program.insts.items.len);
            var storeAddr = try arm.program.getOpfromIR(storeIR.addr, null);
            storeAddr.kind = OperandKind.MemReg;
            var storeInst = Inst.str(storeRT.getReg(), storeAddr, true); //lololol always be signed
            storeInst.id = arm.program.insts.items.len;
            try armFunc.addInst(storeInst, armBlock);
        },
        else => {
            std.debug.print("The inst was {s}\n", .{@tagName(irInst.op)});
            return;
        },
    }
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

test "arm.fibonacci" {
    errdefer log.print();
    const in = "fun fib(int n) int { if(n <= 1) { return n;} return fib(n-1) + fib(n-2);} fun main() void { int a; a = fib(20); print a endl; }";
    var str = try inputToIRStringHeader(in, testAlloc);
    std.debug.print("{s}\n", .{str});
}
