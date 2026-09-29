// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class SolverTests: XCTestCase {
    /// Plays `play` on a real `Game`, or nil when a knob is off the slot the play names or the tank off its position.
    @MainActor private func game(_ play: Play, _ layout: Layout, _ scramble: [Twist], seized: Set<Int> = []) -> Game? {
        let level = Level(id: "test-solver", label: "", title: "", layout: layout, scramble: scramble, seized: seized)
        let game = Game(level: level)
        for move in play.moves {
            switch move {
            case let .stir(knob, slot, steps):
                guard game.slot(of: knob) == slot else { return nil }
                game.commit(rod: knob, steps: steps)
            case let .turn(steps, to):
                game.turnTank(steps)
                guard (game.position % layout.order + layout.order) % layout.order == to else { return nil }
            }
        }
        return game
    }

    /// Whether `play` empties the stack on a real `Game` in the moves it counts, not by looking solved.
    @MainActor private func assertEmpties(_ play: Play?, _ layout: Layout, _ scramble: [Twist], seized: Set<Int> = [],
                                          _ message: String = "", file: StaticString = #filePath, line: UInt = #line) {
        guard let play, let game = game(play, layout, scramble, seized: seized) else {
            return XCTFail("no play, or one the game cannot follow \(message)", file: file, line: line)
        }
        XCTAssertEqual(game.stack, [], message, file: file, line: line)
        XCTAssertEqual(game.moves, play.count, message, file: file, line: line)
    }

    /// Tests that take seconds run only when UNSTIR_SLOW_TESTS=1 reaches the runner, which CI never sets.
    private func skipUnlessSlow() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1",
                          "slow: run with TEST_RUNNER_UNSTIR_SLOW_TESTS=1")
    }

    private func assertOneMovePerEntry(_ levels: [Level]) {
        for level in levels {
            let solver = Solver(level.layout)
            XCTAssertEqual(solver.optimum(level.scramble), level.scramble.count, level.id)
            XCTAssertEqual(solver.park(level.scramble)?.count, level.scramble.count, level.id)
            XCTAssertEqual(solver.noLookahead(level.scramble)?.count, level.scramble.count, level.id)
        }
    }

    func testNothingSeizedTakesOneMovePerEntryOnEachLayout() {
        assertOneMovePerEntry(Layout.allCases.compactMap { layout in Level.plughole.first { $0.layout == layout } })
    }

    func testNothingSeizedTakesOneMovePerEntry() throws {
        try skipUnlessSlow()
        assertOneMovePerEntry(Level.plughole + Level.whirlpool)
    }

    /// Knob 0 is dead over slot 0, so its seam comes off under knob 1 a turn later.
    @MainActor func testADeadKnobCostsATurn() {
        let solver = Solver(.quad), stack = [Twist].parse("0:+3,2:-4", in: .quad)
        XCTAssertEqual(solver.optimum(stack, seized: [0]), 3)
        XCTAssertEqual(solver.park(stack, seized: [0])?.moves,
                       [.stir(knob: 2, slot: 2, steps: 4), .turn(steps: 1, to: 1), .stir(knob: 1, slot: 0, steps: -3)])
        XCTAssertEqual(solver.noLookahead(stack, seized: [0])?.count, 3)
        assertEmpties(solver.optimalPlay(stack, seized: [0]), .quad, stack, seized: [0])
    }

    /// Slot 0's seam is the only whole one. A turn of 2 parks dead knob 0 over clean slot 2 and brings every slot with
    /// a seam under a working knob; the nearest turn parks it over slot 3's seam, which then needs a second turn.
    func testParkRuleParksTheDeadKnobOverAFinishedRing() {
        let solver = Solver(.quad), stack = [Twist].parse("3:+2,1:+3,0:+4", in: .quad)
        XCTAssertEqual(solver.optimum(stack, seized: [0]), 4)
        XCTAssertEqual(solver.park(stack, seized: [0])?.moves, [.turn(steps: 2, to: 2), .stir(knob: 2, slot: 0, steps: -4),
                                                                .stir(knob: 3, slot: 1, steps: -3), .stir(knob: 1, slot: 3, steps: -2)])
        XCTAssertEqual(solver.noLookahead(stack, seized: [0])?.moves, [.turn(steps: 1, to: 1), .stir(knob: 1, slot: 0, steps: -4),
                                                                       .stir(knob: 2, slot: 1, steps: -3), .turn(steps: 1, to: 2),
                                                                       .stir(knob: 1, slot: 3, steps: -2)])
    }

    /// The eye's big knobs only swap with each other.
    func testSeizingBothBigKnobsStrandsTheirSeams() {
        let solver = Solver(.eye), stack = [Twist].parse("0:+3", in: .eye)
        XCTAssertNil(solver.optimum(stack, seized: [0, 1]))
        XCTAssertNil(solver.park(stack, seized: [0, 1]))
        XCTAssertNil(solver.noLookahead(stack, seized: [0, 1]))
    }

    func testStirsOfOneSlotInARowAreOneMove() {
        let play = Play(moves: [.stir(knob: 0, slot: 0, steps: 1), .stir(knob: 0, slot: 0, steps: 2), .turn(steps: 1, to: 1),
                                .stir(knob: 3, slot: 0, steps: 1)])
        XCTAssertEqual(play.count, 3)
    }

    /// Slot 1's stir turned straight back drops out of the count, and shuts slot 0's stir before it, so slot 0's next
    /// turn is a move of its own.
    @MainActor func testAStirTurnedStraightBackIsNoMove() {
        let stack = [Twist].parse("0:+4", in: .tri)
        let play = Play(moves: [.stir(knob: 0, slot: 0, steps: -3), .stir(knob: 1, slot: 1, steps: 2),
                                .stir(knob: 1, slot: 1, steps: -2), .stir(knob: 0, slot: 0, steps: -1)])
        XCTAssertEqual(play.count, 2)
        assertEmpties(play, .tri, stack)
    }

    /// [2:-2, 1:-7, 2:+2] holds rod 3's disc still, so 3:+2 is whole under it, and untwisting it lets 2:-2 merge into
    /// 2:-8. One move takes two entries: rods-only overlap would say 5.
    @MainActor func testAWordThatHoldsADiscStillSavesAMove() {
        let solver = Solver(.quad), stack = [Twist].parse("2:-8,3:+2,2:-2,1:-7,2:+2", in: .quad)
        XCTAssertEqual(stack.count, 5)
        XCTAssertEqual(solver.optimum(stack), 4)
        assertEmpties(solver.optimalPlay(stack), .quad, stack)
    }

    /// A push can build such a word. Pushing 0:+3 in the first makes [0:-3, 3:-7, 0:+3], which holds rod 1's disc
    /// still, and pushing 0:-3 in the second makes [0:+3, 1:-5, 0:-3], which holds rod 3's. Each time the seam under it
    /// comes off and one of the entries above it merges away as it goes back on.
    @MainActor func testAPushThatHoldsADiscStillSavesAMove() {
        let cases: [(String, Set<Int>, Int)] = [
            ("3:-1,0:-7,1:+1,0:-3,3:-7", [2, 3], 7), ("0:-3,2:+2,3:-3,0:+3,1:-5,2:+2", [0, 1], 8),
        ]
        for (scramble, seized, optimum) in cases {
            let solver = Solver(.quad), stack = [Twist].parse(scramble, in: .quad)
            XCTAssertEqual(solver.untwistingPlay(stack, seized: seized)?.count, optimum + 1, scramble)
            XCTAssertEqual(solver.optimum(stack, seized: seized), optimum, scramble)
            assertEmpties(solver.optimalPlay(stack, seized: seized), .quad, stack, seized: seized, scramble)
        }
    }

    /// Any commit counts as a move here, pushes and partial merges too, and in some cases two joined commits to one
    /// slot: nothing clears these faster than the optimum. That holds only for these cases, as the push above shows.
    /// (layout, scramble, seized knobs, step counts a commit may take, commits joined into one move)
    private func assertNothingBeatsTheOptimum(_ cases: [(Layout, String, Set<Int>, [Int], Int)]) {
        for (layout, scramble, seized, steps, commits) in cases {
            let solver = Solver(layout), stack = [Twist].parse(scramble, in: layout)
            let optimum = solver.optimum(stack, seized: seized)!
            XCTAssertEqual(solver.exhaustive(stack, seized: seized, limit: optimum, steps: steps, commits: commits), optimum,
                           "\(layout) \(scramble) \(seized)")
        }
    }

    private static let anySteps = Array(-11...11).filter { $0 != 0 }

    func testTheOptimumMatchesAnExhaustiveSearchOnTheSmallestCase() {
        assertNothingBeatsTheOptimum([(.tri, "2:+3,0:-5", [1], Self.anySteps, 2)])
    }

    func testTheOptimumMatchesAnExhaustiveSearchOnSmallCases() throws {
        try skipUnlessSlow()
        assertNothingBeatsTheOptimum([
            (.quad, "0:+3,2:-4", [0], Self.anySteps, 2),
            (.quad, "3:+2,1:+3,0:+4", [0], Self.anySteps, 1),
            (.tri, "2:+3,0:-5", [1], Self.anySteps, 2),
            (.quad, "2:-8,3:+2,2:-2,1:-7,2:+2", [], [-1, 1], 1),
            (.quad, "2:-8,3:+2,2:-2,1:-7,2:+2", [0], [-1, 1], 1),
        ])
    }

    /// The table in the Nightmare+ proposal, a level set since scrapped where N+k was whirlpool level k's scramble with
    /// some knobs seized, worked out on a port of the model where the tank had to end at home. Its optimum comes back
    /// exactly under that rule. Without it, the optimum drops by the final turn home, which N+9, N+10 and N+22 never
    /// needed, and no detour beats untwisting on any row. Which of two equally near positions the park rule turns to is
    /// Jack's call: clockwise leaves it over the optimum on N+12, N+21, N+22, N+23 and N+27, and the lower position,
    /// which the port took, only on N+22. That tie, not the port ranking first the turn that freed the most seams, is
    /// where the table's fairness came from.
    @MainActor func testTheOldTableAfterTheTurnHome() throws {
        try skipUnlessSlow()
        // (level, seized, old optimum, turn home, park rule clockwise, park rule to the lower position, no lookahead)
        let rows: [(Int, Set<Int>, Int, Int, Int, Int, Int)] = [
            (9, [1], 6, 0, 6, 6, 8), (10, [0], 10, 0, 10, 10, 11), (11, [0], 12, 1, 11, 11, 12),
            (12, [2], 16, 1, 17, 15, 18), (13, [3], 17, 1, 16, 16, 17), (19, [3], 14, 1, 13, 13, 16),
            (20, [2], 17, 1, 16, 16, 16), (21, [1, 4], 22, 1, 22, 21, 24), (22, [4], 21, 0, 25, 22, 25),
            (23, [2, 5], 18, 1, 18, 17, 19), (24, [3, 4], 20, 1, 19, 19, 21), (25, [3, 5], 25, 1, 24, 24, 27),
            (26, [1, 6], 28, 1, 27, 27, 30), (27, [4], 32, 1, 34, 31, 36),
        ]
        for (n, seized, old, turnHome, park, lower, noLookahead) in rows {
            let level = Level.whirlpool[n - 1], solver = Solver(level.layout), stack = level.scramble, id = "N+\(n)"
            XCTAssertEqual(solver.optimum(stack, seized: seized, home: true), old, id)
            XCTAssertEqual(solver.untwistingPlay(stack, seized: seized)?.count, old - turnHome, id)
            let plays = [solver.optimalPlay(stack, seized: seized), solver.park(stack, seized: seized),
                         solver.park(stack, seized: seized, tie: .lowest), solver.noLookahead(stack, seized: seized)]
            XCTAssertEqual(plays.map { $0?.count }, [old - turnHome, park, lower, noLookahead], id)
            for play in plays { assertEmpties(play, level.layout, stack, seized: seized, id) }
        }
    }

    /// At N+25's second blocked turn no position parks both seized knobs over finished rings, so the rule as worded
    /// turns to the nearest. Counting them instead parks one, two steps away, and reaches the optimum, 24, which the
    /// old table checks. Which reading is the rule is Jack's call.
    func testTwoSeizedKnobsParkAsFewAsTheyCan() {
        let level = Level.whirlpool[24], solver = Solver(level.layout), seized: Set<Int> = [3, 5]
        XCTAssertEqual(solver.park(level.scramble, seized: seized, parking: .fewest)?.count, 24)
        XCTAssertEqual(solver.park(level.scramble, seized: seized, parking: .all)?.count, 26)
        XCTAssertEqual(solver.park(level.scramble, seized: seized, parking: .fewest, tie: .lowest)?.count, 24)
        XCTAssertEqual(solver.park(level.scramble, seized: seized, parking: .all, tie: .lowest)?.count, 27)
    }
}
