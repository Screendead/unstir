// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import XCTest
import simd
@testable import Unstir

/// `unstirLens`, a Lens level's glass: the panel drawn finer where a lens magnifies it (`Halftone.Detail`), and
/// `unstir` to the bit everywhere else. Both bodies run as kernels on a texture, as the GPU bench runs them.
final class LensDetailTests: XCTestCase {
    /// A Pro Max's glass, where a hairline is about a pixel and a half: the detail's density is set against that.
    static let n = 1171, scale = 3.0

    private static let kernels = """
        struct TestLayer {
            texture2d<half> picture;
            float pixels;
            half4 sample(float2 p) const {
                constexpr sampler s(filter::linear, address::clamp_to_zero, coord::pixel);
                return picture.sample(s, p * pixels);
            }
        };
        struct DrawArgs {
            float radius, scale, n, fourTaps, plateau, swirlPlateau, lensEdge;
            int count, fineCount;
        };
        kernel void draw(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                         texture2d<half> atlas [[texture(2)]], device const float *twists [[buffer(0)]],
                         constant DrawArgs &a [[buffer(1)]], device const float *fine [[buffer(2)]],
                         uint2 gid [[thread_position_in_grid]]) {
            TestLayer layer = { picture, a.scale };
            float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius);
            out.write(a.fineCount != 0
                ? unstirLensBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                                 a.lensEdge, a.scale, 0.0, float3(0, 0, -1), 0.0, atlas, fine, a.fineCount)
                : unstirBody(pos, layer, centre, a.radius, twists, a.count, a.n, a.fourTaps, a.plateau, a.swirlPlateau,
                             a.lensEdge, a.scale, 0.0, float3(0, 0, -1), 0.0), gid);
        }
        """

    private struct DrawArgs {
        var radius, scale, n, fourTaps, plateau, swirlPlateau, lensEdge: Float
        var count, fineCount: Int32
    }

    /// A glass of `n` pixels drawn off screen: `picture` (RGBA8, the layer) through `stack`, by `unstirLens` with
    /// `detail` and its `table`, or by `unstir` without.
    private struct Glass {
        let kit: ShaderKit
        let pipeline: MTLComputePipelineState
        let n = LensDetailTests.n

        init() throws {
            kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: LensDetailTests.kernels)
            pipeline = try kit.pipeline("draw")
        }

