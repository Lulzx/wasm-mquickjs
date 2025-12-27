# mquickjs-wasm

MicroQuickJS compiled to WebAssembly - a **165KB** JavaScript engine.

## Features

- **Tiny**: ~165KB WASM binary (ReleaseSmall)
- **Self-contained**: Zero host imports required
- **Minimal memory**: Works with 32KB JS heap
- **Full JavaScript**: Arithmetic, arrays, objects, functions, closures

## Quick Start

```javascript
import { createRuntime } from './mquickjs.js';

const vm = await createRuntime({
    maxMemory: 65536,  // 64KB JS heap
    wasmPath: './zig-out/bin/mquickjs.wasm'
});

console.log(vm.eval('1 + 2 * 3'));  // 7
console.log(vm.eval('([1,2,3]).length'));  // 3
console.log(vm.eval('(function(x) { return x * 2; })(21)'));  // 42

vm.free();
```

## Build

Requires Zig 0.15+:

```bash
# Debug build
zig build

# Release build (165KB)
zig build -Doptimize=ReleaseSmall
```

Output: `zig-out/bin/mquickjs.wasm`

## Architecture

```
┌─────────────────────────────────────────────┐
│  Host (Browser / Node.js)                   │
├─────────────────────────────────────────────┤
│  mquickjs.wasm (165KB)                      │
│  ├── mquickjs.c (JS engine core)            │
│  ├── libm.c (embedded math)                 │
│  ├── dtoa.c (number conversion)             │
│  └── libc shims (Zig)                       │
├─────────────────────────────────────────────┤
│  WASM Linear Memory (2MB initial)           │
│  └── JS Heap (configurable, 32-64KB)        │
└─────────────────────────────────────────────┘
```

## API

### Exports

| Function | Description |
|----------|-------------|
| `mqjs_init(heap_size)` | Initialize context with heap size |
| `mqjs_eval(ptr, len)` | Evaluate JS code, return int result |
| `mqjs_gc()` | Run garbage collection |
| `mqjs_free()` | Free the context |
| `mqjs_memory_base()` | Get JS heap buffer pointer |
| `mqjs_memory_size()` | Get JS heap buffer size |

### Limitations

- **Integer results only**: `mqjs_eval` returns decoded integers; strings/objects return pointers
- **No `var` at top-level**: Use expressions or wrap in IIFEs
- **No async/await**: MicroQuickJS is synchronous
- **Time stubs**: `Date.now()` and `performance.now()` return 0

## Credits

- [MicroQuickJS](https://github.com/bellard/mquickjs) by Fabrice Bellard
- [Zig](https://ziglang.org/) for WASM compilation

## License

MIT (wrapper code) + MicroQuickJS license (engine)
