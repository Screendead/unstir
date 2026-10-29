// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import MetalKit
import SwiftUI

/// UNSTIR_GPUBENCH=1: times the tank's shader on the GPU's own clock, off screen, then quits. The display-link bench
/// (UNSTIR_BENCH) sees only main-thread stalls; this runs the stitchables' own bodies (`benchUnstir` in Unstir.metal) on
/// a texture of the picture at the largest phone's tank, 1284 device pixels across, and reads each command buffer's GPU
/// start and end. It prints and logs one line a case (`scripts/gpu-bench.sh`, or `scripts/pull-log.sh` off the phone):
/// a plain stack at 0 and 24 entries for a stack entry's cost, then every Prism specimen as dealt through the
/// per-channel shader and, for comparison, the same stack read white through the plain one.
enum GPUBench {
    static var wanted: Bool { ProcessInfo.processInfo.environment["UNSTIR_GPUBENCH"] == "1" }

    /// The largest phone's tank: 428 points at 3x.
    static let points = 428.0, scale = 3.0

    struct Case {
        var name: String
        var picture: Picture
        var layout: Layout
        var stack: [Twist]
        var masks: [Int: Channels]
        var channels: Bool
    }

    struct Args {
        var radius, scale, n, fourTaps, cost, plateau, swirlPlateau, lensEdge: Float
        var count, maskCount, channels: Int32
    }

    @MainActor static func run() async {
        @MainActor func say(_ line: String) {
            print(line)
            Log.write(line)
        }
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(), let function = library.makeFunction(name: "benchUnstir"),
              let pipeline = try? await device.makeComputePipelineState(function: function) else {
            say("GPUBENCH no Metal")
            return
        }
        let side = Int(points * scale)
        var textures: [Picture: MTLTexture] = [:]
        let loader = MTKTextureLoader(device: device)
        for picture in Set([Picture.grid] + Level.prism.map(\.picture)) {
            guard let image = await picture.render(side: points, scale: scale)?.cgImage,
                  let t = try? await loader.newTexture(cgImage: image, options: [.SRGB: false]) else {
                say("GPUBENCH no picture \(picture.rawValue)")
                return
            }
            textures[picture] = t
        }
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: side, height: side, mipmapped: false)
        desc.usage = .shaderWrite
        guard let out = device.makeTexture(descriptor: desc) else { return }

        var rng = SplitMix64(state: 24)
        let deep = Layout.eye.scramble(depth: 24, inversions: 6, rng: &rng)
        var cases = [Case(name: "plain-0", picture: .grid, layout: .eye, stack: [], masks: [:], channels: false),
                     Case(name: "plain-24", picture: .grid, layout: .eye, stack: deep, masks: [:], channels: false)]
        for level in Level.prism {
            cases.append(Case(name: level.id, picture: level.picture, layout: level.layout, stack: level.scramble,
                              masks: level.masks, channels: true))
            cases.append(Case(name: "\(level.id)-white", picture: level.picture, layout: level.layout, stack: level.scramble,
                              masks: [:], channels: false))
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
            var args = Args(radius: Float(points / 2), scale: Float(scale), n: Float(n), fourTaps: Float(Tank.fourTaps),
                            cost: Float(cost), plateau: Float(Tank.plateau), swirlPlateau: Float(Tank.swirlPlateau),
                            lensEdge: Float(Tank.lensEdge), count: Int32(floats.count), maskCount: Int32(masks.count),
                            channels: c.channels ? 1 : 0)
            let twists = device.makeBuffer(bytes: floats, length: 4 * floats.count)!
            let maskBuffer = device.makeBuffer(bytes: masks, length: 4 * masks.count)!
            func buffer(_ reps: Int) -> Double {
                let cb = queue.makeCommandBuffer()!, enc = cb.makeComputeCommandEncoder()!
                enc.setComputePipelineState(pipeline)
                enc.setTexture(textures[c.picture], index: 0)
                enc.setTexture(out, index: 1)
                enc.setBuffer(twists, offset: 0, index: 0)
                enc.setBuffer(maskBuffer, offset: 0, index: 1)
                enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 2)
                for _ in 0..<reps {
                    enc.dispatchThreads(MTLSize(width: side, height: side, depth: 1),
                                        threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
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

        let heat = ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]
        say("GPUBENCH start, \(side) px, thermal \(heat)")
        var ms: [String: Double] = [:]
        for c in cases {
            let t = time(c) * 1000
            ms[c.name] = t
            say(String(format: "GPUBENCH %@ entries=%d %.3f ms", c.name, c.stack.count, t))
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
                   ["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]))
    }
}

/// What a GPU bench launch shows while it runs: nothing to touch.
struct GPUBenchView: View {
    var body: some View {
        Text("timing the shader…").font(.mono(13)).foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(.black)
            .task {
                // Past the launch's own work, so it lands in no number.
                try? await Task.sleep(for: .seconds(1))
                await GPUBench.run()
                exit(0)
            }
    }
}
