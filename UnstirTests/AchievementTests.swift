// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class AchievementTests: XCTestCase {
    private typealias Record = Achievement.Record

    /// A live achievement can't be deleted and its points can't change, and App Store Connect knows it by its id:
    /// every value here is a literal on purpose.
    func testTheListNeverChanges() {
        let pinned: [(String, String, Int, Bool)] = [
            ("first-drop", "First Drop", 5, false),
            ("down-the-plughole", "Down the Plughole", 15, false),
            ("into-the-vortex", "Into the Vortex", 20, false),
            ("the-maelstrom", "The Maelstrom", 25, false),
            ("unstirred", "Unstirred", 50, false),
            ("no-wake", "No Wake", 10, false),
            ("turn-of-the-tide", "Turn of the Tide", 5, false),
            ("the-edge-turns", "The Edge Turns", 5, false),
            ("todays-tank", "Today's Tank", 5, false),
            ("a-week-of-tanks", "A Week of Tanks", 10, false),
            ("brim", "Brim", 10, false),
            ("over-the-lip", "Over the Lip", 5, true),
            ("in-focus", "In Focus", 20, true),
            ("time-well-spent", "Time Well Spent", 20, true),
            ("white-light", "White Light", 20, true),
            ("whole-shelf", "Whole Shelf", 30, true),
        ]
        XCTAssertEqual(Achievement.allCases.count, pinned.count)
        for (a, p) in zip(Achievement.allCases, pinned) {
            XCTAssertEqual(a.id, "com.screendead.Unstir.achievement.\(p.0)")
            XCTAssertEqual(a.title, p.1)
            XCTAssertEqual(a.points, p.2, a.title)
            XCTAssertEqual(a.hidden, p.3, a.title)
            XCTAssertFalse(a.goal.isEmpty || a.earned.isEmpty, a.title)
        }
        XCTAssertEqual(Achievement.allCases.map(\.points).reduce(0, +), 255)
        XCTAssertEqual(Set(Achievement.allCases.map(\.id)).count, pinned.count)
        XCTAssertEqual(Set(Achievement.allCases.map(\.title)).count, pinned.count)
        XCTAssertEqual(Achievement.allCases.filter(\.flagged), [.unstirred, .noWake, .aWeekOfTanks, .overTheLip])
        XCTAssertEqual(Achievement.shelf.map(\.1), [.lens, .escapement, .prism])
    }

    /// v1 builds without Game Center until the sign-in overlay test passes, and the test host never signs in.
    @MainActor func testV1BuildsWithoutGameCenter() {
        XCTAssertFalse(GameCenter.built)
        XCTAssertFalse(GameCenter.shared.plays)
        GameCenter.shared.signIn()
        XCTAssertFalse(GameCenter.shared.signedIn)
    }

    /// Nothing is earned on a fresh install, and nothing reports at 0.
    func testAFreshRecordEarnsNothing() {
        for a in Achievement.allCases { XCTAssertEqual(a.percent(Record()), 0, a.title) }
        XCTAssertTrue(Achievement.due(Record(), reported: [:]).isEmpty)
    }

    private func bests(_ ids: [String], over: Int = 0, clean: Bool? = nil) -> (String) -> Best? {
        let set = Set(ids)
        return { set.contains($0) ? Best(over: over, seconds: 1, clean: clean) : nil }
    }

    private func ids(_ tiers: Tier...) -> [String] { tiers.flatMap { $0.levels.map(\.id) } }

    func testFirstDropIsAnyPlugholeBest() {
        XCTAssertEqual(Achievement.firstDrop.percent(Record(best: bests(["L5"], over: 3))), 100)
        XCTAssertEqual(Achievement.firstDrop.percent(Record(best: bests(["N1", "daily-20261102", "lens-1"]))), 0)
    }

    /// Each tier's is the next tier open, read without the developer unlock: every level of the tier below solved, at
    /// any score.
    func testEachTierOpensItsOwn() {
        let tiers: [(Achievement, Tier)] = [(.downThePlughole, .plughole), (.intoTheVortex, .whirlpool),
                                             (.theMaelstrom, .vortex)]
        for (a, tier) in tiers {
            let all = tier.levels.map(\.id)
            XCTAssertEqual(a.percent(Record(best: bests(all))), 100, a.title)
            XCTAssertEqual(a.percent(Record(best: bests(Array(all.dropLast())))), 0, a.title)
            let offPar = Record(best: { id in all.contains(id) ? Best(over: id == all.last ? 1 : 0, seconds: 1) : nil })
            XCTAssertEqual(a.percent(offPar), 100, a.title)
        }
        let unlocked = Best.unlocked
        defer { Best.unlocked = unlocked }
        Best.unlocked = true
        XCTAssertEqual(Achievement.downThePlughole.percent(Record()), 0)
    }

    func testUnstirredIsEveryTierAtPar() {
        let all = Tier.allCases.flatMap { $0.levels.map(\.id) }
        XCTAssertEqual(Achievement.unstirred.percent(Record(best: bests(all))), 100)
        XCTAssertEqual(Achievement.unstirred.percent(Record(best: bests(ids(.plughole, .whirlpool, .vortex)))), 0)
        for id in [all.first!, all.last!] {
            XCTAssertEqual(Achievement.unstirred.percent(Record(best: { Best(over: $0 == id ? 1 : 0, seconds: 1) })), 0)
        }
    }

    func testTheFlagsEarnTheirOwn() {
        let flags: [(Achievement, Record)] = [(.noWake, Record(clean: true)), (.turnOfTheTide, Record(tankTurned: true)),
                                              (.theEdgeTurns, Record(swirled: true)), (.overTheLip, Record(spilled: true))]
        for (a, r) in flags {
            XCTAssertEqual(a.percent(r), 100, a.title)
            for (other, _) in flags where other != a { XCTAssertEqual(other.percent(r), 0, "\(a.title) earned \(other.title)") }
        }
    }

    /// The dailies count in any order of days, so a missed day costs only that day; the week shows its share.
    func testTheDailiesCount() {
        XCTAssertEqual(Achievement.todaysTank.percent(Record(dailies: 1)), 100)
        XCTAssertEqual(Achievement.aWeekOfTanks.percent(Record(dailies: 1)), 100.0 / 7, accuracy: 1e-9)
        XCTAssertEqual(Achievement.aWeekOfTanks.percent(Record(dailies: 6)), 600.0 / 7, accuracy: 1e-9)
        XCTAssertEqual(Achievement.aWeekOfTanks.percent(Record(dailies: 7)), 100)
        XCTAssertEqual(Achievement.aWeekOfTanks.percent(Record(dailies: 40)), 100)
    }

    func testBrimIsFiveTanksInARun() {
        XCTAssertEqual(Achievement.brim.percent(Record(tanks: 2)), 40)
        XCTAssertEqual(Achievement.brim.percent(Record(tanks: 5)), 100)
        XCTAssertEqual(Achievement.brim.percent(Record(tanks: 12)), 100)
    }

    /// A pack's is every one of its planned levels with a best, at par or not; Whole Shelf is all three. Owning a pack
    /// earns nothing.
    func testThePacksAreEarnedByPlaying() {
        for (a, pack) in Achievement.shelf {
            let all = pack.levels.map(\.id)
            XCTAssertEqual(all.count, pack.planned, pack.name)
            XCTAssertEqual(a.percent(Record(best: bests(all, over: 4))), 100, a.title)
            XCTAssertEqual(a.percent(Record(best: bests(Array(all.dropFirst())))), 0, a.title)
            XCTAssertEqual(Achievement.wholeShelf.percent(Record(best: bests(all))), 0, pack.name)
        }
        let shelf = Achievement.shelf.flatMap { $0.1.levels.map(\.id) }
        XCTAssertEqual(Achievement.wholeShelf.percent(Record(best: bests(shelf))), 100)
        XCTAssertEqual(Achievement.wholeShelf.percent(Record(best: bests(shelf + Pack.firstStir.levels.map(\.id)))), 100)
        XCTAssertEqual(Achievement.wholeShelf.percent(Record(best: bests(Array(shelf.dropLast())))), 0)
    }

    /// A hidden achievement reports only once earned, so nothing of it shows before; only a rise is reported again.
    func testOnlyARiseIsDue() {
        let r = Record(best: bests(["L1"]), dailies: 3, tanks: 2)
        let due = Achievement.due(r, reported: [:])
        XCTAssertEqual(due.map(\.0), [.firstDrop, .todaysTank, .aWeekOfTanks, .brim])
        let reported = Dictionary(uniqueKeysWithValues: due.map { ($0.0.id, $0.1) })
        XCTAssertTrue(Achievement.due(r, reported: reported).isEmpty)
        var more = r
        more.tanks = 3
        XCTAssertEqual(Achievement.due(more, reported: reported).map(\.0), [.brim])
        for a in Achievement.allCases where a.hidden {
            for n in 0 ... 9 { XCTAssert([0, 100].contains(a.percent(Record(dailies: n, tanks: n))), a.title) }
        }
    }

    /// The stored record reads the game's own keys: a clean best anywhere, and only dailies' bests as dailies.
    func testTheStoredRecordReadsTheGamesKeys() {
        let d = UserDefaults.standard
        let keys = ["best.daily-19990101", "best.daily-19990102", "best.pin-clean", "tank.turned", "swirled",
                    "endless.tanks", "endless.spilled"]
        let saved = keys.map { d.object(forKey: $0) }
        defer { for (key, value) in zip(keys, saved) { d.set(value, forKey: key) } }
        let before = Record.stored()
        Best(over: 0, seconds: 1).save("daily-19990101")
        Best(over: 0, seconds: 1).save("daily-19990102")
        Best(over: 0, seconds: 1, clean: true).save("pin-clean")
        Best.tankTurned = true
        Best.swirled = true
        Best.tanks = 6
        Best.spilled = true
        let r = Record.stored()
        XCTAssertEqual(r.dailies, before.dailies + (saved[0] == nil ? 1 : 0) + (saved[1] == nil ? 1 : 0))
        XCTAssertTrue(r.clean && r.tankTurned && r.swirled && r.spilled)
        XCTAssertEqual(r.tanks, 6)
        XCTAssertNotNil(r.best("pin-clean"))
    }

    /// A spill sets Over the Lip's flag where the level stores progress, never the harness's.
    @MainActor func testASpillSetsItsFlag() {
        let d = UserDefaults.standard, saved = d.object(forKey: "endless.spilled")
        defer { d.set(saved, forKey: "endless.spilled") }
        func spill(stores: Bool) {
            let level = Level(id: "endless", label: "", title: "", layout: .tri, scramble: .parse("0:+4", in: .tri),
                              run: Run(seed: 1, tank: 4, brim: Run.room - 1))
            let game = Game(level: level, storesProgress: stores)
            game.commit(rod: 1, steps: 1)
            XCTAssertTrue(game.spilled)
        }
        Best.spilled = false
        spill(stores: false)
        XCTAssertFalse(Best.spilled)
        spill(stores: true)
        XCTAssertTrue(Best.spilled)
    }
}
