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

var msgs = std.ArrayList(Msg).init(alloc);

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

/// prints all messages in the log
pub fn print() void {
    for (msgs.items) |msg| {
        switch (msg.level) {
            .Info => std.debug.print("INFO  : {s}", .{msg.msg}),
            .Err => std.debug.print("ERROR : {s}", .{msg.msg}),
            .Warn => std.debug.print("WARN  : {s}", .{msg.msg}),
            .Trace => std.debug.print("TRACE : {s}", .{msg.msg}),
        }
    }
}

/// clears all allocated messages and empties the list
/// but does not destroy the list itself
fn clear() void {
    for (msgs.items()) |msg| {
        alloc.destroy(msg.msg);
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
