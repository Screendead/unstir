// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreImage
import CoreVideo
import IOSurface
import Metal
import SwiftUI

/// The stored map: where each tap of a level's glass lands on the picture through the committed stack, worked out once
/// when the stack changes (`stirMap` in Unstir.metal) and read by `unstirMapped` every frame after in place of the
/// chain, so a frame costs the same at any depth (Jack, 2026-11-12: find a faster way to draw twists, provided it
/// doesn't look worse).
enum StirMap {
    /// How `unstirMappedBody` draws a tap that lands between the map's texels: `mix` from the map, as the game ships
    /// (Jack, 2026-11-12); `chain` through the whole chain as `unstir` does, and `show`, `mix` with each pixel tinted
    /// by how many of its taps read their own texel, for the oracle and the eye.
    enum Mode: Float {
        case chain = 0, mix, show
    }

    /// UNSTIR_MAP=off|chain|show, a probe: Debug reads it, and a Release build only with PROBES=YES.
    nonisolated static let mode: Mode? = {
        #if PROBES || DEBUG
        switch ProcessInfo.processInfo.environment["UNSTIR_MAP"] {
        case "off": return nil
        case "chain": return .chain
        case "show": return .show
        default: return .mix
        }
        #else
        return .mix
        #endif
    }()

    private nonisolated static func probed(_ name: String) -> String? {
        #if PROBES || DEBUG
        return ProcessInfo.processInfo.environment[name]
        #else
        return nil
        #endif
    }

    /// How far, in pixels of the picture, four neighbouring texels may lie from a straight map's before a tap between
    /// them takes the nearest whole (`between` in Unstir.metal). UNSTIR_MAPBEND, a probe.
    nonisolated static let bend = probed("UNSTIR_MAPBEND").flatMap(Float.init) ?? 16
    /// The shallowest stack worth a map and its memory: on the Mac's GPU (2026-11-13) a map's rest frame costs what
    /// 6 entries of the chain do, a rod in hand over it 8 and the rim in hand 11. UNSTIR_MAPLEAST, a probe.
    nonisolated static let least = probed("UNSTIR_MAPLEAST").flatMap(Int.init) ?? 10
    /// UNSTIR_MAPLOG, a probe: a line in the log as each map lands (`Holder.report`).
    nonisolated static let logs = probed("UNSTIR_MAPLOG") != nil

    /// Steps a device pixel the map stores a point in, on a glass `pixels` across: the most 16 bits hold across the
    /// glass, in whole fours, so a tap a quarter pixel off a pixel's centre is stored exactly.
    nonisolated static func quant(pixels: Int) -> Float { Float(4 * (65535 / (4 * max(pixels, 1)))) }

    /// What a map is of: the entries it holds, as the shader takes them, the glass's turn and its size.
    struct Key: Equatable, Sendable {
        var twists: [Float]
        var rest: Double
        var side: CGFloat
        var scale: CGFloat
        var pixels: Int { Int((side * scale).rounded(.up)) }
    }

    /// The map a level's glass at rest would draw from, nil where it draws without one: a stack under `least`, one
    /// still winding in, a Lens level (its flow's detail holds the shader's image) or Prism's three chains.
    nonisolated static func key(_ glass: Unstirred, scale: CGFloat) -> Key? {
        guard mode != nil, glass.stack.count >= least, glass.wind >= 1, glass.shares == nil, glass.lenses.isEmpty else { return nil }
        let (twists, channels) = Unstirred.entries(glass.stack.map { ($0.rod, Double($0.steps) * Tank.step) }, layout: glass.layout,
                                                   lenses: [], masks: glass.masks)
        guard Unstirred.channelCost(channels) == nil else { return nil }
        return Key(twists: twists, rest: glass.turn, side: glass.side, scale: scale)
    }

    struct Made: Equatable {
        var key: Key
        var image: Image
        var quant: Float
        /// Which drawing of the map this is, for telling two apart cheaply.
        var id: Int

        nonisolated static func == (a: Made, b: Made) -> Bool { a.id == b.id }
    }

    /// `stirMap`'s arguments, and with `benchMapped`'s own the bench's: MapArgs' layout in Unstir.metal.
    struct Args {
        var radius, scale, centreX, centreY, plateau, swirlPlateau, lensEdge, rest, quant, mode, bend: Float
        var kept: Int32
        var row: Int32 = 0
    }

