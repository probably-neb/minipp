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
        Function: struct {
            /// Pointer to `FunctionProto`
            proto: Ref(.FunctionProto),
            /// pointer to `FunctionBody`
            body: Ref(.FunctionBody),
        },
        /// Declaration of a function, i.e. all info related to a function
        /// except the body
        FunctionProto: struct {
            /// Pointer to `TypedIdentifier` where `ident` is the function name
            /// and `type` is the return type of the function
            name: Ref(.TypedIdentifier),
            /// Pointer to `Parameters` node
            /// null if no parameters
            parameters: ?Ref(.Parameters) = null,
        },
        Parameters: struct {
            /// Pointer to `TypedIdentifier`
            firstParam: Ref(.TypedIdentifier),
            /// When null, only one parameter
            /// Pointer to `TypedIdentifier`
            lastParam: ?Ref(.TypedIdentifier) = null,
        },
        ReturnType: struct {
            /// Pointer to `Type` node
            /// null if `void` return type
            type: ?Ref(.Type) = null,

            const Self = @This();

            fn is_void(self: Self) bool {
                return self.type == null;
            }
        },
        FunctionBody: struct {
            /// Pointer to `LocalDeclarations`
            /// null if no local declarations
            declarations: ?Ref(.LocalDeclarations),
            /// Pointer to `StatementList`
            /// null if function has empty body
            statements: ?Ref(.StatementList) = null,
        },
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

        TypedIdentifier: struct {
            /// Pointer to `Type` node
            type: Ref(.Type),
            /// Pointer to `Identifier` node
            ident: Ref(.Identifier),
        },

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

        Block: struct {
            /// Pointer to `StatementList`
            /// null if no statements in the block
            statements: ?Ref(.StatementList) = null,
        },
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
        ConditionalIf: struct {
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
        },
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
        Return: struct {
            /// The expression to return
            /// null if is `return;`
            expr: ?Ref(.Expression) = null,
        },
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
        Expression: struct {
            /// like with `StatementList` there are occasions we must iterate
            /// over a list of expressions, so it is helpful to have a top level
            /// node indicating the start of a new subtree
            expr: RefOneOf(.{
                .BinaryOperation,
                .UnaryOperation,
                .Factor,
            }),
        },
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
    };
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
    FunctionProto,
    Parameters,
    ReturnType,
    FunctionBody,
    LocalDeclarations,
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
