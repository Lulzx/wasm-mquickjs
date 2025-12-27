// Minimal stdio.h for WASM freestanding
#ifndef _STDIO_H
#define _STDIO_H

#include <stddef.h>
#include <stdarg.h>

// Not implemented - mquickjs core doesn't use these
// printf, fprintf, etc.

#define EOF (-1)

typedef struct FILE FILE;

// printf stub - does nothing, returns 0
static inline int printf(const char *fmt, ...) {
    (void)fmt;
    return 0;
}

static inline int fprintf(FILE *f, const char *fmt, ...) {
    (void)f;
    (void)fmt;
    return 0;
}

static inline int snprintf(char *buf, size_t n, const char *fmt, ...) {
    (void)buf;
    (void)n;
    (void)fmt;
    return 0;
}

static inline int vsnprintf(char *buf, size_t n, const char *fmt, va_list ap) {
    (void)buf;
    (void)n;
    (void)fmt;
    (void)ap;
    return 0;
}

#endif
