// STACK GEN
pub const std = @import("std");

const Ast = @import("../ast.zig");
const utils = @import("../utils.zig");
const log = @import("../log.zig");
const Set = @import("../array_hash_set.zig");

pub const InternPool = @import("../intern-pool.zig");
/// The ID of a string stored in the intern pool
/// Henceforth, all operations involving variable or struct names
/// shall utilize the power of this type, rather than `std.mem.eql(u8, a, b);`
pub const StrID = InternPool.StrID;

pub const IR = @This();

types: TypeList,
globals: GlobalsList,
funcs: FunctionList,
intern_pool: InternPool,
alloc: std.mem.Allocator,

// NOTE: could be made variable by making this a field in the IR struct
// SEE: https://releases.llvm.org/7.0.0/docs/LangRef.html#data-layout
// for defaults this is probably the safest byte alignment
pub const ALIGN = 8;

pub fn reduceChainToFirstIdent(self: *IR, chain: StrID) StrID {
    const chain_long = self.getIdent(chain);
    var start: usize = 0;
    var end: usize = 0;
    for (chain_long) |c| {
        if (c == '.') {
            break;
        }
        end += 1;
    }
    var sliced = chain_long[start..end];
    return self.internIdent(sliced);
}

pub fn isIdentChain(self: *IR, id: StrID) bool {
    // just check if there is a . in the str
    const str = self.getIdent(id);
    for (str) |c| {
        if (c == '.') {
            return true;
        }
    }
    return false;
}

// something like s.a.ass.penis -> Id{s}, Id{a},
pub fn chainToStrIdList(self: *IR, chain: StrID) !std.ArrayList(StrID) {
    var list = std.ArrayList(StrID).init(self.alloc);
    var chain_long = self.getIdent(chain);
    var tokenizer = std.mem.tokenize(u8, chain_long, ".");
    while (tokenizer.next()) |piece| {
        try list.append(self.internIdent(piece));
    }
    return list;
}

pub fn init(alloc: std.mem.Allocator) IR {
    return .{
        .types = TypeList.init(),
        .globals = GlobalsList.init(),
        .funcs = FunctionList.init(),
        .intern_pool = InternPool.init(alloc) catch unreachable,
        .alloc = alloc,
    };
}

const Stringify = @import("./stringify_phi.zig");

/// Stringify the IR with default config options
/// NOTE: highly recommended to pass a std.heap.ArenaAllocator.allocator
pub fn stringify(self: *const IR, alloc: std.mem.Allocator) ![]const u8 {
    return self.stringify_cfg(alloc, .{
        .header = false,
    });
}
pub fn stringifyWithHeader(self: *const IR, alloc: std.mem.Allocator) ![]const u8 {
    return self.stringify_cfg(alloc, .{
        .header = true,
    });
}

pub fn stringify_cfg(self: *const IR, alloc: std.mem.Allocator, cfg: Stringify.Config) ![]const u8 {
    return Stringify.stringify(self, alloc, cfg);
}

pub fn internIdent(self: *IR, ident: []const u8) StrID {
    return self.intern_pool.intern(ident) catch |err| {
        // The only way this can fail is if the intern pool is out of memory
        // I'm not typing try all over the place just so it bubbles up further
        // Im sawy mistew kewwey
        std.debug.panic("Failed to intern ident: {any}\n", .{err});
    };
}

/// Puts the ident at the given index in the ast into the interning pool
pub fn internIdentNodeAt(self: *IR, ast: *const Ast, identIdx: usize) StrID {
    const str = ast.getIdentValue(identIdx);
    return self.internIdent(str);
}

pub fn internToken(self: *IR, ast: *const Ast, token: Ast.Token) StrID {
    const value = token._range.getSubStrFromStr(ast.input);
    return self.internIdent(value);
}

pub fn astTypeToIRType(self: *IR, astType: Ast.Type) Type {
    return switch (astType) {
        .Int => .int,
        .Bool => .bool,
        .Void => .void,
        .Null => std.debug.panic("FUCK WE HAVE TO HANDLE NULL TYPE\n", .{}),
        .IntArray => .int_arr,
        .Struct => |name| blk: {
            const structID = self.internIdent(name);
            break :blk .{ .strct = structID };
        },
    };
}

pub fn safeGetIdent(self: *const IR, id: StrID) ![]const u8 {
    // this is only supposed to be used for debugging, so just panic
    return self.intern_pool.get(id);
}

pub fn getIdent(self: *const IR, id: StrID) []const u8 {
    // this is only supposed to be used for debugging, so just panic
    return self.intern_pool.get(id) catch unreachable;
}

pub fn getFun(self: *const IR, nameID: StrID) !Function {
    for (self.funcs.items.items) |func| {
        if (func.name == nameID) {
            return func;
        }
    }

    return error.NotFound;
}

pub fn parseInt(self: *const IR, id: StrID) !i64 {
    const str = try self.safeGetIdent(id);
    return std.fmt.parseInt(i64, str, 10);
}

pub fn getIdentID(self: *const IR, ident: []const u8) !StrID {
    return self.intern_pool.getIDOf(ident);
}

pub const GlobalsList = struct {
    items: List,

    pub const List = StaticSizeLookupTable(StrID, Item, Item.getKey);
    pub const Item = struct {
        name: StrID,
        type: Type,

        pub fn init(name: StrID, ty: Type) Item {
            return .{ .name = name, .type = ty };
        }

        pub fn getKey(self: Item) StrID {
            return self.name;
        }
    };

    pub fn init() GlobalsList {
        return .{ .items = undefined };
    }

    pub fn fill(self: *GlobalsList, items: []Item) void {
        const lut = List.init(items);
        self.items = lut;
    }

    pub fn index(self: *const GlobalsList, idx: usize) Item {
        return self.items.items[idx];
    }

    pub fn len(self: *const GlobalsList) usize {
        return self.items.len;
    }

    pub fn contains(self: *const GlobalsList, name: StrID) bool {
        return self.items.contains(name);
    }
};

pub const FunctionList = struct {
    items: List,
    pub const List = StaticSizeLookupTable(StrID, Function, Function.getKey);

    pub fn init() FunctionList {
        return .{ .items = undefined };
    }
    /// Note the lack of a way to add one item at a time,
    /// only many at once
    pub fn fill(self: *FunctionList, items: []Function) void {
        self.items = List.init(items);
    }

    pub fn contains(self: *const FunctionList, name: StrID) bool {
        return self.items.contains(name);
    }
};

