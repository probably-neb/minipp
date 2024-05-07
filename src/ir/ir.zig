// STACK GEN

pub const std = @import("std");

const Ast = @import("../ast.zig");
const utils = @import("../utils.zig");
const log = @import("../log.zig");

pub const InternPool = @import("../intern-pool.zig");
/// The ID of a string stored in the intern pool
/// Henceforth, all operations involving variable or struct names
/// shall utilize the power of this type, rather than `std.mem.eql(u8, a, b);`
const StrID = InternPool.StrID;

pub const IR = @This();

types: TypeList,
globals: GlobalsList,
funcs: FunctionList,
intern_pool: InternPool,
// TODO: consider using an arena for everything
// (except intern pool most likely it will live on)
// I already tried but I was getting segfaults
// so... idk
alloc: std.mem.Allocator,

pub fn init(alloc: std.mem.Allocator) IR {
    return .{
        .types = TypeList.init(),
        .globals = GlobalsList.init(),
        .funcs = FunctionList.init(),
        .intern_pool = InternPool.init(alloc) catch unreachable,
        .alloc = alloc,
    };
}

/// Stringify the IR
/// NOTE: highly recommended to pass a std.heap.ArenaAllocator.allocator
pub fn stringify(self: *const IR, alloc: std.mem.Allocator) ![]const u8 {
    const stringifyInner = @import("./stringify.zig");
    return stringifyInner.stringify(self, alloc);
}

pub fn internIdent(self: *IR, ident: []const u8) StrID {
    return self.intern_pool.intern(ident) catch |err| {
        // The only way this can fail is if the intern pool is out of memory
        // I'm not typing try all over the place just so it bubbles up further
        // Im sawy mistew kewwey
        std.debug.panic("Failed to intern ident: {any}\n", .{err});
    };
}

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
        .Struct => |name| blk: {
            const structID = self.internIdent(name);
            break :blk .{ .strct = structID };
        },
    };
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
};

