# DEV_NOTES.md - Capy Zig 0.16-dev Migration

## 2026-03-05 - Initial Analysis

### Zig Version
- From: 0.15.2
- To: 0.16.0-dev.2676+4e2cec265

### Major Breaking Changes Identified

1. **`std.fs.cwd()` removed** -> `std.Io.Dir.cwd()`
   - All Dir methods (openFile, createFile, openDir, access, makePath, etc.) now require an `Io` parameter
   - All File methods (close, read, write) now require an `Io` parameter
   - In build.zig context, `Io` is available via `b.graph.io`
   - In runtime code, need `std.Io.Threaded` or similar

2. **`std.Thread.Mutex` removed** -> `std.Io.Mutex`
   - `lock()` and `unlock()` now require an `Io` parameter
   - `std.Thread.RwLock` likely moved to `std.Io.RwLock`

3. **`std.Thread.sleep` removed** -> `std.Io` sleep / `Clock.Duration.sleep`

4. **`std.Thread.Futex` likely moved** to `std.Io`

5. **`std.ArrayListUnmanaged` deprecated** -> just use `std.ArrayList` (they merged)

6. **`std.fs.File` moved** -> `std.Io.File`

7. **`std.fs.path` deprecated** -> `std.Io.Dir.path`

8. **Version check in build_capy.zig** hardcodes 0.15.2

9. **`std.net` / `std.http` may have changed** - need to check

### Files Needing Changes (Capy source, not zig-pkg/)
- build.zig (3 occurrences of std.fs.cwd())
- build_capy.zig (1 occurrence + version check + std.http.Server + std.net)
- src/image.zig (1 occurrence)
- src/state_logger.zig (1 occurrence + std.fs.File refs)
- src/assets.zig (std.fs.File, std.fs.path)
- src/data.zig (std.Thread.Mutex, std.Thread.RwLock)
- src/capy.zig (std.BoundedArray)
- src/audio.zig (std.Thread.Mutex)
- src/dev_tools.zig (std.Thread, std.net)
- src/internal.zig (std.Thread.Mutex implicit via allocator)
- src/containers.zig
- src/backend.zig (std.Thread.sleep)
- src/backends/android/backend.zig (std.Thread.*)
- src/backends/gtk/ImageData.zig (std.Thread.Mutex)
- src/backends/gtk/Window.zig (std.fs.cwd())
- android/ directory (many std.fs.cwd() occurrences)
- examples/hacker-news.zig (std.http.Client)
- examples/dev-tools.zig (std.net)

### Migration Strategy
1. Fix build.zig and build_capy.zig first (unblocks compilation)
2. Fix core src/ files
3. Fix backend files
4. Fix examples
5. Test build

## 2026-03-05 - Migration Completed

### Build System (build.zig, build_capy.zig)
- `std.fs.cwd()` → `std.Io.Dir.cwd()` with `b.graph.io`
- `lib.linkLibC()` → `lib.root_module.link_libc = true`
- `addCSourceFile` moved from `Compile` to `Module`
- Version check updated to require 0.16.x
- WebServerStep stubbed (std.http.Server API changed too much)

### `@Type` Builtin Removed → Specific Builtins
- `@Type(.{ .int = ... })` → `@Int(.signedness, bits)`
- `@Type(.{ .@"struct" = ... })` → `@Struct(layout, backing_int, field_names, field_types, field_attrs)`
- `@Type(.EnumLiteral)` → `@EnumLiteral()`
- `@Struct` requires `*const [N]T` arrays, not `[]const T` slices
- Files fixed: vendor/zigwin32/zig.zig, src/internal.zig, src/backends/wasm/backend.zig, zig-pkg/zigimg/.../color.zig

### std.Thread.Mutex/RwLock → std.Io.Mutex/RwLock
- Now require `Io` parameter for lock/unlock
- Created `internal.io = std.Options.debug_io` as global Io handle
- src/data.zig: created local Mutex/RwLock compat wrappers using global io
- src/audio.zig, src/state_logger.zig, src/backends/gtk/ImageData.zig, src/backends/android/backend.zig: use `lockUncancelable(io)`/`unlock(io)` directly
- examples/hacker-news.zig: same pattern

### std.time.Instant Removed → std.Io.Timestamp
- Created local `Instant` compat struct in src/data.zig and src/timer.zig
- Uses `std.Io.Timestamp.now(io, .awake)` for monotonic clock
- `since()` uses `durationTo()` on timestamps

### std.time.milliTimestamp/timestamp Removed
- Replaced with `std.Io.Timestamp.now(io, .real).toMilliseconds()` / `.toSeconds()`
- Files: examples/300-buttons.zig, balls.zig, colors.zig, graph.zig, time-feed.zig

### std.Thread.sleep Removed → std.Io.sleep
- `std.Thread.sleep(ns)` → `std.Io.sleep(io, Duration.fromMilliseconds(ms), .awake)`
- Files: src/backend.zig, examples/balls.zig

### std.fs.File → std.Io.File
- src/state_logger.zig: rewritten to use std.Io.File
- src/assets.zig: rewritten to use std.Io.File/Dir
- src/image.zig: `std.Io.Dir.cwd().openFile(io, ...)`

### std.io.fixedBufferStream Removed
- Replaced with `std.fmt.bufPrint` in src/internal.zig

### std.process API Changes
- `std.process.getEnvVarOwned` → `std.process.Environ{ .block = .{ .use_global = true } }.getAlloc(allocator, key)`
- `std.process.hasEnvVar` → `environ.contains(allocator, key)`
- Files: src/state_logger.zig, src/window.zig

### std.os.windows Types Removed
- WPARAM, LRESULT, RECT no longer in std.os.windows
- Sourced from zigwin32.everything instead
- File: src/backends/win32/win32.zig

### std.net → std.Io.net
- `std.net.Address.parseIp` → `std.Io.net.IpAddress.parse`
- `addr.listen(...)` → `addr.listen(io, ...)`
- `server.accept()` → `server.accept(io)`
- `server.deinit()` → `server.deinit(io)`
- File: src/dev_tools.zig

### std.http.Client
- Now requires `io` field in initializer
- File: examples/hacker-news.zig

### std.BoundedArray Removed
- Added local BoundedArray compat type in src/capy.zig (same as in containers.zig)

### `|_|` Capture Discard
- `|_|` is no longer valid in Zig 0.16; omit the capture instead
- File: vendor/zigwin32/zig.zig

### Dead Code (typedConst2_0_13)
- Replaced body with `@compileError` since it used old Zig 0.13 API
- File: vendor/zigwin32/zig.zig

### Result
- **All 55 build steps compile successfully with zero errors**
- Zig version: 0.16.0-dev.2676+4e2cec265
