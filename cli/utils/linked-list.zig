// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

const std = @import("std");
const stdout = std.io.getStdOut().writer();

// Error sets defined further down
pub const ListError = AllocError || WalkError || PrintError;

pub fn Node(comptime T: type) type {
    return struct {
        value: T,
        next: ?*Node(T),
        prev: ?*Node(T),
    };
}

/// Doubly linked list implementation with array-like access to elements
/// Provides methods to go from slice to list and vice versa.
pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        // Instance fields: only name and type
        len: usize,
        head: ?*Node(T),
        tail: ?*Node(T),
        allocator: *std.mem.Allocator,

        /// Provides a LinkedList instance, ready to be populated.
        pub fn init(_allocator: *std.mem.Allocator) Self {
            return Self{
                .len = 0,
                .head = null,
                .tail = null,
                .allocator = _allocator,
            };
        }

        /// Takes some slice and allocates the new linked list from the slice
        pub fn initFromSlice(_allocator: *std.mem.Allocator, slice: []const T) !Self {
            var self = init(_allocator);
            if (slice.len == 0) return self;

            // Sets head
            try self.prepend(slice[0]);

            for (1..slice.len) |i| {
                try self.append(slice[i]);
            }

            return self;
        }

        /// Returns an equivalent slice from the current state of the list; the slice is allocated using the 
        /// provided allocator, so freeing it is up to the caller.
        pub fn toSlice(self: *Self, _allocator: *std.mem.Allocator) ListError![]T {
            var slice: []T = _allocator.alloc(T, self.len) catch return error.OutOfMemory;
            // slice.len = self.len; // no, it's read only

            var node = self.head;
            var i: usize = 0;

            while (node) |n| {
                slice[i] = n.value;
                node = n.next;
                i += 1;
            }

            if (i + 1 < self.len) {
                _allocator.free(slice);
                try stdout.print("[LinkedList] Something went wrong when emitting the slice.\n", .{});
                return error.InvalidNode;
            }

            return slice;
        }

        /// Accesses the i-th element of the list, or returns out of bounds if it doesn't exist
        /// TODO: can be slightly optimized to be a forward walk if index < self.len / 2, a backwards walk if index > self.len / 2
        /// TODO: Could possibly also optionally take a node address to start from and start walking from there.
        inline fn walk(self: *Self, index: usize) (WalkError||PrintError)!?*Node(T) {
            if (index >= self.len) {
                try stdout.print("[LinkedList] tried to access index {d} in a list of length {d}\n", .{ index, self.len });
                return error.OutOfBounds;
            }

            var current = self.head;
            for (0..index) |i| {
                if (current) |curr| {
                    current = curr.next;
                } else {
                    try stdout.print("[LinkedList] the len attribute is set to {d}, but the element at index {d} is set to null.\n", .{ index, i });
                    return error.InvalidNode;
                }
            }

            return current;
        }

        /// Checks if a given value is present in the list, and if so sets the index where said value is first encountered.
        pub fn where(self: *Self, value: T, out_index: *usize, out_address: **Node(T) ) bool {

            var current = self.head;
            for (0..self.len) |i| {
                if (std.mem.eql(u8, current.?.value, value)) {
                    out_index.* = i;
                    out_address.* = current.? ;
                    return true;
                }
                current = current.?.next;
            }

            return false;
        }

        /// Simply returns if the value was encountered or not.
        pub fn contains(self: *Self, value: T) bool {
            var dummy_idx: usize = undefined;
            var dummy_addr: *Node(T) = undefined;
            return self.where(value, &dummy_idx, &dummy_addr);
        }

        /// You give it a value; it returns the next if found, null otherwise.
        pub fn getNextValue(self: *Self, value: T) ?T {
            var dummy: usize = undefined;
            var address: *Node(T) = undefined;
            
            const found = self.where(value, &dummy, &address);

            if (!found) return null;
            if (address.next == null) return null;
            return address.next.?.value;
        }

        /// Reads the i-th element of the list
        pub fn read(self: *Self, index: usize) ListError!T {
            const current = try self.walk(index);
            return current.?.value;
        }

        /// Sets the value of the i-th element of the list
        pub fn write(self: *Self, index: usize, value: T) ListError!void {
            const node = try self.walk(index);
            node.?.value = value;
        }

        /// Formatted print of all elements in the list
        pub fn print(self: *Self) PrintError!void {
            const format_str = comptime switch (T) {
                [:0]u8, []u8, [:0]const u8, []const u8 => "{s}  ",
                u8, u16, u32, u64, usize => "{d}  ",
                i8, i16, i32, i64, isize => "{d}  ",
                f32, f64 => "{f}",
                bool => "{}",
                else => @compileError("Unsupported type for formatting"),
            };

            try stdout.print("====[Printing LinkedList(  " ++ format_str ++ ")]====\n", .{@typeName(T)});
            try stdout.print("List length: {}\n", .{self.len});

            var current = self.head;
            if (current) |head| {
                try stdout.print(format_str, .{head.value});
                current = head.next;

                while (current) |node| {
                    try stdout.print("<-> " ++ format_str, .{node.value});
                    current = node.next;
                }
            }

            try stdout.print("\n", .{});
        }

        /// Unlinks the node without performing the walk along the chain.
        pub fn removeFromPtr(self: *Self, node: *Node(T)) void {
            if (node.next) |next| {
                next.prev = node.prev;
            }

            if (node.prev) |prev| {
                prev.next = node.next;
            }

            if (self.head == node) {
                self.head = node.next;
            } else if (self.tail == node) {
                self.tail = node.prev;
            }

            self.len -= 1;

            // TODO: optionally, free memory.
        }

        /// Remove the i-th element from the list
        pub fn remove(self: *Self, index: usize) WalkError!void {
            const node = try self.walk(index);
            const elem = node orelse return WalkError.InvalidNode; // Makes it a valid node, not an optional
            self.removeFromPtr(elem);
        }

        /// Inserts an element at a certain index in the middle of the chain, and shifts the old resident at that index down by one position towards the tail.
        /// It cannot append to head or tail, i.e. valid indices are between 1 and len - 2.
        /// Use append() and prepend() to add a new element to the tail or head.
        pub fn insert(self: *Self, index: usize, value: T) ListError!void {
            if (index <= 0 or self.len < 2 or index >= self.len) {
                try stdout.print(
                    \\[LinkedList] Attempted to insert a new element at index {d} for a list with length {d};
                    \\Insertion is only available for middle nodes (1 to len-2)
                    \\Consider using append() and prepend() methods to alter tail or head of the list.
                    \\
                , .{ index, self.len });
                return error.OutOfBounds;
            }

            var new_node = try self.allocator.create(Node(T));
            new_node.* = .{
                .value = value,
                .prev = null,
                .next = null,
            };

            // Holds the node currently in the index we want to write
            const old_node = try self.walk(index);

            // Re-link
            const old = old_node orelse unreachable;

            new_node.prev = old.prev;
            new_node.next = old;

            if (old.prev) |prev| {
                prev.next = new_node;
            }

            self.len += 1;
        }

        /// Sets new tail
        pub fn append(self: *Self, value: T) AllocError!void {
            const new_tail = try self.allocator.create(Node(T));
            new_tail.* = .{
                .value = value,
                .prev = null,
                .next = null,
            };

            if (self.tail) |old_tail| {
                old_tail.next = new_tail;
                new_tail.prev = old_tail;
            } else {
                new_tail.prev = self.head;
                if (self.head) |head| head.next = new_tail;
            }

            self.tail = new_tail;
            self.len += 1;
        }

        /// Sets a new head
        pub fn prepend(self: *Self, value: T) AllocError!void {
            const new_head = try self.allocator.create(Node(T));
            new_head.* = .{
                .value = value,
                .prev = null,
                .next = null,
            };

            if (self.head) |old_head| {
                old_head.prev = new_head;
                new_head.next = old_head;
            } else {
                new_head.next = self.tail;
                if (self.tail) |tail| tail.prev = new_head;
            }

            self.head = new_head;
            self.len += 1;
        }

        /// Release the allocated memory of all nodes
        pub fn free(self: *Self) void {
            var current = self.head;
            while (current) |node| {
                const next = node.next;
                self.allocator.destroy(node);
                current = next;
            }

            self.head = null;
            self.tail = null;
            self.len = 0;
        }
    };
}

