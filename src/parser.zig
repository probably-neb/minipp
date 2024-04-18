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
/// NOTE: there is a lot of indirection present in the tree
///     ex. Expression -> Selector -> Factor -> Number
///     the plan is to remove this as needed while working on the following
///     compile steps that operate on the AST (name resolution, type checking, semantic analysis)
///     to suit the needs of those steps
///
///     the primary goal will be to remove as many of the so-called "lhs only" nodes
///     such as Expression.
///
///     The goal of the AST is not to produce a clean representation
///     of the grammar based on the input file, it is to create a structure suitable
///     for the following compile steps/passes
///     Therefore information that can be assumed
///     (like the condition in an if statement is an expression)
///     should not be stored as it only adds more places for mistakes, and more required
///     logic/indirection to the consumers
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

const ParserError = error{ InvalidToken, TokenIndexOutOfBounds, TokensDoNotMatch, NotEnoughTokens, NoRangeForToken, OutofBounds, OutOfMemory, AssertionError };

/// A parser is responsible for taking the tokens and creating an abstract syntax tree.
/// The resulting ast is a flat array of nodes.
/// To deinit the parser call the `deinit` member function.
/// Reccomended usage:
/// ```zig
/// cosnt tokens = try Lexer.tokenize(input, file_name, allocator);
/// const parser = try Parser.parseTokens(tokens, input, allocator);
/// defer parser.deinit();
/// ```
pub const Struct_t = struct {
    id: usize,
    decls: lexer.Range,
};

pub const Function_t = struct {
    id: usize,
    returnType: usize,
    args: lexer.Range,
    decls: lexer.Range,
};

