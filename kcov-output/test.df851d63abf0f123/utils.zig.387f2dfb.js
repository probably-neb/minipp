var data = {lines:[
{"lineNum":"    1","line":"const std = @import(\"std\");"},
{"lineNum":"    2","line":""},
{"lineNum":"    3","line":"pub fn assert(a: bool, comptime fmt: []const u8, vars: anytype) void {","class":"lineCov","hits":"5","order":"871","possible_hits":"5",},
{"lineNum":"    4","line":"    if (a) {","class":"lineCov","hits":"5","order":"872","possible_hits":"5",},
{"lineNum":"    5","line":"        return;","class":"lineCov","hits":"5","order":"873","possible_hits":"5",},
{"lineNum":"    6","line":"    }"},
{"lineNum":"    7","line":"    std.debug.panic(fmt, vars);","class":"lineNoCov","hits":"0","possible_hits":"5",},
{"lineNum":"    8","line":"}"},
{"lineNum":"    9","line":""},
{"lineNum":"   10","line":"pub fn todo(comptime fmt: []const u8, vars: anytype) void {","class":"lineNoCov","hits":"0","possible_hits":"13",},
{"lineNum":"   11","line":"    std.debug.panic(fmt, vars);","class":"lineNoCov","hits":"0","possible_hits":"13",},
{"lineNum":"   12","line":"}"},
]};
var percent_low = 25;var percent_high = 75;
var header = { "command" : "test", "date" : "2024-04-26 16:14:49", "instrumented" : 6, "covered" : 3,};
var merged_data = [];
