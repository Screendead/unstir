// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import MetalKit
import SwiftUI

/// UNSTIR_GPUBENCH=1: times the tank's shader on the GPU's own clock, off screen, then quits. The display-link bench
/// (UNSTIR_BENCH) sees only main-thread stalls; this runs the stitchables' own bodies (`benchUnstir` in Unstir.metal) on
/// a texture of the picture and reads each command buffer's GPU start and end. It prints and logs one line a case
/// (`scripts/gpu-bench.sh`, or `scripts/pull-log.sh` off the phone): a plain stack at 0, 18 and 36 entries, with four
/// taps and with two, on glasses of 1137 px (the iPhone 13 Pro Max's), 1284 and 1471 (the open Duo's upright one); the
/// glass's own fill (`benchGlass` in Glass.metal) and whirlpool 27's whole frame, that fill under its stack, at 1137 and
/// 1471; then, at 1284, a plain stack at 0 and 24 entries and every Prism specimen as dealt through the per-channel
/// shader and, for comparison, the same stack read white through the plain one.
enum GPUBench {
    static var wanted: Bool { ProcessInfo.processInfo.environment["UNSTIR_GPUBENCH"] == "1" }

    /// The Prism sweep's tank: 428 points at 3x.
    static let points = 428.0, scale = 3.0
    /// The glasses the size sweep draws, in device pixels: the iPhone 13 Pro Max's, the Prism sweep's and the open Duo's
    /// upright one.
    static let sides = [1137, 1284, 1471]
    /// `fourTaps` values that force each tap count whatever the stack's depth: the shader drops to two past it.
    static let four: Float = 99, two: Float = -1

    enum Kind { case unstir, fill, frame }

    struct Case {
        var name: String
        var picture: Picture
        var layout: Layout
        var stack: [Twist]
        var masks: [Int: Channels] = [:]
        var channels = false
        var side = Int(points * scale)
        var fourTaps = Float(Tank.fourTaps)
        var kind = Kind.unstir
    }

    struct Args {
        var radius, scale, n, fourTaps, cost, plateau, swirlPlateau, lensEdge: Float
        var count, maskCount, channels: Int32
    }

    struct GlassArgs {
        var radius, px, scale, t: Float
    }