pub const Function = struct {
    alloc: std.mem.Allocator,
    name: StrID,
    returnType: Type,
    bbsToCFG: std.AutoHashMap(BasicBlock.ID, CfgBlock.ID_t),
    cfgToBBs: std.AutoHashMap(CfgBlock.ID_t, BasicBlock.ID),
    defBlocks: std.AutoHashMap(StrID, std.ArrayList(BasicBlock.ID)),
    declaredVars: std.AutoHashMap(StrID, Type),
    bbs: OrderedList(BasicBlock),
    regs: LookupTable(Register.ID, Register, Register.getID),
    cfg: CfgFunction,
    exitBBID: BasicBlock.ID,
    retRegUsed: bool = false,

    /// a list of the instructions that are within the fuction
    /// the basic blocks have a list of instructions that they use,
    /// those come out of this list.
    /// To remove or add instructions, either remove from the Basic Block list
    /// or add to this ordered list and then referer to it in the Basic Block
    insts: OrderedList(Inst),
    returnReg: ?Register.ID = null,
    paramRegs: std.AutoHashMap(StrID, Register.ID),
    params: ParamsList,
    typesMap: std.AutoHashMap(StrID, Type),
    pub const entryBBID: usize = 0;

    pub fn init(alloc: std.mem.Allocator, name: StrID, returnType: Type, params: []Param) Function {
        return .{
            .alloc = alloc,
            .bbs = OrderedList(BasicBlock).init(alloc),
            .name = name,
            .returnType = returnType,
            .regs = LookupTable(Register.ID, Register, Register.getID).init(alloc),
            .params = ParamsList.init(params),
            .insts = OrderedList(Inst).init(alloc),
            .typesMap = std.AutoHashMap(StrID, Type).init(alloc),
            .bbsToCFG = std.AutoHashMap(BasicBlock.ID, CfgBlock.ID_t).init(alloc),
            .cfgToBBs = std.AutoHashMap(CfgBlock.ID_t, BasicBlock.ID).init(alloc),
            .paramRegs = std.AutoHashMap(StrID, Register.ID).init(alloc),
            .declaredVars = std.AutoHashMap(StrID, Type).init(alloc),
            .exitBBID = 0,
            .defBlocks = std.AutoHashMap(StrID, std.ArrayList(BasicBlock.ID)).init(alloc),
            .cfg = CfgFunction.init(alloc),
        };
    }

    pub fn identToType(self: *Function, ident: StrID) !Type {
        const protoType = self.typesMap.get(ident);
        if (protoType != null) {
            return protoType;
        }
    }

    pub fn linkBBsFromCFG(self: *Function) !void {
        for (self.cfg.postOrder.items) |cfgBlockID| {
            const cfgBock = self.cfg.blocks.items[cfgBlockID];
            for (cfgBock.outgoers) |outgoer| {
                if (outgoer == null) {
                    continue;
                }
                const edge = self.cfg.edges.items[outgoer.?];
                const bbID = self.cfgToBBs.get(edge.dest).?;
                const bbInID = self.cfgToBBs.get(edge.src).?;
                const bbOut = self.bbs.get(bbID);
                const bbIn = self.bbs.get(bbInID);
                try bbIn.addOutgoer(bbID);
                try bbOut.addIncomer(bbInID);
            }
        }
    }

    pub fn mapUsesBBFromCFG(self: *Function, ir: *IR) !void {
        for (self.cfg.postOrder.items) |cfgBlockID| {
            const cfgBock = self.cfg.blocks.items[cfgBlockID];
            const bbID = self.cfgToBBs.get(cfgBlockID).?;
            for (cfgBock.typedIdents.items) |ident| {
                var redIdent = ir.reduceChainToFirstIdent(ident);
                var bb = self.bbs.get(bbID);
                if (!bb.uses.contains(redIdent)) {
                    try bb.uses.put(redIdent, true);
                }
            }
        }
    }

    pub fn addPhiEntry(self: *Function, bbDest: BasicBlock.ID, ident: IR.StrId, bbFrom: Label, ref: Ref) !void {
        // check if an entry already exists
        // if it does, then just update the ref
        const block = try self.bbs.get(bbFrom).*;
        const phiInstID = block.phiMap.get(ident);
        if (phiInstID != null) {
            try self.insts.get(phiInstID).phiAddRef(bbFrom, ref);
            return;
        }

        var entries = std.ArrayList(PhiEntry).init(self.alloc);
        defer entries.deinit();
        entries.append(.{ .bb = bbFrom, .ref = ref });
        // create a new phi inst
        const _type = self.typesMap.get(ident).?;
        const inst = Inst.phi(ref, _type, entries);
        const phiInstReg = try self.addNamedInst(bbDest, inst, ident, _type);
        const instId = phiInstReg.inst;

        // add the phi inst to the block's phi map
        try block.addPhiInst(instId, ident);

        self.bbs.set(bbDest, block);
    }

    // index into the insts array
    pub const InstID = u32;

    pub const ParamsList = StaticSizeLookupTable(Param.ID, Param, Param.getKey);
    pub const Param = struct {
        name: StrID,
        type: Type,

        pub const ID = u32;
        pub fn getKey(self: @This()) StrID {
            return self.name;
        }
    };

    pub fn renameRef(self: *Function, ir: *IR, ref: Ref, name: StrID) Ref {
        // check the kind of the ref
        switch (ref.kind) {
            .local => {
                return self.renameLocalRef(ref, name);
            },
            .param => {
                utils.todo("use renameParamRef", .{});
            },
            .global => {
                return self.renameGlobalRef(ir, ref, name);
            },
            else => {
                std.debug.panic("Unknown ref kind: {any}\n", .{ref.kind});
            },
        }
        unreachable;
    }

    pub fn renameRefAnon(
        self: *Function,
        ir: *IR,
        ref: Ref,
    ) Ref {
        // check the kind of the ref
        switch (ref.kind) {
            .local => {
                return self.renameLocalRef(ref, IR.InternPool.NULL);
            },
            .param => {
                var ref_ = ref;
                ref_.name = IR.InternPool.NULL;
                return ref_;
            },
            .global => {
                return self.renameGlobalRef(ir, ref, IR.InternPool.NULL);
            },
            else => {
                std.debug.panic("Unknown ref kind: {any}\n", .{ref.kind});
            },
        }
        unreachable;
    }

    pub fn renameParamRef(self: *Function, ir: *IR, ref: Ref, name: StrID, inst: IR.Function.InstID) Ref {
        utils.todo("This should be removed in refactoring to params as reg", .{});
        _ = self;
        _ = ir;
        if (inst == 0) {}
        // ref.debugPrintWithName(ir);
        // utils.todo("Tried to rename a param, this is not allowed", .{});
        // const param = self.params.contains(ref.name);
        // param.name = name;
        // self.params.set(ref.i, param);
        // return Ref.param(ref.i, name, param.type);
        var refCopy = ref;
        refCopy.kind = .localedParam;
        refCopy.name = name;
        refCopy.extra = inst;
        return refCopy;
    }

    pub fn renameGlobalRef(self: *Function, ir: *IR, ref: Ref, name: StrID) Ref {
        ref.debugPrintWithName(ir);
        _ = name;
        _ = self;
        utils.todo("Tried to rename a gloabl ref, this is not implemented yet", .{});
    }

    pub fn renameLocalRef(self: *Function, ref: Ref, name: StrID) Ref {
        // get the register
        var reg = self.regs.get(ref.i);
        var inst = self.insts.get(reg.inst);
        reg.name = name;
        inst.res = IR.Ref.fromRegLocal(reg);
        self.regs.set(ref.i, reg);
        self.insts.set(reg.inst, inst.*);
        return inst.res;
    }

    pub fn getKey(self: Function) StrID {
        return self.name;
    }

    /// Requires a name which will go to the name of the label in the strinify
    pub fn newBB(self: *Function, name: []const u8) !BasicBlock.ID {
        const bb = BasicBlock.init(self.alloc, name);
        const id = try self.bbs.add(bb);
        return id;
    }

    ///
    pub fn newBBWithParent(self: *Function, parent: BasicBlock.ID, name: []const u8) !BasicBlock.ID {
        var bb = BasicBlock.init(self.alloc, name);

        // add the given parent as an incomer
        try bb.addIncomer(parent);
        const id = try self.bbs.add(bb);

        // add itself to the parent's outgoers list
        _ = try self.bbs.get(parent).addOutgoer(id);
        return id;
    }

    pub fn addNamedInst(self: *Function, bb: BasicBlock.ID, basicInst: Inst, name: StrID, ty: Type) !Register {
        // reserve
        const regID = try self.regs.add(undefined);
        const instID = try self.insts.add(undefined);

        // construct the register to be added, using the reserved IDs
        const reg = Register{ .id = regID, .inst = instID, .name = name, .bb = bb, .type = ty };
        var inst = basicInst;
        inst.res = Ref.local(regID, name, ty); // update the reference of the incoming instruction

        // save
        self.regs.set(regID, reg);
        self.insts.set(instID, inst); // in the inst array update the resulting instruction
        try self.bbs.get(bb).insts.append(instID);
        try self.bbs.get(bb).versionMap.put(name, inst.res);
        return reg;
    }

    /// Add an unnamed instruction, this is used for intermeidates,
    /// This is preety much used for print and read as shown for the LLVM stuff
    pub fn addInst(self: *Function, bb: BasicBlock.ID, inst: Inst, ty: Type) !Register {
        return self.addNamedInst(bb, inst, InternPool.NULL, ty);
    }

    pub fn addCtrlFlowInst(self: *Function, bb: BasicBlock.ID, inst: Inst) !void {
        utils.assert(inst.isCtrlFlow(), "tried to add non control flow instruction:\n{any}\n", .{inst});
        // check if the block already ends in a control flow statement
        // add inst if it doesnt, otherise assert that the two are the same
        // for easier debugging purposes
        // this makes it easy for a parent function to say "add this control flow instruction if not already there"
        // ex. adding a jump to the `%exit` block from the last bb in a function body
        const maybeLastBBInstID = self.bbs.get(bb).getLastInstID();
        if (maybeLastBBInstID) |lastBBInstID| {
            const lastInst = self.insts.get(lastBBInstID).*;
            if (lastInst.isCtrlFlow()) {
                if (!ctrlFlowInstsEqual(lastInst, inst)) {
                    log.err("tried to add control flow instruction to block that already had different control flow instruction.\nexisting = {any}\nnew = {any}\n", .{ lastInst, inst });
                    return error.ConflictingControlFlowInstructions;
                }
                // last inst is already correct, add edges if they dont exist already
                try self.connectInstBBs(bb, inst);
                return;
            }
            // otherwise we continue with the add
        }
        const instID = try self.insts.add(inst);
        try self.connectInstBBs(bb, inst);
        try self.bbs.get(bb).insts.append(instID);
    }

    /// adds edges between basic blocks based on the given control flow instruction
    /// within the given basic block
    /// NOTE: should not mess things up if the blocks are already connected,
    /// the addOutgoer|Incomer functions check if the edge is already defined
    pub fn connectInstBBs(self: *Function, bb: BasicBlock.ID, inst: Inst) !void {
        switch (inst.op) {
            .Jmp => {
                const jmp = Inst.Jmp.get(inst);
                try self.bbs.get(bb).addOutgoer(jmp.dest);
                try self.bbs.get(jmp.dest).addIncomer(bb);
            },
            .Br => {
                const br = Inst.Br.get(inst);
                try self.bbs.get(bb).addOutgoer(br.iftrue);
                try self.bbs.get(bb).addOutgoer(br.iffalse);
                try self.bbs.get(br.iftrue).addIncomer(bb);
                try self.bbs.get(br.iffalse).addIncomer(bb);
            },
            else => {
                std.debug.panic("addLoadAndStoreTo: Invalid control flow instruction: {any}\n", .{@tagName(inst.op)});
            },
        }
    }

    /// Only realy useful for store - i.e. the only(?) instruction that does not have
    /// a result register and is also noth control flow
    /// This is functionally identical to addCtrlFlowInst but with a different name
    /// for semantic clarity
    pub fn addAnonInst(self: *Function, bb: BasicBlock.ID, inst: Inst) !void {
        const instID = try self.insts.add(inst);
        try self.bbs.get(bb).insts.append(instID);
    }

    pub const NotFoundError = error{ OutOfMemory, UnboundIdentifier, AllocFailed };

    pub fn getNamedRef(self: *Function, ir: *IR, name: StrID, bb: BasicBlock.ID, assignmentTOrAccessF: bool) NotFoundError!Ref {
        const namedRef = try self.getNamedRefInner(ir, name, bb, assignmentTOrAccessF);
        if (self.returnReg == null) return namedRef;
        if (namedRef.i == self.returnReg.?) {
            self.retRegUsed = true;
        }
        return namedRef;
    }

    pub fn getNamedRefInner(self: *Function, ir: *IR, name: StrID, bb: IR.BasicBlock.ID, assignmentTOrAccessF: bool) NotFoundError!Ref {
        var ref = try self.getNamedRefNoAdd(ir, name, bb);
        if (ref != null) return ref.?;

        // at this point we know that it is a declared variable, but it has not been used yet
        // we can create a new register for it based on the passed (desired) outcome
        if (assignmentTOrAccessF) {
            // if this is anot assigned over -><- we boned
            const declType = self.typesMap.get(name).?;
            const refAss = Ref.local(0, name, declType);
            return refAss;
        } else {
            // we need to create a new register for this in the entry block using alloca
            const declType = self.typesMap.get(name).?;
            const alloca = Inst.alloca(declType);
            const allocReg = try self.addNamedInst(Function.entryBBID, alloca, name, declType);
            // add a load also for those quircky girls
            const allocRef = IR.Ref.fromReg(allocReg, self, ir);
            const load = Inst.load(declType, allocRef);
            const loadReg = try self.addNamedInst(Function.entryBBID, load, name, declType);
            const loadRef = IR.Ref.fromReg(loadReg, self, ir);
            try self.bbs.get(Function.entryBBID).versionMap.put(name, loadRef);
            return Ref.fromRegLocal(loadReg);
        }

        return error.UnboundIdentifier;
    }

    pub fn getNamedRefNoAdd(self: *Function, ir: *IR, name: StrID, bb: IR.BasicBlock.ID) NotFoundError!?Ref {
        // if (name != IR.InternPool.NULL) {
        //     std.debug.print("getting ref for {s}\n", .{ir.getIdent(name)});
        // } else {
        //     std.debug.print("getting ref for NULL\n", .{});
        // }
        // check if the register is in the current block
        if (self.bbs.get(bb).versionMap.contains(name)) {
            return self.bbs.get(bb).versionMap.get(name).?;
        }

        // do bfs to find the in the incoming blocks
        var queue = std.ArrayList(BasicBlock.ID).init(self.alloc);
        defer queue.deinit();
        var visited = std.AutoHashMap(BasicBlock.ID, bool).init(self.alloc);
        defer visited.deinit();
        try queue.append(bb);
        try visited.put(bb, true);
        while (queue.items.len > 0) {
            const current = queue.orderedRemove(0);
            // std.debug.print("visiting {s}\n", .{self.bbs.get(current).name});
            if (self.bbs.get(current).versionMap.contains(name)) {
                // std.debug.print("found in block {d}\n", .{current});
                return self.bbs.get(current).versionMap.get(name).?;
            }
            for (self.bbs.get(current).incomers.items) |incomer| {
                if (visited.contains(incomer)) {
                    continue;
                }
                try queue.append(incomer);
                try visited.put(incomer, true);
            }
        }

        if (self.bbs.get(IR.Function.entryBBID).versionMap.contains(name)) {
            return self.bbs.get(IR.Function.entryBBID).versionMap.get(name).?;
        }
        // we have not found it, we have traversed the tree all the way up! oh no!

        // checks the function's parameters
        if (self.paramRegs.contains(name)) {
            const paramRegID = self.paramRegs.get(name).?;
            const paramReg = self.regs.get(paramRegID);
            return Ref.fromReg(paramReg, self, ir);
        }
        // now we have to check if its in the typesMap,

        // okay she's nowhere...
        // if it is declared in this function return null, otherwise search on
        if (self.declaredVars.contains(name)) {
            return null;
        }
        // check if its a function?

        if (ir.funcs.items.safeIndexOf(name)) |funcID| {
            const func = ir.funcs.items.entry(funcID);
            return Ref.global(funcID, func.name, func.returnType);
        }

        log.trace("fun.name not found := {s}\n", .{
            ir.getIdent(name),
        });

        for (ir.funcs.items.items) |func| {
            log.trace("func := {s}\n", .{ir.getIdent(func.name)});
        }
        // check if its a global
        // TODO: add it so that global vars are loaded on use, will have to do the same on store
        if (ir.globals.items.safeIndexOf(name)) |globalID| {
            const global = ir.globals.items.entry(globalID);
            return Ref.global(globalID, global.name, global.type);
        }

        std.debug.print("name not found := {s}\n", .{
            ir.getIdent(name),
        });
        return error.UnboundIdentifier;
    }

    /// Gets the ID of a register created with an `alloca` in the entry
    /// based on the name of the identifier in question
    /// Returns `error.NotFound`
    /// WARN: ONLY SUPPOSED TO BE USED IN STACK IR GEN
    /// IN PHI NODES WE SHOULD SEARCH UP THE CFG
    fn getNamedAllocaReg(self: *Function, name: StrID) NotFoundError!Register {
        //       1   2            4          5     6   :(
        for (self.bbs.get(Function.entryBBID).insts.items()) |instID| {
            const inst = self.insts.get(instID);
            const res = inst.res;
            if (res.name == name) {
                return self.regs.get(res.i);
            }
        }
        return error.UnboundIdentifier;
    }

    pub fn setReturnReg(self: *Function, reg: Register.ID) void {
        self.returnReg = reg;
    }

    pub const InstIter = struct {
        func: *const Function,
        bb: BasicBlock.ID,
        instIndex: u32,

        pub fn init(func: *const Function) InstIter {
            return .{ .func = func, .bb = Function.entryBBID, .instIndex = 0 };
        }

        pub const Item = struct {
            bb: BasicBlock.ID,
            inst: Inst,
        };

        pub fn next(self: *InstIter) ?Item {
            if (self.bb >= self.func.bbs.len) {
                return null;
            }
            var bb = self.func.bbs.get(self.bb);
            if (self.instIndex >= bb.insts.len) {
                if (self.bb == self.func.exitBBID) {
                    return null;
                }
                if (self.bb >= self.func.bbs.len - 1) {
                    self.bb = self.func.exitBBID;
                } else {
                    self.bb += 1;
                    if (self.bb == self.func.exitBBID) {
                        // skip the exit bb too
                        self.bb += 1;
                    }
                }
                bb = self.func.bbs.get(self.bb);
                self.instIndex = 0;
            }
            // yeah... this one bit me
            if (self.instIndex >= bb.insts.len) {
                return null;
            }
            const instID = bb.insts.get(self.instIndex).*;
            self.instIndex += 1;
            return .{ .bb = self.bb, .inst = self.func.insts.get(instID).* };
        }
    };

    pub fn instIter(self: *const Function) InstIter {
        return InstIter.init(self);
    }

    pub fn getOrderedInsts(self: *const Function, alloc: std.mem.Allocator) ![]Inst {
        var insts = try alloc.alloc(Inst, self.insts.len);
        var iter = self.instIter();
        var i: usize = 0;
        while (iter.next()) |inst| : (i += 1) {
            insts[i] = inst;
        }
        return insts;
    }
};

fn ctrlFlowInstsEqual(a: Inst, b: Inst) bool {
    utils.assert(a.isCtrlFlow(), "tried to compare non ctrl flow instruction:\n{any}\n", .{a});
    utils.assert(b.isCtrlFlow(), "tried to compare non ctrl flow instruction:\n{any}\n", .{b});

    if (a.op == .Br and b.op == .Br) {
        const aBr = Inst.Br.get(a);
        const bBr = Inst.Br.get(b);
        return aBr.eq(bBr);
    }
    if (a.op == .Jmp and b.op == .Jmp) {
        const aJmp = Inst.Jmp.get(a);
        const bJmp = Inst.Jmp.get(b);
        return aJmp.eq(bJmp);
    }
    if (a.op == .Ret and b.op == .Ret) {
        const aRet = Inst.Ret.get(a);
        const bRet = Inst.Ret.get(b);
        return aRet.eq(bRet);
    }
    log.err("ctrl flow instructions are of different kinds: {s} != {s}\n", .{ @tagName(a.op), @tagName(b.op) });
    return false;
}

/// The number for the resiter is based off the ID ad the name
/// so if there are two xs in phi, one with id 2 and one iwth id 20
/// x = 5
/// x = x +1;
/// x2 = 5;
/// x20 = x2 + 1;
pub const Register = struct {
    id: ID,
    inst: Function.InstID,
    name: StrID,
    bb: BasicBlock.ID,
    type: Type,

    pub const ID = u32;

    pub const default: Register = .{
        .id = 0xdeadbeef,
        .inst = 0xdeadbeef,
        .name = InternPool.NULL,
        .bb = 0xdeadbeef,
        .type = .void,
    };

    pub fn getID(self: Register) ID {
        return self.id;
    }
};

pub const Edge = struct {
    src: CfgBlock.ID_t,
    dest: CfgBlock.ID_t,
    ID: usize,
    pub const ID_t = usize;
};

