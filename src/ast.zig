// NOTE: file is implicitly a struct (because zig amirite!)
// therefore use is as simple and elegant and beautitful as:
// `const Ast = @import("ast.zig");`

const std = @import("std");
pub const Token = @import("lexer.zig").Token;
const log = @import("log.zig");
const utils = @import("utils.zig");

nodes: NodeList,
allocator: std.mem.Allocator,
input: []const u8,

structMap: std.StringHashMap(usize),
functionMap: std.StringHashMap(usize),

const Ast = @This();

// TODO: make struct already declared error more informative
pub fn mapStructs(ast: *Ast) !void {
    const nodes = ast.nodes.items;
    var i: usize = 0;
    for (nodes) |node| {
        if (node.kind == .TypeDeclaration) {
            const ident = ast.get(node.kind.TypeDeclaration.ident);
            const name = ident.token._range.getSubStrFromStr(ast.input);
            // check if the struct is already in the map
            if (ast.structMap.contains(name)) {
                return error.StructAlreadyDeclared;
            }
            try ast.structMap.put(name, i);
        }
        i += 1;
    }
}

pub fn debugPrintAst(self: *const Ast) void {
    var i: usize = 0;
    const nodes = self.nodes.items;
    std.debug.print("AST PRINT START\n", .{});
    for (nodes) |node| {
        const kind = node.kind;
        const token = node.token;
        std.debug.print("{d}: {s} {s}", .{ i, @tagName(kind), token._range.getSubStrFromStr(self.input) });
        switch (kind) {
            .BinaryOperation => {
                const binOp = node.kind.BinaryOperation;
                std.debug.print(" lhs: {any}\n", .{binOp.lhs});
                std.debug.print(" rhs: {any}\n", .{binOp.rhs});
            },
            .Expression => {
                const expr = node.kind.Expression;
                const last = expr.last;
                std.debug.print(" last: {d}", .{last});
            },
            else => {},
        }
        std.debug.print("\n", .{});
        i += 1;
    }
    std.debug.print("AST PRINT END\n", .{});
}
pub fn printAst(self: *const Ast) void {
    var i: usize = 0;
    const nodes = self.nodes.items;
    log.trace("AST PRINT START\n", .{});
    for (nodes) |node| {
        const kind = node.kind;
        const token = node.token;
        log.trace("{d}: {s} {s}\n", .{ i, @tagName(kind), token._range.getSubStrFromStr(self.input) });
        switch (kind) {
            .BinaryOperation => {
                const binOp = node.kind.BinaryOperation;
                log.trace(" lhs: {any}\n", .{binOp.lhs});
                log.trace(" rhs: {any}\n", .{binOp.rhs});
            },
            else => {},
        }
        i += 1;
    }
    log.trace("AST PRINT END\n", .{});
}

pub fn arrayStringsToString(self: *const Ast, arr: std.ArrayList(u8)) ![]u8 {
    var strbuff = std.ArrayList(u8).init(self.allocator);
    defer strbuff.deinit();
    for (arr.items) |str| {
        try strbuff.append(str);
    }
    return try strbuff.toOwnedSlice();
}

pub fn selectorChainToString(self: *const Ast, chainID: ?usize) ![]u8 {
    var cId = chainID;
    var strbuff = std.ArrayList(u8).init(self.allocator);
    defer strbuff.deinit();
    while (cId != null) {
        var chainNode = self.get(cId.?).*;
        var ident = chainNode.kind.SelectorChain.ident;
        var identNode = self.get(ident).*;
        switch (identNode.kind) {
            .Identifier => {
                // const identss = identNode.kind.Identifier;
                const identName = self.getIdentValue(ident);
                try strbuff.append('.');
                for (identName) |c| {
                    try strbuff.append(c);
                }
                cId = chainNode.kind.SelectorChain.next;
            },
            else => {
                return try self.arrayStringsToString(strbuff);
            },
        }
    }
    return try self.arrayStringsToString(strbuff);
}

pub fn lvalToString(self: *const Ast, lvalID: usize) ![]u8 {
    const lvalNode = self.get(lvalID).*;
    const lvalKind = lvalNode.kind;
    var strbuff = std.ArrayList(u8).init(self.allocator);
    defer strbuff.deinit();
    switch (lvalKind) {
        .LValue => {
            const lval = lvalKind.LValue;
            const identName = self.getIdentValue(lval.ident);
            for (identName) |c| {
                try strbuff.append(c);
            }
            if (lval.chain != null) {
                const chainStr = try self.selectorChainToString(lval.chain.?);
                for (chainStr) |c| {
                    try strbuff.append(c);
                }
            }
        },
        else => {
            unreachable;
        },
    }
    return try self.arrayStringsToString(strbuff);
}

pub fn selectorToString(self: *const Ast, selectorId: usize) ![]u8 {
    const selectorNode = self.get(selectorId).*;
    const selectorKind = selectorNode.kind;
    var strbuff = std.ArrayList(u8).init(self.allocator);
    defer strbuff.deinit();
    switch (selectorKind) {
        .Selector => {
            const selector = selectorKind.Selector;
            const factor = selector.factor;
            const factorNode = self.get(factor).*;
            const factorFactor = factorNode.kind.Factor.factor;
            const factorFactorNode = self.get(factorFactor).*;
            switch (factorFactorNode.kind) {
                .Identifier => {
                    const identName = self.getIdentValue(factorFactor);
                    for (identName) |c| {
                        try strbuff.append(c);
                    }
                },
                else => {
                    return try self.arrayStringsToString(strbuff);
                },
            }
            if (selector.chain != null) {
                const chainStr = try self.selectorChainToString(selector.chain.?);
                for (chainStr) |c| {
                    try strbuff.append(c);
                }
            }
        },
        else => {
            unreachable;
        },
    }
    return try self.arrayStringsToString(strbuff);
}

pub fn mapFunctions(ast: *Ast) !void {
    const nodes = ast.nodes.items;
    var i: usize = 0;
    for (nodes) |node| {
        if (node.kind == .Function) {
            const func = node.kind.Function;
            const proto = ast.get(func.proto);
            const name = ast.get(proto.kind.FunctionProto.name).token._range.getSubStrFromStr(ast.input);
            if (ast.functionMap.contains(name)) {
                return error.FunctionAlreadyDeclared;
            }
            try ast.functionMap.put(name, i);
        }
        i += 1;
    }
}

pub fn getFunctionFromName(ast: *const Ast, name: []const u8) ?*const Node {
    const index = ast.functionMap.get(name);
    if (index) |i| {
        return ast.get(i);
    }
    return null;
}

