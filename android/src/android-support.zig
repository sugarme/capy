const std = @import("std");
const builtin = @import("builtin");

const c = @import("c.zig")._c;

const android = @import("android-bind.zig");
const build_options = @import("build_options");

pub const egl = @import("egl.zig");
pub const JNI = @import("jni.zig").JNI;
pub const audio = @import("audio.zig");
pub const NativeActivity = @import("NativeActivity.zig");
pub const NativeInvocationHandler = @import("NativeInvocationHandler.zig");

const app_log = std.log.scoped(.app_glue);

// Re-export android-bind.zig declarations used by consumers of this module.
// (pub usingnamespace was removed in Zig 0.16)
//
// JNI types
pub const JNIEnv = android.JNIEnv;
pub const JNINativeInterface = android.JNINativeInterface;
pub const JNINativeMethod = android.JNINativeMethod;
pub const JNI_TRUE = android.JNI_TRUE;
pub const JNI_VERSION_1_6 = android.JNI_VERSION_1_6;
pub const jobject = android.jobject;
pub const jobjectArray = android.jobjectArray;
pub const jclass = android.jclass;
pub const jfieldID = android.jfieldID;
pub const jfloat = android.jfloat;
pub const jint = android.jint;
pub const jlong = android.jlong;
pub const jmethodID = android.jmethodID;
pub const jstring = android.jstring;
pub const jvalue = android.jvalue;
// Native Activity
pub const ANativeActivity = android.ANativeActivity;
pub const ANativeActivityCallbacks = android.ANativeActivityCallbacks;
pub const ANativeActivity_createFunc = android.ANativeActivity_createFunc;
pub const ANativeWindow = android.ANativeWindow;
pub const ANativeWindow_getWidth = android.ANativeWindow_getWidth;
pub const ANativeWindow_getHeight = android.ANativeWindow_getHeight;
// Input
pub const AInputEvent = android.AInputEvent;
pub const AInputEventType = android.AInputEventType;
pub const AInputEvent_getType = android.AInputEvent_getType;
pub const AInputQueue = android.AInputQueue;
pub const AInputQueue_getEvent = android.AInputQueue_getEvent;
pub const AInputQueue_preDispatchEvent = android.AInputQueue_preDispatchEvent;
pub const AInputQueue_finishEvent = android.AInputQueue_finishEvent;
pub const AKEY_EVENT_ACTION_DOWN = android.AKEY_EVENT_ACTION_DOWN;
pub const AKeyEventActionType = android.AKeyEventActionType;
pub const AKeyEvent_getAction = android.AKeyEvent_getAction;
pub const AKeyEvent_getDownTime = android.AKeyEvent_getDownTime;
pub const AKeyEvent_getEventTime = android.AKeyEvent_getEventTime;
pub const AKeyEvent_getFlags = android.AKeyEvent_getFlags;
pub const AKeyEvent_getKeyCode = android.AKeyEvent_getKeyCode;
pub const AKeyEvent_getMetaState = android.AKeyEvent_getMetaState;
pub const AKeyEvent_getRepeatCount = android.AKeyEvent_getRepeatCount;
pub const AKeyEvent_getScanCode = android.AKeyEvent_getScanCode;
pub const AMotionEventActionType = android.AMotionEventActionType;
pub const AMotionEvent_getAction = android.AMotionEvent_getAction;
pub const AMotionEvent_getButtonState = android.AMotionEvent_getButtonState;
pub const AMotionEvent_getDownTime = android.AMotionEvent_getDownTime;
pub const AMotionEvent_getEdgeFlags = android.AMotionEvent_getEdgeFlags;
pub const AMotionEvent_getEventTime = android.AMotionEvent_getEventTime;
pub const AMotionEvent_getFlags = android.AMotionEvent_getFlags;
pub const AMotionEvent_getMetaState = android.AMotionEvent_getMetaState;
pub const AMotionEvent_getOrientation = android.AMotionEvent_getOrientation;
pub const AMotionEvent_getPointerCount = android.AMotionEvent_getPointerCount;
pub const AMotionEvent_getPointerId = android.AMotionEvent_getPointerId;
pub const AMotionEvent_getPressure = android.AMotionEvent_getPressure;
pub const AMotionEvent_getRawX = android.AMotionEvent_getRawX;
pub const AMotionEvent_getRawY = android.AMotionEvent_getRawY;
pub const AMotionEvent_getSize = android.AMotionEvent_getSize;
pub const AMotionEvent_getToolMajor = android.AMotionEvent_getToolMajor;
pub const AMotionEvent_getToolMinor = android.AMotionEvent_getToolMinor;
pub const AMotionEvent_getToolType = android.AMotionEvent_getToolType;
pub const AMotionEvent_getTouchMajor = android.AMotionEvent_getTouchMajor;
pub const AMotionEvent_getTouchMinor = android.AMotionEvent_getTouchMinor;
pub const AMotionEvent_getX = android.AMotionEvent_getX;
pub const AMotionEvent_getXOffset = android.AMotionEvent_getXOffset;
pub const AMotionEvent_getXPrecision = android.AMotionEvent_getXPrecision;
pub const AMotionEvent_getY = android.AMotionEvent_getY;
pub const AMotionEvent_getYOffset = android.AMotionEvent_getYOffset;
pub const AMotionEvent_getYPrecision = android.AMotionEvent_getYPrecision;
// Looper
pub const ALooper = android.ALooper;
pub const ALooper_acquire = android.ALooper_acquire;
pub const ALooper_addFd = android.ALooper_addFd;
pub const ALooper_forThread = android.ALooper_forThread;
pub const ALooper_release = android.ALooper_release;
pub const ALOOPER_EVENT_INPUT = android.ALOOPER_EVENT_INPUT;
// Configuration
pub const AConfiguration = android.AConfiguration;
pub const AConfiguration_delete = android.AConfiguration_delete;
pub const AConfiguration_fromAssetManager = android.AConfiguration_fromAssetManager;
pub const AConfiguration_getCountry = android.AConfiguration_getCountry;
pub const AConfiguration_getDensity = android.AConfiguration_getDensity;
pub const AConfiguration_getKeyboard = android.AConfiguration_getKeyboard;
pub const AConfiguration_getKeysHidden = android.AConfiguration_getKeysHidden;
pub const AConfiguration_getLanguage = android.AConfiguration_getLanguage;
pub const AConfiguration_getMcc = android.AConfiguration_getMcc;
pub const AConfiguration_getMnc = android.AConfiguration_getMnc;
pub const AConfiguration_getNavHidden = android.AConfiguration_getNavHidden;
pub const AConfiguration_getNavigation = android.AConfiguration_getNavigation;
pub const AConfiguration_getOrientation = android.AConfiguration_getOrientation;
pub const AConfiguration_getScreenLong = android.AConfiguration_getScreenLong;
pub const AConfiguration_getScreenSize = android.AConfiguration_getScreenSize;
pub const AConfiguration_getSdkVersion = android.AConfiguration_getSdkVersion;
pub const AConfiguration_getTouchscreen = android.AConfiguration_getTouchscreen;
pub const AConfiguration_getUiModeNight = android.AConfiguration_getUiModeNight;
pub const AConfiguration_getUiModeType = android.AConfiguration_getUiModeType;
pub const AConfiguration_new = android.AConfiguration_new;
// Logging
pub const ANDROID_LOG_DEBUG = android.ANDROID_LOG_DEBUG;
pub const ANDROID_LOG_ERROR = android.ANDROID_LOG_ERROR;
pub const ANDROID_LOG_INFO = android.ANDROID_LOG_INFO;
pub const ANDROID_LOG_WARN = android.ANDROID_LOG_WARN;
// System
pub const __system_property_get = android.__system_property_get;
pub const __android_log_write = android.__android_log_write;
pub const ARect = android.ARect;