pub const CfgBlock = struct {
    alloc: std.mem.Allocator,
    statements: std.ArrayList(Ast.Node),
    typedIdents: std.ArrayList(StrID),
    assignments: std.ArrayList(StrID),
    incomers: std.ArrayList(Edge.ID_t),
    outgoers: [2]?Edge.ID_t,
    conditional: bool = false,
    ID: usize,
    name: []const u8,
    pub const ID_t = usize;

    pub fn print(self: *CfgBlock) void {
        std.debug.print("Block: {d}\n", .{self.ID});
        std.debug.print("Incomers: ", .{});
        for (self.incomers.items) |incomer| {
            std.debug.print("{d} ", .{incomer});
        }
        std.debug.print("\n", .{});
        std.debug.print("Outgoers: ", .{});
        for (self.outgoers) |outgoer| {
            if (outgoer == null) {
                continue;
            }
            std.debug.print("{d} ", .{outgoer.?});
        }
        std.debug.print("\n", .{});
    }

    pub fn init(alloc: std.mem.Allocator, name: []const u8) CfgBlock {
        return .{
            .alloc = alloc,
            .incomers = std.ArrayList(Edge.ID_t).init(alloc),
            .statements = std.ArrayList(Ast.Node).init(alloc),
            .outgoers = [2]?Edge.ID_t{ null, null },
            .typedIdents = std.ArrayList(StrID).init(alloc),
            .assignments = std.ArrayList(StrID).init(alloc),
            .name = name,
            .ID = 0,
        };
    }

    pub fn addIdentsFromStatement(self: *CfgBlock, ir: *IR, ast: *const Ast, node: Ast.Node) !void {
        const stat = node.kind.Statement;
        const final = stat.finalIndex;
        const start = stat.statement;
        // from start to end find any typed identifiers
        for (start..final) |idx| {
            const c_node = ast.get(idx).*;
            // check if it's a typed identifier
            switch (c_node.kind) {
                .TypedIdentifier => {
                    const typedIdent = c_node.kind.TypedIdentifier;
                    const ident = typedIdent.getName(ast);
                    if (ident.len == 0) {
                        continue;
                    }
                    const name = ir.internIdent(ident);
                    try self.typedIdents.append(name);
                },
                .Selector => {
                    const ident = try ast.selectorToString(idx);
                    if (ident.len == 0) {
                        continue;
                    }
                    const name = ir.internIdent(ident);
                    try self.typedIdents.append(name);
                },
                .LValue => {
                    const ident = try ast.lvalToString(idx);
                    if (ident.len == 0) {
                        continue;
                    }
                    const name = ir.internIdent(ident);
                    try self.typedIdents.append(name);
                    try self.assignments.append(name);
                },
                else => {},
            }
        }
    }

    pub fn addIdentsFromExpression(self: *CfgBlock, ir: *IR, ast: *const Ast, node: Ast.Node) !void {
        const expr = node.kind.Expression;
        const final = expr.last - 1;
        const start = expr.expr;
        // from start to end find any typed identifiers
        for (start..final) |idx| {
            const c_node = ast.get(idx).*;
            // check if it's a typed identifier
            switch (c_node.kind) {
                .TypedIdentifier => {
                    const typedIdent = c_node.kind.TypedIdentifier;
                    const ident = typedIdent.getName(ast);
                    if (ident.len == 0) {
                        continue;
                    }
                    const name = ir.internIdent(ident);
                    try self.typedIdents.append(name);
                },
                .Selector => {
                    const ident = try ast.selectorToString(idx);
                    if (ident.len == 0) {
                        continue;
                    }
                    const name = ir.internIdent(ident);
                    try self.typedIdents.append(name);
                },
                .LValue => {
                    const ident = try ast.lvalToString(idx);
                    if (ident.len == 0) {
                        continue;
                    }
                    const name = ir.internIdent(ident);
                    try self.typedIdents.append(name);
                    try self.assignments.append(name);
                },
                else => {},
            }
        }
    }

    pub fn addIncomer(self: *CfgBlock, fun: *CfgFunction, incomer: CfgBlock.ID_t) !Edge {
        // // see if the incommer already has an outgoer to this block
        // for (fun.blocks.items[incomer].outgoers) |outgoer| {
        //     if (outgoer == null) continue;
        //     const edge1 = fun.edges.items[outgoer.?];
        //     if (edge1.dest == self.ID) {
        //         return edge1;
        //     }
        // }
        // create a new edge
        const edge = Edge{ .src = incomer, .dest = self.ID, .ID = fun.edges.items.len };
        try fun.edges.append(edge);
        try fun.blocks.items[self.ID].incomers.append(edge.ID);
        var edge_res = try fun.blocks.items[incomer].addOutgoerEdge(fun, edge.ID);
        try fun.assertEdgeBothSides(edge_res.ID);
        return edge_res;
    }

    pub fn addOutgoer(self: *CfgBlock, fun: *CfgFunction, outgoer: CfgBlock.ID_t) !Edge {
        // check if we already outgo to this block
        // if we do, return
        for (self.outgoers) |out| {
            if (out == null) continue;
            // get the edge from the lsit
            const edge = fun.edges.items[out.?];
            if (edge.dest == outgoer) {
                return edge;
            }
        }
        // add ourselves as a incomer to the outgoer
        var edge_res = try fun.blocks.items[outgoer].addIncomer(fun, self.ID);
        try fun.assertEdgeBothSides(edge_res.ID);
        return edge_res;
    }

    pub fn addOutgoerEdge(self: *CfgBlock, fun: *CfgFunction, outgoer: Edge.ID_t) !Edge {
        // see the comment in `addOutgoer` for why this is done
        // alternative is to just ignore duplicates while actually
        // using the cfg, but that seems kinda annoying ngl
        if (self.outgoers[0] == null) {
            fun.blocks.items[self.ID].outgoers[0] = outgoer;
            // get the edge
            const edge = fun.edges.items[outgoer];
            return edge;
        } else if (self.outgoers[1] == null) {
            fun.blocks.items[self.ID].outgoers[1] = outgoer;

            // get the edge
            const edge = fun.edges.items[outgoer];
            return edge;
        } else {
            return error.TooManyOutgoers;
        }
    }

    // returns false if no edge was added(could not be found)
    pub fn updateEdge(self: *CfgBlock, fun: *CfgFunction, old_edge: Edge.ID_t, new_edge: Edge.ID_t) !bool {
        // check if its in the incomers
        var flag: bool = false;
        for (self.incomers.items, 0..) |incomer, i| {
            if (incomer == old_edge) {
                fun.blocks.items[self.ID].incomers.items[i] = new_edge;
                flag = true;
            }
        }
        // check if its in the outgoers
        if (self.outgoers[0] != null) {
            if (self.outgoers[0] == old_edge) {
                fun.blocks.items[self.ID].outgoers[0] = new_edge;
                flag = true;
            }
        }
        if (self.outgoers[1] != null) {
            if (self.outgoers[1] == old_edge) {
                fun.blocks.items[self.ID].outgoers[1] = new_edge;
                flag = true;
            }
        }
        if (flag) {
            return true;
        }

        return error.CfgEdgeNotFound;
    }
};