pub fn getFunctionReturnTypeFromName(ast: *const Ast, name: []const u8) ?Type {
    const funcNode = ast.getFunctionFromName(name);
    if (funcNode == null) {
        return null;
    }
    const func = funcNode.?.kind.Function;
    return func.getReturnType(ast);
}

pub fn getFunctionDeclarationTypeFromName(ast: *const Ast, name: []const u8, memberName: []const u8) ?Type {
    const funcNode = ast.getFunctionFromName(name);
    if (funcNode == null) {
        return null;
    }
    const functionBody = funcNode.?.kind.Function.getBody(ast);
    if (functionBody.declarations == null) {
        return null;
    }
    const declarations = ast.get(functionBody.declarations.?);
    return declarations.kind.LocalDeclarations.getMemberType(ast, memberName);
}

pub fn getStructNodeFromName(ast: *const Ast, name: []const u8) ?*const Node {
    const index = ast.structMap.get(name);
    if (index) |i| {
        return ast.get(i);
    }
    return null;
}

pub fn getStructFieldType(ast: *const Ast, structName: []const u8, fieldName: []const u8) ?Type {
    const structNode = ast.getStructNodeFromName(structName);
    if (structNode == null) {
        return null;
    }
    const decls = ast.get(structNode.?.kind.TypeDeclaration.declarations);
    return decls.kind.StructFieldDeclarations.getMemberType(ast, fieldName);
}

pub fn getDeclarationGlobalFromName(ast: *const Ast, name: []const u8) ?Type {
    const nodes = ast.nodes.items;
    for (nodes) |node| {
        if (node.kind == .ProgramDeclarations) {
            const decls = node.kind.ProgramDeclarations.declarations;
            if (decls != null) {
                const localDecls = ast.get(decls.?).kind.LocalDeclarations;
                return localDecls.getMemberType(ast, name);
            }
        }
    }
    return null;
}

pub fn init(alloc: std.mem.Allocator, nodes: NodeList, input: []const u8) !Ast {
    var AST = Ast{
        .nodes = nodes,
        .allocator = alloc,
        .input = input,
        .structMap = std.StringHashMap(usize).init(alloc),
        .functionMap = std.StringHashMap(usize).init(alloc),
    };
    try AST.mapStructs();
    try AST.mapFunctions();

    return AST;
}

pub fn initFromParser(parser: @import("parser.zig").Parser) !Ast {
    const nodes = parser.ast;
    const alloc = parser.allocator;
    const input = parser.input;
    return try Ast.init(alloc, nodes, input);
}

pub const NodeList = std.ArrayList(Node);

