// WASM entry point for mquickjs
// Exports functions for JavaScript interaction

const std = @import("std");

// Declare external C types and functions from mquickjs
const JSContext = opaque {};
const JSValue = u32; // For WASM32, JSValue is uint32_t
const JSSTDLibraryDef = opaque {};
const JSCStringBuf = extern struct {
    buf: [5]u8,
};

// JS value constants (from mquickjs.h)
// JS_TAG_SPECIAL = 3, JS_TAG_SPECIAL_BITS = 5
// JS_EXCEPTION = JS_VALUE_MAKE_SPECIAL(JS_TAG_EXCEPTION, 0) = 15 | (0 << 5) = 15
// JS_UNDEFINED = JS_VALUE_MAKE_SPECIAL(JS_TAG_UNDEFINED, 0) = 11 | (0 << 5) = 11
const JS_EXCEPTION: JSValue = 15;
const JS_UNDEFINED: JSValue = 11;

fn JS_IsException(val: JSValue) bool {
    return val == JS_EXCEPTION;
}

fn JS_IsUndefined(val: JSValue) bool {
    return val == JS_UNDEFINED;
}

// External C functions from mquickjs.c
extern fn JS_NewContext(mem_start: *anyopaque, mem_size: usize, stdlib_def: ?*const JSSTDLibraryDef) ?*JSContext;
extern fn JS_FreeContext(ctx: *JSContext) void;
extern fn JS_Eval(ctx: *JSContext, input: [*]const u8, input_len: usize, filename: [*:0]const u8, eval_flags: c_int) JSValue;
extern fn JS_GetException(ctx: *JSContext) JSValue;
extern fn JS_ToCStringLen(ctx: *JSContext, plen: *usize, val: JSValue, buf: *JSCStringBuf) ?[*:0]const u8;
extern fn JS_GetGlobalObject(ctx: *JSContext) JSValue;
extern fn JS_GC(ctx: *JSContext) void;
extern fn JS_ToString(ctx: *JSContext, val: JSValue) JSValue;

// Extern stdlib definition (from generated wasm_stdlib.h, linked in C)
extern const js_stdlib: JSSTDLibraryDef;

// Export libc functions that the C code needs
export fn strlen(s: [*:0]const u8) usize {
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {}
    return i;
}

export fn memcpy(dest: [*]u8, src: [*]const u8, n: usize) [*]u8 {
    @memcpy(dest[0..n], src[0..n]);
    return dest;
}

export fn memmove(dest: [*]u8, src: [*]const u8, n: usize) [*]u8 {
    if (@intFromPtr(dest) < @intFromPtr(src)) {
        @memcpy(dest[0..n], src[0..n]);
    } else {
        var i: usize = n;
        while (i > 0) {
            i -= 1;
            dest[i] = src[i];
        }
    }
    return dest;
}

export fn memset(dest: [*]u8, val: c_int, n: usize) [*]u8 {
    @memset(dest[0..n], @intCast(val));
    return dest;
}

export fn memcmp(s1: [*]const u8, s2: [*]const u8, n: usize) c_int {
    for (0..n) |i| {
        if (s1[i] != s2[i]) {
            return @as(c_int, s1[i]) - @as(c_int, s2[i]);
        }
    }
    return 0;
}

export fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) c_int {
    var i: usize = 0;
    while (s1[i] != 0 and s1[i] == s2[i]) : (i += 1) {}
    return @as(c_int, s1[i]) - @as(c_int, s2[i]);
}

export fn strncmp(s1: [*]const u8, s2: [*]const u8, n: usize) c_int {
    for (0..n) |i| {
        if (s1[i] != s2[i] or s1[i] == 0) {
            return @as(c_int, s1[i]) - @as(c_int, s2[i]);
        }
    }
    return 0;
}

export fn strcpy(dest: [*]u8, src: [*:0]const u8) [*]u8 {
    var i: usize = 0;
    while (src[i] != 0) : (i += 1) {
        dest[i] = src[i];
    }
    dest[i] = 0;
    return dest;
}

export fn strncpy(dest: [*]u8, src: [*]const u8, n: usize) [*]u8 {
    var i: usize = 0;
    while (i < n and src[i] != 0) : (i += 1) {
        dest[i] = src[i];
    }
    while (i < n) : (i += 1) {
        dest[i] = 0;
    }
    return dest;
}

export fn strcat(dest: [*:0]u8, src: [*:0]const u8) [*]u8 {
    var i: usize = 0;
    while (dest[i] != 0) : (i += 1) {}
    var j: usize = 0;
    while (src[j] != 0) : (j += 1) {
        dest[i + j] = src[j];
    }
    dest[i + j] = 0;
    return dest;
}

export fn strchr(s: [*:0]const u8, ch: c_int) ?[*]const u8 {
    var i: usize = 0;
    while (true) : (i += 1) {
        if (s[i] == @as(u8, @intCast(ch))) {
            return s + i;
        }
        if (s[i] == 0) {
            if (ch == 0) return s + i;
            return null;
        }
    }
}

export fn abs(x: c_int) c_int {
    return if (x < 0) -x else x;
}

// setjmp/longjmp stubs - mquickjs includes setjmp.h but doesn't actually use it
const JmpBuf = [16]c_int;

export fn setjmp(env: *JmpBuf) c_int {
    _ = env;
    return 0;
}

