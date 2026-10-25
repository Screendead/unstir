// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import XCTest
import simd
@testable import Unstir

final class LensTests: XCTestCase {
    private func word(_ s: String) -> [Twist] {
        s.split(separator: ",").map { t in
            let f = t.split(separator: ":")
            return Twist(rod: Int(f[0])!, steps: Int(f[1])!)
        }
    }

    /// A lens's steps form a group: they sum, an entry and its inverse cancel, and `Array.commit` merges and pops them
    /// as it does a twist's.
    func testLensStepsSumAndCancel() {
        let layout = Layout.tri, lenses: Set<Int> = [0]
        func same(_ a: String, _ b: String) -> Bool {
            layout.same(a.isEmpty ? [] : word(a), b.isEmpty ? [] : word(b), at: Tank.samples, within: 1e-9, lenses: lenses)
        }
        XCTAssertTrue(same("0:2,0:1", "0:3"))
        XCTAssertTrue(same("0:-2,0:3", "0:1"))
        XCTAssertTrue(same("0:3,0:-3", ""))
        XCTAssertTrue(same("0:12,0:-12", ""))
        XCTAssertFalse(same("0:12", ""), "a lens never wraps")
        var stack = [Twist]()
        XCTAssertEqual(stack.commit(rod: 0, steps: 1, in: layout, lenses: lenses), .pushed)
        XCTAssertEqual(stack.commit(rod: 0, steps: 2, in: layout, lenses: lenses), .reduced)
        XCTAssertEqual(stack, [Twist(rod: 0, steps: 3)])
        XCTAssertEqual(stack.commit(rod: 0, steps: -3, in: layout, lenses: lenses), .cancelled)
        XCTAssertEqual(stack, [])
    }

    /// A lens moves nothing from its core's rim out, so it fixes every point there exactly; inside, a step scales the
    /// centre by 1.3, and a positive one magnifies: the fluid moves outward.
    func testLensMovesOnlyItsCoreAndMagnifiesClockwise() {
        for layout in Layout.allCases {
            for rod in layout.rods {
                let c = SIMD2(rod.x, rod.y)
                for steps in [-12.0, -3, -1, 0.5, 1, 3, 12] {
                    for u in [Tank.plateau, 0.61, 0.7, 0.95, 1.2] {
                        for a in stride(from: 0.0, to: 2 * .pi, by: 0.7) {
                            let p = c + u * rod.z * SIMD2(cos(a), sin(a)), q = Tank.lens(p, rod: rod, steps: steps)
                            // The rim itself is fixed by the flow, to rounding; beyond it, nothing is computed.
                            if u == Tank.plateau {
                                XCTAssertEqual(simd_distance(q, p), 0, accuracy: 1e-12, "\(layout) on the rim, steps \(steps)")
                            } else {
                                XCTAssertEqual(q, p, "\(layout) u \(u) steps \(steps)")
                            }
                        }
                    }
                    for u in [0.1, 0.3, 0.5, 0.59] {
                        let p = c + u * rod.z * SIMD2(0.6, 0.8), q = Tank.lens(p, rod: rod, steps: steps)
                        let out = simd_distance(q, c) / simd_distance(p, c)
                        XCTAssertEqual(steps > 0, out > 1, "\(layout) u \(u) steps \(steps)")
                        XCTAssertLessThan(simd_distance(q, c), Tank.plateau * rod.z, "stays inside its core")
                    }
                }
                let p = c + SIMD2(1e-4 * rod.z, 0)
                XCTAssertEqual(simd_distance(Tank.lens(p, rod: rod, steps: 1), c) / (1e-4 * rod.z), 1.3, accuracy: 1e-4)
            }
        }
    }

    /// The lens set reaches every merge: on tri, two lenses' cores never meet, so rod 0's second stir merges past rod
    /// 1's; as twists their discs overlap, and it pushes. A game on the level merges as `parse` does.
    @MainActor func testTheLensSetChangesHowAStackMerges() {
        XCTAssertEqual([Twist].parse("0:+1,1:+1,0:+1", in: .tri).count, 3)
        let stack = [Twist].parse("0:+1,1:+1,0:+1", in: .tri, lenses: [0, 1])
        XCTAssertEqual(stack, [Twist(rod: 0, steps: 2), Twist(rod: 1, steps: 1)])
        let level = Level(id: "test-lens", label: "", title: "", layout: .tri, scramble: stack, lenses: [0, 1])
        let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
        game.commit(rod: 0, steps: -2)
        XCTAssertEqual(game.stack, [Twist(rod: 1, steps: 1)])
        XCTAssertEqual(game.level.layout.removable(game.stack, lenses: game.level.lenses), [0])
        game.commit(rod: 1, steps: -1)
        XCTAssertTrue(game.solved)
    }

