// Minimal inttypes.h for WASM freestanding
#ifndef _INTTYPES_H
#define _INTTYPES_H

#include <stdint.h>

// Format specifiers for printf (not used in core but needed for headers)
#define PRId8 "d"
#define PRId16 "d"
#define PRId32 "d"
#define PRId64 "lld"

#define PRIu8 "u"
#define PRIu16 "u"
#define PRIu32 "u"
#define PRIu64 "llu"

#define PRIx8 "x"
#define PRIx16 "x"
#define PRIx32 "x"
#define PRIx64 "llx"

#define PRIo32 "o"
#define PRIo64 "llo"

#define PRIX32 "X"
#define PRIX64 "llX"

#endif
