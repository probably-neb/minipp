// TODO: in the parsing of all the types there is a lot of using an arrayList, however theese are known size array for many of the types and this could be refactored
const std = @import("std");
const lexer = @import("lexer.zig");
const Token = lexer.Token;
const Lexer = lexer.Lexer;
const TokenKind = lexer.TokenKind;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

pub const NodeKind = union(enum) {
    Type,
    Decl,
    NestedDecl,
    TypeDeclaration,
};

pub const Node = struct {
    kind: NodeKind,
    token: Token,
    children: ?[]Node = null,
};

pub const Parser = struct {
    tokens: []Token,
    input: []const u8,
    ast: ?*Node,
    pos: usize = 0,
    readPos: usize = 0,
    idMap: std.StringHashMap(bool),

    fn peekToken(self: *Parser) !Token {
        return self.tokens[self.readPos];
    }

    fn currentToken(self: *Parser) !Token {
        return self.tokens[self.pos];
    }

    fn consumeToken(self: *Parser) !Token {
        const token = self.tokens.get(self.readPos) orelse return error.TokenIndexOutOfBounds;
        self.pos = self.readPos;
        self.readPos += 1;
        return token;
    }

    fn expectToken(self: *Parser, kind: TokenKind) !Token {
        const token = try self.peekToken();
        if (token.kind.equals(kind)) {
            return try self.consumeToken();
        }
        return std.debug.panic("expected token kind {s} but got {s}.\n At \"{s}\":{any}:{any} in input", .{ @tagName(kind), @tagName(token.kind), token.file, token.line, token.column });
    }

    fn expectIdentifier(self: *Parser) !Node {
        const token = try self.expectToken(TokenKind.Identifier);
        self.idMap.put(token.kind.getSubStrFromStr(self.input), true);
        return newTypeNode(token);
    }

    fn newTypeNode(token: Token) Node {
        return Node{ .kind = NodeKind.Type, .token = token };
    }

    pub fn parseTokens(tokens: []Token, input: []const u8) !Parser {
        var parser = Parser{
            .ast = null,
            .idMap = std.StringHashMap(bool).init(allocator),
            .tokens = tokens,
            .input = input,
        };
        // TODO make this program and not type declaration
        parser.ast = try parser.parseTypeDeclaration(tokens);
        std.debug.print("ast: {any}\n", .{parser.ast});
        return parser;
    }

    // TypeDeclaration = "struct" Identifier "{" NestedDeclarations "}" ";"
    pub fn parseTypeDeclaration(self: *Parser, tokens: []Token) !Node {
        // TODO: maybe figure out something better than just using the current token
        var result: Node = Node{ .kind = NodeKind.TypeDeclaration, .token = try self.currentToken() };

        // TODO: remov this
        std.debug.print("tokens: {any}\n\n\n", .{tokens});

        var children = std.ArrayList(Node).init(allocator);

        // Exepect struct
        try children.append(try self.expectToken(TokenKind.KeywordStruct));

        // Expect identifier
        try children.append(try self.expectIdentifier());

        try self.expectToken(TokenKind.LCurly);

        // Expect nested declarations
        try children.append(try self.parseNestedDeclarations());

        // Expect }
        // TODO: maybe don't keep the curly braces in the AST
        try self.expectToken(TokenKind.RCurly);

        // Expect ;
        // TODO: maybe don't keep the semicolons in the AST
        try self.expectToken(TokenKind.Semicolon);

        // convert to array
        result.children = children.toOwnedSlice();

        return result;
    }

    // NestedDeclarations = { Decl ";" }+
    pub fn parseNestedDeclarations(self: *Parser) !Node {
        // init
        var result: Node = Node{ .kind = NodeKind.NestedDecl, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        try children.append(try self.parseDecl());
        try self.expectToken(TokenKind.Semicolon);

        while (try self.peekToken().kind != TokenKind.RCurly) {
            try children.append(try self.parseDecl());
            try self.expectToken(TokenKind.Semicolon);
        }
        result.children = children.toOwnedSlice();
        return result;
    }

    // Declaration = Type Identifier
    pub fn parseDecl(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.NestedDecl, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        try children.append(try self.parseType());

        try children.append(try self.expectIdentifier());

        result.children = children.toOwnedSlice();
        return result;
    }

    pub fn parseType(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.NestedDecl, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        switch (self.currentToken()) {
            TokenKind.KeywordInt, TokenKind.KeywordBool => {
                children = null;
            },
            TokenKind.KeywordStruct => {
                try children.append(try self.expectIdentifier);
            },
            else => {
                return std.debug.panic("expected type but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
            },
        }

        result.children = children.toOwnedSlice();
        return result;
    }
};

pub fn main() !void {
    const source = "struct TS { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source);
    const parser = try Parser.parseTokens(tokens, source);
    _ = parser;
}

//(program:1(
//  types:1 (
//      type_declaration:1 struct TS { (
//          nested_decl:1
//              ( decl:1 (type:1 int) a) ;
//              ( decl:1 (type:1 int) b) ;
//              ( decl:1 (type:3 struct TS) S) ;
//      ) } ;
//  )
//  )
//  declarations:1
//  functions:1
//  <EOF>)