pub const Node = struct {
    kind: Kind,
    token: Token,

    // The parser is responsible for taking the tokens and creating an abstract syntax tree
    pub const Kind = union(enum) {
        Program: struct {
            /// Pointer to `ProgramDeclarations`
            /// The index itself is never null, however if there are no globals,
            /// or type declarations then both fields in the ProgramDeclarations
            /// node will be null
            declarations: Ref(.ProgramDeclarations),
            functions: Ref(.Functions),
        },
        /// ProgramDeclarations is a list of type declarations
        /// and global variable declarations
        ProgramDeclarations: struct {
            types: ?Ref(.Types) = null,
            declarations: ?Ref(.LocalDeclarations) = null,
        },

        /// The top level global type declarations list
        Types: struct {
            /// index of first type declaration
            /// Pointer to `TypeDeclaration`
            firstType: Ref(.TypeDeclaration),
            /// When null, only one type declaration
            /// Pointer to `TypeDeclaration`
            lastType: ?Ref(.TypeDeclaration) = null,
        },
        Type: struct {
            /// The kind of the type is either a pointer to the `StructType`
            /// Node in the case of a struct or the primitive
            /// `bool` or `int` type
            kind: RefOneOf(.{
                .BoolType,
                .IntType,
                .StructType,
                .IntArrayType,
            }),
            /// when kind is `StructType` points to the idenfifier
            /// of the struct
            structIdentifier: ?Ref(.Identifier) = null,
        },

        BoolType,
        IntType,
        StructType,
        IntArrayType,
        Void,
        Read,
        Identifier,

        /// Declaring a type, NOTE: always a struct
        TypeDeclaration: struct {
            /// The struct name
            /// pointer to `Identifier`
            ident: Ref(.Identifier),
            /// The fields of the struct
            declarations: Ref(.StructFieldDeclarations),
        },
        StructFieldDeclarations: struct {
            /// index of first declaration
            /// pointer to `TypedIdentifier`
            firstDecl: Ref(.TypedIdentifier),
            /// When null, only one declaration
            /// pointer to `TypedIdentifier`
            lastDecl: ?Ref(.TypedIdentifier) = null,

            const Self = @This();

            fn is_empty(self: Self) bool {
                return self.firstDecl == null and self.lastDecl == null;
            }

            //Ben you will hate this :D
            //You are correct my friend. I do in fact hate this
            fn getMemberType(self: Self, ast: *const Ast, memberName: []const u8) ?Type {
                const last = self.lastDecl orelse self.firstDecl + 1;
                var iterator: ?usize = self.firstDecl;
                while (iterator) |it| : (iterator = ast.findIndexWithin(.TypedIdentifier, it + 1, last + 1)) {
                    if (it > last) {
                        break;
                    }
                    const decl = ast.get(it).kind.TypedIdentifier;
                    const name = decl.getName(ast);
                    if (std.mem.eql(u8, name, memberName)) {
                        return decl.getType(ast);
                    }
                }
                return null;
            }

            //Dylan you will hate this :D
            pub fn iter(self: Self, ast: *const Ast) NodeIter(.TypedIdentifier) {
                return NodeIter(.TypedIdentifier).init(
                    ast,
                    self.firstDecl,
                    self.lastDecl,
                );
            }
        },

        ///////////////
        // FUNCTIONS //
        ///////////////
        Functions: struct {
            firstFunc: Ref(.Function),
            lastFunc: ?Ref(.Function) = null,

            const Self = @This();

            fn is_empty(self: Self) bool {
                return self.firstFunc == null and self.lastFunc == null;
            }
        },
        Function: FunctionType,
        /// A helper for traversing later, to constrain the search and include all
        /// nodes in the function, even if it only has one (with a nested subtree) statement
        FunctionEnd,
        ArgumentEnd,
        ArgumentsEnd,
        /// Declaration of a function, i.e. all info related to a function
        /// except the body
        FunctionProto: FunctionProtoType,
        Parameters: struct {
            /// Pointer to `TypedIdentifier`
            firstParam: ?Ref(.TypedIdentifier) = null,
            /// When null, only one parameter
            /// Pointer to `TypedIdentifier`
            lastParam: ?Ref(.TypedIdentifier) = null,

            pub fn iter(self: @This(), ast: *const Ast) NodeIter(.TypedIdentifier) {
                return NodeIter(.TypedIdentifier).init(
                    ast,
                    self.firstParam,
                    self.lastParam,
                );
            }
        },
        ReturnType: ReturnTypeType,
        FunctionBody: FunctionBodyType,
        /// Declarations within a function, or global declarations
        LocalDeclarations: struct {
            /// Pointer to `TypedIdentifier`
            firstDecl: Ref(.TypedIdentifier),
            // When null, only one declaration
            // Pointer to `TypedIdentifier`
            lastDecl: ?Ref(.TypedIdentifier) = null,

            const Self = @This();

            fn is_empty(self: Self) bool {
                return self.firstDecl == null and self.lastDecl == null;
            }

            fn getMemberType(self: Self, ast: *const Ast, memberName: []const u8) ?Type {
                const last = self.lastDecl orelse self.firstDecl + 1;
                var iterator: ?usize = self.firstDecl;
                while (iterator != null) {
                    if (iterator.? > last) {
                        break;
                    }
                    const decl = ast.get(iterator.?).kind.TypedIdentifier;
                    const name = decl.getName(ast);
                    if (std.mem.eql(u8, name, memberName)) {
                        return decl.getType(ast);
                    }
                    iterator = ast.findIndexWithin(.TypedIdentifier, iterator.? + 1, last + 1);
                }
                return null;
            }

            //Dylan you will hate this :D
            pub fn iter(self: Self, ast: *const Ast) NodeIter(.TypedIdentifier) {
                return NodeIter(.TypedIdentifier).init(
                    ast,
                    self.firstDecl,
                    self.lastDecl,
                );
            }
        },

        TypedIdentifier: TypedIdentifierType,
        /// An alias for TypedIdentifier. No actual differences, just what nodes
        /// we can expect they refer too. I.e. we don't have to check for `ReturnType`
        /// node when working on the type referenced by TypedIdentifier
        ReturnTypedIdentifier: ReturnTypedIdentifierType,

        StatementList: struct {
            /// Pointer to `Statement`
            firstStatement: Ref(.Statement),
            /// Pointer to `Statement`
            /// null if only one statement
            lastStatement: ?Ref(.Statement) = null,

            pub const EmptyStatementIter = StatementsIter.init(
                undefined,
                1,
                0,
            );
            pub const StatementsIter = struct {
                first: usize,
                last: usize,
                i: usize,
                ast: *const Ast,

                pub fn init(ast: *const Ast, firstStmt: usize, lastStmt: ?usize) StatementsIter {
                    const last: usize = lastStmt orelse firstStmt + 1;
                    const i: usize = firstStmt;

                    return .{
                        .first = i,
                        .last = last,
                        .i = i,
                        .ast = ast,
                    };
                }
                pub fn next(self: *StatementsIter) ?Ast.Node {
                    if (self.i > self.last) {
                        return null;
                    }
                    const stmt = self.ast.get(self.i).*;
                    // Move to the next argument, considering nested Arguments and ArgumentEnds
                    var cursor = self.i + 1;
                    while (cursor <= self.last) : (cursor += 1) {
                        const node = self.ast.get(cursor).*;
                        if (node.kind == .Statement) {
                            break;
                        }
                        if (node.kind == .StatementList) {
                            cursor = (node.kind.StatementList.lastStatement orelse node.kind.StatementList.firstStatement);
                        }
                    }

                    self.i = cursor;

                    return stmt;
                }

                pub fn calculateLen(self: StatementsIter) usize {
                    // create a copy of the iterator with the initial state
                    // (i == first) so we do not mutate the original iterator
                    var copy = StatementsIter{ .ast = self.ast, .i = self.first, .first = self.first, .last = self.last };
                    var length: usize = 0;
                    // the |_| is needed so zig realizes I want them to go until
                    // next is null, otherwise get `expected bool` compile error
                    while (copy.next()) |_| : (length += 1) {
                        // do nothing
                    }
                    return length;
                }
            };

            pub fn iter(self: @This(), ast: *const Ast) StatementsIter {
                return StatementsIter.init(
                    ast,
                    self.firstStatement,
                    self.lastStatement,
                );
            }
        },
        /// Statement holds only one field, the index of the actual statement
        /// it is still usefull, however, as the possible statements are vast,
        /// and therefore iterating over them is much simpler if we can just
        /// find the next `Statement` node and follow the subtree
        Statement: struct {
            /// Pointer to Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation
            statement: RefOneOf(.{
                .Block,
                .Assignment,
                .Print,
                .ConditionalIf,
                .While,
                .Delete,
                .Return,
                .Invocation,
            }),
            finalIndex: usize,

            pub fn isControlFlow(self: @This(), ast: *const Ast) bool {
                const node = ast.get(self.statement);
                switch (node.kind) {
                    .ConditionalIf, .While, .Return, .Block => return true,
                    else => return false,
                }
            }
        },

        Block: BlockType,
        Assignment: struct {
            lhs: Ref(.LValue),
            rhs: RefOneOf(.{ .Expression, .Read }),
        },
        Print: struct {
            /// The expression to print
            expr: Ref(.Expression),
            /// Whether the print statement has an endl
            hasEndl: bool,
        },
        ConditionalIf: ConditionalIfType,
        ConditionalIfElse: struct {
            ifBlock: Ref(.Block),
            elseBlock: Ref(.Block),
        },
        While: struct {
            /// The condition expression to check
            cond: Ref(.Expression),
            /// The block of code to execute
            block: Ref(.Block),
        },
        Delete: struct {
            /// the expression to delete
            expr: Ref(.Expression),
        },
        Return: ReturnExprType,
        Invocation: struct {
            funcName: Ref(.Identifier),
            /// null if no arguments
            args: ?Ref(.Arguments) = null,
        },
        LValue: struct {
            /// The first ident in the chain
            /// Pointer to `Identifier`
            ident: Ref(.Identifier),
            /// Pointer to `SelectorChain` (`{'.'id}*`)
            /// null if no selectors
            // TODO: for adding the int_array access this will need to be changed
            chain: ?Ref(.SelectorChain) = null,
        },
        Expression: ExpressionType,
        BinaryOperation: struct {
            // lhs, rhs actually make sense!
            // token points to operator go look there
            lhs: RefOneOf(.{
                .BinaryOperation,
                .UnaryOperation,
                .Selector,
                .Expression,
            }),
            rhs: RefOneOf(.{
                .BinaryOperation,
                .UnaryOperation,
                .Selector,
                .Expression,
            }),
        },
        UnaryOperation: struct {
            // token says what unary it is
            // go look there
            on: RefOneOf(.{
                .BinaryOperation,
                .UnaryOperation,
                .Selector,
                .Expression,
            }),
        },
        Selector: struct {
            /// Pointer to `Factor`
            factor: Ref(.Factor),
            /// Pointer to `SelectorChain`
            chain: ?Ref(.SelectorChain) = null,
        },
        /// A chain of `.ident` selectors
        SelectorChain: struct {
            /// TODO: change ident to something that can be used for array access
            /// and struct access
            ident: RefOneOf(.{
                .Identifier,
                // Expression is used for array access
                .Expression,
            }),
            /// Pointer to `SelectorChain`
            /// null if last in chain
            next: ?Ref(.SelectorChain) = null,
        },
        // FIXME: remove Factor node and just use `.factor`
        // We never iterate over a list of Factors like we do with Statements,
        // so it is not necessary to have the top level node indicating the
        // start of a new subtree as there is with statements
        Factor: struct {
            /// Pointer to `Number` | `True` | `False` | `New` | `Null` | `Identifier` | `Expression`
            factor: RefOneOf(.{
                .Number,
                .True,
                .False,
                .New,
                .Null,
                .Identifier,
                .Expression,
                .Invocation,
            }),
        },
        Arguments: struct {
            /// Pointer to `Expression`
            firstArg: Ref(.Expression),
            /// Pointer to `Expression`
            /// null if only one argument
            lastArg: ?Ref(.Expression) = null,

            pub const ArgsIter = struct {
                first: usize,
                last: usize,
                i: ?usize,
                ast: *const Ast,

                pub fn init(ast: *const Ast, firstArg: usize, lastArg: ?usize) ArgsIter {
                    const last: usize = lastArg orelse firstArg + 1;
                    const i: usize = firstArg;

                    return .{
                        .first = i,
                        .last = last,
                        .i = i,
                        .ast = ast,
                    };
                }
                pub fn next(self: *ArgsIter) ?Ast.Node {
                    var depth: usize = 0;
                    var arg: ?Ast.Node = null;

                    if (self.i) |i| {
                        arg = self.ast.get(i).*;
                        // Move to the next argument, considering nested Arguments and ArgumentEnds
                        var cursor = i + 1;
                        var flag = true;
                        while (flag and cursor <= self.last) : (cursor += 1) {
                            const node = self.ast.get(cursor).*;
                            switch (node.kind) {
                                .Arguments => depth += 1,
                                .ArgumentEnd => {
                                    if (depth == 0) {
                                        flag = false;
                                    }
                                },
                                .ArgumentsEnd => {
                                    if (depth > 0) {
                                        depth -= 1;
                                    } else {
                                        std.debug.panic("tried to iter over invalid arguments - modify this error message to see what went wrong. Note - ArgsIter should only be used after sema", .{});
                                    }
                                },
                                else => {},
                            }
                        }

                        self.i = if (flag == false) cursor else null;
                    }

                    return arg;
                }
                pub fn calculateLen(self: ArgsIter) usize {
                    // create a copy of the iterator with the initial state
                    // (i == first) so we do not mutate the original iterator
                    var copy = ArgsIter{ .ast = self.ast, .i = self.first, .first = self.first, .last = self.last };
                    var length: usize = 0;
                    // the |_| is needed so zig realizes I want them to go until
                    // next is null, otherwise get `expected bool` compile error
                    while (copy.next()) |_| : (length += 1) {
                        // do nothing
                    }
                    return length;
                }
            };
            pub fn iter(self: @This(), ast: *const Ast) ArgsIter {
                return ArgsIter.init(
                    ast,
                    self.firstArg,
                    self.lastArg,
                );
            }
        },
        /// A number literal, token points to value
        Number,
        /// keyword `true`
        True,
        /// keyword `false`
        False,
        New: struct {
            /// pointer to the identifier being allocated
            ident: Ref(.Identifier),
        },
        NewIntArray: struct {
            /// The space to allocate for the array
            length: Ref(.Number),
        },
        /// keyword `null`
        Null,
        /// This is a special node that is used to reserve space for the AST
        /// specifically for Expression-s and below!
        /// NOTE: This should be skipped when analyzing the AST
        // TODO: make the tag for this zero so its prty
        BackfillReserve,

        pub const FunctionType = struct {
            /// Pointer to `FunctionProto`
            proto: Ref(.FunctionProto),
            /// pointer to `FunctionBody`
            body: Ref(.FunctionBody),

            pub const Self = @This();

            pub fn getProto(self: *const Self, ast: *const Ast) FunctionProtoType {
                return ast.get(self.proto).kind.FunctionProto;
            }

            pub fn getName(self: *const Self, ast: *const Ast) []const u8 {
                const protoNode = ast.get(self.proto);
                const name = ast.getIdentValue(protoNode.kind.FunctionProto.name);
                return name;
            }

            /// Returns the return type for this function
            /// null if it is void
            pub fn getReturnType(self: *const Self, ast: *const Ast) ?Type {
                const proto = self.getProto(ast);
                return proto.getReturnType(ast);
            }

            pub fn getBody(self: *const Self, ast: *const Ast) FunctionBodyType {
                return ast.get(self.body).*.kind.FunctionBody;
            }
        };

        pub const FunctionProtoType = struct {
            /// Pointer to `ReturnTypedIdentifier` where `ident` is the function name
            /// and `type` is the return type of the function
            name: Ref(.ReturnTypedIdentifier),
            /// Pointer to `Parameters` node
            /// null if no parameters
            parameters: ?Ref(.Parameters) = null,

            const Self = @This();

            pub fn getReturnType(self: Self, ast: *const Ast) ?Type {
                const identNode: ReturnTypedIdentifierType = ast.get(self.name).kind.ReturnTypedIdentifier;
                return identNode.getType(ast);
            }

            pub fn getName(self: Self, ast: *const Ast) []const u8 {
                const retIdent: ReturnTypedIdentifierType = ast.get(self.name).kind.ReturnTypedIdentifier;
                return ast.getIdentValue(retIdent.ident);
            }
        };

        pub const ReturnTypeType = struct {
            /// Pointer to `Type` node
            /// null if `void` return type
            type: ?Ref(.Type) = null,

            const Self = @This();

            fn isVoid(self: Self) bool {
                return self.type == null;
            }
        };

        pub const ReturnExprType = struct {
            /// The expression to return
            /// null if is `return;`
            expr: ?Ref(.Expression) = null,
        };

        pub const FunctionBodyType = struct {
            /// Pointer to `LocalDeclarations`
            /// null if no local declarations
            declarations: ?Ref(.LocalDeclarations) = null,
            /// Pointer to `StatementList`
            /// null if function has empty body
            statements: ?Ref(.StatementList) = null,

            const Self = @This();

            pub const ReturnsIter = struct {
                ast: *const Ast,
                i: usize,
                last: usize,

                const IterSelf = @This();

                /// @breif: Get the next return statement in the function
                pub fn next(self: *IterSelf) ?ReturnExprType {
                    if (self.i > self.last) {
                        return null;
                    }
                    const nodeIndex = self.ast.findIndex(.Return, self.i);
                    if (nodeIndex) |i| {
                        const node = self.ast.nodes.items[i];
                        self.i = i + 1;
                        return node.kind.Return;
                    }
                    self.i = self.last + 1;
                    return null;
                }
            };

            pub fn iterReturns(self: Self, ast: *const Ast) ReturnsIter {
                if (self.statements == null) {
                    return ReturnsIter{ .ast = ast, .i = 0, .last = 1 };
                }
                const stmts = ast.get(self.statements.?).kind.StatementList;
                const first = stmts.firstStatement;
                const last = ast.findIndex(.FunctionEnd, first) orelse {
                    std.debug.panic("ast malformed: no FunctionEnd node found after first statement", .{});
                };
                utils.assert(last > first, "ast malformed: last={d} < first={d}", .{ last, first });
                // log.trace("first={d} last={d}\n", .{ first, last });

                return ReturnsIter{
                    .ast = ast,
                    .i = first,
                    .last = last,
                };
            }

            pub fn iterStatements(self: Self, ast: *const Ast) NodeIter(.Statement) {
                if (self.statements) |statementsIndex| {
                    const statements = ast.get(statementsIndex).kind.StatementList;
                    return NodeIter(.Statement).init(
                        ast,
                        statements.firstStatement,
                        statements.lastStatement,
                    );
                }
                return NodeIter(.Statement).initEmpty();
            }

            pub fn iterLocalDecls(self: Self, ast: *const Ast) NodeIter(.TypedIdentifier) {
                if (self.declarations) |declsIndex| {
                    const decls = ast.get(declsIndex).kind.LocalDeclarations;
                    return NodeIter(.TypedIdentifier).init(
                        ast,
                        decls.firstDecl,
                        decls.lastDecl,
                    );
                }
                return NodeIter(.TypedIdentifier).initEmpty();
            }

            test "ast.iterReturns.void" {
                errdefer log.print();
                const input = "fun main() void { return; }";
                const ast = try testMe(input);
                const func = (ast.find(.Function, 0) orelse unreachable).kind.Function;
                const body = ast.get(func.body).kind.FunctionBody;
                var iter = body.iterReturns(&ast);
                const ret = iter.next();
                try std.testing.expect(ret != null);
                try std.testing.expect(ret.?.expr == null);
                try std.testing.expect(iter.next() == null);
            }

            test "ast.iterReturns.findsAll.multiple_void" {
                const input = "fun main() int { if (true) {return;} else {return;} }";
                const ast = try testMe(input);
                const func = (ast.find(.Function, 0) orelse unreachable).kind.Function;
                const body = ast.get(func.body).kind.FunctionBody;
                var iter = body.iterReturns(&ast);

                try std.testing.expect(iter.next() != null);
                try std.testing.expect(iter.next() != null);
                try std.testing.expect(iter.next() == null);
                try std.testing.expect(iter.next() == null);
            }
            test "ast.iterReturns.multiple_void" {
                const input = "fun main() int { if (true) {return;} else {return;} }";
                const ast = try testMe(input);
                const func = (ast.find(.Function, 0) orelse unreachable).kind.Function;
                const body = ast.get(func.body).kind.FunctionBody;
                var iter = body.iterReturns(&ast);

                var ret = iter.next();
                try std.testing.expect(ret != null);

                ret = iter.next();
                try std.testing.expect(ret != null);

                try std.testing.expect(iter.next() == null);
            }

            pub fn getStatementList(self: Self) ?Ref(.StatementList) {
                return self.statements orelse null;
            }
        };

        pub const ReturnTypedIdentifierType = struct {
            /// Pointer to `Type` node
            type: Ref(.ReturnType),
            /// Pointer to `Identifier` node
            ident: Ref(.Identifier),

            const Self = @This();

            // FIXME: remove ? from return type, we don't return null!
            pub fn getType(self: Self, ast: *const Ast) ?Type {
                const retTypeNode = ast.get(self.type).kind.ReturnType;
                if (retTypeNode.type) |tyNodeIndex| {
                    const tyNode = ast.get(tyNodeIndex).kind.Type;
                    const kindNode = ast.get(tyNode.kind).kind;
                    switch (kindNode) {
                        .BoolType => return .Bool,
                        .IntType => return .Int,
                        .Void => return .Void,
                        .StructType => {
                            const nameToken = ast.get(tyNode.structIdentifier.?).token;
                            const name = nameToken._range.getSubStrFromStr(ast.input);
                            return .{ .Struct = name };
                        },
                        .IntArrayType => return .IntArray,
                        else => unreachable,
                    }
                } else {
                    std.debug.assert(retTypeNode.isVoid());
                    return .Void;
                }
            }
        };

        pub const TypedIdentifierType = struct {
            /// Pointer to `Type` node
            type: Ref(.Type),
            /// Pointer to `Identifier` node
            ident: Ref(.Identifier),

            const Self = @This();

            pub fn getType(self: Self, ast: *const Ast) Type {
                const tyNode = ast.get(self.type).kind.Type;
                const kindNode = ast.get(tyNode.kind).kind;
                switch (kindNode) {
                    .BoolType => return .Bool,
                    .IntType => return .Int,
                    .StructType => {
                        const name = ast.getIdentValue(tyNode.structIdentifier.?);
                        return .{ .Struct = name };
                    },
                    .IntArrayType => return .IntArray,
                    else => unreachable,
                }
            }
            pub fn getName(self: Self, ast: *const Ast) []const u8 {
                return ast.getIdentValue(self.ident);
            }
        };
        pub const ExpressionType = struct {
            /// like with `StatementList` there are occasions we must iterate
            /// over a list of expressions, so it is helpful to have a top level
            /// node indicating the start of a new subtree
            expr: RefOneOf(.{
                .BinaryOperation,
                .UnaryOperation,
                .Selector,
            }),
            last: usize,

            const Self = @This();
        };

        pub const ConditionalIfType = struct {
            /// pointer to the condition expression
            cond: Ref(.Expression),
            /// Circumvents the 2 field limit of the union (for alignment reasons)
            /// by pointing to the true and false blocks, so the ConditionalIf can point
            /// to either a block if no else, or a ConditionalIfElse if there is an else
            /// Pointer to either `Block` if no `else` clause, or
            /// `ConditionalIfElse` if there is an `else`
            block: RefOneOf(.{
                .ConditionalIfElse,
                .Block,
            }),

            pub const Self = @This();

            pub fn isIfElse(self: Self, ast: *const Ast) bool {
                const block = ast.get(self.block).kind;
                switch (block) {
                    .Block => return false,
                    .ConditionalIfElse => return true,
                    else => unreachable,
                }
            }
        };

        pub const BlockType = struct {
            /// Pointer to `StatementList`
            /// null if no statements in the block
            statements: ?Ref(.StatementList) = null,

            pub const Self = @This();

            /// returns [start, end)
            pub fn range(self: Self, ast: *const Ast) ?[2]usize {
                if (self.statements) |statements| {
                    const statementsNode = ast.get(statements).kind.StatementList;
                    const start = statementsNode.firstStatement;
                    const lastStatement = (statementsNode.lastStatement orelse start);
                    const lastIndex = ast.get(lastStatement).kind.Statement.finalIndex;
                    return [2]usize{ start, lastIndex };
                }
                return null;
            }

            pub fn iterStatements(self: Self, ast: *const Ast) NodeIter(.Statement) {
                if (self.statements) |statementsIndex| {
                    const statements = ast.get(statementsIndex).kind.StatementList;
                    return NodeIter(.Statement).init(
                        ast,
                        statements.firstStatement,
                        statements.lastStatement,
                    );
                }
                return NodeIter(.Statement).initEmpty();
            }
        };
    };

    pub fn isStatement(self: Node) bool {
        return switch (self.kind) {
            .Statement => true,
            else => false,
        };
    }
};

