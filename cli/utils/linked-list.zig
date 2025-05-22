// Copyright (c) 2025
// Licensed under the GPLv3 — see LICENSE file for details.

const std = @import("std");
const stdout = std.io.getStdOut().writer();


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

const ListError = AllocError || WalkError || PrintError;


pub fn Node(comptime T: type) type {
    return struct {
        value: T,
        next: ?*Node(T),
        prev: ?*Node(T),
    };
}



/// Doubly linked list implementation with array-like access
pub fn LinkedList(comptime T: type) type {
    return struct {

        const Self = @This();

        // Instance fields: only name and type
        len: usize,
        head: ?*Node(T),
        tail: ?*Node(T),
        allocator: *std.mem.Allocator,

        pub fn init(_allocator: *std.mem.Allocator) Self {
            return Self{
                .len = 0,
                .head = null,
                .tail = null,
                .allocator = _allocator,
            };
        }

        /// Takes some slice and allocates the new linked list from the slice
        pub fn initFromSlice(_allocator: *std.mem.Allocator, slice: []T) !Self {
            var _self = Self{
                .len = 0,
                .head = null,
                .tail = null,
                .allocator = _allocator,
            };

            // Sets head
            try _self.prepend(slice[0]);

            for (1..slice.len) |i| {
                try _self.append(slice[i]);
            }

            _self.len = slice.len;
            return _self;
        }

        /// Returns an equivalent slice the current statie of the list
        pub fn toSlice(self: *Self, _allocator: *std.mem.Allocator) ListError![]T {
            
            var slice = _allocator.alloc(T, self.len) catch return error.OutOfMemory;

            var node = self.head;
            var i: usize = 0;

            while (node != null) : (node = node.?.next) {
                slice[i] = node.?.value;
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
        /// TODO: see if this can be inlined
        /// TODO: can be slightly optimized to be a forward walk if index < self.len / 2, a backwards walk if index > self.len / 2
        /// TODO: Could possibly also optionally take a node address to start from and start walking from there.
        fn walk(self: *Self, index: usize) ListError! ?*Node(T) {
            if (index >= self.len) {
                try stdout.print("[LinkedList] tried to access index {d} in a list of length {d}\n", .{index, self.len});
                return error.OutOfBounds;
            }

            var current = self.head;
            for (0..index) |i| {
                if (current) |curr| {
                    current = curr.next;
                } else {
                    try stdout.print("[LinkedList] the len attribute is set to {d}, but the element at index {d} is set to null.\n", .{index, i});
                    return error.InvalidNode;
                }
            }

            return current;
        }

        /// Reads the i-th element of the list
        pub fn read(self: *Self, index: usize) ListError!T {
            const current = try self.walk(index);
            return current.?.value;
        }

        /// Sets the value of the i-th element of the list
        pub fn write(self: *Self, index: usize, comptime value: T) ListError!void {
            const current = try self.walk(index);
            if (current) |node| {
                node.value = value;
            }
            // TODO: else case?
            return;
        }

        /// Formatted print of all elements in the list
        pub fn print(self: *Self) PrintError!void {
            const format_str = comptime switch (T) {
                [:0]u8, []u8, [:0]const u8, []const u8 => "{s}  ", // strings or slices
                u8, u16, u32, u64, usize => "{d}  ", // unsigned ints
                i8, i16, i32, i64, isize => "{d}  ", // signed ints
                f32, f64 => "{f}",                 // floats
                bool => "{}",                      // default formatting for bool is fine
                else => @compileError("Unsupported type for formatting"),
            };

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

        /// Remove the i-th element from the list
        /// TODO: also provide the version that can directly take the pointer to the element, so that the needless walk is avoided
        pub fn remove(self: *Self, index: usize) WalkError!void {
            const node = try self.walk(index);
            const elem = node orelse return WalkError.InvalidNode; // Makes it a valid node, not an optional

            // optionals
            const next_node = elem.next;
            const prev_node = elem.prev;

            if (next_node) |next| next.prev = prev_node;
            if (prev_node) |prev| prev.next = next_node;

            if (index == 0)             self.head = next_node;
            if (index == self.len - 1)   self.tail = prev_node;

            // TODO: check that this does set the head and tail to point to null in the appropriate direction.

            self.len -= 1;
            // TODO: optionally, free the element.
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
                    ,.{index, self.len});
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
            if (index == 0) {
                self.head     = new_node;
            } else if (index == self.len - 1) {
                self.tail     = new_node;
            }


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
                new_head.next  = self.tail;
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

            //self.allocator.free(self);
        }
    };
}
