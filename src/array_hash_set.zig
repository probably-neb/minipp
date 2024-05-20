/// Based of the work of Ralph Caraveo {
///     Open Source Initiative OSI - The MIT License (MIT):Licensing
///     The MIT License (MIT)
///     Copyright (c) 2024 Ralph Caraveo (deckarep@gmail.com)
///     Permission is hereby granted, free of charge, to any person obtaining a copy of
///     this software and associated documentation files (the "Software"), to deal in
///     the Software without restriction, including without limitation the rights to
///     use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
///     of the Software, and to permit persons to whom the Software is furnished to do
///     so, subject to the following conditions:
///     The above copyright notice and this permission notice shall be included in all
///     copies or substantial portions of the Software.
///     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
///     IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
///     FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
///     AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
///     LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
///     OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
///     SOFTWARE.
///}
///
///
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

pub fn Set(comptime E: type) type {
    return struct {
        pub const Map = std.AutoArrayHashMapUnmanaged(E, void);

        pub const Self = @This();
        unmanaged: Map,
        pub const Size = usize;

        pub const Entry = struct {
            key_ptr: *E,
        };

        pub const Iterator = struct {
            keys: [*]E,
            len: usize,
            index: usize = 0,

            pub fn next(self: *Iterator) ?Entry {
                if (self.index >= self.len) return null;
                const result = Entry{ .key_ptr = &self.keys[self.index] };
                self.index += 1;
                return result;
            }

            pub fn reset(self: *Iterator) void {
                self.index = 0;
            }
        };

        pub fn print(self: Self) void {
            std.debug.print("Set (", .{});
            var iter = self.iterator();
            while (iter.next()) |entry| {
                std.debug.print("{any}", .{entry.key_ptr.*});
                std.debug.print(", ", .{});
            }
            std.debug.print(")", .{});
        }

        pub fn init() Self {
            return .{
                .unmanaged = Map{},
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            self.unmanaged.deinit(allocator);
            self.* = undefined;
        }

        pub fn add(self: *Self, allocator: Allocator, element: E) Allocator.Error!bool {
            const prevCount = self.unmanaged.count();
            try self.unmanaged.put(allocator, element, {});
            return prevCount != self.unmanaged.count();
        }

        /// Appends all elements from the provided slice, and may allocate.
        /// appendSlice returns an Allocator.Error or Size which represents how
        /// many elements added and not previously in the slice.
        pub fn appendSlice(self: *Self, allocator: Allocator, elements: []const E) Allocator.Error!Size {
            const prevCount = self.unmanaged.count();
            for (elements) |el| {
                try self.unmanaged.put(allocator, el, {});
            }
            return self.unmanaged.count() - prevCount;
        }

        /// Returns the number of total elements which may be present before
        /// it is no longer guaranteed that no allocations will be performed.
        pub fn capacity(self: *Self) Size {
            // Note: map.capacity() requires mutable access, probably an oversight.
            return self.unmanaged.capacity();
        }

        /// Cardinality effectively returns the size of the set.
        pub fn cardinality(self: Self) Size {
            return self.unmanaged.count();
        }

        /// Invalidates all element pointers.
        pub fn clearAndFree(self: *Self, allocator: Allocator) void {
            self.unmanaged.clearAndFree(allocator);
        }

        /// Invalidates all element pointers.
        pub fn clearRetainingCapacity(self: *Self) void {
            self.unmanaged.clearRetainingCapacity();
        }

        /// Creates a copy of this set, using the same allocator.
        /// clone may return an Allocator.Error or the cloned Set.
        pub fn clone(self: *Self, allocator: Allocator) Allocator.Error!Self {
            // Take a stack copy of self.
            var cloneSelf = self.*;
            // Clone the interal map.
            cloneSelf.unmanaged = try self.unmanaged.clone(allocator);
            return cloneSelf;
        }

        /// Returns true when the provided element exists within the Set otherwise false.
        pub fn contains(self: Self, element: E) bool {
            return self.unmanaged.contains(element);
        }

        /// Returns true when all elements in the other Set are present in this Set
        /// otherwise false.
        pub fn containsAll(self: Self, other: Self) bool {
            var iter = other.iterator();
            while (iter.next()) |el| {
                if (!self.unmanaged.contains(el.*)) {
                    return false;
                }
            }
            return true;
        }

        /// Returns true when all elements in the provided slice are present otherwise false.
        pub fn containsAllSlice(self: Self, elements: []const E) bool {
            for (elements) |el| {
                if (!self.unmanaged.contains(el)) {
                    return false;
                }
            }
            return true;
        }

        /// Returns true when at least one or more elements from the other Set exist within
        /// this Set otherwise false.
        pub fn containsAny(self: Self, other: Self) bool {
            var iter = other.iterator();
            while (iter.next()) |el| {
                if (self.unmanaged.contains(el.*)) {
                    return true;
                }
            }
            return false;
        }

        pub fn ensureTotalCapacity(self: *Self, allocator: Allocator, num: Size) Allocator.Error!void {
            return self.unmanaged.ensureTotalCapacity(allocator, num);
        }

        /// differenceOf returns the difference between this set
        /// and other. The returned set will contain
        /// all elements of this set that are not also
        /// elements of the other.
        ///
        /// Caller owns the newly allocated/returned set.
        pub fn differenceOf(self: Self, allocator: Allocator, other: Self) Allocator.Error!Self {
            var diffSet = Self.init();

            var iter = self.unmanaged.iterator();
            while (iter.next()) |entry| {
                if (!other.unmanaged.contains(entry.key_ptr.*)) {
                    _ = try diffSet.add(allocator, entry.key_ptr.*);
                }
            }
            return diffSet;
        }

        /// differenceUpdate does an in-place mutation of this set
        /// and other. This set will contain all elements of this set that are not
        /// also elements of other.
        pub fn differenceUpdate(self: *Self, allocator: Allocator, other: Self) Allocator.Error!void {
            // In-place mutation invalidates iterators therefore a temp set is needed.
            // So instead of a temp set, just invoke the regular full function which
            // allocates and returns a set then swap out the map internally.

            // Also, this saves a step of not having to possibly discard many elements
            // from the self set.

            // Just get a new set with the normal method.
            const diffSet = try self.differenceOf(allocator, other);

            // Destroy the internal map.
            self.unmanaged.deinit(allocator);

            // Swap it out with the new set.
            self.unmanaged = diffSet.unmanaged;
        }

        /// Returns true when at least one or more elements from the slice exist within
        /// this Set otherwise false.
        pub fn containsAnySlice(self: Self, elements: []const E) bool {
            for (elements) |el| {
                if (self.unmanaged.contains(el)) {
                    return true;
                }
            }
            return false;
        }

        /// eql determines if two sets are equal to each
        /// other. If they have the same cardinality
        /// and contain the same elements, they are
        /// considered equal. The order in which
        /// the elements were added is irrelevant.
        pub fn eql(self: Self, other: Self) bool {
            // First discriminate on cardinalities of both sets.
            if (self.unmanaged.count() != other.unmanaged.count()) {
                return false;
            }

            // Now check for each element one for one and exit early
            // on the first non-match.
            var iter = self.unmanaged.iterator();
            while (iter.next()) |entry| {
                if (!other.unmanaged.contains(entry.key_ptr.*)) {
                    return false;
                }
            }

            return true;
        }

        /// intersectionOf returns a new set containing only the elements
        /// that exist only in both sets.
        ///
        /// Caller owns the newly allocated/returned set.
        pub fn intersectionOf(self: Self, allocator: Allocator, other: Self) Allocator.Error!Self {
            var interSet = Self.init();

            // Optimization: iterate over whichever set is smaller.
            // Matters when disparity in cardinality is large.
            var s = other;
            var o = self;
            if (self.unmanaged.count() < other.unmanaged.count()) {
                s = self;
                o = other;
            }

            var iter = s.unmanaged.iterator();
            while (iter.next()) |entry| {
                if (o.unmanaged.contains(entry.key_ptr.*)) {
                    _ = try interSet.add(allocator, entry.key_ptr.*);
                }
            }

            return interSet;
        }

        /// intersectionUpdate does an in-place intersecting update
        /// to the current set from the other set keeping only
        /// elements found in this Set and the other Set.
        pub fn intersectionUpdate(self: *Self, allocator: Allocator, other: Self) Allocator.Error!void {
            // In-place mutation invalidates iterators therefore a temp set is needed.
            // So instead of a temp set, just invoke the regular full function which
            // allocates and returns a set then swap out the map internally.

            // Also, this saves a step of not having to possibly discard many elements
            // from the self set.

            // Just get a new set with the normal method.
            const interSet = try self.intersectionOf(allocator, other);

            // Destroy the internal map.
            self.unmanaged.deinit(allocator);

            // Swap it out with the new set.
            self.unmanaged = interSet.unmanaged;
        }

        pub fn isEmpty(self: Self) bool {
            return self.unmanaged.count() == 0;
        }

        /// Create an iterator over the elements in the set.
        /// The iterator is invalidated if the set is modified during iteration.
        pub fn iterator(self: Self) Iterator {
            const slice = self.unmanaged.entries.slice();
            return .{
                .keys = slice.items(.key).ptr,
                .len = @as(u32, @intCast(slice.len)),
            };
        }

        /// properSubsetOf determines if every element in this set is in
        /// the other set but the two sets are not equal.
        pub fn properSubsetOf(self: Self, other: Self) bool {
            return self.unmanaged.count() < other.unmanaged.count() and self.subsetOf(other);
        }

        /// properSupersetOf determines if every element in the other set
        /// is in this set but the two sets are not equal.
        pub fn properSupersetOf(self: Self, other: Self) bool {
            return self.unmanaged.count() > other.unmanaged.count() and self.supersetOf(other);
        }

        /// subsetOf determines if every element in this set is in
        /// the other set.
        pub fn subsetOf(self: Self, other: Self) bool {
            // First discriminate on cardinalties of both sets.
            if (self.unmanaged.count() > other.unmanaged.count()) {
                return false;
            }

            // Now check that self set has at least some elements from other.
            var iter = self.unmanaged.iterator();
            while (iter.next()) |entry| {
                if (!other.unmanaged.contains(entry.key_ptr.*)) {
                    return false;
                }
            }

            return true;
        }

        /// subsetOf determines if every element in the other Set is in
        /// the this Set.
        pub fn supersetOf(self: Self, other: Self) bool {
            // This is just the converse of subsetOf.
            return other.subsetOf(self);
        }

        /// pop removes and returns an arbitrary ?E from the set.
        /// Order is not guaranteed.
        /// This safely returns null if the Set is empty.
        pub fn pop(self: *Self) ?E {
            if (self.unmanaged.count() > 0) {
                var iter = self.unmanaged.iterator();
                // NOTE: No in-place mutation as it invalidates live iterators.
                // So a temporary capture is taken.
                var capturedElement: E = undefined;
                while (iter.next()) |entry| {
                    capturedElement = entry.key_ptr.*;
                    break;
                }
                _ = self.unmanaged.swapRemove(capturedElement);
                return capturedElement;
            } else {
                return null;
            }
        }

        /// remove discards a single element from the Set
        pub fn remove(self: *Self, element: E) bool {
            return self.unmanaged.swapRemove(element);
        }

        /// removesAll discards all elements passed from the other Set from
        /// this Set
        pub fn removeAll(self: *Self, other: Self) void {
            var iter = other.iterator();
            while (iter.next()) |el| {
                _ = self.unmanaged.swapRemove(el.key_ptr.*);
            }
        }

        /// removesAllSlice discards all elements passed as a slice from the Set
        pub fn removeAllSlice(self: *Self, elements: []const E) void {
            for (elements) |el| {
                _ = self.unmanaged.swapRemove(el);
            }
        }

        /// symmetricDifferenceOf returns a new set with all elements which are
        /// in either this set or the other set but not in both.
        ///
        /// The caller owns the newly allocated/returned Set.
        pub fn symmetricDifferenceOf(self: Self, allocator: Allocator, other: Self) Allocator.Error!Self {
            var sdSet = Self.init();

            var iter = self.unmanaged.iterator();
            while (iter.next()) |entry| {
                if (!other.unmanaged.contains(entry.key_ptr.*)) {
                    _ = try sdSet.add(allocator, entry.key_ptr.*);
                }
            }

            iter = other.unmanaged.iterator();
            while (iter.next()) |entry| {
                if (!self.unmanaged.contains(entry.key_ptr.*)) {
                    _ = try sdSet.add(allocator, entry.key_ptr.*);
                }
            }

            return sdSet;
        }

        /// symmetricDifferenceUpdate does an in-place mutation with all elements
        /// which are in either this set or the other set but not in both.
        pub fn symmetricDifferenceUpdate(self: *Self, allocator: Allocator, other: Self) Allocator.Error!void {
            // In-place mutation invalidates iterators therefore a temp set is needed.
            // So instead of a temp set, just invoke the regular full function which
            // allocates and returns a set then swap out the map internally.

            // Also, this saves a step of not having to possibly discard many elements
            // from the self set.

            // Just get a new set with the normal method.
            const sd = try self.symmetricDifferenceOf(allocator, other);

            // Destroy the internal map.
            self.unmanaged.deinit(allocator);

            // Swap it out with the new set.
            self.unmanaged = sd.unmanaged;
        }

        /// union returns a new set with all elements in both sets.
        ///
        /// The caller owns the newly allocated/returned Set.
        pub fn unionOf(self: Self, allocator: Allocator, other: Self) Allocator.Error!Self {
            // Sniff out larger set for capacity hint.
            var n = self.unmanaged.count();
            if (other.unmanaged.count() > n) n = other.unmanaged.count();

            var uSet = try Self.initCapacity(
                allocator,
                @intCast(n),
            );

            var iter = self.unmanaged.iterator();
            while (iter.next()) |entry| {
                _ = try uSet.add(allocator, entry.key_ptr.*);
            }

            iter = other.unmanaged.iterator();
            while (iter.next()) |entry| {
                _ = try uSet.add(allocator, entry.key_ptr.*);
            }

            return uSet;
        }

        /// unionUpdate does an in-place union of the current Set and other Set.
        ///
        /// Allocations may occur.
        pub fn unionUpdate(self: *Self, allocator: Allocator, other: Self) Allocator.Error!void {
            var iter = other.unmanaged.iterator();
            while (iter.next()) |entry| {
                _ = try self.add(allocator, entry.key_ptr.*);
            }
        }
    };
}
