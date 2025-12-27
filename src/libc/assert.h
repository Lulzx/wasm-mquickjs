// Minimal assert.h for WASM freestanding
#ifndef _ASSERT_H
#define _ASSERT_H

// No-op assert for release builds
#ifdef NDEBUG
#define assert(expr) ((void)0)
#else
// In debug builds, trap on assertion failure
#define assert(expr) ((expr) ? (void)0 : __builtin_trap())
#endif

#endif