// Error sets used by the LinkedList class
const WalkError = error{
    OutOfBounds,
    InvalidNode,
};

const AllocError = error{
    OutOfMemory,
};

const PrintError = error{
    AccessDenied,
    BrokenPipe,
    ConnectionResetByPeer,
    DeviceBusy,
    DiskQuota,
    FileTooBig,
    InputOutput,
    InvalidArgument,
    LockViolation,
    MessageTooBig,
    NoDevice,
    NoSpaceLeft,
    NotOpenForWriting,
    OperationAborted,
    PermissionDenied,
    ProcessNotFound,
    SystemResources,
    Unexpected,
    WouldBlock,
};

// ====================[ Tests ]=======================

test "Conversion Slice <-> Linked list" {
    var allocator = std.testing.allocator;

    const strings = [_][:0]const u8{ "hello", "world", "whats", "up", "?" };

    var list = try LinkedList([:0]const u8).initFromSlice(&allocator, &strings);
    defer list.free();

    const recovered_slice = try list.toSlice(&allocator);
    defer allocator.free(recovered_slice);

    try std.testing.expect(strings.len == recovered_slice.len);

    for (0..recovered_slice.len) |i| {
        try std.testing.expect(std.mem.eql(u8, strings[i], recovered_slice[i]));
    }
}

test "Check insertion" {
    var allocator = std.testing.allocator;

    var list = LinkedList([:0]const u8).init(&allocator);
    defer list.free();

    try list.prepend("Hello");
    try list.append("world");

    const addendum: [:0]const u8 = try allocator.dupeZ(u8, "beautiful");
    defer allocator.free(addendum);

    try list.insert(1, addendum);

    try std.testing.expect(list.len == 3);
    try std.testing.expect(std.mem.eql(u8, list.head.?.value, "Hello"));
    try std.testing.expect(std.mem.eql(u8, list.tail.?.value, "world"));
}

test "Print a list" {
    var allocator = std.testing.allocator;

    var list = LinkedList([:0]const u8).init(&allocator);
    defer list.free();

    try list.prepend("If");
    try list.append("you");
    try list.append("can");
    try list.append("read");
    try list.append("this");
    try list.append("the");
    try list.append("test");
    try list.append("worked");

    try list.print();
}

test "Finding values" {
    var allocator = std.testing.allocator;

    var list = LinkedList([:0]const u8).init(&allocator);
    defer list.free();

    try list.prepend("Hello");
    try list.append("world!");

    try std.testing.expect(list.contains("Hello"));
    try std.testing.expect(!list.contains("( ͡° ͜ʖ ͡°)"));

    var index: usize = undefined;
    try std.testing.expect(list.where("world!", &index));

    try std.testing.expect(index == 1);
}

