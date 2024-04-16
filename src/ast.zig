// NOTE: file is implicitly a struct (because zig amirite!)
// therefore use is as simple and elegant and beautitful as:
// `const Ast = @import("ast.zig");`

const std = @import("std");
const Token = @import("lexer.zig").Token;

nodes: NodeList,
allocator: std.mem.Allocator,

pub const NodeList = std.ArrayList(Node);
// The parser is responsible for taking the tokens and creating an abstract syntax tree
pub const NodeKind = enum {
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
    And,
    Or,
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
    /// This is a special node that is used to reserve space for the AST,
    /// specifically for Expression-s and below!
    /// NOTE: This should be skipped when analyzing the AST
    BackfillReserve,
};

pub const Node = struct {
    kind: NodeKind,
    token: Token,
    lhs: ?usize = null,
    rhs: ?usize = null,
};