pub const CfgFunction = struct {
    pub const ID = usize;
    blocks: std.ArrayList(CfgBlock),
    postOrder: std.ArrayList(CfgBlock.ID_t),
    postOrderMap: std.AutoHashMap(CfgBlock.ID_t, usize),
    edges: std.ArrayList(Edge),
    alloc: std.mem.Allocator,
    params: std.ArrayList(StrID),
    decls: std.ArrayList(StrID),
    declsUsed: std.AutoHashMap(StrID, bool),
    assignments: std.AutoHashMap(StrID, std.AutoHashMap(CfgBlock.ID_t, bool)),
    paramsUsed: std.ArrayList(StrID),
    statements: std.ArrayList(Ast.Node),
    funNode: Ast.Node.Kind.FunctionType,
    dominators: std.ArrayList(Set.Set(CfgBlock.ID_t)),
    idoms: std.AutoHashMap(CfgBlock.ID_t, CfgBlock.ID_t),
    domChildren: std.AutoHashMap(CfgBlock.ID_t, std.ArrayList(CfgBlock.ID_t)),
    domFront: std.AutoHashMap(CfgBlock.ID_t, std.ArrayList(CfgBlock.ID_t)),
    exitID: CfgBlock.ID_t,

    pub const BSet = Set.Set(CfgBlock.ID_t);

    pub fn getBlockIncomerIDs(self: *CfgFunction, blockID: CfgBlock.ID_t) !std.ArrayList(CfgBlock.ID_t) {
        const block = self.blocks.items[blockID];
        var result = std.ArrayList(CfgBlock.ID_t).init(self.alloc);
        for (block.incomers.items) |incomer| {
            try result.append(self.edges.items[incomer].src);
        }
        return result;
    }

    pub fn getPostID(self: *CfgFunction, postID: usize) CfgBlock.ID_t {
        return self.postOrder.items[postID];
    }

    // // dominator of the start node is the start itself
    // Dom(n0) = {n0}
    // // for all other nodes, set all nodes as dominators
    // for each n in N - {n0}
    //     Dom(n) = N;
    // // iteratively eliminate nodes that are not dominators
    // while changes in any Dom(n)
    //     for each n in N - {n0}:
    //         Dom(n) = {n} union with intersection over Dom(p) for all p in pred(n)
    // return Dom
    pub fn generateDominators(self: *CfgFunction) !void {
        var result = try std.ArrayList(Set.Set(CfgBlock.ID_t)).initCapacity(self.alloc, self.blocks.items.len);
        // fill all the dominators with empty
        for (self.blocks.items) |_| {
            try result.append(BSet.init());
        }

        // // dominator of the start node is the start itself
        // Dom(n0) = {n0}
        // // for all other nodes, set all nodes as dominators
        // for each n in N - {n0}
        //     Dom(n) = N;
        // initialize the dominator sets
        for (self.postOrder.items, 0..) |block, i| {
            if (i == 0) {
                _ = try result.items[block].add(self.alloc, block);
                continue;
            }

            for (self.postOrder.items) |block2| {
                _ = try result.items[block].add(self.alloc, block2);
            }
        }

        // // std.debug.print("after init Dominators\n", .{});
        // for (self.postOrder.items) |block| {
        //     std.debug.print("block = {any}, ", .{block});
        //     result.items[block].print();
        //     std.debug.print("\n", .{});
        // }
        // while changes in any Dom(n)
        //     for each n in N - {n0}:
        //         Dom(n) = {n} union with intersection over Dom(p) for all p in pred(n)
        // return Dom
        var changes = true;
        while (changes) {
            changes = false;
            for (self.postOrder.items, 0..) |block, i| {
                if (i == 0) continue;

                // get the predecessors for this block
                const preds = try self.getBlockIncomerIDs(block);
                for (preds.items) |pred| {
                    // get the intersection of the dominators of the predecessors
                    // get Dom(p)
                    var predDom = result.items[pred];
                    var blockDom = result.items[block];
                    var intersection = try blockDom.intersectionOf(self.alloc, predDom);
                    _ = try intersection.add(self.alloc, block);
                    // std.debug.print("\nblock = {any}, pred = {any}\n", .{ block, pred });
                    // std.debug.print("predDom\n", .{});
                    // predDom.print();
                    // std.debug.print("blockDm\n", .{});
                    // blockDom.print();
                    // std.debug.print("intersection\n", .{});
                    // intersection.print();
                    // std.debug.print("\n", .{});
                    var changedInter = intersection.eql(blockDom);
                    if (!changedInter) {
                        result.items[block].deinit(self.alloc);
                        result.items[block] = try intersection.clone(self.alloc);
                        changes = true;
                    } else {}
                    intersection.deinit(self.alloc);
                }
                preds.deinit();
            }
        }
        self.dominators = result;
        // // std.debug.print("Dominators\n", .{});
        // for (self.postOrder.items) |block| {
        //     std.debug.print("block = {any}, ", .{block});
        //     self.dominators.items[block].print();
        //     std.debug.print("\n", .{});
        // }
    }

    // // Initialize the immediate dominators map to be empty
    // idom = {}

    // // For each node n in the set of all nodes N
    // for each n in N:
    //     // Exclude the node itself from its set of dominators to find possible idoms
    //     PossibleIdoms = Dom(n) - {n}

    //     // The idom of node n is the unique dominator d in PossibleIdoms such that
    //     // every other dominator in PossibleIdoms is also dominated by d
    //     for each d in PossibleIdoms:
    //         if ∀d' ∈ PossibleIdoms - {d} : d' ∈ Dom(d)
    //             idom[n] = d
    //             break
    // // Return the map of immediate dominators
    // return idom
    pub fn computeIdoms(self: *CfgFunction) !void {
        // for each n in N;
        for (self.postOrder.items) |block| {
            // Exclude the node itself from its set of dominators to find possible idoms
            var blockDom = self.dominators.items[block];
            var possibleIdoms = try blockDom.clone(self.alloc);
            _ = possibleIdoms.remove(block);

            // The idom of node n is the unique dominator d in PossibleIdoms such that
            // every other dominator in PossibleIdoms is also dominated by d
            var posIter = possibleIdoms.iterator();
            while (posIter.next()) |d| {
                var doms_all = true;
                // // Check if d dominates all other elements in PossibleIdoms
                // for each d' in PossibleIdoms:
                //     if d != d' and d' not in Dom(d):
                //         dominates_all = false
                //         break
                var posIter2 = possibleIdoms.iterator();
                while (posIter2.next()) |d2| {
                    if (d.key_ptr.* == d2.key_ptr.*) {
                        continue;
                    }
                    if (!self.dominators.items[d.key_ptr.*].contains(d2.key_ptr.*)) {
                        // std.debug.print("block = {d}, d = {d}, d2 = {d}\n", .{ block, d.key_ptr.*, d2.key_ptr.* });
                        doms_all = false;
                        break;
                    }
                }

                if (doms_all) {
                    // std.debug.print("idom adding block = {d}, idom = {d}\n", .{ block, d.key_ptr.* });

                    _ = try self.idoms.put(block, d.key_ptr.*);
                    break;
                }
            }
            possibleIdoms.deinit(self.alloc);
        }
    }

    // finds the children for a node
    // function find_children(idom, all_nodes, target_node):
    //     children = []

    //     // Iterate over all nodes in the graph
    //     for each node in all_nodes:
    //         // Check if the immediate dominator of the current node is the target_node
    //         if idom[node] == target_node:
    //             // If so, add the node to the children list
    //             children.append(node)

    //     // Return the list of children nodes
    //     return children
    pub fn findChildren(self: *CfgFunction, target_node: CfgBlock.ID_t) !std.ArrayList(CfgBlock.ID_t) {
        var children = std.ArrayList(CfgBlock.ID_t).init(self.alloc);
        for (self.postOrder.items) |node| {
            if (self.idoms.get(node) == target_node) {
                try children.append(node);
            }
        }
        return children;
    }

    pub fn printChildren(self: *CfgFunction, node: CfgBlock.ID_t) void {
        // print block name
        self.printBlockName(node);
        const children = self.domChildren.get(node);
        if (children == null) {
            return;
        }
        for (children.?.items) |child| {
            std.debug.print("{d} ", .{child});
        }
        std.debug.print("\n", .{});
    }

    pub fn printallChildren(self: *CfgFunction) void {
        for (self.postOrder.items) |node| {
            self.printChildren(node);
        }
    }

    pub fn generateDomChildren(self: *CfgFunction) !void {
        for (self.postOrder.items) |node| {
            try self.domChildren.put(node, try self.findChildren(node));
        }
    }

    //computeDF[n]:
    //    S = {}
    //    for each node y in succ[n]:
    //      if idom(y) != n:
    //         S = S U {y}
    //    for each child c of n in the dom-tree:
    //      computeDF[c]
    //      for each w that is in the set DF[c]
    //         if n does not dom w, or n = w:
    //            S = S U {w}
    //    DF[n] = S
    pub fn computeDomFront(self: *CfgFunction, nodeID: CfgBlock.ID_t) !void {
        const node = self.blocks.items[nodeID];
        var S = std.ArrayList(CfgBlock.ID_t).init(self.alloc);
        // for each node y in succ[n]:
        for (node.outgoers) |outgoer| {
            if (outgoer == null) {
                continue;
            }
            const edge = self.edges.items[outgoer.?];
            if (self.idoms.get(edge.dest) != nodeID) {
                // std.debug.print("edge.dest = {d}, nodeID = {d}\n", .{ edge.dest, nodeID });

                try S.append(edge.dest);
            }
        }
        // for each child c of n in the dom-tree:
        var children = self.domChildren.get(nodeID);
        if (children == null) {
            return;
        }
        for (self.domChildren.get(nodeID).?.items) |child| {
            try self.computeDomFront(child);
            const DF = self.domFront.get(child);
            if (DF == null) continue;
            for (DF.?.items) |w| {
                if (!self.dominators.items[w].contains(nodeID) or nodeID == w) {
                    try S.append(w);
                }
            }
        }
        try self.domFront.put(nodeID, S);
    }

    /// just do it for all of them
    pub fn computeAllDomFronts(self: *CfgFunction) !void {
        for (self.postOrder.items) |node| {
            try self.computeDomFront(node);
        }
    }

    pub fn genDominance(self: *CfgFunction) !void {
        try self.generateDominators();
        try self.computeIdoms();
        try self.generateDomChildren();
        try self.computeAllDomFronts();
    }

    pub fn init(alloc: std.mem.Allocator) CfgFunction {
        return .{
            .blocks = std.ArrayList(CfgBlock).init(alloc),
            .edges = std.ArrayList(Edge).init(alloc),
            .params = std.ArrayList(StrID).init(alloc),
            .decls = std.ArrayList(StrID).init(alloc),
            .declsUsed = std.AutoHashMap(StrID, bool).init(alloc),
            .paramsUsed = std.ArrayList(StrID).init(alloc),
            .statements = std.ArrayList(Ast.Node).init(alloc),
            .postOrder = std.ArrayList(CfgBlock.ID_t).init(alloc),
            .idoms = std.AutoHashMap(CfgBlock.ID_t, CfgBlock.ID_t).init(alloc),
            .domChildren = std.AutoHashMap(CfgBlock.ID_t, std.ArrayList(CfgBlock.ID_t)).init(alloc),
            .domFront = std.AutoHashMap(CfgBlock.ID_t, std.ArrayList(CfgBlock.ID_t)).init(alloc),
            .dominators = std.ArrayList(Set.Set(CfgBlock.ID_t)).init(alloc),
            .postOrderMap = std.AutoHashMap(CfgBlock.ID_t, usize).init(alloc),
            .assignments = std.AutoHashMap(StrID, std.AutoHashMap(CfgBlock.ID_t, bool)).init(alloc),
            .funNode = undefined,
            .exitID = 1,
            .alloc = alloc,
        };
    }

    pub fn printBlockName(self: *CfgFunction, id: CfgBlock.ID_t) void {
        const block = self.blocks.items[id];
        log.trace("\"{s}_{d}\"", .{ block.name, id });
    }

    pub fn assertEdgeBothSides(self: *CfgFunction, edgeID: Edge.ID_t) !void {
        // get the edge
        const edge = self.edges.items[edgeID];
        // get the src and dest
        const src = edge.src;
        const dest = edge.dest;
        var destIncomers = self.blocks.items[dest].incomers;
        var outgoers = self.blocks.items[src].outgoers;
        var outGoList = std.ArrayList(Edge.ID_t).init(self.alloc);
        defer outGoList.deinit();
        for (outgoers) |outgoer| {
            if (outgoer == null) {
                continue;
            }
            try outGoList.append(outgoer.?);
        }
        // check that the src has this edge
        var srcFlag: bool = false;
        var destFlag: bool = false;
        for (outGoList.items) |out| {
            if (out == edgeID) {
                srcFlag = true;
            }
        }
        // check that the dest has this edge
        for (destIncomers.items) |incomer| {
            if (incomer == edgeID) {
                destFlag = true;
            }
        }

        if (destFlag and srcFlag) {
            return;
        }
        unreachable;
    }

    pub fn printBlockOutEdges(self: *CfgFunction, id: CfgBlock.ID_t) !void {
        // get the blcok
        const block = self.blocks.items[id];
        // get the outgoers
        const outgoers = block.outgoers;
        if (outgoers[0] != null) {
            const edge = self.edges.items[outgoers[0].?];
            self.printBlockName(edge.src);
            std.debug.print(" -> ", .{});
            self.printBlockName(edge.dest);
            if (outgoers[1] == null) {
                std.debug.print(";\n", .{});
            } else {
                std.debug.print(", ", .{});
                const edge2 = self.edges.items[outgoers[1].?];
                self.printBlockName(edge2.dest);
                std.debug.print(";\n", .{});
            }
        } else if (outgoers[1] != null) {
            const edge = self.edges.items[outgoers[1].?];
            self.printBlockName(edge.src);
            std.debug.print(" -> ", .{});
            self.printBlockName(edge.dest);
            std.debug.print(";\n", .{});
        }
    }

    // FIXME
    // pub fn printAstRange(ast: *const Ast, start: usize, end: usize) void {
    //     for (start..end) |idx| {
    //         const node = ast.get(idx).*;
    //         const kind = node.kind;
    //         const token = node.token;
    //         std.debug.print("{d}: {s} {s}\n", .{ idx, @tagName(kind), token._range.getSubStrFromStr(ast.input) });
    //     }
    // }

    // pub fn printOutStatemetns(self: *CfgFunction, ir: *IR, blockId: CfgBlock.ID_t) void {
    //     for (self.blocks.items[blockId].statements.items) |stmt| {
    //         switch (stmt.kind) {
    //             .Expression => {
    //                 self.
    //             },
    //         }
    //         std.debug.print("{s}\n", .{ir.intern_pool.get(stmt)});
    //     }
    // }

    pub fn printOutFunAsDot(self: *CfgFunction, ir: *IR) void {
        std.debug.print("digraph G{{ \n", .{});
        std.debug.print("node [shape=box]\n", .{});
        for (self.postOrder.items) |block_id| {
            var block = self.blocks.items[block_id];
            self.printBlockName(block.ID);
            std.debug.print(" [label=", .{});
            self.printBlockName(block.ID);
            std.debug.print("+\"\\n", .{});
            for (block.typedIdents.items) |ident| {
                std.debug.print("{s}\\n", .{ir.getIdent(ident)});
            }
            std.debug.print("\"];\n", .{});
            try self.printBlockOutEdges(block.ID);
        }
        // print out params and decls as a node
        std.debug.print("params [label=\"params\\n", .{});
        for (self.params.items) |param| {
            std.debug.print("{s}\\n", .{ir.getIdent(param)});
        }
        std.debug.print("\"];\n", .{}); // end of params
        std.debug.print("decls [label=\"decls\\n", .{});
        for (self.decls.items) |decl| {
            std.debug.print("{s}\\n", .{ir.getIdent(decl)});
        }
        std.debug.print("\"];\n", .{}); // end of decls
        // print out the used decls
        std.debug.print("declsUsed [label=\"declsUsed\\n", .{});
        var keyIter = self.declsUsed.keyIterator();
        while (keyIter.next()) |key| {
            std.debug.print("{s}\\n", .{ir.getIdent(key.*)});
        }
        std.debug.print("\"];\n", .{}); // end of declsUsed
        std.debug.print("}}\n", .{});
    }

    pub fn addEdgeBetween(self: *CfgFunction, src: CfgBlock.ID_t, dest: CfgBlock.ID_t) !Edge {
        const edge = Edge{ .src = src, .dest = dest, .ID = self.edges.items.len };
        try self.edges.append(edge);
        // add the outgoer to the src block
        var srcOutgoers = self.blocks.items[src].outgoers;
        if (srcOutgoers[0] == null) {
            self.blocks.items[src].outgoers[0] = edge.ID;
        } else if (srcOutgoers[1] == null) {
            self.blocks.items[src].outgoers[1] = edge.ID;
        } else {
            return error.TooManyOutgoers;
        }

        // add the incomer to the dest block
        try self.blocks.items[dest].incomers.append(edge.ID);
        try self.assertEdgeBothSides(edge.ID);

        return edge;
    }

    // 1. Initialize:
    //    - visited = empty set
    //    - reversePostOrder = empty list

    // 2. DFS Function:
    //    function DFS(node):
    //        if node is not in visited:
    //            visited.add(node)
    //            for each child in successors(node):
    //                DFS(child)
    //            reversePostOrder.prepend(node)  // Prepend to build the list in reverse postorder

    // 3. Start DFS from Entry:
    //    - DFS(entryNode)

    // 4. Check Unvisited Nodes (optional, for handling disconnected graphs):
    //    for each node in CFG:
    //        if node is not visited:
    //            DFS(node)

    // 5. Result:
    //    - reversePostOrder now contains the nodes in reverse postorder/
    // DFS function
    pub fn DFS(self: *CfgFunction, node: CfgBlock.ID_t, visited: *std.AutoHashMap(CfgBlock.ID_t, bool), reversePostOrder: *std.ArrayList(CfgBlock.ID_t)) !void {
        if (visited.get(node) == null) {
            try visited.put(node, true);
            var outgoer = self.blocks.items[node].outgoers[1];
            if (outgoer != null) {
                const edge = self.edges.items[outgoer.?];
                try DFS(self, edge.dest, visited, reversePostOrder);
            }
            outgoer = self.blocks.items[node].outgoers[0];
            if (outgoer != null) {
                const edge = self.edges.items[outgoer.?];
                try DFS(self, edge.dest, visited, reversePostOrder);
            }
            try reversePostOrder.append(node);
        }
    }

    pub fn arrayListReverse(self: *std.ArrayList(CfgBlock.ID_t)) !void {
        var i: usize = 0;
        var j: usize = self.items.len - 1;
        while (i < j) {
            // swap ij
            var temp = self.items[i];
            self.items[i] = self.items[j];
            self.items[j] = temp;

            i += 1;
            j -= 1;
        }
    }

    pub fn isFloating(self: *CfgFunction, blockID: CfgBlock.ID_t) bool {
        const income = self.blocks.items[blockID].incomers.items.len == 0;
        const out = self.blocks.items[blockID].outgoers[0] == null and self.blocks.items[blockID].outgoers[1] == null;
        return income and out;
    }

    pub fn reversePostOrderComp(self: *CfgFunction) !void {
        var visited = std.AutoHashMap(CfgBlock.ID_t, bool).init(self.alloc);
        var reversePostOrder = std.ArrayList(CfgBlock.ID_t).init(self.alloc);
        defer {
            visited.deinit();
        }

        // start DFS from entry
        if (self.blocks.items.len == 0) {
            return;
        }
        try DFS(self, 0, &visited, &reversePostOrder);

        // check unvisited nodes
        for (self.blocks.items) |block| {
            if (visited.get(block.ID) == null) {
                // check if the node has both inputs and outputs
                if (!self.isFloating(block.ID)) {
                    try DFS(self, block.ID, &visited, &reversePostOrder);
                }
            }
        }
        try arrayListReverse(&reversePostOrder);
        for (reversePostOrder.items, 0..) |block, i| {
            try self.postOrderMap.put(block, i);
        }
        self.postOrder = reversePostOrder;
    }

    pub fn printDomFront(self: *CfgFunction) !void {
        // get dom iter
        var domIter = self.domFront.keyIterator();
        while (domIter.next()) |dom| {
            const domFront = self.domFront.get(dom.*).?;
            std.debug.print("{any} domFront: ", .{dom.*});
            for (domFront.items) |front| {
                std.debug.print("{any} ", .{front});
            }
            std.debug.print("\n", .{});
        }
    }

    pub fn generate(
        func: *Function,
        ast: *const Ast,
        funNode: Ast.Node.Kind.FunctionType,
        ir: *IR,
    ) !CfgFunction {
        var self = CfgFunction.init(func.alloc);
        // fill the params and the decls
        for (func.params.items) |param| {
            try (self.params).append(param.name);
        }

        const funBody = funNode.getBody(ast);
        var declsIter = funBody.iterLocalDecls(ast);
        while (declsIter.next()) |decl| {
            const declNode = decl.kind.TypedIdentifier;
            const declName = ir.internIdent(declNode.getName(ast));
            try self.decls.append(declName);
        }

        // pre init body and exit blocks
        const bodyInit = CfgBlock.init(func.alloc, "body");
        const exitInit = CfgBlock.init(func.alloc, "exit");
        const the_edge = try self.addBlocksWithEdge(bodyInit, exitInit);

        // get the statement from the function body
        var statIter = funBody.iterStatements(ast);
        try self.generateStatements(ast, ir, statIter, the_edge);
        try self.reversePostOrderComp();
        try self.genDominance();
        // self.printallChildren();
        // try self.printDomFront();
        // self.printOutFunAsDot(ir);

        // for every blocks's assignments add to the functions assignemnts
        for (self.postOrder.items) |blockID| {
            for (self.blocks.items[blockID].assignments.items) |ident| {
                if (!self.assignments.contains(ident)) {
                    // init the assignments for the ident
                    try self.assignments.put(ident, std.AutoHashMap(CfgBlock.ID_t, bool).init(self.alloc));
                }
                try self.assignments.getPtr(ident).?.put(blockID, true);
            }
        }
        return self;
    }

    pub fn cleanseOutgersRec(self: *CfgFunction, blockID: CfgBlock.ID_t) !void {
        var outIDArr = std.ArrayList(CfgBlock.ID_t).init(self.alloc);
        for (self.blocks.items[blockID].outgoers, 0..) |out, i| {
            if (out != null) {
                try self.assertEdgeBothSides(out.?);
                // get the edge
                var outEdge = self.edges.items[out.?];
                if (outEdge.dest == self.exitID) {
                    if (self.blocks.items[blockID].incomers.items.len == 0 and blockID != 0) {} else {
                        continue;
                    }
                }

                try outIDArr.append(self.edges.items[out.?].dest);

                self.blocks.items[blockID].outgoers[i] = null;
            }
        }
        for (outIDArr.items) |outID| {
            if (outID == self.exitID) {
                // check if we have no incomers, check if we are not block 0
                if (self.blocks.items[blockID].incomers.items.len == 0 and blockID != 0) {} else {
                    continue;
                }
            }
            var succIncomers = self.blocks.items[outID].incomers;
            var newSuccIncomers = std.ArrayList(Edge.ID_t).init(self.alloc);
            for (succIncomers.items) |incomer| {
                var succInEdge = self.edges.items[incomer];
                if (succInEdge.src == blockID) {
                    continue;
                }
                if (succInEdge.dest != outID) {
                    utils.todo("This edge has been inproperly configed fix it\n", .{});
                }
                try newSuccIncomers.append(incomer);
            }
            self.blocks.items[outID].incomers.deinit();
            self.blocks.items[outID].incomers = newSuccIncomers;
        }

        for (outIDArr.items) |outID| {
            if (self.blocks.items[outID].incomers.items.len == 0) {
                try self.cleanseOutgersRec(outID);
            }
        }

        outIDArr.deinit();
    }

    pub fn generateStatements(
        self: *CfgFunction,
        ast: *const Ast,
        ir: *IR,
        _statIter: Ast.NodeIter(.Statement),
        _edge: Edge,
    ) !void {
        var edge = _edge;
        var cBlock = edge.src;
        var statIter = _statIter;

        // to pass onto exiting child statIter must be update to be at the end of the code within the control flow
        // the edge must be updated such that the src is the exiting child, and that the dest is the block that follows top level this should alway be pointing to exit
        while (statIter.nextInc()) |c_stat| {
            const statementIndex = c_stat.kind.Statement.statement;
            const statementNode = c_stat.kind.Statement;
            self.printBlockName(cBlock);
            ast.printNodeLineTo(c_stat, log.trace);
            const innerNode = ast.get(statementIndex);
            const kind = innerNode.kind;
            const finalIndex = c_stat.kind.Statement.finalIndex;
            _ = finalIndex;

            // if not control flow
            if (!statementNode.isControlFlow(ast)) {
                // add all the idents in the statement to the block
                try self.blocks.items[cBlock].addIdentsFromStatement(ir, ast, c_stat);
                // add the statement to the block
                try self.blocks.items[cBlock].statements.append(c_stat);
                // std.debug.print("items in block ", .{});
                // self.printBlockName(cBlock);
                // std.debug.print("{any}\n", .{self.blocks.items[cBlock].statements.items});
                continue;
            }

            // add all the idents in the block (that we will now be leaving)
            // to the declsUsed
            for (self.blocks.items[cBlock].typedIdents.items) |ident| {
                try self.declsUsed.put(ident, true);
            }

            switch (kind) {
                // early optimization of removing all code that is after a return
                .Return => {
                    // add all the idents in the statement to the block
                    try self.blocks.items[cBlock].addIdentsFromStatement(ir, ast, c_stat);

                    // add the statement to the block
                    try self.blocks.items[cBlock].statements.append(c_stat);

                    // if this is a return in the body, we are done
                    if (self.exitID == edge.dest) {
                        // add all the idents in the block (that we will now be leaving)
                        // to the declsUsed
                        for (self.blocks.items[cBlock].typedIdents.items) |ident| {
                            try self.declsUsed.put(ident, true);
                        }
                        return;
                    }
                    try self.cleanseOutgersRec(cBlock);
                    var exitEdge = try self.addEdgeBetween(cBlock, self.exitID);
                    _ = exitEdge;

                    for (self.blocks.items[cBlock].typedIdents.items) |ident| {
                        try self.declsUsed.put(ident, true);
                    }
                    return;
                },
                .ConditionalIf => |_if| {
                    const isIfElse = _if.isIfElse(ast);
                    const as_ifCond = ast.get(_if.cond).*;
                    var as_thenBlock: Ast.Node = undefined;
                    var as_elseBlock: ?Ast.Node = undefined;
                    var as_elseBlockID: ?usize = undefined;

                    if (!isIfElse) {
                        as_thenBlock = ast.get(_if.block).*;
                    } else {
                        const condife = ast.get(_if.block).kind.ConditionalIfElse;
                        as_thenBlock = ast.get(condife.ifBlock).*;
                        as_elseBlockID = condife.elseBlock;
                        as_elseBlock = ast.get(condife.elseBlock).*;
                    }
                    var ed = edge;
                    // if block
                    // create 4 new blocks
                    // if.cond
                    var ifCond = CfgBlock.init(self.alloc, "if.cond");
                    try ifCond.addIdentsFromExpression(ir, ast, as_ifCond);
                    try ifCond.statements.append(as_ifCond);
                    for (ifCond.typedIdents.items) |ident| {
                        try self.declsUsed.put(ident, true);
                    }
                    ifCond.conditional = true;
                    var ifCondID = try self.addBlockOnEdge(ifCond, ed);
                    ed.src = ifCondID;

                    // then.body
                    // will add the idents and such after
                    var thenBody = CfgBlock.init(self.alloc, "then.body");
                    var thenBodyID = try self.addBlockOnEdge(thenBody, ed);
                    ed.src = thenBodyID;
                    const body_range = as_thenBlock.kind.Block.range(ast);
                    var ifThenEdge = ed;

                    // then.exit
                    var thenExit = CfgBlock.init(self.alloc, "then.exit");
                    var thenExitID = try self.addBlockOnEdge(thenExit, ed);
                    ed.src = thenExitID;

                    ifThenEdge = self.edges.items[self.blocks.items[thenBodyID].outgoers[0].?];
                    try self.assertEdgeBothSides(ifThenEdge.ID);

                    // if.exit
                    var ifExit = CfgBlock.init(self.alloc, "if.exit");
                    var ifExitID = try self.addBlockOnEdge(ifExit, ed);
                    ed.src = ifExitID;

                    edge = ed;
                    if (!isIfElse) {
                        _ = try self.addEdgeBetween(ifCondID, ifExitID);
                    }

                    if (body_range != null) {
                        // var ifBody_iter: Ast.NodeList(.Statement) = undefined;
                        // ifBody_iter = ifBody_iter.init(ast, body_range[0], body_range[1]);
                        // const ifBody_iter = Ast.NodeList(Ast.Node.Kind.Statement).init(ast, body_range[0], body_range[1]);
                        const ifBody_iter = Ast.NodeIter(@typeInfo(Ast.Node.Kind).Union.tag_type.?.Statement).init(ast, body_range.?[0], body_range.?[1]);
                        try self.generateStatements(ast, ir, ifBody_iter, self.edges.items[ifThenEdge.ID]);
                        statIter.skipTo(body_range.?[1]);
                    } else {
                        statIter.skipTo(_if.block);
                    }

                    if (isIfElse) {
                        // else block
                        // else.body
                        var elseBody = CfgBlock.init(self.alloc, "else.body");
                        var elseExit = CfgBlock.init(self.alloc, "else.exit");
                        var elseEdge = try self.addBlocksWithEdge(elseBody, elseExit);
                        _ = try self.blocks.items[ifCondID].addOutgoer(self, elseEdge.src);
                        _ = try self.blocks.items[elseEdge.dest].addOutgoer(self, ifExitID);

                        const else_range = as_elseBlock.?.kind.Block.range(ast);
                        if (else_range != null) {
                            var erage = else_range.?;
                            const elseBody_iter = Ast.NodeIter(@typeInfo(Ast.Node.Kind).Union.tag_type.?.Statement).init(ast, erage[0], erage[1]);
                            try self.generateStatements(ast, ir, elseBody_iter, elseEdge);
                            statIter.skipTo(erage[1]);
                        } else {
                            statIter.skipTo(as_elseBlockID.?);
                        }
                    }
                    cBlock = ifExitID;
                },
                .ConditionalIfElse => {},
                .While => |_while| {
                    var ed = edge;
                    const w_cond_ast = _while.cond;
                    const as_wCond = ast.get(w_cond_ast).*;
                    const w_block_ast = _while.block;
                    const w_block_ast_node = ast.get(w_block_ast).*;

                    // while loop
                    var wCond = CfgBlock.init(self.alloc, "while.cond1");
                    wCond.conditional = true;
                    try wCond.addIdentsFromExpression(ir, ast, as_wCond);
                    try wCond.statements.append(as_wCond);
                    for (wCond.typedIdents.items) |ident| {
                        try self.declsUsed.put(ident, true);
                    }
                    var wCondID = try self.addBlockOnEdge(wCond, ed);
                    ed.src = wCondID;

                    var wCond2 = CfgBlock.init(self.alloc, "while.cond2");
                    wCond2.conditional = true;
                    try wCond2.addIdentsFromExpression(ir, ast, as_wCond);
                    try wCond2.statements.append(as_wCond);
                    for (wCond2.typedIdents.items) |ident| {
                        try self.declsUsed.put(ident, true);
                    }
                    var wCondID2 = try self.addBlockOnEdge(wCond2, ed);
                    ed.src = wCondID2;

                    // b edge is between the conds -> fist item in wCond2 edges
                    var bEdge = self.edges.items[self.blocks.items[wCondID].outgoers[0].?];

                    // create the body block
                    var wBody = CfgBlock.init(self.alloc, "while.body");
                    var wBodyID = try self.addBlockOnEdge(wBody, bEdge);

                    // create the fillback block (to be added between cond2 and body)
                    var wFillback = CfgBlock.init(self.alloc, "while.fillback");
                    var fbEdge = Edge{ .src = wCondID2, .dest = wBodyID, .ID = self.edges.items.len };
                    try self.edges.append(fbEdge);
                    self.blocks.items[wCondID2].outgoers[1] = fbEdge.ID;
                    try self.blocks.items[wBodyID].incomers.append(fbEdge.ID);
                    try self.assertEdgeBothSides(fbEdge.ID);

                    var wFillbackID = try self.addBlockOnEdge(wFillback, fbEdge);

                    // create the exit block
                    var wExit = CfgBlock.init(self.alloc, "while.exit");
                    var wExitID = try self.addBlockOnEdge(wExit, ed);
                    ed.src = wExitID;

                    // swap wCond2's outgoers
                    var wCond2Outgoers = self.blocks.items[wCondID2].outgoers;
                    self.blocks.items[wCondID2].outgoers[0] = wCond2Outgoers[1];
                    self.blocks.items[wCondID2].outgoers[1] = wCond2Outgoers[0];

                    _ = try self.addEdgeBetween(wCondID, wExitID);

                    // add the body to the block
                    const body_range = w_block_ast_node.kind.Block.range(ast);
                    if (body_range != null) {
                        const wBody_iter = Ast.NodeIter(@typeInfo(Ast.Node.Kind).Union.tag_type.?.Statement).init(ast, body_range.?[0], body_range.?[1]);

                        try self.generateStatements(ast, ir, wBody_iter, self.edges.items[bEdge.ID]);
                        // iterate over every block from wExitId to the most recent block
                        // and add the typed idents from the body to the fillback block
                        for (wExitID..self.blocks.items.len) |id| {
                            for (self.blocks.items[id].typedIdents.items) |ident| {
                                try self.blocks.items[wFillbackID].typedIdents.append(ident);
                                try self.blocks.items[wFillbackID].assignments.append(ident);
                            }
                        }
                        // for the idents in body add them to the fillback block
                        for (self.blocks.items[wBodyID].typedIdents.items) |ident| {
                            try self.blocks.items[wFillbackID].typedIdents.append(ident);
                            try self.blocks.items[wFillbackID].assignments.append(ident);
                        }
                        // for the idents in while cond2 add them to the fillback block
                        for (self.blocks.items[wCondID2].typedIdents.items) |ident| {
                            try self.blocks.items[wFillbackID].typedIdents.append(ident);
                            try self.blocks.items[wFillbackID].assignments.append(ident);
                        }
                        statIter.skipTo(body_range.?[1]);
                    } else {
                        statIter.skipTo(w_block_ast);
                    }
                    cBlock = wExitID;
                    edge = ed;
                },
                else => {
                    unreachable;
                },
            }
        }
        // add all the idents in the block (that we will now be leaving)
        // to the declsUsed
        for (self.blocks.items[cBlock].typedIdents.items) |ident| {
            try self.declsUsed.put(ident, true);
        }
    }

    pub fn addBlocksWithEdge(self: *CfgFunction, blockSrc_: CfgBlock, blockDest_: CfgBlock) !Edge {
        var blockSrc = blockSrc_;
        var blockDest = blockDest_;
        const srcID = self.blocks.items.len;
        const destID = self.blocks.items.len + 1;
        blockSrc.ID = srcID;
        blockDest.ID = destID;
        try self.blocks.append(blockSrc);
        try self.blocks.append(blockDest);

        const edge = Edge{ .src = srcID, .dest = destID, .ID = self.edges.items.len };
        try self.edges.append(edge);

        self.blocks.items[srcID].outgoers[0] = edge.ID;
        try (self.blocks.items[destID].incomers).append(edge.ID);
        try self.assertEdgeBothSides(edge.ID);
        return edge;
    }

    pub fn addBlock(self: *CfgFunction, block_: CfgBlock) !CfgBlock.ID_t {
        var block = block_;
        const id = self.blocks.items.len;
        block.ID = id;
        try (self.blocks).append(block);
        return id;
    }

    pub fn addBlockOnEdge(self: *CfgFunction, block_: CfgBlock, edge_: Edge) !CfgBlock.ID_t {
        var edge = edge_.ID;
        var block = block_;
        const id = self.blocks.items.len;
        block.ID = id;
        try (self.blocks).append(block);
        // try (self.blocks.items[edge.dest]).addIncomer(id);

        return try self.insertBlockOnEdge(id, edge);
    }

    pub fn insertBlockOnEdge(self: *CfgFunction, blockID: CfgBlock.ID_t, edge: Edge.ID_t) !CfgBlock.ID_t {
        // find the edge
        const e = self.edges.items[edge];

        // new edge between old source and new block
        const newEdge = Edge{ .src = e.src, .dest = blockID, .ID = self.edges.items.len };
        try self.edges.append(newEdge);

        _ = try (self.blocks.items[e.src]).updateEdge(self, edge, newEdge.ID);

        self.blocks.items[blockID].outgoers[0] = edge;
        try (self.blocks.items[blockID].incomers).append(newEdge.ID);

        // update the old edge to point from the new block to the old
        self.edges.items[edge].src = blockID;
        try self.assertEdgeBothSides(newEdge.ID);
        try self.assertEdgeBothSides(edge);
        return blockID;
    }

    pub fn getBlock(self: *CfgFunction, id: CfgBlock.ID_t) CfgBlock {
        return self.blocks.items[id];
    }
};

