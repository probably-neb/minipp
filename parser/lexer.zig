const std = @import("std");

const Range = struct {
    start: u32,
    end: u32,

    pub fn new(start: u32, end: u32) Range {
        return Range{ .start = start, .end = end };
    }
};

pub const TokenKind = union(enum) {
    // For error handling and reporting
    Ident: Range,
    Number: Range,
    Lt,
    LtEq,
    Gt,
    GtEq,
    Eq,
    DoubleEq,
    Plus,
    Minus,
    Mul,
    Div,
    LParen,
    RParen,
    LSquirly,
    RSquirly,
    Eof,
    KeywordBool,
    KeywordDelete,
    KeywordEndl,
    KeywordFalse,
    KeywordFun,
    KeywordIf,
    KeywordInt,
    KeywordNew,
    KeywordNull,
    KeywordRead,
    KeywordReturn,
    KeywordStruct,
    KeywordTrue,
    KeywordVoid,
    KeywordWhile,

    pub const keywords = std.ComptimeStringMap(TokenKind, .{
        .{ "bool", TokenKind.KeywordBool },
        .{ "delete", TokenKind.KeywordDelete },
        .{ "endl", TokenKind.KeywordEndl },
        .{ "false", TokenKind.KeywordFalse },
        .{ "fun", TokenKind.KeywordFun },
        .{ "if", TokenKind.KeywordIf },
        .{ "int", TokenKind.KeywordInt },
        .{ "new", TokenKind.KeywordNew },
        .{ "null", TokenKind.KeywordNull },
        .{ "read", TokenKind.KeywordRead },
        .{ "return", TokenKind.KeywordReturn },
        .{ "struct", TokenKind.KeywordStruct },
        .{ "true", TokenKind.KeywordTrue },
        .{ "void", TokenKind.KeywordVoid },
        .{ "while", TokenKind.KeywordWhile },
    });
};

pub const Token = struct {
    kind: TokenKind,
    line_number: u32,
    line: Range,
    column: u32,
    file: []const u8,
};

pub const Lexer = struct {
    // For error handling and reporting
    line_number: u32,
    column: u32,
    file: []const u8,
    line: Range,

    // The current position in the input
    pos: u32,
    // The position that we are currently reading
    read_pos: u32,
    // The current character we are reading
    ch: u8,
    // The input string
    input: []const u8,

    pub fn new(input: []const u8) Lexer {
        var lxr = Lexer{
            .line_number = 0,
            .column = 0,
            // TODO handle this file name properly
            .file = "stdin",
            .line = Range{ .start = 0, .end = 0 },
            .pos = 0,
            .read_pos = 0,
            .ch = 0,
            .input = input,
        };
        lxr.step();
        return lxr;
    }

    pub fn next_token(lxr: *Lexer) Token {
        lxr.skip_whitespace();

        const kind = switch (lxr.ch) {
            'a'...'z', 'A'...'Z' => lxr.ident_or_builtin(),
            '0'...'9' => lxr.read_number(),
            else => blk: {
                if (std.ascii.isPrint(lxr.ch)) {
                    break :blk lxr.read_symbol();
                } else if (lxr.ch == 0) {
                    break :blk TokenKind.Eof;
                }
                // TODO add proper handling for errors
                unreachable;
            },
        };

        lxr.step();
        const tok = Token{ .kind = kind, .line = lxr.line, .line_number = lxr.line_number, .column = lxr.column, .file = lxr.file };
        return tok;
    }

    fn step(lxr: *Lexer) void {
        if (lxr.read_pos >= lxr.input.len) {
            lxr.ch = 0;
        } else {
            lxr.ch = lxr.input[lxr.read_pos];
        }

        lxr.pos = lxr.read_pos;
        lxr.read_pos += 1;
    }

    // This function has no use currently, but could be used in the future to
    // help with error handling.
    fn expect(lxr: *Lexer, byte: u8) void {
        lxr.step();
        if (lxr.ch != byte) {
            std.debug.panic("unexpected char {} in input, expected {}", .{ lxr.ch, byte });
        }
    }

    fn peek(lxr: *Lexer) u8 {
        if (lxr.read_pos >= lxr.input.len) {
            return 0;
        } else {
            return lxr.input[lxr.read_pos];
        }
    }

    fn skip_whitespace(lxr: *Lexer) void {
        while (true) {
            switch (lxr.ch) {
                '\n' => {
                    lxr.line_number += 1;
                    lxr.column = 0;
                    lxr.line.start = if (lxr.line.end == 0) 0 else lxr.line.end + 1;
                    lxr.line.end = lxr.pos;
                },
                ' ', '\t', '\r' => {
                    lxr.column += 1;
                },
                else => break,
            }
            lxr.step();
        }
    }

    fn read_ident(lxr: *Lexer) Range {
        const pos = lxr.pos;
        while (std.ascii.isAlphabetic(lxr.ch)) {
            lxr.step();
        }
        return Range{ .start = pos, .end = lxr.pos };
    }

    fn ident_or_builtin(lxr: *Lexer) TokenKind {
        const range = lxr.read_ident();
        const ident = lxr.slice(range);
        const tok = TokenKind.keywords.get(ident) orelse TokenKind{ .Ident = range };
        return tok;
    }

    fn read_number(lxr: *Lexer) TokenKind {
        const pos = lxr.pos;
        while (std.ascii.isDigit(lxr.ch)) {
            lxr.step();
        }
        return TokenKind{ .Number = Range{ .start = pos, .end = lxr.pos } };
    }

    fn read_symbol(lxr: *Lexer) TokenKind {
        // This function requires implementing if_peek logic, adapted to Zig.
        // Zig doesn't support Rust-like macros, so we use inline functions or conditionals.
        // For simplicity, let's just handle a couple of cases:
        return switch (lxr.ch) {
            '<' => if (lxr.peek() == '=') TokenKind.LtEq else TokenKind.Lt,
            '>' => if (lxr.peek() == '=') TokenKind.GtEq else TokenKind.Gt,
            '=' => if (lxr.peek() == '=') TokenKind.DoubleEq else TokenKind.Eq,
            '-' => TokenKind.Minus,
            '(' => TokenKind.LParen,
            ')' => TokenKind.RParen,
            '{' => TokenKind.LSquirly,
            '}' => TokenKind.RSquirly,
            '+' => TokenKind.Plus,
            '*' => TokenKind.Mul,
            '/' => TokenKind.Div,
            // TODO add proper handling for errors
            else => unreachable,
        };
    }

    fn slice(lxr: *Lexer, range: Range) []const u8 {
        const end = @min(range.end, lxr.input.len);
        return lxr.input[range.start..end];
    }
};

pub fn main() void {
    var input: []const u8 = "( (+ 1 2) 3 ) (5 + 6) (3 - 8))";
    var lxr = Lexer.new(input);
    var tok = lxr.next_token();
    while (tok.kind != TokenKind.Eof) : (tok = lxr.next_token()) {
        std.debug.print("{}\n", .{tok.kind});
    }
}
