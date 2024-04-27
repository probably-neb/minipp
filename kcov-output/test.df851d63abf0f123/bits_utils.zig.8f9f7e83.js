var data = {lines:[
{"lineNum":"    1","line":"const math = @import(\"std\").math;"},
{"lineNum":"    2","line":""},
{"lineNum":"    3","line":"// Reverse bit-by-bit a N-bit code."},
{"lineNum":"    4","line":"pub fn bitReverse(comptime T: type, value: T, N: usize) T {","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"    5","line":"    const r = @bitReverse(value);","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"    6","line":"    return r >> @as(math.Log2Int(T), @intCast(@typeInfo(T).Int.bits - N));","class":"lineNoCov","hits":"0","possible_hits":"2",},
{"lineNum":"    7","line":"}"},
{"lineNum":"    8","line":""},
{"lineNum":"    9","line":"test \"bitReverse\" {"},
{"lineNum":"   10","line":"    const std = @import(\"std\");"},
{"lineNum":"   11","line":""},
{"lineNum":"   12","line":"    const ReverseBitsTest = struct {"},
{"lineNum":"   13","line":"        in: u16,"},
{"lineNum":"   14","line":"        bit_count: u5,"},
{"lineNum":"   15","line":"        out: u16,"},
{"lineNum":"   16","line":"    };"},
{"lineNum":"   17","line":""},
{"lineNum":"   18","line":"    var reverse_bits_tests = [_]ReverseBitsTest{"},
{"lineNum":"   19","line":"        .{ .in = 1, .bit_count = 1, .out = 1 },"},
{"lineNum":"   20","line":"        .{ .in = 1, .bit_count = 2, .out = 2 },"},
{"lineNum":"   21","line":"        .{ .in = 1, .bit_count = 3, .out = 4 },"},
{"lineNum":"   22","line":"        .{ .in = 1, .bit_count = 4, .out = 8 },"},
{"lineNum":"   23","line":"        .{ .in = 1, .bit_count = 5, .out = 16 },"},
{"lineNum":"   24","line":"        .{ .in = 17, .bit_count = 5, .out = 17 },"},
{"lineNum":"   25","line":"        .{ .in = 257, .bit_count = 9, .out = 257 },"},
{"lineNum":"   26","line":"        .{ .in = 29, .bit_count = 5, .out = 23 },"},
{"lineNum":"   27","line":"    };"},
{"lineNum":"   28","line":""},
{"lineNum":"   29","line":"    for (reverse_bits_tests) |h| {"},
{"lineNum":"   30","line":"        var v = bitReverse(u16, h.in, h.bit_count);"},
{"lineNum":"   31","line":"        try std.testing.expectEqual(h.out, v);"},
{"lineNum":"   32","line":"    }"},
{"lineNum":"   33","line":"}"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test", "date" : "2024-04-26 16:14:49", "instrumented" : 3, "covered" : 0,};
var merged_data = [];