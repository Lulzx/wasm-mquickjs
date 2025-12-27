// Minimal stdlib.h for WASM freestanding
#ifndef _STDLIB_H
#define _STDLIB_H

#include <stddef.h>

// Not implemented - mquickjs doesn't use these in core
// void *malloc(size_t size);
// void free(void *ptr);

// For compatibility
#define NULL ((void*)0)

// abs - provided by Zig
int abs(int x);

// abort - trap in WASM
static inline void abort(void) {
    __builtin_trap();
}

#endif