pub const Type = union(enum) {
    Bool,
    Int,
    IntArray,
    Null,
    Void,
    Struct: []const u8,

    const Self = @This();

    pub fn isStruct(self: Self) bool {
        return @intFromEnum(self) == @intFromEnum(Type.Struct);
    }

    pub fn equalsNoCont(self: Self, other: Self) bool {
        return @intFromEnum(self) == @intFromEnum(other);
    }
    pub fn equals(self: Self, other: Self) bool {
        return switch (self) {
            .Struct => switch (other) {
                // names equal
                .Struct => std.mem.eql(u8, self.Struct, other.Struct),
                .Null => true,
                else => false,
            },
            // I'm not sure if the null == null is necessary but it can't
            // hurt right?
            //
            // right?
            .Null => switch (other) {
                .Struct, .Null => true,
                else => false,
            },
            else => @intFromEnum(self) == @intFromEnum(other),
        };
        // Dylan I see what you were going for here I just don't like it ;)
        // also it didn't work and was hard to extend to support null so I made
        // it better ;) - Ben
        // ... why did copilot just sign my name for me?
        // const tmp = @intFromEnum(self) ^ @intFromEnum(other);
        // // if struct
        // if (std.mem.eql(u8, @tagName(self), @tagName(other)) and std.mem.eql(u8, @tagName(self), "Struct")) {
        //     // memcmp
        //     return std.mem.eql(u8, self.Struct, other.Struct);
        // }
        // return tmp == 0;
    }

    pub fn isOneOf(self: Self, comptime others: anytype) bool {
        inline for (others) |other| {
            if (self.equals(other)) {
                return true;
            }
        }
        return false;
    }
};

