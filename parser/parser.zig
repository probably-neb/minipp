///////////////////////////////////////////////////////////////////////////////
/// Version 0.0: The parser was implemented but did not have nice ast
/// Version 0.1: AST will be flat array(s)
///     - NOTE: for the ones that are lists, the LHS will be the first, and the RHS will be the last
///       - Only implemented so far for NestedDecl
///     - The optionals on the AST are nice, however, I think that they should
///       be removed because they fore the use of getters and setters, so that
///       the code is not insanely long.
///       - Furthermore I do not like how the inline version panics out.
///////////////////////////////////////////////////////////////////////////////

const std = @import("std");
const lexer = @import("lexer.zig");
const Token = lexer.Token;
const Lexer = lexer.Lexer;
const TokenKind = lexer.TokenKind;

const ParserError = error{ InvalidToken, TokenIndexOutOfBounds, TokensDoNotMatch, NotEnoughTokens, NoRangeForToken, OutofBounds, OutOfMemory };

// The parser is responsible for taking the tokens and creating an abstract syntax tree
pub const NodeKind = union(enum) {
    Types,
    Program,
    Type,
    BoolType,
    IntType,
    StructType,
    Void,
    Read,
    Decl,
    NestedDecl,
    Identifier,
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
    Mul,
    Div,
    Plus,
    Minus,
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
    lhs: ?usize = null,
    rhs: ?usize = null,

    pub fn fromToken(token: Token) Node {
        const kind = switch (token.kind) {
            TokenKind.KeywordStruct => NodeKind.StructType,
            TokenKind.KeywordInt => NodeKind.IntType,
            TokenKind.KeywordBool => NodeKind.BoolType,
            TokenKind.Identifier => NodeKind.Identifier,
            TokenKind.KeywordVoid => NodeKind.Void,
            TokenKind.KeywordRead => NodeKind.Read,
            TokenKind.KeywordReturn => NodeKind.Return,
            TokenKind.KeywordDelete => NodeKind.Delete,
            TokenKind.Number => NodeKind.Number,
            TokenKind.KeywordTrue => NodeKind.True,
            TokenKind.KeywordFalse => NodeKind.False,
            TokenKind.KeywordNew => NodeKind.New,
            TokenKind.KeywordNull => NodeKind.Null,
            TokenKind.KeywordWhile => NodeKind.While,
            TokenKind.Mul => NodeKind.Mul,
            TokenKind.Div => NodeKind.Div,
            TokenKind.Plus => NodeKind.Plus,
            TokenKind.Minus => NodeKind.Minus,
            TokenKind.DoubleEq => NodeKind.Equals,
            TokenKind.NotEq => NodeKind.NotEq,
            TokenKind.Lt => NodeKind.LessThan,
            TokenKind.Gt => NodeKind.GreaterThan,
            TokenKind.LtEq => NodeKind.LessThanEq,
            TokenKind.GtEq => NodeKind.GreaterThanEq,
            TokenKind.Not => NodeKind.Not,

            else => {
                unreachable;
            },
        };
        return Node{ .kind = kind, .token = token };
    }
};

