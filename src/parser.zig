///////////////////////////////////////////////////////////////////////////////
/// Version 0.0: The parser was implemented but did not have nice ast
/// Version 0.1: AST will be flat array(s)
///     - NOTE: for the ones that are lists, the LHS will be the first, and the RHS will be the last
///       - Only implemented so far for NestedDecl
///     - The optionals on the AST are nice, however, I think that they should
///       be removed because they fore the use of getters and setters, so that
///       the code is not insanely long.
///       - Furthermore I do not like how the inline version panics out.
/// Version 0.2: The AST is now a flat array.
///    - NOTE: right now the tree down to a type is made, I think this should be
///            removed such that it is only the thing is there.
///      - Example:
///       Assignment: d
///       LValue: d
///       Identifier: d
///       Expression: 5
///       BackfillReserve: 5
///       BoolTerm: 5
///       BackfillReserve: 5
///       EqTerm: 5
///       BackfillReserve: 5
///       RelTerm: 5
///       BackfillReserve: 5
///       Simple: 5
///       BackfillReserve: 5
///       Term: 5
///       BackfillReserve: 5
///       Unary: 5
///       BackfillReserve: 5
///       Selector: 5
///       Factor: 5
///       Number: 5
///     Should be able to rectify down to its actual state without the endless chains
///
///
///////////////////////////////////////////////////////////////////////////////

const std = @import("std");
const lexer = @import("lexer.zig");
const Token = lexer.Token;
const Lexer = lexer.Lexer;
const TokenKind = lexer.TokenKind;

const Node = @import("ast.zig").Node;
const NodeKind = Node.Kind;
const NodeLIst = @import("ast.zig").NodeList;

const utils = @import("utils.zig");

const ParserError = error{ InvalidToken, TokenIndexOutOfBounds, TokensDoNotMatch, NotEnoughTokens, NoRangeForToken, OutofBounds, OutOfMemory };

