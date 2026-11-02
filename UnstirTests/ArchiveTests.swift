// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class ArchiveTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(_ ymd: Int, hour: Int = 12) throws -> Date {
        try XCTUnwrap(calendar.date(from: DateComponents(year: ymd / 10000, month: ymd / 100 % 100, day: ymd % 100, hour: hour)))
    }

    /// Until daily #1 is set, the archive is the 30 days before today, oldest first, ending yesterday: today's daily
    /// stays on the menu.
    func testTheArchiveIsTheThirtyDaysBeforeTodayUntilLaunch() throws {
        let days = Archive.days(today: try date(20261102), firstDay: nil).map(Level.dailyDay)
        XCTAssertEqual(days.count, 30)
        XCTAssertEqual(days.first, 20261003)
        XCTAssertEqual(days.last, 20261101)
        XCTAssertFalse(days.contains(20261102))
        XCTAssertEqual(days, days.sorted())
        XCTAssertEqual(Set(days).count, days.count, "no day twice, the clocks' change on 25 October included")
        XCTAssertEqual(Archive.days(today: try date(20261102, hour: 0), firstDay: nil).map(Level.dailyDay), days,
                       "the same at a minute past midnight")
        XCTAssertEqual(Archive.days(today: try date(20261102, hour: 23), firstDay: nil).map(Level.dailyDay), days)
    }

    /// Once launch day is set, the archive back-fills 30 days before it and grows by a day each day after.
    func testTheArchiveBackFillsThirtyDaysBeforeLaunch() throws {
        let launch = 20261201
        let onLaunch = Archive.days(today: try date(launch), firstDay: launch).map(Level.dailyDay)
        XCTAssertEqual(onLaunch.count, 30, "one calendar page on day one")
        XCTAssertEqual(onLaunch.first, 20261101)
        XCTAssertEqual(onLaunch.last, 20261130)
        let later = Archive.days(today: try date(20270115), firstDay: launch).map(Level.dailyDay)
        XCTAssertEqual(later.first, 20261101, "the back-fill stays put")
        XCTAssertEqual(later.last, 20270114, "across the year's end")
        XCTAssertEqual(later.count, 30 + 31 + 14)
        // A launch day still ahead, as on a build made before it, back-fills from today.
        XCTAssertEqual(Archive.days(today: try date(20261102), firstDay: launch),
                       Archive.days(today: try date(20261102), firstDay: nil))
    }

    /// Any purchase opens it, and the developer unlock where it opens packs; nothing else does, in Release.
    func testOnlyAPurchaseOpensTheArchive() {
        XCTAssertFalse(Archive.opens(bought: false, unlocked: false, release: true, playtest: false))
        XCTAssertTrue(Archive.opens(bought: true, unlocked: false, release: true, playtest: false))
        XCTAssertFalse(Archive.opens(bought: false, unlocked: true, release: true, playtest: false),
                       "a store build's unlock opens no paid content")
        XCTAssertTrue(Archive.opens(bought: false, unlocked: true, release: true, playtest: true))
        XCTAssertTrue(Archive.opens(bought: false, unlocked: true, release: false, playtest: false))
        XCTAssertFalse(Archive.opens(bought: false, unlocked: false, release: false, playtest: false))
    }

    /// Any one purchase: a pack, or Complete, which grants every pack. A pending or revoked one isn't bought.
    func testAnyPurchaseIsBought() {
        func bought(_ products: [String: Purchase]) -> Bool {
            var ledger = Ledger()
            for (id, state) in products { ledger.record(id, state) }
            return ledger.boughtAny
        }
        XCTAssertFalse(bought([:]))
        XCTAssertTrue(bought([Pack.lens.productID: .owned]))
        XCTAssertTrue(bought([Pack.completeID: .owned]))
        XCTAssertFalse(bought([Pack.lens.productID: .pending, Pack.completeID: .revoked]))
    }

    /// An archive day's best is its own: the days running count only bests kept on their day.
    func testArchiveBestsNeverCountTowardTheRun() throws {
        let today = try date(20261102)
        func run(live: Set<Int>, archived: Set<Int>) -> Int {
            Daily.run(today: today) { id in
                let k = (0 ..< 40).first { Level.dailyID(self.calendar.date(byAdding: .day, value: -$0, to: today)!) == id }!
                return live.contains(k) ? Best(over: 0, seconds: 9) : archived.contains(k) ? Best(over: 0, seconds: 9, archived: true) : nil
            }
        }
        XCTAssertEqual(run(live: [0, 1, 2], archived: []), 3)
        XCTAssertEqual(run(live: [0, 2, 3], archived: [1]), 1, "an archive solve doesn't mend a missed day")
        XCTAssertEqual(run(live: [], archived: [0, 1, 2]), 0)
        XCTAssertEqual(run(live: [0], archived: [1, 2, 3]), 1)
    }

    /// A past daily played from the archive saves its best marked as the archive's, never touches the run, and plays as
    /// any level: again is no practice, and no share line or next daily's time.
    @MainActor func testAnArchiveSolveSavesItsOwnBest() throws {
        let day = try date(20261020)
        let level = Level.daily(day, archived: true)
        XCTAssertEqual(level.id, "daily-20261020", "the day's own id")
        XCTAssertEqual(level.scramble, Level.daily(day).scramble, "the day's own tank, from the frozen generator")
        XCTAssertEqual(level.back, "\u{2039} archive")
        defer { for key in ["best.\(level.id)", "started.\(level.id)"] { UserDefaults.standard.removeObject(forKey: key) } }
        let game = Game(level: level, tankTurned: true, bank: (10, nil))
        XCTAssertTrue(game.counts)
        for t in level.scramble.reversed() { game.commit(rod: game.knob(over: t.rod), steps: -t.steps) }
        XCTAssertTrue(game.solved)
        let best = try XCTUnwrap(Best.load(level.id))
        XCTAssertEqual(best.archived, true)
        XCTAssertEqual(best.clean, true)
        XCTAssertNil(game.shareText)
        XCTAssertEqual(Daily.run(today: day), 0, "an archive day starts no run")
        XCTAssertEqual(Archive.Mark(level.id), .clean)
        XCTAssertTrue(game.reset())
        XCTAssertTrue(game.counts, "again on an archive day isn't practice")
    }

    /// A day that kept a best on its day keeps it: the archive replays it as practice, so the run it is in stands.
    @MainActor func testAnArchiveReplayLeavesTheDaysOwnBest() throws {
        let day = try date(20261021)
        let level = Level.daily(day, archived: true)
        defer { for key in ["best.\(level.id)", "started.\(level.id)"] { UserDefaults.standard.removeObject(forKey: key) } }
        Best(over: 2, seconds: 9).save(level.id)
        Best.start(level.id)
        XCTAssertEqual(Daily.run(today: day), 1)
        let game = Game(level: level, tankTurned: true, bank: (10, nil))
        XCTAssertFalse(game.counts)
        for t in level.scramble.reversed() { game.commit(rod: game.knob(over: t.rod), steps: -t.steps) }
        XCTAssertTrue(game.solved)
        XCTAssertEqual(Best.load(level.id)?.over, 2, "a solve at par from the archive would replace +2 if it saved")
        XCTAssertNil(Best.load(level.id)?.archived)
        XCTAssertEqual(Daily.run(today: day), 1)
    }

    /// Each day says its result in the menu's words, and in VoiceOver's.
    func testEachDayShowsItsResult() throws {
        XCTAssertEqual(Archive.Mark(Best(over: 0, seconds: 9, clean: true), started: true), .clean)
        XCTAssertEqual(Archive.Mark(Best(over: 0, seconds: 9), started: true), .par)
        XCTAssertEqual(Archive.Mark(Best(over: 3, seconds: 9), started: true), .over(3))
        XCTAssertEqual(Archive.Mark(nil, started: true), .tried)
        XCTAssertEqual(Archive.Mark(nil, started: false), .unplayed)
        XCTAssertEqual([Archive.Mark.clean, .par, .over(3), .tried, .unplayed].map(\.word), ["clean", "par", "+3", "tried", ""])
        let day = try date(20261020)
        let spoken = Spoken.archiveDay(day, level: Level.daily(day, archived: true), mark: .over(3))
        XCTAssertTrue(spoken.label.contains("20"), spoken.label)
        XCTAssertEqual(spoken.value, "3 over par")
        XCTAssertEqual(Spoken.archiveRow(open: false, days: 30, atPar: 0).value, "locked, comes with any pack")
        XCTAssertEqual(Spoken.archiveRow(open: true, days: 30, atPar: 4).value, "4 of 30 at par")
    }

    /// An archive day's try survives a launch, as today's daily's does.
    func testAnArchiveDaysTryIsKnown() {
        for day in Archive.days() { XCTAssertTrue(Resume.known.contains(Level.dailyID(day))) }
    }
}
