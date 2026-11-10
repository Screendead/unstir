// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import XCTest

/// One of Sources' `.metal` files compiled with a test's own kernels after it, and the plumbing to run them.
struct ShaderKit {
    let device: MTLDevice
    let queue: MTLCommandQueue
    let library: MTLLibrary

    /// `file` (in Sources) without SwiftUI's header, then `kernels`. A stitchable that takes a layer can't compile
    /// without that header, so `helpersOnly` keeps only what comes before the first; otherwise every stitchable stays,
    /// as a plain function.
    init(_ file: String, helpersOnly: Bool, kernels: String) throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("no Metal device") }
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/\(file)")
        let whole = try String(contentsOf: url, encoding: .utf8)
        let kept = helpersOnly ? try XCTUnwrap(whole.components(separatedBy: "[[ stitchable ]]").first)
            : whole.replacingOccurrences(of: "[[ stitchable ]]", with: "")
        self.device = device
        queue = try XCTUnwrap(device.makeCommandQueue())
        library = try device.makeLibrary(source: kept.replacingOccurrences(of: "#include <SwiftUI/SwiftUI_Metal.h>", with: "")
                                         + "\n" + kernels, options: nil)
    }

    func pipeline(_ kernel: String) throws -> MTLComputePipelineState {
        try device.makeComputePipelineState(function: try XCTUnwrap(library.makeFunction(name: kernel), kernel))
    }

    /// A buffer holding `values`.
    func buffer<T>(_ values: [T]) throws -> MTLBuffer {
        try XCTUnwrap(device.makeBuffer(bytes: values, length: MemoryLayout<T>.stride * values.count))
    }

    /// A zeroed buffer of `count` `T`s.
    func buffer<T>(_: T.Type, count: Int) throws -> MTLBuffer {
        let b = try XCTUnwrap(device.makeBuffer(length: MemoryLayout<T>.stride * count))
        memset(b.contents(), 0, b.length)
        return b
    }

    /// The `T`s a buffer holds.
    func read<T>(_ buffer: MTLBuffer, as _: T.Type) -> [T] {
        let n = buffer.length / MemoryLayout<T>.stride
        return Array(UnsafeBufferPointer(start: buffer.contents().bindMemory(to: T.self, capacity: n), count: n))
    }

    /// Runs `pipeline` over `grid` with what `encode` sets, and waits for it.
    func run(_ pipeline: MTLComputePipelineState, grid: MTLSize, group: MTLSize = MTLSize(width: 64, height: 1, depth: 1),
             _ encode: (MTLComputeCommandEncoder) -> Void) throws {
        let cb = try XCTUnwrap(queue.makeCommandBuffer()), enc = try XCTUnwrap(cb.makeComputeCommandEncoder())
        enc.setComputePipelineState(pipeline)
        encode(enc)
        enc.dispatchThreads(grid, threadsPerThreadgroup: group)
        enc.endEncoding()
        cb.commit()
        cb.waitUntilCompleted()
        XCTAssertNil(cb.error)
    }

    /// Runs `kernel` once per item of a one-dimensional grid of `count`.
    func run(_ kernel: String, count: Int, _ encode: (MTLComputeCommandEncoder) -> Void) throws {
        try run(try pipeline(kernel), grid: MTLSize(width: count, height: 1, depth: 1), encode)
    }
}