pub fn generateTypeInt() Type {
    return .Int;
}

// Required for the `Ref` to work because if we use
// @typeInfo to extract the Union, zig complains (reasonably)
// about the type being self referential
// to update run the following vim commands after copying the body of the node
// struct into the enum and selecting the inside of the enum
// '<,'>g/: struct/norm f:dt{da{
// '<,'>g://:d
// '<,'>g:^\s*$:d
pub const KindTagDupe = enum {
    Program,
    ProgramDeclarations,
    Types,
    Type,
    BoolType,
    IntType,
    StructType,
    IntArrayType,
    Void,
    Read,
    Identifier,
    TypeDeclaration,
    StructFieldDeclarations,
    Functions,
    Function,
    FunctionEnd,
    ArgumentEnd,
    ArgumentsEnd,
    FunctionProto,
    Parameters,
    ReturnType,
    FunctionBody,
    LocalDeclarations,
    TypedIdentifier,
    ReturnTypedIdentifier,
    StatementList,
    Statement,
    Block,
    Assignment,
    Print,
    ConditionalIf,
    ConditionalIfElse,
    While,
    Delete,
    Return,
    Invocation,
    LValue,
    Expression,
    BinaryOperation,
    UnaryOperation,
    Selector,
    SelectorChain,
    Factor,
    Arguments,
    Number,
    True,
    False,
    New,
    NewIntArray,
    Null,
    BackfillReserve,
};

