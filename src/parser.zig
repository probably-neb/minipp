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
const NodeList = @import("ast.zig").NodeList;

const utils = @import("utils.zig");
const log = @import("log.zig");

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
pub const Parser = struct {
    tokens: []Token,
    input: []const u8,

    ast: NodeList,
    astLen: usize = 0,

    pos: usize = 0,
    readPos: usize = 1,
    idMap: std.StringHashMap(bool),

    allocator: std.mem.Allocator,

    // flags
    showParseTree: bool = false,
    allowNoMain: bool = @import("builtin").is_test,

    pub fn init(tokens: []Token, input: []const u8, allocator: std.mem.Allocator) !Parser {
        var parser = Parser{
            .ast = try std.ArrayList(Node).initCapacity(allocator, tokens.len),
            .idMap = std.StringHashMap(bool).init(allocator),
            .tokens = tokens,
            .input = input,
            .readPos = if (tokens.len > 0) 1 else 0,
            .allocator = allocator,
        };

        return parser;
    }

    pub fn deinit(self: *Parser) void {
        self.allocator.free(self.tokens);
        self.idMap.deinit();
    }

    pub fn parseTokens(tokens: []Token, input: []const u8, allocator: std.mem.Allocator) !Parser {
        var parser = try Parser.init(tokens, input, allocator);
        parser.parseProgram() catch |err| {
            log.err("Error in parsing the program.\n", .{});
            parser.deinit();
            return err;
        };
        return parser;
    }

    fn peekToken(self: *Parser) !Token {
        if (self.readPos >= self.tokens.len) return error.TokenIndexOutOfBounds;
        return self.tokens[self.readPos];
    }

    fn peekNTokens(self: *Parser, n: usize) !Token {
        if (self.readPos + n >= self.tokens.len) return error.TokenIndexOutOfBounds;
        return self.tokens[self.readPos + n];
    }

    // TODO : create currentTokenThatShouldBe function for more checks and
    // easier bug finding (supposedly (my opinions are my own))
    fn currentToken(self: *Parser) !Token {
        if (self.pos >= self.tokens.len) return error.TokenIndexOutOfBounds;
        return self.tokens[self.pos];
    }

    fn consumeToken(self: *Parser) !Token {
        if (self.pos >= self.tokens.len) {
            log.err("Error Consuming Token: Out of bounds @ Token# {d}/{d}\n The last token was: {s}.\n", .{ self.readPos, self.tokens.len, @tagName((try self.currentToken()).kind) });
            log.err("Hit EOF before expected.\n", .{});
            return error.TokenIndexOutOfBounds;
        }
        const token = self.tokens[self.pos];
        self.pos = self.readPos;
        self.readPos += 1;
        return token;
    }

    fn expectToken(self: *Parser, kind: TokenKind) !void {
        const token = self.consumeToken() catch |err| {
            log.err("Error could not find expected Token: {s}\n", .{@tagName(kind)});
            return err;
        };
        if (!token.kind.equals(kind)) {
            // TODO: should update with the desired changes to TokenKind, such that the position is found.
            // Refactored for the moment
            log.err("Error invalid Token at {d}: expected token kind {s} but got {s}.\n", .{ @max(self.pos, 1) - 1, @tagName(kind), @tagName(token.kind) });
            const line: []const u8 = token._range.getLineCont(self.input);
            log.err("{s}\n", .{line});
            token._range.printLineContUnderline(self.input);
            return error.InvalidToken;
        }
    }

    fn expectAndYeildToken(self: *Parser, kind: TokenKind) !Token {
        const token = self.consumeToken() catch |err| {
            log.err("Error could not yeild expected Token: {s}\n", .{@tagName(kind)});
            return err;
        };
        if (token.kind.equals(kind)) {
            return token;
        }
        // TODO: should update with the desired changes to TokenKind, such that the position is found.
        // Refactored for the moment
        log.err("Error invalid Token: expected token kind {s} but got {s}.\n", .{ @tagName(kind), @tagName(token.kind) });
        log.err("{s}\n", .{token._range.getLineCont(self.input)});
        token._range.printLineContUnderline(self.input);
        return error.InvalidToken;
    }

    fn expectIdentifier(self: *Parser) !Node {
        const token = self.expectAndYeildToken(TokenKind.Identifier) catch |err| {
            log.err("Error could not yeild Identifier.\n", .{});
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
        log.info("AST:{{\n", .{});
        while (i < self.astLen) {
            const node = ast[i];
            const token = node.token;
            const tokenStr = token._range.getSubStrFromStr(self.input);
            const kind = @tagName(node.kind);
            log.info("{s}: {s}\n", .{ kind, tokenStr });
            i += 1;
        }
        log.info("}}\n", .{});
    }

    /// reserves a location using the BackFillReserve Node
    /// NOTE: does not call any token consuming functions, expects
    /// the caller to handle tokens
    fn reserve(self: *Parser) !usize {
        const index = self.astLen;
        const node = Node{ .kind = .BackfillReserve, .token = Token{
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

    ///////////////////////////////////////////////////////////////////////////
    /// Parser Grammar Functions
    ///////////////////////////////////////////////////////////////////////////

    // Program = Types Declarations Functions
    // each sub function returns an u32, which is the index into the array where they start
    pub fn parseProgram(self: *Parser) !void {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Program\n", .{});
                log.err("Defined as: Program = Types Declarations Functions\n", .{});
            }
        }

        var progToken = try self.currentToken();
        // Init indexes
        var programIndex = try self.reserve();

        const programDeclarationsIndex = try self.reserve();
        // Expect Types
        const programTypesIndex = try self.parseTypes();

        // Expect Declarations
        // Functions will be rhsIndex
        const programGlobalDeclarationsIndex = try self.parseLocalDeclarations();

        const programDeclarationsNode = Node{
            .kind = .{ .ProgramDeclarations = .{
                .types = programTypesIndex,
                .declarations = programGlobalDeclarationsIndex,
            } },
            .token = progToken,
        };
        try self.set(programDeclarationsIndex, programDeclarationsNode);

        // Expect Functions
        const functionsIndex = try self.parseFunctions();

        // Expect EOF
        // TODO: make sure that Eof gets assigned propperly
        try self.expectToken(TokenKind.Eof);

        const progNode = Node{
            .kind = NodeKind{ .Program = .{ .declarations = programDeclarationsIndex, .functions = functionsIndex } },
            .token = progToken,
        };
        try self.set(programIndex, progNode);
    }

    // Types = { TypeDeclaration }*
    // returns null when no types declared
    pub fn parseTypes(self: *Parser) !?usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing Types\n", .{});
                log.err("Defined as: Types = {{ TypeDeclaration }}*\n", .{});
            }
        }
        // Init indexes
        const typesToken = try self.currentToken();
        const typesIndex = try self.reserve();

        if ((try self.currentToken()).kind != .KeywordStruct) {
            return null;
        }

        const firstTypeIndex = try self.parseTypeDeclaration();

        var lastTypeIndex: ?usize = null;
        // // While not EOF then parse TypeDeclaration
        // // Expect (TypeDeclaration)*
        while ((try self.currentToken()).kind == TokenKind.KeywordStruct) {
            // peek to see if we are now doing globals
            if ((try self.peekNTokens(1)).kind != TokenKind.LCurly) {
                return null;
            }
            lastTypeIndex = try self.parseTypeDeclaration();
        }
        const node = Node{ .kind = NodeKind{ .Types = .{ .firstType = firstTypeIndex, .lastType = lastTypeIndex } }, .token = typesToken };
        try self.set(typesIndex, node);

        return typesIndex;
    }

    // TypeDeclaration = "struct" Identifier "{" NestedDeclarations "}" ";"
    // Refactored
    pub fn parseTypeDeclaration(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a TypeDelcaration\n", .{});
                log.err("Defined as: TypeDeclaration = \"struct\" Identifier {{ NestedDeclarations }} \";\"\n", .{});
            }
        }

        // Init indexes
        const tok = try self.currentToken();
        var typeNodeIndex = try self.reserve();
        var identIndex: usize = undefined;
        var declarationsIndex: usize = undefined;

        // Exepect struct
        try self.expectToken(TokenKind.KeywordStruct);

        // Expect identifier
        identIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect nested declarations
        declarationsIndex = try self.parseStructFieldDeclarations();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .TypeDeclaration = .{ .ident = identIndex, .declarations = declarationsIndex } },
            .token = tok,
        };

        try self.set(typeNodeIndex, node);

        // convert to array
        return typeNodeIndex;
    }

    // NestedDecl = { Decl ";" }+
    pub fn parseStructFieldDeclarations(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing NestedDeclarations\n", .{});
                log.err("Defined as: NestedDeclarations = {{ Decl \";\" }}+\n", .{});
            }
        }

        // Init indexes
        const tok = try self.currentToken();
        var nestedDeclarationsIndex = try self.reserve();
        // var nestedDeclarationsIndex = try self.astAppend(, try self.currentToken());
        var lhsIndex: usize = undefined;
        var rhsIndex: ?usize = null;

        // Expect { Decl ";" }+
        // i.e. at least one declaration
        lhsIndex = try self.parseStructFieldDeclaration();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        // Repeat
        while ((try self.currentToken()).kind != TokenKind.RCurly) {
            rhsIndex = try self.parseStructFieldDeclaration();
            try self.expectToken(TokenKind.Semicolon);
        }

        const node = Node{
            .kind = NodeKind{ .StructFieldDeclarations = .{ .firstDecl = lhsIndex, .lastDecl = rhsIndex } },
            .token = tok,
        };
        try self.set(nestedDeclarationsIndex, node);

        return nestedDeclarationsIndex;
    }

    // Decl = Type Identifier
    pub fn parseStructFieldDeclaration(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Decl\n", .{});
                log.err("Defined as: Decl = Type Identifier\n", .{});
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
            .kind = NodeKind{ .TypedIdentifier = .{ .type = typeIndex, .ident = identIndex } },
            .token = tok,
        };

        try self.set(declIndex, node);

        return declIndex;
    }

    // Type = "int" | "bool" | "struct" Identifier
    pub fn parseType(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Type\n", .{});
                log.err("Defined as: Type = \"int\" | \"bool\" | \"struct\" Identifier\n", .{});
            }
        }

        // Init indexes
        const tok = try self.currentToken();
        var typeIndex = try self.reserve();
        var kindIndex: usize = undefined;
        var structIdentifierIndex: ?usize = null;

        const token = try self.consumeToken();

        // Expect int | bool | struct (id)
        switch (token.kind) {
            TokenKind.KeywordInt => {
                const kind = NodeKind.IntType;
                kindIndex = try self.astAppend(kind, token);
            },
            TokenKind.KeywordBool => {
                kindIndex = try self.astAppend(NodeKind.BoolType, token);
            },
            TokenKind.KeywordStruct => {
                kindIndex = try self.astAppend(NodeKind.StructType, token);
                structIdentifierIndex = try self.astAppendNode(try self.expectIdentifier());
            },
            else => {
                // TODO: make this error like the others
                log.err("Error invalid Token: expected token kind {s} | {s} | {s} but got {s}.\n", .{ @tagName(TokenKind.KeywordInt), @tagName(TokenKind.KeywordBool), @tagName(TokenKind.KeywordStruct), @tagName(token.kind) });
                const line: []const u8 = token._range.getLineCont(self.input);
                log.err("{s}\n", .{line});
                token._range.printLineContUnderline(self.input);
                return error.InvalidToken;
            },
        }
        const node = Node{
            .kind = NodeKind{ .Type = .{ .kind = kindIndex, .structIdentifier = structIdentifierIndex } },
            .token = tok,
        };
        try self.set(typeIndex, node);

        return typeIndex;
    }

    // Declarations = { Declaration }*
    // returns null if no declarations
    pub fn parseLocalDeclarations(self: *Parser) !?usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing Declarations\n", .{});
                log.err("Defined as: Declarations = {{ Declaration }}*\n", .{});
            }
        }
        if (!(try self.isCurrentTokenAType())) {
            return null;
        }
        // Init indexes
        const tok = try self.currentToken();
        var declarationsIndex = try self.reserve();

        // While not EOF or function keyword then parse declaration
        // Expect (Declaration)*
        const firstDeclIndex = try self.parseDeclaration();

        var lastDeclIndex: ?usize = null;
        while (try self.isCurrentTokenAType()) {
            // Expect Declaration
            lastDeclIndex = try self.parseDeclaration();
        }

        const node = Node{
            .kind = NodeKind{ .LocalDeclarations = .{ .firstDecl = firstDeclIndex, .lastDecl = lastDeclIndex } },
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
                log.err("Error in parsing a Declaration\n", .{});
                log.err("Defined as: Declaration = Type Identifier (\",\" Identifier)* \";\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        const firstDeclIndex = try self.reserve();

        // Expect type
        const typeIndex = try self.parseType();

        // Expect Identifier
        const firstIdentIndex = try self.astAppendNode(try self.expectIdentifier());

        const firstDeclNode = Node{
            .kind = NodeKind{ .TypedIdentifier = .{ .type = typeIndex, .ident = firstIdentIndex } },
            .token = tok,
        };
        try self.set(firstDeclIndex, firstDeclNode);

        // Expect ("," Identifier)* ";"
        while ((try self.currentToken()).kind != TokenKind.Semicolon) {
            // Expect ,
            try self.expectToken(TokenKind.Comma);
            const localDeclIndex = try self.reserve();

            // Expect Identifier
            const identIndex = try self.astAppendNode(try self.expectIdentifier());
            const localDeclNode = Node{
                .kind = NodeKind{ .TypedIdentifier = .{ .type = typeIndex, .ident = identIndex } },
                .token = try self.currentToken(),
            };
            // Repeat
            try self.set(localDeclIndex, localDeclNode);
        }

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        return firstDeclIndex;
    }

    // Functions = ( Function )*
    pub fn parseFunctions(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing Functions\n", .{});
                log.err("Defined as: Functions = ( Function )*\n", .{});
            }
        }
        // init indexes
        const tok = try self.currentToken();
        var functionsIndex = try self.reserve();

        const firstFuncIndex = self.parseFunction() catch {
            if (self.allowNoMain) {
                // It's really annoying to have to provide a main for test cases
                log.warn("Ignoring no main in test...\n", .{});
                return 0;
            }
            log.err("Error in parsing Functions, expected a function.\n", .{});
            log.err("At least one function (main;) must be defined.\n", .{});
            return error.InvalidProgram;
        };

        var lastFuncIndex: ?usize = null;
        // While not EOF then parse function
        // Expect (Function)*
        while ((try self.currentToken()).kind == TokenKind.KeywordFun) {
            lastFuncIndex = try self.parseFunction();
        }
        // FIXME: having no functions is an error, at least one (main) function is required
        // but I am assuming we will handle it in semantic analysis

        const node = Node{
            .kind = NodeKind{ .Functions = .{ .firstFunc = firstFuncIndex, .lastFunc = lastFuncIndex } },
            .token = tok,
        };
        try self.set(functionsIndex, node);

        return functionsIndex;
    }

    // Function = "fun" Identifier Paramaters ReturnType "{" Declarations StatementList "}"
    pub fn parseFunction(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Function\n", .{});
                log.err("Defined as: Function = \"fun\" Identifier Paramaters ReturnType \"{{\" Declarations StatementList \"}}\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var functionIndex = try self.reserve();

        const protoIndex = try self.parseFunctionProto();

        const bodyIndex = try self.parseFunctionBody();

        const node = Node{
            .kind = NodeKind{ .Function = .{ .proto = protoIndex, .body = bodyIndex } },
            .token = tok,
        };
        try self.set(functionIndex, node);
        _ = try self.astAppend(.FunctionEnd, tok);

        return functionIndex;
    }

    /// parse identifier, parameters, returntype
    pub fn parseFunctionProto(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Function\n", .{});
                log.err("Defined as: Function = \"fun\" Identifier Paramaters ReturnType \"{{\" Declarations StatementList \"}}\"\n", .{});
            }
        }
        const tok = try self.currentToken();
        const protoIndex = try self.reserve();
        const typedIdentIndex = try self.reserve();

        try self.expectToken(TokenKind.KeywordFun);

        const identToken = try self.currentToken();
        const funcNameIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect Parameters
        const paramsIndex = try self.parseParameters();

        // Expect ReturnType
        const returnTypeIndex = try self.parseReturnType();

        const typedIdentNode = Node{
            .kind = .{ .ReturnTypedIdentifier = .{ .ident = funcNameIndex, .type = returnTypeIndex } },
            .token = identToken,
        };
        try self.set(typedIdentIndex, typedIdentNode);

        const protoNode = Node{
            .kind = .{ .FunctionProto = .{ .name = typedIdentIndex, .parameters = paramsIndex } },
            .token = tok,
        };
        try self.set(protoIndex, protoNode);
        return protoIndex;
    }

    /// `Parameters = "(" (Decl ("," Decl)* )? ")"`
    /// returns null if next token is `.RParen` aka no parameters
    pub fn parseParameters(self: *Parser) !?usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing Parameters\n", .{});
                log.err("Defined as: Parameters = \"(\" (Decl (\",\" Decl)* )? \")\"\n", .{});
            }
        }

        // return null if no params
        const nextTok = try self.peekToken();
        if (nextTok.kind == TokenKind.RParen) {
            try self.expectToken(.LParen);
            try self.expectToken(.RParen);
            return null;
        }

        // Init indexes
        const tok = try self.currentToken();
        var parametersIndex = try self.reserve();
        var lhsIndex: ?usize = null;
        var rhsIndex: ?usize = null;

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // FIXME: I think this is supposed to be parsing params like go params,
        // where you can have multiple args with the same type like so (in mini syntax)
        // `fun (int a, b, c, bool foo)`
        // but I am not sure that is valid syntax, I believe based on the grammar it should be
        // `fun (int a, int b, int c, bool foo)`
        while (try self.isCurrentTokenAType()) {
            // Expect Decl
            lhsIndex = try self.parseStructFieldDeclaration();
            // Expect ("," Decl)*

            while ((try self.currentToken()).kind == TokenKind.Comma) {
                // Expect ,
                try self.expectToken(TokenKind.Comma);
                // Expect Decl
                rhsIndex = try self.parseStructFieldDeclaration();
            }
        }

        // Expect )
        try self.expectToken(TokenKind.RParen);

        const node = Node{
            .kind = NodeKind{ .Parameters = .{ .firstParam = lhsIndex.?, .lastParam = rhsIndex } },
            .token = tok,
        };
        try self.set(parametersIndex, node);
        return parametersIndex;
    }

    // ReturnType = Type | "void"
    pub fn parseReturnType(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing ReturnType\n", .{});
                log.err("Defined as: ReturnType = Type | \"void\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var returnTypeIndex = try self.reserve();

        var typeIndex: ?usize = null;

        if (tok.kind == .KeywordVoid) {
            // leave typeIndex as null
            try self.expectToken(TokenKind.KeywordVoid);
        } else {
            typeIndex = try self.parseType();
        }

        const node = Node{
            .kind = NodeKind{ .ReturnType = .{ .type = typeIndex } },
            .token = tok,
        };
        try self.set(returnTypeIndex, node);

        return returnTypeIndex;
    }

    pub fn parseFunctionBody(self: *Parser) !usize {
        const tok = try self.currentToken();

        const bodyIndex = try self.reserve();
        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect Declarations
        const declarationsIndex = try self.parseLocalDeclarations();

        // Expect StatementList
        const statementsIndex = try self.parseStatementList();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        const bodyNode = Node{
            .kind = .{ .FunctionBody = .{ .declarations = declarationsIndex, .statements = statementsIndex } },
            .token = tok,
        };
        try self.set(bodyIndex, bodyNode);
        return bodyIndex;
    }

    // Statement = Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation
    pub fn parseStatement(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Statement\n", .{});
                log.err("Defined as: Statement = Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var statementIndex = try self.reserve();
        var lhsIndex: ?usize = null;

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
                log.err("Error invalid Token: expected token kind of Statment \n", .{});
                const line: []const u8 = (try self.currentToken())._range.getLineCont(self.input);
                log.err("{s}\n", .{line});
                (try self.currentToken())._range.printLineContUnderline(self.input);
                return error.InvalidToken;
            },
        }

        const node = Node{
            .kind = NodeKind{ .Statement = .{ .statement = lhsIndex.?, .finalIndex = self.ast.items.len } },
            .token = tok,
        };
        try self.set(statementIndex, node);

        return statementIndex;
    }

    /// `StatementList = ( Statement )*`
    /// returns null if there are no statements (current token is )
    /// TODO: test that it works with no statements
    pub fn parseStatementList(self: *Parser) ParserError!?usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a StatementList\n", .{});
                log.err("Defined as: StatementList = ( Statement )*\n", .{});
            }
        }

        // Init indexes
        const tok = try self.currentToken();
        if (tok.kind == TokenKind.RCurly) {
            return null;
        }
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
            .kind = NodeKind{ .StatementList = .{ .firstStatement = lhsIndex.?, .lastStatement = rhsIndex } },
            .token = tok,
        };
        try self.set(statementListIndex, node);

        return statementListIndex;
    }

    // Block = "{" StatementList "}"
    pub fn parseBlock(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Block\n", .{});
                log.err("Defined as: Block = \"{{\" StatementList \"}}\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var blockIndex = try self.reserve();

        // Expect {
        try self.expectToken(TokenKind.LCurly);

        // Expect StatementList
        const statementsIndex = try self.parseStatementList();

        // Expect }
        try self.expectToken(TokenKind.RCurly);

        const node = Node{
            .kind = NodeKind{ .Block = .{ .statements = statementsIndex } },
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
                log.err("Error in parsing an Assignment\n", .{});
                log.err("Defined as: Assignment = LValue = (Expression | \"read\") \";\"\n", .{});
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
                .kind = NodeKind.Read,
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
                log.err("Error in parsing a Print type\n", .{});
                log.err("Defined as: Print = \"print\" Expression \";\"\n", .{});
            }
            log.err("Or defined as: PrintLn = \"print\" Expression \"endl\" \";\"\n", .{});
        }
        // Init indexes
        const tok = try self.currentToken();
        var printIndex = try self.reserve();

        // Expect print
        try self.expectToken(TokenKind.KeywordPrint);

        // Expect Expression
        const exprIndex = try self.parseExpression();

        var hasEndl = false;

        switch ((try self.currentToken()).kind) {
            // Expect ;
            TokenKind.Semicolon => {
                try self.expectToken(TokenKind.Semicolon);
            },
            // Expect endl ;
            TokenKind.KeywordEndl => {
                try self.expectToken(TokenKind.KeywordEndl);
                try self.expectToken(TokenKind.Semicolon);
                hasEndl = true;
            },
            else => {
                log.err("expected ; or endl but got {s}.", .{@tagName((try self.currentToken()).kind)});
                return error.InvalidToken;
            },
        }

        const node = Node{
            .kind = NodeKind{ .Print = .{ .expr = exprIndex, .hasEndl = hasEndl } },
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
                log.err("Error in parsing a Conditional\n", .{});
                log.err("Defined as: ConditionalIf = \"if\" \"(\" Expression \")\" Block\n", .{});
                log.err("Or defined as: ConditionalIfElse = \"if\" \"(\" Expression \")\" Block \"else\" Block\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var conditionalIfIndex = try self.reserve();

        // Expect if
        try self.expectToken(TokenKind.KeywordIf);

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // Expect Expression
        const condIndex = try self.parseExpression();

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // Expect Block
        var blockIndex = try self.parseBlock();

        // If else then parse else block
        if ((try self.currentToken()).kind == TokenKind.KeywordElse) {
            const ifElseIndex = try self.reserve();
            // Expect else
            try self.expectToken(TokenKind.KeywordElse);
            // Expect Block
            const elseBlockIndex = try self.parseBlock();
            const ifElseNode = Node{
                .kind = NodeKind{ .ConditionalIfElse = .{ .ifBlock = blockIndex, .elseBlock = elseBlockIndex } },
                .token = tok,
            };
            try self.set(ifElseIndex, ifElseNode);
            blockIndex = ifElseIndex;
        }

        const node = Node{
            .kind = NodeKind{ .ConditionalIf = .{ .cond = condIndex, .block = blockIndex } },
            .token = tok,
        };
        try self.set(conditionalIfIndex, node);

        return conditionalIfIndex;
    }

    // While = "while" "(" Expression ")" Block
    /// While goes like this:
    /// [[While, expression, block]]
    ///           lhs         rhs
    pub fn parseWhile(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a While\n", .{});
                log.err("Defined as: While = \"while\" \"(\" Expression \")\" Block\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var whileIndex = try self.reserve();

        // Expect while
        try self.expectToken(TokenKind.KeywordWhile);

        // Expect (
        try self.expectToken(TokenKind.LParen);

        // Expect Expression
        const condIndex = try self.parseExpression();

        // Expect )
        try self.expectToken(TokenKind.RParen);

        // Expect Block
        const blockIndex = try self.parseBlock();

        const node = Node{
            .kind = NodeKind{ .While = .{ .cond = condIndex, .block = blockIndex } },
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
                log.err("Error in parsing a Delete\n", .{});
                log.err("Defined as: Delete = \"delete\" Expression \";\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var deleteIndex = try self.reserve();

        // Expect delete
        try self.expectToken(TokenKind.KeywordDelete);

        // Expect Expression
        const exprIndex = try self.parseExpression();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .Delete = .{ .expr = exprIndex } },
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
                log.err("Error in parsing a Return\n", .{});
                log.err("Defined as: Return = \"return\" (Expression)?  \";\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var returnIndex = try self.reserve();
        var exprIndex: ?usize = null;

        // Expect return
        try self.expectToken(TokenKind.KeywordReturn);

        // Expect Expression optionally
        if ((try self.currentToken()).kind != TokenKind.Semicolon) {
            log.err("Expected an expression after return.\n", .{});
            // Expect Expression
            exprIndex = try self.parseExpression();
        }

        const node = Node{
            .kind = NodeKind{ .Return = .{ .expr = exprIndex } },
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
                log.err("Error in parsing an Identifier\n", .{});
                log.err("Defined as: Invocation = Identifier Arguments \";\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var invocationIndex = try self.reserve();

        // Expect Identifier
        const funcNameIndex = try self.astAppendNode(try self.expectIdentifier());

        // Expect Arguments
        const argsIndex = try self.parseArguments();

        // Expect ;
        try self.expectToken(TokenKind.Semicolon);

        const node = Node{
            .kind = NodeKind{ .Invocation = .{ .funcName = funcNameIndex, .args = argsIndex } },
            .token = tok,
        };
        try self.set(invocationIndex, node);

        return invocationIndex;
    }

    // LValue = Identifier ("." Identifier)*
    pub fn parseLValue(self: *Parser) !usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing an LValue\n", .{});
                log.err("Defined as: LValue = Identifier (\".\" Identifier)*\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var lValueIndex = try self.reserve();

        // Expect Identifier
        const identIndex = try self.astAppendNode(try self.expectIdentifier());

        const chainIndex = try self.parseSelectorChain();

        const node = Node{
            .kind = NodeKind{ .LValue = .{ .ident = identIndex, .chain = chainIndex } },
            .token = tok,
        };
        try self.set(lValueIndex, node);

        return lValueIndex;
    }

    // Arguments = "(" (Expression ("," Expression)*)? ")"
    // returns null when no arguments are present (`funcName()`)
    pub fn parseArguments(self: *Parser) !?usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing Arguments\n", .{});
                log.err("Defined as: Arguments = \"(\" (Expression (\",\" Expression)*)? \")\"\n", .{});
            }
        }

        // Expect (
        try self.expectToken(TokenKind.LParen);

        if ((try self.currentToken()).kind == TokenKind.RParen) {
            // Expect )
            try self.expectToken(TokenKind.RParen);
            // return null for no args
            return null;
        }

        // Init indexes (after checking if there are any args at all)
        const tok = try self.currentToken();
        var argumentsIndex = try self.reserve();

        // Expect (Expression ("," Expression)*)?
        // Expect Expression
        const firstArgIndex = try self.parseExpression();

        var lastArgIndex: ?usize = null;

        // Expect ("," Expression)*
        while ((try self.currentToken()).kind == TokenKind.Comma) {
            // Expect ,
            try self.expectToken(TokenKind.Comma);
            // Expect Expression
            lastArgIndex = try self.parseExpression();
        }

        // Expect )
        try self.expectToken(TokenKind.RParen);

        const node = Node{
            .kind = NodeKind{ .Arguments = .{ .firstArg = firstArgIndex, .lastArg = lastArgIndex } },
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
                        .on = onIndex,
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
                log.err("Error in parsing an Expression\n", .{});
                log.err("Defined as: Expression = boolterm (\"||\" boolterm)*\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        const expressionIndex = try self.reserve();

        var arenaAlloc = std.heap.ArenaAllocator.init(self.allocator);
        defer arenaAlloc.deinit();
        var arena = arenaAlloc.allocator();

        const expr = try self.prattParseExpression(arena, 0);
        log.info("\nEXTRACTED: {any}\n", .{expr});
        const treeIndex = try self.reconstructTree(expr);

        // NOTE: unessary?
        const node = Node{
            .kind = NodeKind{ .Expression = .{ .expr = treeIndex } },
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
                log.err("Invalid atom\nbre wth is this: {any}", .{startTok});
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
                log.err("Error in parsing a Selector\n", .{});
                log.err("Defined as: Selector = Factor (\".\" Identifier)*\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        const selectorIndex = try self.reserve();

        // Expect Factor
        const factorIndex = try self.parseFactor();

        const chainIndex = try self.parseSelectorChain();

        const node = Node{
            .kind = NodeKind{ .Selector = .{ .factor = factorIndex, .chain = chainIndex } },
            .token = tok,
        };
        try self.set(selectorIndex, node);

        return selectorIndex;
    }

    /// Parses a chain of selectors
    /// `{ "." Identifier }*`
    /// expects caller to parse first item in chain
    /// i.e. Factor for `Selector` and `Identifier` for `LValue`
    pub fn parseSelectorChain(self: *Parser) !?usize {
        var chainIndex: ?usize = null;

        var curChainIndex: ?usize = null;

        // Expect ("." Identifier)*
        while ((try self.currentToken()).kind == TokenKind.Dot) {
            const chainNodeIndex = try self.reserve();
            if (chainIndex == null) {
                chainIndex = chainNodeIndex;
            }
            // Expect .
            const dotToken = try self.expectAndYeildToken(TokenKind.Dot);
            // Expect Identifier
            const identIndex = try self.astAppendNode(try self.expectIdentifier());
            const chainNode = Node{
                .kind = .{ .SelectorChain = .{ .ident = identIndex, .next = null } },
                .token = dotToken,
            };
            try self.set(chainNodeIndex, chainNode);

            if (curChainIndex) |cci| {
                self.ast.items[cci].kind.SelectorChain.next = chainNodeIndex;
            }
            curChainIndex = chainNodeIndex;
        }
        return chainIndex;
    }

    // Factor = "(" Expression ")" | Identifier (Arguments)? | Number | "true" | "false" | "new" Identifier | "null"
    pub fn parseFactor(self: *Parser) ParserError!usize {
        errdefer {
            if (self.showParseTree) {
                log.err("Error in parsing a Factor\n", .{});
                log.err("Defined as: Factor = \"(\" Expression \")\" | Identifier (Arguments)? | Number | \"true\" | \"false\" | \"new\" Identifier | \"null\"\n", .{});
            }
        }
        // Init indexes
        const tok = try self.currentToken();
        var factorIndex = try self.reserve();
        var lhsIndex: ?usize = null;

        // FIXME: remove Factor node and just return `lhsIndex`, rhsIndex is never used
        // We never iterate over a list of Factors like we do with Statements,
        // so it is not necessary to have the top level node indicating the start of a new subtree
        // as there is with statements
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
                const peekTokenKind = (try self.peekToken()).kind;
                if (peekTokenKind == .LParen) {
                    // function invocation
                    // FIXME: this repeats the logic in `parseInvocation`
                    // however, parseInvocation expects a trailing semicolon
                    // should call parseInvocation here, and either expect the semicolon
                    // in the other calling sites of parseInvocation, or have parseInvocation
                    // take a parameter to indicate if it should expect a semicolon

                    const invocIndex = try self.reserve();

                    const ident = try self.expectIdentifier();
                    const funcNameIndex = try self.astAppendNode(ident);
                    const argsIndex = try self.parseArguments();

                    const invocNode = Node{
                        .kind = .{ .Invocation = .{ .funcName = funcNameIndex, .args = argsIndex } },
                        .token = tok,
                    };
                    try self.set(invocIndex, invocNode);

                    lhsIndex = invocIndex;
                } else {
                    // Expect Identifier
                    lhsIndex = try self.astAppendNode(try self.expectIdentifier());
                }
            },
            // Theese could all be refactored into a helper function
            // or just simplified ifykyk
            // TODO: check that this works
            TokenKind.Number => {
                const numberToken = try self.expectAndYeildToken(TokenKind.Number);
                const numberNode = Node{
                    .kind = .Number,
                    .token = numberToken,
                };
                lhsIndex = try self.astAppendNode(numberNode);
            },
            TokenKind.KeywordTrue => {
                const trueToken = try self.expectAndYeildToken(TokenKind.KeywordTrue);
                const trueNode = Node{
                    .kind = .True,
                    .token = trueToken,
                };
                lhsIndex = try self.astAppendNode(trueNode);
            },
            TokenKind.KeywordFalse => {
                const falseToken = try self.expectAndYeildToken(TokenKind.KeywordFalse);
                const falseNode = Node{
                    .kind = .False,
                    .token = falseToken,
                };
                lhsIndex = try self.astAppendNode(falseNode);
            },
            TokenKind.KeywordNull => {
                const nullToken = try self.expectAndYeildToken(TokenKind.KeywordNull);
                const nullNode = Node{
                    .kind = .Null,
                    .token = nullToken,
                };
                lhsIndex = try self.astAppendNode(nullNode);
            },
            TokenKind.KeywordNew => {
                // Expect new
                const newToken = try self.expectAndYeildToken(.KeywordNew);
                const newIndex = try self.reserve();

                // Expect Identifier
                const identIndex = try self.astAppendNode(try self.expectIdentifier());

                const newNode = Node{
                    .kind = .{ .New = .{ .ident = identIndex } },
                    .token = newToken,
                };
                try self.set(newIndex, newNode);
                lhsIndex = newIndex;
            },
            else => {
                // TODO: make this error like the others
                return error.InvalidToken;
            },
        }
        const node = Node{
            .kind = NodeKind{ .Factor = .{ .factor = lhsIndex.? } },
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
    log.err("Parsed successfully\n", .{});
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

fn parseMe(source: []const u8) !Parser {
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    const parser = try Parser.parseTokens(tokens, source, debugAlloc);
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

test "program declarations indices null for no types" {
    const source = "fun TS() void { int a; int b; struct TS S; }";
    const tokens = try Lexer.tokenizeFromStr(source, debugAlloc);
    const parser = try Parser.parseTokens(tokens, source, debugAlloc);
    switch (parser.ast.items[0].kind) {
        .Program => |prog| {
            const decls = parser.ast.items[prog.declarations].kind.ProgramDeclarations;
            try ting.expectEqual(decls.types, null);
            try ting.expectEqual(decls.declarations, null);
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
    // log.err("ATOM: {any}\n", .{parser.tokens[atom.start..(atom.start + atom.len)]});
    const start: usize = 0;
    const len: usize = 7;
    try ting.expectEqual(start, atom.start);
    try ting.expectEqual(len, atom.len);
}

fn expectAtomSliceTokenKinds(parser: *Parser, atom: Parser.ExprAtom, tokens: []const TokenKind) !void {
    const atomSlice = parser.tokens[atom.start..(atom.start + atom.len)];
    for (tokens, 0..) |token, i| {
        ting.expect(atomSlice.len > i) catch {
            log.err("Atom Slice Missing Tokens: {any}\n", .{tokens[i..]});
            return error.OutofBounds;
        };
        ting.expectEqual(token, atomSlice[i].kind) catch {
            log.err("Token mismatch at {d}: \nExpected: {}\n Got: {}\n", .{ i, token, atomSlice[i].kind });
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
    log.info("TREE: {}\n", .{expr.*});
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
    errdefer log.print();
    var parser = try testMe("1 + foo(x, new y, x + 1)");
    const expr = try parser.prattParseExpression(debugAlloc, 0);
    const treeIndex = try parser.reconstructTree(expr);
    log.info("TREE: {}\n", .{treeIndex});
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
    try ting.expect(items[6].kind == .Invocation);
    // TODO: ... finish
}

/// The Enum of the NodeKind fields (no body required)
const NodeKindTag = @typeInfo(NodeKind).Union.tag_type.?;
// const NodeKindBody = @typeInfo(NodeKind).Union.body_type;

fn expectHasNodeWithKind(nodes: []const Node, kind: NodeKindTag) !Node {
    for (nodes) |node| {
        if (node.kind == kind) {
            return node;
        }
    }
    log.err("Expected Node with Kind: {any}\n", .{kind});
    log.err("But Nodes were: {any}\n", .{nodes});
    return error.NotFound;
}

test "fun.with_locals" {
    const source = "fun A() void { int d; d = 2 + 5; }";
    const parser = try parseMe(source);
    const nodes = parser.ast.items;
    const funNode = try expectHasNodeWithKind(nodes, .Function);
    try ting.expect(nodes[funNode.kind.Function.proto].kind == .FunctionProto);
    // TODO: add more checks for function subtree structure
}
