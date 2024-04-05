const std = @import("std");
const lexer = @import("lexer.zig");
const Token = lexer.Token;
const TokenKind = lexer.TokenKind;

pub const NodeKind = union(enum) {
    Type,
    ReturnType,
};

pub const Node = struct {
    kind: NodeKind,
    token: Token,
    lhs: Node,
    rhs: Node,

};

pub const Parser = struct {
    tokens: []Token,
    ast: *Node,
    idMap: std.StringHashMap,

    fn newTypeNode(token: Token) Node {
        return Node{ .kind = NodeKind.Type, .token = token, .lhs = null, .rhs = null };
    }
};
`