/// An alias for usize, used to make what the referenes in
/// `Node.Kind` are referring to more explicit
/// WARN: not checked!
fn Ref(comptime tag: KindTagDupe) type {
    _ = tag;
    return usize;
}

fn RefOneOf(comptime tags: anytype) type {
    _ = tags;
    return usize;
}

/////////////
// HELPERS //
/////////////

const NodeKindTag = @typeInfo(Node.Kind).Union.tag_type.?;

pub fn NodeKindType(comptime tag: NodeKindTag) type {
    return @typeInfo(Node.Kind).Union.fields[@intFromEnum(tag)].type;
}

fn cmpNodeKindAndTag(node: Node, nkTag: NodeKindTag) bool {
    return @intFromEnum(node.kind) == @intFromEnum(nkTag);
}

pub fn numNodes(ast: *const Ast, nodeKind: NodeKindTag, startingAt: usize) usize {
    var count: usize = 0;
    for (ast.nodes.items[startingAt..]) |node| {
        if (cmpNodeKindAndTag(node, nodeKind)) {
            count += 1;
        }
    }
    return count;
}

test "ast.numNodes" {
    const input = "fun main() int { if (true) {return 1;} else {return 2;} }";
    const ast = try testMe(input);
    const func = (ast.find(.Function, 0) orelse unreachable).kind.Function;
    const body = ast.get(func.body).kind.FunctionBody;
    const numReturns = ast.numNodes(.Return, body.statements.?);
    try std.testing.expect(numReturns == 2);
}

