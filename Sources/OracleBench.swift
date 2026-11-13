// Copyright © 2026 Jack Lusher. All rights reserved.

import ImageIO
import Metal
import MetalKit
import SwiftUI
import UniformTypeIdentifiers

#if PROBES || DEBUG
/// UNSTIR_GPUBENCH=oracle: the twist oracle's timer (`scripts/twist-oracle.sh time`). Each case in UNSTIR_ORACLECASES
/// (`name|UNSTIR_KEY=value ...;name|...`, the harness variables its screenshot is taken with) is built as `LevelView`
/// builds its glass (`frame(of:)`), drawn off screen by every method in `methods` at UNSTIR_ORACLESIDE pixels (1137, the
/// iPhone 13 Pro Max's glass), each method's frame written to tmp/oracle/<method>/<case>.png (today's twins beside it, for the pass rule), and timed in turn with
/// the others, so a slow moment on a shared GPU lands on all of them: one `ORACLE` line a method, its time a frame,
/// the least and most of its rounds, and its share of today's, round by round.
///
/// A way to draw twists faster joins `methods` with the kernels it needs: `draw` encodes one frame into `Frame.out`,
/// and `commit`, where it has one, the work it does once when the committed stack changes (`Frame.committed` entries,
/// the rest in flight), timed apart. Today's shader is `today`, the stitchables' own bodies (`benchUnstir`); `map` is
/// the stored map as the game draws it (`StirMap`, `benchMapped`), its commit the map's drawing, and `map-chain` the
/// map with every tap off its texel run through the chain.
///
/// The picture under the stack is a texture: a baked picture's own bake, and for every live picture the glass's fill at
/// the case's clock (`benchGlass`, the one fill with a kernel), which stands in for the others'. So a line times the
/// twist pass alone; the glass's fill is timed once on its own line. The solve wave isn't drawn.
enum OracleBench {
    static var wanted: Bool { ProcessInfo.processInfo.environment["UNSTIR_GPUBENCH"] == "oracle" }

    struct Frame {
        var name: String
        var side: Int
        var shader: TankShader
        /// The entries below those in flight (the drag, a tick, the breath).
        var committed: Int
        /// The stored map the game would draw this glass from (`StirMap.key`), nil where it draws without one.
        var map: StirMap.Key?
        var args: GPUBench.Args
        var twists, masks, fine: MTLBuffer
        var picture, out: MTLTexture
        var atlas: MTLTexture
    }

    struct Method {
        var name: String
        var commit: ((Frame, MTLComputeCommandEncoder) -> Void)?
        var draw: (Frame, MTLComputeCommandEncoder) -> Void
    }

    static let group = MTLSize(width: 16, height: 16, depth: 1)

