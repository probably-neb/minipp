const std = @import("std");

const IR = @import("ir.zig");
const Inst = IR.Inst;

const Ast = @import("../ast.zig");
const log = @import("../log.zig");
const utils = @import("../utils.zig");

pub const StackGen = @This();
const Ctx = StackGen;

alloc: std.mem.Allocator,

pub fn generate(alloc: std.mem.Allocator, ast: *const Ast) !IR {
    const this = StackGen{
        .alloc = alloc,
    };
    _ = this;
    var ir = IR.init(alloc);

    const globals = try gen_globals(&ir, ast);
    ir.globals.fill(globals);

    const types = try gen_types(&ir, ast);
    try ir.types.fill(types);

    return ir;
}

pub const MemError = std.mem.Allocator.Error;

pub fn gen_globals(ir: *IR, ast: *const Ast) MemError![]IR.GlobalsList.Item {
    const Global = IR.GlobalsList.Item;
    const programDecls = ast.find(.ProgramDeclarations, 0) orelse unreachable;
    const globalDeclsIndex = programDecls.kind.ProgramDeclarations.declarations;
    if (globalDeclsIndex == null) {
        // wierd I know but it coerces to empty list because
        // zig has reasonable defaults
        // there is a test that checks for this do not worry
        return undefined;
    }
    var globalDeclsIter = ast.get(globalDeclsIndex.?).kind.LocalDeclarations.iter(ast);

    const numDecls = globalDeclsIter.calculateLen();
    const globalDecls: []Global = try ir.alloc.alloc(Global, numDecls);

    var gi: usize = 0;
    while (globalDeclsIter.next()) |globalNode| : (gi += 1) {
        const global = globalNode.kind.TypedIdentifier;

        const ident = ir.internIdent(global.getName(ast));
        const irType = ir.astTypeToIRType(global.getType(ast));

        globalDecls[gi] = Global.init(ident, irType);
    }

    return globalDecls;
}

pub fn gen_types(ir: *IR, ast: *const Ast) MemError![]IR.TypeList.Item {
    const Struct = IR.TypeList.Item;
    const Field = Struct.Field;

    var iter = ast.structMap.valueIterator();

    // WARN: read the comment at the call to realloc at the end of this function
    const numDecls = iter.len;
    log.trace("numDecls: {}\n", .{numDecls});
    const types: []Struct = try ir.alloc.alloc(Struct, numDecls);

    var ti: usize = 0;

    while (iter.next()) |declIndex| : (ti += 1) {
        // Just a safeguard in case iter.len is lower than the number of declarations
        // see comments before the return
        utils.assert(ti <= numDecls, "ti <= numDecls in `gen_types`. There's a comment about this. I'm Sorry\n", .{});

        const decl = ast.get(declIndex.*).kind.TypeDeclaration;
        const structNameID = ir.internIdentNodeAt(ast, decl.ident);

        var fieldIter = ast.get(decl.declarations).kind.StructFieldDeclarations.iter(ast);

        // pre-iter all fields so no realloc
        const numFields = fieldIter.calculateLen();
        const fields: []Field = try ir.alloc.alloc(Field, numFields);

        var fi: usize = 0;

        while (fieldIter.next()) |fieldNode| : (fi += 1) {
            const field = fieldNode.kind.TypedIdentifier;
            const fieldNameID = ir.internIdent(field.getName(ast));

            const fieldAstType = field.getType(ast);
            const fieldType = ir.astTypeToIRType(fieldAstType);

            fields[fi] = Field.init(fieldNameID, fieldType);
        }
        types[ti] = Struct.init(structNameID, fields);
    }

    // So.... the structMap iter.len is not accurate, only bigger as far as I can tell,
    // so i'm doing the easy thing and just resizing the array here instead of figuring out
    // how to get the correct size. I apologize in advance if `.len` is ever too small
    // and there's an out of bounds error
    const types_sized = try ir.alloc.realloc(types, ti);
    return types_sized;
}

const ting = std.testing;
const testAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !IR {
    const tokens = try @import("../lexer.zig").Lexer.tokenizeFromStr(input, testAlloc);
    const parser = try @import("../parser.zig").Parser.parseTokens(tokens, input, testAlloc);
    const ast = try Ast.initFromParser(parser);
    const ir = try generate(testAlloc, &ast);
    return ir;
}

test "stack.types.none" {
    const input = "fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 0), ir.types.len());
}

test "stack.types.multiple" {
    errdefer log.print();
    const input = "struct Foo { int a; bool b; }; struct Bar { int c; int d; int e;}; fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 2), ir.types.len());
    const foo = ir.types.index(0);
    const bar = ir.types.index(1);
    try ting.expectEqualStrings("Foo", ir.getIdent(foo.name));
    try ting.expectEqual(@as(usize, 2), foo.numFields());
    try ting.expectEqualStrings("Bar", ir.getIdent(bar.name));
    try ting.expectEqual(@as(usize, 3), bar.numFields());
}

test "stack.globals.multiple" {
    const input = "struct Foo { int a; bool b; }; int a; bool b; fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 2), ir.globals.len());
    const a = ir.globals.index(0);
    const b = ir.globals.index(1);
    try ting.expectEqualStrings("a", ir.getIdent(a.name));
    try ting.expectEqual(IR.Type.int, a.type);
    try ting.expectEqualStrings("b", ir.getIdent(b.name));
    try ting.expectEqual(IR.Type.bool, b.type);
}

test "stack.globals.none" {
    const input = "struct Foo { int a; bool b; }; fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 0), ir.globals.len());
}