pub const Function = struct {
    alloc: std.mem.Allocator,
    name: StrID,
    returnType: Type,
    bbs: OrderedList(BasicBlock),
    regs: LookupTable(Register.ID, Register, Register.getID),
    insts: OrderedList(Inst),
    returnReg: ?Register.ID = null,
    params: ParamsList,

    // index into the insts array
    pub const InstID = u32;

    pub const entryBBID = 0;
    pub const exitBBID = 1;

    pub const Param = struct {
        name: StrID,
        type: Type,

        pub const ID = u32;
        pub fn getKey(self: @This()) StrID {
            return self.name;
        }
    };

    pub const ParamsList = StaticSizeLookupTable(Param.ID, Param, Param.getKey);

    pub fn init(alloc: std.mem.Allocator, name: StrID, returnType: Type, params: []Param) Function {
        return .{
            .alloc = alloc,
            .bbs = OrderedList(BasicBlock).init(alloc),
            .name = name,
            .returnType = returnType,
            .regs = LookupTable(Register.ID, Register, Register.getID).init(alloc),
            .params = ParamsList.init(params),
            .insts = OrderedList(Inst).init(alloc),
        };
    }

    pub fn getKey(self: Function) StrID {
        return self.name;
    }

    pub fn newBB(self: *Function) !BasicBlock.ID {
        const bb = BasicBlock.init(self.alloc);
        const id = try self.bbs.add(bb);
        return id;
    }

    pub fn newBBWithParent(self: *Function, parent: BasicBlock.ID) !BasicBlock.ID {
        var bb = BasicBlock.init(self.alloc);
        try bb.addIncomer(parent);
        const id = try self.bbs.add(bb);
        try self.bbs.get(parent).addOutgoer(id);
        return id;
    }

    pub fn addNamedInst(self: *Function, bb: BasicBlock.ID, basicInst: Inst, name: StrID, ty: Type) !Register {
        // reserve
        const regID = try self.regs.add(undefined);
        const instID = try self.insts.add(undefined);

        // construct
        const reg = Register{ .id = regID, .inst = instID, .name = name, .bb = bb, .type = ty };
        var inst = basicInst;
        inst.res = Ref.local(regID, name, ty);

        // save
        self.regs.set(regID, reg);
        self.insts.set(instID, inst);
        try self.bbs.get(bb).insts.append(instID);
        return reg;
    }

    pub fn addInst(self: *Function, bb: BasicBlock.ID, inst: Inst, ty: Type) !Register {
        return self.addNamedInst(bb, inst, InternPool.NULL, ty);
    }

    // a helper for the stack ir gen because this is a very common pattern
    pub fn addLoadAndStoreTo(self: *Function, bb: BasicBlock.ID, from: Register, to: Register.ID) !void {
        const load = Inst.load(from.type, Ref.local(from.id, from.name, from.type));
        const loadReg = try self.addInst(bb, load, from.type);
        const store = Inst.store(loadReg.type, Ref.local(to, loadReg.name, loadReg.type), loadReg.type, Ref.local(loadReg.id, loadReg.name, loadReg.type));
        try self.addAnonInst(bb, store);
    }

    pub fn addCtrlFlowInst(self: *Function, bb: BasicBlock.ID, inst: Inst) !void {
        utils.assert(inst.isCtrlFlow(), "tried to add non control flow instruction:\n{any}\n", .{inst});
        const maybeLastBBInstID = self.bbs.get(bb).getLastInstID();
        if (maybeLastBBInstID) |lastBBInstID| {
            const lastInst = self.insts.get(lastBBInstID).*;
            if (lastInst.isCtrlFlow()) {
                if (ctrlFlowInstsEqual(lastInst, inst)) {
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

    pub const NotFoundError = error{IdentifierNotFound};

    pub fn getNamedRef(self: *Function, ir: *const IR, name: StrID) NotFoundError!Ref {
        if (self.getNamedAllocaReg(name)) |reg| {
            return Ref.fromReg(reg);
        } else |_| {}

        if (self.params.safeLookup(name)) |paramID| {
            const param = self.params.entry(paramID);
            return Ref.param(paramID, param.name, param.type);
        }

        const globalID = ir.globals.items.lookup(name);
        const global = ir.globals.items.entry(globalID);
        return Ref.global(globalID, global.name, global.type);
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
        return error.IdentifierNotFound;
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

        pub fn next(self: *InstIter) ?Inst {
            if (self.bb >= self.func.bbs.len) {
                return null;
            }
            var bb = self.func.bbs.get(self.bb);
            if (self.instIndex >= bb.insts.len) {
                if (self.bb == Function.exitBBID) {
                    return null;
                }
                if (self.bb >= self.func.bbs.len - 1) {
                    self.bb = Function.exitBBID;
                } else {
                    self.bb += 1;
                    if (self.bb == Function.exitBBID) {
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
            return self.func.insts.get(instID).*;
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

pub const BasicBlock = struct {
    incomers: std.ArrayList(Label),
    outgoers: [2]?Label,
    // and ORDERED list of the instruction ids of the instructions in this block
    insts: List,

    /// The ID of a basic block is it's index within the arraylist of
    /// basic blocks in the `Function` type
    /// This is done differently than the LUT based approach for almost
    /// everthing else in the IR because the order of the basic blocks
    pub const ID = u32;

    pub const List = OrderedList(Function.InstID);

    pub fn init(alloc: std.mem.Allocator) BasicBlock {
        return .{
            .incomers = std.ArrayList(Label).init(alloc),
            .outgoers = [2]?Label{ null, null },
            .insts = List.init(alloc),
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

        pub const ID = u32;

        pub fn init(items: []Value) Self {
            return .{ .items = items, .len = @intCast(items.len) };
        }

        pub fn lookup(self: Self, key: Key) ID {
            const maybe_id = self.safeLookup(key);
            if (maybe_id) |id| {
                return id;
            }
            @panic("Item not found in lookup table");
        }

        pub fn safeLookup(self: Self, key: Key) ?ID {
            for (self.items, 0..) |existing, i| {
                const itemKey = getKey(existing);
                if (itemKey == key) {
                    return @intCast(i);
                }
            }
            return null;
        }

        pub fn entry(self: Self, key: ID) Value {
            return self.items[key];
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
        pub const Self = @This();

        pub fn init(alloc: std.mem.Allocator) Self {
            return .{ .list = std.ArrayList(T).init(alloc), .len = 0 };
        }

        /// A helper for iterating instead of `field.list.items`
        pub inline fn items(self: Self) []T {
            return self.list.items;
        }

        // TODO: consider refactoring to return just `T`
        // and create another `getPtr` for when you need a pointer
        // the `.*` everywhere is kinda annoying ngl
        pub inline fn get(self: Self, idx: u32) *T {
            return &self.list.items[idx];
        }

        /// Appends an item and returns the index
        pub fn add(self: *Self, item: T) !u32 {
            const id = self.len;
            try self.list.append(item);
            self.len += 1;
            return id;
        }

        pub inline fn set(self: *Self, idx: u32, item: T) void {
            self.list.items[idx] = item;
        }

        /// same as add, but does not return the index
        /// for when you just don't care yk?
        pub fn append(self: *Self, item: T) !void {
            try self.list.append(item);
            self.len += 1;
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
        ty: Type,

        pub fn init(name: StrID, ty: Type) Field {
            return .{ .name = name, .ty = ty };
        }

        pub fn getKey(self: Field) StrID {
            return self.name;
        }
    };

    pub const FieldID = u32;

    pub fn init(name: StrID, fields: []Field) StructType {
        const fieldLookup = FieldList.init(fields);
        return .{ .name = name, .fieldLookup = fieldLookup, .size = 0 };
    }

    pub fn getFieldWithName(self: StructType, name: StrID) Field {
        const idx = self.fieldLookup.lookup(name);
        return self.fieldLookup.get(idx);
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

    pub fn get(self: *const TypeList, id: StructID) Item {
        const idx = self.items.lookup(id);
        return self.items.entry(idx);
    }

    /// WARN: I think I saw somewhere that the AutoArrayHashMap preserves
    /// insertion order but I'm not sure
    pub fn index(self: *const TypeList, idx: usize) Item {
        return self.items.items[idx];
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
    /// `<result> = phi <ty> [<value 0>, <label 0>] [<value 1>, <label 1>]`
    Phi,

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
    /// The type used instead of optionals
    pub const default = Type.void;

    pub fn eq(self: Type, other: Type) bool {
        return switch (self) {
            .strct => |selfStructID| switch (other) {
                .strct => |otherStructID| selfStructID == otherStructID,
                else => false,
            },
            .arr => |selfArr| switch (other) {
                .arr => |otherArr| selfArr.type == otherArr.type and selfArr.len == otherArr.len,
                else => false,
            },
            else => @intFromEnum(self) == @intFromEnum(other),
        };
    }
};

/// Ref to a register
pub const Ref = struct {
    /// ID
    i: Register.ID,
    name: StrID,
    kind: Kind,
    type: Type,
    /// Ref used when no ref needed
    pub const default = Ref.local(69420, InternPool.NULL, .void);

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
    };

    pub inline fn fromReg(reg: Register) Ref {
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

    pub inline fn param(id: Function.Param.ID, name: StrID, ty: Type) Ref {
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
        return Ref{ .kind = .global, .i = 0xbf1A4f, .type = .i8, .name = name };
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

    pub fn eq(self: Ref, other: Ref) bool {
        return self.kind == other.kind and self.i == other.i and self.name == other.name and self.type.eq(other.type);
    }
};

/// A reference to another basic block
pub const Label = u32;

pub const PhiEntry = struct { label: Label };

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

    pub fn isCtrlFlow(self: *const Inst) bool {
        return switch (self.op) {
            .Jmp, .Br, .Ret => true,
            else => false,
        };
    }

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
            // NOTE: written by copilot - must be double checked
            switch (inst.op) {
                .Add => return Inst.add(inst.register, inst.lhs, inst.rhs),
                .Mul => return Inst.mul(inst.register, inst.lhs, inst.rhs),
                .Div => return Inst.div(inst.register, inst.lhs, inst.rhs),
                .Sub => return Inst.sub(inst.register, inst.lhs, inst.rhs),
                .And => return Inst.and_(inst.register, inst.lhs, inst.rhs),
                .Or => return Inst.or_(inst.register, inst.lhs, inst.rhs),
                .Xor => return Inst.xor(inst.register, inst.lhs, inst.rhs),
            }
        }
    };

    // WARN: ALL OF THESE HELPERS EXPECT TO BE CREATED WITH THE HELPERS IN
    // `Function` SO THE RES FIELD IS SET PROPERLY

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
            return Inst.cmp(inst.res, inst.cond, inst.lhs, inst.rhs);
        }
    };
    // Comparison and Branching
    /// <recmp> = icmp <cond> <ty> <op1>, <op2> ; @.g., <cond> = eq
    pub inline fn cmp(cond: Op.Cond, lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Cmp, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .cond = cond } };
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
            return Inst.load(inst.res, inst.ty, inst.ptr);
        }
    };
    // Loads & Stores
    /// `<result> = load <ty>* <pointer>`
    /// newer:
    /// `<result> = load <ty>, <ty>* <pointer>`
    pub inline fn load(ty: Type, ptr: Ref) Inst {
        return .{ .op = .Load, .ty1 = ty, .op1 = ptr };
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
            return Inst.store(inst.ty, inst.to, inst.fromType, inst.from);
        }
    };
    /// `store <ty> value, <ty>* <pointer>`
    // TODO: remove type params and take them from ref
    pub inline fn store(ty: Type, to: Ref, fromType: Type, from: Ref) Inst {
        return .{ .op = .Store, .ty1 = ty, .op1 = to, .ty2 = fromType, .op2 = from };
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
            return Inst.gep(inst.res, inst.baseTy, inst.ptrTy, inst.ptrVal, inst.index);
        }
    };
    /// `<result> = getelementptr <ty>* <ptrval>, i1 0, i32 <index>`
    /// newer:
    /// `<result> = getelementptr <ty>, <ty>* <ptrval>, i1 0, i32 <index>`
    pub inline fn gep(basisTy: Type, ptrTy: Type, ptrVal: Ref, index: Ref) Inst {
        return .{ .op = .Gep, .ty1 = basisTy, .ty2 = ptrTy, .op1 = ptrVal, .op2 = index };
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

        pub const Kind = enum { bitcast, trunc, zext };

        pub inline fn get(inst: Inst) Misc {
            return .{
                .kind = switch (inst.op) {
                    .Bitcast => .bitcast,
                    .Trunc => .trunc,
                    .Zext => .zext,
                    else => unreachable,
                },
                .res = inst.res,
                .fromType = inst.ty1,
                .from = inst.op1,
                .toType = inst.ty2,
            };
        }
        pub inline fn toInst(inst: Misc) Inst {
            switch (inst.kind) {
                .bitcast => Inst.bitcast(inst.res, inst.fromType, inst.from, inst.toType),
                .trunc => Inst.trunc(inst.res, inst.fromType, inst.from, inst.toType),
                .zext => Inst.zext(inst.res, inst.fromType, inst.from, inst.toType),
            }
        }
    };
    // Miscellaneous
    /// `<result> = bitcast <ty> <value> to <ty2> ; cast type`
    pub inline fn bitcast(fromType: Type, from: Ref, toType: Type) Inst {
        return .{ .op = .Bitcast, .ty1 = fromType, .op1 = from, .ty2 = toType };
    }
    /// `<result> = trunc <ty> <value> to <ty2> ; truncate to ty2`
    pub inline fn trunc(res: Ref, ty: Type, from: Ref, to: Type) Inst {
        return .{ .op = .Trunc, .ty1 = ty, .res = res, .op1 = from, .ty2 = to };
    }
    /// `<result> = zext <ty> <value> to <ty2> ; zero-extend to ty2`
    pub inline fn zext(res: Ref, ty: Type, from: Ref, to: Type) Inst {
        return .{ .op = .Zext, .ty1 = ty, .res = res, .op1 = from, .ty2 = to };
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
            return Inst.phi(inst.res, inst.type, inst.entries);
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
            .Bitcast, .Trunc, .Zext => {
                var _misc = Inst.Misc.get(self);
                return writer.print("{any}\n", .{_misc});
            },
            .Phi => {
                const _phi = Inst.Phi.get(self);
                return writer.print("{any}\n", .{_phi});
            },
        }
    }
};

const ting = std.testing;

// feelin too lazy to fix this rn. It was just supposed to make sure evertyhing compiles
// test "binop helpers" {
//     _ = Inst.add(Ref.local(0), Ref.local(1), Ref.local(2));
//     _ = Inst.mul(Ref.local(0), Ref.local(1), Ref.local(2));
//     _ = Inst.div(Ref.local(0), Ref.local(1), Ref.local(2));
//     _ = Inst.sub(Ref.local(0), Ref.local(1), Ref.local(2));
//     _ = Inst.and_(Ref.local(0), Ref.local(1), Ref.local(2));
//     _ = Inst.or_(Ref.local(0), Ref.local(1), Ref.local(2));
//     _ = Inst.xor(Ref.local(0), Ref.local(1), Ref.local(2));
// }
