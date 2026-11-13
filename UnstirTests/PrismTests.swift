// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import MetalKit
import UIKit
import XCTest
import simd
@testable import Unstir

/// Prism's channel masks: a stir moves only its rod's channels, so commutation and the win are judged per channel.
final class PrismTests: XCTestCase {
    private let redCyan: [Int: Channels] = [0: .red, 1: .cyan]

    /// A knob spells its channels in the swatches' letters, so a mask reads without telling its colour.
    func testEveryMaskSpellsItsPrimaries() {
        XCTAssertEqual([Channels.red, .green, .blue, .cyan, .magenta, .yellow, .white].map(\.letters),
                       ["R", "G", "B", "GB", "RB", "RG", "RGB"])
        XCTAssertEqual(Level.prism[0].channels(of: 1), .cyan)
        XCTAssertNil(Level.lens[0].channels(of: 0))
    }

    func testMasksParse() {
        XCTAssertEqual(Channels.masks("0:r,1:C,2:w"), [0: .red, 1: .cyan, 2: .white])
        XCTAssertEqual(Channels.masks(""), [:])
        XCTAssertNil(Channels.masks("0:x"))
        XCTAssertNil(Channels.masks("0:rg"))
        XCTAssertEqual([Channels.red, .green, .blue, .cyan, .magenta, .yellow, .white].compactMap(\.letter),
                       ["r", "g", "b", "c", "m", "y", "w"])
    }

    /// Tri's rods 0 and 1 overlap, so their turns fail to commute on a white picture, and commute once their masks share
    /// no channel.
    func testOverlappingEntriesWithDisjointMasksCommute() {
        let layout = Layout.tri, a = Twist(rod: 0, steps: 3), b = Twist(rod: 1, steps: 4)
        XCTAssertTrue(layout.overlaps(0, 1))
        XCTAssertFalse(layout.same([a, b], [b, a], at: Tank.samples, within: 1e-6))
        XCTAssertTrue(layout.same([a, b], [b, a], at: Tank.samples, within: 1e-6, masks: redCyan))
        XCTAssertFalse(layout.same([a, b], [b, a], at: Tank.samples, within: 1e-6, masks: [0: .red, 1: .magenta]))
        XCTAssertTrue(layout.commutes([a, b], above: 0, rod: 0, steps: -3, masks: redCyan))
        XCTAssertFalse(layout.commutes([a, b], above: 0, rod: 0, steps: -3, masks: [0: .red, 1: .yellow]))
        XCTAssertFalse(layout.commutes([a, b], above: 0, rod: 0, steps: -3))
    }

    /// A shared channel still commutes where the maps do on it: hex's hub and its swirl share a centre.
    func testASharedChannelCommutesWhereItsMapsDo() {
        let layout = Layout.hexSwirl, hub = Twist(rod: 0, steps: 2), swirl = Twist(rod: 7, steps: 3), rim = Twist(rod: 1, steps: 3)
        XCTAssertTrue(layout.commutes([hub, swirl], above: 0, rod: 0, steps: -2, masks: [0: .red, 7: .yellow]))
        XCTAssertFalse(layout.commutes([rim, swirl], above: 0, rod: 1, steps: -3, masks: [1: .red, 7: .yellow]))
        XCTAssertTrue(layout.commutes([rim, swirl], above: 0, rod: 1, steps: -3, masks: [1: .red, 7: .cyan]))
    }

    func testAnEntryMergesOnlyAsItsChannelsAllow() {
        XCTAssertEqual([Twist].parse("0:+3,1:+4,0:-1", in: .tri, masks: redCyan),
                       [Twist(rod: 0, steps: 2), Twist(rod: 1, steps: 4)])
        XCTAssertEqual([Twist].parse("0:+3,1:+4,0:-1", in: .tri, masks: [0: .red, 1: .magenta]).count, 3)
        XCTAssertEqual([Twist].parse("0:+3,1:+4,0:-1", in: .tri).count, 3)
        var stack = [Twist].parse("0:+3,1:+4", in: .tri, masks: redCyan)
        XCTAssertEqual(Layout.tri.removable(stack, masks: redCyan), [0, 1])
        XCTAssertEqual(Layout.tri.removable(stack), [1])
        XCTAssertEqual(stack.commit(rod: 0, steps: -3, in: .tri, masks: redCyan), .cancelled)
        XCTAssertEqual(stack, [Twist(rod: 1, steps: 4)])
        var white = [Twist].parse("0:+3,1:+4", in: .tri)
        XCTAssertEqual(white.commit(rod: 0, steps: -3, in: .tri), .pushed)
    }

    /// The win is every channel back: a word that leaves each channel's own word the identity is solved, though the whole
    /// word, read white, is not.
    func testLooksSolvedIsPerChannel() {
        let word = [Twist(rod: 0, steps: 3), Twist(rod: 1, steps: 4), Twist(rod: 0, steps: -3), Twist(rod: 1, steps: -4)]
        XCTAssertTrue(Layout.tri.looksSolved(word, masks: redCyan))
        XCTAssertFalse(Layout.tri.looksSolved(word))
        XCTAssertFalse(Layout.tri.looksSolved([Twist(rod: 1, steps: 4)], masks: redCyan))
        XCTAssertFalse(Layout.tri.looksSolved([Twist(rod: 0, steps: 3)], masks: [0: .red]))
    }

