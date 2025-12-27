// Minimal math.h for WASM freestanding
// mquickjs has its own libm.c, we just need a few helpers
#ifndef _MATH_H
#define _MATH_H

// IEEE 754 double bit manipulation for isnan, isinf, ldexp
typedef union {
    double d;
    unsigned long long u;
} double_bits;

// Check if double is NaN
static inline int isnan(double x) {
    double_bits db;
    db.d = x;
    // NaN has all exponent bits set and non-zero mantissa
    return ((db.u >> 52) & 0x7FF) == 0x7FF && (db.u & 0xFFFFFFFFFFFFFULL) != 0;
}

// Check if double is infinite
static inline int isinf(double x) {
    double_bits db;
    db.d = x;
    // Infinity has all exponent bits set and zero mantissa
    return ((db.u >> 52) & 0x7FF) == 0x7FF && (db.u & 0xFFFFFFFFFFFFFULL) == 0;
}

// Check if double is finite
static inline int isfinite(double x) {
    double_bits db;
    db.d = x;
    return ((db.u >> 52) & 0x7FF) != 0x7FF;
}

// ldexp: multiply by power of 2
static inline double ldexp(double x, int exp) {
    double_bits db;
    db.d = x;

    if (exp == 0 || x == 0.0 || !isfinite(x)) {
        return x;
    }

    int old_exp = (db.u >> 52) & 0x7FF;
    int new_exp = old_exp + exp;

    if (new_exp <= 0) {
        // Underflow to zero
        return 0.0;
    }
    if (new_exp >= 0x7FF) {
        // Overflow to infinity
        return (db.u >> 63) ? -1.0/0.0 : 1.0/0.0;
    }

    db.u = (db.u & ~(0x7FFULL << 52)) | ((unsigned long long)new_exp << 52);
    return db.d;
}

// frexp: extract mantissa and exponent
static inline double frexp(double x, int *exp) {
    double_bits db;
    db.d = x;

    if (x == 0.0) {
        *exp = 0;
        return 0.0;
    }

    if (!isfinite(x)) {
        *exp = 0;
        return x;
    }

    int e = ((db.u >> 52) & 0x7FF) - 1022;
    *exp = e;

    // Set exponent to -1 (bias 1022) to get value in [0.5, 1)
    db.u = (db.u & ~(0x7FFULL << 52)) | (0x3FEULL << 52);
    return db.d;
}

// scalbn: scale by power of 2 (integer exponent)
static inline double scalbn(double x, int n) {
    return ldexp(x, n);
}

// fabs: absolute value
static inline double fabs(double x) {
    double_bits db;
    db.d = x;
    db.u &= ~(1ULL << 63);
    return db.d;
}

// copysign: copy sign from y to x
static inline double copysign(double x, double y) {
    double_bits dx, dy;
    dx.d = x;
    dy.d = y;
    dx.u = (dx.u & ~(1ULL << 63)) | (dy.u & (1ULL << 63));
    return dx.d;
}

// signbit: return sign bit
static inline int signbit(double x) {
    double_bits db;
    db.d = x;
    return (db.u >> 63) != 0;
}

// Constants
#define INFINITY (1.0/0.0)
#define NAN (0.0/0.0)
#define HUGE_VAL INFINITY

#endif
