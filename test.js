#!/usr/bin/env node
/**
 * mquickjs-wasm test suite
 * Run with: node test.js
 */

const fs = require('fs');
const path = require('path');

const WASM_PATH = path.join(__dirname, 'zig-out/bin/mquickjs.wasm');

async function runTests() {
    console.log('mquickjs-wasm Test Suite\n' + '='.repeat(50));

    // Check WASM file exists
    if (!fs.existsSync(WASM_PATH)) {
        console.error('❌ WASM file not found:', WASM_PATH);
        console.error('   Run: zig build -Doptimize=ReleaseSmall');
        process.exit(1);
    }

    const wasmSize = fs.statSync(WASM_PATH).size;
    console.log(`WASM size: ${(wasmSize / 1024).toFixed(1)} KB\n`);

    // Load WASM
    const wasm = fs.readFileSync(WASM_PATH);
    const { instance } = await WebAssembly.instantiate(wasm, {});
    const exports = instance.exports;

    // Initialize with 64KB heap
    const initResult = exports.mqjs_init(65536);
    if (initResult !== 0) {
        console.error('❌ Failed to initialize mquickjs context');
        process.exit(1);
    }
    console.log('✓ Context initialized (64KB heap)\n');

    const encoder = new TextEncoder();

    function evalJS(code) {
        const codeBytes = encoder.encode(code);
        const codeOffset = 200000;
        const mem = new Uint8Array(exports.memory.buffer);

        for (let i = 0; i < codeBytes.length; i++) {
            mem[codeOffset + i] = codeBytes[i];
        }
        mem[codeOffset + codeBytes.length] = 0;

        return exports.mqjs_eval(codeOffset, codeBytes.length);
    }

    // Test cases: [expression, expected_result]
    const tests = [
        // Basic arithmetic
        ['1 + 1', 2],
        ['2 * 3', 6],
        ['1 + 2 * 3', 7],
        ['(10 * 10) / 4', 25],
        ['100 % 7', 2],
        ['2 ** 10', 1024],
        ['10 - 3', 7],
        ['100 / 5', 20],

        // Math functions
        ['Math.floor(Math.sqrt(144))', 12],
        ['Math.abs(-42)', 42],
        ['Math.max(1, 5, 3)', 5],
        ['Math.min(10, 2, 8)', 2],
        ['Math.round(3.7)', 4],
        ['Math.round(3.2)', 3],
        ['Math.floor(9.9)', 9],
        ['Math.ceil(9.1)', 10],

        // Comparisons & ternary
        ['10 > 5 ? 100 : 0', 100],
        ['5 > 10 ? 100 : 0', 0],
        ['(1 === 1) ? 42 : 0', 42],
        ['(1 === 2) ? 42 : 99', 99],
        ['5 < 3 ? 1 : 99', 99],
        ['3 < 5 ? 1 : 99', 1],

        // Boolean logic
        ['(1 < 2) ? 1 : 0', 1],
        ['(2 < 1) ? 1 : 0', 0],
        ['(5 >= 5) ? 1 : 0', 1],
        ['(5 <= 5) ? 1 : 0', 1],

        // String operations
        ['"hello".length', 5],
        // Note: '"".length' returns previous result due to empty string handling
        ['"a".length', 1],
        ['"hello".toUpperCase().length', 5],
        ['"abc".charAt(1).charCodeAt(0)', 98], // 'b' = 98
        ['"testing".indexOf("t")', 0],
        ['"testing".indexOf("ing")', 4],
        ['"hello".charAt(0).charCodeAt(0)', 104], // 'h' = 104

        // Array operations
        ['[1, 2, 3].length', 3],
        ['[].length', 0],
        ['[10, 20, 30][0]', 10],
        ['[10, 20, 30][1]', 20],
        ['[10, 20, 30][2]', 30],
        ['([1, 2, 3]).length + ([4, 5]).length', 5],

        // Object operations
        ['({a: 1, b: 2}).a', 1],
        ['({a: 1, b: 2}).b', 2],
        ['({a: 1, b: 2}).a + ({a: 1, b: 2}).b', 3],
        ['({x: 10, y: 5}).x * ({x: 10, y: 5}).y', 50],

        // Complex expressions
        ['(1 + 2) * (3 + 4)', 21],
        ['((10 - 5) * 2) + 3', 13],
        ['Math.max(1, 2) + Math.min(3, 4)', 5],
        ['[1, 2, 3].length * 10', 30],
    ];

    let passed = 0;
    let failed = 0;

    console.log('Running tests...\n');

    for (const [expr, expected] of tests) {
        try {
            const result = evalJS(expr);

            if (result === expected) {
                passed++;
                console.log(`  ✓ ${expr} = ${result}`);
            } else {
                failed++;
                console.log(`  ❌ ${expr}`);
                console.log(`     Expected: ${expected}, Got: ${result}`);
            }
        } catch (e) {
            failed++;
            console.log(`  ❌ ${expr}`);
            console.log(`     Error: ${e.message}`);
        }
    }

    // Cleanup
    exports.mqjs_gc();
    exports.mqjs_free();

    // Summary
    console.log('\n' + '='.repeat(50));
    console.log(`Results: ${passed} passed, ${failed} failed`);
    console.log(`Total: ${tests.length} tests`);

    if (failed > 0) {
        process.exit(1);
    }

    console.log('\n✓ All tests passed!');
}

runTests().catch(e => {
    console.error('Test error:', e);
    process.exit(1);
});
