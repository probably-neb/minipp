const std = @import("std");

const IR = @import("ir.zig");
const Inst = IR.Inst;

const Ast = @import("../ast.zig");

pub const StackGen = @This();
const Ctx = StackGen;

alloc: std.mem.Allocator,

pub fn generate(alloc: std.mem.Allocator, ast: *const Ast) !IR {
    const this = StackGen{
        .alloc = alloc,
    };
    _ = this;
    var ir = IR.init(alloc);

    gen_global_decls(&ir, ast);
    try gen_types(&ir, ast);

    return ir;
}

pub fn gen_global_decls(ir: *IR, ast: *const Ast) void {
    _ = ir;
    _ = ast;
}

pub fn gen_types(ir: *IR, ast: *const Ast) std.mem.Allocator.Error!void {
    const Struct = IR.TypeList.Item;
    const Field = Struct.Field;

    var iter = ast.structMap.valueIterator();

    const numDecls = iter.len;
    const types: []Struct = try ir.alloc.alloc(Struct, numDecls);

    var ti: usize = 0;

    while (iter.next()) |declIndex| : (ti += 1) {
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

    try ir.types.fill(types);
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

test "stack.types.2" {
    const input = "struct Foo { a: int, b: bool } struct fun main() void {}";
    const ir = try testMe(input);
    try ting.expectEqual(@as(usize, 1), ir.types.len());
    const foo = ir.types.at(0);
    try ting.expectEqual("Foo", foo.name);
    try ting.expectEqual(@as(usize, 2), foo.fields.len());
    try ting.expectEqual("a", foo.fields.at(0).name);
    try ting.expectEqual("b", foo.fields.at(1).name);
}
