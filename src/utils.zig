const std = @import("std");

pub fn assert(a: bool, comptime fmt: []const u8, vars: anytype) void {
    if (a) {
        return;
    }
    std.debug.panic(fmt, vars);
}

pub fn todo(comptime fmt: []const u8, vars: anytype) noreturn {
    const prefix = "TODO: ";
    std.debug.panic(prefix ++ fmt, vars);
}

// Like todo, but for unreachable
// had to name it impossible because unreachable is a keyword
pub fn impossible(comptime fmt: []const u8, vars: anytype) noreturn {
    const prefix = "UNREACHABLE: ";
    std.debug.panic(prefix ++ fmt, vars);
}