pub fn find(ast: *const Ast, nodeKind: NodeKindTag, startingAt: usize) ?Node {
    if (startingAt >= ast.nodes.items.len) {
        return null;
    }
    for (ast.nodes.items[startingAt..]) |node| {
        // log.trace("node {s} - {d} =? kind {s} - {d}\n", .{ @tagName(node.kind), @intFromEnum(node.kind), @tagName(nodeKind), @intFromEnum(nodeKind) });
        if (cmpNodeKindAndTag(node, nodeKind)) {
            return node;
        }
    }
    return null;
}

pub fn findIndex(ast: *const Ast, nodeKind: NodeKindTag, startingAt: usize) ?usize {
    if (startingAt >= ast.nodes.items.len) {
        return null;
    }
    for (ast.nodes.items[startingAt..], startingAt..) |node, i| {
        if (cmpNodeKindAndTag(node, nodeKind)) {
            return i;
        }
    }
    return null;
}

pub fn findIndexWithin(ast: *const Ast, nodeKind: NodeKindTag, start: usize, end: usize) ?usize {
    if (start >= ast.nodes.items.len) {
        return null;
    }
    for (ast.nodes.items[start..@min(end, ast.nodes.items.len)], start..) |node, i| {
        if (cmpNodeKindAndTag(node, nodeKind)) {
            return i;
        }
    }
    return null;
}

pub fn get(ast: *const Ast, i: usize) *const Node {
    return &ast.nodes.items[i];
}

pub fn getIdentValue(ast: *const Ast, identIndex: usize) []const u8 {
    const idNode = ast.get(identIndex);
    // utils.assert(cmpNodeKindAndTag(idNode.*, .Identifier) or cmpNodeKindAndTag(idNode.*, .ReturnTypedIdentifier), "expected Identifier, got {s}", .{@tagName(idNode.kind)});
    const token = idNode.token;
    const name = token._range.getSubStrFromStr(ast.input);
    return name;
}

pub const FuncIter = struct {
    ast: *const Ast,
    i: usize,
    last: usize,

    const Self = @This();

    fn new(ast: *const Ast) Self {
        const prog = ast.find(.Program, 0);
        const funcs = ast.get(prog.?.kind.Program.functions).kind.Functions;
        const firstFuncIndex = funcs.firstFunc;
        const lastFuncIndex = funcs.lastFunc orelse firstFuncIndex;
        return Self{ .ast = ast, .i = firstFuncIndex, .last = lastFuncIndex };
    }

    pub fn next(self: *Self) ?Node.Kind.FunctionType {
        if (self.i > self.last) {
            return null;
        }
        // PERF: use a hashmap to store the indexes of the functions
        const nodeIndex = self.ast.findIndex(.Function, self.i);
        if (nodeIndex) |i| {
            self.i = i + 1;
            const n = self.ast.nodes.items[i];
            return n.kind.Function;
        }
        self.i = self.last + 1;
        return null;
    }
};

/// A generic iterator over nodes of a specific kind
/// designed to be wrapped in `*Type` struct helper function
/// that finds first, last
pub fn NodeIter(comptime tag: NodeKindTag) type {
    return struct {
        ast: *const Ast,
        i: usize,
        first: usize,
        last: usize,

        const Self = @This();

        pub fn init(ast: *const Ast, first: ?usize, last: ?usize) Self {
            if (first == null) {
                return Self.initEmpty();
            }
            const firstIndex = first.?;
            const lastIndex = last orelse firstIndex;
            return Self{ .ast = ast, .first = firstIndex, .i = firstIndex, .last = lastIndex };
        }

        /// You know, for when the shit is null
        pub fn initEmpty() Self {
            return Self.init(undefined, 1, 0);
        }

        pub fn next(self: *Self) ?Node {
            if (self.i > self.last) {
                return null;
            }
            // PERF: use a hashmap to store the indexes of the functions
            const nodeIndex = self.ast.findIndexWithin(tag, self.i, self.last + 1);
            if (nodeIndex) |i| {
                self.i = i + 1;
                const n = self.ast.nodes.items[i];
                return n;
            }
            self.i = self.last + 1;
            return null;
        }
        pub fn nextInc(self: *Self) ?Node {
            if (self.i > self.last) {
                return null;
            }
            // PERF: use a hashmap to store the indexes of the functions
            const nodeIndex = self.ast.findIndexWithin(tag, self.i, self.last + 1);
            if (nodeIndex) |i| {
                self.i = i + 1;
                const n = self.ast.nodes.items[i];
                return n;
            }
            self.i = self.last + 1;
            return null;
        }

        // WARN: somewhat expensive. Iterates over all entries
        pub fn calculateLen(self: Self) usize {
            // create a copy of the iterator with the initial state
            // (i == first) so we do not mutate the original iterator
            var copy = Self{ .ast = self.ast, .i = self.first, .first = self.first, .last = self.last };
            var length: usize = 0;
            // the |_| is needed so zig realizes I want them to go until
            // next is null, otherwise get `expected bool` compile error
            while (copy.next()) |_| : (length += 1) {
                // do nothing
            }
            return length;
        }

        /// Helper mainly for the statement iterations, where there are nested statements
        /// and we have to iterate. Instead of overcomplicating the logic in this struct,
        /// leaves handling skips to the callee. E.x.:
        /// `switch (kind) {.Block => |block| {iter.skipTo(block.lastIndex); ...handle}, ...}`
        pub fn skipTo(self: *Self, i: usize) void {
            self.i = i;
        }
    };
}

pub fn iterFuncs(ast: *const Ast) FuncIter {
    return FuncIter.new(ast);
}

pub fn printNodeLine(ast: *const Ast, node: Node) void {
    printNodeLineTo(ast, node, std.debug.print);
}

pub fn printNodeLineTo(ast: *const Ast, node: Node, comptime printer: fn (comptime fmt: []const u8, args: anytype) void) void {
    const input = ast.input;
    const tok = node.token;
    const tok_start = tok._range.start;
    const tok_end = tok._range.end;
    var line_start: usize = tok_start;
    while (line_start > 0 and input[line_start] != '\n') : (line_start -= 1) {}
    line_start += 1;
    var line_end: usize = tok_end;
    while (line_end < input.len and input[line_end] != '\n') : (line_end += 1) {}
    const line = input[line_start..line_end];
    var line_no: usize = 0;
    var i: usize = 0;
    while (i < line_start) : (i += 1) {
        if (input[i] == '\n') {
            line_no += 1;
        }
    }
    const col_no = tok_start - line_start;
    @call(.auto, printer, .{ "LINE {d}:{d} \"{s}\"\n", .{ line_no, col_no, line } });
}

