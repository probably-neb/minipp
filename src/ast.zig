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
            declarations: usize,
            functions: ?usize = null,
        },
        /// ProgramDeclarations is a list of type declarations
        /// and global variable declarations
        ProgramDeclarations: struct {
            types: ?usize = null,
            declarations: ?usize = null,
        },

        /// The top level global type declarations list
        Types: struct {
            /// index of first type declaration
            /// Pointer to `TypeDeclaration`
            firstType: usize,
            /// When null, only one type declaration
            /// Pointer to `TypeDeclaration`
            lastType: ?usize = null,
        },
        Type: struct {
            /// The kind of the type is either a pointer to the `StructType`
            /// Node in the case of a struct or the primitive
            /// `bool` or `int` type
            kind: usize,
            /// when kind is `StructType` points to the idenfifier
            /// of the struct
            structIdentifier: ?usize = null,
        },

        BoolType,
        IntType,
        StructType,
        Void,
        Read,
        Identifier,

        TypeDeclaration: struct {
            /// The struct name
            /// pointer to `Identifier`
            ident: usize,
            /// The fields of the struct
            declarations: usize,
        },
        StructFieldDeclarations: struct {
            /// index of first declaration
            /// pointer to `TypedIdentifier`
            firstDecl: usize,
            /// When null, only one declaration
            /// pointer to `TypedIdentifier`
            lastDecl: ?usize = null,

            const Self = @This();

            fn is_empty(self: Self) bool {
                return self.firstDecl == null and self.lastDecl == null;
            }
        },

        ///////////////
        // FUNCTIONS //
        ///////////////
        Functions: struct {
            firstFunc: ?usize = null,
            lastFunc: ?usize = null,

            const Self = @This();

            fn is_empty(self: Self) bool {
                return self.firstFunc == null and self.lastFunc == null;
            }
        },
        Function: struct {
            /// Pointer to `FunctionProto`
            proto: usize,
            /// pointer to `FunctionBody`
            body: usize,
        },
        /// Declaration of a function, i.e. all info related to a function
        /// except the body
        FunctionProto: struct {
            /// Pointer to `TypedIdentifier` where `ident` is the function name
            /// and `type` is the return type of the function
            name: usize,
            /// Pointer to `Parameters` node
            /// null if no parameters
            parameters: ?usize = null,
        },
        Parameters: struct {
            /// Pointer to `TypedIdentifier`
            firstParam: usize,
            /// When null, only one parameter
            /// Pointer to `TypedIdentifier`
            lastParam: ?usize = null,
        },
        ReturnType: struct {
            /// Pointer to `Type` node
            /// null if `void` return type
            type: ?usize = null,

            const Self = @This();

            fn is_void(self: Self) bool {
                return self.type == null;
            }
        },
        FunctionBody: struct {
            /// Pointer to `LocalDeclarations`
            /// null if no local declarations
            declarations: ?usize,
            /// Pointer to `StatementList`
            /// null if function has empty body
            statements: ?usize,
        },
        /// Declarations within a function, or global declarations
        LocalDeclarations: struct {
            /// Pointer to `TypedIdentifier`
            firstDecl: usize,
            // When null, only one declaration
            // Pointer to `TypedIdentifier`
            lastDecl: ?usize = null,

            const Self = @This();

            fn is_empty(self: Self) bool {
                return self.firstDecl == null and self.lastDecl == null;
            }
        },

        // TODO: use TypedIdentifier more often, it is a helpful pairing of
        // name and type that will make typechecking simpler
        TypedIdentifier: struct {
            /// Pointer to `Type` node
            type: usize,
            /// Pointer to `Identifier` node
            ident: usize,
        },

        StatementList: struct {
            /// Pointer to `Statement`
            firstStatement: usize,
            /// Pointer to `Statement`
            /// null if only one statement
            lastStatement: ?usize = null,
        },
        /// Statement holds only one field, the index of the actual statement
        /// it is still usefull, however, as the possible statements are vast,
        /// and therefore iterating over them is much simpler if we can just
        /// find the next `Statement` node and follow the subtree
        Statement: struct {
            /// Pointer to Block | Assignment | Print | PrintLn | ConditionalIf | ConditionalIfElse | While | Delete | Return | Invocation
            statement: usize,
        },

        Block: struct {
            /// Pointer to `StatementList`
            /// null if no statements in the block
            statements: ?usize = null,
        },
        Assignment: struct {
            lhs: ?usize = null,
            rhs: ?usize = null,
        },
        Print: struct {
            /// The expression to print
            expr: usize,
            /// Whether the print statement has an endl
            hasEndl: bool,
        },
        ConditionalIf: struct {
            /// pointer to the condition expression
            cond: usize,
            /// Circumvents the 2 field limit of the union (for alignment reasons)
            /// by pointing to the true and false blocks, so the ConditionalIf can point
            /// to either a block if no else, or a ConditionalIfElse if there is an else
            /// Pointer to either `Block` if no `else` clause, or
            /// `ConditionalIfElse` if there is an `else`
            block: usize,
        },
        ConditionalIfElse: struct {
            ifBlock: usize,
            elseBlock: usize,
        },
        While: struct {
            /// The condition expression to check
            cond: usize,
            /// The block of code to execute
            block: usize,
        },
        Delete: struct {
            /// the expression to delete
            expr: usize,
        },
        Return: struct {
            /// The expression to return
            /// null if is `return;`
            expr: ?usize = null,
        },
        Invocation: struct {
            funcName: usize,
            /// null if no arguments
            args: ?usize = null,
        },
        LValue: struct {
            /// The first ident in the chain
            /// Pointer to `Identifier`
            ident: usize,
            /// Pointer to `SelectorChain` (`{'.'id}*`)
            /// null if no selectors
            chain: ?usize = null,
        },
        Expression: struct {
            /// like with `StatementList` there are occasions we must iterate
            /// over a list of expressions, so it is helpful to have a top level
            /// node indicating the start of a new subtree
            expr: usize,
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
            on: usize,
        },
        Selector: struct {
            /// Pointer to `Factor`
            factor: usize,
            /// Pointer to `SelectorChain`
            chain: ?usize = null,
        },
        /// A chain of `.ident` selectors
        SelectorChain: struct {
            ident: usize,
            /// Pointer to `SelectorChain`
            /// null if last in chain
            next: ?usize = null,
        },
        // FIXME: remove Factor node and just use `.factor`
        // We never iterate over a list of Factors like we do with Statements,
        // so it is not necessary to have the top level node indicating the
        // start of a new subtree as there is with statements
        Factor: struct {
            /// Pointer to `Number` | `True` | `False` | `New` | `Null` | `Identifier` | `Expression`
            factor: usize,
        },
        Arguments: struct {
            /// Pointer to `Expression`
            firstArg: usize,
            /// Pointer to `Expression`
            /// null if only one argument
            lastArg: ?usize = null,
        },
        /// A number literal, token points to value
        Number,
        /// keyword `true`
        True,
        /// keyword `false`
        False,
        New: struct {
            /// pointer to the identifier being allocated
            ident: usize,
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
