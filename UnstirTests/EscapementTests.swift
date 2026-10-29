// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// Escapement's clock, played on a real `Game` through the calls a finger makes: the first problem, the packs mock-up's.
@MainActor final class EscapementTests: XCTestCase {
    /// The first problem under an id of no pack level, so a win keeps no best.
    private func level(_ scramble: String? = nil) -> Level {
        var level = Level.escapement[0]
        level.id = "test-escapement"
        if let scramble { level.scramble = tri(scramble) }
        return level
    }
    private func game(_ scramble: String? = nil, bank: Int = 3) -> Game {
        Game(level: level(scramble), tankTurned: true, bank: (bank, nil))
    }
    private func tri(_ s: String) -> [Twist] { .parse(s, in: .tri) }

    func testTheFirstProblemIsTheMockUps() {
        let level = Level.escapement[0]
        XCTAssertEqual(level.id, "escapement-1")
        XCTAssertEqual(level.pack, .escapement)
        XCTAssertEqual(level.scramble, tri("0:-1,1:+3,0:-2,2:-4"))
        XCTAssertEqual(level.clock, 0)
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
        XCTAssertEqual(g.escapement.ticks, 3)
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
        XCTAssertEqual(g.overdue, 1)
        XCTAssertEqual(g.tickPushes, 1)
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
        XCTAssertEqual(g.overdue, 1)
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
        XCTAssertEqual(g.escapement.ticks, 2)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-1,2:-4") + [Twist(rod: 0, steps: 1)])
        XCTAssertTrue(g.lost)
    }

    func testTheClockRodIsNeverTurned() {
        let g = game()
        g.commit(rod: 0, steps: 2)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-2,2:-4"))
        XCTAssertEqual(g.moves, 0)
        XCTAssertEqual(g.escapement.ticks, 0)
    }

    /// Jack's call E2 (round 9): once the clock's own twists are gone it stops, and a picture still twisted then is lost.
    func testAClockThatStopsWithTwistsLeftIsLost() {
        let g = game("1:+3,0:-1")
        g.wait(on: 0)
        XCTAssertEqual(g.stack, tri("1:+3"))
        XCTAssertEqual(g.clockStops, 1)
        XCTAssertEqual(g.overdue, 0)
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
        XCTAssertEqual(g.overdue, 0)
        XCTAssertEqual(g.escapement.ticks, 1)
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
        XCTAssertEqual(g.escapement.ticks, 0)
        XCTAssertEqual(g.moves, 0)
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-2,2:-4"))
    }

    func testTheDemonstrationRunsOnItsOwnStackAndLeavesTheProblemUntouched() {
        let g = game()
        XCTAssertEqual(g.level.demo, tri("0:-3,1:+2"))
        g.demo(g.level.demo)
        XCTAssertEqual(g.reachable, Twist(rod: 1, steps: -2))
        g.commit(rod: 1, steps: -2)
        XCTAssertEqual(g.stack, tri("0:-2"))
        g.wait(on: 0)
        XCTAssertEqual(g.stack, tri("0:-1"))
        XCTAssertFalse(g.finished)
        g.endDemo()
        XCTAssertEqual(g.stack, tri("0:-1,1:+3,0:-2,2:-4"))
        XCTAssertEqual(g.moves, 0)
        XCTAssertEqual(g.escapement.ticks, 0)
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

    /// Every problem ships proved: par is the prover's fewest, and its line wins on a real `Game` at par.
    func testEveryProblemsParIsTheProversOptimum() throws {
        for level in Level.escapement {
            let clock = try XCTUnwrap(level.clock, level.id)
            var seen = 0
            let play = try XCTUnwrap(Solver(level.layout).escapement(level.scramble, clock: clock, limit: level.par, seen: &seen),
                                     level.id)
            XCTAssertEqual(play.count, level.par, level.id)
            var test = level
            test.id = "test-" + level.id
            let g = Game(level: test, tankTurned: true, bank: (0, nil))
            for move in play.moves {
                switch move {
                case let .stir(knob, _, steps): g.commit(rod: knob, steps: steps)
                case .wait: g.wait(on: clock)
                case .turn: XCTFail("a clock's tank never turns: \(level.id)")
                }
            }
            XCTAssertTrue(g.solved, level.id)
            XCTAssertEqual(g.moves, level.par, level.id)
        }
    }

    /// The prover finds nothing shorter than the composed line, and drops the lost lines: on 1:+3,0:-1, taking rod 1
    /// off first buries the clock's seam, so its tick pushes, and waiting first stops the clock with rod 1 still on.
    func testTheProverDropsLostLines() {
        var seen = 0
        let solver = Solver(.tri)
        XCTAssertNil(solver.escapement(tri("0:-1,1:+3,0:-2,2:-4"), clock: 0, limit: 2, seen: &seen))
        XCTAssertEqual(solver.escapement(tri("0:-1,1:+3,0:-2,2:-4"), clock: 0, limit: 3, seen: &seen)?.count, 3)
        XCTAssertEqual(solver.escapement(tri("0:-1,1:+3"), clock: 0, limit: 4, seen: &seen)?.count, 1)
        XCTAssertNil(solver.escapement(tri("1:+3,0:-1"), clock: 0, limit: 4, seen: &seen))
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