const AndroidApp = @import("root").AndroidApp;

pub var sdk_version: c_int = 0;

/// Actual application entry point
export fn ANativeActivity_onCreate(activity: *android.ANativeActivity, savedState: ?[*]u8, savedStateSize: usize) callconv(.C) void {
    {
        var sdk_ver_str: [92]u8 = undefined;
        const len = android.__system_property_get("ro.build.version.sdk", &sdk_ver_str);
        if (len <= 0) {
            sdk_version = 0;
        } else {
            const str = sdk_ver_str[0..@as(usize, @intCast(len))];
            sdk_version = std.fmt.parseInt(c_int, str, 10) catch 0;
        }
    }

    app_log.debug(
        \\Zig Android SDK:
        \\  App:              {s}
        \\  API level:        target={d}, actual={d}
        \\  App pid:          {}
        \\  Build mode:       {s}
        \\  ABI:              {s}-{s}-{s}
        \\  Compiler version: {}
        \\  Compiler backend: {s}
    , .{
        build_options.app_name,
        build_options.android_sdk_version,
        sdk_version,
        std.os.linux.getpid(),
        @tagName(builtin.mode),
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
        @tagName(builtin.abi),
        builtin.zig_version,
        @tagName(builtin.zig_backend),
    });

    const app = std.heap.c_allocator.create(AndroidApp) catch {
        app_log.err("Could not create new AndroidApp: OutOfMemory!\n", .{});
        return;
    };

    activity.callbacks.* = makeNativeActivityGlue(AndroidApp);

    app.* = AndroidApp.init(
        std.heap.c_allocator,
        activity,
        if (savedState) |state|
            state[0..savedStateSize]
        else
            null,
    ) catch |err| {
        std.log.err("Failed to restore app state: {}\n", .{err});
        std.heap.c_allocator.destroy(app);
        return;
    };

    app.start() catch |err| {
        std.log.err("Failed to start app state: {}\n", .{err});
        app.deinit();
        std.heap.c_allocator.destroy(app);
        return;
    };

    activity.instance = app;

    app_log.debug("Successfully started the app.\n", .{});
}