/// A parser is responsible for taking the tokens and creating an abstract syntax tree.
/// The resulting ast is a flat array of nodes.
/// To deinit the parser call the `deinit` member function.
/// Reccomended usage:
/// ```zig
/// cosnt tokens = try Lexer.tokenize(input, file_name, allocator);
/// const parser = try Parser.parseTokens(tokens, input, allocator);
/// defer parser.deinit();
/// ```
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
    showParseTree: bool = false,

    fn deinit(self: *Parser) void {
        self.allocator.free(self.tokens);
        self.ast.deinit();
        self.idMap.deinit();
    }
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
        const node = Node{ .kind = NodeKind{ .Identifier = .{} }, .token = token };
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

        parser.parseProgram() catch |err| {
            std.debug.print("Error in parsing the program.\n", .{});
            parser.deinit();
            return err;
        };
        return parser;
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

    pub fn prettyPrintAst(self: *const Parser) !void {
        const ast = self.ast.items;
        var i: usize = 0;
        std.debug.print("AST:{{\n", .{});
        while (i < self.astLen) {
            const node = ast[i];
            const token = node.token;
            const tokenStr = token._range.getSubStrFromStr(self.input);
            const kind = @tagName(node.kind);
            std.debug.print("{s}: {s}\n", .{ kind, tokenStr });
            i += 1;
        }
        std.debug.print("}}\n", .{});
    }

    /// reserves a location using the BackFillReserve Node
    /// NOTE: does not call any token consuming functions, expects
    /// the caller to handle tokens
    fn reserve(self: *Parser) !usize {
        const index = self.astLen;
        try self.ast.append(Node{ .kind = NodeKind{ .BackfillReserve = .{} }, .token = undefined });
        self.astLen += 1;
        return index;
    }

    fn set(self: *Parser, at: usize, node: Node) !void {
        try utils.assert(at < self.astLen, "tried to set a node out of bounds: astLen = {d}, your mistake = {d}", .{ at, self.astLen });
        self.ast.items[at] = node;
    }

    ///////////////////////////////////////////////////////////////////////////
    /// Parser Grammar Functions
    ///////////////////////////////////////////////////////////////////////////

    // Program = Types Declarations Functions
    // each sub function returns an u32, which is the index into the array where they start
    pub fn parseProgram(self: *Parser) !void {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Program\n", .{});
                std.debug.print("Defined as: Program = Types Declarations Functions\n", .{});
            }
        }

        var progToken = try self.currentToken();
        // Init indexes
        var programIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Types
        lhsIndex = try self.parseTypes();

        // Expect Declarations
        rhsIndex = try self.parseDeclarations();

        // Expect Functions
        if (try self.parseFunctions()) |rhs| {
            // only update rhs if there were functions...
            rhsIndex = rhs;
        }

        // Expect EOF
        // TODO: make sure that Eof gets assigned propperly
        try self.expectToken(TokenKind.Eof);

        const progNode = Node{ .kind = NodeKind.Program{ .lhs = lhsIndex, .rhs = rhsIndex }, .token = progToken, .lhs = lhsIndex, .rhs = rhsIndex };
        try self.set(programIndex, progNode);
    }

    // Types = { TypeDeclaration }*
    pub fn parseTypes(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing Types\n", .{});
                std.debug.print("Defined as: Types = {{ TypeDeclaration }}*\n", .{});
            }
        }
        // Init indexes
        const typesToken = try self.currentToken();
        var typesIndex = try self.reserve();
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
        const node = Node{ .kind = NodeKind{ .Types = .{ .lhs = lhsIndex, .rhs = rhsIndex }, .token = typesToken } };
        try self.set(typesIndex, node);

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
        const tok = try self.currentToken();
        var typeNodeIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Exepect struct
        try self.expectToken(TokenKind.KeywordStruct);

        // Expect identifier
        lhsIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect nested declarations
        rhsIndex = try self.parseNestedDeclarations();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .TypeDeclaration = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };

        try self.set(typeNodeIndex, node);

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
        const tok = try self.currentToken();
        var nestedDeclarationsIndex = try self.reserve();
        // var nestedDeclarationsIndex = try self.astAppend(, try self.currentToken());
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect { Decl ";" }+
        lhsIndex = try self.parseDecl();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // Repeat
        while ((try self.currentToken()).kind != TokenKind.RCurly) {
            rhsIndex = try self.parseDecl();
            try self.expectToken(TokenKind.Semicolon);
        }

        const node = Node{ .kind = NodeKind.NestedDecls{ .lhs = lhsIndex, .rhs = rhsIndex }, .token = tok, .lhs = lhsIndex, .rhs = rhsIndex };

        try self.set(nestedDeclarationsIndex, node);

        // assign the lhs and rhs
        self.ast.items[nestedDeclarationsIndex].lhs = lhsIndex;
        self.ast.items[nestedDeclarationsIndex].rhs = rhsIndex;

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
        // REFACTOR: this could use the lhs and rhs index, however.... its
        // actually faster this way
        // Init indexes
        const tok = try self.currentToken();
        var declIndex = try self.reserve();

        // Expect Type
        const typeIndex = try self.parseType();

        // Expect Identifier
        const identIndex = try self.astAppendNode(try self.expectIdentifier());

        const node = Node{ .kind = NodeKind.Decl{ .lhs = typeIndex, .rhs = identIndex }, .token = tok };

        try self.set(declIndex, node);

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
        const tok = try self.currentToken();
        var typeIndex = try self.reserve();
        var rhsIndex: ?usize = null;
        var lhsIndex: ?usize = null;

        const token = try self.consumeToken();

        // Expect int | bool | struct (id)
        switch (token.kind) {
            TokenKind.KeywordInt => {
                lhsIndex = try self.astAppend(NodeKind{ .IntType = .{} }, token);
            },
            TokenKind.KeywordBool => {
                lhsIndex = try self.astAppend(NodeKind{ .BoolType = .{} }, token);
            },
            TokenKind.KeywordStruct => {
                lhsIndex = try self.astAppend(NodeKind{ .StructType = .{} }, token);
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
        const node = Node{
            .kind = NodeKind{ .Type = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(typeIndex, node);

        return typeIndex;
    }

    // Declarations = { Declaration }*
    pub fn parseDeclarations(self: *Parser) !usize {
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

        return declarationsIndex;
    }

    // Declaration = Type Identifier ("," Identifier)* ";"
    // NOTE: removes syntax sugar, and creates n type declarations that use the
    // same type for the different identifiers, they should be added in order,
    // in the array
    pub fn parseDeclaration(self: *Parser) !usize {
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

            const internalNode = Node{ .kind = NodeKind.Declaration, .token = try self.currentToken(), .lhs = lhsIndex, .rhs = null };
            const internalIndex = try self.astAppendNode(internalNode);

            // Expect Identifier
            const internalRHS = try self.astAppendNode(try self.expectIdentifier());
            // Repeat
            self.ast.items[internalIndex].rhs = internalRHS;
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // assign the lhs and rhs
        self.ast.items[declarationIndex].lhs = lhsIndex;
        self.ast.items[declarationIndex].rhs = rhsIndex;

        return declarationIndex;
    }

    // Functions = ( Function )*
    pub fn parseFunctions(self: *Parser) !usize {
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
    pub fn parseFunction(self: *Parser) !usize {
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

        return functionIndex;
    }

    // Parameters = "(" (Decl ("," Decl)* )? ")"
    pub fn parseParameters(self: *Parser) !usize {
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

        return parametersIndex;
    }

    // ReturnType = Type | "void"
    pub fn parseReturnType(self: *Parser) !usize {
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
                lhsIndex = try self.astAppend(NodeKind.Void, try self.expectAndYeildToken(TokenKind.KeywordVoid));
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
    pub fn parseStatement(self: *Parser) !usize {
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

        return statementIndex;
    }

    // StatementList = ( Statement )*
    pub fn parseStatementList(self: *Parser) ParserError!usize {
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
    pub fn parseBlock(self: *Parser) !usize {
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
    // REFACTOR: This is not properly written
    // FIXME:
    pub fn parseAssignment(self: *Parser) !usize {
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
    pub fn parsePrints(self: *Parser) !usize {
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
    /// If it is an if it goes like this:
    /// [[ConditionalIf, expression, then block]]
    ///                  lhs           rhs
    /// If it is an if else it goes like this:
    /// [[ConditionalIfElse, expression, then block, else block]]
    ///                         lhs                   rhs
    pub fn parseConditionals(self: *Parser) !usize {
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
    /// While goes like this:
    /// [[While, expression, block]]
    ///           lhs         rhs
    pub fn parseWhile(self: *Parser) !usize {
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
    /// Delete goes like this:
    /// [[Delete, expression]]
    ///              lhs
    pub fn parseDelete(self: *Parser) !usize {
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
    /// Return goes like this:
    /// [[Return, expression]]
    ///             lhs
    pub fn parseReturn(self: *Parser) !usize {
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
    /// Invocation goes like this:
    /// [[Invocation, identifier, arguments]]
    ///               lhs         rhs
    pub fn parseInvocation(self: *Parser) !usize {
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
    /// LValue goes like this:
    /// [[LValue, identifier,... , identifier]]
    ///             lhs              rhs
    pub fn parseLValue(self: *Parser) !usize {
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
        // NOTE:
        self.ast.items[lValueIndex].lhs = lhsIndex;
        self.ast.items[lValueIndex].rhs = rhsIndex;

        return lValueIndex;
    }

    pub fn backfillParse(self: *Parser, parentIndex: usize, optParentNode: NodeKind, optParentToken: TokenKind, childParseFn: *const fn (self: *Parser) ParserError!usize) !usize {
        // Init the backfill next!
        const lhsIndex: usize = try self.astAppend(NodeKind.BackfillReserve, try self.currentToken());

        // Expect child parse function type
        const rhsIndex: ?usize = try childParseFn(self);

        // set the backfill to the rhs, so that when we theoretically parse an
        // or it is set up
        self.ast.items[lhsIndex].lhs = rhsIndex;
        // set the rhs to the parent, so that we can set the parents rhs to null
        // if we have an opt
        self.ast.items[lhsIndex].rhs = parentIndex;

        var backfillIndex = lhsIndex;

        // Expect something to repeat
        while ((try self.currentToken()).kind == optParentToken) {

            // Expect ||
            var optNode = Node{ .kind = optParentNode, .token = try self.expectAndYeildToken(optParentToken) };
            optNode.lhs = self.ast.items[backfillIndex].lhs;
            // set parents rhs to null, so that only lhs is set (to the or and
            // now the next item is the lhs of the opt node)
            self.ast.items[self.ast.items[backfillIndex].rhs.?].rhs = null;
            self.ast.items[backfillIndex] = optNode;

            // opt has now replaced backfill
            // now create a new backfill, and set its lhs to the upcoming term
            // and its rhs to the current backfill
            const newBackfillNode = Node{
                .kind = NodeKind.BackfillReserve,
                .token = try self.currentToken(),
                .lhs = null,
                .rhs = backfillIndex,
            };

            var newBackfillIndex = try self.astAppendNode(newBackfillNode);

            self.ast.items[backfillIndex].rhs = newBackfillIndex;

            const childRHS = try childParseFn(self);

            self.ast.items[newBackfillIndex].lhs = childRHS;

            backfillIndex = newBackfillIndex;
        }

        // assign the lhs and rhs
        self.ast.items[parentIndex].lhs = lhsIndex;
        self.ast.items[parentIndex].rhs = rhsIndex;

        return parentIndex;
    }

    pub fn backfillParseMany(self: *Parser, parentIndex: usize, optBackfillNodeKinds: []const NodeKind, optBackfillTokenKinds: []const TokenKind, childParseFn: *const fn (self: *Parser) ParserError!usize) !usize {
        // Init the backfill next!
        const lhsIndex: usize = try self.astAppend(NodeKind.BackfillReserve, try self.currentToken());

        // Expect child parse function type
        const rhsIndex: ?usize = try childParseFn(self);

        // set the backfill to the rhs, so that when we theoretically parse an
        // or it is set up
        self.ast.items[lhsIndex].lhs = rhsIndex;
        // set the rhs to the parent, so that we can set the parents rhs to null
        // if we have an opt
        self.ast.items[lhsIndex].rhs = parentIndex;

        var backfillIndex = lhsIndex;

        var optBackfillType: ?usize = null;

        std.debug.print("optBackfillTokenKinds.len: {any}\n", .{optBackfillTokenKinds.len});
        std.debug.print("optBackfillNodeKinds.len: {any}\n", .{optBackfillNodeKinds.len});
        std.debug.print("optBackfillTokenKinds: {any}\n", .{optBackfillTokenKinds});
        std.debug.print("optBackfillNodeKinds: {any}\n", .{optBackfillNodeKinds});
        std.debug.print("backfillIndex: {any}\n", .{backfillIndex});
        std.debug.print("lhsIndex: {any}\n", .{lhsIndex});
        std.debug.print("rhsIndex: {any}\n", .{rhsIndex});
        std.debug.print("rhsKind: {any}\n", .{self.ast.items[rhsIndex.?].kind});
        std.debug.print("remaining tokens: {any}\n", .{self.tokens[self.pos..]});

        // Expect something to repeat
        while (true) {
            const tempToken = try self.currentToken();
            std.debug.print("tempToken kind: {any}\n", .{tempToken.kind});
            var i: usize = 0;
            while (i < optBackfillTokenKinds.len) {
                if (tempToken.kind == optBackfillTokenKinds[i]) {
                    optBackfillType = i;
                    break;
                }
                i += 1;
            }
            std.debug.print("optBackfillType: {any}\n", .{optBackfillType});

            if (optBackfillType == null) {
                std.debug.print("optBackfillType is null\n", .{});
                break;
            }

            if (i == optBackfillTokenKinds.len) {
                std.debug.print("i == optBackfillTokenKinds.len\n", .{});
                break;
            }

            // Expect some kind of opt
            var optNode: Node = Node{ .kind = optBackfillNodeKinds[i], .token = try self.expectAndYeildToken(optBackfillTokenKinds[i]) };
            std.debug.print("optNode: {any}\n", .{optNode});
            optNode.lhs = self.ast.items[backfillIndex].lhs;
            // set parents rhs to null, so that only lhs is set (to the or and
            // now the next item is the lhs of the opt node)
            self.ast.items[self.ast.items[backfillIndex].rhs.?].rhs = null;
            self.ast.items[backfillIndex] = optNode;

            // opt has now replaced backfill
            // now create a new backfill, and set its lhs to the upcoming term
            // and its rhs to the current backfill
            const newBackfillNode = Node{
                .kind = NodeKind.BackfillReserve,
                .token = try self.currentToken(),
                .lhs = null,
                .rhs = backfillIndex,
            };

            var newBackfillIndex = try self.astAppendNode(newBackfillNode);

            self.ast.items[backfillIndex].rhs = newBackfillIndex;

            const childRHS = try childParseFn(self);

            self.ast.items[newBackfillIndex].lhs = childRHS;

            backfillIndex = newBackfillIndex;
        }

        // assign the lhs and rhs
        self.ast.items[parentIndex].lhs = lhsIndex;
        self.ast.items[parentIndex].rhs = rhsIndex;

        return parentIndex;
    }

    /////////// UNTOUCHED TO REFACTOR ////////////////////////
    // Expression = BoolTerm ("||" BoolTerm)*
    /// Expression goes like this:
    /// [[ Expression, BackfillReserve, Boolterm,...]]
    ///                   lhs             rhs
    /// TESTME: this is untested
    /// Should be able to skip any nodes called backfill reserve in the use of
    /// the ast, and will act as it would if we were using a tree rather than a
    /// array
    ///
    /// NOTE: Would be possible to have the Backfill be represented as rhs,
    /// before it is turned into an or.
    /// however, this would be in conflict with the memory representation, so
    /// it has not been implemented yet.
    pub fn parseExpression(self: *Parser) ParserError!usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Expression\n", .{});
                std.debug.print("Defined as: Expression = BoolTerm (\"||\" BoolTerm)*\n", .{});
            }
        }
        // Init indexes
        const expressionIndex = try self.astAppend(NodeKind.Expression, try self.currentToken());

        const parsedIndex = backfillParse(
            self,
            expressionIndex, // The index for this node, this will act as parent
            NodeKind.Or, // The optional node that we will create  will be filled
            // with a BackfillReserve to start
            TokenKind.Or, // The optional token that we will use
            Parser.parseBoolTerm, // the funciton to call to make the child(ren)
        );

        return parsedIndex;
    }

    // Boolterm = EqTerm ("&&" EqTerm)*
    pub fn parseBoolTerm(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a BoolTerm\n", .{});
                std.debug.print("Defined as: Boolterm = EqTerm (\"&&\" EqTerm)*\n", .{});
            }
        }
        // Init indexes
        var boolTermIndex = try self.astAppend(NodeKind.BoolTerm, try self.currentToken());

        const parsedIndex = backfillParse(
            self,
            boolTermIndex, // The index for this node, this will act as parent
            NodeKind.And, // The optional node that we will create  will be filled
            // with a BackfillReserve to start
            TokenKind.And, // The optional token that we will use
            Parser.parseEqTerm, // the funciton to call to make the child(ren)
        );

        return parsedIndex;
    }

    // EqTerm = RelTerm (("==" | "!=") RelTerm)*
    pub fn parseEqTerm(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an EqTerm\n", .{});
                std.debug.print("Defined as: EqTerm = RelTerm (\"==\" | \"!=\") RelTerm)*\n", .{});
            }
        }

        // Init indexes
        var eqTermIndex = try self.astAppend(NodeKind.EqTerm, try self.currentToken());
        const nodeKinds: [2]NodeKind = [_]NodeKind{ NodeKind.Equals, NodeKind.NotEq };
        const tokenKinds: [2]TokenKind = [_]TokenKind{ TokenKind.DoubleEq, TokenKind.NotEq };

        const parsedIndex = backfillParseMany(
            self,
            eqTermIndex, // The index for this node, this will act as parent
            &nodeKinds, // The optional node that we will create  will be filled
            // with a BackfillReserve to start
            &tokenKinds, // The optional token that we will use
            Parser.parseRelTerm, // the funciton to call to make the child(ren)
        );
        return parsedIndex;
    }

    // RelTerm = Simple (("<" | ">" | ">=" | "<=") Simple)*
    pub fn parseRelTerm(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a RelTerm\n", .{});
                std.debug.print("Defined as: RelTerm = Simple (\"<\" | \">\" | \">=\" | \"<=\") Simple)*\n", .{});
            }
        }
        // Init indexes
        var relTermIndex = try self.astAppend(NodeKind.RelTerm, try self.currentToken());
        const nodeKinds: [4]NodeKind = [_]NodeKind{ NodeKind.LessThan, NodeKind.GreaterThan, NodeKind.GreaterThanEq, NodeKind.LessThanEq };
        const tokenKinds: [4]TokenKind = [_]TokenKind{ TokenKind.Lt, TokenKind.Gt, TokenKind.GtEq, TokenKind.LtEq };

        const parsedIndex = backfillParseMany(
            self,
            relTermIndex, // The index for this node, this will act as parent
            &nodeKinds, // The optional node that we will create  will be filled
            // with a BackfillReserve to start
            &tokenKinds, // The optional token that we will use
            Parser.parseSimple, // the funciton to call to make the child(ren)
        );
        return parsedIndex;
    }

    // Simple = Term (("+" | "-") Term)*
    pub fn parseSimple(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Simple\n", .{});
                std.debug.print("Defined as: Simple = Term (\"+\" | \"-\") Term)*\n", .{});
            }
        }
        // Init indexes
        var simpleIndex = try self.astAppend(NodeKind.Simple, try self.currentToken());
        const nodeKinds: [2]NodeKind = [_]NodeKind{ NodeKind.Plus, NodeKind.Minus };
        const tokenKinds: [2]TokenKind = [_]TokenKind{ TokenKind.Plus, TokenKind.Minus };

        const parsedIndex = backfillParseMany(
            self,
            simpleIndex, // The index for this node, this will act as parent
            &nodeKinds, // The optional node that we will create  will be filled
            // with a BackfillReserve to start
            &tokenKinds, // The optional token that we will use
            Parser.parseTerm, // the funciton to call to make the child(ren)
        );

        return parsedIndex;
    }

    // Term = Unary (("*" | "/") Unary)*
    pub fn parseTerm(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Term\n", .{});
                std.debug.print("Defined as: Term = Unary (\"*\" | \"/\") Unary)*\n", .{});
            }
        }
        // Init indexes
        var termIndex = try self.astAppend(NodeKind.Term, try self.currentToken());
        const nodeKinds: [2]NodeKind = [_]NodeKind{ NodeKind.Mul, NodeKind.Div };
        const tokenKinds: [2]TokenKind = [_]TokenKind{ TokenKind.Mul, TokenKind.Div };

        const parsedIndex = backfillParseMany(
            self,
            termIndex, // The index for this node, this will act as parent
            &nodeKinds, // The optional node that we will create  will be filled
            &tokenKinds, // The optional token that we will use
            Parser.parseUnary, // the funciton to call to make the child(ren)
        );

        return parsedIndex;
    }

    // Unary = ("!" | "-")* Selector
    pub fn parseUnary(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing a Unary\n", .{});
                std.debug.print("Defined as: Unary = (\"!\" | \"-\")* Selector\n", .{});
            }
        }
        // Init indexes
        var unaryIndex = try self.astAppend(NodeKind.Unary, try self.currentToken());
        const nodeKinds: [2]NodeKind = [_]NodeKind{ NodeKind.Not, NodeKind.Minus };
        const tokenKinds: [2]TokenKind = [_]TokenKind{ TokenKind.Not, TokenKind.Minus };

        const parsedIndex = backfillParseMany(
            self,
            unaryIndex, // The index for this node, this will act as parent
            &nodeKinds, // The optional node that we will create  will be filled
            &tokenKinds, // The optional token that we will use
            Parser.parseSelector, // the funciton to call to make the child(ren)
        );

        return parsedIndex;
    }

    // Selector = Factor ("." Identifier)*
    pub fn parseSelector(self: *Parser) !usize {
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
    pub fn parseFactor(self: *Parser) ParserError!usize {
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
            TokenKind.Number => {
                const numberToken = try self.expectAndYeildToken(TokenKind.Number);
                const numberNode = Node{ .kind = NodeKind.Number, .token = numberToken };
                lhsIndex = try self.astAppendNode(numberNode);
            },
            TokenKind.KeywordTrue => {
                const trueToken = try self.expectAndYeildToken(TokenKind.KeywordTrue);
                const trueNode = Node{ .kind = NodeKind.True, .token = trueToken };
                lhsIndex = try self.astAppendNode(trueNode);
            },
            TokenKind.KeywordFalse => {
                const falseToken = try self.expectAndYeildToken(TokenKind.KeywordFalse);
                const falseNode = Node{ .kind = NodeKind.False, .token = falseToken };
                lhsIndex = try self.astAppendNode(falseNode);
            },
            TokenKind.KeywordNull => {
                const nullToken = try self.expectAndYeildToken(TokenKind.KeywordNull);
                const nullNode = Node{ .kind = NodeKind.Null, .token = nullToken };
                lhsIndex = try self.astAppendNode(nullNode);
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
                return error.InvalidToken;
            },
        }
        // assign the lhs and rhs
        self.ast.items[factorIndex].lhs = lhsIndex;
        self.ast.items[factorIndex].rhs = rhsIndex;

        return factorIndex;
    }

    // Arguments = "(" (Expression ("," Expression)*)? ")"
    pub fn parseArguments(self: *Parser) !usize {
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
        self.ast.items[argumentsIndex].rhs = rhsIndex;

        return argumentsIndex;
    }
};

