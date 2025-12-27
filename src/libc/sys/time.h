// Minimal sys/time.h for WASM freestanding
#ifndef _SYS_TIME_H
#define _SYS_TIME_H

// Not actually used - just a placeholder
struct timeval {
    long tv_sec;
    long tv_usec;
};

// Stub - returns 0
static inline int gettimeofday(struct timeval *tv, void *tz) {
    if (tv) {
        tv->tv_sec = 0;
        tv->tv_usec = 0;
    }
    return 0;
}

#endif
