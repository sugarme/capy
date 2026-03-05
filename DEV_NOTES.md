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

## 2026-03-05 - Runtime Fixes (slide-viewer, D2D, memory leaks)

### std.fs.File in vendored zigimg → std.Io.File
- `std.fs.File` → `std.Io.File`, `std.fs.File.Reader` → `std.Io.File.Reader`, `std.fs.File.Writer` → `std.Io.File.Writer`
- `std.fs.File.SeekError` → `std.Io.File.SeekError`, `std.fs.File.Reader.SeekError` → `std.Io.File.Reader.SeekError`
- `initFile(file, buffer)` → `initFile(file, io, buffer)` (file.reader/writer now require `io` param)
- File: zig-pkg/zigimg-*/src/io.zig
- Caller updated: src/image.zig

### WINDOW_STYLE packed struct (not enum)
- `win32.WS_CAPTION`, `win32.WS_THICKFRAME`, `win32.WS_EX_*` are `packed struct(u32)`, not enums
- `@intFromEnum(win32.WS_CAPTION)` → `@as(u32, @bitCast(win32.WS_CAPTION))`
- File: src/backends/win32/backend.zig (fullscreen/unfullscreen)

### COM extern union value-copy bug (D2D segfault at address 0x10)
- In Zig 0.16, accessing a COM interface field on an `extern union` through a pointer
  (e.g. `render_target.ID2D1RenderTarget.FillEllipse(...)`) copies the union value to
  a stack temporary. The method auto-references this copy, passing a stack address as
  the COM `self`/`this` pointer instead of the real COM object pointer. The vtable
  dispatch succeeds (correct vtable ptr), but d2d1.dll crashes when accessing internal
  object state beyond offset 0 from the wrong `this`.
- Symptom: `Segmentation fault at address 0x10` inside d2d1.dll on any D2D draw call
  (FillRectangle, FillEllipse, etc.)
- Fix: use `@ptrCast` to reinterpret the derived COM pointer as the base interface
  pointer, preserving the original heap address:
  ```zig
  // BEFORE (broken in 0.16 — copies extern union value to stack):
  const rt = self.render_target.ID2D1RenderTarget;
  rt.FillRectangle(&rect, @ptrCast(self.brush));

  // AFTER (correct — reinterprets pointer, no copy):
  const rt: *win32.ID2D1RenderTarget = @ptrCast(self.render_target);
  rt.FillRectangle(&rect, @ptrCast(self.brush));
  ```
- Same fix applied to `.IUnknown.QueryInterface(...)` calls on render targets
- File: src/backends/win32/backend.zig (WM_PAINT handler, DrawContextImpl methods:
  fill, stroke, line, clear, text)

### Memory leak fixes
- **EventUserData leak** (src/backends/win32/backend.zig): EventUserData allocated per
  widget in `setupEvents` was never freed. Added `freeEventUserData` callback + WM_DESTROY
  handler that enumerates all child windows via `EnumChildWindows` and frees their
  EventUserData (covers standard Win32 controls like Label/Slider that don't use our
  wndproc). WM_NCDESTROY frees the current HWND's own EventUserData (for custom window
  classes). Also fixed WM_DESTROY to only call `PostQuitMessage` for the main Window type.
- **Monitor device_name leak** (src/backends/win32/Monitor.zig): `deinit()` freed
  `adapter_win32_name`, `win32_name`, and `internal_name` but not `device_name`. Added
  `free(self.device_name)`.
- **audio.zig mutex bug**: `deinit()` locked mutex but never unlocked — added
  `defer generatorsMutex.unlock(internal.io)`. `AudioGenerator.deinit()` did lock/unlock
  without protecting the `swapRemove` — moved critical section inside mutex scope.
- **media-player.zig**: Added `defer generator.deinit()` and `defer pitch.deinit()` to
  free AudioGenerator and Atom binding nodes on exit.

