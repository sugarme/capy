//! URI based system for retrieving assets
const std = @import("std");
const http = @import("http.zig");
const internal = @import("internal.zig");
const log = std.log.scoped(.assets);
const Uri = std.Uri;

const Dir = std.Io.Dir;
const File = std.Io.File;

const GetError = Uri.ParseError || http.SendRequestError || error{ UnsupportedScheme, InvalidPath } || std.mem.Allocator.Error;

pub const AssetHandle = struct {
    data: union(enum) {
        http: http.HttpResponse,
        file: File,
    },

    pub const ReadError = File.ReadStreamingError || http.HttpResponse.ReadError;

    pub fn read(self: *AssetHandle, dest: []u8) ReadError!usize {
        switch (self.data) {
            .http => |*resp| {
                return try resp.read(dest);
            },
            .file => |file| {
                return file.readStreaming(internal.io, &.{dest});
            },
        }
    }

    /// Read all contents into an allocated buffer
    pub fn readAllAlloc(self: *AssetHandle, alloc: std.mem.Allocator, max_size: usize) ![]u8 {
        _ = max_size;
        switch (self.data) {
            .file => {
                var result = std.ArrayList(u8).empty;
                var buf: [4096]u8 = undefined;
                while (true) {
                    const n = try self.read(&buf);
                    if (n == 0) break;
                    try result.appendSlice(alloc, buf[0..n]);
                }
                return result.toOwnedSlice(alloc);
            },
            .http => {
                var result = std.ArrayList(u8).empty;
                var buf: [4096]u8 = undefined;
                while (true) {
                    const n = try self.read(&buf);
                    if (n == 0) break;
                    try result.appendSlice(alloc, buf[0..n]);
                }
                return result.toOwnedSlice(alloc);
            },
        }
    }

    pub fn deinit(self: *AssetHandle) void {
        switch (self.data) {
            .http => |*resp| {
                resp.deinit();
            },
            .file => |file| {
                file.close(internal.io);
            },
        }
    }
};

pub fn get(url: []const u8) GetError!AssetHandle {
    // Normalize the URI for the file:// and asset:// scheme
    var out_url: [4096]u8 = undefined;
    const new_size = std.mem.replacementSize(u8, url, "///", "/");
    _ = std.mem.replace(u8, url, "///", "/", &out_url);

    const uri = try Uri.parse(out_url[0..new_size]);
    log.debug("Loading {s}", .{url});

    if (std.mem.eql(u8, uri.scheme, "asset")) {
        var raw_path_buf: [Dir.max_path_bytes]u8 = undefined;
        const raw_uri_path = uri.path.toRaw(&raw_path_buf) catch return error.InvalidPath;

        const asset_path = try std.fs.path.join(internal.allocator, &.{ "assets/", raw_uri_path });
        defer internal.allocator.free(asset_path);
        log.debug("-> {s}", .{asset_path});

        const file = Dir.cwd().openFile(internal.io, asset_path, .{ .mode = .read_only }) catch return error.InvalidPath;
        return AssetHandle{ .data = .{ .file = file } };
    } else if (std.mem.eql(u8, uri.scheme, "file")) {
        var raw_path_buf2: [Dir.max_path_bytes]u8 = undefined;
        const raw_uri_path = uri.path.toRaw(&raw_path_buf2) catch return error.InvalidPath;

        log.debug("-> {s}", .{raw_uri_path});
        const file = Dir.openFileAbsolute(internal.io, raw_uri_path, .{ .mode = .read_only }) catch return error.InvalidPath;
        return AssetHandle{ .data = .{ .file = file } };
    } else if (std.mem.eql(u8, uri.scheme, "http") or std.mem.eql(u8, uri.scheme, "https")) {
        const request = http.HttpRequest.get(url);
        var response = try request.send();

        while (!response.isReady()) {
            // TODO: suspend; when async is back
        }
        try response.checkError();

        return AssetHandle{ .data = .{ .http = response } };
    } else {
        return error.UnsupportedScheme;
    }
}

test "asset:// URI loads file from assets directory" {
    // internal.allocator defaults to std.testing.allocator in test mode
    var handle = try get("asset:///ziglogo.png");
    defer handle.deinit();
    const contents = try handle.readAllAlloc(std.testing.allocator, std.math.maxInt(usize));
    defer std.testing.allocator.free(contents);
    // PNG files start with the magic bytes 0x89 P N G
    try std.testing.expect(contents.len > 8);
    try std.testing.expectEqual(@as(u8, 0x89), contents[0]);
    try std.testing.expectEqual(@as(u8, 'P'), contents[1]);
    try std.testing.expectEqual(@as(u8, 'N'), contents[2]);
    try std.testing.expectEqual(@as(u8, 'G'), contents[3]);
}

test "triple-slash URI normalization" {
    // Verify that asset:///path normalizes correctly (the bug that caused SIGABRT)
    var out_url: [4096]u8 = undefined;
    const url = "asset:///ziglogo.png";
    const new_size = std.mem.replacementSize(u8, url, "///", "/");
    _ = std.mem.replace(u8, url, "///", "/", &out_url);
    const normalized = out_url[0..new_size];
    // After normalization, "asset:///ziglogo.png" -> "asset:/ziglogo.png"
    try std.testing.expectEqualStrings("asset:/ziglogo.png", normalized);
    // Verify it parses as a valid URI
    const parsed_uri = try Uri.parse(normalized);
    try std.testing.expectEqualStrings("asset", parsed_uri.scheme);
}

test "unsupported scheme returns error" {
    // internal.allocator defaults to std.testing.allocator in test mode
    const result = get("ftp://example.com/file.png");
    try std.testing.expectError(error.UnsupportedScheme, result);
}
