const std = @import("std");
const log = @import("log.zig");

/// Print function that only prints in test mode. Useful for printing info
/// for debugging purposes that you don't want to show up when not running tests
fn test_print(comptime fmt: []const u8, args: anytype) void {
    const builtin = @import("builtin");
    if (builtin.is_test) {
        log.err(fmt, args);
    }
}

pub const Range = struct {
    start: u32,
    end: u32,

    pub fn new(start: u32, end: u32) Range {
        return Range{ .start = start, .end = end };
    }

    pub fn getSubStrFromStr(self: Range, str: []const u8) []const u8 {
        return str[self.start..self.end];
    }

    pub fn getLineCont(self: Range, input: []const u8) []const u8 {
        var start = self.start;
        if (start == input.len) {
            start -= 1;
        }
        while (start > 0 and start < input.len and input[start] != '\n') {
            start -= 1;
        }
        var end = self.end;
        while (end < input.len and input[end] != '\n' and end >= 0) {
            end += 1;
        }
        return input[start..end];
    }

    pub fn printLineContUnderline(self: Range, input: []const u8) void {
        var start = self.start;
        if (start == input.len) {
            start -= 1;
        }
        while (start > 0 and start < input.len and input[start] != '\n') {
            start -= 1;
        }
        var end = self.end;
        while (end < input.len and end >= 0 and input[end] != '\n') {
            end += 1;
        }

        // print spaces from start to self.start
        // // print ^ from self.start to self.end
        // // print spaces from self.end to end
        while (start < self.start) {
            log.err(" ", .{});
            start += 1;
        }
        if (self.start == self.end) {
            log.err("^", .{});
            start += 1;
        }
        while (start < self.end) {
            log.err("^", .{});
            start += 1;
        }
        while (start < end) {
            log.err(" ", .{});
            start += 1;
        }
        log.err("\n", .{});
    }
};

