import struct SwiftUI.EnvironmentValues
import XCTest
import simd
@testable import Unstir

final class UnstirTests: XCTestCase {
    /// The undo bank lives in the shared defaults, so every run starts it full.
    override func setUp() { UserDefaults.standard.removeObject(forKey: "undos.spent") }

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

    /// Nightmare 11 as the player unstirred it: the picture came back while the old rule still held 21 entries.
    func testNightmare11UnstirsToEmpty() {
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

    /// The old rule's stack on nightmare 11, captured by debugger, less its bottom 0:+4: the identity. Taking a twist off the
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
        XCTAssertEqual(Level.all.map(\.scramble.count), par)
        XCTAssertEqual(Level.all.filter(\.replay).count, 3)
    }

    /// Against the design table's inversion column.
    func testInversions() {
        XCTAssertEqual(Level.all.map { $0.layout.inversions($0.scramble) },
                       [0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 1, 2, 0, 1, 1, 2, 2, 0, 1, 2, 3, 0, 1, 2, 3, 4])
    }

    /// Twice each level's par, strictly more inversions (against the nightmare design table), and room to stir on top.
    func testNightmare() {
        let nightmare = Level.nightmare
        XCTAssertEqual(nightmare.map(\.layout), Level.all.map(\.layout))
        XCTAssertEqual(nightmare.map(\.scramble.count), Level.all.map { 2 * $0.scramble.count })
        let inversions = nightmare.map { $0.layout.inversions($0.scramble) }
        XCTAssertEqual(inversions, [1, 1, 2, 2, 3, 3, 4, 4, 2, 3, 4, 5, 6, 3, 4, 3, 6, 7, 4, 5, 6, 8, 5, 6, 8, 10, 12])
        for (n, level) in zip(inversions, Level.all) { XCTAssertGreaterThan(n, level.layout.inversions(level.scramble), level.id) }
        XCTAssertFalse(nightmare.contains(where: \.replay))
        XCTAssertGreaterThanOrEqual(Tank.maxStack - nightmare.map(\.scramble.count).max()!, 8)
    }

    /// Nightmare's scrambles under ids of their own: a nightmare best or start must never open a Nightmare+ level or spend
    /// its first try.
    func testNightmarePlusKeepsItsOwnProgress() {
        XCTAssertEqual(Level.nightmarePlus.map(\.scramble), Level.nightmare.map(\.scramble))
        XCTAssertTrue(Set(Level.nightmarePlus.map(\.id)).isDisjoint(with: (Level.all + Level.nightmare).map(\.id)))
        XCTAssertTrue(Level.nightmarePlus.allSatisfy { $0.nightmare && $0.plus && $0.picture == .nightmarePlus })
        XCTAssertFalse((Level.all + Level.nightmare).contains(where: \.plus))
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
