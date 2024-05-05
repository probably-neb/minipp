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
        .Null => .null,
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

    // index into the insts array
    pub const InstID = u32;

    pub const entryBBID = 0;
    pub const exitBBID = 1;

    pub fn init(alloc: std.mem.Allocator, name: StrID, returnType: Type) Function {
        return .{
            .alloc = alloc,
            .bbs = OrderedList(BasicBlock).init(alloc),
            .name = name,
            .returnType = returnType,
            .regs = LookupTable(Register.ID, Register, Register.getID).init(alloc),
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

    pub fn addNamedInst(self: *Function, bb: BasicBlock.ID, basicInst: Inst, name: StrID, ty: Type) !Register {
        // reserve
        const regID = try self.regs.add(undefined);
        const instID = try self.insts.add(undefined);

        // construct
        const reg = Register{ .id = regID, .inst = instID, .name = name, .bb = bb, .type = ty };
        var inst = basicInst;
        inst.res = Ref.local(regID, name);

        // save
        self.regs.set(regID, reg);
        self.insts.set(instID, inst);
        return reg;
    }

    pub const NotFoundError = error{IdentifierNotFound};
    /// Gets the ID of a register created with an `alloca` in the entry
    /// based on the name of the identifier in question
    /// Returns `error.NotFound`
    /// WARN: ONLY SUPPOSED TO BE USED IN STACK IR GEN
    /// IN PHI NODES WE SHOULD SEARCH UP THE CFG
    pub fn getNamedAllocaReg(self: *Function, name: StrID) NotFoundError!Register {
        //       1   2            4          5     6   :(
        for (self.bbs.get(Function.entryBBID).insts.items) |instID| {
            const inst = self.insts.get(instID);
            const res = inst.res;
            if (res.name == name) {
                return self.regs.get(res.i);
            }
        }
        return error.IdentifierNotFound;
    }
};

pub const Register = struct {
    id: ID,
    inst: Function.InstID,
    name: StrID,
    bb: BasicBlock.ID,
    type: Type,

    pub const ID = u32;

    pub fn getID(self: Register) ID {
        return self.id;
    }
};

pub const BasicBlock = struct {
    incomers: std.ArrayList(Label),
    outgoers: [2]?Label,
    // and ORDERED list of the instruction ids of the instructions in this block
    insts: std.ArrayList(Function.InstID),

    /// The ID of a basic block is it's index within the arraylist of
    /// basic blocks in the `Function` type
    /// This is done differently than the LUT based approach for almost
    /// everthing else in the IR because the order of the basic blocks
    pub const ID = u32;

    pub fn init(alloc: std.mem.Allocator) BasicBlock {
        return .{
            .incomers = std.ArrayList(Label).init(alloc),
            .outgoers = [2]?Label{ null, null },
            .insts = std.ArrayList(Function.InstID).init(alloc),
        };
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

        pub fn lookup(self: Self, key: Key) Key {
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
                    return i;
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
            const id = self.len;
            try self.items.append(val);
            self.len += 1;
            return id;
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
        pub fn array(self: Self) []T {
            return self.list.items;
        }

        pub fn get(self: Self, idx: u32) T {
            return self.list.items[idx];
        }

        pub fn add(self: *Self, item: T) !u32 {
            const id = self.len;
            try self.list.append(item);
            self.len += 1;
            return id;
        }

        pub fn set(self: *Self, idx: u32, item: T) void {
            self.list.items[idx] = item;
        }
    };
}

pub const StructType = struct {
    // NOTE: same as this structs ID
    name: StrID,
    /// Lookup table for field names, where index of fields StrID
    /// is the index of the field i.e. its FieldID
    /// The slice is assumed to be allocated and freed if necessary by the TypeList
    fieldLookup: FieldList,

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
        return .{ .name = name, .fieldLookup = fieldLookup };
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

    pub fn get(self: *const TypeList, id: StructID) ?Item {
        return self.items.get(id);
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
    /// `<result> = getelementptr <ty>* <ptrval>, i1 0, i32 <index>`
    Store,
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
    pub const Cond = enum { Eq, Lt, Gt, GtEq, LtEq };

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
    null,
    // sawy dylan
    strct: StructID,
    /// The type used instead of optionals
    pub const default = Type.void;
};

/// Ref to a register
pub const Ref = struct {
    /// ID
    i: Register.ID,
    name: StrID,
    kind: enum { local, global, label, immediate },
    /// Ref used when no ref needed
    pub const default = Ref.local(0, InternPool.NULL);

    /// Helper function to create a ref to eine local
    pub inline fn local(i: u32, name: StrID) Ref {
        return Ref{ .i = i, .kind = .local, .name = name };
    }

    /// Helper function to create a ref to eine global
    pub inline fn global(i: u32, name: StrID) Ref {
        return Ref{ .i = i, .kind = .global, .name = name };
    }

    /// Helper function to create a ref to eine label
    pub inline fn label(i: u32) Ref {
        return Ref{ .i = i, .kind = .label, .name = i };
    }

    pub inline fn immediate(name: StrID) Ref {
        return Ref{ .i = 0, .kind = .immediate, .name = name };
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
        /// Function arguments
        args: std.ArrayList(Ref),
        /// Helper to use `none_` more elegantly
        pub fn none() Extra {
            return .{ .none_ = undefined };
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
        return Inst.sub(Ref.immediate(InternPool.ZERO), val);
    }
    // Boolean
    /// `<result> = and <ty> <op1>, <op2>`
    pub inline fn and_(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .And } };
    }
    /// `<result> = or <ty> <opi>, <op2>`
    pub inline fn or_(res: Ref, lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .res = res, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Or } };
    }
    /// `<result> = xor <ty> <opl>, <op2>`
    pub inline fn xor(lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Binop, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .op = .Xor } };
    }
    pub inline fn not(val: Ref) Inst {
        return Inst.xor(val, Ref.immediate(InternPool.ONE));
    }

    pub const Cmp = struct {
        cond: Op.Cond,
        opTypes: Type,
        lhs: Ref,
        rhs: Ref,
        pub inline fn get(inst: Inst) Cmp {
            return .{
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
    pub inline fn cmp(res: Ref, cond: Op.Cond, lhs: Ref, rhs: Ref) Inst {
        return .{ .op = .Cmp, .res = res, .ty1 = .bool, .op1 = lhs, .op2 = rhs, .extra = .{ .cond = cond } };
    }

    pub const Br = struct {
        on: Ref,
        iftrue: Ref,
        iffalse: Ref,
        pub inline fn get(inst: Inst) Br {
            return .{
                .on = inst.extra.on,
                .iftrue = inst.op1,
                .iffalse = inst.op2,
            };
        }

        pub inline fn toInst(inst: Br) Inst {
            return Inst.br(inst.on, inst.iftrue, inst.iffalse);
        }
    };
    /// br i1 <cond>, label <iftrue>, label <iffalse>
    pub inline fn br(cond: Ref, iftrue: Ref, iffalse: Ref) Inst {
        return .{ .op = .Br, .extra = .{ .on = cond }, .op1 = iftrue, .op2 = iffalse };
    }

    pub const Jmp = struct {
        dest: Ref,
        pub inline fn get(inst: Inst) Jmp {
            return .{ .dest = inst.op1 };
        }
        pub inline fn toInst(inst: Jmp) Inst {
            return Inst.jmp(inst.dest);
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
    pub inline fn store(ty: Type, to: Ref, fromType: Type, from: Ref) Inst {
        return .{ .op = .Store, .ty1 = ty, .op1 = to, .ty2 = fromType, .op2 = from };
    }

    pub const Gep = struct {
        res: Ref,
        resTy: Type,
        ptrTy: Type,
        ptrVal: Ref,
        index: Ref,
        pub inline fn get(inst: Inst) Gep {
            return .{
                .res = inst.res,
                .resTy = inst.ty1,
                .ptrTy = inst.ty2,
                .ptrVal = inst.op1,
                .index = inst.op2,
            };
        }

        pub inline fn toInst(inst: Gep) Inst {
            return Inst.gep(inst.res, inst.resTy, inst.ptrTy, inst.ptrVal, inst.index);
        }
    };
    /// `<result> = getelementptr <ty>* <ptrval>, i1 0, i32 <index>`
    /// newer:
    /// `<result> = getelementptr <ty>, <ty>* <ptrval>, i1 0, i32 <index>`
    pub inline fn gep(res: Ref, resTy: Type, ptrTy: Type, ptrVal: Ref, index: Ref) Inst {
        return .{ .op = .Gep, .res = res, .ty1 = resTy, .ty2 = ptrTy, .op1 = ptrVal, .op2 = index };
    }

    pub const Call = struct {
        res: Ref,
        retTy: Type,
        fun: Ref,
        args: std.ArrayList(Ref),
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
    pub inline fn call(res: Ref, retTy: Type, fun: Ref, args: std.ArrayList(Ref)) Inst {
        return .{ .op = .Jmp, .res = res, .ty1 = retTy, .op1 = fun, .extra = .{ .args = args } };
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
        kind: enum { bitcast, trunc, zext },
        res: Ref,
        fromType: Type,
        from: Ref,
        toType: Type,
        pub inline fn get(inst: Inst) Misc {
            const kind = switch (inst.op) {
                .Bitcast => .bitcast,
                .Trunc => .trunc,
                .Zext => .zext,
                else => unreachable,
            };
            return .{
                .kind = kind,
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
    pub inline fn bitcast(res: Ref, fromType: Type, from: Ref, toType: Type) Inst {
        return .{ .op = .Bitcast, .ty1 = fromType, .res = res, .op1 = from, .ty2 = toType };
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
                .entries = inst.extra.phi,
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
