// NOTE: file is implicitly a struct (because zig amirite!)
// therefore use is as simple and elegant and beautitful as:
// `const Ast = @import("ast.zig");`

const std = @import("std");
const Token = @import("lexer.zig").Token;

nodes: NodeList,
allocator: std.mem.Allocator,

pub const NodeList = std.ArrayList(Node);

pub const Node = struct {
    kind: Kind,
    token: Token,

    // The parser is responsible for taking the tokens and creating an abstract syntax tree
    pub const Kind = union(enum) {
        Types: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Program: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Type: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        BoolType: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        IntType: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        StructType: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Void: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Read: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Decl: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        NestedDecl: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Identifier: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        TypeDeclaration: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Declarations: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Declaration: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Functions: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Function: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Parameters: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        ReturnType: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Statement: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Block: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Assignment: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Print: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        PrintLn: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        ConditionalIf: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        ConditionalIfElse: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        While: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Delete: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Return: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Invocation: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        StatementList: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        LValue: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Expression: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        BinaryOperation: struct {
            // lhs, rhs actually make sense!
            // token points to operator go look there
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        UnaryOperation: struct {
            // token says what unary it is
            // go look there
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Selector: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Factor: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Arguments: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Number: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        True: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        False: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        New: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Null: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        /// This is a special node that is used to reserve space for the AST
        /// specifically for Expression-s and below!
        /// NOTE: This should be skipped when analyzing the AST
        // TODO: make the tag for this zero so its prty
        BackfillReserve: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
    };
};