// // Required by C code for now…
threadlocal var errno: c_int = 0;
export fn __errno_location() *c_int {
    return &errno;
}

var recursive_panic = false;

// Android Panic implementation
pub fn panic(message: []const u8, stack_trace: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    var logger = LogWriter{ .log_level = android.ANDROID_LOG_ERROR };

    if (@atomicLoad(bool, &recursive_panic, .SeqCst)) {
        logger.print("RECURSIVE PANIC: {s}\n", .{message});
        std.process.exit(1);
    }

    @atomicStore(bool, &recursive_panic, true, .SeqCst);

    logger.print("PANIC: {s}\n", .{message});

    // Stack trace iteration requires Io in Zig 0.16, which is not available in the panic handler.
    // The android log above will still show the panic message.
    _ = stack_trace;

    logger.writeAll("<-- end of panic -->\n");

    std.process.exit(1);
}

const LogWriter = struct {
    log_level: c_int,

    line_buffer: [8192]u8 = undefined,
    line_len: usize = 0,

    fn writeBytes(self: *LogWriter, buffer: []const u8) void {
        for (buffer) |char| {
            switch (char) {
                '\n' => {
                    self.flush();
                },
                else => {
                    if (self.line_len >= self.line_buffer.len - 1) {
                        self.flush();
                    }
                    self.line_buffer[self.line_len] = char;
                    self.line_len += 1;
                },
            }
        }
    }

    fn flush(self: *LogWriter) void {
        if (self.line_len > 0) {
            std.debug.assert(self.line_len < self.line_buffer.len - 1);
            self.line_buffer[self.line_len] = 0;
            _ = android.__android_log_write(
                self.log_level,
                build_options.app_name.ptr,
                &self.line_buffer,
            );
        }
        self.line_len = 0;
    }

    fn print(self: *LogWriter, comptime fmt: []const u8, args: anytype) void {
        var buf: [4096]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, fmt, args) catch {
            self.writeBytes("(fmt error)");
            return;
        };
        self.writeBytes(msg);
    }

    fn writeAll(self: *LogWriter, bytes: []const u8) void {
        self.writeBytes(bytes);
    }
};

pub const std_options = struct {

    // Android Logging implementation
    pub fn logFn(
        comptime message_level: std.log.Level,
        comptime scope: @Type(.EnumLiteral),
        comptime format: []const u8,
        args: anytype,
    ) void {
        const level = switch (message_level) {
            //  => .ANDROID_LOG_VERBOSE,
            .debug => android.ANDROID_LOG_DEBUG,
            .info => android.ANDROID_LOG_INFO,
            .warn => android.ANDROID_LOG_WARN,
            .err => android.ANDROID_LOG_ERROR,
        };

        var logger = LogWriter{
            .log_level = level,
        };
        defer logger.flush();

        logger.print("{s}: " ++ format, .{@tagName(scope)} ++ args);
    }
};

