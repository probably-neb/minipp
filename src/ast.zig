// NOTE: file is implicitly a struct (because zig amirite!)
// therefore use is as simple and elegant and beautitful as:
// `const Ast = @import("ast.zig");`

const std = @import("std");
const Token = @import("lexer.zig").Token;
const log = @import("log.zig");
const utils = @import("utils.zig");

nodes: NodeList,
allocator: std.mem.Allocator,
input: []const u8,

const Ast = @This();

pub fn init(alloc: std.mem.Allocator, nodes: NodeList, input: []const u8) Ast {
    return Ast{
        .nodes = nodes,
        .allocator = alloc,
        .input = input,
    };
}

pub fn initFromParser(parser: @import("parser.zig").Parser) Ast {
    const nodes = parser.ast;
    const alloc = parser.allocator;
    const input = parser.input;
    return Ast.init(alloc, nodes, input);
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
            }),
            /// when kind is `StructType` points to the idenfifier
            /// of the struct
            structIdentifier: ?Ref(.Identifier) = null,
        },

        BoolType,
        IntType,
        StructType,
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
        /// Declaration of a function, i.e. all info related to a function
        /// except the body
        FunctionProto: FunctionProtoType,
        Parameters: struct {
            /// Pointer to `TypedIdentifier`
            firstParam: Ref(.TypedIdentifier),
            /// When null, only one parameter
            /// Pointer to `TypedIdentifier`
            lastParam: ?Ref(.TypedIdentifier) = null,
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
        },

        Block: BlockType,
        Assignment: struct {
            lhs: ?Ref(.LValue) = null,
            rhs: ?Ref(.Expression) = null,
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
            chain: ?Ref(.SelectorChain) = null,
        },
        Expression: ExpressionType,
        BinaryOperation: struct {
            // lhs, rhs actually make sense!
            // token points to operator go look there
            lhs: ?Ref(.Expression) = null,
            rhs: ?Ref(.Expression) = null,
        },
        UnaryOperation: struct {
            // token says what unary it is
            // go look there
            on: Ref(.Expression),
        },
        Selector: struct {
            /// Pointer to `Factor`
            factor: Ref(.Factor),
            /// Pointer to `SelectorChain`
            chain: ?Ref(.SelectorChain) = null,
        },
        /// A chain of `.ident` selectors
        SelectorChain: struct {
            ident: Ref(.Identifier),
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

            fn getProto(self: *const Self, ast: *const Ast) FunctionProtoType {
                return ast.get(self.proto).kind.FunctionProto;
            }

            pub fn getName(self: *const Self, ast: *const Ast) []const u8 {
                const protoNode = ast.get(self.proto);
                const nameNode = ast.get(protoNode.kind.FunctionProto.name);
                const name = nameNode.token._range.getSubStrFromStr(ast.input);
                return name;
            }

            /// Returns the return type for this function
            /// null if it is void
            pub fn getReturnType(self: *const Self, ast: *const Ast) ?Type {
                const proto = self.getProto(ast);
                return proto.getReturnType(ast);
            }

            pub fn getBody(self: *const Self, ast: *const Ast) FunctionBodyType {
                return ast.get(self.body).kind.FunctionBody;
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
                // std.debug.print("first={d} last={d}\n", .{ first, last });

                return ReturnsIter{
                    .ast = ast,
                    .i = first,
                    .last = last,
                };
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

                // const expr1 = ast.get(ret.?.expr.?).kind.Expression;
                // const expr1Selector = ast.get(expr1.expr).kind.Selector;
                // const expr1Factor = ast.get(expr1Selector.factor).kind.Factor;
                // const expr1Number = ast.get(expr1Factor.factor).token._range.getSubStrFromStr(ast.input);
                // try std.testing.expectEqualStrings(expr1Number, "1");

                ret = iter.next();
                try std.testing.expect(ret != null);

                // const expr2 = ast.get(ret.?.expr.?).kind.Expression;
                // const expr2Selector = ast.get(expr2.expr).kind.Selector;
                // const expr2Factor = ast.get(expr2Selector.factor).kind.Factor;
                // const expr2Number = ast.get(expr2Factor.factor).token._range.getSubStrFromStr(ast.input);
                // try std.testing.expectEqualStrings(expr2Number, "1");

                try std.testing.expect(iter.next() == null);
            }
            // test "ast.iterReturns.ret_expr" {
            //     const input = "fun main() int { if (true) {return 1;} else {return 2;} }";
            //     const ast = try testMe(input);
            //     const func = (ast.find(.Function, 0) orelse unreachable).kind.Function;
            //     const body = ast.get(func.body).kind.FunctionBody;
            //     var iter = body.iterReturns(&ast);

            //     var ret = iter.next();
            //     try std.testing.expect(ret != null);

            //     const expr1 = ast.get(ret.?.expr.?).kind.Expression;
            //     const expr1Selector = ast.get(expr1.expr).kind.Selector;
            //     const expr1Factor = ast.get(expr1Selector.factor).kind.Factor;
            //     const expr1Number = ast.get(expr1Factor.factor).token._range.getSubStrFromStr(ast.input);
            //     try std.testing.expectEqualStrings(expr1Number, "1");

            //     ret = iter.next();
            //     try std.testing.expect(ret != null);

            //     const expr2 = ast.get(ret.?.expr.?).kind.Expression;
            //     const expr2Selector = ast.get(expr2.expr).kind.Selector;
            //     const expr2Factor = ast.get(expr2Selector.factor).kind.Factor;
            //     const expr2Number = ast.get(expr2Factor.factor).token._range.getSubStrFromStr(ast.input);
            //     try std.testing.expectEqualStrings(expr2Number, "1");

            //     try std.testing.expect(iter.next() == null);
            // }

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
                        const nameToken = ast.get(tyNode.structIdentifier.?).token;
                        const name = nameToken._range.getSubStrFromStr(ast.input);
                        return .{ .Struct = name };
                    },
                }
            }
        };
        pub const ExpressionType = struct {
            /// like with `StatementList` there are occasions we must iterate
            /// over a list of expressions, so it is helpful to have a top level
            /// node indicating the start of a new subtree
            expr: RefOneOf(.{
                .BinaryOperation,
                .UnaryOperation,
                .Factor,
            }),

            const Self = @This();

            pub fn getType(self: Self, ast: *const Ast) Type {
                // FIXME: BORQED
                const factor = ast.get(self.expr).kind.Factor;
                const factorKind = ast.get(factor.factor).kind;
                switch (factorKind) {
                    .Number => return .Int,
                    .True => return .Bool,
                    .False => return .Bool,
                    .New => return .{ .Struct = "TODO" },
                    .Null => return .Null,
                    .Identifier => {
                        utils.todo("implement name resolution", .{});
                    },
                }
            }
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
                    const end = (statementsNode.lastStatement orelse start) + 1;
                    return [2]usize{ start, end };
                }
                return null;
            }
        };
    };
};

