# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Capy is a cross-platform GUI library for Zig that uses native OS controls (Win32 on Windows, GTK 4 on Linux, AppKit on macOS, DOM on WASM, NDK on Android). It targets **Zig 0.15.2** exactly — the build will fail on any other version.

## Build Commands

```bash
# Build all examples and the shared library
zig build

# Run a specific example (example name = filename without .zig)
zig build calculator
zig build widget-catalog

# Run unit tests
zig build test --summary all

# Check formatting
zig fmt --check src examples

# Build for a specific target
zig build -Dtarget=x86_64-windows
zig build -Dtarget=x86-windows

# Generate documentation
zig build docs

# Build shared library (C ABI)
zig build shared
```

On Linux, GTK 4 dev headers are required: `sudo apt-get install libgtk-4-dev`

## Architecture

See `ARCHITECTURE.md` for the full guide. Key points:

**Layered design:** User code → `src/capy.zig` (public API) → `src/internal.zig` (widget trait system) + `src/containers.zig` (layout engine) + `src/data.zig` (reactive atoms) → `src/backend.zig` (compile-time OS dispatch) → platform backends.

**Backend selection** (`src/backend.zig`): Compile-time switch on `builtin.os.tag` selects from `src/backends/{win32,gtk,macos,wasm,android,gles}/backend.zig`. Not all backends support all widget types — optionality is handled with `@hasDecl` checks that fall back to `void`.

**Widget trait system** (`src/internal.zig`): `All(T)` combines `Widgeting(T)` and `Events(T)` into a struct of methods that each widget must explicitly re-export. Since Zig 0.15.2 removed `pub usingnamespace`, every widget in `src/components/` has an explicit list of `pub const foo = _all.foo;` lines. **If you add a new method to `All(T)`, you must add the corresponding re-export to every widget.**

**Reactive data** (`src/data.zig`): `Atom(T)` is a mutex-protected observable value with change listeners, bindings, and animation support. `ListAtom(T)` is an observable list. These contain custom `SinglyLinkedList` and `BoundedArray` reimplementations for Zig 0.15 compatibility.

**Layout** (`src/containers.zig`): Layout is computed by Capy, not native toolkits. Column, Row, Grid, Stack, Border layouts use callback-based `moveResize`/`getSize` for both real layout and preferred-size computation.

## Key Conventions

- Each cross-platform widget lives in `src/components/WidgetName.zig` with a corresponding lowercase constructor function (e.g., `Button` type + `button()` function)
- Backend implementations for widgets live in `src/backends/<platform>/WidgetName.zig`
- `src/capy.zig` re-exports everything that constitutes the public API
- Tests are inline `test` blocks in source files, using `std.testing.allocator` to detect memory leaks
- Examples are auto-discovered from `examples/` — just add a `.zig` file to create a new one (no build.zig edit needed)
- The `build_capy.zig` file contains the `runStep` function and build options used by both this repo and downstream consumers

## Broken Examples on Windows

The following examples are known-broken on Windows and excluded from the default build: `osm-viewer`, `fade`, `slide-viewer`, `demo`, `notepad`, `dev-tools`.
