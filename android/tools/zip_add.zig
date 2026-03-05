const std = @import("std");

const c = @cImport({
    @cInclude("zip.h");
});

const Error = error{
    FailedToCopyZip,
    FailedToWriteEntry,
    FileNotFound,
    FailedToCreateEntry,
    Overflow,
    OutOfMemory,
    InvalidCmdLine,
};

// zip_add file.zip local_path zip_path
pub fn main(init: std.process.Init) Error!u8 {
    const allocator = init.gpa;
    const io = init.io;

    // Collect args into a slice
    var args_list: std.ArrayList([]const u8) = .empty;
    var args_it = init.minimal.args.initAllocator(allocator) catch return error.OutOfMemory;
    defer args_it.deinit();
    while (args_it.next()) |arg| {
        args_list.append(allocator, arg) catch return error.OutOfMemory;
    }
    const args = args_list.items;

    if (args.len < 5)
        return 1;

    const zip_file = args[1];
    const out_file = args[2];
    const file_args = args[3..];

    if (file_args.len % 2 != 0)
        return error.InvalidCmdLine;

    // Create a copy of the zip file instead of modifying the old one
    {
        const cwd = std.Io.Dir.cwd();
        const old_base = std.fs.path.basename(zip_file);
        var old_dir = new_dir: {
            if (std.fs.path.dirname(zip_file)) |in_path| {
                break :new_dir cwd.openDir(io, in_path, .{}) catch return error.FailedToCopyZip;
            } else {
                break :new_dir cwd;
            }
        };
        defer if (old_dir.handle != cwd.handle) old_dir.close(io);
        const new_base = std.fs.path.basename(out_file);
        var new_dir = new_dir: {
            if (std.fs.path.dirname(out_file)) |out_path| {
                break :new_dir cwd.openDir(io, out_path, .{}) catch return error.FailedToCopyZip;
            } else {
                break :new_dir cwd;
            }
        };
        defer if (new_dir.handle != cwd.handle) new_dir.close(io);

        old_dir.copyFile(old_base, new_dir, new_base, io, .{}) catch return error.FailedToCopyZip;
    }

    const zip = c.zip_open(out_file.ptr, c.ZIP_DEFAULT_COMPRESSION_LEVEL, 'a') orelse return error.FileNotFound;
    defer c.zip_close(zip);

    var i: usize = 0;
    while (i < file_args.len) : (i += 2) {
        const src_file_name = file_args[i];
        const dst_file_name = file_args[i + 1];

        errdefer |e| switch (@as(Error, e)) {
            error.FailedToWriteEntry => std.log.err("could not find {s}", .{src_file_name}),
            error.FileNotFound => std.log.err("could not open {s}", .{out_file}),
            error.FailedToCreateEntry => std.log.err("could not create {s}", .{dst_file_name}),
            else => {},
        };

        if (c.zip_entry_open(zip, dst_file_name.ptr) < 0)
            return error.FailedToCreateEntry;
        defer _ = c.zip_entry_close(zip);

        if (c.zip_entry_fwrite(zip, src_file_name.ptr) < 0)
            return error.FailedToWriteEntry;
    }

    return 0;
}