pub fn main() !void {
    const source = "struct test{ int a; }; fun A() void{ int d;d=2+5;}";
    const tokens = try Lexer.tokenizeFromStr(source, std.heap.page_allocator);
    const parser = try Parser.parseTokens(tokens, source, std.heap.page_allocator);
    std.debug.print("Parsed successfully\n", .{});
    try parser.prettyPrintAst();
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////// Tests
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

const debugAlloc = std.testing.allocator;
test "no_identifier_struct" {
    const source = "struct { int a; int b; struct TS S; };";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "no_keyword_struct" {
    const source = "TS{ int a; int b; struct TS S; };";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "no_members_struct" {
    const source = "struct TS { };";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "no_semicolon_struct_end" {
    const source = "struct TS { int a int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "no_semicolon_struct_member" {
    const source = "struct TS { int a; int b; struct TS S };";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "no_struct_function" {
    const source = "fun TS() void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    var parser = try Parser.parseTokens(tokens, source, debugAlloc);
    parser.deinit();
}

test "function_no_identifier" {
    const source = "fun () void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "function_no_parameters" {
    const source = "fun TS void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "function_no_return_type" {
    const source = "fun TS() { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}

test "function_no_lcurly" {
    const source = "fun TS() void int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    try std.testing.expectError(error.InvalidToken, Parser.parseTokens(tokens, source, debugAlloc));
}