    static func methods(_ device: MTLDevice, _ library: MTLLibrary) throws -> [Method] {
        let pipeline = try device.makeComputePipelineState(function: library.makeFunction(name: "benchUnstir")!)
        func today(_ f: Frame, _ enc: MTLComputeCommandEncoder) {
            do {
                var args = f.args
                enc.setComputePipelineState(pipeline)
                enc.setTexture(f.picture, index: 0)
                enc.setTexture(f.out, index: 1)
                enc.setTexture(f.atlas, index: 2)
                enc.setBuffer(f.twists, offset: 0, index: 0)
                enc.setBuffer(f.masks, offset: 0, index: 1)
                enc.setBytes(&args, length: MemoryLayout<GPUBench.Args>.stride, index: 2)
                enc.setBuffer(f.fine, offset: 0, index: 3)
                enc.dispatchThreads(MTLSize(width: f.side, height: f.side, depth: 1), threadsPerThreadgroup: group)
            }
        }
        // The stored map (`unstirMappedBody`) as the game draws it, `map`, and with every tap off its texel run through
        // the chain, `map-chain`. A glass the game draws without a map draws as today in both.
        let stir = try device.makeComputePipelineState(function: library.makeFunction(name: "stirMap")!)
        let mapped = try device.makeComputePipelineState(function: library.makeFunction(name: "benchMapped")!)
        final class Maps { var made: [String: MTLTexture] = [:] }
        let maps = Maps()
        func commit(_ f: Frame, _ enc: MTLComputeCommandEncoder) {
            guard let key = f.map else { return }
            let map = maps.made[f.name] ?? {
                let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 2 * f.side, height: 2 * f.side, mipmapped: false)
                desc.usage = [.shaderRead, .shaderWrite]
                return device.makeTexture(descriptor: desc)!
            }()
            maps.made[f.name] = map
            var m = StirMap.args(key)
            enc.setComputePipelineState(stir)
            enc.setTexture(map, index: 0)
            enc.setBuffer(f.twists, offset: 0, index: 0)
            enc.setBytes(&m, length: MemoryLayout<StirMap.Args>.stride, index: 1)
            enc.dispatchThreads(MTLSize(width: f.side, height: f.side, depth: 1), threadsPerThreadgroup: group)
        }
        func draw(_ mode: StirMap.Mode) -> (Frame, MTLComputeCommandEncoder) -> Void {
            { f, enc in
                guard let key = f.map, let map = maps.made[f.name] else { return today(f, enc) }
                var a = f.args, m = StirMap.args(key, mode: mode)
                enc.setComputePipelineState(mapped)
                enc.setTexture(f.picture, index: 0)
                enc.setTexture(f.out, index: 1)
                enc.setTexture(map, index: 3)
                enc.setBuffer(f.twists, offset: 0, index: 0)
                enc.setBytes(&a, length: MemoryLayout<GPUBench.Args>.stride, index: 2)
                enc.setBytes(&m, length: MemoryLayout<StirMap.Args>.stride, index: 4)
                enc.dispatchThreads(MTLSize(width: f.side, height: f.side, depth: 1), threadsPerThreadgroup: group)
            }
        }
        return [
            Method(name: "today", draw: today),
            Method(name: "map", commit: commit, draw: draw(.mix)),
            Method(name: "map-chain", draw: draw(.chain)),
        ]
    }

    /// The glass a harness launch with `env` draws, as `LevelView.tank` builds it, `side` points across.
    @MainActor static func glass(_ env: [String: String], side: CGFloat, scale: CGFloat) -> (level: Level, glass: Unstirred, committed: Int, map: StirMap.Key?) {
        let h = Harness(env), level = h.level
        let game = Game(level: level, tankTurned: h.tankTurned, swirled: h.swirled, bank: h.bank, storesProgress: false)
        game.turnTank(h.tank)
        if let t = h.turned { game.commit(rod: t.rod, steps: t.steps) }
        for m in h.played {
            if level.kind(of: m.rod) == .ratchet { game.wait(on: m.rod) } else { game.commit(rod: m.rod, steps: m.steps) }
        }
        let live = h.live.map { (slot: game.slot(of: $0.rod), angle: $0.steps * Tank.step) }
        let turn = Double(game.position) * level.layout.tankStep
        var u = Unstirred(stack: h.bare ? [] : game.stack, layout: level.layout, lenses: level.lenses, masks: level.masks,
                          liveRod: live?.slot, liveAngle: live?.angle ?? 0, wind: h.wind ?? 1, side: side, turn: turn,
                          fillEntries: level.picture.fillEntries, isolate: h.swatch,
                          held: live.map { level.masks[$0.slot] ?? .white }, hold: live == nil ? 0 : 1,
                          budget: env["UNSTIR_TAPS"].flatMap(Int.init), crisp: 1)
        if let p = h.tickAt, p < Double(game.tick.count) {
            let i = Int(max(p, 0)), t = game.tick[i]
            u.stack = t.stack
            u.tick = (t.rod, LevelView.flight(p, i) * Double(t.dir) * Tank.step)
        }
        if let s = h.breath, game.breathes, let swirl = level.layout.swirl {
            u.breath = (game.slot(of: swirl), Breath(start: 0, wait: Breath.first).angle(at: s))
        }
        // The committed glass's map, as `HeldUnstirred` asks for it, then the rim's turn in hand.
        let map = StirMap.key(u, scale: scale)
        u.turn += (h.tankLive ?? 0) * .pi / 180
        return (level, u, u.stack.count, map)
    }

    @MainActor static func run() async {
        func say(_ line: String) {
            print(line)
            Log.write(line)
        }
        let env = ProcessInfo.processInfo.environment, scale = GPUBench.scale
        let side = env["UNSTIR_ORACLESIDE"].flatMap(Int.init) ?? Int(Tank.tunedPixels.rounded())
        let points = CGFloat(side) / scale
        guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary(), let methods = try? methods(device, library),
              let fill = try? await device.makeComputePipelineState(function: library.makeFunction(name: "benchGlass")!) else {
            say("ORACLE no Metal")
            return
        }
        func texture(_ pixels: [UInt8], _ width: Int, _ height: Int, usage: MTLTextureUsage = .shaderRead) -> MTLTexture {
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
            desc.usage = usage
            let t = device.makeTexture(descriptor: desc)!
            if !pixels.isEmpty {
                t.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: pixels, bytesPerRow: 4 * width)
            }
            return t
        }
        func buffer(_ floats: [Float]) -> MTLBuffer { device.makeBuffer(bytes: floats, length: 4 * floats.count)! }
        var wallClock = false
        /// Seconds a pass of `reps` encodings of `work` takes: the GPU's own clock, or in the simulator, whose command
        /// buffers carry none, the wall clock round the buffer.
        func time(_ reps: Int, _ work: (MTLComputeCommandEncoder) -> Void) -> Double {
            let cb = queue.makeCommandBuffer()!, enc = cb.makeComputeCommandEncoder()!
            for _ in 0..<reps { work(enc) }
            enc.endEncoding()
            let start = CACurrentMediaTime()
            cb.commit()
            cb.waitUntilCompleted()
            let wall = CACurrentMediaTime() - start, gpu = cb.gpuEndTime - cb.gpuStartTime
            if gpu < wall / 4 { wallClock = true }
            return (wallClock ? wall : gpu) / Double(reps)
        }
        func fillGlass(_ into: MTLTexture, clock: Double, seed: Int) -> (MTLComputeCommandEncoder) -> Void {
            let cells = buffer(Picture.glass.data(seed: seed, clock: clock) ?? [0])
            var args = GPUBench.GlassArgs(radius: Float(points / 2), px: Float(2 / Double(side)), scale: Float(scale), t: Float(clock))
            return { enc in
                enc.setComputePipelineState(fill)
                enc.setTexture(into, index: 0)
                enc.setBuffer(cells, offset: 0, index: 0)
                enc.setBytes(&args, length: MemoryLayout<GPUBench.GlassArgs>.stride, index: 1)
                enc.dispatchThreads(MTLSize(width: side, height: side, depth: 1), threadsPerThreadgroup: group)
            }
        }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("oracle")
        try? FileManager.default.removeItem(at: out)
        let loader = MTKTextureLoader(device: device)
        var filled = false
        say("ORACLE start \(side) px, thermal \(["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue])")
        for spec in (env["UNSTIR_ORACLECASES"] ?? "").split(separator: ";") {
            let parts = spec.split(separator: "|", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let name = String(parts[0])
            let vars = Dictionary(parts[1].split(separator: " ").compactMap { kv -> (String, String)? in
                let f = kv.split(separator: "=", maxSplits: 1)
                return f.count == 2 ? (String(f[0]), String(f[1])) : nil
            }, uniquingKeysWith: { $1 })
            let (level, glass, committed, map) = glass(vars, side: points, scale: scale)
            var shader = glass.shader(scale: scale)
            let clock = vars["UNSTIR_CLOCK"].flatMap(Double.init) ?? 0, seed = Int(level.label) ?? 0
            let picture: MTLTexture
            if level.picture.isLive {
                picture = texture([], side, side, usage: [.shaderRead, .shaderWrite])
                let work = fillGlass(picture, clock: clock, seed: seed)
                _ = time(1, work)
                if !filled {
                    let runs = (0..<9).map { _ in time(10, work) }.sorted()
                    say(String(format: "ORACLE the glass's fill %.3f ms (%.3f to %.3f), once a frame under every live picture's line", runs[4] * 1000, runs[0] * 1000, runs[8] * 1000))
                    filled = true
                }
            } else {
                guard let image = await level.picture.render(side: points, scale: scale, panel: level.plate)?.cgImage,
                      let t = try? await loader.newTexture(cgImage: image, options: [.SRGB: false]) else {
                    say("ORACLE \(name) no picture")
                    continue
                }
                picture = t
            }
            var atlas = texture([0, 0, 0, 0], 1, 1), table: [Float] = [0]
            if level.picture == .halftone, !level.lenses.isEmpty, shader.prism == nil {
                let panel = Halftone.panel(level.panel), rods = level.lenses.sorted().map { level.layout.rods[$0] }
                let detail = await Task.detached(priority: .userInitiated) { panel.detail(side, lenses: rods) }.value
                atlas = texture(detail.pixels, detail.width, detail.height)
                shader.fine = Fine(detail)
                table = detail.table
                table[Fine.share] = 1
            }
            let twists = shader.twists.isEmpty ? [0, 0, 0, 0] : shader.twists
            let masks = shader.prism?.masks ?? [Float](repeating: 7, count: twists.count / 4)
            let tint = shader.prism?.tint ?? SIMD3(1, 1, 1)
            let args = GPUBench.Args(radius: Float(points / 2), scale: Float(scale), n: Float(shader.twists.count / 4),
                                     fourTaps: shader.fourTaps, cost: Float(shader.prism?.cost ?? 0),
                                     plateau: Float(shader.plateau), swirlPlateau: Float(shader.swirlPlateau),
                                     lensEdge: Float(shader.lensEdge), held: Float(shader.prism?.held?.rawValue ?? 0),
                                     hold: shader.prism?.hold ?? 0, turn: Float(shader.turn), haze: Float(shader.haze),
                                     isolate: Float(shader.prism?.isolate?.rawValue ?? 0), tintR: tint.x, tintG: tint.y, tintB: tint.z,
                                     count: Int32(twists.count), maskCount: Int32(masks.count),
                                     channels: shader.prism == nil ? 0 : 1, fineCount: shader.fine == nil ? 0 : Int32(table.count))
            let frame = Frame(name: name, side: side, shader: shader, committed: committed, map: map, args: args, twists: buffer(twists),
                              masks: buffer(masks), fine: buffer(table), picture: picture,
                              out: texture([], side, side, usage: [.shaderRead, .shaderWrite]), atlas: atlas)
            // Each method's frame, written before any is timed, then every method timed in turn, round by round.
            var commits: [Double?] = []
            for m in methods {
                commits.append(m.commit.map { c in (0..<5).map { _ in time(1) { c(frame, $0) } }.sorted()[2] })
                _ = time(3) { m.draw(frame, $0) }
                write(frame.out, to: out.appendingPathComponent(m.name).appendingPathComponent("\(name).png"))
            }
            // Enough frames a buffer that today's takes some 30 ms: a cheap frame's buffer is otherwise mostly its own
            // overhead, by the wall clock.
            let reps = min(max(Int(0.03 / time(10) { methods[0].draw(frame, $0) }), 10), 300)
            // Today's frame twice more as the pass rule's twins, the stir a tenth of a pixel along each axis, one way and
            // the other (`Unstirred.nudge`).
            for (folder, y) in [("twin", Float(0.1)), ("twin2", -0.1)] {
                var twin = frame
                (twin.args.nudgeX, twin.args.nudgeY) = (0.1, y)
                _ = time(1) { methods[0].draw(twin, $0) }
                write(frame.out, to: out.appendingPathComponent(methods[0].name).appendingPathComponent("\(folder)/\(name).png"))
            }
            var rounds = [[Double]](repeating: [], count: methods.count)
            for _ in 0..<15 {
                for (k, m) in methods.enumerated() { rounds[k].append(time(reps) { m.draw(frame, $0) }) }
            }
            for (k, m) in methods.enumerated() {
                let sorted = rounds[k].sorted(), ratios = zip(rounds[k], rounds[0]).map { $0 / $1 }.sorted()
                say(String(format: "ORACLE %@ %@ frame %.3f ms (%.3f to %.3f) x%.3f of today, %d entries %d committed, %@ taps%@",
                           name, m.name, sorted[7] * 1000, sorted[0] * 1000, sorted[14] * 1000, ratios[7],
                           shader.twists.count / 4, committed,
                           (shader.prism.map { Float($0.cost) } ?? Float(shader.twists.count / 4)) > shader.fourTaps ? "two" : "four",
                           commits[k].map { String(format: ", commit %.3f ms", $0 * 1000) } ?? ""))
            }
        }
        say("ORACLE done, by the \(wallClock ? "wall" : "GPU") clock, thermal \(["nominal", "fair", "serious", "critical"][ProcessInfo.processInfo.thermalState.rawValue]), frames in \(out.path)")
    }

    static func write(_ texture: MTLTexture, to url: URL) {
        let w = texture.width, h = texture.height
        var bytes = [UInt8](repeating: 0, count: 4 * w * h)
        texture.getBytes(&bytes, bytesPerRow: 4 * w, from: MTLRegionMake2D(0, 0, w, h), mipmapLevel: 0)
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 4 * w,
                                  space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                                  provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
              let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, image, nil)
        CGImageDestinationFinalize(dest)
    }
}

/// What an oracle bench launch shows while it runs.
struct OracleBenchView: View {
    var body: some View {
        Text(verbatim: "timing the oracle's cases…").font(.ui(.detail)).foregroundStyle(.white)
            .frame(maxWidth: .infinity, maxHeight: .infinity).background(.black)
            .task {
                try? await Task.sleep(for: .seconds(1))
                await OracleBench.run()
                exit(0)
            }
    }
}
#endif

/// What a launch shows in place of the game where the build holds a probe (Debug, or PROBES=YES) and the launch asks
/// for it; a plain Release build compiles the probes out.
@MainActor enum Probes {
    static var screen: AnyView? {
        #if PROBES || DEBUG
        if OracleBench.wanted { return AnyView(OracleBenchView()) }
        #endif
        return nil
    }
}