pub const Parser = struct {
    tokens: []Token,
    input: []const u8,

    ast: std.ArrayList(Node),
    astLen: usize = 0,

    pos: usize = 0,
    readPos: usize = 1,
    idMap: std.StringHashMap(bool),

    allocator: std.mem.Allocator,

    // flags
    showParseTree: bool = true,

    fn peekToken(self: *Parser) !Token {
        if (self.readPos >= self.tokens.len) return error.TokenIndexOutOfBounds;
        return self.tokens[self.readPos];
    }

    fn currentToken(self: *Parser) !Token {
        if (self.pos >= self.tokens.len) return error.TokenIndexOutOfBounds;
        return self.tokens[self.pos];
    }

    fn consumeToken(self: *Parser) !Token {
        if (self.pos >= self.tokens.len) {
            std.debug.print("Error Consuming Token: Out of bounds @ Token# {d}/{d}\n The last token was: {s}.\n", .{ self.readPos, self.tokens.len, @tagName((try self.currentToken()).kind) });
            std.debug.print("Hit EOF before expected.\n", .{});
            return error.TokenIndexOutOfBounds;
        }
        const token = self.tokens[self.pos];
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
            token._range.printLineContUnderline(self.input);
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
        const node = Node{ .kind = NodeKind.Identifier, .token = token };
        return node;
    }

    // Adds the node to the types array in the ast
    // Returns the index of the node in the types array
    pub fn astAppendNode(self: *Parser, node: Node) !usize {
        try self.ast.append(node);
        self.astLen += 1;
        return self.astLen - 1;
    }

    pub fn astAppend(self: *Parser, kind: NodeKind, token: Token) !usize {
        const node = Node{ .kind = kind, .token = token };
        return self.astAppendNode(node);
    }

    pub fn fromTypesAppend(self: *Parser, token: Token) !usize {
        const node = Node.fromToken(token);
        return self.astAppendNode(node);
    }

    pub fn parseTokens(tokens: []Token, input: []const u8, allocator: std.mem.Allocator) !Parser {
        var parser = Parser{
            .ast = try std.ArrayList(Node).initCapacity(allocator, tokens.len),
            .idMap = std.StringHashMap(bool).init(allocator),
            .tokens = tokens,
            .input = input,
            .readPos = if (tokens.len > 0) 1 else 0,
            .allocator = allocator,
        };

        try parser.parseProgram();
        return parser;
    }

    // Program = Types Declarations Functions
    // each sub function returns an u32, which is the index into the array where they start
    pub fn parseProgram(self: *Parser) !void {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Program\n", .{});
                std.debug.print("Defined as: Program = Types Declarations Functions\n", .{});
            }
        }

        // Init indexes
        var programIndex = try self.astAppend(NodeKind.Program, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Types
        lhsIndex = try self.parseTypes();

        // Expect Declarations
        rhsIndex = try self.parseDeclarations();

        // Expect Functions
        rhsIndex = try self.parseFunctions();

        // Expect EOF
        // TODO: make sure that Eof gets assigned propperly
        try self.expectToken(TokenKind.Eof);

        // assign the lhs and rhs
        self.ast.items[programIndex].lhs = lhsIndex;
        self.ast.items[programIndex].rhs = rhsIndex;
    }

    // Types = { TypeDeclaration }*
    pub fn parseTypes(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Types\n", .{});
                std.debug.print("Defined as: Types = { TypeDeclaration }*\n", .{});
            }
        }
        // Init indexes
        var typesIndex = try self.astAppend(NodeKind.Types, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // While not EOF then parse TypeDeclaration
        // Expect (TypeDeclaration)*
        while ((try self.currentToken()).kind == TokenKind.KeywordStruct) {
            if (lhsIndex == null) {
                lhsIndex = try self.parseTypeDeclaration();
            } else {
                rhsIndex = try self.parseTypeDeclaration();
            }
        }
        // assign the lhs and rhs
        self.ast.items[typesIndex].lhs = lhsIndex;
        self.ast.items[typesIndex].rhs = rhsIndex;

        return typesIndex;
    }

    // TypeDeclaration = "struct" Identifier "{" NestedDeclarations "}" ";"
    // Refactored
    pub fn parseTypeDeclaration(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a TypeDelcaration\n", .{});
                std.debug.print("Defined as: TypeDeclaration = \"struct\" Identifier {{ NestedDeclarations }} \";\"\n", .{});
            }
        }

        // Init indexes
        var typeNodeIndex = try self.astAppend(NodeKind.TypeDeclaration, try self.currentToken());

        // Exepect struct
        try self.expectToken(TokenKind.KeywordStruct);

        // Expect identifier
        const identIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect nested declarations
        const nestedDeclarationsIndex = try self.parseNestedDeclarations();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // Assign the lhs and rhs
        self.ast.items[typeNodeIndex].lhs = identIndex;
        self.ast.items[typeNodeIndex].rhs = nestedDeclarationsIndex;

        // convert to array
        return typeNodeIndex;
    }

    // NestedDecl = { Decl ";" }+
    pub fn parseNestedDeclarations(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing NestedDeclarations\n", .{});
                std.debug.print("Defined as: NestedDeclarations = {{ Decl \";\" }}+\n", .{});
            }
        }

        // Init indexes
        var nestedDeclarationsIndex = try self.astAppend(NodeKind.NestedDecl, try self.currentToken());

        // Expect { Decl ";" }+
        var declIndex = try self.parseDecl();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        var finalIndex = declIndex;
        // Repeat
        while ((try self.currentToken()).kind != TokenKind.RCurly) {
            finalIndex = try self.parseDecl();
            try self.expectToken(TokenKind.Semicolon);
        }

        // assign the lhs and rhs
        self.ast.items[nestedDeclarationsIndex].lhs = declIndex;
        self.ast.items[nestedDeclarationsIndex].rhs = finalIndex;

        return nestedDeclarationsIndex;
    }

    // Decl = Type Identifier
    pub fn parseDecl(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Decl\n", .{});
                std.debug.print("Defined as: Decl = Type Identifier\n", .{});
            }
        }
        // Init indexes
        var declIndex = try self.astAppend(NodeKind.Decl, try self.currentToken());

        // Expect Type
        const typeIndex = try self.parseType();

        // Expect Identifier
        const identIndex = try self.astAppendNode(try self.expectIdentifier());

        // assign the lhs and rhs
        self.ast.items[declIndex].lhs = typeIndex;
        self.ast.items[declIndex].rhs = identIndex;

        return declIndex;
    }

    // Type = "int" | "bool" | "struct" Identifier
    pub fn parseType(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Type\n", .{});
                std.debug.print("Defined as: Type = \"int\" | \"bool\" | \"struct\" Identifier\n", .{});
            }
        }

        // Init indexes
        var typeIndex = try self.astAppend(NodeKind.Type, try self.currentToken());
        var rhsIndex: ?usize = null;
        var lhsIndex: ?usize = null;

        const token = try self.consumeToken();

        // Expect int | bool | struct (id)
        switch (token.kind) {
            TokenKind.KeywordInt => {
                lhsIndex = try self.astAppend(NodeKind.IntType, token);
            },
            TokenKind.KeywordBool => {
                lhsIndex = try self.astAppend(NodeKind.BoolType, token);
            },
            TokenKind.KeywordStruct => {
                lhsIndex = try self.astAppend(NodeKind.StructType, token);
                rhsIndex = try self.astAppendNode(try self.expectIdentifier());
            },
            else => {
                // TODO: make this error like the others
                std.debug.print("Error invalid Token: expected token kind {s} | {s} | {s} but got {s}.\n", .{ @tagName(TokenKind.KeywordInt), @tagName(TokenKind.KeywordBool), @tagName(TokenKind.KeywordStruct), @tagName(token.kind) });
                const line: []const u8 = token._range.getLineCont(self.input);
                std.debug.print("{s}\n", .{line});
                token._range.printLineContUnderline(self.input);
                return error.InvalidToken;
            },
        }
        // assign the lhs and rhs
        self.ast.items[typeIndex].rhs = rhsIndex;
        self.ast.items[typeIndex].lhs = lhsIndex;

        return typeIndex;
    }

    pub fn isCurrentTokenAType(self: *Parser) !bool {
        switch ((try self.currentToken()).kind) {
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
        // Init indexes
        var declarationsIndex = try self.astAppend(NodeKind.Declarations, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // While not EOF or function keyword then parse declaration
        // Expect (Declaration)*
        if (try self.isCurrentTokenAType()) {
            lhsIndex = try self.parseDeclaration();
        }
        while (try self.isCurrentTokenAType()) {
            // Expect Declaration
            rhsIndex = try self.parseDeclaration();
        }

        // assign the lhs and rhs
        self.ast.items[declarationsIndex].lhs = lhsIndex;
        self.ast.items[declarationsIndex].rhs = rhsIndex;
    }

    // Declaration = Type Identifier ("," Identifier)* ";"
    pub fn parseDeclaration(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Declaration\n", .{});
                std.debug.print("Defined as: Declaration = Type Identifier (\",\" Identifier)* \";\"\n", .{});
            }
        }
        // Init indexes
        var declarationIndex = try self.astAppend(NodeKind.Declaration, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect type
        lhsIndex = try self.parseType();

        // Expect Identifier
        rhsIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect ("," Identifier)* ";"
        while ((try self.currentToken()).kind != TokenKind.Semicolon) {
            // Expect ,
            try self.expectToken(TokenKind.Comma);
            // Expect Identifier
            rhsIndex = try self.astAppendNode(try self.expectIdentifier());
            // Repeat
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // assign the lhs and rhs
        self.ast.items[declarationIndex].lhs = lhsIndex;
        self.ast.items[declarationIndex].rhs = rhsIndex;

        return declarationIndex;
    }

    // Functions = ( Function )*
    pub fn parseFunctions(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Functions\n", .{});
                std.debug.print("Defined as: Functions = ( Function )*\n", .{});
            }
        }
        // init indexes
        var functionsIndex = try self.astAppend(NodeKind.Functions, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // While not EOF then parse function
        // Expect (Function)*
        while ((try self.currentToken()).kind == TokenKind.KeywordFun) {
            if (lhsIndex == null) {
                lhsIndex = try self.parseFunction();
            } else {
                rhsIndex = try self.parseFunction();
            }
        }

        // assign the lhs and rhs
        self.ast.items[functionsIndex].lhs = lhsIndex;
        self.ast.items[functionsIndex].rhs = rhsIndex;

        return functionsIndex;
    }

    // Function = "fun" Identifier Paramaters ReturnType "{" Declarations StatementList "}"
    pub fn parseFunction(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Function\n", .{});
                std.debug.print("Defined as: Function = \"fun\" Identifier Paramaters ReturnType \"{{\" Declarations StatementList \"}}\"\n", .{});
            }
        }
        // Init indexes
        var functionIndex = try self.astAppend(NodeKind.Function, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect fun
        try self.expectToken(TokenKind.KeywordFun);

        // Expect Identifier
        lhsIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect Parameters
        rhsIndex = try self.parseParameters();

        // Expect ReturnType
        rhsIndex = try self.parseReturnType();

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect Declarations
        rhsIndex = try self.parseDeclarations();

        // Expect StatementList
        rhsIndex = try self.parseStatementList();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        // assign the lhs and rhs
        self.ast.items[functionIndex].lhs = lhsIndex;
        self.ast.items[functionIndex].rhs = rhsIndex;
    }

    // Parameters = "(" (Decl ("," Decl)* )? ")"
    pub fn parseParameters(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Parameters\n", .{});
                std.debug.print("Defined as: Parameters = \"(\" (Decl (\",\" Decl)* )? \")\"\n", .{});
            }
        }
        // Init indexes
        var parametersIndex = try self.astAppend(NodeKind.Parameters, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect (
        try self.expectToken(TokenKind.LParen);

        while (try self.isCurrentTokenAType()) {
            // Expect Decl
            lhsIndex = try self.parseDecl();
            // Expect ("," Decl)*

            while ((try self.currentToken()).kind == TokenKind.Comma) {
                // Expect ,
                try self.expectToken(TokenKind.Comma);
                // Expect Decl
                rhsIndex = try self.parseDecl();
            }
        }

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // assign the lhs and rhs
        self.ast.items[parametersIndex].lhs = lhsIndex;
        self.ast.items[parametersIndex].rhs = rhsIndex;
    }

    // ReturnType = Type | "void"
    pub fn parseReturnType(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing ReturnType\n", .{});
                std.debug.print("Defined as: ReturnType = Type | \"void\"\n", .{});
            }
        }
        // Init indexes
        var returnTypeIndex = try self.astAppend(NodeKind.ReturnType, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Token to switch on
        const token = try self.currentToken();
        switch (token.kind) {
            TokenKind.KeywordVoid => {
                lhsIndex = try self.astAppend(NodeKind.Void, token);
            },
            else => {
                if (lhsIndex == null) {
                    lhsIndex = try self.parseType();
                } else {
                    rhsIndex = try self.parseType();
                }
            },
        }

        // assign the lhs and rhs
        self.ast.items[returnTypeIndex].lhs = lhsIndex;
        self.ast.items[returnTypeIndex].rhs = rhsIndex;

        return returnTypeIndex;
    }

    // Statement = Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation
    pub fn parseStatement(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Statement\n", .{});
                std.debug.print("Defined as: Statement = Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation\n", .{});
            }
        }
        // Init indexes
        var statementIndex = try self.astAppend(NodeKind.Statement, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        const token = try self.currentToken();
        switch (token.kind) {
            // Block
            TokenKind.LCurly => {
                lhsIndex = try self.parseBlock();
            },
            // Invocation | Assignment
            TokenKind.Identifier => {
                switch ((try self.peekToken()).kind) {
                    TokenKind.LParen => {
                        lhsIndex = try self.parseInvocation();
                    },
                    else => {
                        lhsIndex = try self.parseAssignment();
                    },
                }
            },
            // ConditionalIf | ConditionalIfElse
            TokenKind.KeywordIf => {
                lhsIndex = try self.parseConditionals();
            },
            // While
            TokenKind.KeywordWhile => {
                lhsIndex = try self.parseWhile();
            },
            // Delete
            TokenKind.KeywordDelete => {
                lhsIndex = try self.parseDelete();
            },
            // Return
            TokenKind.KeywordReturn => {
                lhsIndex = try self.parseReturn();
            },
            // Print | PrintLn
            TokenKind.KeywordPrint => {
                lhsIndex = try self.parsePrints();
            },
            else => {
                // TODO: make this error like the others
                // TOOD: really actually tho
                std.debug.print("Error invalid Token: expected token kind of Statment \n", .{});
                const line: []const u8 = (try self.currentToken())._range.getLineCont(self.input);
                std.debug.print("{s}\n", .{line});
                (try self.currentToken())._range.printLineContUnderline(self.input);
                return error.InvalidToken;
            },
        }

        // assign the lhs and rhs
        self.ast.items[statementIndex].lhs = lhsIndex;
        self.ast.items[statementIndex].rhs = rhsIndex;
    }

    // StatementList = ( Statement )*
    pub fn parseStatementList(self: *Parser) ParserError!Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a StatementList\n", .{});
                std.debug.print("Defined as: StatementList = ( Statement )*\n", .{});
            }
        }
        // Init indexes
        var statementListIndex = try self.astAppend(NodeKind.StatementList, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // While not EOF then parse statement
        // Expect (Statement)*
        while ((try self.currentToken()).kind != TokenKind.RCurly) {
            if (lhsIndex == null) {
                lhsIndex = try self.parseStatement();
            } else {
                rhsIndex = try self.parseStatement();
            }
        }

        // assign the lhs and rhs
        self.ast.items[statementListIndex].lhs = lhsIndex;
        self.ast.items[statementListIndex].rhs = rhsIndex;

        return statementListIndex;
    }

    // Block = "{" StatementList "}"
    pub fn parseBlock(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Block\n", .{});
                std.debug.print("Defined as: Block = \"{{\" StatementList \"}}\"\n", .{});
            }
        }
        // Init indexes
        var blockIndex = try self.astAppend(NodeKind.Block, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect StatementList
        lhsIndex = try self.parseStatementList();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        // assign the lhs and rhs
        self.ast.items[blockIndex].lhs = lhsIndex;
        self.ast.items[blockIndex].rhs = rhsIndex;

        return blockIndex;
    }

    // Assignment = LValue = (Expression | "read") ";"
    pub fn parseAssignment(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Assignment\n", .{});
                std.debug.print("Defined as: Assignment = LValue = (Expression | \"read\") \";\"\n", .{});
            }
        }
        // Init indexes
        var assignmentIndex = try self.astAppend(NodeKind.Assignment, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect LValue
        lhsIndex = try self.parseLValue();

        // Expect =
        try self.expectToken(TokenKind.Eq);

        // Expect Expression | "read"
        if ((try self.currentToken()).kind == TokenKind.KeywordRead) {
            // make read node
            rhsIndex = try self.astAppend(NodeKind.Read, try self.consumeToken());
        } else {
            // make expression node
            rhsIndex = try self.parseExpression();
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // assign the lhs and rhs
        self.ast.items[assignmentIndex].lhs = lhsIndex;
        self.ast.items[assignmentIndex].rhs = rhsIndex;
        return assignmentIndex;
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
        // Init indexes
        var printIndex = try self.astAppend(NodeKind.Print, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect print
        try self.expectToken(TokenKind.KeywordPrint);

        // Expect Expression
        lhsIndex = try self.parseExpression();

        switch ((try self.currentToken()).kind) {
            // Expect ;
            TokenKind.Semicolon => {
                try self.expectToken(TokenKind.Semicolon);
                self.ast.items[printIndex].kind = NodeKind.Print;
            },
            // Expect endl ;
            TokenKind.KeywordEndl => {
                try self.expectToken(TokenKind.KeywordEndl);
                try self.expectToken(TokenKind.Semicolon);
                self.ast.items[printIndex].kind = NodeKind.PrintLn;
            },
            else => {
                return std.debug.panic("expected ; or endl but got {s}.", .{@tagName((try self.currentToken()).kind)});
            },
        }

        // assign the lhs and rhs
        self.ast.items[printIndex].lhs = lhsIndex;
        self.ast.items[printIndex].rhs = rhsIndex;
        return printIndex;
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
        // Init indexes
        var conditionalIndex = try self.astAppend(NodeKind.ConditionalIf, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect if
        try self.expectToken(TokenKind.KeywordIf);

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // Expect Expression
        lhsIndex = try self.parseExpression();

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // Expect Block
        rhsIndex = try self.parseBlock();

        // If else then parse else block
        if ((try self.currentToken()).kind == TokenKind.KeywordElse) {
            // Expect else
            try self.expectToken(TokenKind.KeywordElse);
            // Expect Block
            rhsIndex = try self.parseBlock();
            self.ast.items[conditionalIndex].kind = NodeKind.ConditionalIfElse;
        }

        // assign the lhs and rhs
        self.ast.items[conditionalIndex].lhs = lhsIndex;
        self.ast.items[conditionalIndex].rhs = rhsIndex;

        return conditionalIndex;
    }

    // While = "while" "(" Expression ")" Block
    pub fn parseWhile(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a While\n", .{});
                std.debug.print("Defined as: While = \"while\" \"(\" Expression \")\" Block\n", .{});
            }
        }
        // Init indexes
        var whileIndex = try self.astAppend(NodeKind.While, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect while
        try self.expectToken(TokenKind.KeywordWhile);

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // Expect Expression
        lhsIndex = try self.parseExpression();

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // Expect Block
        rhsIndex = try self.parseBlock();

        // assign the lhs and rhs
        self.ast.items[whileIndex].lhs = lhsIndex;
        self.ast.items[whileIndex].rhs = rhsIndex;

        return whileIndex;
    }

    // Delete = "delete" Expression ";"
    pub fn parseDelete(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Delete\n", .{});
                std.debug.print("Defined as: Delete = \"delete\" Expression \";\"\n", .{});
            }
        }
        // Init indexes
        var deleteIndex = try self.astAppend(NodeKind.Delete, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect delete
        try self.expectToken(TokenKind.KeywordDelete);

        // Expect Expression
        lhsIndex = try self.parseExpression();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // assign the lhs and rhs
        self.ast.items[deleteIndex].lhs = lhsIndex;
        self.ast.items[deleteIndex].rhs = rhsIndex;

        return deleteIndex;
    }

    // Return = "return" (Expression)?  ";"
    pub fn parseReturn(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Return\n", .{});
                std.debug.print("Defined as: Return = \"return\" (Expression)?  \";\"\n", .{});
            }
        }
        // Init indexes
        var returnIndex = try self.astAppend(NodeKind.Return, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect return
        try self.expectToken(TokenKind.KeywordReturn);

        // Expect Expression optionally
        if ((try self.currentToken()).kind != TokenKind.Semicolon) {
            // Expect Expression
            lhsIndex = try self.parseExpression();
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // assign the lhs and rhs
        self.ast.items[returnIndex].lhs = lhsIndex;
        self.ast.items[returnIndex].rhs = rhsIndex;

        return returnIndex;
    }

    // Invocation = Identifier Arguments ";"
    pub fn parseInvocation(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Identifier\n", .{});
                std.debug.print("Defined as: Invocation = Identifier Arguments \";\"\n", .{});
            }
        }
        // Init indexes
        var invocationIndex = try self.astAppend(NodeKind.Invocation, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Identifier
        lhsIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect Arguments
        rhsIndex = try self.parseArguments();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // assign the lhs and rhs
        self.ast.items[invocationIndex].lhs = lhsIndex;
        self.ast.items[invocationIndex].rhs = rhsIndex;

        return invocationIndex;
    }

    // LValue = Identifier ("." Identifier)*
    pub fn parseLValue(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an LValue\n", .{});
                std.debug.print("Defined as: LValue = Identifier (\".\" Identifier)*\n", .{});
            }
        }
        // Init indexes
        var lValueIndex = try self.astAppend(NodeKind.LValue, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Identifier
        lhsIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect ("." Identifier)*
        while ((try self.currentToken()).kind == TokenKind.Dot) {
            // Expect .
            try self.expectToken(TokenKind.Dot);
            // Expect Identifier
            rhsIndex = try self.astAppendNode(try self.expectIdentifier());
        }

        // assign the lhs and rhs
        self.ast.items[lValueIndex].lhs = lhsIndex;
        self.ast.items[lValueIndex].rhs = rhsIndex;

        return lValueIndex;
    }

    /////////// UNTOUCHED TO REFACTOR ////////////////////////
    // Expression = BoolTerm ("||" BoolTerm)*
    pub fn parseExpression(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Expression\n", .{});
                std.debug.print("Defined as: Expression = BoolTerm (\"||\" BoolTerm)*\n", .{});
            }
        }
        // Init indexes
        var expressionIndex = try self.astAppend(NodeKind.Expression, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect BoolTerm
        lhsIndex = try self.parseBoolTerm();

        // Expect ("||" BoolTerm)*
        while ((try self.currentToken()).kind == TokenKind.Or) {
            // Expect ||
            try self.expectToken(TokenKind.Or);
            // Expect BoolTerm
            rhsIndex = try self.parseBoolTerm();
        }

        // assign the lhs and rhs
        self.ast.items[expressionIndex].lhs = lhsIndex;
        self.ast.items[expressionIndex].rhs = rhsIndex;

        return expressionIndex;
    }

    // Boolterm = EqTerm ("&&" EqTerm)*
    pub fn parseBoolTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a BoolTerm\n", .{});
                std.debug.print("Defined as: Boolterm = EqTerm (\"&&\" EqTerm)*\n", .{});
            }
        }
        // Init indexes
        var boolTermIndex = try self.astAppend(NodeKind.BoolTerm, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect EqTerm
        lhsIndex = try self.parseEqTerm();

        // Expect ("&&" EqTerm)*
        while ((try self.currentToken()).kind == TokenKind.And) {
            // Expect &&
            try self.expectToken(TokenKind.And);
            // Expect EqTerm
            rhsIndex = try self.parseEqTerm();
        }

        // assign the lhs and rhs
        self.ast.items[boolTermIndex].lhs = lhsIndex;
        self.ast.items[boolTermIndex].rhs = rhsIndex;

        return boolTermIndex;
    }

    // EqTerm = RelTerm (("==" | "!=") RelTerm)*
    pub fn parseEqTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an EqTerm\n", .{});
                std.debug.print("Defined as: EqTerm = RelTerm (\"==\" | \"!=\") RelTerm)*\n", .{});
            }
        }
        // Init indexes
        var eqTermIndex = try self.astAppend(NodeKind.EqTerm, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect RelTerm
        lhsIndex = try self.parseRelTerm();

        // Expect (("==" | "!=") RelTerm)*
        while ((try self.currentToken()).kind == TokenKind.DoubleEq or (try self.currentToken()).kind == TokenKind.NotEq) {
            switch ((try self.currentToken()).kind) {
                TokenKind.NotEq => {
                    // Expect !=
                    const notEqToken = try self.expectAndYeildToken(TokenKind.NotEq);
                    const notEqNode = Node{ .kind = NodeKind.NotEq, .token = notEqToken };
                    rhsIndex = try self.astAppendNode(notEqNode);
                    // Expect RelTerm
                    rhsIndex = try self.parseRelTerm();
                },
                TokenKind.DoubleEq => {
                    // Expect ==
                    const eqToken = try self.expectAndYeildToken(TokenKind.DoubleEq);
                    const eqNode = Node{ .kind = NodeKind.Equals, .token = eqToken };
                    rhsIndex = try self.astAppendNode(eqNode);
                    // Expect RelTerm
                    rhsIndex = try self.parseRelTerm();
                },
                else => {
                    // TODO: make this error like the others
                    return std.debug.panic("expected == or != but got {s}.\n", .{@tagName((try self.currentToken()).kind)});
                },
            }
        }

        // assign the lhs and rhs
        self.ast.items[eqTermIndex].lhs = lhsIndex;
        self.ast.items[eqTermIndex].rhs = rhsIndex;
    }

    // RelTerm = Simple (("<" | ">" | ">=" | "<=") Simple)*
    pub fn parseRelTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a RelTerm\n", .{});
                std.debug.print("Defined as: RelTerm = Simple (\"<\" | \">\" | \">=\" | \"<=\") Simple)*\n", .{});
            }
        }
        // Init indexes
        var relTermIndex = try self.astAppend(NodeKind.RelTerm, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Simple
        lhsIndex = try self.parseSimple();

        // Expect (("<" | ">" | ">=" | "<=") Simple)*
        while ((try self.currentToken()).kind == TokenKind.Lt or (try self.currentToken()).kind == TokenKind.Gt or (try self.currentToken()).kind == TokenKind.GtEq or (try self.currentToken()).kind == TokenKind.LtEq) {
            switch ((try self.currentToken()).kind) {
                TokenKind.Lt => {
                    // Expect <
                    const ltToken = try self.expectAndYeildToken(TokenKind.Lt);
                    const ltNode = Node{ .kind = NodeKind.LessThan, .token = ltToken };
                    rhsIndex = try self.astAppendNode(ltNode);
                    // Expect Simple
                    rhsIndex = try self.parseSimple();
                },
                TokenKind.Gt => {
                    // Expect >
                    const gtToken = try self.expectAndYeildToken(TokenKind.Gt);
                    const gtNode = Node{ .kind = NodeKind.GreaterThan, .token = gtToken };
                    rhsIndex = try self.astAppendNode(gtNode);

                    // Expect Simple
                    rhsIndex = try self.parseSimple();
                },
                TokenKind.GtEq => {
                    // Expect >=
                    const gtEqToken = try self.expectAndYeildToken(TokenKind.GtEq);
                    const gtEqNode = Node{ .kind = NodeKind.GreaterThanEq, .token = gtEqToken };
                    rhsIndex = try self.astAppendNode(gtEqNode);
                    // Expect Simple
                    rhsIndex = try self.parseSimple();
                },
                TokenKind.LtEq => {
                    // Expect <=
                    const ltEqToken = try self.expectAndYeildToken(TokenKind.LtEq);
                    const ltEqNode = Node{ .kind = NodeKind.LessThanEq, .token = ltEqToken };
                    rhsIndex = try self.astAppendNode(ltEqNode);

                    // Expect Simple
                    rhsIndex = try self.parseSimple();
                },
                else => {
                    // TODO: make this error like the others
                    return std.debug.panic("expected <, >, >= or <= but got {s}.\n", .{@tagName((try self.currentToken()).kind)});
                },
            }
        }

        // assign the lhs and rhs
        self.ast.items[relTermIndex].lhs = lhsIndex;
        self.ast.items[relTermIndex].rhs = rhsIndex;

        return relTermIndex;
    }

    // Simple = Term (("+" | "-") Term)*
    pub fn parseSimple(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Simple\n", .{});
                std.debug.print("Defined as: Simple = Term (\"+\" | \"-\") Term)*\n", .{});
            }
        }
        // Init indexes
        var simpleIndex = try self.astAppend(NodeKind.Simple, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Term
        lhsIndex = try self.parseTerm();

        // Expect (("+" | "-") Term)*
        while ((try self.currentToken()).kind == TokenKind.Plus or (try self.currentToken()).kind == TokenKind.Minus) {
            switch ((try self.currentToken()).kind) {
                TokenKind.Plus => {
                    // Expect +
                    const plusToken = try self.expectAndYeildToken(TokenKind.Plus);
                    const plusNode = Node{ .kind = NodeKind.Plus, .token = plusToken };
                    rhsIndex = try self.astAppendNode(plusNode);
                    // Expect Term
                    rhsIndex = try self.parseTerm();
                },
                TokenKind.Minus => {
                    // Expect -
                    const minusToken = try self.expectAndYeildToken(TokenKind.Minus);
                    const minusNode = Node{ .kind = NodeKind.Minus, .token = minusToken };
                    rhsIndex = try self.astAppendNode(minusNode);
                    // Expect Term
                    rhsIndex = try self.parseTerm();
                },
                else => {
                    // TODO: make this error like the others
                    return std.debug.panic("expected + or - but got {s}\n", .{@tagName((try self.currentToken()).kind)});
                },
            }
        }

        // assign the lhs and rhs
        self.ast.items[simpleIndex].lhs = lhsIndex;
        self.ast.items[simpleIndex].rhs = rhsIndex;

        return simpleIndex;
    }

    // Term = Unary (("*" | "/") Unary)*
    pub fn parseTerm(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Term\n", .{});
                std.debug.print("Defined as: Term = Unary (\"*\" | \"/\") Unary)*\n", .{});
            }
        }
        // Init indexes
        var termIndex = try self.astAppend(NodeKind.Term, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Unary
        lhsIndex = try self.parseUnary();

        // Expect (("*" | "/") Unary)*
        while ((try self.currentToken()).kind == TokenKind.Mul or (try self.currentToken()).kind == TokenKind.Div) {
            switch ((try self.currentToken()).kind) {
                TokenKind.Mul => {
                    // Expect *
                    const mulToken = try self.expectAndYeildToken(TokenKind.Mul);
                    const mulNode = Node{ .kind = NodeKind.Mul, .token = mulToken };
                    rhsIndex = try self.astAppendNode(mulNode);
                    // Expect Unary
                    rhsIndex = try self.parseUnary();
                },
                TokenKind.Div => {
                    // Expect /
                    const divToken = try self.expectAndYeildToken(TokenKind.Div);
                    const divNode = Node{ .kind = NodeKind.Div, .token = divToken };
                    rhsIndex = try self.astAppendNode(divNode);
                    // Expect Unary
                    rhsIndex = try self.parseUnary();
                },
                else => {
                    // TODO: make this error look like the others
                    return std.debug.panic("expected * or / but got {s}.\n", .{@tagName((try self.currentToken()).kind)});
                },
            }
        }
        // assign the lhs and rhs
        self.ast.items[termIndex].lhs = lhsIndex;
        self.ast.items[termIndex].rhs = rhsIndex;

        return termIndex;
    }

    // Unary = ("!" | "-")* Selector
    pub fn parseUnary(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Unary\n", .{});
                std.debug.print("Defined as: Unary = (\"!\" | \"-\")* Selector\n", .{});
            }
        }
        // Init indexes
        var unaryIndex = try self.astAppend(NodeKind.Unary, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect ("!" | "-")*
        while ((try self.currentToken()).kind == TokenKind.Not or (try self.currentToken()).kind == TokenKind.Minus) {
            switch ((try self.currentToken()).kind) {
                TokenKind.Not => {
                    // Expect !
                    const notToken = try self.expectAndYeildToken(TokenKind.Not);
                    const notNode = Node{ .kind = NodeKind.Not, .token = notToken };
                    lhsIndex = try self.astAppendNode(notNode);
                },
                TokenKind.Minus => {
                    // Expect -
                    const minusToken = try self.expectAndYeildToken(TokenKind.Minus);
                    const minusNode = Node{ .kind = NodeKind.Unary, .token = minusToken };
                    lhsIndex = try self.astAppendNode(minusNode);
                },
                else => {
                    // TODO: make this error like the others
                    return std.debug.panic("expected ! or - but got {s}.\n", .{@tagName((try self.currentToken()).kind)});
                },
            }
        }

        // TODO: check that this is right
        // Expect Selector
        rhsIndex = try self.parseSelector();

        // assign the lhs and rhs
        self.ast.items[unaryIndex].lhs = lhsIndex;
        self.ast.items[unaryIndex].rhs = rhsIndex;

        return unaryIndex;
    }

    // Selector = Factor ("." Identifier)*
    pub fn parseSelector(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Selector\n", .{});
                std.debug.print("Defined as: Selector = Factor (\".\" Identifier)*\n", .{});
            }
        }
        // Init indexes
        var selectorIndex = try self.astAppend(NodeKind.Selector, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Factor
        lhsIndex = try self.parseFactor();

        // Expect ("." Identifier)*
        while ((try self.currentToken()).kind == TokenKind.Dot) {
            // Expect .
            try self.expectToken(TokenKind.Dot);
            // Expect Identifier
            rhsIndex = try self.astAppendNode(try self.expectIdentifier());
        }

        // assign the lhs and rhs
        self.ast.items[selectorIndex].lhs = lhsIndex;
        self.ast.items[selectorIndex].rhs = rhsIndex;

        return selectorIndex;
    }

    // Factor = "(" Expression ")" | Identifier (Arguments)? | Number | "true" | "false" | "new" Identifier | "null"
    pub fn parseFactor(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Factor\n", .{});
                std.debug.print("Defined as: Factor = \"(\" Expression \")\" | Identifier (Arguments)? | Number | \"true\" | \"false\" | \"new\" Identifier | \"null\"\n", .{});
            }
        }
        // Init indexes
        var factorIndex = try self.astAppend(NodeKind.Factor, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        const token = try self.currentToken();
        switch (token.kind) {
            TokenKind.LParen => {
                // Expect (
                try self.expectToken(TokenKind.LParen);
                // Expect Expression
                lhsIndex = try self.parseExpression();
                // Expect )
                try self.expectToken(TokenKind.RParen);
            },
            TokenKind.Identifier => {
                // Expect Identifier
                lhsIndex = try self.astAppendNode(try self.expectIdentifier());
                // Expect (Arguments)?
                if ((try self.currentToken()).kind == TokenKind.LParen) {
                    // Expect Arguments
                    rhsIndex = try self.parseArguments();
                }
            },
            // Theese could all be refactored into a helper function
            // TODO: check that this works
            TokenKind.Number, TokenKind.KeywordTrue, TokenKind.KeywordFalse, TokenKind.KeywordNull => {
                try self.consumeToken();
                try self.fromTypesAppend(token);
            },
            TokenKind.KeywordNew => {
                // Expect new
                const newToken = try self.consumeToken();
                const newNode = Node{ .kind = NodeKind.New, .token = newToken };
                lhsIndex = try self.astAppendNode(newNode);

                // Expect Identifier
                rhsIndex = try self.astAppendNode(try self.expectIdentifier());
            },
            else => {
                // TODO: make this error like the others
                return std.debug.panic("expected factor but got {s}.\n", .{@tagName((try self.currentToken()).kind)});
            },
        }
        // assign the lhs and rhs
        self.ast.items[factorIndex].lhs = lhsIndex;
        self.ast.items[factorIndex].rhs = rhsIndex;

        return factorIndex;
    }

    // Arguments = "(" (Expression ("," Expression)*)? ")"
    pub fn parseArguments(self: *Parser) !Node {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Arguments\n", .{});
                std.debug.print("Defined as: Arguments = \"(\" (Expression (\",\" Expression)*)? \")\"\n", .{});
            }
        }
        // Init indexes
        var argumentsIndex = try self.astAppend(NodeKind.Arguments, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // Expect (Expression ("," Expression)*)?
        if ((try self.currentToken()).kind != TokenKind.RParen) {
            // Expect Expression
            lhsIndex = try self.parseExpression();

            // Expect ("," Expression)*
            while ((try self.currentToken()).kind == TokenKind.Comma) {
                // Expect ,
                try self.expectToken(TokenKind.Comma);
                // Expect Expression
                rhsIndex = try self.parseExpression();
            }
        }

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // assign the lhs and rhs
        self.ast.items[argumentsIndex].lhs = lhsIndex;
        self.ast.itemsl[argumentsIndex].rhs = rhsIndex;

        return argumentsIndex;
    }
};

pub fn main() !void {
    const source = "struct test{ int a; };";
    const tokens = try Lexer.tokenizeFromStr(source);
    const parser = try Parser.parseTokens(tokens, source, std.heap.page_allocator);
    std.debug.print("Parsed successfully\n", .{});
    std.debug.print("{any}\n", .{parser});
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// Tests
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

test "no_identifier_struct" {
    const source = "struct { int a; int b; struct TS S; };";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "no_keyword_struct" {
    const source = "TS{ int a; int b; struct TS S; };";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "no_members_struct" {
    const source = "struct TS { };";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "no_semicolon_struct_end" {
    const source = "struct TS { int a int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "no_semicolon_struct_member" {
    const source = "struct TS { int a; int b; struct TS S };";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "no_struct_function" {
    const source = "fun TS() void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source);
    _ = try Parser.parseTokens(tokens, source);
}

test "function_no_identifier" {
    const source = "fun () void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "function_no_parameters" {
    const source = "fun TS void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "function_no_return_type" {
    const source = "fun TS() { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}

test "function_no_lcurly" {
    const source = "fun TS() void int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source));
}