pub const BasicBlock = struct {
    name: []const u8,
    incomers: std.ArrayList(Label),
    outgoers: [2]?Label,
    defs: Set.Set(StrID),
    uses: std.AutoHashMap(StrID, bool),
    // a map of strID to the last definition within this block
    versionMap: std.AutoHashMap(StrID, Ref),
    // and ORDERED list of the instruction ids of the instructions in this block
    insts: List,
    phiInsts: std.ArrayList(Function.InstID),
    phiMap: std.AutoHashMap(StrID, Function.InstID),

    pub fn addRefToPhi(self: BasicBlock.ID, fun: *Function, ref: Ref, bbIn: BasicBlock.ID, name: StrID) !Function.InstID {
        // std.debug.print("ref.i {any}\n", .{ref.i});
        const bb = fun.bbs.get(self);
        var phiInstID = bb.getPhi(name);
        if (phiInstID == null) {
            phiInstID = try IR.BasicBlock.addEmptyPhiOrClear(self, fun, name);
        }
        const phiInst = fun.insts.get(phiInstID.?);
        var phi = IR.Inst.Phi.get(phiInst.*);
        // std.debug.print("ref.i {any}\n", .{ref.i});
        try phi.entries.append(IR.PhiEntry{ .ref = ref, .bb = bbIn });
        // std.debug.print("entries: {any}\n", .{phi.entries.items});
        var updatedPhiInst = phi.toInst();
        fun.insts.set(phiInstID.?, updatedPhiInst);
        return phiInstID.?;
    }

    pub fn addRefToPhiReturn(self: BasicBlock.ID, fun: *Function, ref: Ref, bbIn: BasicBlock.ID, ir: *IR) !Function.InstID {
        var name = ir.internIdent("return_reg");
        // std.debug.print("ref.i {any}\n", .{ref.i});
        const bb = fun.bbs.get(self);
        var phiInstID = bb.getPhi(name);
        if (phiInstID == null) {
            phiInstID = try IR.BasicBlock.addEmptyPhiReturn(self, fun, ir);
        }
        const phiInst = fun.insts.get(phiInstID.?);
        var phi = IR.Inst.Phi.get(phiInst.*);
        // std.debug.print("ref.i {any}\n", .{ref.i});
        try phi.entries.append(IR.PhiEntry{ .ref = ref, .bb = bbIn });
        // std.debug.print("entries: {any}\n", .{phi.entries.items});
        var updatedPhiInst = phi.toInst();
        fun.insts.set(phiInstID.?, updatedPhiInst);
        return phiInstID.?;
    }

    pub fn addEmptyPhiReturn(self: BasicBlock.ID, fun: *Function, ir: *IR) !Function.InstID {
        var ident = ir.internIdent("return_reg");
        const bbMap = fun.bbs.get(self).*.phiMap;
        if (bbMap.contains(ident)) {
            const contInst = bbMap.get(ident).?;
            const fInst = fun.insts.get(contInst).*;
            var phiInst = IR.Inst.Phi.get(fInst);
            try phiInst.entries.resize(0);
            const phiInstInst = phiInst.toInst();
            fun.insts.set(contInst, phiInstInst);
            try fun.bbs.get(self).versionMap.put(ident, fInst.res);
            return contInst;
        }
        const identType = fun.typesMap.get(ident).?;
        var phiEntries = std.ArrayList(IR.PhiEntry).init(fun.alloc);
        const phi = Inst.phi(IR.Ref.default, identType, phiEntries);

        // reserve
        const regID = try fun.regs.add(undefined);
        const instID = try fun.insts.add(undefined);

        // construct the register to be added, using the reserved IDs
        const reg = Register{ .id = regID, .inst = instID, .name = ident, .bb = self, .type = identType };
        var inst = phi;
        inst.res = Ref.local(regID, ident, identType); // update the reference of the incoming instruction

        // save
        fun.regs.set(regID, reg);
        fun.insts.set(instID, inst); // in the inst array update the resulting instruction
        try fun.bbs.get(self).versionMap.put(ident, inst.res);

        try fun.bbs.get(self).addPhiInst(instID, ident);
        return instID;
    }

    // creates a new instruction phi node and adds it to the block, adds it to the phiMap
    // and version map
    pub fn addEmptyPhiOrClear(self: BasicBlock.ID, fun: *Function, ident: StrID) !Function.InstID {
        const bbMap = fun.bbs.get(self).*.phiMap;
        if (bbMap.contains(ident)) {
            const contInst = bbMap.get(ident).?;
            const fInst = fun.insts.get(contInst).*;
            var phiInst = IR.Inst.Phi.get(fInst);
            try phiInst.entries.resize(0);
            const phiInstInst = phiInst.toInst();
            fun.insts.set(contInst, phiInstInst);
            try fun.bbs.get(self).versionMap.put(ident, fInst.res);
            return contInst;
        }
        const identType = fun.typesMap.get(ident).?;
        var phiEntries = std.ArrayList(IR.PhiEntry).init(fun.alloc);
        const phi = Inst.phi(IR.Ref.default, identType, phiEntries);

        // reserve
        const regID = try fun.regs.add(undefined);
        const instID = try fun.insts.add(undefined);

        // construct the register to be added, using the reserved IDs
        const reg = Register{ .id = regID, .inst = instID, .name = ident, .bb = self, .type = identType };
        var inst = phi;
        inst.res = Ref.local(regID, ident, identType); // update the reference of the incoming instruction

        // save
        fun.regs.set(regID, reg);
        fun.insts.set(instID, inst); // in the inst array update the resulting instruction
        try fun.bbs.get(self).versionMap.put(ident, inst.res);

        try fun.bbs.get(self).addPhiInst(instID, ident);
        return instID;
    }

    // ads aphi node with %name = phi [%undef, %pred block]
    pub fn addPhiWithPreds(bbID: BasicBlock.ID, fun: *Function, ident: StrID) !Function.InstID {
        const bb = fun.bbs.get(bbID);
        const currentPhiInstID = try BasicBlock.addEmptyPhiOrClear(bbID, fun, ident);
        const bbPhiInst = fun.insts.get(currentPhiInstID).*;
        var bbPhi = IR.Inst.Phi.get(bbPhiInst);

        for (bb.incomers.items) |it| {
            // const predBB = fun.bbs.get(it);
            // const predInst = predBB.versionMap.get(ident);
            // if there is no phi for the pred block then continue
            // if (predInst == null) {
            var phiEntryTemp = IR.PhiEntry{ .ref = IR.Ref.default, .bb = it };
            phiEntryTemp.ref.name = ident;
            try bbPhi.entries.append(phiEntryTemp);
            // continue;
            // }
            // try bbPhi.entries.append(IR.PhiEntry{ .ref = predInst.?, .bb = it });
        }

        const phiInst = bbPhi.toInst();
        fun.insts.set(currentPhiInstID, phiInst);
        return currentPhiInstID;
    }

    pub fn addPhiInst(self: *BasicBlock, instID: Function.InstID, ident: StrID) !void {
        try self.phiInsts.append(instID);
        try self.phiMap.put(ident, instID);
        try self.uses.put(ident, true);
    }

    pub fn getPhi(self: *BasicBlock, ident: StrID) ?Function.InstID {
        return self.phiMap.get(ident);
    }

    /// The ID of a basic block is it's index within the arraylist of
    /// basic blocks in the `Function` type
    /// This is done differently than the LUT based approach for almost
    /// everthing else in the IR because the order of the basic blocks
    pub const ID = u32;

    pub const List = OrderedList(Function.InstID);

    pub fn init(alloc: std.mem.Allocator, name: []const u8) BasicBlock {
        return .{
            .incomers = std.ArrayList(Label).init(alloc),
            .defs = Set.Set(StrID).init(),
            .uses = std.AutoHashMap(StrID, bool).init(alloc),
            .versionMap = std.AutoHashMap(StrID, Ref).init(alloc),
            .outgoers = [2]?Label{ null, null },
            .insts = List.init(alloc),
            .phiInsts = std.ArrayList(Function.InstID).init(alloc),
            .phiMap = std.AutoHashMap(StrID, Function.InstID).init(alloc),
            .name = name,
        };
    }

    pub fn addIncomer(self: *BasicBlock, incomer: Label) !void {
        // see the comment in `addOutgoer` for why this is done
        // alternative is to just ignore duplicates while actually
        // using the cfg, but that seems kinda annoying ngl
        for (self.incomers.items) |existing| {
            if (existing == incomer) {
                return;
            }
        }
        try self.incomers.append(incomer);
    }

    pub fn addOutgoer(self: *BasicBlock, outgoer: Label) !void {
        // note the `or _ == outgoer` to allow adding the same outgoer twice
        // without reprecussions. This just makes me less worried about adding
        // outgoers in `Function` helper methods
        if (self.outgoers[0] == null or self.outgoers[0] == outgoer) {
            self.outgoers[0] = outgoer;
        } else if (self.outgoers[1] == null or self.outgoers[1] == outgoer) {
            self.outgoers[1] = outgoer;
        } else {
            return error.TooManyOutgoers;
        }
    }

    pub fn getLastInstID(self: *const BasicBlock) ?Function.InstID {
        if (self.insts.len == 0) {
            return null;
        }
        return self.insts.items()[self.insts.len - 1];
    }
};