    @MainActor static func run() async {
        @MainActor func say(_ line: String) {
            print(line)
            Log.write(line)
        }
        func heat() -> String { ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue] }
        say("GPUBENCH start, thermal \(heat()), low power \(ProcessInfo.processInfo.isLowPowerModeEnabled ? "on" : "off")")
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary() else {
            say("GPUBENCH no Metal")
            return
        }
        func make(_ name: String) async -> MTLComputePipelineState? {
            guard let function = library.makeFunction(name: name) else {
                say("GPUBENCH no function \(name)")
                return nil
            }
            do { return try await device.makeComputePipelineState(function: function) } catch {
                say("GPUBENCH no pipeline \(name): \(error)")
                return nil
            }
        }
        guard let pipeline = await make("benchUnstir"), let glassPipeline = await make("benchGlass") else { return }
        let side = Int(points * scale)
        struct Key: Hashable { var picture: Picture, side: Int }
        var textures: [Key: MTLTexture] = [:]
        let loader = MTKTextureLoader(device: device)
        for key in Set(sides.map { Key(picture: .grid, side: $0) } + Level.prism.map { Key(picture: $0.picture, side: side) }) {
            guard let image = await key.picture.render(side: Double(key.side) / scale, scale: scale)?.cgImage,
                  let t = try? await loader.newTexture(cgImage: image, options: [.SRGB: false]) else {
                say("GPUBENCH no picture \(key.picture.rawValue)")
                return
            }
            textures[key] = t
        }
        var outs: [Int: MTLTexture] = [:], fills: [Int: MTLTexture] = [:]
        for s in sides {
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: s, height: s, mipmapped: false)
            desc.usage = .shaderWrite
            outs[s] = device.makeTexture(descriptor: desc)
            desc.usage = [.shaderWrite, .shaderRead]
            fills[s] = device.makeTexture(descriptor: desc)
        }

        var rng = SplitMix64(state: 24)
        let deep = Layout.eye.scramble(depth: 24, inversions: 6, rng: &rng)
        var deepest = deep
        while deepest.count < Tank.maxStack { deepest += deep }
        deepest = Array(deepest.prefix(Tank.maxStack))
        var cases: [Case] = []
        for s in sides {
            for (taps, f) in [("four", four), ("two", two)] {
                for depth in [0, 18, 36] {
                    cases.append(Case(name: "\(s)-\(taps)-\(depth)", picture: .grid, layout: .eye,
                                      stack: Array(deepest.prefix(depth)), side: s, fourTaps: f))
                }
            }
        }
        let estuary = Level.whirlpool.last!
        var estuary36 = estuary.scramble
        while estuary36.count < Tank.maxStack { estuary36 += estuary.scramble }
        estuary36 = Array(estuary36.prefix(Tank.maxStack))
        for s in [sides.first!, sides.last!] {
            cases.append(Case(name: "\(s)-fill", picture: estuary.picture, layout: estuary.layout, stack: [], side: s, kind: .fill))
            for (taps, f) in [("four", four), ("two", two)] {
                for stack in [estuary.scramble, estuary36] {
                    cases.append(Case(name: "\(s)-\(estuary.id)-\(taps)-\(stack.count)", picture: estuary.picture,
                                      layout: estuary.layout, stack: stack, side: s, fourTaps: f, kind: .frame))
                }
            }
        }
        cases += [Case(name: "plain-0", picture: .grid, layout: .eye, stack: []),
                  Case(name: "plain-24", picture: .grid, layout: .eye, stack: deep)]
        for level in Level.prism {
            cases.append(Case(name: level.id, picture: level.picture, layout: level.layout, stack: level.scramble,
                              masks: level.masks, channels: true))
            cases.append(Case(name: "\(level.id)-white", picture: level.picture, layout: level.layout, stack: level.scramble))
        }

        var wallClock = false
        /// GPU seconds per frame of `c`: the median over 15 command buffers of 10 dispatches each, after a warm-up.
        func time(_ c: Case) -> Double {
            let rods = c.layout.rods
            var floats = c.stack.flatMap { t -> [Float] in
                let r = rods[t.rod]
                return [Float(r.x), Float(r.y), Float(r.z), Float(Double(t.steps) * Tank.step)]
            }
            var masks = c.stack.map { Float((c.masks[$0.rod] ?? .white).rawValue) }
            let n = floats.count / 4
            if floats.isEmpty { floats = [0, 0, 0, 0]; masks = [7] }
            let cost = Unstirred.channelCost(masks) ?? n
            let radius = Double(c.side) / scale / 2
            var args = Args(radius: Float(radius), scale: Float(scale), n: Float(n), fourTaps: c.fourTaps,
                            cost: Float(cost), plateau: Float(Tank.plateau), swirlPlateau: Float(Tank.swirlPlateau),
                            lensEdge: Float(Tank.lensEdge), count: Int32(floats.count), maskCount: Int32(masks.count),
                            channels: c.channels ? 1 : 0)
            let twists = device.makeBuffer(bytes: floats, length: 4 * floats.count)!
            let maskBuffer = device.makeBuffer(bytes: masks, length: 4 * masks.count)!
            let cells: [Float] = c.kind == .unstir ? [0] : c.picture.data(seed: 27, clock: 0) ?? [0]
            let cellBuffer = device.makeBuffer(bytes: cells, length: 4 * cells.count)!
            var glassArgs = GlassArgs(radius: Float(radius), px: Float(2 / (2 * radius * scale)), scale: Float(scale), t: 0)
            let grid = MTLSize(width: c.side, height: c.side, depth: 1), group = MTLSize(width: 16, height: 16, depth: 1)
            let picture = c.kind == .unstir ? textures[Key(picture: c.picture, side: c.side)] : fills[c.side]
            func buffer(_ reps: Int) -> Double {
                let cb = queue.makeCommandBuffer()!, enc = cb.makeComputeCommandEncoder()!
                for _ in 0..<reps {
                    // The default serial encoder finishes the fill before the unstir that samples it starts.
                    if c.kind != .unstir {
                        enc.setComputePipelineState(glassPipeline)
                        enc.setTexture(fills[c.side], index: 0)
                        enc.setBuffer(cellBuffer, offset: 0, index: 0)
                        enc.setBytes(&glassArgs, length: MemoryLayout<GlassArgs>.stride, index: 1)
                        enc.dispatchThreads(grid, threadsPerThreadgroup: group)
                    }
                    if c.kind != .fill {
                        enc.setComputePipelineState(pipeline)
                        enc.setTexture(picture, index: 0)
                        enc.setTexture(outs[c.side], index: 1)
                        enc.setBuffer(twists, offset: 0, index: 0)
                        enc.setBuffer(maskBuffer, offset: 0, index: 1)
                        enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 2)
                        enc.dispatchThreads(grid, threadsPerThreadgroup: group)
                    }
                }
                enc.endEncoding()
                let start = CACurrentMediaTime()
                cb.commit()
                cb.waitUntilCompleted()
                let wall = CACurrentMediaTime() - start
                // The simulator's command buffers carry no real GPU clock; there the wall clock round the buffer stands in.
                let gpu = cb.gpuEndTime - cb.gpuStartTime
                if gpu < wall / 4 { wallClock = true }
                return (wallClock ? wall : gpu) / Double(reps)
            }
            _ = buffer(5)
            let runs = (0..<15).map { _ in buffer(10) }.sorted()
            return runs[runs.count / 2]
        }

        var ms: [String: Double] = [:]
        for c in cases {
            let t = time(c) * 1000
            ms[c.name] = t
            say(String(format: "GPUBENCH %@ %d px entries=%d %.3f ms", c.name, c.side, c.stack.count, t))
        }
        let frame = 1000 / 120.0
        for s in sides {
            // Each entry's cost is the slope from 18 to 36 entries within one tap count.
            let four = (ms["\(s)-four-36"]! - ms["\(s)-four-18"]!) / 18, two = (ms["\(s)-two-36"]! - ms["\(s)-two-18"]!) / 18
            let base = ms["\(s)-four-0"]!
            say(String(format: "GPUBENCH %d px: an entry %.4f ms four taps, %.4f two (%.2fx); base %.3f; four-tap entries in a 120 Hz frame %.1f; 36 entries %.3f ms four taps, %.3f two; thermal %@",
                       s, four, two, four / two, base, (frame - base) / four, ms["\(s)-four-36"]!, ms["\(s)-two-36"]!, heat()))
            guard let fill = ms["\(s)-fill"] else { continue }
            let id = estuary.id, n = estuary.scramble.count
            say(String(format: "GPUBENCH %d px %@ (glass): fill %.3f ms, %.1f four-tap entries; whole frame %d entries %.3f ms four taps, %.3f two; %d entries %.3f four, %.3f two; of %.3f ms at 120 Hz, %.3f at 60",
                       s, id, fill, fill / four, n, ms["\(s)-\(id)-four-\(n)"]!, ms["\(s)-\(id)-two-\(n)"]!, Tank.maxStack,
                       ms["\(s)-\(id)-four-\(Tank.maxStack)"]!, ms["\(s)-\(id)-two-\(Tank.maxStack)"]!, frame, 2 * frame))
        }
        let base = ms["plain-0"]!, entry = (ms["plain-24"]! - base) / 24
        say(String(format: "GPUBENCH a plain entry, four taps: %.3f ms, by the %@ clock", entry, wallClock ? "wall" : "GPU"))
        var worst = (name: "", ms: 0.0), drift: [Double] = []
        for level in Level.prism {
            let masks = level.scramble.map { Float((level.masks[$0.rod] ?? .white).rawValue) }
            let assumed = Unstirred.channelCost(masks) ?? 0
            let measured = (ms[level.id]! - base) / entry
            drift.append(measured / Double(assumed))
            if ms[level.id]! > worst.ms { worst = (level.id, ms[level.id]!) }
            say(String(format: "GPUBENCH %@ cost assumed %d entries, measured %.1f (white %.1f)", level.id, assumed, measured,
                       (ms["\(level.id)-white"]! - base) / entry))
        }
        drift.sort()
        say(String(format: "GPUBENCH measured / assumed cost: median %.2f, max %.2f; slowest %@ at %.3f ms of the 8.333 ms a 120 Hz frame has; thermal %@",
                   drift[drift.count / 2], drift.last!, worst.name, worst.ms,
                   heat()))
    }
}

/// What a GPU bench launch shows while it runs: nothing to touch.
struct GPUBenchView: View {
    var body: some View {
        Text("timing the shader…").font(.ui(.detail)).foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(.black)
            .task {
                // Past the launch's own work, so it lands in no number.
                try? await Task.sleep(for: .seconds(1))
                await GPUBench.run()
                exit(0)
            }
    }
}