/// Returns a wrapper implementation for the given App type which implements all
/// ANativeActivity callbacks.
fn makeNativeActivityGlue(comptime App: type) android.ANativeActivityCallbacks {
    const T = struct {
        fn invoke(activity: *android.ANativeActivity, comptime func: []const u8, args: anytype) void {
            if (@hasDecl(App, func)) {
                if (activity.instance) |instance| {
                    const result = @call(.auto, @field(App, func), .{@as(*App, @ptrCast(@alignCast(@alignOf(App), instance)))} ++ args);
                    switch (@typeInfo(@TypeOf(result))) {
                        .ErrorUnion => result catch |err| app_log.err("{s} returned error {s}", .{ func, @errorName(err) }),
                        .Void => {},
                        .ErrorSet => app_log.err("{s} returned error {s}", .{ func, @errorName(result) }),
                        else => @compileError("callback must return void!"),
                    }
                }
            } else {
                app_log.debug("ANativeActivity callback {s} not available on {s}", .{ func, @typeName(App) });
            }
        }

        // return value must be created with malloc(), so we pass the c_allocator to App.onSaveInstanceState
        fn onSaveInstanceState(activity: *android.ANativeActivity, outSize: *usize) callconv(.C) ?[*]u8 {
            outSize.* = 0;
            if (@hasDecl(App, "onSaveInstanceState")) {
                if (activity.instance) |instance| {
                    const optional_slice = @as(*App, @ptrCast(@alignCast(@alignOf(App), instance))).onSaveInstanceState(std.heap.c_allocator);
                    if (optional_slice) |slice| {
                        outSize.* = slice.len;
                        return slice.ptr;
                    }
                }
            } else {
                app_log.debug("ANativeActivity callback onSaveInstanceState not available on {s}", .{@typeName(App)});
            }
            return null;
        }

        fn onDestroy(activity: *android.ANativeActivity) callconv(.C) void {
            if (activity.instance) |instance| {
                const app = @as(*App, @ptrCast(@alignCast(@alignOf(App), instance)));
                app.deinit();
                std.heap.c_allocator.destroy(app);
            }
        }
        fn onStart(activity: *android.ANativeActivity) callconv(.C) void {
            invoke(activity, "onStart", .{});
        }
        fn onResume(activity: *android.ANativeActivity) callconv(.C) void {
            invoke(activity, "onResume", .{});
        }
        fn onPause(activity: *android.ANativeActivity) callconv(.C) void {
            invoke(activity, "onPause", .{});
        }
        fn onStop(activity: *android.ANativeActivity) callconv(.C) void {
            invoke(activity, "onStop", .{});
        }
        fn onConfigurationChanged(activity: *android.ANativeActivity) callconv(.C) void {
            invoke(activity, "onConfigurationChanged", .{});
        }
        fn onLowMemory(activity: *android.ANativeActivity) callconv(.C) void {
            invoke(activity, "onLowMemory", .{});
        }
        fn onWindowFocusChanged(activity: *android.ANativeActivity, hasFocus: c_int) callconv(.C) void {
            invoke(activity, "onWindowFocusChanged", .{(hasFocus != 0)});
        }
        fn onNativeWindowCreated(activity: *android.ANativeActivity, window: *android.ANativeWindow) callconv(.C) void {
            invoke(activity, "onNativeWindowCreated", .{window});
        }
        fn onNativeWindowResized(activity: *android.ANativeActivity, window: *android.ANativeWindow) callconv(.C) void {
            invoke(activity, "onNativeWindowResized", .{window});
        }
        fn onNativeWindowRedrawNeeded(activity: *android.ANativeActivity, window: *android.ANativeWindow) callconv(.C) void {
            invoke(activity, "onNativeWindowRedrawNeeded", .{window});
        }
        fn onNativeWindowDestroyed(activity: *android.ANativeActivity, window: *android.ANativeWindow) callconv(.C) void {
            invoke(activity, "onNativeWindowDestroyed", .{window});
        }
        fn onInputQueueCreated(activity: *android.ANativeActivity, input_queue: *android.AInputQueue) callconv(.C) void {
            invoke(activity, "onInputQueueCreated", .{input_queue});
        }
        fn onInputQueueDestroyed(activity: *android.ANativeActivity, input_queue: *android.AInputQueue) callconv(.C) void {
            invoke(activity, "onInputQueueDestroyed", .{input_queue});
        }
        fn onContentRectChanged(activity: *android.ANativeActivity, rect: *const android.ARect) callconv(.C) void {
            invoke(activity, "onContentRectChanged", .{rect});
        }
    };
    return android.ANativeActivityCallbacks{
        .onStart = T.onStart,
        .onResume = T.onResume,
        .onSaveInstanceState = T.onSaveInstanceState,
        .onPause = T.onPause,
        .onStop = T.onStop,
        .onDestroy = T.onDestroy,
        .onWindowFocusChanged = T.onWindowFocusChanged,
        .onNativeWindowCreated = T.onNativeWindowCreated,
        .onNativeWindowResized = T.onNativeWindowResized,
        .onNativeWindowRedrawNeeded = T.onNativeWindowRedrawNeeded,
        .onNativeWindowDestroyed = T.onNativeWindowDestroyed,
        .onInputQueueCreated = T.onInputQueueCreated,
        .onInputQueueDestroyed = T.onInputQueueDestroyed,
        .onContentRectChanged = T.onContentRectChanged,
        .onConfigurationChanged = T.onConfigurationChanged,
        .onLowMemory = T.onLowMemory,
    };
}

// NOTE: printSymbolInfoAt, realFmtMaybeLineInfo, and fmtMaybeLineInfo were removed
// because they referenced std.debug.LineInfo and SelfInfo APIs that changed in Zig 0.16.
// The panic handler no longer uses stack trace iteration (it requires Io in 0.16),
// so these functions are no longer needed.
