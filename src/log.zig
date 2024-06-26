/// This Lib is a part of the Rust Core Library (idk copilot wrote that)
/// It is designed for delaying error and other logging. I decided to write it
/// when type checking got complicated.
/// It uses a global allocator and message log to store messages until a call to print
const Self = @This();

const std = @import("std");

const Level = enum {
    Trace,
    Info,
    Err,
    Warn,
};

const Msg = struct {
    level: Level,
    msg: []const u8,
};

const alloc = std.heap.page_allocator;

threadlocal var msgs = std.ArrayList(Msg).init(alloc);

fn logInner(level: Level, comptime msg: []const u8, vars: anytype) void {
    const slice = std.fmt.allocPrint(alloc, msg, vars) catch |e| {
        std.debug.print("Failed to format message: {}\n", .{e});
        return;
    };
    msgs.append(Msg{ .msg = slice, .level = level }) catch |e| {
        std.debug.print("Failed to append message: {}\n", .{e});
        return;
    };
}

pub fn trace(comptime msg: []const u8, vars: anytype) void {
    logInner(Level.Trace, msg, vars);
}
/// Log a message with the `info` level. Fails silently if the message can't be formatted.
pub fn info(comptime msg: []const u8, vars: anytype) void {
    logInner(Level.Info, msg, vars);
}

pub fn err(comptime msg: []const u8, vars: anytype) void {
    logInner(Level.Err, msg, vars);
}

pub fn warn(comptime msg: []const u8, vars: anytype) void {
    logInner(Level.Warn, msg, vars);
}

const RED = "\x1b[0;31m";
const GREEN = "\x1b[0;32m";
const YELLOW = "\x1b[0;33m";
const BLUE = "\x1b[0;34m";
const NC = "\x1b[0m";

fn print_inner(prefix: []const u8) void {
    for (msgs.items) |msg| {
        switch (msg.level) {
            .Info => std.debug.print("{s}{s}INFO{s}  : {s}", .{ prefix, GREEN, NC, msg.msg }),
            .Err => std.debug.print("{s}{s}ERROR{s} : {s}", .{ prefix, RED, NC, msg.msg }),
            .Warn => std.debug.print("{s}{s}WARN{s}  : {s}", .{ prefix, YELLOW, NC, msg.msg }),
            .Trace => std.debug.print("{s}{s}TRACE{s} : {s}", .{ prefix, BLUE, NC, msg.msg }),
        }
    }
    clear();
}
/// prints all messages in the log
pub fn print() void {
    print_inner("");
}

/// prints all messages in the log with a prefix
pub fn printWithPrefix(comptime prefix: []const u8) void {
    print_inner("[" ++ prefix ++ "] ");
}

pub fn empty() void {
    for (msgs.items) |msg| {
        alloc.free(msg.msg);
    }

    msgs.clearRetainingCapacity();
}

/// clears all allocated messages and empties the list
/// but does not destroy the list itself
fn clear() void {
    for (msgs.items) |msg| {
        alloc.free(msg.msg);
    }
    msgs.clearAndFree();
}

/// Deinitializes the log, destroying all messages and the list itself
pub fn deinit() void {
    for (msgs.items()) |msg| {
        alloc.destroy(msg.msg);
    }
    msgs.deinit();
}
