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
    Void,
    Read,
    Decl,
    NestedDecl,
    TypeDeclaration,
    Declarations,
    Declaration,
    Functions,
    Function,
    Parameters,
    ReturnType,
    Statement,
    Block,
    Assignment,
    Print,
    PrintLn,
    ConditionalIf,
    ConditionalIfElse,
    While,
    Delete,
    Return,
    Invocation,
    StatementList,
    LValue,
    Expression,
    BoolTerm,
    EqTerm,
    RelTerm,
    Simple,
    Term,
    Unary,
    Selector,
    Factor,
    Arguments,
    Not,
    NotEq,
    Equals,
    GreaterThan,
    LessThan,
    GreaterThanEq,
    LessThanEq,
    Number,
    True,
    False,
    New,
    Null,
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

    fn peekNToken(self: *Parser, n: usize) !Token {
        return self.tokens[self.readPos + n];
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

    // Type = "int" | "bool" | "struct" Identifier
    pub fn parseType(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.NestedDecl, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        switch (self.consumeToken()) {
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

    pub fn isCurrentTokenAType(self: *Parser) bool {
        switch (self.currentToken().kind) {
            TokenKind.KeywordInt, TokenKind.KeywordBool, TokenKind.KeywordStruct => {
                return true;
            },
            else => {
                return false;
            },
        }
    }

    // Declarations = { Declaration }*
    pub fn parseDeclarations(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // While not EOF or function keyword then parse declaration
        // Expect (Declaration)*
        while (try self.isCurrentTokenAType()) {
            // Expect Declaration
            try children.append(try self.parseDeclaration());
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Declaration = Type Identifier ("," Identifier)* ";"
    pub fn parseDeclaration(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declaration, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect type
        try children.append(try self.parseType());

        // Expect Identifier
        try children.append(try self.expectIdentifier());

        // Expect ("," Identifier)* ";"
        while (try self.currentToken().kind != TokenKind.Semicolon) {
            // Expect ,
            try self.expectToken(TokenKind.Comma);
            // Expect Identifier
            try children.append(try self.expectIdentifier());
            // Repeat
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        result.children = children.toOwnedSlice();
        return result;
    }

    // Functions = { Function }*
    pub fn parseFunctions(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // While not EOF then parse function
        // Expect (Function)*
        while (try self.currentToken().kind == TokenKind.KeywordFun) {
            try children.append(try self.parseFunction());
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Function = "fun" Identifier Paramaters ReturnType "{" Declarations StatementList "}"
    pub fn parseFunction(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect fun
        try self.expectToken(TokenKind.KeywordFun);

        // Expect Identifier
        try children.append(try self.expectIdentifier());

        // Expect Parameters
        try children.append(try self.parseParameters());

        // Expect ReturnType
        try children.append(try self.parseReturnType());

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect Declarations
        try children.append(try self.parseDeclarations());

        // Expect StatementList
        try children.append(try self.parseStatementList());

        // Expect }

        try self.expectToken(TokenKind.RCurly);

        result.children = children.toOwnedSlice();
        return result;
    }

    // Parameters = "(" (Decl ("," Decl)* )? ")"
    pub fn parseParameters(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect (
        try self.expectToken(TokenKind.LParen);

        while (try self.isCurrentTokenAType()) {
            // Expect Decl
            try children.append(try self.parseDecl());
            // Expect ("," Decl)*

            while (try self.currentToken().kind == TokenKind.Comma) {
                // Expect ,
                try self.expectToken(TokenKind.Comma);
                // Expect Decl
                try children.append(try self.parseDecl());
            }
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // ReturnType = Type | "void"
    pub fn parseReturnType(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        switch (self.currentToken().kind) {
            TokenKind.KeywordVoid => {
                children = null;
            },
            else => {
                try children.append(try self.parseType());
            },
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Statement = Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation
    pub fn parseStatement(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        switch (self.currentToken().kind) {
            // Block
            TokenKind.LCurly => {
                try children.append(try self.parseBlock());
            },
            // Invocation | Assignment
            TokenKind.Identifier => {
                switch (self.peekToken().kind) {
                    TokenKind.LParen => {
                        try children.append(try self.parseInvocation());
                    },
                    else => {
                        try children.append(try self.parseAssignment());
                    },
                }
            },
            // ConditionalIf | ConditionalIfElse
            TokenKind.KeywordIf => {
                try children.append(try self.parseConditionals());
            },
            // While
            TokenKind.KeywordWhile => {
                try children.append(try self.parseWhile());
            },
            // Delete
            TokenKind.KeywordDelete => {
                try children.append(try self.parseDelete());
            },
            // Return
            TokenKind.KeywordReturn => {
                try children.append(try self.parseReturn());
            },
            // Print | PrintLn
            TokenKind.KeywordPrint => {
                try children.append(try self.parsePrints());
            },
            else => {
                return std.debug.panic("expected statement but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
            },
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Block = "{" StatementList "}"
    pub fn parseBlock(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // if not } then parse statement list
        while (try self.currentToken().kind != TokenKind.RCurly) {
            try children.append(try self.parseStatement());
        }

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        result.children = children.toOwnedSlice();
        return result;
    }

    // Assignment = LValue = (Expression | "read") ";"
    pub fn parseAssignment(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect LValue
        try children.append(try self.parseLValue());

        // Expect =
        try self.expectToken(TokenKind.Eq);

        // Expect Expression | "read"
        if (self.currentToken().kind == TokenKind.KeywordRead) {
            // make read node
            const readNode = Node{ .kind = NodeKind.Read, .token = try self.consumeToken() };
            try children.append(readNode);
        } else {
            try children.append(try self.parseExpression());
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        result.children = children.toOwnedSlice();
        return result;
    }

    // Print = "print" Expression ";"
    // PrintLn = "print" Expression "endl" ";"
    pub fn parsePrints(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Print, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect print
        try self.expectToken(TokenKind.KeywordPrint);

        // Expect Expression
        try children.append(try self.parseExpression());

        switch (self.currentToken().kind) {
            // Expect ;
            TokenKind.Semicolon => {
                try self.expectToken(TokenKind.Semicolon);
                result.kind = NodeKind.Print;
            },
            // Expect endl ;
            TokenKind.KeywordEndl => {
                try self.expectToken(TokenKind.KeywordEndl);
                try self.expectToken(TokenKind.Semicolon);
                result.kind = NodeKind.PrintLn;
            },
            else => {
                return std.debug.panic("expected ; or endl but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
            },
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // ConditionalIf = "if" "(" Expression ")" Block
    // ConditionalIfElse = "if" "(" Expression ")" Block "else" Block
    pub fn parseConditionals(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.ConditionalIf, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect if
        try self.expectToken(TokenKind.KeywordIf);

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // Expect Expression
        try children.append(try self.parseExpression());

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // Expect Block
        try children.append(try self.parseBlock());

        // If else then parse else block
        if (self.currentToken().kind == TokenKind.KeywordElse) {
            // Expect else
            try self.expectToken(TokenKind.KeywordElse);
            // Expect Block
            try children.append(try self.parseBlock());
            result.kind = NodeKind.ConditionalIfElse;
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // While = "while" "(" Expression ")" Block
    pub fn parseWhile(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect while
        try self.expectToken(TokenKind.KeywordWhile);

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // Expect Expression
        try children.append(try self.parseExpression());

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // Expect Block
        try children.append(try self.parseBlock());

        result.children = children.toOwnedSlice();
        return result;
    }

    // Delete = "delete" Expression ";"
    pub fn parseDelete(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect delete
        try self.expectToken(TokenKind.KeywordDelete);

        // Expect Expression
        try children.append(try self.parseExpression());

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        result.children = children.toOwnedSlice();
        return result;
    }

    // Return = "return" (Expression)?  ";"
    pub fn parseReturn(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect return
        try self.expectToken(TokenKind.KeywordReturn);

        // Expect Expression optionally
        if (self.currentToken().kind != TokenKind.Semicolon) {
            // Expect Expression
            try children.append(try self.parseExpression());
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        result.children = children.toOwnedSlice();
        return result;
    }

    // Invocation = Identifier Arguments ";"
    pub fn parseIdentifier(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Identifier
        try children.append(try self.expectIdentifier());

        // Expect Arguments
        try children.append(try self.parseArguments());

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        result.children = children.toOwnedSlice();
        return result;
    }

    // LValue = Identifier ("." Identifier)*
    pub fn parseLValue(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Identifier
        try children.append(try self.expectIdentifier());

        // Expect ("." Identifier)*
        while (try self.currentToken().kind == TokenKind.Dot) {
            // Expect .
            try self.expectToken(TokenKind.Dot);
            // Expect Identifier
            try children.append(try self.expectIdentifier());
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Expression = BoolTerm ("||" BoolTerm)*
    pub fn parseExpression(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect BoolTerm
        try children.append(try self.parseBoolTerm());

        // Expect ("||" BoolTerm)*
        while (try self.currentToken().kind == TokenKind.Or) {
            // Expect ||
            try self.expectToken(TokenKind.Or);
            // Expect BoolTerm
            try children.append(try self.parseBoolTerm());
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Boolterm = EqTerm ("&&" EqTerm)*
    pub fn parseBoolTerm(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect EqTerm
        try children.append(try self.parseEqTerm());

        // Expect ("&&" EqTerm)*
        while (try self.currentToken().kind == TokenKind.And) {
            // Expect &&
            try self.expectToken(TokenKind.And);
            // Expect EqTerm
            try children.append(try self.parseEqTerm());
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // EqTerm = RelTerm (("==" | "!=") RelTerm)*
    pub fn parseEqTerm(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect RelTerm
        try children.append(try self.parseRelTerm());

        // Expect (("==" | "!=") RelTerm)*
        while (try self.currentToken().kind == TokenKind.DoubleEq or self.currentToken().kind == TokenKind.NotEq) {
            switch (self.currentToken().kind) {
                TokenKind.NotEq => {
                    // Expect !=
                    const notEqToken = try self.expectToken(TokenKind.NotEq);
                    const notEqNode = Node{ .kind = NodeKind.NotEq, .token = notEqToken };
                    try children.append(notEqNode);

                    // Expect RelTerm
                    try children.append(try self.parseRelTerm());
                },
                TokenKind.DoubleEq => {
                    // Expect ==
                    const eqToken = try self.expectToken(TokenKind.DoubleEq);
                    const eqNode = Node{ .kind = NodeKind.Equals, .token = eqToken };
                    try children.append(eqNode);
                    // Expect RelTerm
                    try children.append(try self.parseRelTerm());
                },
                else => {
                    return std.debug.panic("expected == or != but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
                },
            }
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // RelTerm = Simple (("<" | ">" | ">=" | "<=") Simple)*
    pub fn parseRelTerm(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Simple
        try children.append(try self.parseSimple());

        // Expect (("<" | ">" | ">=" | "<=") Simple)*
        while (try self.currentToken().kind == TokenKind.Lt or self.currentToken().kind == TokenKind.Gt or self.currentToken().kind == TokenKind.GtEq or self.currentToken().kind == TokenKind.LtEq) {
            switch (self.currentToken().kind) {
                TokenKind.Lt => {
                    // Expect <
                    const ltToken = try self.expectToken(TokenKind.Lt);
                    const ltNode = Node{ .kind = NodeKind.LessThan, .token = ltToken };
                    try children.append(ltNode);
                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                TokenKind.Gt => {
                    // Expect >
                    const gtToken = try self.expectToken(TokenKind.Gt);
                    const gtNode = Node{ .kind = NodeKind.GreaterThan, .token = gtToken };
                    try children.append(gtNode);

                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                TokenKind.GtEq => {
                    // Expect >=
                    const gtEqToken = try self.expectToken(TokenKind.GtEq);
                    const gtEqNode = Node{ .kind = NodeKind.GreaterThanEq, .token = gtEqToken };
                    try children.append(gtEqNode);
                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                TokenKind.LtEq => {
                    // Expect <=
                    const ltEqToken = try self.expectToken(TokenKind.LtEq);
                    const ltEqNode = Node{ .kind = NodeKind.LessThanEq, .token = ltEqToken };
                    try children.append(ltEqNode);
                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                else => {
                    return std.debug.panic("expected <, >, >= or <= but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
                },
            }
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Simple = Term (("+" | "-") Term)*
    pub fn parseSimple(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Term
        try children.append(try self.parseTerm());

        // Expect (("+" | "-") Term)*
        while (try self.currentToken().kind == TokenKind.Plus or self.currentToken().kind == TokenKind.Minus) {
            switch (self.currentToken().kind) {
                TokenKind.Plus => {
                    // Expect +
                    const plusToken = try self.expectToken(TokenKind.Plus);
                    const plusNode = Node{ .kind = NodeKind.Plus, .token = plusToken };
                    try children.append(plusNode);
                    // Expect Term
                    try children.append(try self.parseTerm());
                },
                TokenKind.Minus => {
                    // Expect -
                    const minusToken = try self.expectToken(TokenKind.Minus);
                    const minusNode = Node{ .kind = NodeKind.Minus, .token = minusToken };
                    try children.append(minusNode);
                    // Expect Term
                    try children.append(try self.parseTerm());
                },
                else => {
                    return std.debug.panic("expected + or - but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
                },
            }
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Term = Unary (("*" | "/") Unary)*
    pub fn parseTerm(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Unary
        try children.append(try self.parseUnary());

        // Expect (("*" | "/") Unary)*
        while (try self.currentToken().kind == TokenKind.Mul or self.currentToken().kind == TokenKind.Div) {
            switch (self.currentToken().kind) {
                TokenKind.Asterisk => {
                    // Expect *
                    const mulToken = try self.expectToken(TokenKind.Mul);
                    const mulNode = Node{ .kind = NodeKind.Mul, .token = mulToken };
                    try children.append(mulNode);
                    // Expect Unary
                    try children.append(try self.parseUnary());
                },
                TokenKind.Slash => {
                    // Expect /
                    const divToken = try self.expectToken(TokenKind.Div);
                    const divNode = Node{ .kind = NodeKind.Div, .token = divToken };
                    try children.append(divNode);
                    // Expect Unary
                    try children.append(try self.parseUnary());
                },
                else => {
                    return std.debug.panic("expected * or / but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
                },
            }
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Unary = ("!" | "-")* Selector
    pub fn parseUnary(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect ("!" | "-")*
        while (try self.currentToken().kind == TokenKind.Not or self.currentToken().kind == TokenKind.Minus) {
            switch (self.currentToken().kind) {
                TokenKind.Not => {
                    // Expect !
                    const notToken = self.expectToken(TokenKind.Not);
                    const notNode = Node{ .kind = NodeKind.Not, .token = notToken };
                    try children.append(notNode);
                },
                TokenKind.Minus => {
                    // Expect -
                    const minusToken = try self.expectToken(TokenKind.Minus);
                    const minusNode = Node{ .kind = NodeKind.Unary, .token = minusToken };
                    try children.append(minusNode);
                },
                else => {
                    return std.debug.panic("expected ! or - but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
                },
            }
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Selector = Factor ("." Identifier)*
    pub fn parseSelector(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Factor
        try children.append(try self.parseFactor());

        // Expect ("." Identifier)*
        while (try self.currentToken().kind == TokenKind.Dot) {
            // Expect .
            try self.expectToken(TokenKind.Dot);
            // Expect Identifier
            try children.append(try self.expectIdentifier());
        }

        result.children = children.toOwnedSlice();
        return result;
    }

    // Factor = "(" Expression ")" | Identifier (Arguments)? | Number | "true" | "false" | "new" Identifier | "null"
    pub fn parseFactor(self: *Parser) !Node {
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        switch (self.currentToken().kind) {
            TokenKind.LParen => {
                // Expect (
                try self.expectToken(TokenKind.LParen);
                // Expect Expression
                try children.append(try self.parseExpression());
                // Expect )
                try self.expectToken(TokenKind.RParen);
            },
            TokenKind.Identifier => {
                // Expect Identifier
                try children.append(try self.expectIdentifier());
                // Expect (Arguments)?
                if (self.currentToken().kind == TokenKind.LParen) {
                    // Expect Arguments
                    try children.append(try self.parseArguments());
                }
            },
            TokenKind.Number => {
                // Expect Number
                const numberToken = try self.expectToken(TokenKind.Number);
                const numberNode = Node{ .kind = NodeKind.Number, .token = numberToken };
                try children.append(numberNode);
            },
            TokenKind.KeywordTrue => {
                // Expect true
                const trueToken = try self.consumeToken();
                const trueNode = Node{ .kind = NodeKind.True, .token = trueToken };
                try children.append(trueNode);
            },
            TokenKind.KeywordFalse => {
                // Expect  false
                const falseToken = try self.consumeToken();
                const falseNode = Node{ .kind = NodeKind.False, .token = falseToken };
                try children.append(falseNode);
            },
            TokenKind.KeywordNew => {
                // Expect new
                const newToken = try self.consumeToken();
                const newNode = Node{ .kind = NodeKind.New, .token = newToken };
                try children.append(newNode);

                // Expect Identifier
                try children.append(try self.expectIdentifier());
            },
            TokenKind.KeywordNull => {
                // Expect null
                const nullToken = try self.consumeToken();
                const nullNode = Node{ .kind = NodeKind.Null, .token = nullToken };
                try children.append(nullNode);
            },
            else => {
                return std.debug.panic("expected factor but got {s}.\n At \"{s}\":{any}:{any} in input", .{ TokenKind[self.currentToken().kind], self.currentToken().file, self.currentToken().line, self.currentToken().column });
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
