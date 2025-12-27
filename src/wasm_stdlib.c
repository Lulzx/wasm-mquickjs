// WASM stdlib wrapper - includes the generated stdlib table
// This provides the js_stdlib symbol that the Zig code references

#include <stddef.h>
#include "mquickjs.h"
#include "mquickjs_priv.h"

// Stub implementations for functions referenced by the stdlib but not in mquickjs.c

// print - no-op for now (could be hooked to WASM import)
JSValue js_print(JSContext *ctx, JSValue *this_val, int argc, JSValue *argv) {
    return JS_UNDEFINED;
}

// Date.now() - returns 0 (could be hooked to WASM import for actual time)
JSValue js_date_now(JSContext *ctx, JSValue *this_val, int argc, JSValue *argv) {
    return JS_NewInt64(ctx, 0);
}

// performance.now() - returns 0 (could be hooked to WASM import)
JSValue js_performance_now(JSContext *ctx, JSValue *this_val, int argc, JSValue *argv) {
    return JS_NewInt64(ctx, 0);
}

// gc() - trigger garbage collection
JSValue js_gc(JSContext *ctx, JSValue *this_val, int argc, JSValue *argv) {
    JS_GC(ctx);
    return JS_UNDEFINED;
}

// load() - not supported in WASM
JSValue js_load(JSContext *ctx, JSValue *this_val, int argc, JSValue *argv) {
    return JS_ThrowError(ctx, JS_CLASS_ERROR, "load() not supported in WASM");
}

// setTimeout - stub (no-op, returns 0)
JSValue js_setTimeout(JSContext *ctx, JSValue *this_val, int argc, JSValue *argv) {
    return JS_NewInt32(ctx, 0);
}

// clearTimeout - stub (no-op)
JSValue js_clearTimeout(JSContext *ctx, JSValue *this_val, int argc, JSValue *argv) {
    return JS_UNDEFINED;
}

// Include the generated 32-bit stdlib
#include "wasm_stdlib.h"
