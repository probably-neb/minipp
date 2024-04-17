const std = @import("std");

pub fn assert(a: bool, comptime fmt: []const u8, vars: anytype) void {
    if (a) {
        return;
    }
    std.debug.panic(fmt, vars);
}