    nonisolated static func args(_ key: Key, mode: Mode = .mix, bend: Float = StirMap.bend) -> Args {
        let r = Float(key.side / 2), scale = Float(key.scale)
        return Args(radius: r, scale: scale, centreX: r + Float(Unstirred.nudge.x) / scale, centreY: r + Float(Unstirred.nudge.y) / scale,
                    plateau: Float(Tank.plateau), swirlPlateau: Float(Tank.swirlPlateau), lensEdge: Float(Tank.lensEdge),
                    rest: Float(key.rest), quant: quant(pixels: key.pixels), mode: mode.rawValue, bend: bend, kept: Int32(key.twists.count / 4))
    }

    /// A map drawn: its image, and for the log the GPU's time over its strips.
    struct Drawn: @unchecked Sendable {
        var image: CGImage
        var gpu: Double
        var strips: Int
    }

    private struct GPU: @unchecked Sendable {
        var device: MTLDevice
        var queue: MTLCommandQueue
        var pipeline: MTLComputePipelineState
        var context: CIContext
    }

    private static let gpu: GPU? = {
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let function = device.makeDefaultLibrary()?.makeFunction(name: "stirMap"),
              let pipeline = try? device.makeComputePipelineState(function: function) else { return nil }
        return GPU(device: device, queue: queue, pipeline: pipeline,
                   context: CIContext(mtlDevice: device, options: [.workingColorSpace: NSNull(), .outputColorSpace: NSNull(), .cacheIntermediates: false]))
    }()

    private static let drawing = DispatchQueue(label: "stir map", qos: .userInitiated)

