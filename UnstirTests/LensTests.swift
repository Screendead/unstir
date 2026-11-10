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
        func same(_ a: String, _ b: String, within tolerance: Double = 1e-9) -> Bool {
            layout.same(a.isEmpty ? [] : word(a), b.isEmpty ? [] : word(b), at: Tank.samples, within: tolerance, lenses: lenses)
        }
        XCTAssertTrue(same("0:2,0:1", "0:3"))
        XCTAssertTrue(same("0:-2,0:3", "0:1"))
        XCTAssertTrue(same("0:3,0:-3", ""))
        // x4096 and back: rounding just inside the rim comes back 2^24 times over, still far under the merges' 1e-6.
        XCTAssertTrue(same("0:12,0:-12", "", within: 1e-7))
        XCTAssertFalse(same("0:12", ""), "a lens never wraps")
        var stack = [Twist]()
        XCTAssertEqual(stack.commit(rod: 0, steps: 1, in: layout, lenses: lenses), .pushed)
        XCTAssertEqual(stack.commit(rod: 0, steps: 2, in: layout, lenses: lenses), .reduced)
        XCTAssertEqual(stack, [Twist(rod: 0, steps: 3)])
        XCTAssertEqual(stack.commit(rod: 0, steps: -3, in: layout, lenses: lenses), .cancelled)
        XCTAssertEqual(stack, [])
    }

    /// A lens moves nothing from its core's rim out, so it fixes every point there exactly; inside, a step scales the
    /// centre by 2, and a positive one magnifies: the fluid moves outward.
    func testLensMovesOnlyItsCoreAndMagnifiesOnAPositiveStep() {
        for layout in Layout.allCases {
            for rod in layout.rods {
                let c = SIMD2(rod.x, rod.y)
                for steps in [-12.0, -3, -1, 0.5, 1, 3, 12] {
                    for u in [Tank.plateau, 0.61, 0.7, 0.95, 1.2] {
                        for a in stride(from: 0.0, to: 2 * .pi, by: 0.7) {
                            let p = c + u * rod.z * SIMD2(cos(a), sin(a)), q = Tank.lens(p, rod: rod, steps: steps)
                            // The rim itself is fixed by the flow, to rounding, which the flow scales by 2^(2|steps|)
                            // there; beyond it, nothing is computed.
                            if u == Tank.plateau {
                                XCTAssertEqual(simd_distance(q, p), 0, accuracy: 1e-15 * pow(2, 2 * abs(steps)), "\(layout) on the rim, steps \(steps)")
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
                XCTAssertEqual(simd_distance(Tank.lens(p, rod: rod, steps: 1), c) / (1e-4 * rod.z), 2, accuracy: 1e-4)
            }
        }
    }

    /// A lens's drag runs up and down: a finger gone up by `lensPitch` (y falls) is one positive step, which magnifies,
    /// and down the same is one negative; across, it does nothing.
    func testALensDraggedUpZoomsIn() {
        XCTAssertEqual(LevelView.lensTurn(from: 0.2, to: 0.2 - LevelView.lensPitch), Tank.step, accuracy: 1e-12)
        XCTAssertEqual(LevelView.lensTurn(from: -0.1, to: -0.1 + 2 * LevelView.lensPitch), -2 * Tank.step, accuracy: 1e-12)
        XCTAssertEqual(LevelView.lensTurn(from: 0.3, to: 0.3), 0)
    }

    /// Lens 01's ghost finger starts level with the knob, rides only down, the way that undoes the level's zoom, fades
    /// out at the foot and comes back at the top, showing fully halfway down.
    func testTheLensLessonRidesDownTheTrack() {
        let knob = CGPoint(x: 80, y: 100), step: CGFloat = 30
        func f(_ t: Double) -> (at: CGPoint, opacity: Double) { LensLesson.finger(knob: knob, core: 28, step: step, at: t) }
        XCTAssertEqual(f(0).at, CGPoint(x: 66, y: 100))
        XCTAssertEqual(f(0).opacity, 1)
        var y = f(0).at.y
        for t in stride(from: 0.1, through: 1.6, by: 0.1) {
            XCTAssertGreaterThan(f(t).at.y, y, "down at \(t) s")
            XCTAssertEqual(f(t).at.x, 66)
            y = f(t).at.y
        }
        XCTAssertEqual(f(1.6).at.y, 160, accuracy: 1e-9)
        XCTAssertEqual(f(LensLesson.middle).at.y, 130, accuracy: 1e-9)
        XCTAssertEqual(f(LensLesson.middle).opacity, 1)
        XCTAssertEqual(f(2.0).opacity, 0, accuracy: 1e-9)
        XCTAssertEqual(f(2.1).at.y, 100)
        XCTAssertEqual(f(2.2).at.y, f(0).at.y, accuracy: 1e-9)
        XCTAssertEqual(f(2.2 + 0.8).at.y, f(0.8).at.y, accuracy: 1e-9)
        for t in stride(from: 0.0, through: 4.4, by: 0.05) { XCTAssert((0...1).contains(f(t).opacity), "\(t) s") }
    }

    /// A drag that copies the lesson solves Lens 01 whatever the glass's size: it lands on the lens's knob, its track
    /// stands where the lesson's rail does, and its ride, through the lens's own turn and detent, is the level's `0:-2`.
    @MainActor func testCopyingTheLensLessonSolvesLens01() {
        let level = Pack.lens.levels[0]
        XCTAssertEqual(level.scramble, [Twist(rod: 0, steps: 2)])
        for r: CGFloat in [150, 167, 195, 215] {
            let rod = level.layout.rods[0], knob = CGPoint(x: r + rod.x * r, y: r + rod.y * r), core = 2 * Tank.coreRadius * r
            let top = LensLesson.finger(knob: knob, core: core, step: LevelView.lensPitch * r, at: 0).at
            let foot = LensLesson.finger(knob: knob, core: core, step: LevelView.lensPitch * r, at: 1.6).at
            let landing = SIMD2(Double((top.x - r) / r), Double((top.y - r) / r))
            XCTAssertEqual(LevelView.grab(level.layout, motion: level.motion, kind: level.kind(of:), at: landing), .rod(0), "r \(r)")
            XCTAssertEqual(LevelView.trackX(knob: knob.x, core: core, side: LevelView.trackSide(landing: landing.x, knob: rod.x)),
                           LensLesson.rail(knob: knob, core: core), "r \(r)")
            XCTAssertEqual(LensLesson.rail(knob: knob, core: core), LevelView.trackX(knob: knob.x, core: core, side: 1))
            let angle = LevelView.lensTurn(from: landing.y, to: Double((foot.y - r) / r))
            XCTAssertEqual(Detent.steps(angle, of: Tank.step), -2, "r \(r)")
        }
    }

    /// The lesson shows on Lens 01 alone, until it is solved, and in a game while no lens's stir is in the history: a
    /// twist's stir first leaves it up, and an undo of the lens's stir brings it back.
    @MainActor func testTheLensLessonShowsUntilALensCommit() {
        let one = Pack.lens.levels[0], two = Pack.lens.levels[1]
        XCTAssertEqual(one.lenses, [0])
        XCTAssertTrue(LensLesson.shows(level: one, history: [], best: nil))
        XCTAssertTrue(LensLesson.shows(level: one, history: [Twist(rod: 1, steps: 2)], best: nil))
        XCTAssertFalse(LensLesson.shows(level: one, history: [Twist(rod: 1, steps: 2), Twist(rod: 0, steps: -1)], best: nil))
        XCTAssertFalse(LensLesson.shows(level: one, history: [], best: Best(over: 0, seconds: 30, clean: true)))
        XCTAssertFalse(LensLesson.shows(level: two, history: [], best: nil))
        XCTAssertFalse(LensLesson.shows(level: Tier.plughole.levels[0], history: [], best: nil))
        let game = Game(level: one, tankTurned: true, swirled: true, bank: (5, nil))
        game.commit(rod: 0, steps: -1)
        XCTAssertFalse(LensLesson.shows(level: one, history: game.history, best: nil))
        game.undo()
        XCTAssertTrue(LensLesson.shows(level: one, history: game.history, best: nil))
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
        let kit = try ShaderKit("Unstir.metal", helpersOnly: true, kernels: """
            kernel void flow(device const float4 *in [[buffer(0)]], device float *out [[buffer(1)]],
                             uint i [[thread_position_in_grid]]) {
                out[i] = lensFlow(in[i].x, in[i].y, in[i].z, in[i].w);
            }
            """)
        var cases: [SIMD4<Float>] = []
        for k in -48...48 {
            for j in 1..<60 {
                cases.append(SIMD4(Float(Double(j) / 100), Float(Double(k) / 4 * Tank.lensRate), Float(Tank.plateau),
                                   Float(Tank.lensEdge)))
            }
        }
        let input = try kit.buffer(cases), output = try kit.buffer(Float.self, count: cases.count)
        try kit.run("flow", count: cases.count) { enc in
            enc.setBuffer(input, offset: 0, index: 0)
            enc.setBuffer(output, offset: 0, index: 1)
        }
        let got = kit.read(output, as: Float.self)
        for (i, c) in cases.enumerated() {
            let want = Tank.lensFlow(Double(c.x), Double(c.y))
            // A pixel at Pro Max size is about 1/568 of the tank's radius; this is a few hundredths of one.
            XCTAssertEqual(Double(got[i]), want, accuracy: 2e-5, "u \(c.x) t \(c.y)")
        }
    }

    /// The pack's table as `docs/lens-tables.md` gives it (table A, lenses on every rod size), pinned: a level's id
    /// keeps its best, so a row changes only on purpose.
    static let table: [(Layout, Set<Int>, String)] = [
        (.tri, [0], "0:+2"),
        (.tri, [0], "0:+1,1:+3"),
        (.tri, [0], "1:-2,2:+4,0:+3"),
        (.tri, [1], "0:+3,1:+2,2:-4,1:+1"),
        (.eye, [2], "0:-4,2:+2,1:+5,3:-3"),
        (.eye, [0], "2:+3,0:+2,1:-4,3:+5,0:+1"),
        (.tri, [0, 1], "2:+4,0:+2,1:+1"),
        (.quad, [0, 2], "1:+4,0:+2,3:-3,2:+3,1:-5,0:+1"),
        (.eye, [2, 3], "0:+3,2:+2,1:-4,3:+3,0:+2,2:+1"),
        (.tri, [2], "0:+3,2:+2,1:-5,0:-2,2:+1,1:+4"),
        (.quad, [1, 3], "0:+3,1:+3,2:-4,3:+2,0:-3,3:+1,2:+5"),
        (.eye, [0, 1], "2:+3,0:+2,3:-4,1:+3,2:-2,0:+1,3:+5"),
        (.hex, [1, 4], "0:+3,1:+2,2:-4,4:+3,6:+2,0:-2,5:+4"),
        (.hex, [2, 5], "3:-3,2:+2,0:+4,5:+1,6:-3,2:+1,4:+5,5:+2"),
        (.eye, [2], "1:+4,2:+1,0:-5,3:+3,2:+2,1:-3,0:+4,3:-2"),
        (.tri, [0], "1:+3,0:+1,2:-4,1:-2,0:+1,2:+5,1:+4,0:+1"),
        (.hex, [1, 3, 5], "0:+2,1:+3,2:-4,3:+2,4:+3,5:+1,6:-5,0:+4,5:+2"),
        (.quad, [0, 2], "1:+3,0:+1,3:-4,2:+2,1:+5,0:+2,3:+3,2:+1,1:-4"),
        (.hex, [0], "1:+3,0:+2,4:-3,2:+4,0:+1,5:-3,3:+2,6:+4"),
        (.hex, [0, 1, 4], "2:+3,0:+2,1:+3,5:-4,4:+2,3:+4,0:+1,6:-3,2:-2"),
        (.eye, [0, 3], "2:+4,0:+2,1:-5,3:+2,2:-3,0:+1,1:+4,3:+1,2:+3"),
        (.hex, [0, 2, 5], "1:+3,0:+1,2:+2,3:-4,6:+5,5:+3,4:-3,0:+2,1:-3,2:+1"),
        (.hex, [0], "3:+4,0:+1,6:-3,1:+5,0:+1,2:-4,4:+3,0:+1,5:-5,3:+2"),
        (.eye, [2, 3], "0:+4,2:+2,1:-3,3:+1,0:-4,3:+2,1:+5,2:+1,0:+3,1:-2"),
        (.hex, [0, 1, 3, 5], "2:+3,0:+1,1:+2,4:-4,3:+3,6:+3,0:+1,5:+2,2:-5,1:+1,4:+4,0:+1"),
    ]

    /// The pack's levels: the pinned table, each on the halftone with a lens, every dealt entry kept as dealt, every
    /// dealt lens entry magnifying by 1 to 3 steps and each lens netting at most +3, each lens in reach of a twist; par
    /// is the depth, and untwisting reaches it on a real game.
    @MainActor func testLensLevels() {
        XCTAssertEqual(Level.lens.count, 25)
        XCTAssertEqual(Level.lens.map(\.id), (1...25).map { "lens-\($0)" })
        XCTAssertEqual(Level.lensChapters, ["Close-up", "Cut-in", "Double-take", "Big Picture"])
        XCTAssertEqual(Level.lens.compactMap(\.chapter), [6, 6, 6, 7].enumerated().flatMap { c, n in
            Array(repeating: Level.lensChapters[c], count: n)
        })
        for (level, (layout, lenses, scramble)) in zip(Level.lens, Self.table) {
            XCTAssertEqual(level.layout, layout, level.id)
            XCTAssertEqual(level.lenses, lenses, level.id)
            XCTAssertEqual(level.scramble, .parse(scramble, in: layout, lenses: lenses), level.id)
            XCTAssertEqual(level.scramble.count, scramble.split(separator: ",").count, "\(level.id) merges as it is dealt")
            XCTAssertEqual(level.par, level.scramble.count, level.id)
            let solver = Solver(layout, lenses: lenses)
            for lens in lenses {
                XCTAssertTrue(layout.rods.indices.contains { !lenses.contains($0) && solver.interacts[lens][$0] },
                              "\(level.id): no twist reaches lens \(lens)")
            }
        }
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
            let game = Game(level: level, tankTurned: true, swirled: true, bank: (5, nil))
            while let t = game.reachable, !game.finished { game.commit(rod: t.rod, steps: t.steps) }
            XCTAssertTrue(game.solved, level.id)
            XCTAssertEqual(game.moves, level.par, level.id)
        }
    }

    /// Every Lens level's par, its depth, is the solver's optimum: no detour beats untwisting. Over a minute unoptimised,
    /// so slow; `scripts/lens-table.py docs/lens-tables.md --solve` checks the same in seconds.
    func testLensParIsTheOptimum() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1",
                          "slow: run with TEST_RUNNER_UNSTIR_SLOW_TESTS=1")
        for level in Level.lens {
            XCTAssertEqual(Solver(level.layout, lenses: level.lenses).optimum(level.scramble), level.par, level.id)
        }
    }

    /// A pack's undo puts a lens's entry back as the stir found it: a magnified core un-shrunk, a push taken off.
    @MainActor func testAPackUndoPutsALensBack() throws {
        let level = Level.lens[2]
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

    /// The least share of a rod's core that a step changes on a panel: a twist of 1 to 11 steps, or a lens of 1 to 3
    /// either way.
    private func leastChange(_ panel: Halftone.Panel, rod: SIMD3<Double>, lens: Bool) -> (share: Double, steps: Int) {
        let aa = 1.0 / 568, spacing = 1.0 / 48
        let c = SIMD2(rod.x, rod.y), reach = Tank.plateau * rod.z
        var points: [SIMD2<Double>] = []
        for y in stride(from: -reach, through: reach, by: spacing) {
            for x in stride(from: -reach, through: reach, by: spacing) where x * x + y * y < reach * reach {
                points.append(c + SIMD2(x, y))
            }
        }
        let clean = points.map { panel.light($0, aa: aa) }
        func changed(_ back: (SIMD2<Double>) -> SIMD2<Double>) -> Double {
            let moved = zip(points, clean).filter { p, light in
                let d = simd_abs(panel.light(back(p), aa: aa) - light)
                return max(d.x, d.y, d.z) > 0.25
            }
            return Double(moved.count) / Double(points.count)
        }
        let shares = lens
            ? [-3, -2, -1, 1, 2, 3].map { s in (changed { Tank.lens($0, rod: rod, steps: -Double(s)) }, s) }
            : (1...11).map { s in (changed { Tank.twist($0, rod: rod, angle: -Double(s) * Tank.step) }, s) }
        return shares.min { $0.0 < $1.0 }!
    }

    /// On the test panel, every step of every rod on every layout changes what shows inside its core, which is what the
    /// player reads: a twist turns the asymmetric linework, a lens swells the dots. Seconds alone, so slow.
    func testEveryStepMovesContrastingPixelsOnTheHalftone() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1",
                          "slow: run with TEST_RUNNER_UNSTIR_SLOW_TESTS=1")
        for layout in Layout.allCases {
            for (k, rod) in layout.rods.enumerated() {
                for lens in [false, true] {
                    let least = leastChange(Halftone.test, rod: rod, lens: lens)
                    XCTAssertGreaterThan(least.share, 0.15, "\(layout) rod \(k) \(lens ? "lens" : "twist") \(least.steps)")
                }
            }
        }
    }

    /// The same of each level's own panel, on its level: every step of each of its rods, a lens's as a lens and a
    /// twist's as a twist (`scripts/lens-panels.sh check` measures one panel the same way). Slow, as that is.
    func testEveryLensPanelShowsEachStepOnItsLevel() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1",
                          "slow: run with TEST_RUNNER_UNSTIR_SLOW_TESTS=1")
        for level in Level.lens {
            guard let panel = LensArt.levels[level.panel] else { continue }
            for (k, rod) in level.layout.rods.enumerated() {
                let least = leastChange(panel, rod: rod, lens: level.lenses.contains(k))
                XCTAssertGreaterThan(least.share, 0.15, "\(level.id) on \(panel.name), rod \(k), \(least.steps) steps")
            }
        }
    }

    /// A Lens level draws the panel of its number, and the test panel until that is drawn, as every other level's
    /// halftone does. A panel's name keys its bake in Caches, so no two share one.
    func testEachLensLevelDrawsItsOwnPanel() {
        XCTAssertEqual(Level.lens.map(\.panel), Array(1...25))
        XCTAssertTrue((Tier.allCases.flatMap(\.levels) + Level.prism + Level.escapement).allSatisfy { $0.panel == 0 })
        XCTAssertEqual(Halftone.panel(0).name, "test")
        XCTAssertEqual(Halftone.panel(1).name, "keyhole")
        XCTAssertTrue(LensArt.levels.keys.allSatisfy { (1...25).contains($0) })
        for n in 1...25 where LensArt.levels[n] == nil { XCTAssertEqual(Halftone.panel(n).name, "test") }
        XCTAssertEqual(Set(Halftone.panels.map(\.name)).count, Halftone.panels.count)
    }
}
