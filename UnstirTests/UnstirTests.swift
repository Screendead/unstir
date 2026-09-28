// Copyright © 2026 Jack Lusher. All rights reserved.

import Metal
import os
import struct SwiftUI.EnvironmentValues
import XCTest
import simd
@testable import Unstir

final class UnstirTests: XCTestCase {
    /// The undo bank and the tank's lesson live in the shared defaults, so every run starts with the bank full and the
    /// tank never turned.
    override func setUp() {
        UserDefaults.standard.removeObject(forKey: "undos.spent")
        UserDefaults.standard.removeObject(forKey: "tank.turned")
    }

    func testPush() {
        var s: [Twist] = [Twist(rod: 0, steps: 3)]
        XCTAssertEqual(s.commit(rod: 1, steps: -2, in: .tri), .pushed)
        XCTAssertEqual(s, [Twist(rod: 0, steps: 3), Twist(rod: 1, steps: -2)])
    }

    func testSameRodReduces() {
        var s: [Twist] = [Twist(rod: 2, steps: 5)]
        XCTAssertEqual(s.commit(rod: 2, steps: -2, in: .tri), .reduced)
        XCTAssertEqual(s, [Twist(rod: 2, steps: 3)])
    }

    func testCancelPopsAndEmptyIsSolved() {
        var s: [Twist] = [Twist(rod: 1, steps: 4), Twist(rod: 0, steps: 3)]
        XCTAssertEqual(s.commit(rod: 0, steps: -3, in: .tri), .cancelled)
        XCTAssertEqual(s, [Twist(rod: 1, steps: 4)])
        XCTAssertFalse(s.isEmpty)
        XCTAssertEqual(s.commit(rod: 1, steps: -4, in: .tri), .cancelled)
        XCTAssertTrue(s.isEmpty)
    }

    func testSeparateRodsCommute() {
        var s = [Twist].parse("0:+3,2:-4", in: .quad)
        XCTAssertEqual(s.commit(rod: 0, steps: -3, in: .quad), .cancelled)
        XCTAssertEqual(s.commit(rod: 2, steps: 4, in: .quad), .cancelled)
        XCTAssertTrue(s.isEmpty)
    }

    func testOverlappingTwistThatDoesNotCommutePushes() {
        var s = [Twist].parse("0:+3,1:+4", in: .quad)
        XCTAssertEqual(s.commit(rod: 0, steps: -3, in: .quad), .pushed)
    }

    /// After 1:+4 no point of rod 0's disc comes within reach of rod 2, so the word holds that disc still and every rod 0
    /// twist commutes with it, though rod 0 overlaps rod 1.
    func testTwistCommutesWithAWordThatHoldsItsDiscStill() {
        let stack = [Twist].parse("0:+1,2:+2,1:+4,2:-6,1:-4", in: .quad)
        for steps in [1, -5, 11] { XCTAssertTrue(Layout.quad.commutes(stack, above: 0, rod: 0, steps: steps)) }
    }

    /// Whirlpool 11 as the player unstirred it: the picture came back while the old rule still held 21 entries.
    func testWhirlpool11UnstirsToEmpty() {
        var s = [Twist].parse("0:+4,1:-4,3:+2,0:-6,3:+7,0:-5,2:+2,1:+4,2:-6,1:-6", in: .quad)
        let moves = [(1, 2), (0, 11), (1, 4), (2, 6), (1, -4), (2, -2), (1, 4), (0, -6), (3, -7), (0, 6), (3, -2), (0, -4)]
        XCTAssertFalse(moves.map { s.commit(rod: $0.0, steps: $0.1, in: .quad) }.contains(.pushed))
        XCTAssertTrue(s.isEmpty)
    }

    /// 2:+6 cancels 2:-6 through a word that holds rod 2's disc still, which leaves 1:+4 and 1:-6 touching: they must
    /// merge then, so taking the rest of the rod 1 seam off later cancels.
    func testCancelBelowTheTopMergesWhatItUncovers() {
        var s = [Twist].parse("0:+4,1:-4,3:+2,0:-6,3:+7,0:-5,2:+2,1:+4,2:-6,1:-6", in: .quad)
        for (rod, steps) in [(0, 11), (1, 6), (2, 6), (1, -6), (0, -11)] { s.commit(rod: rod, steps: steps, in: .quad) }
        XCTAssertEqual(s.commit(rod: 1, steps: 2, in: .quad), .cancelled)
    }