/// A lookup table where the index of the item is the key
/// and the size never changes after being initialized
pub fn StaticSizeLookupTable(comptime Key: type, comptime Value: type, comptime getKey: fn (val: Value) Key) type {
    return struct {
        items: []Value,
        len: u32,

        const Self = @This();

        pub const Index = u32;

        pub fn init(items: []Value) Self {
            return .{ .items = items, .len = @intCast(items.len) };
        }

        /// FIXME: if you see this function followed
        /// immediately by a call to `entry`
        /// it should bre replaced with a call to lookup
        /// FIXME: remove and make safeIndexOf be indexOf  -> ?Value
        /// or !Value
        pub fn indexOf(self: Self, key: Key) Index {
            const maybe_id = self.safeIndexOf(key);
            if (maybe_id) |id| {
                return id;
            }
            @panic("Item not found in lookup table");
        }

        pub fn safeIndexOf(self: Self, key: Key) ?Index {
            for (self.items, 0..) |existing, i| {
                const itemKey = getKey(existing);
                if (itemKey == key) {
                    return @intCast(i);
                }
            }
            return null;
        }

        pub fn lookup(self: Self, key: Key) !Value {
            const maybeid = self.safeIndexOf(key);
            if (maybeid) |id| {
                return self.items[id];
            }
            return error.NotFound;
        }

        /// Like lookup but also returns the index
        pub fn find(self: Self, key: Key) ?struct { index: Index, value: Value } {
            for (self.items, 0..) |existing, i| {
                const itemKey = getKey(existing);
                if (itemKey == key) {
                    return .{ .index = @intCast(i), .value = existing };
                }
            }
            return null;
        }

        pub fn entry(self: Self, key: Index) Value {
            return self.items[key];
        }

        pub fn get(self: Self, key: Index) *Value {
            return &self.items[key];
        }

        /// Helper mainly for the `fromLUT` function for when the value is the key
        pub fn IDgetKeyHelper(val: anytype) @TypeOf(val) {
            return val;
        }

        /// Helper for creating a static size lookup table from another LUT given it's length
        /// Because both will use the indices as keys, 0 in the new LUT will be the same
        /// as 0 in the old LUT and so on
        pub fn initSized(alloc: std.mem.Allocator, size: usize, maybeDefault: ?Value) !Self {
            const default = maybeDefault orelse undefined;

            const items = try alloc.alloc(Value, size);

            for (0..size) |i| {
                items[i] = default;
            }
            return Self.init(items);
        }
        pub fn contains(self: Self, key: Key) bool {
            return self.safeIndexOf(key) != null;
        }
    };
}

/// A lookup table where the index of the item is the key
/// and it is backed by an `ArrayList`. The the arraylist itself is
/// append only and therefore the keys never change
pub fn LookupTable(comptime Key: type, comptime Value: type, comptime getKey: fn (val: Value) Key) type {
    return struct {
        items: List,
        len: u32,

        const Self = @This();

        pub const ID = u32;

        pub const List = std.ArrayList(Value);

        pub fn init(alloc: std.mem.Allocator) Self {
            const items = List.init(alloc);
            return .{ .items = items, .len = @intCast(items.items.len) };
        }

        /// A wrapper around `safeLookup` that panics if the key is not
        /// found
        pub fn lookup(self: Self, key: Key) Key {
            const maybe_id = self.safeLookup(key);
            if (maybe_id) |id| {
                return id;
            }
            @panic("Item not found in lookup table");
        }

        pub fn safeLookup(self: Self, key: Key) ?ID {
            for (self.items.items, 0..) |existing, i| {
                const itemKey = getKey(existing);
                if (itemKey == key) {
                    return i;
                }
            }
            return null;
        }

        pub fn get(self: Self, key: ID) Value {
            return self.items.items[key];
        }

        pub fn getPtr(self: Self, key: ID) *Value {
            return &self.items.items[key];
        }

        pub fn set(self: *Self, key: ID, value: Value) void {
            self.items.items[key] = value;
        }

        pub fn add(self: *Self, val: Value) !ID {
            // const id = self.len;
            try self.items.append(val);
            self.len += 1;
            return @intCast(self.items.items.len - 1);
            // return id;
        }
    };
}

/// A wrapper around `std.ArrayList` to provide a way to get
/// the index when you append, and some other helpers TBD + nicer interface
/// (.len field, .get method etc.)
pub fn OrderedList(comptime T: type) type {
    return struct {
        list: std.ArrayList(T),
        len: u32,
        ids: std.ArrayList(u32),
        order: std.ArrayList(u32),

        pub const Self = @This();
        pub const UNDEF = std.math.maxInt(u32);

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{
                .list = std.ArrayList(T).init(alloc),
                .order = std.ArrayList(u32).init(alloc),
                .ids = std.ArrayList(u32).init(alloc),
                .len = 0,
            };
        }

        /// A helper for iterating instead of `field.list.items`
        pub inline fn items(self: Self) []T {
            return self.list.items;
        }

        // TODO: consider refactoring to return just `T`
        // and create another `getPtr` for when you need a pointer
        // the `.*` everywhere is kinda annoying ngl
        pub inline fn get(self: Self, idx: u32) *T {
            const actual = self.order.items[idx];
            utils.assert(actual != Self.UNDEF, "tried to access removed element in ordered list {d}\n", .{idx});
            return &self.list.items[actual];
        }

        /// Appends an item and returns the index
        pub fn add(self: *Self, item: T) !u32 {
            const id = self.len;
            try self.list.append(item);
            try self.ids.append(id);
            try self.order.append(id);
            self.len += 1;
            return id;
        }

        pub inline fn set(self: *Self, idx: u32, item: T) void {
            const actual = self.order.items[idx];
            utils.assert(actual != Self.UNDEF, "tried to access removed element in ordered list {d}\n", .{idx});
            self.list.items[actual] = item;
        }

        /// same as add, but does not return the index
        /// for when you just don't care yk?
        pub fn append(self: *Self, item: T) !void {
            _ = try self.add(item);
        }

        // actuall remove from ids and list
        pub fn remove(self: *Self, id: u32) void {
            const index = self.order.items[id];
            utils.assert(index != Self.UNDEF, "tried to remove removed element in ordered list {d}\n", .{id});
            self.order.items[id] = Self.UNDEF;
            _ = self.list.orderedRemove(index);
            _ = self.ids.orderedRemove(index);
            if (index + 1 < self.len) {
                for (index + 1..self.len - 1) |i| {
                    if (self.order.items[i] == Self.UNDEF) {
                        continue;
                    }
                    self.order.items[i] -= 1;
                }
            }
            self.len -= 1;
        }

        pub fn orderedRemove(self: *Self, idx: u32) T {
            const val = self.list.orderedRemove(idx);
            _ = self.ids.orderedRemove(idx);
            for (self.order.items) |*i| {
                if (i.* == idx) {
                    i.* = Self.UNDEF;
                    continue;
                }
                if (i.* > idx) {
                    i.* -= 1;
                }
            }
            self.len -= 1;
            return val;
        }
    };
}

pub const StructType = struct {
    // NOTE: same as this structs ID
    name: StrID,
    size: u32,
    /// Lookup table for field names, where index of fields StrID
    /// is the index of the field i.e. its FieldID
    /// The slice is assumed to be allocated and freed if necessary by the TypeList
    fieldLookup: FieldList,

    pub const ID = StrID;
    const FieldList = StaticSizeLookupTable(StrID, Field, Field.getKey);

    pub const Field = struct {
        name: StrID,
        type: Type,

        pub fn init(name: StrID, ty: Type) Field {
            return .{ .name = name, .type = ty };
        }

        pub fn getKey(self: Field) StrID {
            return self.name;
        }
    };

    pub const FieldID = u32;

    pub fn init(name: StrID, size: u32, fieldList: []Field) StructType {
        const fieldLookup = FieldList.init(fieldList);
        return .{ .name = name, .fieldLookup = fieldLookup, .size = size };
    }

    pub fn getFieldWithName(self: StructType, name: StrID) !struct { index: u32, field: Field } {
        const field = self.fieldLookup.find(name) orelse {
            return error.FieldNotFound;
        };

        return .{ .index = field.index, .field = field.value };
    }

    pub fn indexOfFieldWithName(self: StructType, name: StrID) !FieldList.Index {
        return self.fieldLookup.safeIndexOf(name) orelse error.FieldNotFound;
    }

    pub fn fields(self: *const StructType) []Field {
        return self.fieldLookup.items;
    }

    pub fn numFields(self: StructType) usize {
        return @as(usize, self.fieldLookup.len);
    }

    pub fn getKey(self: StructType) StrID {
        return self.name;
    }

    pub fn getType(self: *const StructType) Type {
        return .{ .strct = self.name };
    }
};

pub const StructID = StrID;

/// Literally just a list of types
/// Abstracted so we can change it as needed and define helpers
pub const TypeList = struct {
    items: List,

    // TODO: use lookup table
    pub const List = StaticSizeLookupTable(StructID, Item, Item.getKey);
    pub const Item = StructType;

    pub fn init() TypeList {
        return .{ .items = undefined };
    }

    /// Note the lack of a way to add one item at a time,
    /// only many at once
    pub fn fill(self: *TypeList, items: []Item) void {
        self.items = List.init(items);
    }

    pub fn len(self: *const TypeList) usize {
        return @intCast(self.items.len);
    }

    pub fn get(self: *const TypeList, id: StructID) !Item {
        return self.items.lookup(id) catch error.TypeNotFound;
    }

    /// WARN: I think I saw somewhere that the AutoArrayHashMap preserves
    /// insertion order but I'm not sure
    pub fn index(self: *const TypeList, idx: usize) Item {
        return self.items.items[idx];
    }

    pub fn getFromIdent(self: *const TypeList, ident: StrID) !Item {
        return self.items.lookup(ident) catch error.TypeNotFound;
    }

    // TODO: !!!
};

/// Literally just a list of types... for now... bwahahaha
/// Abstracted so we can change it as needed and define helpers
pub const InstructionList = struct {
    items: List,

    pub const List = std.ArrayList(Inst);

    pub fn init(alloc: std.mem.Allocator) InstructionList {
        return .{ .items = List.init(alloc) };
    }

    // TODO: !!!
};

