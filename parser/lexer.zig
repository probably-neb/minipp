const std = @import("std");

const Range = struct {
    start: u32,
    end: u32,

    pub fn new(start: u32, end: u32) Range {
        return Range{ .start = start, .end = end };
    }

    pub fn getSubStrFromStr(self: Range, str: []const u8) []const u8 {
        return str[self.start..self.end];
    }
};

// TODO: include range in Token struct and have getter function for it
// so we don't have to track/compute it for trivially known values (like keywords or `==`)
pub const TokenKind = union(enum) {
    // For error handling and reporting
    Identifier: Range,
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
    LCurly,
    RCurly,
    Semicolon,
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

    // NOTE: bool, int, void shouldn't be valid keywords, (valid /type/ names)
    // and I feel that anything returned from the keywords map should be a keyword
    // we should move checking for "int"/"bool"/"void" to the type checking/name resolution steps (type name resolution)
    // when it exists
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

    pub fn equals(self: TokenKind, other: TokenKind) bool {
        const self_tag = @intFromEnum(self);
        const other_tag = @intFromEnum(other);

        return self_tag == other_tag;
    }
};

// TODO: remove unecessary fields
// line (Range), column, line_no are only needed for errors and debug sybmols
// and encode the same information. Could realistcally be replaced with a single `start_index`
// and we can just reparse later. UX for that api / speed tradeoff TBD
pub const Token = struct {
    kind: TokenKind,
    line_number: u32,
    line: Range,
    column: u32,
    file: []const u8,
};

