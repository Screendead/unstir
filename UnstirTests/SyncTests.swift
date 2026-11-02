// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// The key-value store as a dictionary.
private final class FakeCloud: Cloud {
    var values: [String: Any] = [:]
    var writes = 0
    func dictionary(forKey key: String) -> [String: Any]? { values[key] as? [String: Any] }
    func set(_ value: Any?, forKey key: String) {
        values[key] = value
        writes += 1
    }
}

final class SyncTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suite = "SyncTests"

    override func setUp() {
        UserDefaults().removePersistentDomain(forName: suite)
        defaults = UserDefaults(suiteName: suite)
    }

    override func tearDown() { UserDefaults().removePersistentDomain(forName: suite) }

    private func data(_ b: Best) -> Data { try! JSONEncoder().encode(b) }

    private func phone() -> [String: Best] {
        (defaults.persistentDomain(forName: suite) ?? [:]).reduce(into: [:]) { into, kv in
            if kv.key.hasPrefix("best."), let b = (kv.value as? Data).flatMap(Best.decode) { into[String(kv.key.dropFirst(5))] = b }
        }
    }

    private func cloudBests(_ cloud: FakeCloud) -> [String: Best] {
        (cloud.dictionary(forKey: Sync.key) ?? [:]).compactMapValues { ($0 as? Data).flatMap(Best.decode) }
    }

    /// Pinned: a renamed key strands every best already in a player's iCloud.
    func testTheStoresKeyNeverChanges() {
        XCTAssertEqual(Sync.key, "bests")
    }

    /// Clean, then fewer over par, never time; a tie keeps what the side already holds (Jack's call C10, round 13).
    func testTheBetterBestWinsAndATieKeepsTheOneHeld() {
        let clean = Best(over: 2, seconds: 90, clean: true), par = Best(over: 0, seconds: 10, clean: false)
        XCTAssertTrue(Sync.beats(clean, par))
        XCTAssertFalse(Sync.beats(par, clean))
        XCTAssertTrue(Sync.beats(Best(over: 1, seconds: 500), Best(over: 2, seconds: 5)))
        XCTAssertFalse(Sync.beats(Best(over: 1, seconds: 5), Best(over: 1, seconds: 500)))
        XCTAssertFalse(Sync.beats(Best(over: 1, seconds: 500), Best(over: 1, seconds: 5)))
    }

    /// A daily kept on its day outranks one the archive saved after it, however good, as the archive never replaces
    /// one on a phone: so a synced archive solve never moves the streak.
    func testADailyKeptOnItsDayOutranksTheArchives() {
        let onDay = Best(over: 3, seconds: 60, clean: false), archived = Best(over: 0, seconds: 60, clean: true, archived: true)
        XCTAssertTrue(Sync.beats(onDay, archived))
        XCTAssertFalse(Sync.beats(archived, onDay))
        let id = Level.dailyID(.now)
        let (local, cloud) = Sync.merge(local: [id: archived], cloud: [id: onDay])
        XCTAssertEqual(local[id]?.archived, nil)
        XCTAssertTrue(cloud.isEmpty)
    }

    func testEachSideTakesWhatBeatsItsOwnOrWhatItLacks() {
        let local = ["L1": Best(over: 0, seconds: 9, clean: true), "L2": Best(over: 3, seconds: 9), "L3": Best(over: 1, seconds: 9)]
        let cloud = ["L2": Best(over: 1, seconds: 9), "L3": Best(over: 1, seconds: 1), "lens-4": Best(over: 0, seconds: 9)]
        let (took, sent) = Sync.merge(local: local, cloud: cloud)
        XCTAssertEqual(Set(took.keys), ["L2", "lens-4"])
        XCTAssertEqual(took["L2"]?.over, 1)
        XCTAssertEqual(Set(sent.keys), ["L1"])
        XCTAssertNil(took["L3"])
    }

    /// Two phones that reconcile through the store each end with the other's better bests and lose none of their own.
    func testTwoPhonesReconcileToTheBetterOfEach() {
        let cloud = FakeCloud()
        let other = UserDefaults(suiteName: suite + ".other")!
        defer { UserDefaults().removePersistentDomain(forName: suite + ".other") }
        defaults.set(data(Best(over: 2, seconds: 9)), forKey: "best.L1")
        defaults.set(data(Best(over: 0, seconds: 9, clean: true)), forKey: "best.L2")
        other.set(data(Best(over: 0, seconds: 9)), forKey: "best.L1")
        other.set(data(Best(over: 1, seconds: 9)), forKey: "best.V3")

        XCTAssertEqual(Sync.reconcile(cloud, defaults, domain: suite).sent, 2)
        let second = Sync.reconcile(cloud, other, domain: suite + ".other")
        XCTAssertEqual(second.took, 1)
        XCTAssertEqual(second.sent, 2)
        XCTAssertEqual(Sync.reconcile(cloud, defaults, domain: suite).took, 2)

        let mine = phone()
        XCTAssertEqual(mine["L1"]?.over, 0)
        XCTAssertEqual(mine["L2"]?.clean, true)
        XCTAssertEqual(mine["V3"]?.over, 1)
        XCTAssertEqual(cloudBests(cloud).mapValues(\.over), ["L1": 0, "L2": 0, "V3": 1])
        // Settled: nothing moves either way, and nothing is written.
        let writes = cloud.writes
        for (p, domain) in [(defaults!, suite), (other, suite + ".other")] {
            let again = Sync.reconcile(cloud, p, domain: domain)
            XCTAssertEqual(again.took + again.sent, 0, domain)
        }
        XCTAssertEqual(cloud.writes, writes)
    }

    /// Bests alone go up: never the undo bank, its day or its anchor, nor any other flag the game keeps.
    func testOnlyBestsReachTheStore() {
        let cloud = FakeCloud()
        defaults.set(data(Best(over: 0, seconds: 9)), forKey: "best.L1")
        for key in ["undos.spent", "undos.day", "undos.anchor", "started.L2", "tank.turned", "endless.tanks", "resume.L3"] {
            defaults.set(1, forKey: key)
        }
        Sync.reconcile(cloud, defaults, domain: suite)
        XCTAssertEqual(Array(cloud.values.keys), [Sync.key])
        XCTAssertEqual(Array((cloud.dictionary(forKey: Sync.key) ?? [:]).keys), ["L1"])
    }

    /// The phone stores the store's own bytes, and an entry this build can't read is left as it was: a later version's
    /// best survives an older version's reconcile.
    func testAnUnreadableEntryIsNeverWrittenOver() {
        let cloud = FakeCloud()
        let later = Data(#"{"over":0,"seconds":4,"clean":true,"lens":7}"#.utf8), unreadable = Data("not a best".utf8)
        cloud.values[Sync.key] = ["L1": later, "L2": unreadable]
        defaults.set(data(Best(over: 1, seconds: 9)), forKey: "best.L1")
        defaults.set(data(Best(over: 0, seconds: 9)), forKey: "best.L2")
        let (took, sent) = Sync.reconcile(cloud, defaults, domain: suite)
        XCTAssertEqual(took, 1)
        XCTAssertEqual(sent, 0)
        XCTAssertEqual(defaults.data(forKey: "best.L1"), later)
        XCTAssertEqual(cloud.dictionary(forKey: Sync.key)?["L2"] as? Data, unreadable)
    }

    /// The test host never syncs, so no test's best reaches a store.
    @MainActor func testTheTestHostNeverSyncs() {
        XCTAssertFalse(Sync.shared.plays)
    }

    /// A best iCloud brought counts as the level started: a later try there is no first try, so it can't be clean, and
    /// a daily plays as practice, as on the phone that set it (Jack's calls C18 and P1, round 13).
    @MainActor func testABestWithoutAStartedFlagIsNoFirstTry() throws {
        let level = Level.daily(try XCTUnwrap(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 23))))
        defer { for key in ["best.\(level.id)", "started.\(level.id)"] { UserDefaults.standard.removeObject(forKey: key) } }
        XCTAssertTrue(Game(level: level, tankTurned: true, bank: (10, nil)).firstTry)
        UserDefaults.standard.set(data(Best(over: 2, seconds: 9)), forKey: "best.\(level.id)")
        XCTAssertFalse(Best.started(level.id))
        let game = Game(level: level, tankTurned: true, bank: (10, nil))
        XCTAssertFalse(game.firstTry)
        XCTAssertFalse(game.counts, "the daily plays as practice")
        for t in level.scramble.reversed() { game.commit(rod: game.knob(over: t.rod), steps: -t.steps) }
        XCTAssertTrue(game.solved)
        XCTAssertFalse(game.clean)
        XCTAssertEqual(Best.load(level.id)?.over, 2, "practice saves nothing")
    }

    /// A best iCloud brought counts as the level started: a later try there is no first try, so it can't be clean, and
    /// a daily plays as practice, as on the phone that set it (Jack's calls C18 and P1, round 13).
    @MainActor func testABestWithoutAStartedFlagIsNoFirstTry() throws {
        let level = Level.daily(try XCTUnwrap(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 23))))
        defer { for key in ["best.\(level.id)", "started.\(level.id)"] { UserDefaults.standard.removeObject(forKey: key) } }
        XCTAssertTrue(Game(level: level, tankTurned: true, bank: (10, nil)).firstTry)
        UserDefaults.standard.set(data(Best(over: 2, seconds: 9)), forKey: "best.\(level.id)")
        XCTAssertFalse(Best.started(level.id))
        let game = Game(level: level, tankTurned: true, bank: (10, nil))
        XCTAssertFalse(game.firstTry)
        XCTAssertFalse(game.counts, "the daily plays as practice")
        for t in level.scramble.reversed() { game.commit(rod: game.knob(over: t.rod), steps: -t.steps) }
        XCTAssertTrue(game.solved)
        XCTAssertFalse(game.clean)
        XCTAssertEqual(Best.load(level.id)?.over, 2, "practice saves nothing")
    }

    /// Saving keeps the rank the merge does: a daily's best on its day replaces the archive's, however good, and the
    /// archive's never replaces one kept on its day, so `Daily.run` counts a day played on its day.
    func testSavingRanksAsTheMergeDoes() {
        let id = "sync-save-rank"
        defer { UserDefaults.standard.removeObject(forKey: "best.\(id)") }
        let archived = Best(over: 0, seconds: 9, clean: true, archived: true), onDay = Best(over: 3, seconds: 9)
        archived.save(id)
        onDay.save(id)
        XCTAssertNil(Best.load(id)?.archived)
        XCTAssertEqual(Best.load(id)?.over, 3)
        archived.save(id)
        XCTAssertNil(Best.load(id)?.archived)
        XCTAssertTrue(Sync.beats(onDay, archived))
    }
}