    /// Masks left out or all white leave every existing level's stack as it was dealt.
    func testWhiteMasksChangeNoLevel() {
        let levels = Tier.allCases.flatMap(\.levels) + Pack.allCases.flatMap(\.levels)
        for level in levels where level.masks.isEmpty {
            let white = Dictionary(uniqueKeysWithValues: level.layout.rods.indices.map { ($0, Channels.white) })
            var stack: [Twist] = []
            for t in level.scramble { stack.commit(t, in: level.layout, lenses: level.lenses, masks: white) }
            XCTAssertEqual(stack, level.scramble, level.id)
        }
    }

    /// A game on masks heals a buried entry its channels free, and wins once every channel is back.
    @MainActor func testAGameHealsByChannel() {
        let stack = [Twist].parse("2:+2,0:+3,1:+4", in: .tri, masks: redCyan)
        XCTAssertEqual(stack.count, 3)
        let level = Level(id: "test-prism", label: "", title: "", layout: .tri, scramble: stack, masks: redCyan)
        let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
        game.commit(rod: 0, steps: -3)
        XCTAssertEqual(game.stack, [Twist(rod: 2, steps: 2), Twist(rod: 1, steps: 4)])
        game.commit(rod: 1, steps: -4)
        XCTAssertFalse(game.solved)
        game.commit(rod: 2, steps: -2)
        XCTAssertTrue(game.solved)
    }

    func testTheSolverReadsMasks() throws {
        let stack = [Twist].parse("2:+2,0:+3,1:+4", in: .tri, masks: redCyan)
        let solver = Solver(.tri, masks: redCyan)
        let play = try XCTUnwrap(solver.optimalPlay(stack, seized: []))
        XCTAssertEqual(play.count, 3)
        XCTAssertFalse(solver.interacts[0][1])
        XCTAssertTrue(Solver(.tri).interacts[0][1])
        let deeper = [Twist].parse("2:+2,0:+3,1:+4,0:+2", in: .tri, masks: [0: .red, 1: .green])
        let optimum = try XCTUnwrap(Solver(.tri, masks: [0: .red, 1: .green]).optimum(deeper))
        XCTAssertEqual(Solver(.tri, masks: [0: .red, 1: .green])
            .exhaustive(deeper, limit: optimum, steps: [-5, -4, -2, 2, 4, 5]), optimum)
    }

