const std = @import("std");

pub fn build(b: *std.Build) void {
    // WASM32 freestanding target
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const optimize = b.standardOptimizeOption(.{});

    // Create the WASM library
    const lib = b.addExecutable(.{
        .name = "mquickjs",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/wasm_entry.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Export as WASM with dynamic memory
    lib.rdynamic = true;
    lib.entry = .disabled;
    lib.export_memory = true;
    lib.import_memory = false;
    lib.initial_memory = 65536 * 18; // 1.125MB - minimum needed for code+data
    lib.max_memory = 65536 * 18; // No growth - fixed size

    // Add C source files
    const c_sources = [_][]const u8{
        "mquickjs/mquickjs.c",
        "mquickjs/dtoa.c",
        "mquickjs/libm.c",
        "mquickjs/cutils.c",
        "src/wasm_stdlib.c",
    };

    const c_flags = [_][]const u8{
        "-DNDEBUG",
        "-fno-math-errno",
        "-fno-trapping-math",
        "-Os",
        "-fno-stack-protector",
        "-fno-sanitize=undefined",
        "-Wno-incompatible-library-redeclaration",
    };

    // Include paths - libc shim must come FIRST
    lib.addIncludePath(b.path("src/libc"));
    lib.addIncludePath(b.path("mquickjs"));
    lib.addIncludePath(b.path("src"));

    lib.addCSourceFiles(.{
        .files = &c_sources,
        .flags = &c_flags,
    });

    b.installArtifact(lib);

    // Add a run step that shows the size
    const size_cmd = b.addSystemCommand(&.{
        "wc", "-c",
    });
    size_cmd.addFileArg(lib.getEmittedBin());

    const size_step = b.step("size", "Show WASM binary size");
    size_step.dependOn(&size_cmd.step);
}