const ting = std.testing;
const debugAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !Ast {
    const tokens = try @import("lexer.zig").Lexer.tokenizeFromStr(input, debugAlloc);
    const parser = try @import("parser.zig").Parser.parseTokens(tokens, input, debugAlloc);
    const ast = Ast.initFromParser(parser);
    return ast;
}

test "ast.structMap" {
    errdefer log.print();
    const input = "struct Foo { int a; int b; }; fun main() void{}";
    var ast = try testMe(input);
    try ting.expect(ast.structMap.contains("Foo"));
}

test "ast.structMap_duplicate" {
    errdefer log.print();
    const input = "struct Foo { int a; int b; }; struct Foo{int a; int b;}; fun main() void{}";
    try ting.expectError(error.StructAlreadyDeclared, testMe(input));
}

test "ast.getStructNodeFromName" {
    errdefer log.print();
    const input = "struct Foo { int a; int b; }; fun main() void{}";
    var ast = try testMe(input);
    const node = ast.getStructNodeFromName("Foo");
    try ting.expect(node != null);
    const ident = ast.get(node.?.kind.TypeDeclaration.ident);
    const name = ident.token._range.getSubStrFromStr(ast.input);
    try ting.expectEqualStrings(name, "Foo");
}

test "ast.getStructMemberType" {
    errdefer log.print();
    const input = "struct Foo { int a; int b; }; fun main() void{}";
    var ast = try testMe(input);
    const ty = ast.getStructFieldType("Foo", "a");
    try ting.expect(ty != null);
    const kind = ty.?;
    try ting.expect(kind == Type.Int);
}

test "ast.mapFunctions" {
    errdefer log.print();
    const input = "fun main() void{}";
    var ast = try testMe(input);
    try ting.expect(ast.functionMap.contains("main"));
}

test "ast.mapFunctions_duplicate" {
    errdefer log.print();
    const input = "fun main() void{} fun main() void{}";
    try ting.expectError(error.FunctionAlreadyDeclared, testMe(input));
}

test "ast.getFunctionFromName" {
    errdefer log.print();
    const input = "fun main() void{}";
    var ast = try testMe(input);
    var node = ast.getFunctionFromName("main");
    try ting.expect(node != null);
    const func = node.?.kind.Function;
    const proto = ast.get(func.proto);
    const name = ast.get(proto.kind.FunctionProto.name).token._range.getSubStrFromStr(ast.input);
    try ting.expectEqualStrings(name, "main");
}

test "ast.getFunctionReturnTypeFromName" {
    errdefer log.print();
    const input = "fun main() int{}";
    var ast = try testMe(input);
    const ty = ast.getFunctionReturnTypeFromName("main");
    try ting.expect(ty != null);
    try ting.expect(ty.? == Type.Int);
}

test "ast.getFunctionDeclarationTypeFromName" {
    errdefer log.print();
    const input = "fun main() int{int a;}";
    var ast = try testMe(input);
    var ty = ast.getFunctionDeclarationTypeFromName("main", "a");
    try ting.expect(ty != null);
    var kind = ty.?;
    try ting.expect(kind == Type.Int);
}

test "ast.getFunctionDeclarationTypeFromName_notFound" {
    errdefer log.print();
    const input = "fun main() int{int a;}";
    var ast = try testMe(input);
    var ty = ast.getFunctionDeclarationTypeFromName("main", "b");
    try ting.expect(ty == null);
}

test "ast.getFunctionReturnTypeFromName_void" {
    errdefer log.print();
    const input = "fun main() void{}";
    var ast = try testMe(input);
    const ty = ast.getFunctionReturnTypeFromName("main");
    try ting.expect(ty != null);
    try ting.expect(ty.? == Type.Void);
}

test "ast.getFunctionReturnTypeFromName_notFound" {
    errdefer log.print();
    const input = "fun main() void{}";
    var ast = try testMe(input);
    const ty = ast.getFunctionReturnTypeFromName("main2");
    try ting.expect(ty == null);
}

test "ast.getDeclaratoinGlobalTypeFromName" {
    errdefer log.print();
    const input = "int a; fun main() void{}";
    var ast = try testMe(input);
    const ty = ast.getDeclarationGlobalFromName("a");
    try ting.expect(ty != null);
    try ting.expect(ty.? == Type.Int);
}

test "ast.getDeclaratoinGlobalTypeFromName_notFound" {
    errdefer log.print();
    const input = "int a; fun main() void{}";
    var ast = try testMe(input);
    const ty = ast.getDeclarationGlobalFromName("b");
    try ting.expect(ty == null);
}

test "ast.getGloablStructTypeFromName" {
    errdefer log.print();
    const input = "struct Foo { int a; int b; }; struct Foo f; fun main() void{}";
    var ast = try testMe(input);
    const ty = ast.getDeclarationGlobalFromName("f");
    const expected = Type{ .Struct = "Foo" };
    try ting.expect(ty.?.equals(expected));
}

test "ast.getGloablStructTypeFromName_notFound" {
    errdefer log.print();
    const input = "struct Foo { int a; int b; }; struct Foo f; fun main() void{}";
    var ast = try testMe(input);
    const ty = ast.getDeclarationGlobalFromName("b");
    try ting.expect(ty == null);
}

test "ast.int_array_main" {
    errdefer log.print();
    const input = "fun main() void { int_array a; a = new int_array[10]; }";
    var ast = try testMe(input);
    _ = ast.getFunctionDeclarationTypeFromName("main", "a");
}

test "ast.int_array_access" {
    errdefer log.print();
    const input = "fun main() void { int_array a; a = new int_array[10]; a[0] = 1; }";
    var ast = try testMe(input);
    _ = ast;
}

// test "parser.printlvalue" {
//     const source = "struct S{struct S s;}; fun main() void {struct S s; int_array a; s.s.s.s.s.s.s.s.s.s.s.s = 22+500 + a[0] + s.s.s.s.s; a = new int_array[10]; a[0] = 1;}";
//     var ast = try testMe(source);
//     var count: u32 = 0;
//     ast.debugPrintAst();
//     for (ast.nodes.items) |node| {
//         switch (node.kind) {
//             .LValue => {
//                 const str = try ast.lvalToString(count);
//                 std.debug.print("{s}\n", .{str});
//             },
//             .Selector => {
//                 const str = try ast.selectorToString(count);
//                 std.debug.print("{s}\n", .{str});
//             },
//             else => {},
//         }
//         count += 1;
//     }
// }