/// This is for LLVM 3.4.2 (with some differences for newer versions noted inline). The full
/// manual is linked from the course website. There are often multiple variants of each of the
/// following instructions; I list here only what I used (a sampling of what is available).
pub const Op = enum {
    // Arithmetic
    /// <result> = add <ty> <op1>, <op2>
    /// <result> = mul <ty> <op1>, <op2>
    /// <result> = sdiv <ty> <op1>, <op2>
    /// <result> = sub <ty> <op1>, <op2>
    // Boolean
    /// <result> = and <ty> <op1>, <op2>
    /// <result> = or <ty> <opi>, <op2>
    /// <result> = xor <ty> <opl>, <op2>
    Binop,

    // Comparison and Branching
    /// <result> = icmp <cond> <ty> <op1>, <op2> ; @.g., <cond> = eq
    Cmp,
    /// br i1 <cond>, label <iftrue>, label <iffalse>
    Br,
    /// `br label <dest>`
    /// I know I know this isn't the actual name,
    /// but this is what it means and
    /// I dislike Mr. Lattner's design decision
    Jmp,

    // Loads & Stores
    /// `<result> = load <ty>* <pointer>`
    /// newer:
    /// `<result> = load <ty>, <ty>* <pointer>`
    Load,
    /// `store <ty> value, <ty>* <pointer>`
    Store,
    /// `<result> = getelementptr <ty>* <ptrval>, i1 0, i32 <index>`
    /// newer:
    /// `<result> = getelementptr <ty>, <ty>* <ptrval>, i1 0, i32 <index>`
    Gep,

    // Invocation
    /// `<result> = call <ty> <fnptrval>(<args>)`
    /// newer:
    /// `<result> = call <ty> <fnval>(<args>)`
    Call,
    /// `ret void`
    /// `ret <ty> <value>`
    Ret,
    // Allocation
    /// `<result> = alloca <ty>`
    Alloc,

    // Miscellaneous
    /// `<result> = bitcast <ty> <value> to <ty2> ; cast type`
    Bitcast,
    /// `<result> = trunc <ty> <value> to <ty2> ; truncate to ty2`
    Trunc,
    /// `<result> = zext <ty> <value> to <ty2> ; zero-extend to ty2`
    Zext,
    /// `<result> = sext <ty> <value> to <ty2> ; sign-extend to ty2`
    Sext,
    /// `<result> = phi <ty> [<value 0>, <label 0>] [<value 1>, <label 1>]`
    Phi,

    Param,

    /// The condition of a cmp
    /// Placed in `Op` struct for namespacing
    pub const Cond = enum { Eq, NEq, Lt, Gt, GtEq, LtEq };

    /// The binary operation of a Binop
    /// Placed in `Op` struct for namespacing
    pub const Binop = enum { Add, Mul, Div, Sub, And, Or, Xor };
};

/// The type of a value or ref.
/// Purposefully left ambiguous (not i32, i64 etc)
/// for flexibility and because I'm not sure which to use
/// for bools
pub const Type = union(enum) {
    void,
    int,
    bool,
    // sawy dylan
    strct: StructID,
    // only used for malloc, free, printf, read decls and args
    // will always be a pointer to i8
    i8,
    // only used for args to malloc and gep as shown in the
    // examples beard gave us
    // could just use int but I think it being wierd helps
    // make it stand out and that is probably a good thing
    i32,
    int_arr,
    arr: struct {
        type: enum {
            i8,
            // Same as Type.int, just has to be a separate thing
            // for
            // 1. semantics - we only have arrays of i8 (the printf inputs)
            //    and soon int (the user arrays)
            // 2. to avoid having the type be recursively defined
            //    which zig likes to bitch and moan about (understandably)
            int,
        },
        len: u32,
    },
    null_,
    /// The type used instead of optionals
    pub const default = Type.void;

    pub fn eq(self: Type, other: Type) bool {
        return switch (self) {
            .strct => |selfStructID| switch (other) {
                .strct => |otherStructID| selfStructID == otherStructID,
                .null_ => true,
                else => false,
            },
            .null_ => other == .strct or other == .null_,
            .arr => |selfArr| switch (other) {
                .arr => |otherArr| selfArr.type == otherArr.type and selfArr.len == otherArr.len,
                else => false,
            },
            else => @intFromEnum(self) == @intFromEnum(other),
        };
    }

    pub fn debugPrint(self: Type) void {
        switch (self) {
            .void => std.debug.print("Type: void\n", .{}),
            .int => std.debug.print("Type: int\n", .{}),
            .bool => std.debug.print("Type: bool\n", .{}),
            .strct => |structID| std.debug.print("Type: struct, StructID: {}\n", .{structID}),
            .i8 => std.debug.print("Type: i8\n", .{}),
            .i32 => std.debug.print("Type: i32\n", .{}),
            .int_arr => std.debug.print("Type: int_arr\n", .{}),
            .arr => |arrType| std.debug.print("Type: arr, Element Type: {}, Length: {}\n", .{ arrType.type, arrType.len }),
            .null_ => std.debug.print("Type: null\n", .{}),
        }
    }

    /// WARN: returns sizeof(void*) for structs
    /// not the actual size of the struct
    pub fn sizeof(self: Type) u32 {
        return switch (self) {
            .strct, .int, .null_ => 8,
            // int_arr is just a pointer to a dynamically allocated
            // array so it is just the size of a pointer
            .int_arr => 8,
            .i8, .bool => 1,
            .void => 0,
            .i32 => 4,
            // FIXME: NEEDS TO BE POINTER SIZED IN STRUCTS
            .arr => |arr| arr.len * (switch (arr.type) {
                // don't ask
                .i8 => @as(u32, 1),
                .int => @as(u32, 8),
            }),
        };
    }

    pub fn aligned_sizeof(alignment: u32, ty: Type) u32 {
        const size: u32 = Type.sizeof(ty);
        utils.assert((alignment & 1 == 0), "alignment must be even (power of 2 as optimally???)\n", .{});
        utils.assert(alignment != 0, "alignment must not be zero\n", .{});
        if (size < alignment) {
            return alignment;
        }
        // return size + (size >> (alignment >> 1));
        // WARN: HORROR AHEAD RESULTING FROM TRYING TO BE CLEVER

        // ERR: src/ir/ir.zig:884:43: error: expected type 'u5', found 'u32'
        // ERR: return size + (size >> (alignment >> 1));
        //                         ~~~~~~~~~~^~~~
        // ERR: src/ir/ir.zig:884:43: note: unsigned 5-bit int cannot represent all possible unsigned 32-bit values
        return size + @mod(size, alignment);
    }

    pub fn orelseIfNull(self: Type, dfault: Type) Type {
        switch (self) {
            .null_ => switch (dfault) {
                .null_ => return .i8,
                else => return dfault,
            },
            else => return self,
        }
    }
    test "alignof-bool" {
        try std.testing.expectEqual(@as(u32, 4), Type.aligned_sizeof(4, .bool));
    }
};

/// Ref to a register
pub const Ref = struct {
    /// ID
    i: Register.ID,
    name: StrID,
    kind: Kind,
    type: Type,
    // used for when a thing is assigned an immediate and then assigned something else
    extraImm: Kind = ._invalid,
    /// Ref used when no ref needed
    /// FIXME: add deadbeef here too
    pub const default = Ref.local(69420, InternPool.NULL, .void);

    pub fn debugPrintWithName(self: Ref, ir: *IR) void {
        std.debug.print("Ref: {any}, Kind: ", .{self.i});
        self.kind.debugPrint();
        std.debug.print(", Type: ", .{});
        self.type.debugPrint();
        std.debug.print("\n", .{});
        if (self.name != InternPool.NULL) {
            const name = ir.getIdent(self.name);
            std.debug.print("Name: {s}\n", .{name});
        } else {
            std.debug.print("Name: NULL\n", .{});
        }
        // id
        if (self.i != 69420) {
            std.debug.print("ID: {any}\n", .{self.i});
        } else {
            std.debug.print("ID: 69420\n", .{});
        }
    }
    pub fn debugPrint(self: Ref) void {
        std.debug.print("Ref: {any}, Kind: ", .{self.i});
        self.kind.debugPrint();
        std.debug.print(", Type: ", .{});
        self.type.debugPrint();
        std.debug.print("\n", .{});
        // name
        if (self.name != InternPool.NULL) {
            std.debug.print("Name: {any}\n", .{self.name});
        } else {
            std.debug.print("Name: NULL\n", .{});
        }
        // id
        if (self.i != 69420) {
            std.debug.print("ID: {any}\n", .{self.i});
        } else {
            std.debug.print("ID: 69420\n", .{});
        }
    }

    pub const Kind = enum {
        local,
        global,
        label,
        immediate,
        // a special variant of immediate for when we know the integer
        // the immediate is (such as struct size)
        // and we put the u32 value in the i field instead of
        // interning it
        // this makes things simpler trust me bro
        immediate_u32,
        param,
        _invalid,
        pub fn debugPrint(self: Kind) void {
            switch (self) {
                .local => std.debug.print("local", .{}),
                .global => std.debug.print("global", .{}),
                .label => std.debug.print("label", .{}),
                .immediate => std.debug.print("immediate", .{}),
                .immediate_u32 => std.debug.print("immediate_u32", .{}),
                .param => std.debug.print("param", .{}),
                ._invalid => std.debug.print("_invalid", .{}),
            }
        }
    };

    pub inline fn fromRegLocal(reg: Register) Ref {
        return Ref{ .i = reg.id, .kind = .local, .name = reg.name, .type = reg.type };
    }

    pub inline fn fromReg(reg: Register, fun: *Function, ir: *IR) Ref {
        if (fun.paramRegs.contains(reg.name)) {
            return Ref{ .i = reg.id, .kind = .param, .name = reg.name, .type = reg.type };
        }
        if (ir.globals.contains(reg.name)) {
            return Ref{ .i = reg.id, .kind = .global, .name = reg.name, .type = reg.type };
        }
        return Ref{ .i = reg.id, .kind = .local, .name = reg.name, .type = reg.type };
    }

    /// Helper function to create a ref to eine local
    pub inline fn local(i: u32, maybeName: ?StrID, ty: Type) Ref {
        const name = maybeName orelse InternPool.NULL;
        return Ref{ .i = i, .kind = .local, .name = name, .type = ty };
    }

    /// Helper function to create a ref to eine global
    pub inline fn global(i: u32, name: StrID, ty: Type) Ref {
        return Ref{ .i = i, .kind = .global, .name = name, .type = ty };
    }

    /// Helper function to create a ref to eine label
    pub inline fn label(i: u32) Ref {
        return Ref{ .i = i, .kind = .label, .name = InternPool.NULL, .type = .void };
    }

    pub inline fn immediate(id: StrID, ty: Type) Ref {
        // storing the internPoolID in the id field
        // because otherwise propogating names throughout new
        // ir refs results in local registers having immediates as their name
        return Ref{ .i = id, .kind = .immediate, .name = InternPool.NULL, .type = ty };
    }

    pub inline fn immu32(val: u32, ty: Type) Ref {
        return Ref{ .i = val, .kind = .immediate_u32, .name = InternPool.NULL, .type = ty };
    }

    pub inline fn param(id: Register.ID, name: StrID, ty: Type, remove_me: u32) Ref {
        _ = remove_me;
        return Ref{ .i = id, .kind = .param, .name = name, .type = ty };
    }

    pub inline fn immFalse() Ref {
        return Ref.immediate(InternPool.FALSE, .bool);
    }

    pub inline fn immTrue() Ref {
        return Ref.immediate(InternPool.TRUE, .bool);
    }

    pub inline fn immZero() Ref {
        return Ref.immediate(InternPool.ZERO, .int);
    }

    pub inline fn immOne() Ref {
        return Ref.immediate(InternPool.ONE, .int);
    }

    pub inline fn malloc(ir: *IR) Ref {
        // TODO: move somewhere else? make constant in InternPool?
        const name = ir.internIdent("malloc");
        // FIXME: make this make more sense somehow
        return Ref{ .kind = .global, .i = 0xba110c, .type = .i8, .name = name };
    }

    pub inline fn free(ir: *IR) Ref {
        // TODO: move somewhere else? make constant in InternPool?
        const name = ir.internIdent("free");
        // FIXME: make this make more sense somehow
        return Ref{ .kind = .global, .i = 0xf433, .type = .void, .name = name };
    }

    pub inline fn printf(ir: *IR) Ref {
        const name = ir.internIdent("printf");
        return Ref{ .kind = .global, .i = 0xbf1A4f, .type = .i32, .name = name };
    }

    pub inline fn print_fmt(ir: *IR) Ref {
        const name = ir.internIdent(".print");
        const ty = Type{ .arr = .{
            .type = .i8,
            .len = 5,
        } };
        return Ref{ .kind = .global, .i = 0xfa420, .type = ty, .name = name };
    }

    pub inline fn print_ln_fmt(ir: *IR) Ref {
        const name = ir.internIdent(".println");
        const ty = Type{ .arr = .{
            .type = .i8,
            .len = 5,
        } };
        return Ref{ .kind = .global, .i = 0xfa421, .type = ty, .name = name };
    }

    pub inline fn scanf(ir: *IR) Ref {
        const name = ir.internIdent("scanf");
        const ty = .i32;
        return Ref{ .kind = .global, .i = 0xdeadbeef, .type = ty, .name = name };
    }

    pub inline fn read_fmt(ir: *IR) Ref {
        const name = ir.internIdent(".read");
        const ty = Type{ .arr = .{
            .type = .i8,
            .len = 4,
        } };
        return Ref{ .kind = .global, .i = 0xdeadbeef, .type = ty, .name = name };
    }

    /// The scratch variable to store the `%ld` scanned in using
    /// scanf before it is stored somewhere else
    pub inline fn read_scratch(ir: *IR) Ref {
        const name = ir.internIdent(".read_scratch");
        const ty = .i32;
        return Ref{ .kind = .global, .i = 0xdeadbeef, .type = ty, .name = name };
    }

    /// @param ty: the type of the null pointer
    pub inline fn immnull() Ref {
        return Ref.immediate(InternPool.NULL, .null_);
    }

    pub fn eq(self: Ref, other: Ref) bool {
        return self.kind == other.kind and self.i == other.i and self.name == other.name and self.type.eq(other.type);
    }
};

/// A reference to another basic block
pub const Label = u32;

/// TODO: this needs to hold a register ID, which, is then used as a list inside
/// of the Inst type.
pub const PhiEntry = struct { bb: Label, ref: Ref };