    /// The map's image, two texels a device pixel, drawn by the GPU straight into a surface the image then stands
    /// for: SwiftUI hands a shader an image, not a texture, and uploads an image of plain bytes on the main thread
    /// as it first draws it, 20 MB a map, one long frame a commit (33 to 43 ms in the simulator). A deferred Core
    /// Image image of a surface is one RenderBox makes its texture of in place (`prepare_from_iosurface`, by a sample
    /// of the simulator, iOS 26.5, 2026-11-13), so nothing is read back and nothing uploaded. The surface is never
    /// written again: every map has its own. Tagged sRGB, which reaches the shader untouched; BGRA, the order
    /// SwiftUI's own textures keep.
    ///
    /// Drawn a strip of rows at a time, each its own command buffer, meant to let a frame the screen is waiting on
    /// queue behind one strip and not the whole map, which is a frame of the full chain's work (no phone has shown it).
    private nonisolated static func draw(_ key: Key) -> Drawn? {
        guard let gpu, !key.twists.isEmpty else { return nil }
        let pixels = key.pixels, n = 2 * pixels
        let properties: [CFString: Any] = [kIOSurfaceWidth: n, kIOSurfaceHeight: n, kIOSurfaceBytesPerElement: 4,
                                           kIOSurfacePixelFormat: kCVPixelFormatType_32BGRA]
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: n, height: n, mipmapped: false)
        desc.usage = [.shaderRead, .shaderWrite]
        guard let surface = IOSurfaceCreate(properties as CFDictionary),
              let map = gpu.device.makeTexture(descriptor: desc, iosurface: surface, plane: 0),
              let twists = gpu.device.makeBuffer(bytes: key.twists, length: 4 * key.twists.count) else { return nil }
        var args = args(key), seconds = 0.0
        let strips = min(max(key.twists.count / 12, 1), 16), rows = (pixels + strips - 1) / strips
        for row in stride(from: 0, to: pixels, by: rows) {
            guard let commands = gpu.queue.makeCommandBuffer(), let enc = commands.makeComputeCommandEncoder() else { return nil }
            args.row = Int32(row)
            enc.setComputePipelineState(gpu.pipeline)
            enc.setTexture(map, index: 0)
            enc.setBuffer(twists, offset: 0, index: 0)
            enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 1)
            enc.dispatchThreads(MTLSize(width: pixels, height: min(rows, pixels - row), depth: 1),
                                threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
            enc.endEncoding()
            commands.commit()
            commands.waitUntilCompleted()
            guard commands.status == .completed else { return nil }
            seconds += commands.gpuEndTime - commands.gpuStartTime
        }
        let image = CIImage(ioSurface: surface, options: [.colorSpace: NSNull()])
        return gpu.context.createCGImage(image, from: image.extent, format: .BGRA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB), deferred: true)
            .map { Drawn(image: $0, gpu: seconds, strips: (pixels + rows - 1) / rows) }
    }

    /// `draw` off the main actor, one map at a time.
    nonisolated static func drawn(_ key: Key) async -> Drawn? {
        await withCheckedContinuation { done in drawing.async { done.resume(returning: draw(key)) } }
    }

    /// A level's glass's map: the last one drawn, and the drawing of the next once the committed stack has held
    /// still for `settle`, one at a time. A frame drawn meanwhile takes the map it has for as many of its bottom
    /// entries as that holds (`Unstirred.shader`).
    @MainActor @Observable final class Holder {
        /// How long a key is asked for before its map is drawn: a tick's flight, autoplay or the glass easing home
        /// asks for another every frame, and a map costs the GPU a frame of the whole chain.
        static let settle = Duration.milliseconds(40)

        private(set) var made: Made?
        @ObservationIgnored private var wanted: Key?
        @ObservationIgnored private var busy = false
        @ObservationIgnored private var count = 0
        @ObservationIgnored private var asked = [Twist]()
        @ObservationIgnored private var askedOf: (layout: Layout, turn: Double, side: CGFloat, scale: CGFloat, wound: Bool)?

        nonisolated init() {}

        /// Asks for `glass`'s map, where it draws from one (`StirMap.key`). Called a frame, so it only makes the key
        /// where what the key is made of has changed.
        func want(_ glass: Unstirred, scale: CGFloat) {
            let of = (glass.layout, glass.turn, glass.side, scale, glass.wind >= 1 && glass.shares == nil)
            if let askedOf, askedOf == of, asked == glass.stack { return }
            (asked, askedOf) = (glass.stack, of)
            want(StirMap.key(glass, scale: scale))
        }

        func want(_ key: Key?) {
            guard key != wanted else { return }
            wanted = key
            watch()
            guard !busy else { return }
            busy = true
            Task {
                while true {
                    try? await Task.sleep(for: Self.settle)
                    guard let key = wanted else {
                        made = nil
                        break
                    }
                    if key == made?.key { break }
                    let start = CACurrentMediaTime()
                    let drawn = await StirMap.drawn(key)
                    if let drawn {
                        count += 1
                        made = Made(key: key, image: Image(decorative: drawn.image, scale: 1), quant: StirMap.quant(pixels: key.pixels), id: count)
                        report(key, drawn, took: CACurrentMediaTime() - start)
                    }
                    if wanted == key { break }
                }
                busy = false
            }
        }

        #if PROBES || DEBUG
        @ObservationIgnored private lazy var gaps = Gaps()

        private func watch() {
            if StirMap.logs { gaps.watch() }
        }

        /// UNSTIR_MAPLOG: each map as it lands, for `scripts/pull-log.sh`: what it holds, how long it took to draw
        /// and how much of that was the GPU's, then (`Gaps`) the longest frame of the eight after it beside the
        /// usual one, and the app's memory.
        private func report(_ key: Key, _ drawn: Drawn, took: Double) {
            guard StirMap.logs else { return }
            Log.write(String(format: "stirmap: %d entries at %d px, %.1f MB, drawn in %.1f ms, %.2f ms of the GPU's in %d strips",
                             key.twists.count / 4, 2 * key.pixels, Double(16 * key.pixels * key.pixels) / 1e6, took * 1000, drawn.gpu * 1000, drawn.strips))
            gaps.landed()
        }
        #else
        @inline(__always) private func watch() {}
        @inline(__always) private func report(_ key: Key, _ drawn: Drawn, took: Double) {}
        #endif
    }

    #if PROBES || DEBUG
    /// The display link's longest gap over the eight frames after a map lands, beside its usual one: what a landing
    /// costs the main thread shows as a long frame here.
    @MainActor private final class Gaps {
        private var last = 0.0, usual = 0.0, worst = 0.0, left = 0
        private var link: CADisplayLink?

        func watch() {
            guard link == nil else { return }
            link = CADisplayLink(target: self, selector: #selector(step))
            link?.add(to: .main, forMode: .common)
        }

        func landed() {
            watch()
            (left, worst) = (8, 0)
        }

        @objc private func step(_ l: CADisplayLink) {
            let gap = last > 0 ? l.timestamp - last : 0
            last = l.timestamp
            if left > 0 {
                worst = max(worst, gap)
                left -= 1
                if left == 0 {
                    Log.write(String(format: "stirmap: landed with a longest frame of %.1f ms, %.1f usual, memory %.0f MB",
                                     worst * 1000, usual * 1000, StirMap.footprint() / 1e6))
                }
            } else if gap > 0 {
                usual = usual == 0 ? gap : 0.9 * usual + 0.1 * gap
            }
        }
    }

    /// The app's memory as iOS counts it against its limit, in bytes.
    nonisolated static func footprint() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) }
        }
        return result == KERN_SUCCESS ? Double(info.phys_footprint) : 0
    }
    #endif
}
