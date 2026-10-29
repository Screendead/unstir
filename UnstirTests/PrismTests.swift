// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import UIKit
import XCTest
import simd
@testable import Unstir

/// Prism's channel masks: a stir moves only its rod's channels, so commutation and the win are judged per channel.
final class PrismTests: XCTestCase {
    private let redCyan: [Int: Channels] = [0: .red, 1: .cyan]

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
        guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("no Metal device") }
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Unstir.metal")
        let helpers = try XCTUnwrap(try String(contentsOf: url, encoding: .utf8).components(separatedBy: "[[ stitchable ]]").first)
            .replacingOccurrences(of: "#include <SwiftUI/SwiftUI_Metal.h>", with: "")
        let source = helpers + """

            kernel void chain(device const float2 *points [[buffer(0)]], device const float *twists [[buffer(1)]],
                              device const float *masks [[buffer(2)]], constant int &n [[buffer(3)]],
                              constant float3 &k [[buffer(4)]], device float2 *out [[buffer(5)]],
                              uint i [[thread_position_in_grid]]) {
                float2 qr = points[i], qg = qr, qb = qr;
                chains(n, twists, masks, k.x, k.y, k.z, qr, qg, qb);
                out[3 * i] = qr; out[3 * i + 1] = qg; out[3 * i + 2] = qb;
            }
            """
        let library = try device.makeLibrary(source: source, options: nil)
        let pipeline = try device.makeComputePipelineState(function: try XCTUnwrap(library.makeFunction(name: "chain")))
        let layout = Layout.hexSwirl, rods = layout.rods
        let all: [Channels] = [.red, .green, .blue, .cyan, .magenta, .yellow, .white]
        var rng = SplitMix64(state: 60)
        var masks: [Int: Channels] = [:]
        for k in rods.indices where k != layout.swirl { masks[k] = all[rng.below(all.count)] }
        let stack = (0..<12).map { _ in Twist(rod: rng.below(rods.count), steps: [-5, -3, -1, 2, 4][rng.below(5)]) }
        let twists = stack.flatMap { [Float(rods[$0.rod].x), Float(rods[$0.rod].y), Float(rods[$0.rod].z), Float(Double($0.steps) * Tank.step)] }
        let channels = stack.map { Float((masks[$0.rod] ?? .white).rawValue) }
        let points = Array(Tank.grid(41)).filter { simd_length($0) < 1 }
        let input = points.map { SIMD2<Float>(Float($0.x), Float($0.y)) }
        var n = Int32(stack.count)
        var k = SIMD3<Float>(Float(Tank.plateau), Float(Tank.swirlPlateau), Float(Tank.lensEdge))
        let output = try XCTUnwrap(device.makeBuffer(length: 8 * 3 * points.count))
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let cb = try XCTUnwrap(queue.makeCommandBuffer()), enc = try XCTUnwrap(cb.makeComputeCommandEncoder())
        enc.setComputePipelineState(pipeline)
        enc.setBuffer(device.makeBuffer(bytes: input, length: 8 * input.count), offset: 0, index: 0)
        enc.setBuffer(device.makeBuffer(bytes: twists, length: 4 * twists.count), offset: 0, index: 1)
        enc.setBuffer(device.makeBuffer(bytes: channels, length: 4 * channels.count), offset: 0, index: 2)
        enc.setBytes(&n, length: 4, index: 3)
        enc.setBytes(&k, length: 16, index: 4)
        enc.setBuffer(output, offset: 0, index: 5)
        enc.dispatchThreads(MTLSize(width: points.count, height: 1, depth: 1),
                            threadsPerThreadgroup: MTLSize(width: 64, height: 1, depth: 1))
        enc.endEncoding()
        cb.commit()
        cb.waitUntilCompleted()
        XCTAssertNil(cb.error)
        let got = output.contents().bindMemory(to: SIMD2<Float>.self, capacity: 3 * points.count)
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

    /// The per-channel shader draws only a stack with a mask that isn't white, and its cost counts each channel's map.
    func testTheChannelCostCountsEachChannelsMap() {
        let w = Float(Channels.white.rawValue), r = Float(Channels.red.rawValue), c = Float(Channels.cyan.rawValue)
        XCTAssertNil(Unstirred.channelCost([]))
        XCTAssertNil(Unstirred.channelCost([w, w, w]))
        XCTAssertEqual(Unstirred.channelCost([w, r, c]), 2 + 3 + 1 + 2)
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
                if r > 230 { lit += 1 }
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

    static let table: [(Layout, [Int: Channels], String)] = [
        (.tri, [0: .red, 1: .cyan, 2: .white], "2:+3,0:+4,1:-3"),
        (.quad, [0: .red, 1: .cyan, 2: .red, 3: .white], "3:+3,2:-4,1:+3,0:+5"),
        (.eye, [0: .red, 1: .cyan, 2: .red, 3: .white], "3:+4,0:-3,2:+2,1:+5,0:+3"),
        (.quad, [0: .red, 1: .red, 2: .cyan, 3: .white], "3:-3,0:+3,1:+4,2:-5,0:-2,1:+3"),
        (.pent, [0: .red, 1: .red, 2: .cyan, 3: .cyan, 4: .white], "4:+3,0:+4,2:-3,1:+2,3:+4,0:-3,2:+5"),
        (.hex, [0: .white, 1: .red, 2: .red, 3: .cyan, 4: .cyan, 5: .red, 6: .cyan],
         "0:+3,1:+4,3:-3,2:-2,5:+2,4:+5,1:+3,6:-4,3:+2"),
    ]

    /// The Two Colours tray, `docs/prism-design.md`: red and cyan rods, every one dealt, over one white rod that holds only
    /// the bottom entry. Nothing merges as it is dealt, par is the depth, untwisting reaches it, and every stack keeps four
    /// taps under the per-channel shader's assumed cost.
    @MainActor func testPrismLevels() {
        XCTAssertEqual(Level.prism.count, Self.table.count)
        XCTAssertEqual(Level.prism.map(\.id), (1...Self.table.count).map { "prism-\($0)" })
        for (level, (layout, masks, scramble)) in zip(Level.prism, Self.table) {
            XCTAssertEqual(level.pack, .prism)
            XCTAssertEqual(level.picture, .fern)
            XCTAssertEqual(level.motion, .none)
            XCTAssertEqual(level.layout, layout, level.id)
            XCTAssertEqual(level.masks, masks, level.id)
            XCTAssertEqual(Set(masks.keys), Set(layout.rods.indices), level.id)
            XCTAssertTrue(masks.values.allSatisfy { [.red, .cyan, .white].contains($0) }, level.id)
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
        XCTAssertFalse(Offer.shelf(release: true).contains(.pack(.prism)), "Prism stays off the Release shelf")
    }

    /// Every specimen's par, its depth, is the solver's optimum: no detour beats untwisting. Slow, as Lens's is.
    func testPrismParIsTheOptimum() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1",
                          "slow: run with TEST_RUNNER_UNSTIR_SLOW_TESTS=1")
        for level in Level.prism {
            XCTAssertEqual(Solver(level.layout, masks: level.masks).optimum(level.scramble), level.par, level.id)
        }
    }
}
