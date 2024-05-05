const std = @import("std");

pub fn assert(a: bool, comptime fmt: []const u8, vars: anytype) void {
    if (a) {
        return;
    }
    std.debug.panic(fmt, vars);
}

pub fn todo(comptime fmt: []const u8, vars: anytype) void {
    const prefix = "TODO: ";
    comptime var prefixedFmt: [prefix.len + fmt.len]u8 = .{0};
    @memcpy(prefixedFmt[0..prefix.len], prefix[0..prefix.len]);
    @memcpy(prefixedFmt[prefix.len..], fmt[0..fmt.len]);
    std.debug.panic(&prefixedFmt, vars);
}