export fn longjmp(env: *JmpBuf, val: c_int) noreturn {
    _ = env;
    _ = val;
    @trap();
}

// IEEE 754 double manipulation for math helpers
fn floatBits(x: f64) u64 {
    return @bitCast(x);
}

fn bitsToFloat(bits: u64) f64 {
    return @bitCast(bits);
}

export fn isnan(x: f64) c_int {
    const bits = floatBits(x);
    const exp: u64 = (bits >> 52) & 0x7FF;
    const mantissa = bits & 0xFFFFFFFFFFFFF;
    return if (exp == 0x7FF and mantissa != 0) 1 else 0;
}

export fn isinf(x: f64) c_int {
    const bits = floatBits(x);
    const exp: u64 = (bits >> 52) & 0x7FF;
    const mantissa = bits & 0xFFFFFFFFFFFFF;
    return if (exp == 0x7FF and mantissa == 0) 1 else 0;
}

export fn isfinite(x: f64) c_int {
    const bits = floatBits(x);
    const exp: u64 = (bits >> 52) & 0x7FF;
    return if (exp != 0x7FF) 1 else 0;
}

export fn ldexp(x: f64, exp_val: c_int) f64 {
    if (exp_val == 0 or x == 0.0 or isnan(x) != 0 or isinf(x) != 0) {
        return x;
    }

    var bits = floatBits(x);
    const old_exp: i32 = @intCast((bits >> 52) & 0x7FF);
    const new_exp = old_exp + exp_val;

    if (new_exp <= 0) {
        return 0.0;
    }
    if (new_exp >= 0x7FF) {
        return if ((bits >> 63) != 0) -std.math.inf(f64) else std.math.inf(f64);
    }

    bits = (bits & ~(@as(u64, 0x7FF) << 52)) | (@as(u64, @intCast(new_exp)) << 52);
    return bitsToFloat(bits);
}

export fn frexp(x: f64, exp_ptr: *c_int) f64 {
    if (x == 0.0) {
        exp_ptr.* = 0;
        return 0.0;
    }

    if (isnan(x) != 0 or isinf(x) != 0) {
        exp_ptr.* = 0;
        return x;
    }

    var bits = floatBits(x);
    const e: i32 = @intCast(((bits >> 52) & 0x7FF) - 1022);
    exp_ptr.* = e;

    bits = (bits & ~(@as(u64, 0x7FF) << 52)) | (0x3FE << 52);
    return bitsToFloat(bits);
}

export fn scalbn(x: f64, n: c_int) f64 {
    return ldexp(x, n);
}

export fn fabs(x: f64) f64 {
    var bits = floatBits(x);
    bits &= ~(@as(u64, 1) << 63);
    return bitsToFloat(bits);
}

export fn copysign(x: f64, y: f64) f64 {
    const x_bits = floatBits(x);
    const y_bits = floatBits(y);
    const result = (x_bits & ~(@as(u64, 1) << 63)) | (y_bits & (@as(u64, 1) << 63));
    return bitsToFloat(result);
}

// Global context pointer and memory
var js_memory: [65536]u8 align(8) = undefined;
var js_ctx: ?*JSContext = null;

// WASM Exports for JS API

/// Initialize the JS context with the given memory size
export fn mqjs_init(mem_size: u32) i32 {
    const size = if (mem_size == 0) 65536 else @min(mem_size, js_memory.len);
    js_ctx = JS_NewContext(&js_memory, size, &js_stdlib);
    return if (js_ctx != null) 0 else -1;
}

/// Evaluate JavaScript code and return result as i32
/// Returns the result value (for ints) or 0 on error
export fn mqjs_eval(code_ptr: [*]const u8, code_len: u32) i32 {
    const ctx = js_ctx orelse return -1;

    const result = JS_Eval(
        ctx,
        code_ptr,
        code_len,
        "eval",
        1, // JS_EVAL_RETVAL flag
    );

    if (JS_IsException(result)) {
        return -1;
    }

    // For simple integer results, we can return the value directly
    // (shifted right by 1 for JS_TAG_INT encoding)
    return @intCast(result >> 1);
}

/// Get the last exception message
export fn mqjs_get_exception(len_out: *u32) ?[*]const u8 {
    const ctx = js_ctx orelse return null;

    const exc = JS_GetException(ctx);
    if (JS_IsUndefined(exc)) {
        return null;
    }

    // Convert to string
    const str_val = JS_ToString(ctx, exc);
    if (JS_IsException(str_val)) {
        return null;
    }

    var buf: JSCStringBuf = undefined;
    var str_len: usize = 0;
    const str = JS_ToCStringLen(ctx, &str_len, str_val, &buf);
    if (str == null) {
        return null;
    }

    len_out.* = @intCast(str_len);
    return @ptrCast(str);
}

/// Run garbage collection
export fn mqjs_gc() void {
    if (js_ctx) |ctx| {
        JS_GC(ctx);
    }
}

/// Free the JS context
export fn mqjs_free() void {
    if (js_ctx) |ctx| {
        JS_FreeContext(ctx);
        js_ctx = null;
    }
}

/// Get WASM memory base for direct access
export fn mqjs_memory_base() [*]u8 {
    return &js_memory;
}

/// Get allocated memory size
export fn mqjs_memory_size() u32 {
    return js_memory.len;
}