    /// Unstir.metal's per-channel chains carry each channel's point through the inverses of exactly the entries whose
    /// mask holds it, as the model's restricted words map it, on hex's swirl too. Only the helpers above the stitchables
    /// compile here, since they take a layer.
    func testTheShadersChannelChainsMatchTheModel() throws {
        let kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: """
            kernel void chain(device const float2 *points [[buffer(0)]], device const float *twists [[buffer(1)]],
                              device const float *masks [[buffer(2)]], constant int &n [[buffer(3)]],
                              constant float3 &k [[buffer(4)]], device float2 *out [[buffer(5)]],
                              uint i [[thread_position_in_grid]]) {
                float2 qr = points[i], qg = qr, qb = qr;
                chains(n, twists, masks, k.x, k.y, k.z, qr, qg, qb);
                out[3 * i] = qr; out[3 * i + 1] = qg; out[3 * i + 2] = qb;
            }
            """)
        let layout = Layout.hexSwirl, rods = layout.rods
        let all: [Channels] = [.red, .green, .blue, .cyan, .magenta, .yellow, .white]
        var rng = SplitMix64(state: 60)
        var masks: [Int: Channels] = [:]
        for k in rods.indices where k != layout.swirl { masks[k] = all[rng.below(all.count)] }
        let stack = (0..<12).map { _ in Twist(rod: rng.below(rods.count), steps: [-5, -3, -1, 2, 4][rng.below(5)]) }
        let (twists, channels) = Unstirred.entries(stack.map { ($0.rod, Double($0.steps) * Tank.step) }, layout: layout,
                                                   lenses: [], masks: masks)
        let points = Array(Tank.grid(41)).filter { simd_length($0) < 1 }
        let input = points.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
        var n = Int32(stack.count)
        var k = SIMD3<Float>(Float(Tank.plateau), Float(Tank.swirlPlateau), Float(Tank.lensEdge))
        let buffers = try [kit.buffer(input), kit.buffer(twists), kit.buffer(channels)]
        let output = try kit.buffer(SIMD2<Float>.self, count: 3 * points.count)
        try kit.run("chain", count: points.count) { enc in
            for (i, b) in buffers.enumerated() { enc.setBuffer(b, offset: 0, index: i) }
            enc.setBytes(&n, length: 4, index: 3)
            enc.setBytes(&k, length: 16, index: 4)
            enc.setBuffer(output, offset: 0, index: 5)
        }
        let got = kit.read(output, as: SIMD2<Float>.self)
        var moved = 0
        for (i, p) in points.enumerated() {
            for (j, c) in Channels.each.enumerated() {
                let want = stack.filter { (masks[$0.rod] ?? .white).contains(c) }.reversed()
                    .reduce(p) { Tank.twist($0, rod: rods[$1.rod], angle: -Double($1.steps) * Tank.step) }
                let q = SIMD2<Double>(Double(got[3 * i + j].x), Double(got[3 * i + j].y))
                XCTAssertLessThan(simd_distance(q, want), 2e-4, "\(p) channel \(j)")
                if simd_distance(want, p) > 0.01 { moved += 1 }
            }
        }
        XCTAssertGreaterThan(moved, points.count, "the stack moves enough of the tank to test")
    }

    /// Unstir.metal's taps (`tapsThrough`) are the pixel's four points a quarter device pixel off its centre, each
    /// turned back by the glass's turn and carried through the stack's inverses as the model maps it, on hex's swirl
    /// too; with two taps the diagonal pair is; and a pixel past the glass's edge runs no entry.
    func testTheShadersTapsMatchTheModel() throws {
        let kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: """
            struct TapArgs { float radius, scale, turn, plateau, swirlPlateau, lensEdge; int entries, stride, side; };
            kernel void taps(device const float *twists [[buffer(0)]], constant TapArgs &a [[buffer(1)]],
                             device float2 *out [[buffer(2)]], uint2 gid [[thread_position_in_grid]]) {
                float2 pos = (float2(gid) + 0.5) / a.scale;
                Taps t = tapsThrough(pos, float2(a.radius), a.radius, twists, a.entries, a.stride, a.plateau,
                                     a.swirlPlateau, a.lensEdge, a.scale, a.turn);
                int i = 8 * (gid.y * a.side + gid.x);
                out[i] = t.p0; out[i + 1] = t.p1; out[i + 2] = t.p2; out[i + 3] = t.p3;
                out[i + 4] = t.q0; out[i + 5] = t.q1; out[i + 6] = t.q2; out[i + 7] = t.q3;
            }
            """)
        struct Args {
            var radius, scale, turn, plateau, swirlPlateau, lensEdge: Float
            var entries, stride, side: Int32
        }
        let layout = Layout.hexSwirl, rods = layout.rods
        var rng = SplitMix64(state: 61)
        // Shallow and gentle: a deep stack stretches a float's last bit past any tolerance worth holding.
        let stack = (0..<6).map { _ in Twist(rod: rng.below(rods.count), steps: [-2, -1, 1, 2][rng.below(4)]) }
        let twists = Unstirred.entries(stack.map { ($0.rod, Double($0.steps) * Tank.step) }, layout: layout, lenses: [],
                                       masks: [:]).twists
        // A glass 54 px across in a 64 px square, so its corners lie past the edge.
        let side = 64, scale = 2.0, radius = 13.5, turn = 0.4
        for stride in [1, 3] {
            var args = Args(radius: Float(radius), scale: Float(scale), turn: Float(turn), plateau: Float(Tank.plateau),
                            swirlPlateau: Float(Tank.swirlPlateau), lensEdge: Float(Tank.lensEdge),
                            entries: Int32(stack.count), stride: Int32(stride), side: Int32(side))
            let output = try kit.buffer(SIMD2<Float>.self, count: 8 * side * side)
            try kit.run(try kit.pipeline("taps"), grid: MTLSize(width: side, height: side, depth: 1),
                        group: MTLSize(width: 8, height: 8, depth: 1)) { enc in
                enc.setBuffer(try! kit.buffer(twists), offset: 0, index: 0)
                enc.setBytes(&args, length: MemoryLayout<Args>.stride, index: 1)
                enc.setBuffer(output, offset: 0, index: 2)
            }
            let got = kit.read(output, as: SIMD2<Float>.self).map { SIMD2<Double>(Double($0.x), Double($0.y)) }
            var moved = 0, outside = 0
            for y in 0..<side {
                for x in 0..<side {
                    for j in stride == 1 ? [0, 1, 2, 3] : [0, 3] {
                        let at = SIMD2(Double(x) + 0.5 + (Double(j & 1) - 0.5) * 0.5, Double(y) + 0.5 + (Double(j >> 1) - 0.5) * 0.5)
                        let p = (at / scale - SIMD2(radius, radius)) / radius
                        let back = SIMD2(p.x * cos(turn) + p.y * sin(turn), p.y * cos(turn) - p.x * sin(turn))
                        let want = stack.reversed().reduce(back) { Tank.twist($0, rod: rods[$1.rod], angle: -Double($1.steps) * Tank.step) }
                        let i = 8 * (y * side + x)
                        XCTAssertLessThan(simd_distance(got[i + j], p), 1e-5, "tap \(j) of \(x), \(y)")
                        XCTAssertLessThan(simd_distance(got[i + 4 + j], want), 2e-4, "tap \(j) of \(x), \(y) through the stack")
                        if simd_distance(want, back) > 0.01 { moved += 1 }
                        if simd_length(p) > 1.05 { outside += 1 }
                    }
                }
            }
            XCTAssertGreaterThan(moved, side * side / 2, "the stack moves enough of the glass to test")
            XCTAssertGreaterThan(outside, side * side / 8, "pixels past the glass's edge are tested")
        }
    }

    /// The shader runs no entry for a pixel past the glass's edge (`pastTheGlass`), which holds only while every disc
    /// lies within the glass: there each entry's map is the identity.
    func testEveryDiscLiesWithinTheGlass() {
        for layout in Layout.allCases {
            for (k, rod) in layout.rods.enumerated() {
                XCTAssertLessThanOrEqual((rod.x * rod.x + rod.y * rod.y).squareRoot() + rod.z, 1 + 1e-6, "\(layout) rod \(k)")
            }
        }
    }

    /// `TankShader` passes each of the tank's stitchables its arguments in the signature's order, SwiftUI giving the
    /// position and layer and each array's count after it.
    func testTheTankShaderPassesTheSignaturesOrder() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Unstir.metal")
        let source = try String(contentsOf: url, encoding: .utf8)
        var shader = TankShader(centre: .zero, radius: 1, twists: [0, 0, 0.5, 1], fourTaps: 40, scale: 3)
        let fine = try XCTUnwrap(Fine(Halftone.test.detail(64, lenses: [])))
        let prism = TankShader.Prism(masks: [1], cost: 3, isolate: .red, tint: SIMD3(1, 0, 0))
        let mapped = TankShader.Mapped(image: fine.atlas, kept: 1, rest: 0, quant: 56, mode: .mix)
        for (prism, fine, mapped) in [(nil, nil, nil), (prism, nil, nil), (nil, fine, nil), (nil, nil, mapped)] {
            (shader.prism, shader.fine, shader.mapped) = (prism, fine, mapped)
            let head = try XCTUnwrap(source.range(of: "[[ stitchable ]] half4 \(shader.name)("), shader.name)
            let declared = source[head.upperBound...].prefix { $0 != ")" }.split(separator: ",")
                .map { $0.split(whereSeparator: \.isWhitespace) }
            var names: [String] = []
            for (i, words) in declared.enumerated().dropFirst(2) where !(declared[i - 1].first == "device") {
                names.append(String(try XCTUnwrap(words.last).drop { $0 == "*" }))
            }
            XCTAssertEqual(shader.parameters.map(\.name), names, shader.name)
        }
    }

    /// The per-channel shader draws only a stack with a mask that isn't white, and its cost counts each channel's map.
    func testTheChannelCostCountsEachChannelsMap() {
        let w = Float(Channels.white.rawValue), r = Float(Channels.red.rawValue), c = Float(Channels.cyan.rawValue)
        XCTAssertNil(Unstirred.channelCost([]))
        XCTAssertNil(Unstirred.channelCost([w, w, w]))
        XCTAssertEqual(Unstirred.channelCost([w, r, c]), 3 + 3 + 1 + 2)
    }

    /// Unstir.metal's Prism body over a texture of the plate, as the GPU bench samples it, and beside it the glass as
    /// it was drawn before a held rod had a read: each channel through its own chain, lit and finished, written out here.
    private static let heldKernel = """
        struct PlateLayer {
            texture2d<half> picture;
            float pixels;
            half4 sample(float2 p) const {
                constexpr sampler s(filter::linear, address::clamp_to_zero, coord::pixel);
                return picture.sample(s, p * pixels);
            }
        };
        struct HeldArgs { float radius, scale, n, cost, fourTaps, plateau, swirlPlateau, lensEdge, held, hold; int count, maskCount; };
        kernel void held(texture2d<half> picture [[texture(0)]], texture2d<half, access::write> out [[texture(1)]],
                         texture2d<half, access::write> plain [[texture(2)]], device const float *twists [[buffer(0)]],
                         device const float *masks [[buffer(1)]], constant HeldArgs &a [[buffer(2)]],
                         uint2 gid [[thread_position_in_grid]]) {
            if (gid.x >= out.get_width() || gid.y >= out.get_height()) return;
            PlateLayer layer = { picture, a.scale };
            float2 pos = (float2(gid) + 0.5) / a.scale, centre = float2(a.radius);
            out.write(unstirChannelsBody(pos, layer, centre, a.radius, twists, a.count, masks, a.maskCount, a.n, a.cost,
                                         a.fourTaps, a.plateau, a.swirlPlateau, a.lensEdge, a.scale, 0.0, float3(0, 0, -1),
                                         0.0, 0.0, float3(1), a.held, a.hold), gid);
            int stride = a.cost > a.fourTaps ? 3 : 1;
            float3 acc = 0;
            for (int j = 0; j < 4; j += stride) {
                float2 p = (pos + (float2(j & 1, j >> 1) - 0.5) * 0.5 / a.scale - centre) / a.radius;
                float2 qr = p, qg = p, qb = p;
                chains(min(int(a.n), min(a.count / 4, a.maskCount)), twists, masks, a.plateau, a.swirlPlateau, a.lensEdge,
                       qr, qg, qb);
                acc += lit(float3(layer.sample(centre + qr * a.radius).r, layer.sample(centre + qg * a.radius).g,
                                  layer.sample(centre + qb * a.radius).b), p, float3(0, 0, -1));
            }
            plain.write(finish(acc, stride, 0.0), gid);
        }
        """

    private struct HeldArgs {
        var radius, scale, n, cost, fourTaps, plateau, swirlPlateau, lensEdge, held, hold: Float
        var count, maskCount: Int32
    }

    /// The moves the held-rod tests turn: a Prism level, its stack before the move (its scramble's first `depth`
    /// entries), whose top entry's rod is the one in hand, stirred once and not white. Frond's cyan and red rods,
    /// Thistle's blue and specimen 14's yellow, each a move of its level's untwist (`scripts/prism-levels.sh read`).
    private static let heldMoves = [(1, 3), (1, 2), (8, 3), (14, 3)]

    /// A 1200 px glass of `level`'s first `depth` entries, its top entry's rod held `off` steps from its count, drawn
    /// through the held read at `hold` and as the glass was drawn before it, each as RGBA bytes, with the disc that
    /// rod turns rigidly in pixels.
    @MainActor private func held(_ kit: ShaderKit, _ plate: MTLTexture, level: Level, depth: Int, off: Double,
                                 hold: Float) throws -> (read: [UInt8], plain: [UInt8], side: Int, disc: (SIMD2<Double>, Double)) {
        let stack = Array(level.scramble.prefix(depth)), top = try XCTUnwrap(stack.last)
        let mask = level.masks[top.rod] ?? .white
        let count = -Double(top.steps), angle = (count + (count < 0 ? -off : off)) * Tank.step
        let turns = stack.map { ($0.rod, Double($0.steps) * Tank.step) } + [(top.rod, angle)]
        let (twists, masks) = Unstirred.entries(turns, layout: level.layout, lenses: [], masks: level.masks)
        let side = plate.width, scale: Float = 3, radius = Float(side) / scale / 2
        var args = HeldArgs(radius: radius, scale: scale, n: Float(turns.count), cost: Float(try XCTUnwrap(Unstirred.channelCost(masks))),
                            fourTaps: 99, plateau: Float(Tank.plateau), swirlPlateau: Float(Tank.swirlPlateau),
                            lensEdge: Float(Tank.lensEdge), held: Float(mask.rawValue), hold: hold,
                            count: Int32(twists.count), maskCount: Int32(masks.count))
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: side, height: side, mipmapped: false)
        desc.usage = .shaderWrite
        let outs = try (0..<2).map { _ in try XCTUnwrap(kit.device.makeTexture(descriptor: desc)) }
        let buffers = try [kit.buffer(twists), kit.buffer(masks)]
        try kit.run(try kit.pipeline("held"), grid: MTLSize(width: side, height: side, depth: 1),
                    group: MTLSize(width: 16, height: 16, depth: 1)) { enc in
            enc.setTexture(plate, index: 0)
            enc.setTexture(outs[0], index: 1)
            enc.setTexture(outs[1], index: 2)
            for (i, b) in buffers.enumerated() { enc.setBuffer(b, offset: 0, index: i) }
            enc.setBytes(&args, length: MemoryLayout<HeldArgs>.stride, index: 2)
        }
        let bytes = outs.map { t in
            var b = [UInt8](repeating: 0, count: 4 * side * side)
            t.getBytes(&b, bytesPerRow: 4 * side, from: MTLRegionMake2D(0, 0, side, side), mipmapLevel: 0)
            return b
        }
        let rod = level.layout.rods[top.rod], r = Double(side) / 2
        return (bytes[0], bytes[1], side, (SIMD2(r * (1 + rod.x), r * (1 + rod.y)), r * rod.z * Tank.plateau))
    }

    /// `level`'s plate at 1200 px, gamma-encoded as the layer samples it.
    @MainActor private func plate(_ kit: ShaderKit, _ level: Level) async throws -> MTLTexture {
        let rendered = await level.picture.render(side: 400, scale: 3)
        let image = try XCTUnwrap(rendered?.cgImage)
        return try await MTKTextureLoader(device: kit.device).newTexture(cgImage: image, options: [.SRGB: false])
    }

    /// The share of the lit pixels white (every channel past 0.6 of the brightest, lit past 110 of 255) in the held
    /// rod's rigid disc outside its knob's cap (0.12 of the glass's radius), as the trial's shots were measured.
    private func whiteShare(_ px: [UInt8], side: Int, disc: (SIMD2<Double>, Double)) -> Double {
        let (c, r1) = disc, r0 = 0.12 * Double(side) / 2
        var lit = 0, white = 0
        for j in max(Int(c.y - r1), 0)...min(Int(c.y + r1), side - 1) {
            for i in max(Int(c.x - r1), 0)...min(Int(c.x + r1), side - 1) {
                let d = simd_distance(SIMD2(Double(i), Double(j)), c)
                guard d > r0, d < r1 else { continue }
                let k = 4 * (j * side + i), p = [px[k], px[k + 1], px[k + 2]].map(Double.init)
                guard p.max()! > 110 else { continue }
                lit += 1
                if p.min()! > 0.6 * p.max()! { white += 1 }
            }
        }
        return Double(white) / Double(max(lit, 1))
    }

    /// While a rod is held its disc draws only the channels it moves, in their own colour, until the turn is within
    /// half a step of its count, and white closes up on the count. The read looks at the stack's maps, never at the
    /// count, so this is a measure of the plates as dealt, not of a rule.
    @MainActor func testAHeldRodReadsInItsOwnColourUntilNearItsCount() async throws {
        let kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: Self.heldKernel)
        var rows: [String] = []
        for (n, depth) in Self.heldMoves {
            let level = Level.prism[n - 1], where_ = "\(level.id) after \(depth)"
            let plate = try await plate(kit, level)
            var shares: [Double] = []
            for off in [-1, -0.5, 0, 0.5, 1] {
                let drawn = try held(kit, plate, level: level, depth: depth, off: off, hold: 1)
                let share = whiteShare(drawn.read, side: drawn.side, disc: drawn.disc)
                shares.append(share)
                if off == 0 {
                    XCTAssertGreaterThanOrEqual(share, 0.7, "\(where_) on the count")
                } else {
                    XCTAssertLessThanOrEqual(share, 0.02, "\(where_) \(off) steps off the count")
                }
            }
            rows.append(where_ + ": " + shares.map { String(format: "%.3f", $0) }.joined(separator: " "))
        }
        print("held white share, -1 -0.5 on +0.5 +1 steps off the count\n" + rows.joined(separator: "\n"))
    }

    /// Let go and faded out, the held read leaves the glass exactly as it was drawn before it, to the byte.
    @MainActor func testAHeldRodsReadLeavesTheGlassAsItWasWhenLetGo() async throws {
        let kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: Self.heldKernel)
        let level = Level.prism[0], plate = try await plate(kit, level)
        for off in [0, 0.5] {
            let drawn = try held(kit, plate, level: level, depth: 3, off: off, hold: 0)
            XCTAssertTrue(drawn.read == drawn.plain, "\(off) steps off the count")
            let gripped = try held(kit, plate, level: level, depth: 3, off: off, hold: 1)
            XCTAssertFalse(gripped.read == gripped.plain, "the read shows in hand")
        }
    }

    /// Each plate, drawn at `side`, as grey levels, row 0 at the top.
    @MainActor private func pixels(_ picture: Picture, side: Int) async throws -> (rgb: [UInt8], w: Int) {
        let rendered = await picture.render(side: CGFloat(side), scale: 1)
        let image = try XCTUnwrap(rendered?.cgImage)
        let w = image.width, h = image.height
        var pixels = [UInt8](repeating: 0, count: 4 * w * h)
        let ctx = try XCTUnwrap(CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 4 * w,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue))
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        return (pixels, w)
    }

    /// Every plate is grey everywhere, so a channel out of register shows its own colour and aligned lines are white.
    @MainActor func testEveryPlateIsWhiteLinesOnBlack() async throws {
        for plate in Engraving.Plate.allCases {
            let picture = try XCTUnwrap(Picture(rawValue: plate.rawValue))
            XCTAssertEqual(picture.plate, plate)
            XCTAssertFalse(picture.isLive)
            let (px, w) = try await pixels(picture, side: 240)
            var lit = 0, tinted = 0
            for i in 0..<(w * w) {
                let r = Int(px[4 * i]), g = Int(px[4 * i + 1]), b = Int(px[4 * i + 2])
                if max(abs(r - g), abs(g - b), abs(r - b)) > 2 { tinted += 1 }
                // At 240 px a fine line (0.003) is a third of a pixel wide, so a plate drawn mostly in fine lines
                // seldom reaches white; lit is the step test's half grey.
                if r > 127 { lit += 1 }
            }
            XCTAssertEqual(tinted, 0, plate.rawValue)
            XCTAssertGreaterThan(lit, w * w / 400, plate.rawValue)
        }
    }

    /// Every core of every layout holds some of each plate's lines, and a 30° step of the core moves most of its light,
    /// so a step reads wherever a specimen puts a rod (`scripts/prism-plates.sh check` prints the same measures).
    @MainActor func testEveryPlateShowsAStepInEveryCore() async throws {
        for plate in Engraving.Plate.allCases {
            let (px, w) = try await pixels(Picture(rawValue: plate.rawValue)!, side: 512)
            let r = Double(w) / 2
            func lit(_ x: Double, _ y: Double) -> Bool {
                let i = Int(r + x * r), j = Int(r + y * r)
                return i >= 0 && j >= 0 && i < w && j < w && px[4 * (j * w + i)] > 127
            }
            for layout in Layout.allCases {
                for (k, rod) in layout.rods.enumerated() {
                    let core = rod.z * Tank.plateau, step = 2 / Double(w)
                    var inside = 0, on = 0, moved = 0
                    for y in stride(from: -core, through: core, by: step) {
                        for x in stride(from: -core, through: core, by: step) where x * x + y * y <= core * core {
                            inside += 1
                            guard lit(rod.x + x, rod.y + y) else { continue }
                            on += 1
                            let c = cos(Tank.step), s = sin(Tank.step)
                            if !lit(rod.x + c * x - s * y, rod.y + s * x + c * y) { moved += 1 }
                        }
                    }
                    let where_ = "\(plate.rawValue) \(layout.rawValue) rod \(k)"
                    XCTAssertGreaterThan(Double(on) / Double(inside), 0.02, where_)
                    XCTAssertGreaterThan(Double(moved) / Double(max(on, 1)), 0.5, where_)
                }
            }
        }
    }

    /// Pinned: a specimen's id holds its best, so a row changes only with a reason.
    static let table: [(Layout, [Int: Channels], String)] = [
        (.tri, [0: .red, 1: .cyan, 2: .white], "2:+3,0:+4,1:-3"),
        (.quad, [0: .red, 1: .cyan, 2: .red, 3: .white], "3:+3,2:-4,1:+3,0:+5"),
        (.eye, [0: .red, 1: .cyan, 2: .red, 3: .white], "3:+4,0:-3,2:+2,1:+5,0:+3"),
        (.quad, [0: .red, 1: .red, 2: .cyan, 3: .white], "3:-3,0:+3,1:+4,2:-5,0:-2,1:+3"),
        (.pent, [0: .red, 1: .red, 2: .cyan, 3: .cyan, 4: .white], "4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5"),
        (.hex, [0: .cyan, 1: .cyan, 2: .cyan, 3: .red, 4: .red, 5: .white, 6: .cyan], "5:-2,1:+5,6:+3,1:-5,4:-5,0:+3,2:-3,3:-4"),
        (.quad, [0: .blue, 1: .green, 2: .red, 3: .white], "3:-4,2:-5,1:-4,0:-3"),
        (.pent, [0: .blue, 1: .green, 2: .red, 3: .white, 4: .red], "3:+3,1:-5,0:+4,4:-4,2:-2"),
        (.pent, [0: .red, 1: .green, 2: .blue, 3: .white, 4: .red], "3:-3,2:+2,1:-2,0:+3,4:+2,0:-2"),
        (.pent, [0: .green, 1: .green, 2: .red, 3: .blue, 4: .white], "4:+4,2:+4,1:+2,0:+2,3:+5,1:+3"),
        (.pent, [0: .green, 1: .white, 2: .blue, 3: .blue, 4: .red], "1:-5,2:-4,3:-5,0:+3,2:-5,4:-5,3:+5"),
        (.pent, [0: .blue, 1: .white, 2: .red, 3: .red, 4: .green], "1:+5,2:-2,4:+3,0:+4,3:-2,2:-3,3:-3,2:+4"),
        (.tri, [0: .magenta, 1: .cyan, 2: .white], "2:-5,1:+5,0:-4,1:-5"),
        (.quad, [0: .white, 1: .magenta, 2: .cyan, 3: .yellow], "0:-5,1:+4,3:-4,2:-2"),
        (.quad, [0: .yellow, 1: .white, 2: .magenta, 3: .cyan], "1:-3,2:-3,0:+5,3:+3,2:+5"),
        (.eye, [0: .cyan, 1: .white, 2: .yellow, 3: .magenta], "1:+5,0:+5,2:-2,0:-5,3:+5"),
        (.pent, [0: .cyan, 1: .cyan, 2: .magenta, 3: .white, 4: .yellow], "3:+3,0:+5,4:+3,0:+3,2:-2,1:+2"),
        (.pent, [0: .magenta, 1: .yellow, 2: .cyan, 3: .white, 4: .yellow], "3:+3,2:+5,4:+5,1:+4,0:-3,1:-5,2:-3"),
        (.quad, [0: .cyan, 1: .blue, 2: .yellow, 3: .white], "3:-5,2:-2,1:-4,0:+3,1:-3,0:-3"),
        (.eye, [0: .white, 1: .magenta, 2: .green, 3: .blue], "0:-2,2:+3,3:+4,1:+3,3:-2,1:-4"),
        (.eye, [0: .white, 1: .blue, 2: .yellow, 3: .magenta], "0:-4,3:+5,1:-2,2:-3,3:+5,1:+3,3:-4"),
        (.pent, [0: .cyan, 1: .white, 2: .blue, 3: .magenta, 4: .green], "1:+3,4:-2,0:+2,2:-2,3:+5,4:-5,2:+5"),
        (.pent, [0: .magenta, 1: .red, 2: .cyan, 3: .blue, 4: .white], "4:+5,3:+2,0:-5,2:-3,1:+3,0:-5,1:-2,0:+2"),
        (.pent, [0: .yellow, 1: .white, 2: .green, 3: .cyan, 4: .magenta], "1:-2,4:-5,3:-5,0:+3,2:+3,3:+3,4:+2,3:+2"),
        (.tri, [0: .white, 1: .magenta, 2: .red], "0:+2,1:+5,2:+3,1:-2,2:-2,1:-3"),
        (.quad, [0: .yellow, 1: .cyan, 2: .red, 3: .white], "3:+5,2:+4,1:-4,0:-4,1:-4,0:+2,1:-4"),
        (.eye, [0: .blue, 1: .white, 2: .magenta, 3: .yellow], "1:-4,0:+3,2:-2,3:-3,0:+5,2:+3,0:+3"),
        (.eye, [0: .white, 1: .red, 2: .magenta, 3: .blue], "0:-3,2:-2,3:-3,1:-5,2:+4,1:+5,2:-2,1:-2"),
        (.pent, [0: .cyan, 1: .magenta, 2: .blue, 3: .yellow, 4: .white], "4:-4,3:+5,0:-3,2:+2,1:+4,2:-3,1:+3,0:-4"),
        (.pent, [0: .yellow, 1: .magenta, 2: .red, 3: .white, 4: .green], "3:-3,2:+2,1:-2,2:-2,0:+3,4:+2,1:+2,0:-2"),
    ]

    /// Prism's five trays, `docs/prism-design.md`: every rod dealt, over one white rod that holds only the bottom entry.
    /// Nothing merges as it is dealt, no stack is deeper than 8 (Jack's call PK1: deeper reads too busy), par is the
    /// depth, untwisting reaches it, and every stack keeps four taps under the per-channel shader's assumed cost.
    @MainActor func testPrismLevels() {
        XCTAssertEqual(Level.prism.count, Self.table.count)
        XCTAssertEqual(Level.prism.map(\.id), (1...Self.table.count).map { "prism-\($0)" })
        for (level, (layout, masks, scramble)) in zip(Level.prism, Self.table) {
            XCTAssertEqual(level.pack, .prism)
            let tray = (Int(level.label)! - 1) / 6
            XCTAssertEqual(level.picture, Level.prismPlates[tray], level.id)
            XCTAssertEqual(level.chapter, Level.prismTrays[tray], level.id)
            XCTAssertLessThanOrEqual(level.scramble.count, 8, "\(level.id) is deeper than Prism's cap")
            XCTAssertEqual(level.motion, .none)
            XCTAssertEqual(level.layout, layout, level.id)
            XCTAssertEqual(level.masks, masks, level.id)
            XCTAssertEqual(Set(masks.keys), Set(layout.rods.indices), level.id)
            if tray == 0 { XCTAssertTrue(masks.values.allSatisfy { [.red, .cyan, .white].contains($0) }, level.id) }
            XCTAssertEqual(masks.values.filter { $0 == .white }.count, 1, level.id)
            XCTAssertEqual(level.scramble, .parse(scramble, in: layout, masks: masks), level.id)
            XCTAssertEqual(level.scramble.count, scramble.split(separator: ",").count, "\(level.id) merges as it is dealt")
            XCTAssertEqual(level.par, level.scramble.count, level.id)
            let bottom = level.scramble[0].rod
            XCTAssertEqual(masks[bottom], .white, "\(level.id): the bottom entry is white")
            XCTAssertEqual(level.scramble.filter { $0.rod == bottom }.count, 1, level.id)
            XCTAssertEqual(Set(level.scramble.map(\.rod)), Set(layout.rods.indices), "\(level.id): a knob with nothing to do")
            XCTAssertFalse(level.layout.looksSolved(level.scramble, masks: masks), level.id)
            let cost = Unstirred.channelCost(level.scramble.map { Float(masks[$0.rod]!.rawValue) })
            XCTAssertLessThanOrEqual(cost ?? .max, Tank.fourTaps - level.picture.fillEntries, level.id)
            let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
            while let t = game.reachable, !game.finished { game.commit(rod: t.rod, steps: t.steps) }
            XCTAssertTrue(game.solved, level.id)
            XCTAssertEqual(game.moves, level.par, level.id)
        }
        XCTAssertEqual(Level.prism.count, Pack.prism.planned)
        XCTAssertTrue(Offer.shelf(release: true).contains(.pack(.prism)), "Prism ships in v1 (PK1)")
    }

    /// Every specimen's par, its depth, is the solver's optimum: no detour beats untwisting. Slow, as Lens's is.
    func testPrismParIsTheOptimum() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1",
                          "slow: run with TEST_RUNNER_UNSTIR_SLOW_TESTS=1")
        for level in Level.prism {
            XCTAssertEqual(Solver(level.layout, masks: level.masks).optimum(level.scramble), level.par, level.id)
        }
    }

    /// Until the player chooses in settings, the letters follow Differentiate Without Colour either way; a choice holds
    /// whatever the system says. Jack's call C16, round 13.
    func testLettersFollowTheSystemUntilChosen() {
        let saved = UserDefaults.standard.object(forKey: "letters")
        defer { UserDefaults.standard.set(saved, forKey: "letters") }
        Letters.choice = nil
        XCTAssertNil(UserDefaults.standard.object(forKey: "letters"))
        XCTAssertTrue(Letters.shown(system: true))
        XCTAssertFalse(Letters.shown(system: false))
        Letters.choice = false
        XCTAssertFalse(Letters.shown(system: true))
        Letters.choice = true
        XCTAssertTrue(Letters.shown(system: false))
        XCTAssertEqual(Offer.pack(.prism).note, "letters for colour-blind play, in settings")
        XCTAssertNil(Offer.pack(.lens).note)
    }
}
