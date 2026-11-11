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
        XCTAssertEqual(Share.text(day: 2026_10_25, moves: 3, par: 3, firstTry: true, clean: true, undos: 0, resets: 0, firstDay: nil),
                       "Unstir 2026-10-25 \u{00B7} \u{25CF}\u{25CF}\u{25CF} \u{00B7} 3 moves (par 3) \u{00B7} clean")
    }

    /// A player who owns a pack carries the supporter mark after the daily's name.
    func testTheSupporterMarkFollowsTheName() {
        XCTAssertEqual(Share.text(day: 2026_10_25, moves: 3, par: 3, firstTry: true, clean: true, undos: 0, resets: 0,
                                  supporter: true, firstDay: nil),
                       "Unstir 2026-10-25 \u{2726} \u{00B7} \u{25CF}\u{25CF}\u{25CF} \u{00B7} 3 moves (par 3) \u{00B7} clean")
        XCTAssertEqual(Share.text(day: 2026_11_04, moves: 1, par: 1, firstTry: false, clean: false, undos: 0, resets: 0,
                                  supporter: true, firstDay: 2026_10_25),
                       "Unstir #11 \u{2726} \u{00B7} \u{25CF}\u{25CF}\u{25CB} \u{00B7} practice \u{00B7} 1 move (par 1)")
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
        XCTAssertEqual(Share.text(day: 2026_10_25, moves: 7, par: 6, firstTry: true, clean: false, undos: 0, resets: 0, firstDay: first),
                       "Unstir #1 \u{00B7} \u{25CF}\u{25CB}\u{25CB} \u{00B7} 7 moves (par 6)")
        XCTAssertEqual(Share.text(day: 2026_11_04, moves: 1, par: 1, firstTry: true, clean: true, undos: 0, resets: 0, firstDay: first),
                       "Unstir #11 \u{00B7} \u{25CF}\u{25CF}\u{25CF} \u{00B7} 1 move (par 1) \u{00B7} clean")
        XCTAssertEqual(Share.text(day: 2026_10_26, moves: 6, par: 6, firstTry: true, clean: false, undos: 2, resets: 1, firstDay: first),
                       "Unstir #2 \u{00B7} \u{25CF}\u{25CF}\u{25CB} \u{00B7} 6 moves (par 6) \u{00B7} 2 undos \u{00B7} 1 reset")
    }

    func testPracticeSaysSo() {
        XCTAssertEqual(Share.text(day: 2026_10_27, moves: 6, par: 6, firstTry: false, clean: false, undos: 1, resets: 0, firstDay: first),
                       "Unstir #3 \u{00B7} \u{25CF}\u{25CF}\u{25CB} \u{00B7} practice \u{00B7} 6 moves (par 6) \u{00B7} 1 undo")
    }

    func testBeforeTheFirstDayTheLineNamesTheDate() {
        XCTAssertEqual(Share.text(day: 2026_09_28, moves: 3, par: 3, firstTry: true, clean: true, undos: 0, resets: 0, firstDay: first),
                       "Unstir 2026-09-28 \u{00B7} \u{25CF}\u{25CF}\u{25CF} \u{00B7} 3 moves (par 3) \u{00B7} clean")
    }

    @MainActor func testADailysSolveSharesItsDots() {
        let game = Game(level: Level(id: "daily-20261101", label: "", title: "", layout: .tri, scramble: .parse("2:+3,0:-5", in: .tri)),
                        tankTurned: true, bank: (10, nil))
        game.commit(rod: 2, steps: +1)
        game.undo()
        game.commit(rod: 0, steps: +2)
        // Turned back to nothing, rod 1's stir leaves no mark and shuts rod 0's, so its next turn is a stir of its own.
        game.commit(rod: 1, steps: +1)
        game.commit(rod: 1, steps: -1)
        game.commit(rod: 0, steps: +3)
        game.commit(rod: 2, steps: -3)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(game.shareText, "Unstir 2026-11-01 \u{00B7} \u{25CF}\u{25CB}\u{25CB} \u{00B7} 3 moves (par 2) \u{00B7} 1 undo")
        XCTAssertNil(Game(level: Level.plughole[0]).shareText)
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
        XCTAssertEqual(game.shareText, "Unstir 2026-11-02 \u{00B7} \u{25CF}\u{25CF}\u{25CB} \u{00B7} practice \u{00B7} 1 move (par 1)")
    }

    /// "again" on the daily's card plays it as practice: it saves no best, so the first try's stands, and no streak
    /// day (Jack's call P1 = B).
    @MainActor func testTheDailysAgainIsPractice() throws {
        let id = "daily-20261103"
        defer {
            for key in ["best.\(id)", "started.\(id)", Resume.key(id)] { UserDefaults.standard.removeObject(forKey: key) }
        }
        let day = try XCTUnwrap(DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 11, day: 3).date)
        let game = Game(level: Level(id: id, label: "", title: "", layout: .tri, scramble: .parse("0:+4", in: .tri)),
                        tankTurned: true, bank: (10, nil), storesResume: true)
        // Rod 1's stir turned back between them splits rod 0's heal in two moves: one over par.
        for (rod, steps) in [(0, -2), (1, 1), (1, -1), (0, -2)] { game.commit(rod: rod, steps: steps) }
        XCTAssertTrue(game.solved)
        XCTAssertTrue(game.counts)
        XCTAssertEqual(Best.load(id)?.over, 1)
        XCTAssertEqual(Daily.run(today: day), 1)
        XCTAssertTrue(game.offersAgain)
        XCTAssertTrue(game.reset())
        XCTAssertFalse(game.firstTry)
        XCTAssertFalse(game.counts)
        XCTAssertNil(game.bests, "the card would show the first try's best line again")
        XCTAssertEqual(Resume.load(id)?.firstTry, false, "a resumed practice stays practice")
        game.commit(rod: 0, steps: -4)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(Best.load(id)?.over, 1, "a practice at par would beat the first try's +1 if it saved")
        XCTAssertNil(game.bests)
        XCTAssertEqual(Daily.run(today: day), 1)
        XCTAssertTrue(Best.started(id))
        XCTAssertEqual(game.shareText, "Unstir 2026-11-03 \u{00B7} \u{25CF}\u{25CF}\u{25CB} \u{00B7} practice \u{00B7} 1 move (par 1) \u{00B7} 1 reset")
    }

    /// Only "again" after a daily's solve makes practice: a reset mid-try, or another level's again, keeps the first try.
    @MainActor func testOnlyTheDailysAgainEndsTheFirstTry() {
        let ids = ["daily-20261104", "test"]
        defer {
            for id in ids { for key in ["best.\(id)", "started.\(id)"] { UserDefaults.standard.removeObject(forKey: key) } }
        }
        func tried(_ id: String, solve: Bool) -> Game {
            let game = Game(level: Level(id: id, label: "", title: "", layout: .tri, scramble: .parse("0:+4", in: .tri)),
                            tankTurned: true, bank: (10, nil), firstTry: true)
            game.commit(rod: 0, steps: -2)
            if solve {
                for (rod, steps) in [(1, 1), (1, -1), (0, -2)] { game.commit(rod: rod, steps: steps) }
                XCTAssertTrue(game.offersAgain, id)
            }
            XCTAssertTrue(game.reset())
            return game
        }
        let reset = tried("daily-20261104", solve: false)
        XCTAssertTrue(reset.firstTry)
        XCTAssertTrue(reset.counts)
        XCTAssertTrue(tried("test", solve: true).firstTry)
    }
}