    /// Unstir.metal's copy of the lens's flow agrees with `Tank.lensFlow` at the rim sharpness Swift passes it, far past
    /// the deal's three steps either way. Only the helpers above the stitchable compile here, since it takes a layer.
    func testLensShaderMatchesSwift() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("no Metal device") }
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Unstir.metal")
        let whole = try String(contentsOf: url, encoding: .utf8)
        let helpers = try XCTUnwrap(whole.components(separatedBy: "[[ stitchable ]]").first)
            .replacingOccurrences(of: "#include <SwiftUI/SwiftUI_Metal.h>", with: "")
        let source = helpers + """

            kernel void flow(device const float4 *in [[buffer(0)]], device float *out [[buffer(1)]],
                             uint i [[thread_position_in_grid]]) {
                out[i] = lensFlow(in[i].x, in[i].y, in[i].z, in[i].w);
            }
            """
        let library = try device.makeLibrary(source: source, options: nil)
        let pipeline = try device.makeComputePipelineState(function: try XCTUnwrap(library.makeFunction(name: "flow")))
        var cases: [SIMD4<Float>] = []
        for k in -48...48 {
            for j in 1..<60 {
                cases.append(SIMD4(Float(Double(j) / 100), Float(Double(k) / 4 * Tank.lensRate), Float(Tank.plateau),
                                   Float(Tank.lensEdge)))
            }
        }
        let input = try XCTUnwrap(device.makeBuffer(bytes: cases, length: 16 * cases.count))
        let output = try XCTUnwrap(device.makeBuffer(length: 4 * cases.count))
        let queue = try XCTUnwrap(device.makeCommandQueue())
        let cb = try XCTUnwrap(queue.makeCommandBuffer()), enc = try XCTUnwrap(cb.makeComputeCommandEncoder())
        enc.setComputePipelineState(pipeline)
        enc.setBuffer(input, offset: 0, index: 0)
        enc.setBuffer(output, offset: 0, index: 1)
        enc.dispatchThreads(MTLSize(width: cases.count, height: 1, depth: 1),
                            threadsPerThreadgroup: MTLSize(width: 64, height: 1, depth: 1))
        enc.endEncoding()
        cb.commit()
        cb.waitUntilCompleted()
        XCTAssertNil(cb.error)
        let got = output.contents().bindMemory(to: Float.self, capacity: cases.count)
        for (i, c) in cases.enumerated() {
            let want = Tank.lensFlow(Double(c.x), Double(c.y))
            // A pixel at Pro Max size is about 1/568 of the tank's radius; this is a few hundredths of one.
            XCTAssertEqual(Double(got[i]), want, accuracy: 2e-5, "u \(c.x) t \(c.y)")
        }
    }

    /// The pack's levels: each on the halftone with a lens, every dealt lens entry magnifying by 1 to 3 steps and each
    /// lens netting at most +3; par is the solver's optimum, and untwisting reaches it on a real game.
    @MainActor func testLensLevels() {
        XCTAssertEqual(Level.lens.count, 3)
        for level in Level.lens {
            XCTAssertEqual(level.pack, .lens)
            XCTAssertEqual(level.picture, .halftone)
            XCTAssertEqual(level.motion, .none)
            XCTAssertFalse(level.lenses.isEmpty, level.id)
            for lens in level.lenses {
                let entries = level.scramble.filter { $0.rod == lens }.map(\.steps)
                XCTAssertTrue(entries.allSatisfy { (1...3).contains($0) }, "\(level.id) lens \(lens): \(entries)")
                XCTAssertLessThanOrEqual(entries.reduce(0, +), 3, level.id)
            }
            XCTAssertFalse(level.layout.looksSolved(level.scramble, lenses: level.lenses), level.id)
            let solver = Solver(level.layout, lenses: level.lenses)
            XCTAssertEqual(solver.optimum(level.scramble), level.par, level.id)
            let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
            while let t = game.reachable, !game.finished { game.commit(rod: t.rod, steps: t.steps) }
            XCTAssertTrue(game.solved, level.id)
            XCTAssertEqual(game.moves, level.par, level.id)
        }
    }

    /// A pack's undo puts a lens's entry back as the stir found it: a magnified core un-shrunk, a push taken off.
    @MainActor func testAPackUndoPutsALensBack() throws {
        let level = try XCTUnwrap(Level.lens.last)
        let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
        let dealt = game.stack
        game.commit(rod: 0, steps: -1)
        XCTAssertEqual(game.stack.last, Twist(rod: 0, steps: 2))
        game.commit(rod: 1, steps: 2)
        game.undo()
        game.undo()
        XCTAssertEqual(game.stack, dealt)
        XCTAssertEqual(game.moves, 0)
        XCTAssertEqual(game.bank, 3)
    }

    /// On the halftone, every step of every rod on every layout changes what shows inside its core, which is what the
    /// player reads: a twist turns the asymmetric linework, a lens swells the dots.
    func testEveryStepMovesContrastingPixelsOnTheHalftone() {
        let aa = 1.0 / 568, spacing = 1.0 / 48
        for layout in Layout.allCases {
            for (k, rod) in layout.rods.enumerated() {
                let c = SIMD2(rod.x, rod.y), reach = Tank.plateau * rod.z
                var points: [SIMD2<Double>] = []
                for y in stride(from: -reach, through: reach, by: spacing) {
                    for x in stride(from: -reach, through: reach, by: spacing) where x * x + y * y < reach * reach {
                        points.append(c + SIMD2(x, y))
                    }
                }
                let clean = points.map { Halftone.light($0, aa: aa) }
                func changed(_ back: (SIMD2<Double>) -> SIMD2<Double>) -> Double {
                    let moved = zip(points, clean).filter { p, light in
                        let d = simd_abs(Halftone.light(back(p), aa: aa) - light)
                        return max(d.x, d.y, d.z) > 0.25
                    }
                    return Double(moved.count) / Double(points.count)
                }
                for steps in 1...11 {
                    let share = changed { Tank.twist($0, rod: rod, angle: -Double(steps) * Tank.step) }
                    XCTAssertGreaterThan(share, 0.15, "\(layout) rod \(k) twist \(steps)")
                }
                for steps in [-3, -2, -1, 1, 2, 3] {
                    let share = changed { Tank.lens($0, rod: rod, steps: -Double(steps)) }
                    XCTAssertGreaterThan(share, 0.15, "\(layout) rod \(k) lens \(steps)")
                }
            }
        }
    }
}