    /// The old rule's stack on whirlpool 11, captured by debugger, less its bottom 0:+4: the identity. Taking a twist off the
    /// top leaves it standing, so only the fine pass can call the win.
    @MainActor func testIdentityStackIsSolved() async throws {
        let captured = "1:-4 3:+2 0:-6 3:+7 0:-5 2:+2 1:+4 2:-6 1:-4 0:+11 1:+4 2:+6 1:-4 2:-2 1:+4 0:-6 3:-7 0:+6 3:-2 0:+1"
        let scramble = captured.split(separator: " ").map { t in Twist(rod: Int(t.prefix(1))!, steps: Int(t.dropFirst(2))!) }
        let game = Game(level: Level(id: "test", label: "", title: "", layout: .quad, scramble: scramble))
        game.commit(rod: 0, steps: -1)
        XCTAssertFalse(game.solved)
        // The fine pass runs off the main actor, about 1 s in Debug.
        let deadline = ContinuousClock.now + .seconds(10)
        while !game.solved, .now < deadline { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(game.solved)
    }

    @MainActor func testResetZeroesMovesButCostsClean() {
        let game = Game(level: Level(id: "test-reset", label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)]))
        XCTAssertTrue(game.firstTry)
        game.commit(rod: 0, steps: -2)
        game.reset()
        XCTAssertEqual(game.moves, 0)
        game.commit(rod: 0, steps: -4)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.over, 0)
        XCTAssertFalse(game.clean)
    }

    /// At par the newest stir can still be adjusted or undone, but a new stir ends the run.
    @MainActor func testEndlessEndsOnTheFirstStirPastPar() {
        let game = Game(level: .endless(Run(seed: 7)))
        for i in 0..<game.par { game.commit(rod: i % 2, steps: 1) }
        let last = (game.par - 1) % 2
        game.commit(rod: last, steps: 1)
        XCTAssertEqual(game.moves, game.par)
        game.undo()
        XCTAssertEqual(game.moves, game.par - 1)
        XCTAssertEqual(Best.undos, 9)
        game.commit(rod: last, steps: 1)
        XCTAssertFalse(game.finished)
        game.commit(rod: 1 - last, steps: 1)
        XCTAssertTrue(game.finished)
        XCTAssertFalse(game.solved)
    }

    /// Only the newest stir comes back free; turning an older rod back is a new stir.
    @MainActor func testTurnsOfOneRodInARowAreOneStir() {
        let game = Game(level: Level(id: "test-stir", label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)]))
        game.commit(rod: 0, steps: -1)
        game.commit(rod: 0, steps: 5)
        XCTAssertEqual(game.history, [Twist(rod: 0, steps: 4)])
        game.commit(rod: 0, steps: -4)
        XCTAssertEqual(game.moves, 0)
        game.commit(rod: 0, steps: 2)
        game.commit(rod: 1, steps: 1)
        game.commit(rod: 1, steps: -1)
        XCTAssertEqual(game.moves, 1)
        game.commit(rod: 0, steps: -2)
        XCTAssertEqual(game.history, [Twist(rod: 0, steps: 2), Twist(rod: 0, steps: -2)])
    }

    /// An undo takes back a whole stir, gives its move back and costs the clean; the stir before stays shut, and an
    /// empty bank refuses.
    @MainActor func testUndoSpendsTheBank() {
        Best.undos = 2
        let scramble = [Twist(rod: 0, steps: 4)]
        let atPar = Game(level: Level(id: "test-undo", label: "", title: "", layout: .tri, scramble: scramble))
        atPar.commit(rod: 1, steps: 1)
        atPar.commit(rod: 1, steps: 2)
        atPar.undo()
        XCTAssertEqual(atPar.moves, 0)
        atPar.commit(rod: 0, steps: -4)
        XCTAssertTrue(atPar.solved)
        XCTAssertEqual(atPar.over, 0)
        XCTAssertFalse(atPar.clean)

        let game = Game(level: Level(id: "test-undo-2", label: "", title: "", layout: .tri, scramble: scramble))
        game.commit(rod: 0, steps: 2)
        game.commit(rod: 2, steps: 1)
        game.undo()
        game.commit(rod: 0, steps: -2)
        XCTAssertEqual(game.history, [Twist(rod: 0, steps: 2), Twist(rod: 0, steps: -2)])
        XCTAssertEqual(Best.undos, 0)
        game.undo()
        XCTAssertEqual(game.moves, 2)
    }

    /// Unstirred back to the clean picture it opened on, the sandbox plays on; new rods clear the stir. Its undos are free.
    @MainActor func testSandboxNeverFinishes() {
        Best.undos = 0
        let game = Game(level: .sandbox)
        game.commit(rod: 1, steps: 1)
        game.undo()
        XCTAssertEqual(game.moves, 0)
        XCTAssertEqual(Best.undos, 0)
        game.commit(rod: 0, steps: 3)
        game.commit(rod: 0, steps: -3)
        game.commit(rod: 2, steps: 1)
        XCTAssertEqual(game.stack, [Twist(rod: 2, steps: 1)])
        game.nextLayout()
        XCTAssertEqual(game.stack, [])
    }

    /// An endless pent tank the player saw smudged where rods 1 and 2 overlap: 32 px at most, about 40 px across.
    func testVisibleSmudgeIsNotSolved() {
        let stack = [Twist].parse("2:-2,4:-3,3:-5,1:-4,4:+6,2:+2,1:+2,0:-7,4:-6,2:-2,3:+5,4:+6,0:+7,4:-3,2:+2,1:-2,2:-2,1:+4,2:+2",
                                  in: .pent)
        XCTAssertFalse(Layout.pent.looksSolved(stack))
        XCTAssertFalse(Layout.pent.same(stack, [], at: Tank.grid(Tank.pixelGrid), within: Tank.halfPixel), "the 2 px grid alone")
    }

    func testSameRodAnglesAdd() {
        for _ in 0..<1000 {
            let p = SIMD2(Double.random(in: -1...1), Double.random(in: -1...1))
            let rod = Layout.allCases.randomElement()!.rods.randomElement()!
            let a = Double.random(in: -6...6), b = Double.random(in: -6...6)
            let twice = Tank.twist(Tank.twist(p, rod: rod, angle: a), rod: rod, angle: b)
            XCTAssertLessThan(simd_distance(twice, Tank.twist(p, rod: rod, angle: a + b)), 1e-9)
        }
    }

    func testForwardThenInverseReturnsPoint() {
        for _ in 0..<1000 {
            let p = SIMD2(Double.random(in: -1...1), Double.random(in: -1...1))
            let rods = Layout.allCases.randomElement()!.rods
            let word = (0..<6).map { _ in (rods.randomElement()!, Double.random(in: -9...9) * Tank.step) }
            var q = p
            for (rod, a) in word { q = Tank.twist(q, rod: rod, angle: a) }
            for (rod, a) in word.reversed() { q = Tank.twist(q, rod: rod, angle: -a) }
            XCTAssertLessThan(simd_distance(q, p), 1e-9)
        }
    }

    func testLayoutGeometry() {
        let overlapping: [Layout: Int] = [.tri: 3, .quad: 4, .eye: 5, .pent: 5, .hex: 12]
        for layout in Layout.allCases {
            let rods = layout.rods
            var pairs = 0, reached: Set = [0], todo = [0]
            for (i, a) in rods.enumerated() {
                XCTAssertLessThanOrEqual(simd_length(SIMD2(a.x, a.y)) + a.z, 1 + 1e-9, "\(layout) rod \(i) leaves the tank")
                for (j, b) in rods.enumerated() where j > i {
                    let gap = simd_distance(SIMD2(a.x, a.y), SIMD2(b.x, b.y)) - Tank.plateau * (a.z + b.z)
                    XCTAssertGreaterThan(gap, 0, "\(layout) cores \(i) and \(j) touch")
                    if layout.overlaps(i, j) { pairs += 1 }
                }
            }
            while let i = todo.popLast() {
                for j in rods.indices where layout.overlaps(i, j) && reached.insert(j).inserted { todo.append(j) }
            }
            XCTAssertEqual(pairs, overlapping[layout], "\(layout)")
            XCTAssertEqual(reached.count, rods.count, "\(layout) overlap graph is not connected")
        }
    }

    /// Any undo-able twist, taken in any order, cancels; and the picture comes back exactly.
    func testUndoInAnyLegalOrder() {
        for layout in Layout.allCases {
            for seed in 0..<100 as Range<UInt64> {
                var rng = SplitMix64(state: seed)
                let word = layout.scramble(depth: 8, inversions: 2, rng: &rng)
                XCTAssertEqual(word.count, 8)
                let points = (0..<20).map { _ in SIMD2(Double.random(in: -1...1), Double.random(in: -1...1)) }
                var q = points.map { p in word.reduce(p) { Tank.twist($0, rod: layout.rods[$1.rod], angle: Double($1.steps) * Tank.step) } }
                var stack = word
                while let i = layout.removable(stack).randomElement() {
                    let t = stack[i]
                    XCTAssertEqual(stack.commit(rod: t.rod, steps: -t.steps, in: layout), .cancelled)
                    q = q.map { Tank.twist($0, rod: layout.rods[t.rod], angle: -Double(t.steps) * Tank.step) }
                }
                XCTAssertTrue(stack.isEmpty)
                for (a, b) in zip(q, points) { XCTAssertLessThan(simd_distance(a, b), 1e-9, "\(layout) seed \(seed)") }
            }
        }
    }

    func testLevelsNeverMerge() {
        let par = [1, 1, 2, 2, 3, 3, 4, 3, 2, 4, 5, 6, 7, 4, 5, 3, 7, 8, 6, 7, 8, 9, 7, 8, 10, 12, 14]
        XCTAssertEqual(Level.plughole.map(\.scramble.count), par)
        XCTAssertEqual(Level.plughole.filter(\.replay).count, 3)
    }

    /// Against the design table's inversion column.
    func testInversions() {
        XCTAssertEqual(Level.plughole.map { $0.layout.inversions($0.scramble) },
                       [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 2, 0, 1, 1, 2, 2, 0, 1, 2, 3, 0, 1, 2, 3, 4])
    }

    /// Twice each level's par, strictly more inversions (against the whirlpool design table), and room to stir on top.
    func testWhirlpool() {
        let whirlpool = Level.whirlpool
        XCTAssertEqual(whirlpool.map(\.layout), Level.plughole.map(\.layout))
        XCTAssertEqual(whirlpool.map(\.scramble.count), Level.plughole.map { 2 * $0.scramble.count })
        let inversions = whirlpool.map { $0.layout.inversions($0.scramble) }
        XCTAssertEqual(inversions, [1, 1, 2, 2, 3, 3, 4, 4, 2, 3, 4, 5, 6, 3, 4, 3, 6, 7, 4, 5, 6, 8, 5, 6, 8, 10, 12])
        for (n, level) in zip(inversions, Level.plughole) { XCTAssertGreaterThan(n, level.layout.inversions(level.scramble), level.id) }
        XCTAssertFalse(whirlpool.contains(where: \.replay))
        XCTAssertGreaterThanOrEqual(Tank.maxStack - whirlpool.map(\.scramble.count).max()!, 8)
    }

    /// The menu stores the raw value, and declaration order is the ladder.
    func testTiers() {
        XCTAssertEqual(Tier.allCases.map(\.rawValue), ["plughole", "whirlpool", "maelstrom"])
        XCTAssertEqual(Tier.allCases.map(\.below), [nil, .plughole, .whirlpool])
    }

    /// Plughole is always open. Each tier above opens exactly when every level of the tier just below has a best at or
    /// under par, whatever its hints, and the developer unlock opens them all.
    func testTierGate() {
        var bests: [String: Best] = [:]
        func open(_ tier: Tier, unlocked: Bool = false) -> Bool { tier.isOpen(unlocked: unlocked) { bests[$0] } }
        XCTAssertEqual(Tier.allCases.map { open($0) }, [true, false, false])
        for level in Level.plughole.dropLast() { bests[level.id] = Best(over: 0, hints: 0, seconds: 30) }
        XCTAssertFalse(open(.whirlpool))
        bests[Level.plughole.last!.id] = Best(over: 1, hints: 0, seconds: 30)
        XCTAssertFalse(open(.whirlpool))
        XCTAssertEqual(Tier.plughole.atPar { bests[$0] }, Array(repeating: true, count: 26) + [false])
        bests[Level.plughole.last!.id] = Best(over: 0, hints: 3, seconds: 30)
        XCTAssertEqual(Tier.allCases.map { open($0) }, [true, true, false])
        // A maelstrom best opens nothing below it, and the tier just below is the only one that counts.
        for level in Level.maelstrom { bests[level.id] = Best(over: 0, hints: 0, seconds: 30) }
        XCTAssertFalse(open(.maelstrom))
        for level in Level.whirlpool { bests[level.id] = Best(over: 0, hints: 0, seconds: 30) }
        for level in Level.plughole { bests[level.id] = nil }
        XCTAssertEqual(Tier.allCases.map { open($0) }, [true, false, true])
        bests = [:]
        XCTAssertEqual(Tier.allCases.map { open($0, unlocked: true) }, [true, true, true])

        let flag = Best.unlocked
        defer { Best.unlocked = flag }
        Best.unlocked = true
        XCTAssertTrue(Tier.allCases.allSatisfy { $0.isOpen { _ in nil } })
        Best.unlocked = false
        XCTAssertFalse(Tier.whirlpool.isOpen { _ in nil })
    }

    /// A locked tier opened to look at is never stored, and a stored tier that has closed since comes back as the
    /// highest open one below it.
    func testStoredTierIsNeverLocked() {
        let saved = UserDefaults.standard.string(forKey: "tier")
        defer { UserDefaults.standard.set(saved, forKey: "tier") }
        UserDefaults.standard.removeObject(forKey: "tier")
        var opened: Set<Tier> = [.plughole]
        func stored() -> Tier { Tier.stored { opened.contains($0) } }
        func store(_ tier: Tier) { Tier.store(tier) { opened.contains($0) } }
        XCTAssertEqual(stored(), .plughole)
        store(.whirlpool)
        XCTAssertEqual(stored(), .plughole)
        opened.insert(.whirlpool)
        store(.whirlpool)
        XCTAssertEqual(stored(), .whirlpool)
        store(.maelstrom)
        XCTAssertEqual(stored(), .whirlpool)
        opened = Set(Tier.allCases)
        store(.maelstrom)
        XCTAssertEqual(stored(), .maelstrom)
        opened = [.plughole, .whirlpool]
        XCTAssertEqual(stored(), .whirlpool)
        opened = [.plughole]
        XCTAssertEqual(stored(), .plughole)
    }

    /// A drag switches tiers only when its first move runs at least twice as far sideways as up or down; anything
    /// steeper stays the scroll view's.
    func testOnlyASidewaysDragSwitchesTiers() {
        XCTAssertTrue(MenuView.isSideways(CGSize(width: -15, height: 0)))
        XCTAssertTrue(MenuView.isSideways(CGSize(width: 15, height: -7)))
        XCTAssertFalse(MenuView.isSideways(CGSize(width: 14, height: 7)))
        XCTAssertFalse(MenuView.isSideways(CGSize(width: -11, height: 11)))
        XCTAssertFalse(MenuView.isSideways(CGSize(width: 0, height: -15)))
    }

    private let slop = 0.04
    private func centre(_ layout: Layout, _ k: Int) -> SIMD2<Double> { SIMD2(layout.rods[k].x, layout.rods[k].y) }
    /// Where a finger at p lands after turning `length` round c, either way.
    private func carried(_ p: SIMD2<Double>, about c: SIMD2<Double>, _ length: Double) -> SIMD2<Double> {
        let d = p - c, a = length / simd_length(d)
        return c + SIMD2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a))
    }

    /// Deep in one disc a finger holds that rod the moment it lands.
    func testGrabInOneDiscIsImmediate() {
        for layout in Layout.allCases {
            for k in layout.rods.indices {
                let p = centre(layout, k) + SIMD2(0.05, 0.03)
                XCTAssertEqual(LevelView.grab(layout, seized: [], from: p, to: p, slop: slop), .rod(k), "\(layout) \(k)")
            }
        }
    }

    /// Near both tips of every lens, a turn about either centre holds that rod, whichever way it runs, once the finger
    /// has moved the slop; before that the finger holds every disc it is in, undecided.
    func testGrabNearLensTipsFollowsTheMotion() {
        for layout in Layout.allCases {
            let rods = layout.rods
            for i in rods.indices {
                for j in rods.indices where i < j && layout.overlaps(i, j) {
                    let a = centre(layout, i), b = centre(layout, j), d = simd_distance(a, b)
                    let x = (d * d + rods[i].z * rods[i].z - rods[j].z * rods[j].z) / (2 * d), h = sqrt(rods[i].z * rods[i].z - x * x)
                    let u = (b - a) / d, n = SIMD2(-u.y, u.x)
                    for tip in [a + u * x + n * h, a + u * x - n * h] {
                        let p = tip + simd_normalize(a + u * x - tip) * 0.03
                        let under = rods.indices.filter { simd_distance(p, centre(layout, $0)) < rods[$0].z }
                        XCTAssertEqual(LevelView.grab(layout, seized: [], from: p, to: p + SIMD2(0.02, 0), slop: slop), .undecided(under))
                        for k in [i, j] {
                            for length in [-1.5 * slop, 1.5 * slop] {
                                let q = carried(p, about: centre(layout, k), length)
                                XCTAssertEqual(LevelView.grab(layout, seized: [], from: p, to: q, slop: slop), .rod(k),
                                               "\(layout) lens \(i)-\(j) at \(p), turning \(k) by \(length)")
                            }
                        }
                    }
                }
            }
        }
    }

    /// On the line between two centres their tangents agree, so any motion falls back to the nearer centre in its own
    /// disc's radius. On the eye, a point nearer the small rod's centre is still nearer the big rod in radii.
    func testGrabOnTheCentreLineFallsBackToTheNearest() {
        func check(_ layout: Layout, _ i: Int, _ j: Int, at t: Double, _ want: Int) {
            let a = centre(layout, i), b = centre(layout, j), p = a + (b - a) * t, u = simd_normalize(b - a)
            for move in [SIMD2(-u.y, u.x), u, simd_normalize(u + SIMD2(-u.y, u.x))] {
                XCTAssertEqual(LevelView.grab(layout, seized: [], from: p, to: p + move * 1.5 * slop, slop: slop), .rod(want),
                               "\(layout) \(i)-\(j) at \(t), moving \(move)")
            }
        }
        check(.quad, 0, 1, at: 0.4, 0)
        check(.quad, 0, 1, at: 0.6, 1)
        check(.hex, 0, 3, at: 0.45, 0)
        let a = centre(.eye, 0), b = centre(.eye, 2), t = 0.37 / simd_distance(a, b), p = a + (b - a) * t
        XCTAssertLessThan(simd_distance(p, b), simd_distance(p, a))
        check(.eye, 0, 2, at: t, 0)
    }

    /// A seized knob is never held: alone under the finger it holds nothing but says which knob refused, and in an
    /// overlap the finger holds a working neighbour only when the motion picks that one, rather than being passed to it.
    /// Where knobs are seized the rim wins over the discs that reach it.
    func testGrabNeverHoldsASeizedKnob() {
        let a = centre(.quad, 0), b = centre(.quad, 1), p = (a + b) / 2 + SIMD2(0.25, 0)
        XCTAssertEqual(LevelView.grab(.quad, seized: [0], from: p, to: p, slop: slop), .undecided([1]))
        XCTAssertEqual(LevelView.grab(.quad, seized: [0], from: p, to: carried(p, about: b, slop * 1.5), slop: slop), .rod(1))
        XCTAssertEqual(LevelView.grab(.quad, seized: [0], from: p, to: carried(p, about: a, slop * 1.5), slop: slop), .seized(0))
        let nearer1 = p + SIMD2(0, 0.02)
        XCTAssertEqual(LevelView.grab(.quad, seized: [0, 1], from: nearer1, to: nearer1, slop: slop), .seized(1))
        XCTAssertEqual(LevelView.grab(.quad, seized: [0], from: a, to: a, slop: slop), .seized(0))
        XCTAssertEqual(LevelView.grab(.quad, seized: [0], from: .zero, to: .zero, slop: slop), .nothing)
        let rim = SIMD2(0.0, -0.95)
        XCTAssertEqual(LevelView.grab(.tri, seized: [1], from: rim, to: rim, slop: slop), .rim)
        XCTAssertEqual(LevelView.grab(.tri, seized: [], from: rim, to: rim, slop: slop), .rod(0))
        var rng = SplitMix64(state: 5)
        for _ in 0..<20000 {
            let layout = Layout.allCases[rng.below(Layout.allCases.count)]
            let seized = Set(layout.rods.indices.filter { _ in rng.below(3) == 0 })
            let start = SIMD2(Double.random(in: -1...1, using: &rng), Double.random(in: -1...1, using: &rng))
            let point = start + SIMD2(Double.random(in: -0.1...0.1, using: &rng), Double.random(in: -0.1...0.1, using: &rng))
            switch LevelView.grab(layout, seized: seized, from: start, to: point, slop: slop) {
            case .rod(let k):
                XCTAssertFalse(seized.contains(k))
                XCTAssertLessThan(simd_distance(start, centre(layout, k)), layout.rods[k].z)
            case .undecided(let ks):
                XCTAssertGreaterThan(ks.count, 0)
                XCTAssertTrue(ks.allSatisfy { !seized.contains($0) })
            case .seized(let k):
                XCTAssertTrue(seized.contains(k))
                XCTAssertLessThan(simd_distance(start, centre(layout, k)), layout.rods[k].z)
            case .rim, .nothing: break
            }
        }
    }

    /// Progress is stored by id: each is its tier's prefix and the level's number, and no two levels share one. The
    /// prefixes predate the tiers' names and stay, so a rename keeps what was played.
    func testLevelIdsMatchTheirTier() {
        XCTAssertEqual(Tier.allCases.map(\.prefix), ["L", "N", "N+"])
        for tier in Tier.allCases {
            XCTAssertEqual(tier.levels.map(\.id), tier.levels.indices.map { "\(tier.prefix)\($0 + 1)" })
            XCTAssertTrue(tier.levels.allSatisfy { $0.tier == tier }, tier.rawValue)
        }
        let ids = Tier.allCases.flatMap(\.levels).map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    /// Until maelstrom has levels of its own, whirlpool's scrambles on live pictures, under ids of their own so a
    /// whirlpool best or start never opens a maelstrom level or spends its first try.
    func testMaelstromKeepsItsOwnProgress() {
        XCTAssertEqual(Level.maelstrom.map(\.scramble), Level.whirlpool.map(\.scramble))
        XCTAssertTrue(Set(Level.maelstrom.map(\.id)).isDisjoint(with: (Level.plughole + Level.whirlpool).map(\.id)))
        XCTAssertTrue((Level.whirlpool + Level.maelstrom).allSatisfy(\.picture.isLive))
    }

    /// Against the design table. Coral reads only to 6 stirs and neurons to 14; each maelstrom level shows the twin of
    /// its whirlpool level's picture. The sandbox cycles every picture but the twins.
    func testWhirlpoolPictures() {
        XCTAssertEqual(Array(sequence(first: Picture.grid, next: \.next).prefix(9)),
                       [.grid, .sunset, .city, .glass, .chainmail, .coral, .neurons, .marbling, .grid])
        let table: [(Picture, [Int])] = [(.glass, [1, 9, 14, 19, 23, 26, 27]), (.chainmail, [3, 10, 13, 18, 21, 24]),
                                         (.coral, [2, 5, 8, 16]), (.neurons, [4, 7, 11, 17, 20]), (.marbling, [6, 12, 15, 22, 25])]
        var want = [Picture?](repeating: nil, count: 27)
        for (picture, levels) in table { for n in levels { want[n - 1] = picture } }
        XCTAssertEqual(Level.whirlpool.map(\.picture), want)
        XCTAssertLessThanOrEqual(Level.whirlpool.filter { $0.picture == .coral }.map(\.scramble.count).max()!, 6)
        XCTAssertLessThanOrEqual(Level.whirlpool.filter { $0.picture == .neurons }.map(\.scramble.count).max()!, 14)
        XCTAssertEqual(Level.maelstrom.map(\.picture), Level.whirlpool.map(\.picture.twin))
        let twins = Set(table.map(\.0.twin))
        XCTAssertEqual(twins.count, 5)
        XCTAssertTrue(twins.isDisjoint(with: table.map(\.0)))
    }

    /// A live picture's shader gets the clock mod its period, so its data must repeat with it. Not the glass's: its seeds
    /// wander on 7-13 s circles, so it takes the raw clock. A twin's data is its sibling's, then its heartbeat's delays,
    /// all repeating with the twin's minute; the glass's and the static web's twins can only check their delays.
    func testLiveDataRepeats() {
        typealias Builder = (Int, Double) -> [Float]
        let builders: [(Picture, Builder)] = [(.chainmail, Picture.links), (.coral, Picture.kernels), (.marbling, Picture.drops)]
        let delays: Builder = { Picture.delays(t: $1) }
        let twins: [(Picture, Builder)] = builders.map { picture, data in (picture.twin, { data($0, $1) + delays($0, $1) }) }
            + [(.glassTwin, delays), (.neuronsTwin, delays)]
        for (picture, data) in builders + twins {
            for seed in [0, 12, 27] {
                for t in [0.0, 1.7, 0.5 * picture.period, picture.period - 0.01] {
                    let a = data(seed, t), b = data(seed, t + picture.period)
                    XCTAssertEqual(a.count, b.count)
                    XCTAssertLessThan(zip(a, b).map { abs($0 - $1) }.max()!, 1e-5, "\(picture) seed \(seed) t \(t)")
                }
            }
        }
    }

    /// The neural web's shader draws only p's nearest node (by its own search) and that node's dendrites, so every line,
    /// glow, knob and soma must lie where that search finds its node. Checked against a brute force over every node in a
    /// 5 x 5 window, on each seed that shows the web (the sandbox's and its levels'), for the web and its twin, whose
    /// lines are checked inflamed and at the heartbeat's peak.
    func testNeuronsStayInTheirRegions() throws {
        guard let device = MTLCreateSystemDefaultDevice() else { throw XCTSkip("no Metal device") }
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Sources/Neurons.metal")
        let source = try String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "#include <SwiftUI/SwiftUI_Metal.h>", with: "")
            .replacingOccurrences(of: "[[ stitchable ]]", with: "") + """

            // x the line, y the glow, z the soma's reach at p: as the shader draws them, or over every node near p.
            static float3 probe(float2 p, float ipx, device const packed_float3 *cells, bool brute, bool twin) {
                const float wide = 0.1, high = 0.0866025, left = -1.2, top = -1.1258;
                const int n = 24, rows = 26;
                // A soma and its glow end within 0.0225 of its node (0.0262 in the twin), a knob within 0.0055 (0.0065 in
                // the twin, swollen by the beat).
                float hot = twin ? 1.0 : 0.0, grow = twin ? throb(1.0).x : 1.0;
                float rs = twin ? 0.0262 : 0.0225, rk = twin ? 0.0065 * grow : 0.0055, soma = 0;
                float2 ink = 0;
                if (!brute) {
                    float2 a;
                    float f, da, db;
                    int2 at = nearest(p, cells, a, f, da, db);
                    uint flags = uint(f);
                    float d = sqrt(da);
                    if (flags & 64u) soma = d < rs ? 1.0 - d / rs : 0.0;
                    else if (flags & 128u) ink = float2(saturate((rk - d) * ipx + 0.5), glow(d));
                    dendrites(p, cells, at, a, flags, hot, grow, twin, ipx, ink);
                    return float3(ink, soma);
                }
                int jc = int(floor((p.y - top) / high));
                for (int j = max(jc - 2, 0); j <= min(jc + 2, rows - 1); j++) {
                    int ic = int(floor((p.x - left) / wide - 0.5 * float(j & 1)));
                    for (int i = max(ic - 2, 0); i <= min(ic + 2, n - 1); i++) {
                        float3 cell = float3(cells[j * n + i]);
                        uint flags = uint(cell.z);
                        float d = distance(p, cell.xy);
                        if (flags & 64u) soma = max(soma, d < rs ? 1.0 - d / rs : 0.0);
                        else if (flags & 128u) ink = float2(max(ink.x, saturate((rk - d) * ipx + 0.5)), ink.y + glow(d));
                        int odd = j & 1;
                        const int2 step[3] = {int2(1, 0), int2(odd, 1), int2(odd - 1, 1)};
                        for (int dir = 0; dir < 3; dir++) {
                            if ((flags & (1u << dir)) == 0u) continue;
                            float2 b = float3(cells[(j + step[dir].y) * n + i + step[dir].x]).xy;
                            edge(p, cell.xy, b, (flags >> (8u + 5u * uint(dir))) & 31u, hot, grow, twin, ipx, ink);
                        }
                    }
                }
                return float3(ink, soma);
            }

            // Counts the pixels whose line, glow or soma differ.
            kernel void scan(device const float *data [[buffer(0)]], device atomic_uint *bad [[buffer(1)]],
                             constant float &side [[buffer(2)]], constant uint &twin [[buffer(3)]],
                             uint2 gid [[thread_position_in_grid]]) {
                float2 p = (float2(gid) + 0.5) / side * 2.0 - 1.0;
                if (length_squared(p) > 1.0) return;
                device const packed_float3 *cells = (device const packed_float3 *)data;
                float3 s = probe(p, side / 2.0, cells, false, twin != 0u), b = probe(p, side / 2.0, cells, true, twin != 0u);
                if (abs(s.x - b.x) > 0.05) atomic_fetch_add_explicit(&bad[0], 1u, memory_order_relaxed);
                if (abs(s.y - b.y) > 0.01) atomic_fetch_add_explicit(&bad[1], 1u, memory_order_relaxed);
                if (abs(s.z - b.z) > 0.01) atomic_fetch_add_explicit(&bad[2], 1u, memory_order_relaxed);
            }
            """
        let library = try device.makeLibrary(source: source, options: nil)
        let scan = try device.makeComputePipelineState(function: try XCTUnwrap(library.makeFunction(name: "scan")))
        let queue = try XCTUnwrap(device.makeCommandQueue())
        var side = Float(2400)
        let seeds = [0, 4, 7, 11, 17, 20], webs = OSAllocatedUnfairLock(initialState: [Int: [Float]]())
        // A debug build takes most of a second over each web, so they build side by side.
        DispatchQueue.concurrentPerform(iterations: seeds.count) { k in
            let web = Picture.nodes(seed: seeds[k])
            webs.withLock { $0[seeds[k]] = web }
        }
        for seed in seeds {
            let data = webs.withLock { $0[seed]! }
            let cells = try XCTUnwrap(device.makeBuffer(bytes: data, length: 4 * data.count))
            for var twin: UInt32 in [0, 1] {
                let bad = try XCTUnwrap(device.makeBuffer(length: 12))
                memset(bad.contents(), 0, 12)
                let cb = try XCTUnwrap(queue.makeCommandBuffer()), enc = try XCTUnwrap(cb.makeComputeCommandEncoder())
                enc.setComputePipelineState(scan)
                enc.setBuffer(cells, offset: 0, index: 0)
                enc.setBuffer(bad, offset: 0, index: 1)
                enc.setBytes(&side, length: 4, index: 2)
                enc.setBytes(&twin, length: 4, index: 3)
                enc.dispatchThreads(MTLSize(width: Int(side), height: Int(side), depth: 1),
                                    threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
                enc.endEncoding()
                cb.commit()
                cb.waitUntilCompleted()
                XCTAssertNil(cb.error)
                let n = bad.contents().bindMemory(to: UInt32.self, capacity: 3)
                XCTAssertEqual([n[0], n[1], n[2]], [0, 0, 0], "line, glow and soma pixels off, seed \(seed)\(twin == 1 ? " twin" : "")")
            }
        }
    }

    /// The glass turned by `angle` clockwise about the centre, as the shader turns it.
    private func turned(_ p: SIMD2<Double>, _ angle: Double) -> SIMD2<Double> {
        SIMD2(p.x * cos(angle) - p.y * sin(angle), p.x * sin(angle) + p.y * cos(angle))
    }

    /// Each step of the tank sets every rod's centre down on a rod of the same size, the hub on itself, and `order` steps
    /// come back round.
    func testTankStepsLandRodsOnRodsOfTheSameSize() {
        for layout in Layout.allCases {
            let rods = layout.rods
            XCTAssertEqual(Double(layout.order) * layout.tankStep, 2 * .pi, accuracy: 1e-12)
            for f in -layout.order...(2 * layout.order) {
                let slots = rods.indices.map { layout.slot(of: $0, at: f) }
                XCTAssertEqual(Set(slots).count, rods.count, "\(layout) at \(f) is not a permutation")
                XCTAssertEqual(slots, rods.indices.map { layout.slot(of: $0, at: f + layout.order) })
                for (k, j) in slots.enumerated() {
                    XCTAssertEqual(layout.knob(over: j, at: f), k)
                    let c = turned(SIMD2(rods[j].x, rods[j].y), Double(f) * layout.tankStep)
                    XCTAssertLessThan(simd_distance(c, SIMD2(rods[k].x, rods[k].y)), 1e-12, "\(layout) knob \(k) at \(f)")
                    XCTAssertEqual(rods[j].z, rods[k].z)
                }
            }
            XCTAssertNotEqual(layout.slot(of: 1, at: 1), 1, "\(layout) does not turn")
        }
        XCTAssertTrue((0..<6).allSatisfy { Layout.hex.slot(of: 0, at: $0) == 0 })
    }

    /// Turning knob k on the turned glass does exactly what turning its slot does to the picture underneath: the glass's
    /// turn carries the slot's twist onto the knob. Every layout, position and rod, on the points merges are judged on.
    func testTurnedTankConjugatesTwists() {
        for layout in Layout.allCases {
            let rods = layout.rods
            for f in 0..<layout.order {
                let angle = Double(f) * layout.tankStep
                for k in rods.indices {
                    let slot = layout.slot(of: k, at: f), a = 5 * Tank.step
                    let worst = Tank.samples.map { p in
                        simd_distance(turned(Tank.twist(p, rod: rods[slot], angle: a), angle), Tank.twist(turned(p, angle), rod: rods[k], angle: a))
                    }.max()!
                    XCTAssertLessThan(worst, 1e-12, "\(layout) knob \(k) at \(f)")
                }
            }
        }
    }

    /// A turn of the tank is one move and pushes nothing. Turns in a row join, and a joined turn netting a whole turn is
    /// gone, so turning away, probing and turning back costs nothing. Undo takes a turn back; reset goes home.
    @MainActor func testTankStirs() {
        let level = Level(id: "test-tank", label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)], seized: [0], fixedPar: 2)
        let game = Game(level: level)
        game.turnTank(1)
        game.turnTank(1)
        XCTAssertEqual(game.history, [Twist(rod: Game.tank, steps: -1)])
        XCTAssertEqual(game.stack, level.scramble)
        game.turnTank(1)
        XCTAssertEqual(game.moves, 0)
        XCTAssertEqual(game.position % 3, 0)
        game.turnTank(3)
        XCTAssertEqual(game.moves, 0)

        game.turnTank(-2)
        XCTAssertEqual(game.position, 1)
        // Knob 1 now sits over rod 0's fluid; a knob turned apart from a turn of the tank is a stir of its own.
        XCTAssertEqual(game.slot(of: 1), 0)
        game.commit(rod: 1, steps: 2)
        game.turnTank(1)
        XCTAssertEqual(game.moves, 3)
        XCTAssertEqual(game.history, [Twist(rod: Game.tank, steps: 1), Twist(rod: 0, steps: 2), Twist(rod: Game.tank, steps: 1)])
        game.undo()
        XCTAssertEqual(game.position, 1)
        game.undo()
        XCTAssertEqual(game.stack, level.scramble)
        XCTAssertEqual(game.moves, 1)
        game.reset()
        XCTAssertEqual(game.position, 0)
        XCTAssertEqual(game.moves, 0)

        game.turnTank(1)
        game.commit(rod: 1, steps: -4)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.moves, 2)
        XCTAssertEqual(game.par, 2)
        XCTAssertEqual(game.over, 0)
    }

    /// A drag of the rim counts the stir letting go would leave, so a turn that nets a whole one with the open stir
    /// counts nothing, and one past half a turn counts the short way round.
    @MainActor func testTankCountIsWhatLettingGoLeaves() {
        func game(_ layout: Layout, open: Int) -> Game {
            let game = Game(level: Level(id: "test-count", label: "", title: "", layout: layout, scramble: [Twist(rod: 0, steps: 4)]))
            game.turnTank(open)
            return game
        }
        XCTAssertEqual(game(.tri, open: 1).tankStir(after: 2), 0)
        XCTAssertEqual(game(.tri, open: 0).tankStir(after: 3), 0)
        XCTAssertEqual(game(.hex, open: 2).tankStir(after: 4), 0)
        XCTAssertEqual(game(.eye, open: 1).tankStir(after: 1), 0)
        XCTAssertEqual(game(.hex, open: 0).tankStir(after: 4), -2)
        for layout in Layout.allCases {
            for open in -layout.order...layout.order {
                for steps in -2 * layout.order...2 * layout.order {
                    let g = game(layout, open: open), counted = g.tankStir(after: steps)
                    g.turnTank(steps)
                    XCTAssertEqual(g.openStir?.steps ?? 0, counted, "\(layout) open \(open), turned \(steps)")
                }
            }
        }
    }

    /// A rod picked by motion catches up with the finger by under half a step, either way and across the wrap.
    func testAPickCatchesUpUnderHalfAStep() {
        XCTAssertLessThan(LevelView.catchUp, Tank.step / 2)
        for down in stride(from: -3.0, through: 3.0, by: 0.75) {
            for travel in stride(from: -0.6, through: 0.6, by: 0.05) {
                let now = atan2(sin(down + travel), cos(down + travel))
                XCTAssertEqual(now - LevelView.pickedFrom(down, now: now), min(max(travel, -LevelView.catchUp), LevelView.catchUp),
                               accuracy: 1e-9)
            }
        }
    }

    /// A seized knob refuses a turn even over fluid a working knob could take off; no level seizes the hub, which no turn
    /// of the tank moves, and only a level with a seized knob says it has one.
    @MainActor func testSeizedKnobs() {
        let game = Game(level: Level(id: "test-seized", label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)], seized: [0]))
        game.commit(rod: 0, steps: -4)
        XCTAssertEqual(game.moves, 0)
        XCTAssertEqual(game.stack, [Twist(rod: 0, steps: 4)])
        XCTAssertNil(game.reachable)
        game.turnTank(1)
        XCTAssertEqual(game.reachable, Twist(rod: 1, steps: -4))
        for level in Tier.allCases.flatMap(\.levels) {
            XCTAssertTrue(level.seized.isSubset(of: level.layout.rods.indices), level.id)
            XCTAssertLessThanOrEqual(level.seized.count, 2, level.id)
            if level.layout == .hex { XCTAssertFalse(level.seized.contains(0), level.id) }
            if level.note.contains("seize") { XCTAssertFalse(level.seized.isEmpty, level.id) }
        }
    }

    /// The rim shows how to turn the tank until the player has, on any level: a turn of the tank that commits sets the
    /// flag, and a stir of a rod or a whole turn of the tank does not. A flag the harness sets is never stored.
    @MainActor func testTurningTheTankSetsTheFlag() {
        let level = Level(id: "test-taught", label: "", title: "", layout: .tri, scramble: [Twist(rod: 0, steps: 4)], seized: [0])
        let game = Game(level: level)
        XCTAssertFalse(game.tankTurned)
        game.commit(rod: 1, steps: 2)
        XCTAssertEqual(game.moves, 1)
        game.turnTank(3)
        XCTAssertFalse(game.tankTurned)
        XCTAssertFalse(Best.tankTurned)
        game.turnTank(1)
        XCTAssertTrue(game.tankTurned)
        XCTAssertTrue(Best.tankTurned)
        XCTAssertTrue(Game(level: .sandbox).tankTurned)

        UserDefaults.standard.removeObject(forKey: "tank.turned")
        let harnessed = Game(level: level, tankTurned: false)
        harnessed.turnTank(1)
        XCTAssertTrue(harnessed.tankTurned)
        XCTAssertFalse(Best.tankTurned)
    }

    /// Until the seized levels set their own, par is one move per entry everywhere.
    func testParIsTheScrambleUnlessSet() {
        for level in Tier.allCases.flatMap(\.levels) { XCTAssertEqual(level.par, level.scramble.count, level.id) }
    }

    /// From the prototype, so the Swift generator draws exactly as it does.
    func testDailyAndEndlessVectors() {
        let daily: [(Int, Layout, String)] = [
            (1001, .eye, "0:-4,3:-5,0:-4,2:-5,0:-3,3:-2,1:+5,2:-8,3:+2,0:+7,1:-8,3:+8,2:+4"),
            (1002, .pent, "4:-2,0:+5,1:+4,3:-4,2:+6,1:-8,4:-3,3:+5,4:-7,3:+8,2:-3,1:-3,2:-4,3:-5"),
            (1225, .quad, "2:+3,3:-6,2:-8,0:-3,1:-3,0:+5,1:-3,3:+4,0:+7,2:-4,1:+8,2:-4,0:+2,3:+6"),
        ]
        for (md, layout, word) in daily {
            let date = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: md / 100, day: md % 100, hour: 12))!
            let level = Level.daily(date)
            XCTAssertEqual(level.layout, layout)
            XCTAssertEqual(level.scramble, [Twist].parse(word, in: layout))
        }
        let endless: [(Int, Layout, String)] = [
            (0, .quad, "0:-4,3:+7,1:+4,2:+8"),
            (3, .hex, "1:+4,5:+2,6:+4,2:+2,1:+6,6:+8,2:-4"),
            (9, .eye, "0:+4,2:+2,1:-2,2:+4,0:+7,3:-3,2:-4,0:+6,3:+7,2:-2,1:+8,3:-4,0:+7"),
        ]
        for (tank, layout, word) in endless {
            let level = Level.endless(Run(seed: 7, tank: tank))
            XCTAssertEqual(level.layout, layout)
            XCTAssertEqual(level.scramble, [Twist].parse(word, in: layout))
        }
    }

    /// The grid's node colours against the prototype's oklch (colour.py): its top and bottom rows, x = -1 ... 1.
    @MainActor func testGridColoursMatchPrototype() {
        let rows: [(Double, [UInt32])] = [
            (-1, [0x00BDB6, 0x00BAC7, 0x00B4ED, 0x65A6FF, 0x9996FF, 0xCA7BFF, 0xFF51DD, 0xFF6999, 0xFF735F, 0xF48200, 0xE19000]),
            (1, [0x007974, 0x007780, 0x007399, 0x0064CE, 0x6429FF, 0x9600D5, 0xB20098, 0xC0005C, 0xC50D00, 0x9E5200, 0x915B00]),
        ]
        for (y, hexes) in rows {
            for (k, hex) in hexes.enumerated() {
                let c = Picture.field(Double(k) * 0.2 - 1, y).resolve(in: EnvironmentValues())
                for (got, want) in zip([c.red, c.green, c.blue], [hex >> 16, hex >> 8, hex].map { Float($0 & 0xFF) }) {
                    XCTAssertEqual(got * 255, want, accuracy: 2, "node \(k) at y \(y)")
                }
            }
        }
    }
}