// FIXME: handle comments
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

    pub fn new(input: []const u8, filePath: []const u8) Lexer {
        var lxr = Lexer{
            .line_number = 0,
            .column = 0,
            .file = filePath,
            .line = Range{ .start = 0, .end = 0 },
            .pos = 0,
            .read_pos = 0,
            .ch = 0,
            .input = input,
        };
        lxr.step();
        return lxr;
    }

    pub fn newFromStr(input: []const u8) Lexer {
        return Lexer.new(input, "");
    }

    pub fn tokenize(input: []const u8, filePath: []const u8) ![]Token {
        var lexer = Lexer.new(input, filePath);
        var tokens = std.ArrayList(Token).init(std.heap.page_allocator);
        defer tokens.deinit();

        while (true) {
            const tok = try lexer.next_token();
            if (tok.kind == TokenKind.Eof) {
                break;
            }
            try tokens.append(tok);
        }

        return tokens.toOwnedSlice();
    }

    pub fn tokenizeFromStr(input: []const u8) ![]Token {
        return Lexer.tokenize(input, "");
    }

    pub fn next_token(lxr: *Lexer) !Token {
        lxr.skip_whitespace();

        const kind = switch (lxr.ch) {
            'a'...'z', 'A'...'Z' => lxr.ident_or_builtin(),
            '0'...'9' => lxr.read_number(),
            else => blk: {
                if (std.ascii.isPrint(lxr.ch)) {
                    std.debug.print("reading symbol: {c}\n", .{lxr.ch});
                    break :blk try lxr.read_symbol();
                } else if (lxr.ch == 0) {
                    break :blk TokenKind.Eof;
                }
                // TODO: improve error handling
                if (lxr.file.len == 0) {
                    std.debug.print("error: unexpected character {any} in line=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.line_number, lxr.column });
                } else {
                    std.debug.print("error: unexpected character {any} in line=\"{s}\" in file=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.file, lxr.line_number, lxr.column });
                }
                lxr.line.end = if (lxr.line.end == 0) @truncate(lxr.input.len) else lxr.line.end;
                return error.InvalidToken;
            },
        };

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

    fn step_if_next_is(lxr: *Lexer, ch: u8) bool {
        if (lxr.peek() == ch) {
            lxr.step();
            return true;
        }
        return false;
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
        const tok = TokenKind.keywords.get(ident) orelse TokenKind{ .Identifier = range };
        return tok;
    }

    fn read_number(lxr: *Lexer) TokenKind {
        const pos = lxr.pos;
        while (std.ascii.isDigit(lxr.ch)) {
            lxr.step();
        }
        return TokenKind{ .Number = Range{ .start = pos, .end = lxr.pos } };
    }

    fn read_symbol(lxr: *Lexer) !TokenKind {
        const tok: TokenKind = switch (lxr.ch) {
            '<' => if (lxr.step_if_next_is('=')) TokenKind.LtEq else TokenKind.Lt,
            '>' => if (lxr.step_if_next_is('=')) TokenKind.GtEq else TokenKind.Gt,
            '=' => if (lxr.step_if_next_is('=')) TokenKind.DoubleEq else TokenKind.Eq,
            '-' => TokenKind.Minus,
            '(' => TokenKind.LParen,
            ')' => TokenKind.RParen,
            '{' => TokenKind.LCurly,
            '}' => TokenKind.RCurly,
            '+' => TokenKind.Plus,
            '*' => TokenKind.Mul,
            '/' => TokenKind.Div,
            ';' => TokenKind.Semicolon,
            // TODO: improve error handling
            else => {
                if (lxr.file.len == 0) {
                    std.debug.print("error: unexpected character \'{c}\' in line=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.line_number, lxr.column });
                } else {
                    std.debug.print("error: unexpected character \'{c}\' in line=\"{s}\" in file=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.file, lxr.line_number, lxr.column });
                }
                lxr.line.end = if (lxr.line.end == 0) @truncate(lxr.input.len) else lxr.line.end;
                return error.InvalidToken;
            },
        };
        lxr.step();
        return tok;
    }

    fn slice(lxr: *Lexer, range: Range) []const u8 {
        const end = @min(range.end, lxr.input.len);
        return lxr.input[range.start..end];
    }
};

///////////
// TESTS //
///////////

fn create_soa_tok_list(gpa: std.mem.Allocator, tokens: []Token) !std.MultiArrayList(Token) {
    var new_tokens: std.MultiArrayList(Token) = .{};
    try new_tokens.ensureTotalCapacity(gpa, tokens.len);
    for (tokens) |token| {
        new_tokens.appendAssumeCapacity(token);
    }

    return new_tokens;
}

fn expect_token_kinds_equals(expected: []TokenKind, actual: []Token) !void {
    for (expected, 0..) |expected_kind, i| {
        const actual_tok = actual.get(i) orelse return error.NotEnoughTokens;
        const actual_kind = actual_tok.kind;
        if (!expected_kind.equals(actual_kind.kind)) {
            std.debug.print("error: expected token kind {any} but got {any}\n", .{ expected_kind, actual_kind.kind });
            return error.TokensDoNotMatch;
        }
    }
}

fn print_tokens(tokens: []Token) void {
    for (tokens) |token| {
        std.debug.print("{}\n", .{token.kind});
    }
}

const expect = std.testing.expect;

test "add" {
    const contents = "1+2";
    const tokens = try Lexer.tokenizeFromStr(contents);
    expect(tokens.len == 3) catch |err| {
        std.debug.print("error: expected 3 tokens but got {d}\n", .{tokens.len});
        std.debug.print("got tokens:\n", .{});
        print_tokens(tokens);
        return err;
    };
}

test "simple-struct" {
    const content = "struct SimpleStruct { int x; int y; }";
    const tokens = try Lexer.tokenizeFromStr(content);
    expect(tokens.len == 10) catch |err| {
        std.debug.print("error: expected 10 tokens but got {d}\n", .{tokens.len});
        std.debug.print("got tokens:\n", .{});
        print_tokens(tokens);
        return err;
    };
}

pub fn main() !void {
    var input: []const u8 = "( (+ 1 2) 3 )@(5 + 6) (3 - 8))";
    var lxr = Lexer.newFromStr(input);
    var tok = try lxr.next_token();
    while (tok.kind != TokenKind.Eof) : (tok = try lxr.next_token()) {
        std.debug.print("{}\n", .{tok.kind});
    }
}