pub const Parser = struct {
    tokens: []Token,
    input: []const u8,

    ast: std.ArrayList(Node),
    astLen: usize = 0,

    pos: usize = 0,
    readPos: usize = 1,
    idMap: std.StringHashMap(bool),

    structArray: std.ArrayList(Struct_t),
    functionArray: std.ArrayList(Function_t),
    declArray: std.ArrayList(usize),

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

    // TODO : create currentTokenThatShouldBe function for more checks and
    // easier bug finding (supposedly (my opinions are my own))
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
            std.log.err("Error invalid Token at {d}: expected token kind {s} but got {s}.\n", .{ @max(self.pos, 1) - 1, @tagName(kind), @tagName(token.kind) });
            const line: []const u8 = token._range.getLineCont(self.input);
            std.log.err("{s}\n", .{line});
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

    pub fn init(tokens: []Token, input: []const u8, allocator: std.mem.Allocator) !Parser {
        var parser = Parser{
            .ast = try std.ArrayList(Node).initCapacity(allocator, tokens.len),
            .idMap = std.StringHashMap(bool).init(allocator),
            .structArray = try std.ArrayList(Struct_t).initCapacity(allocator, 10),
            .functionArray = try std.ArrayList(Function_t).initCapacity(allocator, 10),
            .declArray = try std.ArrayList(usize).initCapacity(allocator, 10),
            .tokens = tokens,
            .input = input,
            .readPos = if (tokens.len > 0) 1 else 0,
            .allocator = allocator,
        };

        return parser;
    }

    pub fn parseTokens(tokens: []Token, input: []const u8, allocator: std.mem.Allocator) !Parser {
        var parser = try Parser.init(tokens, input, allocator);
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
        std.log.info("AST:{{\n", .{});
        while (i < self.astLen) {
            const node = ast[i];
            const token = node.token;
            const tokenStr = token._range.getSubStrFromStr(self.input);
            const kind = @tagName(node.kind);
            std.log.info("{s}: {s}\n", .{ kind, tokenStr });
            i += 1;
        }
        std.log.info("}}\n", .{});
    }

    pub fn prettyPrintDeclNode(self: *const Parser, index: usize) !void {
        const node = self.ast.items[index];
        const lhsNode = self.ast.items[node.kind.Decl.lhs.?];
        const rhsNode = self.ast.items[node.kind.Decl.rhs.?];
        const lhsNodelhsNode = self.ast.items[lhsNode.kind.Type.lhs.?];
        const typeTag = @tagName(lhsNodelhsNode.kind);
        const identTag = (rhsNode.token._range.getSubStrFromStr(self.input));

        std.debug.print("{{{s},{s}}}", .{
            typeTag,
            identTag,
        });
    }

    /// reserves a location using the BackFillReserve Node
    /// NOTE: does not call any token consuming functions, expects
    /// the caller to handle tokens
    fn reserve(self: *Parser) !usize {
        const index = self.astLen;
        const node = Node{ .kind = .{ .BackfillReserve = .{ .lhs = 0, .rhs = 0 } }, .token = Token{
            .kind = TokenKind.Eof,
            ._range = lexer.Range.new(0, 0),
        } };
        try self.ast.append(node);
        self.astLen += 1;
        return index;
    }

    /// the sidekick of `reserve` takes in an index returned by `reserve`
    /// and a node to put there and bada-bing-bada-boom you maintained a preorder traversal
    fn set(self: *Parser, at: usize, node: Node) !void {
        utils.assert(at < self.astLen, "tried to set a node out of bounds: astLen = {d}, silly goose passed = {d}", .{ at, self.astLen });
        self.ast.items[at] = node;
    }

    pub fn getStrFromID(self: *Parser, id: usize) ![]const u8 {
        return self.ast.items[id].token._range.getSubStrFromStr(self.input);
    }

    pub fn getTypeNumber(self: *Parser, type_str: []const u8) !usize {
        if (std.mem.eql(u8, type_str, "int")) {
            return 0;
        } else if (std.mem.eql(u8, type_str, "bool")) {
            return 1;
        } else if (std.mem.eql(u8, type_str, "int_array")) {
            return 2;
        }

        // FIXME: should use a map here instead, every time a struct is declared
        // and possibly used it will route through here
        // furthermore, if the Nodes are not union(enum) the calling for this
        // would be faster as well
        var structIter: usize = 0;
        for (self.structArray.items) |s| {
            if (std.mem.eql(u8, type_str, try self.getStrFromID(s.id))) {
                return 3 + structIter;
            }
            structIter += 1;
        }

        // TODO: make this error actually useful
        return error.InvalidType;
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
        // Functions will be rhsIndex
        _ = try self.parseDeclarations();

        // Expect Functions
        rhsIndex = try self.parseFunctions();

        // Expect EOF
        // TODO: make sure that Eof gets assigned propperly
        try self.expectToken(TokenKind.Eof);

        const progNode = Node{
            .kind = NodeKind{ .Program = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = progToken,
        };
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
        const typesIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        if ((try self.currentToken()).kind != .KeywordStruct) {
            const emptyNode = Node{ .kind = NodeKind{ .Types = undefined }, .token = typesToken };
            try self.set(typesIndex, emptyNode);
            return typesIndex;
        }

        lhsIndex = try self.parseTypeDeclaration();

        // // While not EOF then parse TypeDeclaration
        // // Expect (TypeDeclaration)*
        while ((try self.currentToken()).kind == TokenKind.KeywordStruct) {
            rhsIndex = try self.parseTypeDeclaration();
        }
        const node = Node{ .kind = NodeKind{ .Types = .{ .lhs = lhsIndex, .rhs = rhsIndex } }, .token = typesToken };
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

        var typesStart = self.declArray.items.len;
        var typesEnd = self.declArray.items.len;

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
            .kind = NodeKind{ .TypeDeclaration = .{ .lhs = @truncate(lhsIndex.?), .rhs = @truncate(rhsIndex.?) } },
            .token = tok,
        };

        typesEnd = self.declArray.items.len;
        const cur_struct = Struct_t{
            .id = lhsIndex.?,
            .decls = lexer.Range{ .start = @truncate(typesStart), .end = @truncate(typesEnd) },
        };
        try self.structArray.append(cur_struct);

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

        const node = Node{
            .kind = NodeKind{ .Declarations = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(nestedDeclarationsIndex, node);

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

        const node = Node{
            .kind = NodeKind{ .Decl = .{ .lhs = typeIndex, .rhs = identIndex } },
            .token = tok,
        };

        try self.set(declIndex, node);
        try self.declArray.append(declIndex);

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
                const kind = NodeKind{ .IntType = undefined };
                lhsIndex = try self.astAppend(kind, token);
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
        const tok = try self.currentToken();
        var declarationsIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .Declaration = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(declarationsIndex, node);

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
        const tok = try self.currentToken();
        var declarationIndex = try self.reserve();
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
            const internalIndex = try self.reserve();

            // Expect Identifier
            const internalRHS = try self.astAppendNode(try self.expectIdentifier());
            const internalNode = Node{
                .kind = NodeKind{ .Declaration = .{ .lhs = lhsIndex, .rhs = internalRHS } },
                .token = try self.currentToken(),
            };
            // Repeat
            try self.set(internalIndex, internalNode);
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .Declaration = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(declarationIndex, node);

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
        const tok = try self.currentToken();
        var functionsIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .Functions = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(functionsIndex, node);

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
        const tok = try self.currentToken();
        var functionIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect fun
        try self.expectToken(TokenKind.KeywordFun);

        // Expect Identifier
        lhsIndex = try self.astAppendNode(try self.expectIdentifier());
        var funID = lhsIndex;

        var funArgsStart = self.declArray.items.len;
        // Expect Parameters
        rhsIndex = try self.parseParameters();
        var funArgsEnd = self.declArray.items.len;

        // Expect ReturnType
        rhsIndex = try self.parseReturnType();
        var funRet = rhsIndex;

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        var funDeclsStart = self.declArray.items.len;
        // Expect Declarations
        rhsIndex = try self.parseDeclarations();
        var funDeclsEnd = self.declArray.items.len;

        // Expect StatementList
        rhsIndex = try self.parseStatementList();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        const node = Node{
            .kind = NodeKind{ .Function = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(functionIndex, node);

        const fun = Function_t{
            .id = funID.?,
            .returnType = funRet.?,
            .args = lexer.Range{ .start = @truncate(funArgsStart), .end = @truncate(funArgsEnd) },
            .decls = lexer.Range{ .start = @truncate(funDeclsStart), .end = @truncate(funDeclsEnd) },
        };

        try self.functionArray.append(fun);

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
        const tok = try self.currentToken();
        var parametersIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .Parameters = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(parametersIndex, node);
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
        const tok = try self.currentToken();
        var returnTypeIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Token to switch on
        const token = try self.currentToken();
        switch (token.kind) {
            TokenKind.KeywordVoid => {
                const voidToken = try self.expectAndYeildToken(TokenKind.KeywordVoid);
                const voidNodeKind = NodeKind{ .Void = undefined };
                lhsIndex = try self.astAppend(voidNodeKind, voidToken);
            },
            else => {
                if (lhsIndex == null) {
                    lhsIndex = try self.parseType();
                } else {
                    rhsIndex = try self.parseType();
                }
            },
        }

        const node = Node{
            .kind = NodeKind{ .ReturnType = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(returnTypeIndex, node);

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
        const tok = try self.currentToken();
        var statementIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .Statement = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(statementIndex, node);

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
        const tok = try self.currentToken();
        var statementListIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .StatementList = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(statementListIndex, node);

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
        const tok = try self.currentToken();
        var blockIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect StatementList
        lhsIndex = try self.parseStatementList();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        const node = Node{
            .kind = NodeKind{ .Block = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(blockIndex, node);

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
        const tok = try self.currentToken();
        var assignmentIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect LValue
        lhsIndex = try self.parseLValue();

        // Expect =
        try self.expectToken(TokenKind.Eq);

        // Expect Expression | "read"
        if ((try self.currentToken()).kind == TokenKind.KeywordRead) {
            // make read node
            const readNode = Node{
                .kind = NodeKind{ .Read = .{} },
                .token = try self.consumeToken(),
            };
            rhsIndex = try self.astAppendNode(readNode);
        } else {
            // make expression node
            rhsIndex = try self.parseExpression();
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .Assignment = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(assignmentIndex, node);
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
        const tok = try self.currentToken();
        var printIndex = try self.reserve();
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
            },
            // Expect endl ;
            TokenKind.KeywordEndl => {
                try self.expectToken(TokenKind.KeywordEndl);
                try self.expectToken(TokenKind.Semicolon);
                const node = Node{
                    .kind = NodeKind{ .PrintLn = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
                    .token = tok,
                };
                try self.set(printIndex, node);
                return printIndex;
            },
            else => {
                return std.debug.panic("expected ; or endl but got {s}.", .{@tagName((try self.currentToken()).kind)});
            },
        }

        const node = Node{
            .kind = NodeKind{ .Print = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(printIndex, node);
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
        const tok = try self.currentToken();
        var conditionalIndex = try self.reserve();
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
            const node = Node{
                .kind = NodeKind{ .ConditionalIfElse = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
                .token = tok,
            };
            try self.set(conditionalIndex, node);
            return conditionalIndex;
        }

        const node = Node{
            .kind = NodeKind{ .ConditionalIf = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(conditionalIndex, node);

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
        const tok = try self.currentToken();
        var whileIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .While = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(whileIndex, node);

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
        const tok = try self.currentToken();
        var deleteIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect delete
        try self.expectToken(TokenKind.KeywordDelete);

        // Expect Expression
        lhsIndex = try self.parseExpression();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .Delete = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(deleteIndex, node);

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
        const tok = try self.currentToken();
        var returnIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect return
        try self.expectToken(TokenKind.KeywordReturn);

        // Expect Expression optionally
        if ((try self.currentToken()).kind != TokenKind.Semicolon) {
            // Expect Expression
            lhsIndex = try self.parseExpression();
        }

        const node = Node{
            .kind = NodeKind{ .Return = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        try self.set(returnIndex, node);

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
        const tok = try self.currentToken();
        var invocationIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect Identifier
        lhsIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect Arguments
        rhsIndex = try self.parseArguments();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .Invocation = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(invocationIndex, node);

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
        const tok = try self.currentToken();
        var lValueIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .LValue = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(lValueIndex, node);

        return lValueIndex;
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
        const tok = try self.currentToken();
        var argumentsIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect (
        try self.expectToken(TokenKind.LParen);

        if ((try self.currentToken()).kind == TokenKind.RParen) {
            // Expect )
            try self.expectToken(TokenKind.RParen);
            // lhs, rhs = null for no args
            const node = Node{
                .kind = NodeKind{ .Arguments = .{ .lhs = null, .rhs = null } },
                .token = tok,
            };
            try self.set(argumentsIndex, node);
            return argumentsIndex;
        }
        // Expect (Expression ("," Expression)*)?
        // Expect Expression
        lhsIndex = try self.parseExpression();

        // Expect ("," Expression)*
        while ((try self.currentToken()).kind == TokenKind.Comma) {
            // Expect ,
            try self.expectToken(TokenKind.Comma);
            // Expect Expression
            rhsIndex = try self.parseExpression();
        }

        // Expect )
        try self.expectToken(TokenKind.RParen);

        const node = Node{
            .kind = NodeKind{ .Arguments = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(argumentsIndex, node);

        return argumentsIndex;
    }

    /// type alias
    const BindingPower = u8;

    /// "binding power" ~ precedence of an operator
    /// higher binding power means higher precedence
    /// pratt parsing based on these binding powers results in
    /// sub expressions with higher precedence being grouped together
    /// i.e. `a + b * c` is parsed as `a + (b * c)` because `*`
    /// has higher precedence than `+`
    fn binding_power(op: TokenKind) BindingPower {
        return switch (op) {
            // expression -> boolterm { '||' boolterm}∗
            .Or => 1,
            // boolterm -> eqterm { '&&' eqterm}∗
            .And => 2,
            // eqterm -> relterm {{ '==' | '!=' } relterm}∗
            .DoubleEq, .NotEq => 3,
            // relterm -> simple {{ '<' | '>' | '<=' | '>=' } simple}∗
            .Gt, .Lt, .GtEq, .LtEq => 4,
            // simple -> term {{ '+' | '−' } term}∗
            .Plus, .Minus => 5,
            // term -> unary {{ '∗' | '/' } unary}∗
            .Mul, .Div => 6,
            else => unreachable,
        };
    }

    /// binding power of prefix ops (`!`, `-`)
    /// separate function because it is used in a different context
    /// and must avoid returning the bp of `-` when used as negation operator
    fn prefix_binding_power(op: TokenKind) BindingPower {
        return switch (op) {
            // NOTE: must be bigger than biggest binop binding power
            .Not, .Minus => 7,
            else => unreachable,
        };
    }

    fn is_binop(op: TokenKind) bool {
        return switch (op) {
            .Or, .And, .DoubleEq, .NotEq, .Gt, .Lt, .GtEq, .LtEq, .Plus, .Minus, .Mul, .Div => true,
            else => false,
        };
    }

    pub const Expr = union(enum) {
        Binop: ExprBinop,
        Uop: ExprUop,
        Atom: ExprAtom,
    };
    /// An atom is a selector in the grammar, i.e. the lowest level of the expression
    /// heirarchy that contains no operators (not considering `.` field acess as an op)
    /// (described as selector in grammar)
    // TODO: make it {start, end} rather than length. End is almost exclusively used
    // in tests/assertions for taking a slice of the token list
    pub const ExprAtom = struct {
        /// The index into the token list, to set in the parser before calling parseAtom
        /// while reconstructing the tree
        start: usize,
        len: u32,
    };
    /// binary operation
    pub const ExprBinop = struct { op: Token, lhs: *Expr, rhs: *Expr };
    /// unary operation
    pub const ExprUop = struct {
        op: Token,
        on: *Expr,
    };

    fn reconstructTree(self: *Parser, expr: *Expr) !usize {
        switch (expr.*) {
            .Binop => {
                const binopIndex = try self.reserve();
                const lhsIndex = try self.reconstructTree(expr.Binop.lhs);
                const rhsIndex = try self.reconstructTree(expr.Binop.rhs);
                const node = Node{
                    .kind = .{ .BinaryOperation = .{
                        .lhs = lhsIndex,
                        .rhs = rhsIndex,
                    } },
                    .token = expr.Binop.op,
                };
                try self.set(binopIndex, node);
                return binopIndex;
            },
            .Uop => {
                const uopIndex = try self.reserve();
                const onIndex = try self.reconstructTree(expr.Uop.on);
                const node = Node{
                    .kind = .{ .UnaryOperation = .{
                        .lhs = onIndex,
                        .rhs = null,
                    } },
                    .token = expr.Uop.op,
                };
                try self.set(uopIndex, node);
                return uopIndex;
            },
            .Atom => {
                // this is tricky see
                // save token position before overwriting
                const posSave = self.pos;
                const readPosSave = self.readPos;

                // overwrite the token position so when we call parseSelector
                // it starts at the token we skipped while extracting the atom
                self.pos = expr.Atom.start;
                self.readPos = expr.Atom.start + 1;

                const atomIndex = try self.parseSelector();

                // I really should have made this error shorter before the hundredth time I saw it
                utils.assert(self.pos == (expr.Atom.start + expr.Atom.len), "either didn't skip enough tokens when extracting atom or didn't parse enough when reconstructing tree... either way shits borqed! glhf!!!\n Expected to parse: \n{any}\nBut Parsed: \n{any}\n", .{ self.tokens[expr.Atom.start..(expr.Atom.start + expr.Atom.len)], self.tokens[expr.Atom.start..self.pos] });

                // restore read and write pos
                self.pos = posSave;
                self.readPos = readPosSave;

                // return index to atom subtree in ast
                return atomIndex;
            },
        }
    }

    pub fn parseExpression(self: *Parser) ParserError!usize {
        errdefer {
            if (self.showParseTree) {
                std.debug.print("Error in parsing an Expression\n", .{});
                std.debug.print("Defined as: Expression = boolterm (\"||\" boolterm)*\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        const expressionIndex = try self.reserve();

        var arenaAlloc = std.heap.ArenaAllocator.init(self.allocator);
        defer arenaAlloc.deinit();
        var arena = arenaAlloc.allocator();

        const expr = try self.prattParseExpression(arena, 0);
        std.log.info("\nEXTRACTED: {any}\n", .{expr});
        const treeIndex = try self.reconstructTree(expr);

        // NOTE: unessary?
        const node = Node{
            .kind = NodeKind{ .Expression = .{ .lhs = treeIndex, .rhs = null } },
            .token = tok,
        };
        try self.set(expressionIndex, node);
        return expressionIndex;
    }

    fn prattParseExpression(self: *Parser, arena: std.mem.Allocator, minBP: BindingPower) !*Expr {
        const tok = try self.currentToken();

        var lhs = try arena.create(Expr);
        switch (tok.kind) {
            .Not, .Minus => |uop| {
                const bp = prefix_binding_power(uop);
                const rhs = try self.prattParseExpression(arena, bp);
                lhs.* = Expr{ .Uop = .{
                    .op = tok,
                    .on = rhs,
                } };
            },
            // TODO: LParen here
            else => {
                const atom = try self.extractAtom();
                lhs.* = Expr{ .Atom = atom };
            },
        }

        while (true) {
            // not peek because idk this works
            const op = try self.currentToken();
            if (op.kind == TokenKind.Eof) {
                break;
            }
            if (!is_binop(op.kind)) {
                // FIXME: sometimes a non-binop is expected
                // ex. `,` between args
                // but sometimes it means malformed expression (i think (unproven))
                break;
            }
            const bp = binding_power(op.kind);
            // we don't actually use different left/right binding powers,
            // but if we did... this is so we don't have to go find the random
            // shit I was reading to figure out which goes where
            const rBP = bp;
            const lBP = bp;

            if (lBP < minBP) {
                break;
            }
            _ = try self.consumeToken();
            const rhs = try self.prattParseExpression(arena, rBP + 1);

            const newlhs = try arena.create(Expr);
            newlhs.* = Expr{ .Binop = .{ .op = op, .lhs = lhs, .rhs = rhs } };
            lhs = newlhs;
        }
        return lhs;
    }

    // Extracts the list of tokens making up an `atom` (see description in Expr struct above)
    // to be reparsed when reconstructing the pratt-parsed expr tree in preorder-traversal order
    fn extractAtom(self: *Parser) ParserError!ExprAtom {
        const tokenStartIndex = self.pos;
        var numTokens: u32 = 1;

        var startTok = try self.currentToken();
        const peekKind = (try self.peekToken()).kind;

        if ((startTok.kind == .Identifier) and (peekKind == .LParen or peekKind == .Dot)) {
            // skipping all tokens for function call `id '(' {args},* ')'` is functionally the same as skipping all tokens in a parenthized as expression
            // skipping the id token makes it so they can be handled in the same switch arm in the
            // following switch statement
            _ = try self.consumeToken();
            startTok = try self.currentToken();
            if (peekKind == .LParen) {
                // Dot `numTokens` calculation is harder when we increment
                // in both cases here
                numTokens += 1;
            }
            // skipping on `.` however just makes it so identifier is easier in the next switch
        }
        switch (startTok.kind) {
            .LParen => {
                // keep "stack" of paren count to find the last one
                var count: u32 = 1;
                _ = try self.consumeToken();
                while (count != 0) {
                    numTokens += 1;
                    const tok = try self.consumeToken();
                    if (tok.kind == .Eof) {
                        // TODO: handle
                        return error.NotEnoughTokens;
                    }
                    if (tok.kind == .LParen) {
                        count += 1;
                    } else if (tok.kind == .RParen) {
                        count -= 1;
                    }
                }
                const final = self.tokens[self.pos - 1];
                utils.assert(final.kind == .RParen, "final token not RParen, is: {}\n", .{final});
            },
            .KeywordNew => {
                _ = try self.expectToken(.KeywordNew);
                // Note - leaving checking if the thing after new is right until it's parsed later...
                // this is probably a badddd idea (malformed expressions like what! (with the lights on!!??))
                // FIXME:
                _ = try self.consumeToken();
                numTokens += 1;
                utils.assert(numTokens == 2, "New token has more than 2 tokens\n", .{});
            },
            .Dot => {
                while ((try self.currentToken()).kind == .Dot) {
                    _ = try self.consumeToken();
                    try self.expectToken(.Identifier);
                    numTokens += 2;
                }
            },
            .Number, .KeywordTrue, .KeywordFalse, .KeywordNull, .Identifier => {
                _ = try self.consumeToken();
            },
            // TODO: handle error for invalid atom
            else => {
                std.debug.print("Invalid atom\nbre wth is this: {any}", .{startTok});
                return error.InvalidToken;
            },
        }
        return ExprAtom{
            .start = tokenStartIndex,
            .len = numTokens,
        };
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
        const tok = try self.currentToken();
        const selectorIndex = try self.reserve();
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

        const node = Node{
            .kind = NodeKind{ .Selector = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(selectorIndex, node);

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
        const tok = try self.currentToken();
        var factorIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        switch (tok.kind) {
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
            // or just simplified ifykyk
            // TODO: check that this works
            TokenKind.Number => {
                const numberToken = try self.expectAndYeildToken(TokenKind.Number);
                const numberNode = Node{
                    .kind = .{ .Number = undefined },
                    .token = numberToken,
                };
                lhsIndex = try self.astAppendNode(numberNode);
            },
            TokenKind.KeywordTrue => {
                const trueToken = try self.expectAndYeildToken(TokenKind.KeywordTrue);
                const trueNode = Node{
                    .kind = .{ .True = undefined },
                    .token = trueToken,
                };
                lhsIndex = try self.astAppendNode(trueNode);
            },
            TokenKind.KeywordFalse => {
                const falseToken = try self.expectAndYeildToken(TokenKind.KeywordFalse);
                const falseNode = Node{
                    .kind = .{ .False = undefined },
                    .token = falseToken,
                };
                lhsIndex = try self.astAppendNode(falseNode);
            },
            TokenKind.KeywordNull => {
                const nullToken = try self.expectAndYeildToken(TokenKind.KeywordNull);
                const nullNode = Node{
                    .kind = .{ .Null = undefined },
                    .token = nullToken,
                };
                lhsIndex = try self.astAppendNode(nullNode);
            },
            TokenKind.KeywordNew => {
                // Expect new
                const newToken = try self.expectAndYeildToken(.KeywordNew);
                const newNode = Node{
                    .kind = .{ .New = undefined },
                    .token = newToken,
                };
                lhsIndex = try self.astAppendNode(newNode);

                // Expect Identifier
                rhsIndex = try self.astAppendNode(try self.expectIdentifier());
            },
            else => {
                // TODO: make this error like the others
                return error.InvalidToken;
            },
        }
        const node = Node{
            .kind = NodeKind{ .Factor = .{ .lhs = lhsIndex, .rhs = rhsIndex } },
            .token = tok,
        };
        try self.set(factorIndex, node);
        return factorIndex;
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

const debugAlloc = std.heap.page_allocator; //std.testing.allocator;
const ting = std.testing;

// a helper for quickie testing (returns parser that hasn't had parseTokens called!)
fn testMe(source: []const u8) !Parser {
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    const parser = try Parser.init(tokens, source, debugAlloc);
    return parser;
}

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

test "types node empty for no types" {
    const source = "fun TS() void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    const parser = try Parser.parseTokens(tokens, source, debugAlloc);
    switch (parser.ast.items[0].kind) {
        .Types => |kind| {
            try std.testing.expectEqual(kind.lhs, null);
            try std.testing.expectEqual(kind.rhs, null);
        },
        else => {
            return error.Bre;
        },
    }
}

test "extractAtom.Num" {
    var parser = try testMe("123");
    const atom = try parser.extractAtom();
    const start: usize = 0;
    try ting.expectEqual(start, atom.start);
    const len: usize = 1;
    try ting.expectEqual(len, atom.len);
}

test "extractAtom.simple_parenthized_expr" {
    var parser = try testMe("(123)");
    const atom = try parser.extractAtom();
    const start: usize = 0;
    try ting.expectEqual(start, atom.start);
    const len: usize = 3;
    try ting.expectEqual(len, atom.len);
}

test "extractAtom.parenthized_expr" {
    var parser = try testMe("(123, 456, blah, blah, blahbutfkncallbre(), blah, 789, fkncall())");
    defer parser.deinit();
    const atom = try parser.extractAtom();
    const start: usize = 0;
    try ting.expectEqual(start, atom.start);
    const len: usize = 21;
    const atomLen: usize = @intCast(atom.len);
    // note: -1 for ignoring EOF because nobody cares
    try ting.expectEqual(len, atomLen);
}

test "extractAtom.selector" {
    var parser = try testMe("foo.bar.baz.fooagain");
    const atom = try parser.extractAtom();
    // std.debug.print("ATOM: {any}\n", .{parser.tokens[atom.start..(atom.start + atom.len)]});
    const start: usize = 0;
    const len: usize = 7;
    try ting.expectEqual(start, atom.start);
    try ting.expectEqual(len, atom.len);
}

fn expectAtomSliceTokenKinds(parser: *Parser, atom: Parser.ExprAtom, tokens: []const TokenKind) !void {
    const atomSlice = parser.tokens[atom.start..(atom.start + atom.len)];
    for (tokens, 0..) |token, i| {
        ting.expect(atomSlice.len > i) catch {
            std.debug.print("Atom Slice Missing Tokens: {any}\n", .{tokens[i..]});
            return error.OutofBounds;
        };
        ting.expectEqual(token, atomSlice[i].kind) catch {
            std.debug.print("Token mismatch at {d}: \nExpected: {}\n Got: {}\n", .{ i, token, atomSlice[i].kind });
            return error.InvalidToken;
        };
    }
}

test "extractAtom.funcall" {
    const source = "foo(1, 2, 3)";
    var parser = try testMe(source);
    const atom = try parser.extractAtom();
    const start: usize = 0;
    const len: usize = 8;
    const tokenKinds = [_]TokenKind{
        .Identifier, .LParen, .Number, .Comma, .Number, .Comma, .Number, .RParen,
    };
    try expectAtomSliceTokenKinds(&parser, atom, &tokenKinds);
    try ting.expectEqual(start, atom.start);
    try ting.expectEqual(len, atom.len);
}

test "extractAtom.new" {
    const source = "new foo";
    var parser = try testMe(source);
    const atom = try parser.extractAtom();
    const start: usize = 0;
    const len: usize = 2;
    const tokenKinds = [_]TokenKind{ .KeywordNew, .Identifier };
    try expectAtomSliceTokenKinds(&parser, atom, &tokenKinds);
    try ting.expectEqual(start, atom.start);
    try ting.expectEqual(len, atom.len);
}

test "extractAtom.new_in_fkncall" {
    const source = "fkncall(new foo, 1)";
    var parser = try testMe(source);
    const atom = try parser.extractAtom();
    const start: usize = 0;
    const len: usize = 7;
    const tokenKinds = [_]TokenKind{ .Identifier, .LParen, .KeywordNew, .Identifier, .Comma, .Number, .RParen };
    try expectAtomSliceTokenKinds(&parser, atom, &tokenKinds);
    try ting.expectEqual(start, atom.start);
    try ting.expectEqual(len, atom.len);
}

test "pratt.simple_pemdas" {
    var parser = try testMe("1 + 2 * 3");
    const expr = try parser.prattParseExpression(debugAlloc, 0);
    std.log.info("TREE: {}\n", .{expr.*});
    try ting.expectEqual(TokenKind.Plus, expr.*.Binop.op.kind);
    try ting.expect(expr.*.Binop.rhs.* == .Binop);
    try ting.expect(expr.*.Binop.lhs.* == .Atom);
    try ting.expectEqual(expr.*.Binop.lhs.*.Atom.len, 1);
    try ting.expectEqual(expr.*.Binop.rhs.*.Binop.op.kind, TokenKind.Mul);
    try ting.expectEqual(expr.*.Binop.rhs.*.Binop.lhs.*.Atom.start, 2);
    try ting.expectEqual(expr.*.Binop.rhs.*.Binop.lhs.*.Atom.len, 1);
    try ting.expectEqual(expr.*.Binop.rhs.*.Binop.rhs.*.Atom.start, 4);
    try ting.expectEqual(expr.*.Binop.rhs.*.Binop.rhs.*.Atom.len, 1);
}

// FIXME:
test "pratt.funcall" {
    var parser = try testMe("foo(1, 2, 3)");
    const expr = try parser.prattParseExpression(debugAlloc, 0);
    try ting.expect(expr.* == .Atom);
    try ting.expect(expr.*.Atom.start == 0);
    try ting.expect(expr.*.Atom.len == 8);
}

test "parseArguments" {
    const source = "(new y, 2 + 2)";
    var parser = try testMe(source);
    const argsIndex = try parser.parseArguments();

    try ting.expectEqual(argsIndex, 0);

    const items = parser.ast.items;
    try ting.expect(items[0].kind == .Arguments);

    // new y
    try ting.expect(items[1].kind == .Expression);
    try ting.expect(items[2].kind == .Selector);
    try ting.expect(items[3].kind == .Factor);
    try ting.expect(items[4].kind == .New);
    try ting.expect(items[5].kind == .Identifier);

    // 2 + 2
    try ting.expect(items[6].kind == .Expression);
    try ting.expect(items[7].kind == .BinaryOperation);

    // 2 +
    try ting.expect(items[8].kind == .Selector);
    try ting.expect(items[9].kind == .Factor);
    try ting.expect(items[10].kind == .Number);

    // + 2
    try ting.expect(items[11].kind == .Selector);
    try ting.expect(items[12].kind == .Factor);
    try ting.expect(items[13].kind == .Number);
}

// FIXME:
test "pratt.reconstruct.funcall" {
    var parser = try testMe("1 + foo(x, new y, x + 1)");
    const expr = try parser.prattParseExpression(debugAlloc, 0);
    const treeIndex = try parser.reconstructTree(expr);
    std.log.info("TREE: {}\n", .{treeIndex});
    try parser.prettyPrintAst();
    const items = parser.ast.items;
    try ting.expect(items[0].kind == .BinaryOperation);

    // WARN: I'm going to remove this indirection... I just can't
    // also going to make it so related nodes are never siblings and you can't stop me
    // i.e. function is not [id, args] it is [func -> (id, args)]
    try ting.expect(items[0].token.kind == .Plus);
    try ting.expect(items[1].kind == .Selector);
    try ting.expect(items[2].kind == .Factor);
    try ting.expect(items[3].kind == .Number);

    try ting.expect(items[4].kind == .Selector);
    try ting.expect(items[5].kind == .Factor);
    try ting.expect(items[6].kind == .Identifier);
    // TODO: ... finish
}

test "getTypeNumber.keywords" {
    const source = "";
    var parser = try testMe(source);
    try ting.expectEqual(parser.getTypeNumber("int"), 0);
    try ting.expectEqual(parser.getTypeNumber("bool"), 1);
    try ting.expectEqual(parser.getTypeNumber("int_array"), 2);
}

test "getTypeNumber.structsSimple" {
    const source = "struct A{int a;}; struct B{int b;};";
    var parser = try testMe(source);
    try parser.parseProgram();
    try ting.expectEqual(parser.getTypeNumber("A"), 3);
    try ting.expectEqual(parser.getTypeNumber("B"), 4);
}
