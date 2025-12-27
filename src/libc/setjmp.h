// Minimal setjmp.h for WASM freestanding
#ifndef _SETJMP_H
#define _SETJMP_H

// jmp_buf - placeholder type
typedef int jmp_buf[16];

// setjmp/longjmp - extern declarations, implemented in Zig
int setjmp(jmp_buf env);
void longjmp(jmp_buf env, int val);

#endif
