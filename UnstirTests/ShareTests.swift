// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

private let first = 2026_10_25

final class ShareTests: XCTestCase {
    func testDailiesNumberFromTheFirstDay() {
        XCTAssertEqual(Share.number(first, from: first), 1)
        XCTAssertEqual(Share.number(2026_10_26, from: first), 2)
        // Across the clocks going back in Europe (25 Oct) and the US (1 Nov), and a month's end.
        XCTAssertEqual(Share.number(2026_11_02, from: first), 9)
        XCTAssertEqual(Share.number(2027_10_25, from: first), 366)
        XCTAssertEqual(Share.number(2028_10_25, from: first), 732)
        XCTAssertNil(Share.number(2026_10_24, from: first))
    }

    func testUntilLaunchDayIsSetTheLineNamesTheDate() {
        XCTAssertNil(Share.number(2026_10_25, from: nil))
        XCTAssertEqual(Share.text(day: 2026_10_25, moves: 3, par: 3, firstTry: true, clean: true, undos: 0, resets: 0, marks: [], firstDay: nil),
                       "Unstir 2026-10-25 \u{00B7} 3 moves (par 3) \u{00B7} clean")
    }

    func testTheNumberFollowsTheDailysOwnDay() throws {
        // Either side of the US clocks going forward (14 Mar 2027), at 1 a.m. in the runner's zone.
        for (day, n) in [(13, 140), (14, 141), (15, 142)] {
            let date = try XCTUnwrap(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2027, month: 3, day: day, hour: 1)))
            let id = Level.daily(date).id
            XCTAssertEqual(Share.day(of: id).flatMap { Share.number($0, from: first) }, n, id)
        }
        XCTAssertNil(Share.day(of: "endless"))
        XCTAssertNil(Share.day(of: "L5"))
    }

    func testTheLineSaysMovesAgainstParAndHowItWent() {
        let row: [Share.Mark] = [.healed, .healed, .pushed, .healed, .merged, .healed, .healed]
        XCTAssertEqual(Share.text(day: 2026_10_25, moves: 7, par: 6, firstTry: true, clean: false, undos: 0, resets: 0, marks: row, firstDay: first),
                       "Unstir #1 \u{00B7} 7 moves (par 6)\n\u{1F7EA}\u{1F7EA}\u{1F7E5}\u{1F7EA}\u{2B1C}\u{1F7EA}\u{1F7EA}")
        XCTAssertEqual(Share.text(day: 2026_11_04, moves: 1, par: 1, firstTry: true, clean: true, undos: 0, resets: 0, marks: [.healed], firstDay: first),
                       "Unstir #11 \u{00B7} 1 move (par 1) \u{00B7} clean\n\u{1F7EA}")
        XCTAssertEqual(Share.text(day: 2026_10_26, moves: 6, par: 6, firstTry: true, clean: false, undos: 2, resets: 1, marks: [], firstDay: first),
                       "Unstir #2 \u{00B7} 6 moves (par 6) \u{00B7} 2 undos \u{00B7} 1 reset")
    }

    func testPracticeSaysSo() {
        XCTAssertEqual(Share.text(day: 2026_10_27, moves: 6, par: 6, firstTry: false, clean: false, undos: 1, resets: 0, marks: [], firstDay: first),
                       "Unstir #3 \u{00B7} practice \u{00B7} 6 moves (par 6) \u{00B7} 1 undo")
    }

    func testBeforeTheFirstDayTheLineNamesTheDate() {
        XCTAssertEqual(Share.text(day: 2026_09_28, moves: 3, par: 3, firstTry: true, clean: true, undos: 0, resets: 0, marks: [], firstDay: first),
                       "Unstir 2026-09-28 \u{00B7} 3 moves (par 3) \u{00B7} clean")
    }

    func testLongRowsWrapAtTen() {
        let text = Share.text(day: 2026_10_25, moves: 23, par: 20, firstTry: true, clean: false, undos: 0, resets: 0,
                              marks: Array(repeating: .healed, count: 23), firstDay: first)
        XCTAssertEqual(text.split(separator: "\n").dropFirst().map(\.count), [10, 10, 3])
    }

    /// Each move's mark is what the whole stir did to the stack, and an undone move leaves the row.
    @MainActor func testMarksFollowThePlay() {
        let game = Game(level: Level(id: "daily-20261101", label: "", title: "", layout: .tri, scramble: .parse("2:+3,0:-5", in: .tri)),
                        tankTurned: true, bank: (10, nil))
        game.commit(rod: 2, steps: +1)
        XCTAssertEqual(game.marks, [.pushed])
        game.undo()
        XCTAssertEqual(game.marks, [])
        game.commit(rod: 0, steps: +2)
        // Turned back to nothing, rod 1's stir leaves no mark and shuts rod 0's, so its next turn is a stir of its own.
        game.commit(rod: 1, steps: +1)
        game.commit(rod: 1, steps: -1)
        XCTAssertEqual(game.marks, [.merged])
        game.commit(rod: 0, steps: +3)
        game.commit(rod: 2, steps: -3)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.marks, [.merged, .healed, .healed])
        XCTAssertEqual(game.shareText, "Unstir 2026-11-01 \u{00B7} 3 moves (par 2) \u{00B7} 1 undo\n\u{2B1C}\u{1F7EA}\u{1F7EA}")
        XCTAssertNil(Game(level: Level.plughole[0]).shareText)
    }

    @MainActor func testATurnOfTheTankHasItsOwnMark() {
        let game = Game(level: Level(id: "test", label: "", title: "", layout: .quad, scramble: .parse("0:+3", in: .quad)),
                        tankTurned: true, bank: (10, nil))
        game.turnTank(1)
        XCTAssertEqual(game.marks, [.tank])
    }

    @MainActor func testAReplayedDailySharesAsPractice() {
        let id = "daily-20261102"
        Best.start(id)
        defer { UserDefaults.standard.removeObject(forKey: "started.\(id)") }
        let game = Game(level: Level(id: id, label: "", title: "", layout: .tri, scramble: .parse("0:+4", in: .tri)),
                        tankTurned: true, bank: (10, nil))
        game.commit(rod: 0, steps: -4)
        XCTAssertTrue(game.solved)
        XCTAssertFalse(game.counts)
        XCTAssertEqual(game.shareText, "Unstir 2026-11-02 \u{00B7} practice \u{00B7} 1 move (par 1)\n\u{1F7EA}")
    }
}
