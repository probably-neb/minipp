////////////////////////////////////////////////////////////////////////////////
/// Version 0.0: Will need to implement type checking
////////////////////////////////////////////////////////////////////////////////

const std = @import("std");
const lexer = @import("lexer.zig");
const Token = lexer.Token;
const Lexer = lexer.Lexer;
const TokenKind = lexer.TokenKind;

const Node = @import("ast.zig").Node;
const NodeKind = Node.Kind;
const NodeLIst = @import("ast.zig").NodeList;

const utils = @import("utils.zig");
const Parser = @import("parser.zig").Parser;
const Struct_t = @import("parser.zig").Struct_t;

pub fn main() !void {
    const source = "struct test{ int a;int b; int c; int d; struct test t; }; fun A() void{ int d;d=2+5;}";
    const tokens = try Lexer.tokenizeFromStr(source, std.heap.page_allocator);
    const parser = try Parser.parseTokens(tokens, source, std.heap.page_allocator);
    std.debug.print("Parsed successfully\n", .{});
    try parser.prettyPrintAst();
    const structIDS = parser.structArray.items;
    //pretty print structIDS;
    for (structIDS) |structID| {
        std.debug.print("Struct ID: {any}\n", .{structID.id});
        var start = structID.decls.start;
        var end = structID.decls.end;
        while (start < end) {
            const decl = parser.declArray.items[start];
            try parser.prettyPrintDeclNode(decl);
            start += 1;
        }
    }
    std.debug.print("\n\n\n\n\n\n\n", .{});
    const source2 = "struct test{ int a;int b; int c; int d; struct test t; }; fun A() void{ int d; struct test t; d=2+5+t.t.t.t.a;}";
    const tokens2 = try Lexer.tokenizeFromStr(source2, std.heap.page_allocator);
    var parser2 = try Parser.parseTokens(tokens2, source2, std.heap.page_allocator);
    try parser2.prettyPrintAst();
    const decls = parser2.declArray.items;
    for (decls) |decl| {
        try parser2.prettyPrintDeclNode(decl);
        const lhs = parser.ast.items[decl].kind.Decl.lhs;
        var rhs = parser.ast.items[lhs.?].kind.Type.rhs;
        if (rhs == null) {
            rhs = lhs;
        }
        const str = try parser2.getStrFromID(rhs.?);
        std.debug.print("{{{s},{any}}}", .{ str, parser2.getTypeNumber(str) });
    }
}