        func texture(_ pixels: [UInt8], _ width: Int, _ height: Int, write: Bool = false) throws -> MTLTexture {
            let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
            desc.usage = write ? [.shaderWrite, .shaderRead] : .shaderRead
            let t = try XCTUnwrap(kit.device.makeTexture(descriptor: desc))
            if !write {
                t.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: pixels, bytesPerRow: 4 * width)
            }
            return t
        }

        func draw(_ picture: MTLTexture, stack: [Twist], layout: Layout, lenses: Set<Int>, detail: Halftone.Detail? = nil,
                  table: [Float]? = nil, fourTaps: Float = 40) throws -> [UInt8] {
            let turns = stack.map { (rod: $0.rod, angle: Double($0.steps) * Tank.step) }
            var twists = Unstirred.entries(turns, layout: layout, lenses: lenses, masks: [:]).twists
            let count = twists.count
            if twists.isEmpty { twists = [0, 0, 0, 0] }
            let fine: [Float] = table ?? detail?.table ?? [0]
            var args = DrawArgs(radius: Float(Double(n) / LensDetailTests.scale / 2), scale: Float(LensDetailTests.scale),
                                n: Float(count / 4), fourTaps: fourTaps, plateau: Float(Tank.plateau),
                                swirlPlateau: Float(Tank.swirlPlateau), lensEdge: Float(Tank.lensEdge), count: Int32(count),
                                fineCount: detail == nil ? 0 : Int32(fine.count))
            let out = try texture([], n, n, write: true)
            let atlas = try detail.map { try texture($0.pixels, $0.width, $0.height) } ?? texture([0, 0, 0, 255], 1, 1)
            let twistBuffer = try kit.buffer(twists), fineBuffer = try kit.buffer(fine)
            try kit.run(pipeline, grid: MTLSize(width: n, height: n, depth: 1), group: MTLSize(width: 16, height: 16, depth: 1)) { enc in
                enc.setTexture(picture, index: 0)
                enc.setTexture(out, index: 1)
                enc.setTexture(atlas, index: 2)
                enc.setBuffer(twistBuffer, offset: 0, index: 0)
                enc.setBytes(&args, length: MemoryLayout<DrawArgs>.stride, index: 1)
                enc.setBuffer(fineBuffer, offset: 0, index: 2)
            }
            var pixels = [UInt8](repeating: 0, count: 4 * n * n)
            out.getBytes(&pixels, bytesPerRow: 4 * n, from: MTLRegionMake2D(0, 0, n, n), mipmapLevel: 0)
            return pixels
        }
    }

    /// `panel`'s bake at `n`, as `Halftone.Panel.pixels` writes it, but only within `reach` of `centre` (tank units), the
    /// rest black: a whole panel takes an unoptimised build 20 s.
    private func bake(_ panel: Halftone.Panel, around centre: SIMD2<Double>, reach: Double) -> [UInt8] {
        let n = Self.n, px = 2 / Double(n)
        var out = [UInt8](repeating: 0, count: 4 * n * n)
        for j in 0..<n {
            let y = (Double(j) + 0.5) * px - 1
            guard abs(y - centre.y) <= reach else { continue }
            for i in 0..<n {
                let x = (Double(i) + 0.5) * px - 1
                guard abs(x - centre.x) <= reach else { continue }
                let c = panel.light(SIMD2(x, y), aa: px), k = 4 * (j * n + i)
                out[k] = UInt8(Halftone.gamma(c.x) * 255 + 0.5)
                out[k + 1] = UInt8(Halftone.gamma(c.y) * 255 + 0.5)
                out[k + 2] = UInt8(Halftone.gamma(c.z) * 255 + 0.5)
                out[k + 3] = 255
            }
        }
        return out
    }

    /// Where nothing magnifies both ways, a Lens level's glass is `unstir`'s to the byte: the clean panel, twists, a
    /// lens zoomed out, with four taps and with two. Under a lens zoomed in, only its core differs.
    func testALensGlassDrawsAsBeforeWhereNothingMagnifies() throws {
        let glass = try Glass(), n = Self.n
        var rng = SplitMix64(state: 11)
        let noise = (0..<4 * n * n).map { _ in UInt8(truncatingIfNeeded: rng.next()) }
        let picture = try glass.texture(noise, n, n)
        let layout = Layout.tri, lenses: Set<Int> = [0], rod = layout.rods[0]
        let detail = Halftone.test.detail(n, lenses: [rod])
        for taps: Float in [40, -1] {
            for stack in ["", "1:+3,2:-4", "0:-2", "1:+5,0:-3,2:+2"] {
                let twists = [Twist].parse(stack, in: layout, lenses: lenses)
                let before = try glass.draw(picture, stack: twists, layout: layout, lenses: lenses, fourTaps: taps)
                let after = try glass.draw(picture, stack: twists, layout: layout, lenses: lenses, detail: detail, fourTaps: taps)
                XCTAssertTrue(before == after, "\(stack), fourTaps \(taps)")
            }
            let zoomed = [Twist].parse("1:+5,0:+3", in: layout, lenses: lenses)
            let before = try glass.draw(picture, stack: zoomed, layout: layout, lenses: lenses, fourTaps: taps)
            let after = try glass.draw(picture, stack: zoomed, layout: layout, lenses: lenses, detail: detail, fourTaps: taps)
            var outside = 0, inside = 0
            let core = Tank.plateau * rod.z
            for j in 0..<n {
                for i in 0..<n where (0..<4).contains(where: { before[4 * (j * n + i) + $0] != after[4 * (j * n + i) + $0] }) {
                    let p = SIMD2((Double(i) + 0.5) * 2 / Double(n) - 1, (Double(j) + 0.5) * 2 / Double(n) - 1)
                    if simd_distance(p, SIMD2(rod.x, rod.y)) < core { inside += 1 } else { outside += 1 }
                }
            }
            XCTAssertEqual(outside, 0, "fourTaps \(taps)")
            XCTAssertGreaterThan(inside, 10_000, "fourTaps \(taps)")
        }
    }

    /// The detail is the bake's own geometry: with its weight forced to all at the panel's own size, where a pixel's
    /// footprint is a bake pixel, the shader draws Keyhole's panel as `Halftone.Panel.light` baked it, to a level's
    /// rounding but for the few pixels where a stroke's corner or the dots' radii, a byte each, round differently.
    func testTheDetailAtThePanelsOwnSizeIsTheBake() throws {
        let glass = try Glass(), n = Self.n
        let level = Level.lens[0], rod = level.layout.rods[0], centre = SIMD2(rod.x, rod.y)
        let panel = Halftone.panel(level.panel)
        // The middle of the inset, where the keyhole and its eye are: a wider bake only takes longer.
        let inner = 0.3 * Tank.plateau * rod.z
        let baked = bake(panel, around: centre, reach: inner)
        let detail = panel.detail(n, lenses: [rod])
        var table = detail.table
        // No footprint is long enough to fade the detail out.
        (table[6], table[7]) = (2, 3)
        let drawn = try glass.draw(try glass.texture(baked, n, n), stack: [], layout: level.layout, lenses: level.lenses,
                                   detail: detail, table: table)
        var sum = 0, count = 0, far = 0
        for j in 0..<n {
            for i in 0..<n {
                let p = SIMD2((Double(i) + 0.5) * 2 / Double(n) - 1, (Double(j) + 0.5) * 2 / Double(n) - 1) - centre
                guard max(abs(p.x), abs(p.y)) < inner - 2.0 / Double(n) else { continue }
                for c in 0..<3 {
                    let d = abs(Int(drawn[4 * (j * n + i) + c]) - Int(baked[4 * (j * n + i) + c]))
                    sum += d
                    count += 1
                    if d > 24 { far += 1 }
                }
            }
        }
        XCTAssertGreaterThan(count, 40_000)
        XCTAssertLessThan(Double(sum) / Double(count), 0.6, "mean difference in levels")
        XCTAssertLessThan(Double(far) / Double(count), 0.002, "share of samples more than 24 levels off")
    }

    /// The panel's light at a glass pixel through `stack`, as a perfect draw would have it: the mean of `k` by `k`
    /// samples, each mapped back through the stack and read off the panel's geometry far finer than a pixel.
    private func truth(_ panel: Halftone.Panel, stack: [Twist], layout: Layout, lenses: Set<Int>, pixel: (x: Int, y: Int),
                       k: Int = 3) -> SIMD3<Double> {
        let px = 2 / Double(Self.n), rods = layout.rods
        var sum = SIMD3<Double>(repeating: 0)
        for v in 0..<k {
            for u in 0..<k {
                var q = SIMD2((Double(pixel.x) + (Double(u) + 0.5) / Double(k)) * px - 1,
                              (Double(pixel.y) + (Double(v) + 0.5) / Double(k)) * px - 1)
                for t in stack.reversed() {
                    q = lenses.contains(t.rod) ? Tank.lens(q, rod: rods[t.rod], steps: -Double(t.steps))
                        : Tank.twist(q, rod: rods[t.rod], angle: -Double(t.steps) * Tank.step)
                }
                sum += panel.light(q, aa: px / 64)
            }
        }
        return sum / Double(k * k)
    }

    /// Keyhole's lens at x8 over a five-step twist: `unstir` draws the bake's pixels eight times their size, and
    /// `unstirLens` draws what is there at the screen's own pitch, with four taps and with two. Measured over the
    /// window of the glass that holds the keyhole's eye, against the panel's geometry sampled nine times a pixel: the
    /// mean error in levels, and how steep the steepest edges are, a pixel to the next.
    func testALensAtX8DrawsItsPanelAtTheScreensPitch() throws {
        let glass = try Glass(), n = Self.n
        let level = Level.lens[0], rod = level.layout.rods[0], centre = SIMD2(rod.x, rod.y)
        let panel = Halftone.panel(level.panel)
        // At x8 the window shows fluid from within a fifth of the core's radius.
        let picture = try glass.texture(bake(panel, around: centre, reach: 0.25 * Tank.plateau * rod.z), n, n)
        let detail = panel.detail(n, lenses: [rod])
        let cx = Int((centre.x + 1) / 2 * Double(n)), cy = Int((centre.y + 1) / 2 * Double(n))
        let window = (x: (cx - 48)..<(cx + 48), y: (cy - 162)..<(cy - 114))
        func luma(_ c: SIMD3<Double>) -> Double { 0.299 * c.x + 0.587 * c.y + 0.114 * c.z }
        let stack = [Twist].parse("1:+5,0:+3", in: level.layout, lenses: level.lenses)
        var want: [SIMD3<Double>] = []
        for y in window.y {
            for x in window.x {
                let t = truth(panel, stack: stack, layout: level.layout, lenses: level.lenses, pixel: (x, y))
                want.append(SIMD3(Halftone.gamma(t.x), Halftone.gamma(t.y), Halftone.gamma(t.z)) * 255)
            }
        }
        let width = window.x.count
        /// A draw's mean error in levels, and its mean step, a pixel to the next along a row, over the steepest
        /// hundredth of the truth's steps, beside the truth's own.
        func measure(_ drawn: [UInt8]) -> (error: Double, edge: Double, trueEdge: Double) {
            var got: [SIMD3<Double>] = []
            for y in window.y {
                for x in window.x {
                    let k = 4 * (y * n + x)
                    got.append(SIMD3(Double(drawn[k]), Double(drawn[k + 1]), Double(drawn[k + 2])))
                }
            }
            let error = zip(got, want).reduce(0) { $0 + simd_reduce_add(simd_abs($1.0 - $1.1)) / 3 } / Double(want.count)
            var steps: [(truth: Double, own: Double)] = []
            for i in want.indices where i % width != 0 {
                steps.append((abs(luma(want[i]) - luma(want[i - 1])), abs(luma(got[i]) - luma(got[i - 1]))))
            }
            steps.sort { $0.truth > $1.truth }
            let top = steps.prefix(steps.count / 100)
            return (error, top.reduce(0) { $0 + $1.own } / Double(top.count), top.reduce(0) { $0 + $1.truth } / Double(top.count))
        }
        for taps: Float in [40, -1] {
            let before = measure(try glass.draw(picture, stack: stack, layout: level.layout, lenses: level.lenses, fourTaps: taps))
            let after = measure(try glass.draw(picture, stack: stack, layout: level.layout, lenses: level.lenses, detail: detail,
                                               fourTaps: taps))
            print("LENSDETAIL fourTaps \(taps): mean error \(before.error) levels before, \(after.error) after; steepest edges \(after.trueEdge) truth, \(before.edge) before, \(after.edge) after")
            XCTAssertLessThan(after.error, 3, "fourTaps \(taps)")
            XCTAssertGreaterThan(before.error, 5 * after.error, "fourTaps \(taps)")
            XCTAssertGreaterThan(after.edge, 0.9 * after.trueEdge, "fourTaps \(taps)")
            XCTAssertLessThan(before.edge, 0.3 * after.trueEdge, "fourTaps \(taps)")
        }
    }
}
