// TODO: in the parsing of all the types there is a lot of using an arrayList, however theese are known size array for many of the types and this could be refactored
const std = @import("std");
const lexer = @import("lexer.zig");
const Token = lexer.Token;
const Lexer = lexer.Lexer;
const TokenKind = lexer.TokenKind;
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// The parser is responsible for taking the tokens and creating an abstract syntax tree
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
    ast: ?Node,
    pos: usize = 0,
    readPos: usize = 0,
    idMap: std.StringHashMap(bool),

    // flags
    showParseTree: bool = false,

    fn peekToken(self: *Parser) !Token {
        if (self.readPos >= self.tokens.len) return error.TokenIndexOutOfBounds;
        return self.tokens[self.readPos];
    }

    fn currentToken(self: *Parser) !Token {
        if (self.pos >= self.tokens.len) return error.TokenIndexOutOfBounds;
        return self.tokens[self.pos];
    }

    fn consumeToken(self: *Parser) !Token {
        if (self.readPos >= self.tokens.len) {
            std.debug.print("Error Consuming Token: Out of bounds @ Token# {d}/{d}\n The last token was: {s}.\n", .{ self.readPos, self.tokens.len, @tagName((try self.currentToken()).kind) });
            std.debug.print("Hit EOF before expected.\n", .{});
            return error.TokenIndexOutOfBounds;
        }
        const token = self.tokens[self.readPos];
        self.pos = self.readPos;
        self.readPos += 1;
        return token;
    }

    fn expectToken(self: *Parser, kind: TokenKind) !void {
        const token = self.consumeToken() catch |err| {
            std.debug.print("Error could not find expected Token: {s}\n", .{@tagName(kind)});
            return err;
        };
        if (!token.kind.equals(kind)) {
            // TODO: should update with the desired changes to TokenKind, such that the position is found.
            // Refactored for the moment
            std.debug.print("Error invalid Token: expected token kind {s} but got {s}.\n", .{ @tagName(kind), @tagName(token.kind) });
            const line: []const u8 = token._range.getLineCont(self.input);
            std.debug.print("{s}\n", .{line});
            return error.InvalidToken;
        }
    }

    fn expectAndYeildToken(self: *Parser, kind: TokenKind) !Token {
        const token = self.consumeToken() catch |err| {
            std.debug.print("Error could not yeild expected Token: {s}\n", .{@tagName(kind)});
            return err;
        };
        if (token.kind.equals(kind)) {
            return token;
        }
        // TODO: should update with the desired changes to TokenKind, such that the position is found.
        // Refactored for the moment
        std.debug.print("Error invalid Token: expected token kind {s} but got {s}.\n", .{ @tagName(kind), @tagName(token.kind) });
        std.debug.print("{s}\n", .{token._range.getLineCont(self.input)});
        token._range.printLineContUnderline(self.input);
        return error.InvalidToken;
    }

    fn expectIdentifier(self: *Parser) !Node {
        const token = self.expectAndYeildToken(TokenKind.Identifier) catch |err| {
            std.debug.print("Error could not yeild Identifier.\n", .{});
            return err;
        };
        try self.idMap.put(token._range.getSubStrFromStr(self.input), true);
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
        // TODO: make this program and not type declaration
        parser.ast = try parser.parseTypeDeclaration();
        std.debug.print("ast: {any}\n", .{parser.ast});
        return parser;
    }

    // TypeDeclaration = "struct" Identifier "{" NestedDeclarations "}" ";"
    pub fn parseTypeDeclaration(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a TypeDelcaration\n", .{});
                std.debug.print("Defined as: TypeDeclaration = \"struct\" Identifier {{ NestedDeclarations }} \";\"\n", .{});
            }
        }
        // TODO: maybe figure out something better than just using the current token
        var result: Node = Node{ .kind = NodeKind.TypeDeclaration, .token = try self.currentToken() };

        var children = std.ArrayList(Node).init(allocator);

        // Exepect struct
        try self.expectToken(TokenKind.KeywordStruct);

        // Expect identifier
        try children.append(try self.expectIdentifier());

        try self.expectToken(TokenKind.LCurly);

        // Expect nested declarations
        try children.append(try self.parseNestedDeclarations());

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // convert to array
        result.children = try children.toOwnedSlice();

        return result;
    }

    // NestedDecl = { Decl ";" }+
    pub fn parseNestedDeclarations(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing NestedDeclarations\n", .{});
                std.debug.print("Defined as: NestedDeclarations = {{ Decl \";\" }}+\n", .{});
            }
        }
        // init
        var result: Node = Node{ .kind = NodeKind.NestedDecl, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        try children.append(try self.parseDecl());
        try self.expectToken(TokenKind.Semicolon);

        while ((try self.peekToken()).kind != TokenKind.RCurly) {
            try children.append(try self.parseDecl());
            try self.expectToken(TokenKind.Semicolon);
        }
        result.children = try children.toOwnedSlice();
        return result;
    }

    // Decl = Type Identifier
    pub fn parseDecl(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Decl\n", .{});
                std.debug.print("Defined as: Decl = Type Identifier\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Decl, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        try children.append(try self.parseType());

        try children.append(try self.expectIdentifier());

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Type = "int" | "bool" | "struct" Identifier
    pub fn parseType(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Type\n", .{});
                std.debug.print("Defined as: Type = \"int\" | \"bool\" | \"struct\" Identifier\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Type, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        const token = try self.consumeToken();
        switch (token.kind) {
            TokenKind.KeywordInt, TokenKind.KeywordBool => {},
            TokenKind.KeywordStruct => {
                try children.append(try self.expectIdentifier());
            },
            else => {
                return std.debug.panic("expected type but got {s}.\n", .{@tagName(token.kind)});
            },
        }

        result.children = try children.toOwnedSlice();
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
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Declarations\n", .{});
                std.debug.print("Defined as: Declarations = {{ Declaration }}*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Declarations, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // While not EOF or function keyword then parse declaration
        // Expect (Declaration)*
        while (try self.isCurrentTokenAType()) {
            // Expect Declaration
            try children.append(try self.parseDeclaration());
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Declaration = Type Identifier ("," Identifier)* ";"
    pub fn parseDeclaration(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Declaration\n", .{});
                std.debug.print("Defined as: Declaration = Type Identifier (\",\" Identifier)* \";\"\n", .{});
            }
        }
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Functions = ( Function )*
    pub fn parseFunctions(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Functions\n", .{});
                std.debug.print("Defined as: Functions = ( Function )*\n", .{});
            }
        }

        var result: Node = Node{ .kind = NodeKind.Functions, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // While not EOF then parse function
        // Expect (Function)*
        while (try self.currentToken().kind == TokenKind.KeywordFun) {
            try children.append(try self.parseFunction());
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Function = "fun" Identifier Paramaters ReturnType "{" Declarations StatementList "}"
    pub fn parseFunction(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Function\n", .{});
                std.debug.print("Defined as: Function = \"fun\" Identifier Paramaters ReturnType \"{{\" Declarations StatementList \"}}\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Function, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Parameters = "(" (Decl ("," Decl)* )? ")"
    pub fn parseParameters(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Parameters\n", .{});
                std.debug.print("Defined as: Parameters = \"(\" (Decl (\",\" Decl)* )? \")\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Parameters, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // ReturnType = Type | "void"
    pub fn parseReturnType(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing ReturnType\n", .{});
                std.debug.print("Defined as: ReturnType = Type | \"void\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.ReturnType, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        switch (self.currentToken().kind) {
            TokenKind.KeywordVoid => {
                children = null;
            },
            else => {
                try children.append(try self.parseType());
            },
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Statement = Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation
    pub fn parseStatement(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Statement\n", .{});
                std.debug.print("Defined as: Statement = Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Statement, .token = try self.currentToken() };
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
                return std.debug.panic("expected statement but got {s}.\n", .{@tagName(self.currentToken())});
            },
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Block = "{" StatementList "}"
    pub fn parseBlock(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Block\n", .{});
                std.debug.print("Defined as: Block = \"{{\" StatementList \"}}\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Block, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // if not } then parse statement list
        while (try self.currentToken().kind != TokenKind.RCurly) {
            try children.append(try self.parseStatement());
        }

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Assignment = LValue = (Expression | "read") ";"
    pub fn parseAssignment(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Assignment\n", .{});
                std.debug.print("Defined as: Assignment = LValue = (Expression | \"read\") \";\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Assignment, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Print = "print" Expression ";"
    // PrintLn = "print" Expression "endl" ";"
    pub fn parsePrints(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Print type\n", .{});
                std.debug.print("Defined as: Print = \"print\" Expression \";\"\n", .{});
            }
            std.debug.print("Or defined as: PrintLn = \"print\" Expression \"endl\" \";\"\n", .{});
        }
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
                return std.debug.panic("expected ; or endl but got {s}.", .{@tagName(self.currentToken())});
            },
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // ConditionalIf = "if" "(" Expression ")" Block
    // ConditionalIfElse = "if" "(" Expression ")" Block "else" Block
    pub fn parseConditionals(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Conditional\n", .{});
                std.debug.print("Defined as: ConditionalIf = \"if\" \"(\" Expression \")\" Block\n", .{});
                std.debug.print("Or defined as: ConditionalIfElse = \"if\" \"(\" Expression \")\" Block \"else\" Block\n", .{});
            }
        }
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // While = "while" "(" Expression ")" Block
    pub fn parseWhile(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a While\n", .{});
                std.debug.print("Defined as: While = \"while\" \"(\" Expression \")\" Block\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.While, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Delete = "delete" Expression ";"
    pub fn parseDelete(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Delete\n", .{});
                std.debug.print("Defined as: Delete = \"delete\" Expression \";\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Delete, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect delete
        try self.expectToken(TokenKind.KeywordDelete);

        // Expect Expression
        try children.append(try self.parseExpression());

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Return = "return" (Expression)?  ";"
    pub fn parseReturn(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Return\n", .{});
                std.debug.print("Defined as: Return = \"return\" (Expression)?  \";\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Return, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Invocation = Identifier Arguments ";"
    pub fn parseIdentifier(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Identifier\n", .{});
                std.debug.print("Defined as: Invocation = Identifier Arguments \";\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Invocation, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Identifier
        try children.append(try self.expectIdentifier());

        // Expect Arguments
        try children.append(try self.parseArguments());

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        result.children = try children.toOwnedSlice();
        return result;
    }

    // LValue = Identifier ("." Identifier)*
    pub fn parseLValue(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an LValue\n", .{});
                std.debug.print("Defined as: LValue = Identifier (\".\" Identifier)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.LValue, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Expression = BoolTerm ("||" BoolTerm)*
    pub fn parseExpression(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Expression\n", .{});
                std.debug.print("Defined as: Expression = BoolTerm (\"||\" BoolTerm)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Expression, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Boolterm = EqTerm ("&&" EqTerm)*
    pub fn parseBoolTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a BoolTerm\n", .{});
                std.debug.print("Defined as: Boolterm = EqTerm (\"&&\" EqTerm)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.BoolTerm, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // EqTerm = RelTerm (("==" | "!=") RelTerm)*
    pub fn parseEqTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an EqTerm\n", .{});
                std.debug.print("Defined as: EqTerm = RelTerm (\"==\" | \"!=\") RelTerm)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.EqTerm, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect RelTerm
        try children.append(try self.parseRelTerm());

        // Expect (("==" | "!=") RelTerm)*
        while (try self.currentToken().kind == TokenKind.DoubleEq or self.currentToken().kind == TokenKind.NotEq) {
            switch (self.currentToken().kind) {
                TokenKind.NotEq => {
                    // Expect !=
                    const notEqToken = try self.expectAndYeildToken(TokenKind.NotEq);
                    const notEqNode = Node{ .kind = NodeKind.NotEq, .token = notEqToken };
                    try children.append(notEqNode);

                    // Expect RelTerm
                    try children.append(try self.parseRelTerm());
                },
                TokenKind.DoubleEq => {
                    // Expect ==
                    const eqToken = try self.expectAndYeildToken(TokenKind.DoubleEq);
                    const eqNode = Node{ .kind = NodeKind.Equals, .token = eqToken };
                    try children.append(eqNode);
                    // Expect RelTerm
                    try children.append(try self.parseRelTerm());
                },
                else => {
                    return std.debug.panic("expected == or != but got {s}.\n", .{@tagName(self.currentToken())});
                },
            }
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // RelTerm = Simple (("<" | ">" | ">=" | "<=") Simple)*
    pub fn parseRelTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a RelTerm\n", .{});
                std.debug.print("Defined as: RelTerm = Simple (\"<\" | \">\" | \">=\" | \"<=\") Simple)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.RelTerm, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Simple
        try children.append(try self.parseSimple());

        // Expect (("<" | ">" | ">=" | "<=") Simple)*
        while (try self.currentToken().kind == TokenKind.Lt or self.currentToken().kind == TokenKind.Gt or self.currentToken().kind == TokenKind.GtEq or self.currentToken().kind == TokenKind.LtEq) {
            switch (self.currentToken().kind) {
                TokenKind.Lt => {
                    // Expect <
                    const ltToken = try self.expectAndYeildToken(TokenKind.Lt);
                    const ltNode = Node{ .kind = NodeKind.LessThan, .token = ltToken };
                    try children.append(ltNode);
                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                TokenKind.Gt => {
                    // Expect >
                    const gtToken = try self.expectAndYeildToken(TokenKind.Gt);
                    const gtNode = Node{ .kind = NodeKind.GreaterThan, .token = gtToken };
                    try children.append(gtNode);

                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                TokenKind.GtEq => {
                    // Expect >=
                    const gtEqToken = try self.expectAndYeildToken(TokenKind.GtEq);
                    const gtEqNode = Node{ .kind = NodeKind.GreaterThanEq, .token = gtEqToken };
                    try children.append(gtEqNode);
                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                TokenKind.LtEq => {
                    // Expect <=
                    const ltEqToken = try self.expectAndYeildToken(TokenKind.LtEq);
                    const ltEqNode = Node{ .kind = NodeKind.LessThanEq, .token = ltEqToken };
                    try children.append(ltEqNode);
                    // Expect Simple
                    try children.append(try self.parseSimple());
                },
                else => {
                    return std.debug.panic("expected <, >, >= or <= but got {s}.\n", .{@tagName(self.currentToken())});
                },
            }
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Simple = Term (("+" | "-") Term)*
    pub fn parseSimple(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Simple\n", .{});
                std.debug.print("Defined as: Simple = Term (\"+\" | \"-\") Term)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Simple, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Term
        try children.append(try self.parseTerm());

        // Expect (("+" | "-") Term)*
        while (try self.currentToken().kind == TokenKind.Plus or self.currentToken().kind == TokenKind.Minus) {
            switch (self.currentToken().kind) {
                TokenKind.Plus => {
                    // Expect +
                    const plusToken = try self.expectAndYeildToken(TokenKind.Plus);
                    const plusNode = Node{ .kind = NodeKind.Plus, .token = plusToken };
                    try children.append(plusNode);
                    // Expect Term
                    try children.append(try self.parseTerm());
                },
                TokenKind.Minus => {
                    // Expect -
                    const minusToken = try self.expectAndYeildToken(TokenKind.Minus);
                    const minusNode = Node{ .kind = NodeKind.Minus, .token = minusToken };
                    try children.append(minusNode);
                    // Expect Term
                    try children.append(try self.parseTerm());
                },
                else => {
                    return std.debug.panic("expected + or - but got {s}\n", .{@tagName(self.currentToken())});
                },
            }
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Term = Unary (("*" | "/") Unary)*
    pub fn parseTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Term\n", .{});
                std.debug.print("Defined as: Term = Unary (\"*\" | \"/\") Unary)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Term, .token = try self.currentToken() };
        var children = std.ArrayList(Node).init(allocator);

        // Expect Unary
        try children.append(try self.parseUnary());

        // Expect (("*" | "/") Unary)*
        while (try self.currentToken().kind == TokenKind.Mul or self.currentToken().kind == TokenKind.Div) {
            switch (self.currentToken().kind) {
                TokenKind.Asterisk => {
                    // Expect *
                    const mulToken = try self.expectAndYeildToken(TokenKind.Mul);
                    const mulNode = Node{ .kind = NodeKind.Mul, .token = mulToken };
                    try children.append(mulNode);
                    // Expect Unary
                    try children.append(try self.parseUnary());
                },
                TokenKind.Slash => {
                    // Expect /
                    const divToken = try self.expectAndYeildToken(TokenKind.Div);
                    const divNode = Node{ .kind = NodeKind.Div, .token = divToken };
                    try children.append(divNode);
                    // Expect Unary
                    try children.append(try self.parseUnary());
                },
                else => {
                    return std.debug.panic("expected * or / but got {s}.\n", .{@tagName(self.currentToken())});
                },
            }
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Unary = ("!" | "-")* Selector
    pub fn parseUnary(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Unary\n", .{});
                std.debug.print("Defined as: Unary = (\"!\" | \"-\")* Selector\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Unary, .token = try self.currentToken() };
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
                    const minusToken = try self.expectAndYeildToken(TokenKind.Minus);
                    const minusNode = Node{ .kind = NodeKind.Unary, .token = minusToken };
                    try children.append(minusNode);
                },
                else => {
                    return std.debug.panic("expected ! or - but got {s}.\n", .{@tagName(self.currentToken())});
                },
            }
        }

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Selector = Factor ("." Identifier)*
    pub fn parseSelector(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Selector\n", .{});
                std.debug.print("Defined as: Selector = Factor (\".\" Identifier)*\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Selector, .token = try self.currentToken() };
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

        result.children = try children.toOwnedSlice();
        return result;
    }

    // Factor = "(" Expression ")" | Identifier (Arguments)? | Number | "true" | "false" | "new" Identifier | "null"
    pub fn parseFactor(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Factor\n", .{});
                std.debug.print("Defined as: Factor = \"(\" Expression \")\" | Identifier (Arguments)? | Number | \"true\" | \"false\" | \"new\" Identifier | \"null\"\n", .{});
            }
        }
        var result: Node = Node{ .kind = NodeKind.Factor, .token = try self.currentToken() };
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
                const numberToken = try self.expectAndYeildToken(TokenKind.Number);
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
                return std.debug.panic("expected factor but got {s}.\n", .{@tagName(self.currentToken())});
            },
        }

        result.children = try children.toOwnedSlice();
        return result;
    }
};

pub fn main() !void {
    const source = "struct TS { int a; int b; struct TS S; int int}";
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