pub const Type = union(enum) {
    Bool,
    Int,
    Null,
    Void,
    Struct: []const u8,

    const Self = @This();

    pub fn equals(self: Self, other: Self) bool {
        if (self == other) {}
    }
};

// Required for the `Ref` to work because if we use
// @typeInfo to extract the Union, zig complains (reasonably)
// about the type being self referential
// to update run the following vim commands after copying the body of the node
// struct into the enum and selecting the inside of the enum
// '<,'>g/: struct/norm f:dt{da{
// '<,'>g://:d
// '<,'>g:^\s*$:d
const KindTagDupe = enum {
    Program,
    ProgramDeclarations,
    Types,
    Type,
    BoolType,
    IntType,
    StructType,
    Void,
    Read,
    Identifier,
    TypeDeclaration,
    StructFieldDeclarations,
    Functions,
    Function,
    FunctionEnd,
    FunctionProto,
    Parameters,
    ReturnType,
    FunctionBody,
    LocalDeclarations,
    ReturnTypedIdentifier,
    TypedIdentifier,
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
        // std.debug.print("node {s} - {d} =? kind {s} - {d}\n", .{ @tagName(node.kind), @intFromEnum(node.kind), @tagName(nodeKind), @intFromEnum(nodeKind) });
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
    for (ast.nodes.items[start..end], start..) |node, i| {
        if (cmpNodeKindAndTag(node, nodeKind)) {
            return i;
        }
    }
    return null;
}

pub fn get(ast: *const Ast, i: usize) *const Node {
    return &ast.nodes.items[i];
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

pub fn iterFuncs(ast: *const Ast) FuncIter {
    return FuncIter.new(ast);
}

const ting = std.testing;
const debugAlloc = std.heap.page_allocator;

fn testMe(input: []const u8) !Ast {
    const tokens = try @import("lexer.zig").Lexer.tokenizeFromStr(input, debugAlloc);
    const parser = try @import("parser.zig").Parser.parseTokens(tokens, input, debugAlloc);
    const ast = Ast.initFromParser(parser);
    return ast;
}
