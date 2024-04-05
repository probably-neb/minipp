const std = @import("std");

const Range = struct {
    start: u32,
    end: u32,

    pub fn new(start: u32, end: u32) Range {
        return Range{ .start = start, .end = end };
    }
};

pub const Token = union(enum) {
    Ident: Range,
    Int: Range,
    Float: Range,
    String: Range,
    Char: u32,
    Lt,
    LtEq,
    Gt,
    GtEq,
    Eq,
    DblEq,
    Plus,
    Minus,
    Mul,
    Div,
    LParen,
    RParen,
    LSquirly,
    RSquirly,
    LBrace,
    RBrace,
    True,
    False,
    Eof,
    If,
    Fun,
    Let,

    pub const keywords = std.ComptimeStringMap(Token, .{
        .{ "true", Token.True },
        .{ "false", Token.False },
        .{ "if", Token.If },
        .{ "fun", Token.Fun },
        .{ "let", Token.Let },
    });
};

pub const Lexer = struct {
    pos: u32,
    read_pos: u32,
    ch: u8,
    input: []const u8,

    pub fn new(input: []const u8) Lexer {
        var lxr = Lexer{ .pos = 0, .read_pos = 0, .ch = 0, .input = input };
        lxr.step();
        return lxr;
    }

    pub fn next_token(lxr: *Lexer) Token {
        lxr.skip_whitespace();

        const tok = switch (lxr.ch) {
            '"' => Token{ .String = lxr.read_string() },
            '\'' => Token{ .Char = lxr.read_char() },
            'a'...'z', 'A'...'Z', '_' => return lxr.ident_or_builtin(),
            '0'...'9' => return lxr.read_numeric(),
            else => blk: {
                if (std.ascii.isPrint(lxr.ch)) {
                    break :blk lxr.read_symbol();
                } else if (lxr.ch == 0) {
                    break :blk Token.Eof;
                }
                unreachable;
            },
        };

        lxr.step();
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
        while (std.ascii.isWhitespace(lxr.ch)) {
            lxr.step();
        }
    }

    fn ident_or_builtin(lxr: *Lexer) Token {
        const range = lxr.read_ident();
        const ident = lxr.slice(range);
        const tok = Token.keywords.get(ident) orelse Token{ .Ident = range };
        return tok;
    }

    fn read_ident(lxr: *Lexer) Range {
        const pos = lxr.pos;
        while (std.ascii.isAlphabetic(lxr.ch) or lxr.ch == '_') {
            lxr.step();
        }
        return Range{ .start = pos, .end = lxr.pos };
    }

    fn read_numeric(lxr: *Lexer) Token {
        const pos = lxr.pos;
        while (std.ascii.isDigit(lxr.ch)) {
            lxr.step();
        }
        if (lxr.ch == '.' or lxr.ch == 'e') {
            lxr.step();
            return Token{ .Float = lxr.read_float(pos) };
        }
        return Token{ .Int = Range{ .start = pos, .end = lxr.pos } };
    }

    fn read_float(lxr: *Lexer, start: u32) Range {
        while (std.ascii.isDigit(lxr.ch)) {
            lxr.step();
        }
        if (lxr.ch == 'e') {
            lxr.step();
            if (lxr.ch == '-' or lxr.ch == '+') {
                lxr.step();
            }
            while (std.ascii.isDigit(lxr.ch)) {
                lxr.step();
            }
        }
        return Range{ .start = start, .end = lxr.pos };
    }

    fn read_string(lxr: *Lexer) Range {
        const pos = lxr.pos + 1;
        while (lxr.peek() != '"' and lxr.ch != 0) {
            lxr.step();
        }
        lxr.step(); // Move past the closing quote
        return Range{ .start = pos, .end = lxr.pos };
    }

    fn read_char(lxr: *Lexer) u32 {
        const pos = lxr.pos + 1;
        lxr.step();
        lxr.expect('\'');
        return pos;
    }

    fn read_symbol(lxr: *Lexer) Token {
        // This function requires implementing if_peek logic, adapted to Zig.
        // Zig doesn't support Rust-like macros, so we use inline functions or conditionals.
        // For simplicity, let's just handle a couple of cases:
        return switch (lxr.ch) {
            '<' => if (lxr.peek() == '=') Token.LtEq else Token.Lt,
            '>' => if (lxr.peek() == '=') Token.GtEq else Token.Gt,
            '=' => if (lxr.peek() == '=') Token.DblEq else Token.Eq,
            '-' => Token.Minus,
            '(' => Token.LParen,
            ')' => Token.RParen,
            '{' => Token.LSquirly,
            '}' => Token.RSquirly,
            '[' => Token.LBrace,
            ']' => Token.RBrace,
            '+' => Token.Plus,
            '*' => Token.Mul,
            '/' => Token.Div,
            else => unreachable,
        };
    }

    fn slice(lxr: *Lexer, range: Range) []const u8 {
        const end = @min(range.end, lxr.input.len);
        return lxr.input[range.start..end];
    }
};

pub fn main() void {
    var input: []const u8 = "(if (= (+ 1 2) 3 ) (5 + 6) (3 - 8))";
    var lxr = Lexer.new(input);
    var tok = lxr.next_token();
    while (tok != Token.Eof) : (tok = lxr.next_token()) {
        std.debug.print("{}\n", .{tok});
    }
}
