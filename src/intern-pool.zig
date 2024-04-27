// Defines an intern pool for strings. Used for easy lookup / comparison of strings based on their index in a biggg pool of bytes

const std = @import("std");
const utils = @import("utils.zig");

/// Maps strings to it's index in the pool
map: std.StringHashMap(StrID),
// pool of bytes
pool: std.ArrayList(u8),

pub const StrID = u32;

pub const InternPool = @This();

pub const Error = error{ StringNotPresent, OutOfMemory };

pub fn init(allocator: std.mem.Allocator) InternPool {
    return InternPool{
        .map = std.StringHashMap(StrID).init(allocator),
        .pool = std.ArrayList(u8).init(allocator),
    };
}

/// Adds a string to the pool and returns it's index
/// Assumes the check that the string has already been interned has already been done (could honestly just be named addUnchecked)
fn addInner(self: *InternPool, str: []const u8) std.mem.Allocator.Error!StrID {
    const len = str.len;
    var pool = &self.pool;
    const index: u32 = @intCast(pool.items.len);
    // plus 1 for null terminator
    const extraCapacity = len + 1;
    try pool.ensureUnusedCapacity(extraCapacity);
    pool.appendSliceAssumeCapacity(str);
    pool.appendAssumeCapacity(0);

    try self.map.put(str, index);
    return index;
}

pub fn intern(self: *InternPool, str: []const u8) std.mem.Allocator.Error!StrID {
    // This is not arbitrary I swear.
    // Why on gods green earth would you desire this capability
    utils.assert(str.len > 0, "Can't intern an empty string", .{});
    if (self.map.get(str)) |i| {
        return i;
    }
    return self.addInner(str);
}

/// Returns the string
pub fn get(self: *InternPool, id: StrID) Error![]const u8 {
    var i: u32 = id;
    const pool = self.pool.items;
    while (i < pool.len and pool[i] != 0) : ({
        i += 1;
    }) {}
    const str: []const u8 = pool[id..i];

    if (self.map.get(str) != id) {
        // because we just keep going until we find null terminator, this is a
        // pedantic check to make sure what we extracted is actually something
        // that was interned not just a random sequence of bytes
        return error.StringNotPresent;
    }
    return str;
}

const ting = std.testing;
const testAlloc = std.heap.page_allocator;

test "intern.multiple_interns_ignored" {
    var pool = init(testAlloc);
    const i = try pool.intern("foo");
    try ting.expectEqual(i, try pool.intern("foo"));
    try ting.expectEqual(i, try pool.intern("foo"));
}

test "intern.get" {
    var pool = init(testAlloc);
    const i = try pool.intern("foo");
    try ting.expectEqualStrings("foo", try pool.get(i));
}

test "intern.get_fake_id_is_err" {
    var pool = init(testAlloc);
    const i = try pool.intern("foo");
    try ting.expectError(error.StringNotPresent, pool.get(i + 1));
}