### Result
- **All 55 build steps compile successfully with zero errors**
- All D2D-using examples (slide-viewer, media-player, colors, graph, etc.) run without segfault
- media-player runs with zero memory leaks
- Zig version: 0.16.0-dev.2676+4e2cec265

## 2026-03-05 - Fix generators ArrayList backing memory leak

### Problem
- `generators` ArrayList in `src/audio.zig` (module-level `var generators: std.ArrayList(*AudioGenerator) = .empty`)
  backing buffer was never freed — the `append()` allocation was reported as leaked by DebugAllocator
- Root cause: `capy.deinit()` in `src/capy.zig` never called `audio.deinit()`, so the global
  `generators` ArrayList backing memory was never freed

### Fix
- Added `audio.deinit()` call in `capy.deinit()` (src/capy.zig line 251), between
  `timer.runningTimers.deinit()` and `eventStep.deinitAllListeners()`
- `audio.deinit()` already existed and correctly frees the generators ArrayList with
  `generators.deinit(internal.allocator)` — it just was never called

### Result
- media-player runs with zero memory leaks (confirmed via `zig build media-player`)

## 2026-03-05 - Implement std.http.Client for native HTTP (osm-viewer fix)

### Problem
- `src/http.zig` had a `@panic("std.http.Client support not yet ported to Zig 0.15.2")`
  in the native HTTP fallback (when `backend.Http` is void)
- osm-viewer crashed at runtime when trying to fetch map tiles

### Fix
- **src/http.zig**: Replaced `@panic` with working `std.http.Client` implementation
  - `HttpRequest.send()`: creates `std.http.Client` with network-capable IO, uses
    `client.fetch()` with `std.Io.Writer.Allocating` to collect response body,
    dupes body to owned slice
  - Must use `std.Io.Threaded.global_single_threaded.io()` (full IO) instead of
    `internal.io` (`ioBasic()`) — `ioBasic()` disables all networking (sets all
    net* vtable entries to `*Unavailable` stubs), causing `NetworkDown` errors
  - `HttpResponse`: stores owned `body: []u8` with `read_pos` tracking
    - `isReady()` → always true (synchronous fetch)
    - `read()` → reads from stored body with position tracking
    - `readAllAlloc()` → dupes stored body with caller's allocator
    - `deinit()` → frees owned body via `internal.allocator`
- **examples/osm-viewer.zig**:
  - `getTile()`: `catch unreachable` → `catch return null` (graceful tile load failure)
  - `search()`: `try request.send()` → `catch` with log (graceful search failure)

### Note
- HTTP requests are synchronous (block the UI thread) — the original design assumed async
  HTTP via backend peers. A future improvement would use threading for non-blocking requests.

## 2026-03-05 - Implement win32 DrawContext.image() via D2D

### Problem
- `DrawContextImpl.image()` in `src/backends/win32/backend.zig` was a no-op stub
  (`// ImageData.peer is void on win32 — no-op for now`)
- Any image drawing (osm-viewer tiles, Image widget, etc.) silently did nothing on Windows

### Fix
- Implemented `image()` using Direct2D:
  1. Convert RGBA pixel data (from `ImageData.data`) to BGRA (D2D's `B8G8R8A8_UNORM` format)
  2. Create a `ID2D1Bitmap` via `rt.CreateBitmap()` from the BGRA buffer
  3. Draw with `rt.DrawBitmap()` to the destination rectangle
  4. Release the bitmap via `IUnknown.Release()` (using `@ptrCast` for COM safety)
- Uses `PREMULTIPLIED` alpha mode at 96 DPI
- File: src/backends/win32/backend.zig

### Also fixed in osm-viewer
- `getTile()`: changed from async `pendingRequests` pipeline to synchronous fetch+decode+cache
  in one shot, since the HTTP layer is already synchronous
- `centerTo()`: fixed `targetCenterX` set twice (line 158), second should be `targetCenterY`
- `centerTo()`: also set `centerX`/`centerY` directly (not just animation targets) so the
  camera jumps immediately — prevents tiles being fetched for the old position
- `search()`: `try request.send()` → `catch` with log for graceful network error handling
