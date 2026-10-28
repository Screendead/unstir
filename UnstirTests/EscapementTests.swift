// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// Escapement's clocks, played on a real `Game` through the calls a finger makes: most on the second problem, the packs
/// mock-up's, and the book's 30 against its table.
@MainActor final class EscapementTests: XCTestCase {
    /// The second problem under an id of no pack level, so a win keeps no best.
    private func level(_ scramble: String? = nil) -> Level {
        var level = Level.escapement[1]
        level.id = "test-escapement"
        if let scramble { level.scramble = tri(scramble) }
        return level
    }
    private func game(_ scramble: String? = nil, bank: Int = 3) -> Game {
        Game(level: level(scramble), tankTurned: true, bank: (bank, nil))
    }
    private func tri(_ s: String) -> [Twist] { .parse(s, in: .tri) }

    /// Jack's call D1 (round 9): problem 1 is called "The clock", and the demonstration plays as it opens.
    func testTheFirstProblemIsTheClock() {
        let level = Level.escapement[0]
        XCTAssertEqual(level.id, "escapement-1")
        XCTAssertEqual(level.title, "The clock")
        XCTAssertEqual(level.pack, .escapement)
        XCTAssertEqual(level.scramble, tri("0:-1,1:+3,0:-1,2:-4"))
        XCTAssertEqual(level.clocks.map(\.rod), [0])
        XCTAssertEqual(level.par, 2)
        XCTAssertEqual(level.note, "Unstir in 2.")
        XCTAssertEqual(level.demo, tri("0:-3,1:+2"))
        XCTAssertTrue(Level.escapement.dropFirst().allSatisfy(\.demo.isEmpty))
    }

    func testTheSecondProblemIsTheMockUps() {
        let level = Level.escapement[1]
        XCTAssertEqual(level.id, "escapement-2")
        XCTAssertEqual(level.title, "The wait")
        XCTAssertEqual(level.scramble, tri("0:-1,1:+3,0:-2,2:-4"))
        XCTAssertEqual(level.clocks.map(\.rod), [0])
        XCTAssertEqual(level.kind(of: 0), .ratchet)
        XCTAssertEqual(level.motion, .none)
        XCTAssertEqual(level.par, 3)
        XCTAssertEqual(level.note, "Unstir in 3.")
    }

    func testTheComposedLineWinsInThree() {
        let g = game()
        g.commit(rod: 2, steps: 4)
        XCTAssertEqual(g.lastCommit?.result, .cancelled)
        // Its tick takes the clock's upper seam from -2 to -1.
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-1"))
        g.wait(on: 0)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3"))
        XCTAssertEqual(g.moves, 2)
        XCTAssertFalse(g.finished)
        g.commit(rod: 1, steps: -3)
        // The last move's tick empties the stack: solved on the spot.
        XCTAssertEqual(g.stack, [])
        XCTAssertTrue(g.solved)
        XCTAssertEqual(g.moves, 3)
        XCTAssertEqual(g.over, 0)
        XCTAssertEqual(g.clockStops, 1)
        XCTAssertEqual(g.escapement.ticks, [0: 3])
        XCTAssertFalse(g.lost)
    }

