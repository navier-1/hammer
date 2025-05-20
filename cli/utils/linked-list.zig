const std = @import("std");
const stdout = std.io.getStdOut().writer();


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

        // Takes some slice and allocates the new linked list from the slice
        pub fn initFromSlice(_allocator: *std.mem.Allocator, slice: [][:0]u8) !Self {
            var _self = Self{
                .len = 0,
                .head = null,
                .tail = null,
                .allocator = _allocator,
            };

            try _self.insert(0, slice[0]);

            for (1..slice.len) |i| {
                try _self.append(slice[i]);
            }

            _self.len = slice.len;

            return _self;
        }

        pub fn read(self: *Self, index: usize) anyerror!T {
            if (index >= self.len) {
                try stdout.print("LinkedList error: tried to read index {d} in a list of length {d}\n", .{index, self.len});
                return error.OutOfBounds;
            }

            var current = self.head;
            for (0..index) |i| {
                if (current) |node| {
                    current = node.next;
                } else {
                    try stdout.print("LinkedList error: the len attribute is set to {d}, but the element at index {d} is set to null.\n", .{index, i});
                    return error.OutOfBounds;
                }
            }

            return current.?.value;
        }

        // TODO: Is there a way to format the print based on the type T of node.value?
        pub fn print(self: *Self) anyerror!void {

            try stdout.print("List length: {}\n", .{self.len});

            var current = self.head;

            if (current) |head| {
                try stdout.print("{s} ", .{head.value});
                current = head.next;

                while (current) |node| {
                    try stdout.print("<-> {s} ", .{node.value});
                    current = node.next;
                }
            } else {
                try stdout.print("LinkedList is empty\n", .{});
            }

            try stdout.print("\n", .{});
        }

        pub fn write(self: *Self, index: usize, comptime value: T) anyerror!void {
            if (index >= self.len) {
                try stdout.print("LinkedList error: tried to write index {d} in a list of length {d}\n", .{index, self.len});
                return error.OutOfBounds;
            }

            var current = self.head;
            for (0..index) |node| {
                if (node) |_| {
                    current = current.next;
                } else {
                    return error.OutOfBounds;
                }
            }

            current.value = value;
            return;
        }
        
        // TODO: also provide the version that can directly take the pointer to the element, so that the needless walk is avoided
        pub fn remove(self: *Self, index: usize) !void {
            if (index >= self.len) {
                try stdout.print("LinkedList error: tried to remove index {d} in a list of length {d}\n", .{index, self.len});
                return error.OutOfBounds;
            }

            // Walk to requested element
            var current = self.head;
            for (0..index) |_| {
                if (current) |node| {
                    current = node.next;
                } else {
                    return error.OutOfBounds; // TODO: actually, provide a better error
                }
            }

            // Perform unlinking
            if (current) |elem| {

                if (elem.next) |next| {
                    next.prev = elem.prev;
                }

                if (elem.prev) |prev| {
                    prev.next = elem.next;                
                }

                self.len -= 1;
            }
            // TODO: optionally, free the element.
        }

        // Inserts an element at a certain index
        // TODO: insert() is actually behaving like a write()
        pub fn insert(self: *Self, index: usize, value: T) !void {            
            if (self.len > 0 and index >= self.len) {
                try stdout.print("LinkedList error: tried to remove index {d} in a list of length {d}\n", .{index, self.len});
                return error.OutOfBounds;
            }

            // Create the node to insert
            var node = try self.allocator.create(Node(T));
            node.* = .{
                .value = value,
                .prev = null,
                .next = null,
            };

            // Perform the walk...
            var current = self.head;
            for (0..index) |_| {
                if (current) |curr| {
                    current = curr.next;
                } else {
                    return error.OutOfBounds; // TODO: actually, provide a better error
                }
            }

            if (current) |elem| {

                // Perform insertion
                if (elem.next) |next| {
                    next.prev = node;
                    node.next = next;
                }

                if (elem.prev) |prev| {
                    prev.next = node;
                    node.prev = prev;
                }
            }
            
            if (index == 0) self.head = node;
            if (index == self.len) self.tail = node;

            self.len += 1;
        }

        pub fn append(self: *Self, value: T) !void {
            // TODO: controllare se la tail è null; altrimenti, la devo allocare!
            const node = try self.allocator.create(Node(T));
            node.* = .{
                .value = value,
                .prev = self.tail,
                .next = null,
            };

            if (self.tail) |tail_node| {
                tail_node.next = node;
            } else {
                self.head = node;
            }

            self.tail = node;
            self.len += 1;
        }

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