pub const Inst = struct {
    op: Op,
    /// The resulting register
    res: Ref = Ref.default,
    ty1: Type = Type.default,
    ty2: Type = Type.default,
    op1: Ref = Ref.default,
    op2: Ref = Ref.default,
    /// Extra field for unique things
    extra: Extra = Extra.none(),
    comp: bool = false,

    /// Extra field for unique (possibly rarely accessed) things
    pub const Extra = union {
        /// The default
        none_: void,
        /// Used in phi node to store their entries
        phi: std.ArrayList(PhiEntry),
        /// used in cmp to store the condition
        cond: Op.Cond,
        /// used in binop to store the operation
        op: Op.Binop,
        /// Used in br as `op3`
        on: Ref,
        /// Function call arguments
        args: []Ref,

        /// Helper to use `none_` more elegantly
        pub fn none() Extra {
            return .{ .none_ = undefined };
        }
    };

    pub fn phiAddEntry(self: *Inst, bb: Label, ref: Ref) !void {
        const entry = PhiEntry{ .bb = bb, .ref = ref };
        try self.extra.phi.append(entry);
    }

    pub fn isCtrlFlow(self: *const Inst) bool {
        return switch (self.op) {
            .Jmp, .Br, .Ret => true,
            else => false,
        };
    }

    pub const Param = struct {
        type: Type,
        register: Ref,

        pub fn get(inst: Inst) Param {
            return .{
                .type = inst.ty1,
                .register = inst.res,
            };
        }

        pub fn toInst(inst: Param) Inst {
            return .{ .op = .Param, .ty1 = inst.type, .res = inst.register };
        }
    };

    /// Arithmetic struct
    pub const Binop = struct {
        op: Op.Binop,
        returnType: Type,
        register: Ref,
        lhs: Ref,
        rhs: Ref,

        pub fn get(inst: Inst) Binop {
            return .{
                .op = inst.extra.op,
                .register = inst.res,
                .returnType = inst.ty1,
                .lhs = inst.op1,
                .rhs = inst.op2,
            };
        }

        pub fn toInst(inst: Binop) Inst {
            return Inst{
                .op = .Binop,
                .res = inst.register,
                .ty1 = inst.returnType,
                .op1 = inst.lhs,
                .op2 = inst.rhs,
                .extra = .{ .op = inst.op },
            };
        }
    };

    // WARN: ALL OF THESE HELPERS EXPECT TO BE CREATED WITH THE HELPERS IN
    // `Function` SO THE RES FIELD IS SET PROPERLY
    pub inline fn param(res: Ref, ty: Type) Inst {
        return .{ .op = .Param, .res = res, .ty1 = ty };
    }

    /// `<result> = add <ty> <op1>, <op2>`
    pub inline fn add(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .int, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Add } };
    }
    /// `<result> = mul <ty> <op1>, <op2>`
    pub inline fn mul(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .int, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Mul } };
    }
    /// `<result> = sdiv <ty> <op1>, <op2>`
    pub inline fn div(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .int, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Div } };
    }
    /// `<result> = sub <ty> <op1>, <op2>`
    pub inline fn sub(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .int, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Sub } };
    }
    pub inline fn neg(val: Ref) Inst {
        return Inst.sub(Ref.immZero(), val);
    }
    // Boolean
    /// `<result> = and <ty> <op1>, <op2>`
    pub inline fn and_(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .And } };
    }
    /// `<result> = or <ty> <opi>, <op2>`
    pub inline fn or_(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Or } };
    }
    /// `<result> = xor <ty> <opl>, <op2>`
    pub inline fn xor(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Xor } };
    }
    pub inline fn not(val: Ref) Inst {
        return Inst.xor(val, Ref.immOne());
    }

    pub const Cmp = struct {
        res: Ref,
        cond: Op.Cond,
        opTypes: Type,
        lhs: Ref,
        rhs: Ref,
        pub inline fn get(inst: Inst) Cmp {
            return .{
                .res = inst.res,
                .cond = inst.extra.cond,
                .opTypes = inst.ty1,
                .lhs = inst.op1,
                .rhs = inst.op2,
            };
        }

        pub inline fn toInst(inst: Cmp) Inst {
            return Inst.cmp(inst.cond, inst.lhs, inst.rhs);
        }
    };
    // Comparison and Branching
    /// <recmp> = icmp <cond> <ty> <op1>, <op2> ; @.g., <cond> = eq
    pub inline fn cmp(cond: Op.Cond, lhs: Ref, rhs: Ref) Inst {
        utils.assert(lhs.type.eq(rhs.type), "comparison operands must have the same type\n {s} != {s}", .{ @tagName(lhs.type), @tagName(rhs.type) });
        return .{ .op = .Cmp, .ty1 = lhs.type.orelseIfNull(rhs.type), .op1 = lhs, .op2 = rhs, .extra = .{ .cond = cond } };
    }

    pub const Br = struct {
        on: Ref,
        iftrue: BasicBlock.ID,
        iffalse: BasicBlock.ID,
        pub inline fn get(inst: Inst) Br {
            return .{
                .on = inst.extra.on,
                .iftrue = inst.op1.i,
                .iffalse = inst.op2.i,
            };
        }

        pub inline fn toInst(inst: Br) Inst {
            return Inst.br(inst.on, Ref.label(inst.iftrue), Ref.label(inst.iffalse));
        }

        pub fn eq(self: Br, other: Br) bool {
            return self.on.eq(other.on) and self.iftrue == other.iftrue and self.iffalse == other.iffalse;
        }
    };
    /// br i1 <cond>, label <iftrue>, label <iffalse>
    pub inline fn br(cond: Ref, iftrue: Ref, iffalse: Ref) Inst {
        return .{ .op = .Br, .extra = .{ .on = cond }, .op1 = iftrue, .op2 = iffalse };
    }

    pub const Jmp = struct {
        dest: BasicBlock.ID,
        pub inline fn get(inst: Inst) Jmp {
            return .{ .dest = inst.op1.i };
        }
        pub inline fn toInst(inst: Jmp) Inst {
            return Inst.jmp(Ref.label(inst.dest));
        }

        pub fn eq(self: Jmp, other: Jmp) bool {
            return self.dest == other.dest;
        }
    };
    /// `br label <dest>`
    /// I know I know this isn't the actual name,
    /// but this is what it means and
    /// I dislike Mr. Lattner's design decision
    pub inline fn jmp(dest: Ref) Inst {
        return .{ .op = .Jmp, .op1 = dest };
    }

    pub const Load = struct {
        res: Ref,
        ty: Type,
        ptr: Ref,
        pub inline fn get(inst: Inst) Load {
            return .{
                .res = inst.res,
                .ty = inst.ty1,
                .ptr = inst.op1,
            };
        }
        pub inline fn toInst(inst: Load) Inst {
            return Inst{
                .op = .Load,
                .res = inst.res,
                .ty1 = inst.ty,
                .op1 = inst.ptr,
            };
        }
    };
    // Loads & Stores
    /// `<result> = load <ty>* <pointer>`
    /// newer:
    /// `<result> = load <ty>, <ty>* <pointer>`
    pub inline fn load(ty: Type, ptr: Ref) Inst {
        return .{
            .op = .Load,
            .ty1 = ty,
            .op1 = ptr,
        };
    }

    pub const Store = struct {
        ty: Type,
        to: Ref,
        fromType: Type,
        from: Ref,
        pub inline fn get(inst: Inst) Store {
            return .{
                .ty = inst.ty1,
                .to = inst.op1,
                .fromType = inst.ty2,
                .from = inst.op2,
            };
        }

        pub inline fn toInst(inst: Store) Inst {
            return Inst{
                .op = .Store,
                .ty1 = inst.ty,
                .op1 = inst.to,
                .ty2 = inst.fromType,
                .op2 = inst.from,
            };
        }
    };
    /// `store {from.type} {from}, {to.type}* {to}`
    // TODO: remove type params and take them from ref
    pub inline fn store(to: Ref, from: Ref) Inst {
        return .{
            .op = .Store,
            .ty1 = to.type,
            .op1 = to,
            .ty2 = from.type.orelseIfNull(to.type),
            .op2 = from,
        };
    }

    pub const Gep = struct {
        res: Ref,
        baseTy: Type,
        ptrTy: Type,
        ptrVal: Ref,
        index: Ref,
        pub inline fn get(inst: Inst) Gep {
            return .{
                .res = inst.res,
                .baseTy = inst.ty1,
                .ptrTy = inst.ty2,
                .ptrVal = inst.op1,
                .index = inst.op2,
            };
        }

        pub inline fn toInst(inst: Gep) Inst {
            return Inst{
                .op = .Gep,
                .res = inst.res,
                .ty1 = inst.baseTy,
                .ty2 = inst.ptrTy,
                .op1 = inst.ptrVal,
                .op2 = inst.index,
            };
        }
    };
    /// `<result> = getelementptr <ty>* <ptrval>, i1 0, i32 <index>`
    /// newer:
    /// `<result> = getelementptr <ty>, <ty>* <ptrval>, i1 0, i32 <index>`
    pub inline fn gep(basisTy: Type, ptrVal: Ref, index: Ref) Inst {
        return .{ .op = .Gep, .ty1 = basisTy, .ty2 = basisTy, .op1 = ptrVal, .op2 = index };
    }

    /// a wrapper around gep with index 0
    pub inline fn gep_deref(ptrVal: Ref) Inst {
        return Inst.gep(ptrVal.type, ptrVal, Ref.immu32(0, .i32));
    }

    pub const Call = struct {
        res: Ref,
        retTy: Type,
        fun: Ref,
        args: []Ref,
        pub inline fn get(inst: Inst) Call {
            return .{
                .res = inst.res,
                .retTy = inst.ty1,
                .fun = inst.op1,
                .args = inst.extra.args,
            };
        }
        pub inline fn toInst(inst: Call) Inst {
            return Inst.call(inst.res, inst.retTy, inst.fun, inst.args);
        }
    };
    // Invocation
    /// `<result> = call <ty> <inline fnptrval>(<args>)`
    /// newer:
    /// `<result> = call <ty> <inline fnval>(<args>)`
    pub fn call(retTy: Type, fun: Ref, args: []Ref) Inst {
        return .{ .op = .Call, .ty1 = retTy, .op1 = fun, .extra = .{ .args = args } };
    }

    pub const Ret = struct {
        ty: Type,
        val: Ref,
        pub inline fn get(inst: Inst) Ret {
            return .{
                .ty = inst.ty1,
                .val = inst.op1,
            };
        }
        pub inline fn toInst(inst: Ret) Inst {
            return Inst.ret(inst.ty, inst.val);
        }

        pub fn eq(self: Ret, other: Ret) bool {
            return self.ty.eq(other.ty) and self.val.eq(other.val);
        }
    };
    /// `ret void`
    pub inline fn retVoid() Inst {
        return .{ .op = .Ret, .ty1 = .void };
    }
    /// `ret <ty> <value>`
    pub inline fn ret(ty: Type, val: Ref) Inst {
        return .{ .op = .Ret, .op1 = val, .ty1 = ty };
    }

    pub const Alloc = struct {
        res: Ref,
        ty: Type,
        pub inline fn get(inst: Inst) Alloc {
            return .{
                .res = inst.res,
                .ty = inst.ty1,
            };
        }
        pub inline fn toInst(inst: Alloc) Inst {
            return Inst.alloc(inst.res, inst.ty);
        }
    };
    // Allocation
    /// `<result> = alloca <ty>`
    // Alloc,
    pub inline fn alloca(ty: Type) Inst {
        return .{ .op = .Alloc, .ty1 = ty };
    }

    pub const Misc = struct {
        // combined into one because they are so rarely used comparitively
        kind: Kind,
        res: Ref,
        fromType: Type,
        from: Ref,
        toType: Type,

        pub const Kind = enum { bitcast, trunc, zext, sext };

        pub inline fn get(inst: Inst) Misc {
            return .{
                .kind = switch (inst.op) {
                    .Bitcast => .bitcast,
                    .Trunc => .trunc,
                    .Zext => .zext,
                    .Sext => .sext,
                    else => unreachable,
                },
                .res = inst.res,
                .fromType = inst.ty1,
                .from = inst.op1,
                .toType = inst.ty2,
            };
        }
        pub inline fn toInst(inst: Misc) Inst {
            return Inst{
                .op = switch (inst.kind) {
                    .bitcast => .Bitcast,
                    .trunc => .Trunc,
                    .zext => .Zext,
                    .sext => .Sext,
                },
                .res = inst.res,
                .ty1 = inst.fromType,
                .ty2 = inst.toType,
                .op1 = inst.from,
            };
        }
    };
    // Miscellaneous
    /// `<result> = bitcast <ty> <value> to <ty2> ; cast type`
    pub inline fn bitcast(from: Ref, toType: Type) Inst {
        return .{ .op = .Bitcast, .ty1 = from.type, .op1 = from, .ty2 = toType };
    }
    /// `<result> = trunc <ty> <value> to <ty2> ; truncate to ty2`
    pub inline fn trunc(from: Ref, to: Type) Inst {
        return .{ .op = .Trunc, .ty1 = from.type, .op1 = from, .ty2 = to };
    }
    /// `<result> = zext <ty> <value> to <ty2> ; zero-extend to ty2`
    pub inline fn zext(from: Ref, to: Type) Inst {
        return .{ .op = .Zext, .ty1 = from.type, .op1 = from, .ty2 = to };
    }

    /// `<result> = sext <ty> <value> to <ty2> ; sign-extend to ty2`
    pub inline fn sext(from: Ref, to: Type) Inst {
        return .{ .op = .Sext, .ty1 = from.type, .op1 = from, .ty2 = to };
    }

    pub const Phi = struct {
        res: Ref,
        type: Type,
        entries: std.ArrayList(PhiEntry),
        pub inline fn get(inst: Inst) Phi {
            return .{
                .res = inst.res,
                .entries = inst.extra.phi,
                .type = inst.ty1,
            };
        }
        pub inline fn toInst(inst: Phi) Inst {
            return Inst{
                .op = .Phi,
                .res = inst.res,
                .ty1 = inst.type,
                .extra = .{ .phi = inst.entries },
            };
        }
    };
    /// `<result> = phi <ty> [<value 0>, <label 0>] [<value 1>, <label 1>]`
    pub inline fn phi(res: Ref, ty: Type, entries: std.ArrayList(PhiEntry)) Inst {
        return .{ .op = .Phi, .res = res, .ty1 = ty, .extra = .{ .phi = entries } };
    }

    // NOTE: comment out this function to get ugly but complete printing again
    pub fn format(self: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        switch (self.op) {
            .Binop => {
                const _binop = Inst.Binop.get(self);
                return writer.print("{any}\n", .{_binop});
            },
            .Cmp => {
                const _cmp = Inst.Cmp.get(self);
                return writer.print("{any}\n", .{_cmp});
            },
            .Br => {
                const _br = Inst.Br.get(self);
                return writer.print("{any}\n", .{_br});
            },
            .Jmp => {
                const _jmp = Inst.Jmp.get(self);
                return writer.print("{any}\n", .{_jmp});
            },
            .Load => {
                const _load = Inst.Load.get(self);
                return writer.print("{any}\n", .{_load});
            },
            .Store => {
                const _store = Inst.Store.get(self);
                return writer.print("{any}\n", .{_store});
            },
            .Gep => {
                const _gep = Inst.Gep.get(self);
                return writer.print("{any}\n", .{_gep});
            },
            .Call => {
                const _call = Inst.Call.get(self);
                return writer.print("{any}\n", .{_call});
            },
            .Ret => {
                const _ret = Inst.Ret.get(self);
                return writer.print("{any}\n", .{_ret});
            },
            .Alloc => {
                const _alloc = Inst.Alloc.get(self);
                return writer.print("{any}\n", .{_alloc});
            },
            .Bitcast, .Trunc, .Zext, .Sext => {
                var _misc = Inst.Misc.get(self);
                return writer.print("{any}\n", .{_misc});
            },
            .Phi => {
                const _phi = Inst.Phi.get(self);
                return writer.print("{any}\n", .{_phi});
            },
            .Param => {
                const _param = Inst.Param.get(self);
                return writer.print("{any}\n", .{_param});
            },
        }
    }
};