// TODO: include range in Token struct and have getter function for it
// so we don't have to track/compute it for trivially known values (like keywords or `==`)
pub const TokenKind = enum {
    // For error handling and reporting
    Identifier,
    Number,
    Lt,
    LtEq,
    Gt,
    GtEq,
    Eq,
    Dot,
    DoubleEq,
    NotEq,
    Not,
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
    Or,
    And,
    Comma,
    KeywordBool,
    KeywordDelete,
    KeywordElse,
    KeywordEndl,
    KeywordFalse,
    KeywordFun,
    KeywordIf,
    KeywordInt,
    KeywordNew,
    KeywordNull,
    KeywordPrint,
    KeywordRead,
    KeywordReturn,
    KeywordStruct,
    KeywordTrue,
    KeywordVoid,
    KeywordWhile,
    Unset,

    // NOTE: bool, int, void shouldn't be valid keywords, (valid /type/ names)
    // and I feel that anything returned from the keywords map should be a keyword
    // we should move checking for "int"/"bool"/"void" to the type checking/name resolution steps (type name resolution)
    // when it exists
    pub const keywords = std.ComptimeStringMap(TokenKind, .{
        .{ "bool", TokenKind.KeywordBool },
        .{ "delete", TokenKind.KeywordDelete },
        .{ "else", TokenKind.KeywordElse },
        .{ "endl", TokenKind.KeywordEndl },
        .{ "false", TokenKind.KeywordFalse },
        .{ "fun", TokenKind.KeywordFun },
        .{ "if", TokenKind.KeywordIf },
        .{ "int", TokenKind.KeywordInt },
        .{ "new", TokenKind.KeywordNew },
        .{ "null", TokenKind.KeywordNull },
        .{ "print", TokenKind.KeywordPrint },
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
    // TODO: create getter method for range that compute it for trivial cases
    // and returns precomputed value if present.
    // NOTE - must assert that the range is valid in non-trivial cases (Number/Identifier)
    // ALSO NOTE - It's not that much work to compute it for everythnig
    // and takes up the same amount of memory
    _range: Range,
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

    /// Internal struct for holding info required to construct a full token
    /// Used as a DTO (data transfer object)
    /// A good example is the `ident_or_builtin` function which returns
    /// the keyword token type and a null range if it was a keyword
    /// (because range of keyword is trivially known based on start + len)
    /// or the `Identifier` token type and the range if it was an ident
    const TokInfo = struct {
        kind: TokenKind,
        range: Range,
    };

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

    /// Tokenizes the input string and returns a list of tokens.
    /// It returns an owned slice of tokens.
    /// @param input:[]const u8 - The input string to tokenize
    /// @param filePath:[]const u8 - The file path of the input string
    /// @param allocator:std.mem.Allocator - The allocator to use for allocating memory
    /// @return []Token - The list of tokens
    /// NOTE: if you are using a string use the functinon tokenizeFromStr instead
    pub fn tokenize(input: []const u8, filePath: []const u8, allocator: std.mem.Allocator) ![]Token {
        var lexer = Lexer.new(input, filePath);
        var tokens = std.ArrayList(Token).init(allocator);
        defer tokens.deinit();

        // NOTE: EOF is the always token, it makes part of parsing simpler, so I will revise tests to match
        while (true) {
            const tok = try lexer.next_token();
            try tokens.append(tok);
            if (tok.kind == TokenKind.Eof) {
                break;
            }
        }

        return tokens.toOwnedSlice();
    }

    /// Tokenizes the input string and returns a list of tokens.
    /// This is an alias for lexer.tokenize, using a file path of "".
    /// @param input:[]const u8 - The input string to tokenize
    /// @param allocator:std.mem.Allocator - The allocator to use for allocating memory
    /// @return []Token - The list of tokens
    pub fn tokenizeFromStr(input: []const u8, allocator: std.mem.Allocator) ![]Token {
        return Lexer.tokenize(input, "", allocator);
    }

    pub fn next_token(lxr: *Lexer) !Token {
        lxr.skip_whitespace();

        const info: TokInfo = switch (lxr.ch) {
            'a'...'z', 'A'...'Z' => lxr.ident_or_builtin(),
            '0'...'9' => .{ .kind = TokenKind.Number, .range = try lxr.read_number() },
            else => blk: {
                const pos = lxr.pos;
                if (std.ascii.isPrint(lxr.ch)) {
                    break :blk .{ .kind = try lxr.read_symbol(), .range = Range{ .start = pos, .end = pos } };
                }
                if (lxr.ch == 0) {
                    // TODO: return null and make return type ?Token
                    // so that we can use `while (lxr.next_token()) |tok|`
                    // pattern
                    break :blk .{ .kind = TokenKind.Eof, .range = Range{ .start = pos, .end = pos } };
                }
                // TODO: improve error handling
                if (lxr.file.len == 0) {
                    log.err("unexpected character {any} in line=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.line_number, lxr.column });
                } else {
                    log.err("error: unexpected character {any} in line=\"{s}\" in file=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.file, lxr.line_number, lxr.column });
                }
                lxr.line.end = if (lxr.line.end == 0) @truncate(lxr.input.len) else lxr.line.end;
                return error.InvalidToken;
            },
        };

        const tok = Token{ .kind = info.kind, ._range = info.range };
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
                '#' => {
                    while (lxr.ch != '\n' and lxr.ch != 0) {
                        lxr.step();
                    }
                },
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
        // NOTE: no need to check first char is not numeric here
        // because if first char was numeric we would have called
        // read_number instead
        while (std.ascii.isAlphanumeric(lxr.ch)) {
            lxr.step();
        }
        return Range{ .start = pos, .end = lxr.pos };
    }

    fn ident_or_builtin(lxr: *Lexer) TokInfo {
        const range = lxr.read_ident();
        const ident = lxr.slice(range);
        const kw = TokenKind.keywords.get(ident);
        if (kw) |kw_kind| {
            return .{ .kind = kw_kind, .range = range };
        }
        return .{ .kind = .Identifier, .range = range };
    }

    fn read_number(lxr: *Lexer) !Range {
        const pos = lxr.pos;
        while (std.ascii.isDigit(lxr.ch)) {
            lxr.step();
        }
        return Range{ .start = pos, .end = lxr.pos };
    }

    fn read_symbol(lxr: *Lexer) !TokenKind {
        const tok: TokenKind = switch (lxr.ch) {
            '<' => if (lxr.step_if_next_is('=')) .LtEq else .Lt,
            '>' => if (lxr.step_if_next_is('=')) .GtEq else .Gt,
            '=' => if (lxr.step_if_next_is('=')) .DoubleEq else .Eq,
            '!' => if (lxr.step_if_next_is('=')) .NotEq else .Not,
            '&' => if (lxr.step_if_next_is('&')) .And else return error.InvalidToken,
            '|' => if (lxr.step_if_next_is('|')) .Or else return error.InvalidToken,
            '.' => .Dot,
            '-' => .Minus,
            '(' => .LParen,
            ')' => .RParen,
            '{' => .LCurly,
            '}' => .RCurly,
            '+' => .Plus,
            '*' => .Mul,
            '/' => .Div,
            ';' => .Semicolon,
            ',' => .Comma,
            // TODO: improve error handling
            else => {
                if (lxr.file.len == 0) {
                    log.err("error: unexpected character \'{c}\' in line=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.line_number, lxr.column });
                } else {
                    log.err("error: unexpected character \'{c}\' in line=\"{s}\" in file=\"{s}\"@{any}:{any}\n", .{ lxr.ch, lxr.line.getSubStrFromStr(lxr.input), lxr.file, lxr.line_number, lxr.column });
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

const testAlloc = std.testing.allocator;

fn expect_token_kinds_equals(expected: []const TokenKind, actual: []Token) !void {
    if (expected.len != actual.len) {
        log.err("error: expected {d} tokens but got {d}\n", .{ expected.len, actual.len });
        log.err("expected tokens:\n{any}\n", .{expected});
        log.err("got tokens:\n{any}\n", .{actual});
        return error.TokensDoNotMatch;
    }
    for (expected, 0..) |expected_kind, i| {
        if (i >= actual.len) {
            log.err("error: expected token kind {any} but got EOF\n", .{expected_kind});
            return error.NotEnoughTokens;
        }
        const actual_tok = actual[i];
        const actual_kind = actual_tok.kind;
        if (!expected_kind.equals(actual_kind)) {
            log.err("error: expected token kind {any} but got {any}\n", .{ expected_kind, actual_kind });
            return error.TokensDoNotMatch;
        }
    }
}

/// Check if the tokens produced by the lexer match the expected tokens.
/// This function is useful for testing the lexer.
///
/// @param contents:[]const u8        - The string to lex
/// @param expected:[]const TokenKind - The expected tokens
/// @return tokens:[]Token            - The tokens produced by the lexer
fn expect_results_in_tokens(contents: []const u8, expected: []const TokenKind) ![]Token {
    const tokens = try Lexer.tokenizeFromStr(contents, testAlloc);
    try expect_token_kinds_equals(expected, tokens);
    return tokens;
}

fn print_tokens(tokens: []Token) void {
    for (tokens) |token| {
        log.err("{}\n", .{token.kind});
    }
}

const expect = std.testing.expect;

test "add" {
    const tokens = try expect_results_in_tokens("1+2", &[_]TokenKind{
        .Number,
        .Plus,
        .Number,
        .Eof,
    });
    defer testAlloc.free(tokens);
}

test "simple_struct" {
    const content = "struct SimpleStruct { int x; int y; }";
    const tokens = try expect_results_in_tokens(content, &[_]TokenKind{
        .KeywordStruct,
        .Identifier,
        .LCurly,
        .KeywordInt,
        .Identifier,
        .Semicolon,
        .KeywordInt,
        .Identifier,
        .Semicolon,
        .RCurly,
        .Eof,
    });
    defer testAlloc.free(tokens);
    const ident_token = tokens[1];
    try expect(ident_token.kind == TokenKind.Identifier);

    // NODE: this should be implemented in some manner, I've hacked it out to reduce mem size
    //if (ident_token._range) |range| {
    //    try expect(std.mem.eql(u8, range.getSubStrFromStr(content), "SimpleStruct"));
    //} else {
    //    log.err("error: expected range for identifier token but got none\n", .{});
    //    return error.NoRangeForToken;
    //}
    try expect(std.mem.eql(u8, ident_token._range.getSubStrFromStr(content), "SimpleStruct"));
}

// TODO add deallocation
test "ident_can_not_start_with_num" {
    // NOTE: we should probably decide on how to handle this
    // OPTION A: do harder validation work in lexer for checking if
    //           thing after number is valid token (i.e. parsings job)
    //           and recognize it is invalid number
    // OPTION B: do easier validation in parser and don't identify it as
    //           invalid number, rather number,ident as invalid sequence
    //           THIS IS THE EASIEST AND THEREFORE BEST OPTION
    // OPTION C: do harder validation in parser, when identifying
    //           invalid sequence from (B), checking if it does not
    //           have whitespace before it and is therefore an invalid number
    //           not invalid sequence

    const tokens = try expect_results_in_tokens("1foo", &[_]TokenKind{
        .Number,
        .Identifier,
        .Eof,
    });
    defer testAlloc.free(tokens);
}

test "all_binops" {
    const tokens = try expect_results_in_tokens("+ - * / <= >= = ==", &[_]TokenKind{
        .Plus,
        .Minus,
        .Mul,
        .Div,
        .LtEq,
        .GtEq,
        .Eq,
        .DoubleEq,
        .Eof,
    });
    defer testAlloc.free(tokens);
}

test "invalid_char" {
    const contents = "%foo;";
    try std.testing.expectError(error.InvalidToken, Lexer.tokenizeFromStr(contents, testAlloc));
}

test "invalid_char_in_ident" {
    const contents = "foo%bar";
    try std.testing.expectError(error.InvalidToken, Lexer.tokenizeFromStr(contents, testAlloc));
}

// TODO: update this
test "all_keywords" {
    const tokens = try expect_results_in_tokens("delete endl false fun if new null read return struct true while", &[_]TokenKind{
        .KeywordDelete,
        .KeywordEndl,
        .KeywordFalse,
        .KeywordFun,
        .KeywordIf,
        .KeywordNew,
        .KeywordNull,
        .KeywordRead,
        .KeywordReturn,
        .KeywordStruct,
        .KeywordTrue,
        .KeywordWhile,
        .Eof,
    });
    defer testAlloc.free(tokens);
}

test "ident_with_num" {
    const tokens = try expect_results_in_tokens("foo1", &[_]TokenKind{
        .Identifier,
        .Eof,
    });
    defer testAlloc.free(tokens);
}

test "comment" {
    const input =
        \\ # inComment == new;
        \\ fun foo() void {
        \\    # inComment == true;
        \\      return; # postComment = while
        \\    # inComment == false;
        \\    # inComment == false;
        \\ }
        \\ # inComment == false;
    ;
    const tokens = try expect_results_in_tokens(input, &[_]TokenKind{
        .KeywordFun,
        .Identifier,
        .LParen,
        .RParen,
        .KeywordVoid,
        .LCurly,
        .KeywordReturn,
        .Semicolon,
        .RCurly,
        .Eof,
    });
    defer testAlloc.free(tokens);
}
