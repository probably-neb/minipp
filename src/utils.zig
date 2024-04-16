const errprint = @import("std").debug.print;

pub fn assert(a: bool, fmt: []const u8, vars: anytype) !void {
    if (a) return;
    errprint(fmt, vars);
    return error.AssertionError;
}
