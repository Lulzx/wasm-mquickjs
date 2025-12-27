/**
 * MicroQuickJS WASM JavaScript Wrapper
 *
 * A tiny (~165KB) JavaScript engine running in WASM.
 *
 * Usage:
 *   import { createRuntime } from './mquickjs.js';
 *
 *   const vm = await createRuntime({ maxMemory: 65536 });
 *   const result = vm.eval('1 + 2'); // 3
 *   vm.free();
 */

let wasmModule = null;
let wasmInstance = null;

/**
 * Load the WASM module
 * @param {string|URL} wasmPath - Path to mquickjs.wasm
 */
async function loadWasm(wasmPath = './zig-out/bin/mquickjs.wasm') {
    if (wasmModule) return wasmModule;

    const response = await fetch(wasmPath);
    const bytes = await response.arrayBuffer();

    const result = await WebAssembly.instantiate(bytes, {
        env: {
            // No imports needed - fully self-contained
        }
    });

    wasmModule = result.module;
    wasmInstance = result.instance;

    return wasmModule;
}

/**
 * Text encoder/decoder for string conversion
 */
const encoder = new TextEncoder();
const decoder = new TextDecoder();

/**
 * Create a new mquickjs runtime instance
 * @param {Object} options
 * @param {number} options.maxMemory - Max JS heap size in bytes (default: 65536)
 * @param {string|URL} options.wasmPath - Path to WASM file
 * @returns {Promise<MQuickJSRuntime>}
 */
export async function createRuntime(options = {}) {
    const {
        maxMemory = 65536,
        wasmPath = './zig-out/bin/mquickjs.wasm'
    } = options;

    await loadWasm(wasmPath);

    const exports = wasmInstance.exports;
    const memory = exports.memory;

    // Initialize the JS context
    const initResult = exports.mqjs_init(maxMemory);
    if (initResult !== 0) {
        throw new Error('Failed to initialize mquickjs context');
    }

    /**
     * Write a string to WASM memory and return pointer/length
     */
    function writeString(str) {
        const bytes = encoder.encode(str);
        const ptr = exports.mqjs_memory_base();
        const memSize = exports.mqjs_memory_size();

        // Write to end of the internal buffer (after the JS heap)
        // This is a simple approach - for production, use a proper allocator
        const offset = memSize - bytes.length - 1;
        const view = new Uint8Array(memory.buffer, ptr + offset, bytes.length + 1);
        view.set(bytes);
        view[bytes.length] = 0; // null terminator

        return { ptr: ptr + offset, len: bytes.length };
    }

    /**
     * Read a string from WASM memory
     */
    function readString(ptr, len) {
        const view = new Uint8Array(memory.buffer, ptr, len);
        return decoder.decode(view);
    }

    return {
        /**
         * Evaluate JavaScript code and return the result
         * @param {string} code - JavaScript code to evaluate
         * @returns {number|null} - Result (for integers) or null on error
         */
        eval(code) {
            const { ptr, len } = writeString(code);
            const result = exports.mqjs_eval(ptr, len);

            if (result === -1) {
                // Get exception info if available
                const lenPtr = exports.mqjs_memory_base() + exports.mqjs_memory_size() - 4;
                const excPtr = exports.mqjs_get_exception(lenPtr);
                if (excPtr) {
                    const excLen = new Uint32Array(memory.buffer, lenPtr, 1)[0];
                    const excMsg = readString(excPtr, excLen);
                    throw new Error(`JS Error: ${excMsg}`);
                }
                throw new Error('JavaScript evaluation failed');
            }

            return result;
        },

        /**
         * Run garbage collection
         */
        gc() {
            exports.mqjs_gc();
        },

        /**
         * Free the runtime and release resources
         */
        free() {
            exports.mqjs_free();
        },

        /**
         * Get memory statistics
         */
        getMemoryInfo() {
            return {
                wasmPages: memory.buffer.byteLength / 65536,
                jsHeapSize: maxMemory
            };
        }
    };
}

// For Node.js / CommonJS
if (typeof module !== 'undefined' && module.exports) {
    module.exports = { createRuntime };
}