    /// Jack's call E1 (round 9): every let-go is final, so a tick that pushes loses on the move that made it.
    func testAPushedTickLosesAtOnce() {
        let g = game()
        g.commit(rod: 2, steps: 4)
        g.commit(rod: 1, steps: -3)
        // Rod 1 buries the clock's newest seam, so its tick pushes a +1 that nothing can ever pop.
        let slipped = g.stack
        XCTAssertEqual(slipped, tri("0:-1,1:+3,0:-1,1:-3") + [Twist(rod: 0, steps: 1)])
        XCTAssertEqual(g.overdue(0), 1)
        XCTAssertEqual(g.tickPushes, 1)
        XCTAssertEqual(g.pushedClock, 0)
        XCTAssertTrue(g.lost)
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.moves, 2)
        // Lost, nothing more is taken.
        g.commit(rod: 1, steps: 3)
        g.wait(on: 0)
        XCTAssertEqual(g.stack, slipped)
        XCTAssertEqual(g.moves, 2)
    }

    func testAWaitWhoseTickPushesIsLostAtOnce() {
        let g = game("0:-1,1:+3,0:-1")
        g.wait(on: 0)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3"))
        XCTAssertFalse(g.lost)
        g.wait(on: 0)
        XCTAssertEqual(g.overdue(0), 1)
        XCTAssertTrue(g.lost)
        XCTAssertEqual(g.moves, 2)
    }

    /// Jack's call E1: grabbing the knob just let go again is the next move, with a tick of its own, and takes nothing
    /// back: turning it straight back is two moves and two ticks, not none.
    func testTheSameKnobAgainIsAnotherMoveWithItsOwnTick() {
        let g = game()
        g.commit(rod: 2, steps: 4)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-1"))
        XCTAssertEqual(g.openStir, nil)
        g.commit(rod: 2, steps: -4)
        XCTAssertEqual(g.history, [Twist(rod: 2, steps: 4), Twist(rod: 2, steps: -4)])
        XCTAssertEqual(g.escapement.ticks, [0: 2])
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-1,2:-4") + [Twist(rod: 0, steps: 1)])
        XCTAssertTrue(g.lost)
    }

    func testTheClockRodIsNeverTurned() {
        let g = game()
        g.commit(rod: 0, steps: 2)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-2,2:-4"))
        XCTAssertEqual(g.moves, 0)
        XCTAssertEqual(g.escapement.ticks, [:])
    }

    /// Jack's call E2 (round 9): once the clock's own twists are gone it stops, and a picture still twisted then is lost.
    func testAClockThatStopsWithTwistsLeftIsLost() {
        let g = game("1:+3,0:-1")
        g.wait(on: 0)
        XCTAssertEqual(g.stack, tri("1:+3"))
        XCTAssertEqual(g.clockStops, 1)
        XCTAssertEqual(g.lastStopped, 0)
        XCTAssertNil(g.pushedClock)
        XCTAssertEqual(g.overdue(0), 0)
        XCTAssertTrue(g.lost)
        XCTAssertTrue(g.finished)
        // Lost, nothing more is taken.
        g.commit(rod: 1, steps: -3)
        XCTAssertEqual(g.stack, tri("1:+3"))
        XCTAssertEqual(g.moves, 1)
        g.undo()
        XCTAssertFalse(g.lost)
        XCTAssertEqual(g.stack, tri("1:+3,0:-1"))
    }

    /// The pack's undo: the move and its tick together, from the shared bank, on a lost tank too.
    func testUndoTakesTheMoveAndItsTick() {
        let g = game()
        g.commit(rod: 2, steps: 4)
        let s1 = g.stack
        g.commit(rod: 1, steps: -3)
        XCTAssertTrue(g.lost)
        g.undo()
        XCTAssertFalse(g.lost)
        XCTAssertEqual(g.stack, s1)
        XCTAssertEqual(g.overdue(0), 0)
        XCTAssertNil(g.pushedClock)
        XCTAssertEqual(g.escapement.ticks, [0: 1])
        XCTAssertEqual(g.moves, 1)
        XCTAssertEqual(g.bank, 2)
        // And the line still wins in three.
        g.wait(on: 0)
        g.commit(rod: 1, steps: -3)
        XCTAssertTrue(g.solved)
        XCTAssertEqual(g.moves, 3)
        XCTAssertEqual(g.over, 0)
    }

    func testAnEmptyBankLeavesTheLossStanding() {
        let g = game(bank: 0)
        g.commit(rod: 1, steps: 1)
        XCTAssertTrue(g.lost)
        g.undo()
        XCTAssertTrue(g.lost)
        XCTAssertEqual(g.moves, 1)
    }

    func testResetStartsTheClockAfresh() {
        let g = game()
        g.commit(rod: 1, steps: 1)
        XCTAssertTrue(g.lost)
        XCTAssertTrue(g.reset())
        XCTAssertFalse(g.lost)
        XCTAssertEqual(g.escapement.ticks, [:])
        XCTAssertEqual(g.moves, 0)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-2,2:-4"))
    }

    func testTheDemonstrationRunsOnItsOwnStackAndLeavesTheProblemUntouched() {
        var first = Level.escapement[0]
        first.id = "test-escapement"
        let g = Game(level: first, tankTurned: true, bank: (3, nil))
        XCTAssertEqual(g.level.demo, tri("0:-3,1:+2"))
        g.demo(g.level.demo)
        XCTAssertEqual(g.reachable, Twist(rod: 1, steps: -2))
        g.commit(rod: 1, steps: -2)
        XCTAssertEqual(g.stack, tri("0:-2"))
        g.wait(on: 0)
        XCTAssertEqual(g.stack, tri("0:-1"))
        XCTAssertFalse(g.finished)
        g.endDemo()
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-1,2:-4"))
        XCTAssertEqual(g.moves, 0)
        XCTAssertEqual(g.escapement.ticks, [:])
        XCTAssertEqual(g.resets, 0)
    }

    func testTheClockRodsDiscIsTheRatchet() {
        let level = Level.escapement[0], rods = level.layout.rods
        func grab(_ k: Int) -> Grab {
            LevelView.grab(level.layout, motion: level.motion, kind: level.kind(of:), at: SIMD2(rods[k].x, rods[k].y))
        }
        XCTAssertEqual(grab(0), .ratchet(0))
        XCTAssertEqual(grab(1), .rod(1))
    }

    // MARK: - The book

    /// The book's table (docs/escapement-problems.md, "The book at a glance"): layout, clocks in the order they tick
    /// (+ forward, - wound back), par and the one first move that reaches it.
    private static let book: [(layout: Layout, clocks: String, par: Int, key: String)] = [
        (.tri, "0+", 2, "2:+4"), (.tri, "0+", 3, "2:+4"), (.quad, "0+", 2, "2:+4"), (.quad, "0+", 4, "2:+2"),
        (.eye, "2+", 5, "3:+5"), (.hex, "1+", 6, "3:-2"),
        (.quad, "0+", 3, "wait"), (.pent, "0+", 5, "wait"), (.eye, "2+", 6, "3:-3"), (.pent, "0+", 6, "2:-3"),
        (.pent, "0+", 8, "3:+2"), (.hex, "1+", 7, "wait"),
        (.quad, "0+,2+", 3, "3:-2"), (.quad, "0+,2+", 4, "3:+3"), (.pent, "0+,2+", 5, "4:+5"), (.hex, "1+,4+", 6, "3:-2"),
        (.pent, "0+,1+", 5, "3:-5"), (.hex, "1+,2+", 6, "5:+4"),
        (.tri, "0-", 3, "2:-4"), (.quad, "0+,2-", 5, "1:-5"), (.pent, "0-,2+", 6, "wait"), (.hex, "1+,4-", 7, "5:-3"),
        (.pent, "0-", 6, "3:+4"), (.hex, "1-", 7, "6:+2"),
        (.hex, "1+,3+,5+", 3, "0:-3"), (.pent, "0+,2+", 8, "1:-2"), (.pent, "0+", 9, "2:-2"), (.hex, "1+", 9, "2:-4"),
        (.hex, "1+,3+,5+", 8, "4:-3"), (.hex, "1+,3+", 8, "0:-2"),
    ]

    private func clocks(_ level: Level) -> String {
        level.clocks.map { "\($0.rod)\($0.dir > 0 ? "+" : "-")" }.joined(separator: ",")
    }

    private func key(_ move: Move) -> String {
        switch move {
        case .wait: "wait"
        case let .stir(_, slot, steps): "\(slot):\(steps > 0 ? "+" : "")\(steps)"
        case .turn: "turn"
        }
    }

    /// The 30 problems in the book's order and its five chapters of six, the teachers and the finale under the book's
    /// titles but problem 1 (Jack's call D1), the rest by number.
    func testTheLevelsAreTheBook() {
        let levels = Level.escapement
        XCTAssertEqual(levels.count, 30)
        XCTAssertEqual(levels.map(\.id), (1...30).map { "escapement-\($0)" })
        XCTAssertEqual(levels.map(\.label), (1...30).map { String(format: "%02d", $0) })
        XCTAssertEqual(levels.compactMap(\.chapter), (0..<30).map { Level.escapementChapters[$0 / 6] })
        XCTAssertEqual(Level.escapementChapters, ["The Clock", "The Waiting Move", "Two Clocks", "Wound Back", "Grand Complication"])
        let titled = [1: "The clock", 2: "The wait", 3: "The dashed edge", 7: "The quiet first move", 13: "Two dials",
                      19: "Backwards", 25: "Three dials", 30: "Finale"]
        XCTAssertEqual(levels.map(\.title), (1...30).map { titled[$0] ?? "Problem \($0)" })
        for (level, row) in zip(levels, Self.book) {
            XCTAssertEqual(level.layout, row.layout, level.id)
            XCTAssertEqual(clocks(level), row.clocks, level.id)
            XCTAssertEqual(level.par, row.par, level.id)
            XCTAssertEqual(level.note, "Unstir in \(row.par).", level.id)
            XCTAssertEqual(level.motion, .none, level.id)
            XCTAssertTrue(level.seized.isEmpty && level.sockets.isEmpty, level.id)
            XCTAssertTrue(level.ratchets.allSatisfy { level.kind(of: $0) == .ratchet }, level.id)
        }
    }

    /// The app's table is the book's, scramble for scramble, where the book's table can be read.
    func testTheLevelsMatchTheBooksTable() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("scripts/escapement/problems.tsv")
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { throw XCTSkip("no problems.tsv at \(url.path)") }
        let rows = text.split(separator: "\n").map { $0.split(separator: "\t").map(String.init) }
        XCTAssertEqual(rows.count, 30)
        for (level, row) in zip(Level.escapement, rows) {
            XCTAssertEqual(level.id, "escapement-\(row[0])")
            XCTAssertEqual(level.layout.rawValue, row[1], level.id)
            XCTAssertEqual(clocks(level), row[2], level.id)
            XCTAssertEqual(level.scramble, .parse(row[3], in: level.layout), level.id)
        }
    }

    /// Every problem ships proved: its par is what its clocks owe, so no line is shorter, and the prover finds a line at
    /// par in whole heals and waits (every turn of ±1 to ±11 too, under UNSTIR_SLOW_TESTS), which wins on a real `Game`
    /// at par.
    func testEveryProblemsParIsTheProversOptimum() throws {
        let slow = ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1"
        for level in Level.escapement {
            let solver = Solver(level.layout), clocks = level.clocks, steps = slow ? (1...11).flatMap { [$0, -$0] } : []
            XCTAssertEqual(Solver.Clockwork(layout: level.layout, lenses: [], clocks: clocks, steps: []).owed(level.scramble),
                           level.par, level.id)
            var seen = 0
            XCTAssertNil(solver.escapement(level.scramble, clocks: clocks, limit: level.par - 1, steps: steps, seen: &seen),
                         level.id)
            let play = try XCTUnwrap(solver.escapement(level.scramble, clocks: clocks, limit: level.par, steps: steps,
                                                       seen: &seen), level.id)
            XCTAssertEqual(play.moves.count, level.par, level.id)
            var test = level
            test.id = "test-" + level.id
            let g = Game(level: test, tankTurned: true, bank: (0, nil))
            for move in play.moves {
                switch move {
                case let .stir(knob, _, steps): g.commit(rod: knob, steps: steps)
                case .wait: g.wait(on: clocks[0].rod)
                case .turn: XCTFail("a clock's tank never turns: \(level.id)")
                }
                XCTAssertFalse(g.lost, level.id)
            }
            XCTAssertTrue(g.solved, level.id)
            XCTAssertEqual(g.moves, level.par, level.id)
        }
    }

    /// Every problem has one key: among whole heals and waits, exactly one first move reaches par, and it is the book's.
    func testEveryProblemHasOneKey() {
        for (level, row) in zip(Level.escapement, Self.book) {
            let keys = Solver(level.layout).escapementKeys(level.scramble, clocks: level.clocks, par: level.par, steps: [])
            XCTAssertEqual(keys.map(key), [row.key], level.id)
        }
    }

    /// And among every turn of every knob, ±1 to ±11 steps: about a minute in an optimised build, so slow.
    func testEveryProblemHasOneKeyAmongEveryTurn() throws {
        guard ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1" else { throw XCTSkip("set UNSTIR_SLOW_TESTS=1") }
        for (level, row) in zip(Level.escapement, Self.book) {
            let keys = Solver(level.layout).escapementKeys(level.scramble, clocks: level.clocks, par: level.par)
            XCTAssertEqual(keys.map(key), [row.key], level.id)
        }
    }

    // MARK: - Several clocks

    /// Jack's call D1 (round 9): several clocks tick in turn, clockwise from twelve, whatever order they are listed in.
    func testClocksTickClockwiseFromTwelve() {
        func order(_ layout: Layout, _ ratchets: Set<Int>) -> [Int] {
            Level(id: "t", label: "", title: "", layout: layout, scramble: [], ratchets: ratchets).clocks.map(\.rod)
        }
        XCTAssertEqual(order(.hex, [5, 1, 3]), [1, 3, 5])
        XCTAssertEqual(order(.hex, [6, 2]), [2, 6])
        XCTAssertEqual(order(.quad, [3, 0]), [0, 3])
        XCTAssertEqual(order(.pent, [4, 1]), [1, 4])
        // Eye: top, right, bottom, left.
        XCTAssertEqual(order(.eye, [0, 1, 2, 3]), [2, 1, 3, 0])
    }

    /// Two dials (13): clock 0 stops after the second move with twists still on the picture, and that loses nothing while
    /// clock 2 runs; a tap on the stopped clock's ratchet still waits, and its tick finishes.
    func testOneClockStoppingWhileAnotherRunsLosesNothing() {
        var level = Level.escapement[12]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (0, nil))
        g.commit(rod: 3, steps: -2)
        XCTAssertEqual(g.tick.map(\.rod), [0, 2])
        g.commit(rod: 1, steps: -3)
        XCTAssertFalse(g.running(0))
        XCTAssertTrue(g.running(2))
        XCTAssertEqual(g.stops, [0: 1])
        XCTAssertFalse(g.lost)
        XCTAssertFalse(g.stack.isEmpty)
        g.wait(on: 0)
        XCTAssertEqual(g.tick.map(\.rod), [2])
        XCTAssertTrue(g.solved)
        XCTAssertEqual(g.moves, 3)
        XCTAssertEqual(g.escapement.ticks, [0: 2, 2: 3])
    }

    /// 17: clock 0 ticks first and uncovers clock 1's seam for its tick on the same move. With the order reversed no
    /// line exists, so the order is the rule, not a detail.
    func testTheTickOrderDecidesProblem17() {
        let level = Level.escapement[16]
        XCTAssertEqual(level.clocks.map(\.rod), [0, 1])
        var seen = 0
        let solver = Solver(level.layout)
        XCTAssertNotNil(solver.escapement(level.scramble, clocks: level.clocks, limit: level.par, seen: &seen))
        XCTAssertNil(solver.escapement(level.scramble, clocks: level.clocks.reversed(), limit: level.par, seen: &seen))
    }

    /// A tick that pushes loses at once, and no clock after it in the turn ticks.
    func testAPushedTickStopsTheTurn() {
        var level = Level.escapement[12]
        level.id = "test-escapement"
        let g = Game(level: level, tankTurned: true, bank: (1, nil))
        // Knob 3's seam lies over both clocks.
        g.wait(on: 2)
        XCTAssertTrue(g.lost)
        XCTAssertEqual(g.pushedClock, 0)
        XCTAssertEqual(g.tick.map(\.rod), [0])
        XCTAssertEqual(g.escapement.ticks, [0: 1])
        XCTAssertEqual(g.overdue(0), 1)
        XCTAssertEqual(g.overdue(2), 0)
    }

    /// Backwards (19): a wound-back clock ticks -1 over seams stirred clockwise, and a pushed tick of its own is a -1.
    func testAWoundBackClockTicksBack() {
        var level = Level.escapement[18]
        level.id = "test-escapement"
        XCTAssertEqual(level.clocks.map(\.dir), [-1])
        let g = Game(level: level, tankTurned: true, bank: (1, nil))
        g.commit(rod: 2, steps: -4)
        XCTAssertEqual(g.stack, tri("0:+1,1:-3,0:+1"))
        g.wait(on: 0)
        XCTAssertEqual(g.stack, tri("0:+1,1:-3"))
        g.commit(rod: 1, steps: 3)
        XCTAssertTrue(g.solved)
        XCTAssertEqual(g.moves, 3)
        let h = Game(level: level, tankTurned: true, bank: (1, nil))
        h.commit(rod: 1, steps: 3)
        XCTAssertTrue(h.lost)
        XCTAssertEqual(h.stack.last, Twist(rod: 0, steps: -1))
        XCTAssertEqual(h.overdue(0), 1)
    }

    /// Jack's call D1 (round 9): a move whose tick a full stack would refuse, as the 37th entry, is refused, the wait too.
    func testAMoveAFullStackWouldRefuseTheTickOfIsRefused() {
        var level = Level.escapement[1]
        level.id = "test-escapement"
        level.scramble = [Twist(rod: 0, steps: -1)] + (0..<35).map { Twist(rod: 1 + $0 % 2, steps: 1) }
        XCTAssertEqual(level.scramble.count, Tank.maxStack)
        let g = Game(level: level, tankTurned: true, bank: (1, nil))
        // Merges into the top entry, so the stack stays full, and the clock's tick would push a 37th.
        g.commit(rod: 1, steps: 1)
        g.wait(on: 0)
        XCTAssertEqual(g.stack, level.scramble)
        XCTAssertEqual(g.moves, 0)
        XCTAssertFalse(g.lost)
    }

    /// The prover finds nothing shorter than the composed line, and drops the lost lines: on 1:+3,0:-1, taking rod 1
    /// off first buries the clock's seam, so its tick pushes, and waiting first stops the clock with rod 1 still on.
    func testTheProverDropsLostLines() {
        var seen = 0
        let solver = Solver(.tri), clock: Solver.Clocks = [(0, 1)]
        XCTAssertNil(solver.escapement(tri("0:-1,1:+3,0:-2,2:-4"), clocks: clock, limit: 2, seen: &seen))
        XCTAssertEqual(solver.escapement(tri("0:-1,1:+3,0:-2,2:-4"), clocks: clock, limit: 3, seen: &seen)?.moves.count, 3)
        XCTAssertEqual(solver.escapement(tri("0:-1,1:+3"), clocks: clock, limit: 4, seen: &seen)?.moves.count, 1)
        XCTAssertNil(solver.escapement(tri("1:+3,0:-1"), clocks: clock, limit: 4, seen: &seen))
    }

    /// The lost rule: once a tick pushes, the clock holds a positive entry that no continuation pops, so the stack can
    /// never empty. Random small stacks on tri and quad, played at random until a tick pushes, then every continuation
    /// of one move (pushes and partial merges too), ticking after it; of two with UNSTIR_SLOW_TESTS=1, which takes
    /// minutes.
    func testAPushedTickNeverPops() {
        let depth = ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1" ? 2 : 1
        var random = SplitMix64(state: 2026_10_25)
        var cases = 0
        for trial in 0..<400 where cases < 40 {
            let layout: Layout = trial % 2 == 0 ? .tri : .quad, clock = 0, rods = layout.rods.count
            func tick(_ s: inout [Twist]) -> Commit? {
                s.contains { $0.rod == clock } ? s.commit(rod: clock, steps: 1, in: layout) : nil
            }
            func overdue(_ s: [Twist]) -> Int { s.filter { $0.rod == clock && $0.steps > 0 }.reduce(0) { $0 + $1.steps } }
            var stack: [Twist] = []
            for _ in 0..<(3 + random.below(3)) {
                let rod = random.below(rods)
                stack.commit(rod: rod, steps: rod == clock ? -1 - random.below(3) : (random.below(2) == 0 ? 1 : -1) * (1 + random.below(5)),
                             in: layout)
            }
            var pushed: [Twist]?
            for _ in 0..<6 where pushed == nil && !stack.isEmpty {
                if random.below(4) > 0 {
                    stack.commit(rod: 1 + random.below(rods - 1), steps: (random.below(2) == 0 ? 1 : -1) * (1 + random.below(5)),
                                 in: layout)
                }
                if tick(&stack) == .pushed { pushed = stack }
            }
            guard let start = pushed else { continue }
            cases += 1
            let owed = overdue(start)
            XCTAssertGreaterThan(owed, 0)
            var frontier = [start]
            for _ in 0..<depth {
                var next: [[Twist]] = []
                for s in frontier {
                    var after: [[Twist]] = [s]
                    for slot in 1..<rods {
                        for k in Set([1, 2, 3, 4, -1, -2, -3, -4] + s.filter { $0.rod == slot }.map { -$0.steps }) {
                            var t = s
                            if t.commit(rod: slot, steps: k, in: layout) != .refused { after.append(t) }
                        }
                    }
                    for var t in after {
                        _ = tick(&t)
                        XCTAssertFalse(t.isEmpty, "\(start) emptied")
                        XCTAssertGreaterThanOrEqual(overdue(t), owed, "\(start) to \(t)")
                        next.append(t)
                    }
                }
                frontier = next
            }
        }
        XCTAssertEqual(cases, 40)
    }
}
