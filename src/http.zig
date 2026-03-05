//! Module to handle HTTP(S) requests
//!
//! The module was created because it is a very common operation that's not done the same on every devices
//! (For example, on the Web, you can't make TCP sockets, so std.http won't work)
const std = @import("std");
const internal = @import("internal.zig");
const backend = @import("backend.zig");

// TODO: specify more
pub const SendRequestError = anyerror;

pub const HttpRequest = if (backend.Http != void) struct {
    const Self = @This();
    url: []const u8,

    pub fn get(url: []const u8) Self {
        return Self{ .url = url };
    }

    pub fn send(self: Self) !HttpResponse {
        return HttpResponse{ .peer = backend.Http.send(self.url) };
    }
} else struct {
    const Self = @This();
    url: []const u8,

    pub fn get(url: []const u8) Self {
        return Self{ .url = url };
    }

    pub fn send(self: Self) !HttpResponse {
        // Use full IO (not ioBasic) because ioBasic disables networking
        const net_io = std.Io.Threaded.global_single_threaded.io();
        var client: std.http.Client = .{ .allocator = internal.allocator, .io = net_io };
        defer client.deinit();

        var aw: std.Io.Writer.Allocating = .init(internal.allocator);
        errdefer aw.deinit();

        const result = try client.fetch(.{
            .location = .{ .url = self.url },
            .response_writer = &aw.writer,
        });

        if (result.status != .ok) {
            aw.deinit();
            return error.HttpRequestFailed;
        }

        const body = aw.writer.buffer[0..aw.writer.end];
        const owned = try internal.allocator.dupe(u8, body);
        aw.deinit();

        return HttpResponse{ .body = owned };
    }
};

pub const HttpResponse = if (backend.Http != void) struct {
    const Self = @This();
    peer: backend.HttpResponse,

    pub const ReadError = error{};

    pub fn isReady(self: *Self) bool {
        return self.peer.isReady();
    }

    pub fn checkError(self: *Self) !void {
        _ = self;
    }

    pub fn read(self: *Self, dest: []u8) ReadError!usize {
        return self.peer.read(dest);
    }

    pub fn readAllAlloc(self: *Self, alloc: std.mem.Allocator, max_size: usize) ![]u8 {
        _ = max_size;
        var result = std.ArrayList(u8).empty;
        var buf: [4096]u8 = undefined;
        while (true) {
            const n = try self.read(&buf);
            if (n == 0) break;
            try result.appendSlice(alloc, buf[0..n]);
        }
        return result.toOwnedSlice(alloc);
    }

    pub fn deinit(self: *Self) void {
        _ = self;
    }
} else struct {
    const Self = @This();
    body: []u8,
    read_pos: usize = 0,

    pub const ReadError = error{};

    pub fn isReady(_: *Self) bool {
        return true;
    }

    pub fn checkError(_: *Self) !void {}

    pub fn read(self: *Self, dest: []u8) ReadError!usize {
        const remaining = self.body[self.read_pos..];
        const n = @min(dest.len, remaining.len);
        @memcpy(dest[0..n], remaining[0..n]);
        self.read_pos += n;
        return n;
    }

    pub fn readAllAlloc(self: *Self, alloc: std.mem.Allocator, _: usize) ![]u8 {
        return try alloc.dupe(u8, self.body);
    }

    pub fn deinit(self: *Self) void {
        internal.allocator.free(self.body);
    }
};
