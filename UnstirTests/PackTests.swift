// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class PackTests: XCTestCase {
    /// Bests are stored under level ids and purchases under product ids, so a rename loses a player's progress or what
    /// they paid for. Every string here is a literal on purpose: change one only with a migration.
    func testStoredIdsAndProductIdsNeverChange() throws {
        // Vortex's is pinned ahead of its tier, so the pin holds whichever of the two lands first.
        let prefixes = ["plughole": "L", "whirlpool": "N", "vortex": "V", "maelstrom": "M"]
        for tier in Tier.allCases {
            let prefix = try XCTUnwrap(prefixes[tier.rawValue], "\(tier.rawValue) has no pinned prefix")
            XCTAssertEqual(tier.prefix, prefix)
            XCTAssertEqual(tier.levels.map(\.id), (1...27).map { "\(prefix)\($0)" })
        }
        XCTAssertTrue(Set(["plughole", "whirlpool", "maelstrom"]).isSubset(of: Tier.allCases.map(\.rawValue)))
        XCTAssertEqual(Level.daily(DateComponents(calendar: Calendar(identifier: .gregorian), year: 2026, month: 10,
                                                  day: 25).date!).id, "daily-20261025")
        XCTAssertEqual(Level.endless(Run(seed: 1)).id, "endless")
        XCTAssertEqual(Level.sandbox.id, "sandbox")

        XCTAssertEqual(Pack.allCases.map(\.prefix), ["first-stir", "lens", "escapement", "prism"])
        XCTAssertEqual(Pack.allCases.map { $0.id(1) }, ["first-stir-1", "lens-1", "escapement-1", "prism-1"])
        XCTAssertEqual(Pack.allCases.map(\.productID), ["com.screendead.Unstir.pack.firststir",
                                                        "com.screendead.Unstir.pack.lens",
                                                        "com.screendead.Unstir.pack.escapement",
                                                        "com.screendead.Unstir.pack.prism"])
        XCTAssertEqual(Pack.completeID, "com.screendead.Unstir.complete")
        XCTAssertEqual(Pack.productIDs.count, Set(Pack.productIDs).count)
        for pack in Pack.allCases {
            for (i, level) in pack.levels.enumerated() {
                XCTAssertEqual(level.pack, pack)
                XCTAssertEqual(level.id, pack.id(i + 1))
                XCTAssertEqual(pack.number(of: level.id), i + 1)
                XCTAssertTrue(level.keepsProgress, level.id)
            }
        }
    }

    /// Progress is stored under these keys: renaming one loses it as renaming an id does. Each is written through its
    /// own API and read back raw, and whatever was there is put back.
    @MainActor func testStorageKeysNeverChange() throws {
        let d = UserDefaults.standard, id = "pin-test"
        let keys = ["best.\(id)", "started.\(id)", "tier", "undos.spent", "undos.day", "undos.anchor", "unlock",
                    "tank.turned", "swirled", "endless.tanks", "undos.unseen", "undos.shown", "letters",
                    "music.off", "sounds.off", "haptics.off"]
        let saved = keys.map { d.object(forKey: $0) }
        defer { for (key, value) in zip(keys, saved) { d.set(value, forKey: key) } }
        for key in keys { d.removeObject(forKey: key) }

        Best(over: 1, seconds: 9).save(id)
        XCTAssertEqual(try JSONDecoder().decode(Best.self, from: try XCTUnwrap(d.data(forKey: "best.\(id)"))).over, 1)
        Best.start(id)
        XCTAssertTrue(d.bool(forKey: "started.\(id)"))
        Tier.store(.whirlpool, open: { _ in true })
        XCTAssertEqual(d.string(forKey: "tier"), "whirlpool")
        Best.undos = 7
        XCTAssertEqual(d.integer(forKey: "undos.spent"), 3)
        Best.refilled = "2026-10-25"
        XCTAssertEqual(d.string(forKey: "undos.day"), "2026-10-25")
        Best.anchor = Best.Anchor(wall: Date(timeIntervalSince1970: 0), uptime: 5, boot: nil)
        XCTAssertNotNil(d.data(forKey: "undos.anchor"))
        Best.unlocked = true
        XCTAssertTrue(d.bool(forKey: "unlock"))
        Best.tankTurned = true
        XCTAssertTrue(d.bool(forKey: "tank.turned"))
        Best.swirled = true
        XCTAssertTrue(d.bool(forKey: "swirled"))
        Best.tanks = 4
        XCTAssertEqual(d.integer(forKey: "endless.tanks"), 4)
        Best.unseenRefill = 2
        XCTAssertEqual(d.integer(forKey: "undos.unseen"), 2)
        Best.refillShown = true
        XCTAssertTrue(d.bool(forKey: "undos.shown"))
        Letters.choice = true
        XCTAssertEqual(d.object(forKey: "letters") as? Bool, true)
        Settings.music = false
        XCTAssertTrue(d.bool(forKey: "music.off"))
        Settings.sounds = false
        XCTAssertTrue(d.bool(forKey: "sounds.off"))
        Settings.haptics = false
        XCTAssertTrue(d.bool(forKey: "haptics.off"))
    }

    /// Music, sounds and haptics start on, with nothing stored. Jack's call C17, round 13.
    func testSettingsStartOn() {
        let d = UserDefaults.standard, keys = ["music.off", "sounds.off", "haptics.off"]
        let saved = keys.map { d.object(forKey: $0) }
        defer { for (key, value) in zip(keys, saved) { d.set(value, forKey: key) } }
        for key in keys { d.removeObject(forKey: key) }
        XCTAssertTrue(Settings.music)
        XCTAssertTrue(Settings.sounds)
        XCTAssertTrue(Settings.haptics)
        Settings.haptics = false
        XCTAssertFalse(Settings.haptics)
        XCTAssertTrue(Settings.music)
        Settings.haptics = true
        XCTAssertNil(d.object(forKey: "haptics.off"))
    }

    /// A harnessed launch holds the switches in memory: a tap lasts only that launch, and a stored choice never shows.
    func testHeldSettingsAreNeverStored() {
        let d = UserDefaults.standard, keys = ["music.off", "sounds.off", "haptics.off", "letters"]
        let saved = keys.map { d.object(forKey: $0) }
        defer {
            Settings.held.withLock { $0 = nil }
            for (key, value) in zip(keys, saved) { d.set(value, forKey: key) }
        }
        d.set(true, forKey: "music.off")
        d.set(true, forKey: "letters")
        d.removeObject(forKey: "sounds.off")
        Settings.held.withLock { $0 = ["music": true, "sounds": true, "haptics": false] }
        XCTAssertTrue(Settings.music)
        XCTAssertFalse(Settings.haptics)
        XCTAssertNil(Letters.choice)
        Settings.sounds = false
        Letters.choice = false
        XCTAssertFalse(Settings.sounds)
        XCTAssertEqual(Letters.choice, false)
        XCTAssertNil(d.object(forKey: "sounds.off"))
        XCTAssertEqual(d.object(forKey: "letters") as? Bool, true)
        Settings.held.withLock { $0 = nil }
        XCTAssertFalse(Settings.music)
        XCTAssertEqual(Letters.choice, true)
    }

    /// The support address and the policy's page are Jack's, so they live in Config/Local.xcconfig (gitignored) or the
    /// shell, never in a tracked file: the tracked config leaves both empty.
    func testNoTrackedConfigHoldsAPrivateValue() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let config = try String(contentsOf: root.appending(path: "Config/Unstir.xcconfig"), encoding: .utf8)
        let project = try String(contentsOf: root.appending(path: "project.yml"), encoding: .utf8)
        for key in ["SUPPORT_ADDRESS", "POLICY_URL"] {
            let set = config.split(separator: "\n").filter { $0.hasPrefix("\(key) =") || $0.hasPrefix("\(key)=") }
            XCTAssertEqual(set, ["\(key) ="], key)
            XCTAssertTrue(project.contains("$(\(key))"), key)
        }
        let keys = ["SUPPORT_ADDRESS", "POLICY_URL", "SupportAddress", "PolicyURL"]
        for line in (config + "\n" + project).split(separator: "\n").map({ $0.trimmingCharacters(in: .whitespaces) })
        where !line.hasPrefix("//") && !line.hasPrefix("#") && keys.contains(where: line.contains) {
            let value = line.drop { $0 != "=" && $0 != ":" }
            XCTAssertFalse(value.contains("@"), String(line))
            XCTAssertFalse(value.contains("$()/") || value.contains("://"), String(line))
        }
    }

    /// A pack's level whose id doesn't parse needs the card, even unlocked: it never plays as a level in no pack.
    @MainActor func testAMistypedPackIdFailsClosed() {
        for id in ["lens_7", "Lens-7", "lens-", "escapement-7"] {
            let level = Level(id: id, pack: .lens, label: "", title: "", layout: .tri, scramble: [])
            XCTAssertEqual(Store().access(level), .needsCard, id)
        }
        XCTAssertNil(Store().access(Level(id: "L7", label: "", title: "", layout: .tri, scramble: [])))
    }

    /// Opening a level past the taste of a pack the player doesn't own shows the pack's card in its place, from the menu
    /// or from the level before it; the taste and an owned pack play, and so does a level in no pack.
    @MainActor func testALevelPastTheTasteShowsItsCard() {
        let unlocked = Best.unlocked
        defer { Best.unlocked = unlocked }
        Best.unlocked = false
        func level(_ pack: Pack, _ n: Int) -> Level {
            Level(id: pack.id(n), pack: pack, label: "", title: "", layout: .tri, scramble: [])
        }
        let store = Store()
        XCTAssertNil(store.card(for: level(.lens, 3)))
        XCTAssertEqual(store.card(for: level(.lens, 4)), .lens)
        XCTAssertNil(store.card(for: Level.plughole[5]))
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .owned)
        XCTAssertFalse(store.ready)
        store.pretend(ledger)
        // The harness's states are known at launch, so nothing waits on StoreKit.
        XCTAssertTrue(store.ready)
        XCTAssertNil(store.card(for: level(.lens, 4)))
        XCTAssertEqual(store.card(for: level(.escapement, 4)), .escapement)
        ledger.record(Pack.lens.productID, .revoked)
        store.pretend(ledger)
        XCTAssertEqual(store.card(for: level(.lens, 4)), .lens)
    }

    /// First Stir plays whole from the shelf in order: its 25 scenes, each card's next the scene after; the taste of 3
    /// opens unowned and every scene past it shows the card, until the pack is owned. Nothing is left to arrive, and only a
    /// build outside Release shelves it (FS17).
    @MainActor func testFirstStirPlaysInOrderFromTheShelf() {
        let unlocked = Best.unlocked
        defer { Best.unlocked = unlocked }
        Best.unlocked = false
        let levels = Pack.firstStir.levels
        XCTAssertEqual(levels.count, 25)
        XCTAssertEqual(levels.map(\.id), (1...25).map { Pack.firstStir.id($0) })
        for (a, b) in zip(levels, levels.dropFirst()) {
            XCTAssertEqual(levels.drop { $0.id != a.id }.dropFirst().first?.id, b.id)
        }
        let store = Store()
        XCTAssertEqual(levels.map { store.card(for: $0) }, Array(repeating: nil, count: 3) + Array(repeating: .firstStir, count: 22))
        var ledger = Ledger()
        ledger.record(Pack.firstStir.productID, .owned)
        store.pretend(ledger)
        XCTAssertTrue(levels.allSatisfy { store.card(for: $0) == nil })
        XCTAssertTrue(Offer.shelf(release: false).contains(.pack(.firstStir)))
        XCTAssertFalse(Offer.shelf(release: true).contains(.pack(.firstStir)))
        XCTAssertFalse(Offer.pack(.firstStir).arriving)
    }

    /// Complete reads as owned once every pack is, however they were bought.
    @MainActor func testCompleteIsOwnedOnceEveryPackIs() {
        let store = Store()
        var ledger = Ledger()
        for pack in Pack.allCases.dropLast() { ledger.record(pack.productID, .owned) }
        store.pretend(ledger)
        XCTAssertEqual(store.state(.complete), .unowned)
        ledger.record(Pack.allCases.last!.productID, .owned)
        store.pretend(ledger)
        XCTAssertEqual(store.state(.complete), .owned)
        XCTAssertEqual(Offer.all.map(\.key), Pack.allCases.map(\.rawValue) + ["complete"])
        XCTAssertEqual(Offer.all.map { Offer(name: $0.key) }, Offer.all)
    }

    /// A pack's ids never read as another pack's or a tier's.
    /// A Release shelf shows a pack it sells once it has levels past its taste, and Complete once it shows every pack
    /// it sells; a build outside Release shows them all.
    func testAPackGoesOnTheShelfOnceItsLevelsAreIn() {
        XCTAssertEqual(Offer.shelf(release: false, ready: { _ in false }), Offer.all)
        XCTAssertEqual(Offer.shelf(release: true, ready: { _ in false }), [])
        XCTAssertEqual(Offer.shelf(release: true, ready: { $0 != .lens }), [.pack(.escapement), .pack(.prism)])
        XCTAssertEqual(Offer.shelf(release: true, ready: { _ in true }), [.pack(.lens), .pack(.escapement), .pack(.prism), .complete])
        for pack in Pack.allCases {
            XCTAssertEqual(Offer.shelf(release: true).contains(.pack(pack)), pack.ships && pack.levels.count > pack.taste,
                           pack.name)
            XCTAssertEqual(Offer.pack(pack).arriving, pack.levels.count < pack.planned, pack.name)
        }
        XCTAssertEqual(Offer.complete.arriving, Pack.allCases.contains { $0.levels.count < $0.planned })
    }

    /// First Stir is out of v1 (Jack, FS17), and Prism takes its place (PK1): a Release build neither sells First Stir nor
    /// opens its levels, taste and all, and Complete names only what it grants. Outside Release it stays whole.
    func testFirstStirIsOutOfV1() {
        XCTAssertEqual(Pack.sold(release: true), [.lens, .escapement, .prism])
        XCTAssertEqual(Pack.sold(release: false), Pack.allCases)
        XCTAssertEqual(Pack.firstStir.access(1, owned: [.firstStir], unlocked: true, release: true), .withheld)
        XCTAssertEqual(Pack.firstStir.access(4, owned: [.firstStir], release: true), .withheld)
        XCTAssertEqual(Pack.firstStir.access(1, owned: [], unlocked: false, release: false), .taste)
        XCTAssertEqual(Pack.prism.access(1, owned: [], release: true), .taste)
        XCTAssertEqual(Pack.prism.access(4, owned: [], release: true), .needsCard)
        XCTAssertEqual(Pack.prism.access(4, owned: [.prism], release: true), .owned)
        XCTAssertEqual(Pack.prism.access(4, owned: [], harness: [.prism], release: false), .owned)
        XCTAssertEqual(Pack.lens.access(1, owned: [], release: true), .taste)
        XCTAssertEqual(Pack.named(Pack.sold(release: true)), "Lens, Escapement and Prism")
        XCTAssertEqual(Pack.named(Pack.allCases), "First Stir, Lens, Escapement and Prism")
        XCTAssertEqual(Pack.named([.lens]), "Lens")
    }

    /// The developer unlock opens a pack past its taste in a Release build only when `scripts/run-ios.sh` installed it as
    /// a playtest, never in one that ships, and the harness's packs never in Release.
    func testThePlaytestUnlockOpensAPackOnlyInAPlaytest() {
        XCTAssertEqual(Pack.prism.access(4, owned: [], unlocked: true, release: true, playtest: true), .owned)
        XCTAssertEqual(Pack.prism.access(4, owned: [], unlocked: true, release: true, playtest: false), .needsCard)
        XCTAssertEqual(Pack.prism.access(4, owned: [], unlocked: false, release: true, playtest: true), .needsCard)
        XCTAssertEqual(Pack.prism.access(4, owned: [], unlocked: false, harness: [.prism], release: true, playtest: true), .needsCard)
        XCTAssertEqual(Pack.firstStir.access(4, owned: [], unlocked: true, release: true, playtest: true), .withheld)
    }

    func testPackIdsBelongToOnePack() {
        let tierIds = Tier.allCases.flatMap { $0.levels.map(\.id) } + ["endless", "sandbox", "daily-20261025"]
        for pack in Pack.allCases {
            XCTAssertTrue(tierIds.allSatisfy { pack.number(of: $0) == nil })
            for other in Pack.allCases {
                XCTAssertEqual(other.number(of: pack.id(4)), other == pack ? 4 : nil)
            }
        }
        XCTAssertNil(Pack.lens.number(of: "lens-0"))
        XCTAssertNil(Pack.lens.number(of: "lens-"))
        XCTAssertNil(Pack.lens.number(of: "lensx-1"))
    }

    /// Pack bests at par, however many, open no tier; only the tier below does.
    func testNoPackBestOpensATier() {
        let packIds = Set(Pack.allCases.flatMap { pack in (1...40).map { pack.id($0) } })
        let plughole = Set(Tier.plughole.levels.map(\.id))
        func best(_ ids: Set<String>) -> (String) -> Best? { { ids.contains($0) ? Best(over: 0, seconds: 1) : nil } }
        XCTAssertFalse(Tier.whirlpool.isOpen(unlocked: false, best(packIds)))
        XCTAssertFalse(Tier.maelstrom.isOpen(unlocked: false, best(packIds.union(plughole))))
        XCTAssertFalse(Tier.whirlpool.isOpen(unlocked: false, best(packIds.union(plughole.dropFirst()))))
        XCTAssertTrue(Tier.whirlpool.isOpen(unlocked: false, best(plughole)))
        XCTAssertEqual(Tier.stored(open: { $0.isOpen(unlocked: false, best(packIds)) }), .plughole)
    }

    /// UNSTIR_OWNED and UNSTIR_STORE never reach a Release build.
    func testHarnessPurchasesAreDebugOnly() {
        let env = ["UNSTIR_OWNED": "lens,complete", "UNSTIR_STORE": "escapement:pending"]
        XCTAssertNil(Harness.purchases(env, release: true))
        XCTAssertNil(Harness.purchases(["UNSTIR_PACK": "lens"], release: false))
        XCTAssertEqual(Harness.purchases(["UNSTIR_OWNED": "lens"], release: false)?.owned, [.lens])
        XCTAssertEqual(Harness.purchases(["UNSTIR_OWNED": "complete"], release: false)?.owned, Set(Pack.allCases))
    }

    func testHarnessSetsEachPurchaseState() throws {
        let ledger = try XCTUnwrap(Harness.purchases(["UNSTIR_STORE": "first-stir:pending,lens:failed,escapement:revoked"],
                                                     release: false))
        XCTAssertEqual(Pack.allCases.map(ledger.state), [.pending, .failed, .revoked, .unowned])
        let complete = try XCTUnwrap(Harness.purchases(["UNSTIR_STORE": "complete:revoked", "UNSTIR_OWNED": "lens"],
                                                       release: false))
        XCTAssertEqual(Pack.allCases.map(complete.state), [.revoked, .owned, .revoked, .revoked])
        XCTAssertEqual(Harness.purchases(["UNSTIR_STORE": "lens:unowned"], release: false)?.state(.lens), .unowned)
        let unshared = try XCTUnwrap(Harness.purchases(["UNSTIR_STORE": "lens:unshared"], release: false))
        XCTAssertEqual(unshared.state(.lens), .revoked)
        XCTAssertTrue(unshared.unshared(.lens))
    }

    /// An owner's pill plays from the first level without a best, then the first not at par, and goes once all are at
    /// par; it says continue once a level past the taste is solved.
    @MainActor func testAnOwnerPicksUpWhereTheyLeftOff() {
        let levels = Pack.lens.levels
        var bests: [String: Best] = [:]
        func best(_ id: String) -> Best? { bests[id] }
        XCTAssertEqual(PackCard.pickUp(levels, best: best)?.label, "01")
        XCTAssertFalse(PackCard.continues(levels, best: best))
        for level in levels.prefix(3) { bests[level.id] = Best(over: 0, seconds: 60) }
        XCTAssertEqual(PackCard.pickUp(levels, best: best)?.label, "04")
        XCTAssertFalse(PackCard.continues(levels, best: best))
        bests[levels[3].id] = Best(over: 2, seconds: 60)
        XCTAssertEqual(PackCard.pickUp(levels, best: best)?.label, "05")
        XCTAssertTrue(PackCard.continues(levels, best: best))
        for level in levels where bests[level.id] == nil { bests[level.id] = Best(over: 0, seconds: 60) }
        XCTAssertEqual(PackCard.pickUp(levels, best: best)?.label, "04")
        bests[levels[3].id] = Best(over: 0, seconds: 60)
        XCTAssertNil(PackCard.pickUp(levels, best: best))
    }

    /// Try free plays the taste's first level without a best, then offers the three again; the gate's note counts
    /// what is left.
    @MainActor func testTryFreeGoesWhereTheTasteLeftOff() {
        let levels = Pack.lens.levels
        var bests: [String: Best] = [:]
        func best(_ id: String) -> Best? { bests[id] }
        XCTAssertEqual(PackCard.taste(levels, best: best).map { [$0.level.label, "\($0.replay)"] }, ["01", "false"])
        bests[levels[0].id] = Best(over: 1, seconds: 60)
        bests[levels[2].id] = Best(over: 0, seconds: 60)
        XCTAssertEqual(PackCard.taste(levels, best: best).map { [$0.level.label, "\($0.replay)"] }, ["02", "false"])
        bests[levels[1].id] = Best(over: 0, seconds: 60)
        XCTAssertEqual(PackCard.taste(levels, best: best).map { [$0.level.label, "\($0.replay)"] }, ["01", "true"])
        XCTAssertNil(PackCard.taste([], best: best))
        XCTAssertEqual(PackCard.arrival(.pack(.lens), levels, state: .unowned, best: best),
                       "You've played the free three. 22 more in Lens.")
        XCTAssertEqual(PackCard.arrival(.pack(.escapement), Pack.escapement.levels, state: .pending, best: { _ in
            Best(over: 0, seconds: 60) }), "You've played the free three. 27 more in Escapement.")
        XCTAssertNil(PackCard.arrival(.complete, [], state: .unowned, best: best))
        // Only while it is true: not before every free level has a best, nor to an owner or a refunded one.
        XCTAssertNil(PackCard.arrival(.pack(.lens), levels, state: .unowned, best: { _ in nil }))
        XCTAssertNil(PackCard.arrival(.pack(.lens), levels, state: .revoked, best: best))
        XCTAssertNil(PackCard.arrival(.pack(.lens), levels, state: .owned, best: best))
    }

    /// Only a change after the launch's first read lands: before it, an owner's card reads unowned until the read does.
    @MainActor func testTheLaunchsFirstReadIsNoLanding() {
        XCTAssertFalse(PackCard.lands(.unowned, .owned, ready: false))
        XCTAssertTrue(PackCard.lands(.unowned, .owned, ready: true))
        XCTAssertTrue(PackCard.lands(.pending, .owned, ready: true))
        XCTAssertFalse(PackCard.lands(.owned, .owned, ready: true))
        XCTAssertFalse(PackCard.lands(.unowned, .pending, ready: true))
    }

    @MainActor func testHarnessSetsTheCardsMessages() {
        let h = Harness(["UNSTIR_CARD": "lens", "UNSTIR_STORE": "lens:failed", "UNSTIR_FAILED": "offline",
                         "UNSTIR_PRICES": "unreachable", "UNSTIR_PAYMENTS": "0", "UNSTIR_RESTORED": "lens,prism"])
        XCTAssertEqual(h.failure, .offline)
        XCTAssertEqual(h.prices, [:])
        XCTAssertEqual(h.pricing, .unreachable)
        XCTAssertFalse(h.canPay)
        XCTAssertEqual(h.restored, .found([.lens, .prism]))
        XCTAssertEqual(Harness(["UNSTIR_RESTORED": "none"]).restored, .nothing)
        XCTAssertEqual(Harness(["UNSTIR_PRICES": "0"]).pricing, .fetching)
    }

    /// UNSTIR_OWNED lasts the launch: nothing it grants is written anywhere, and solving the placeholder it opens
    /// stores no best or started flag under the id a real level will take.
    @MainActor func testHarnessOwnedIsNeverStored() throws {
        // Harness.init writes the developer unlock, so it alone is left out.
        func stored() -> NSDictionary {
            NSDictionary(dictionary: (UserDefaults.standard.persistentDomain(forName: Bundle.main.bundleIdentifier!) ?? [:])
                .filter { $0.key != "unlock" })
        }
        // An earlier build's harness launch may have left them on this simulator.
        for key in ["best.escapement-31", "started.escapement-31"] { UserDefaults.standard.removeObject(forKey: key) }
        let before = stored()
        let h = Harness(["UNSTIR_OWNED": "complete", "UNSTIR_PACK": "escapement", "UNSTIR_LEVEL": "31"])
        let store = Store()
        store.pretend(try XCTUnwrap(h.purchases))
        XCTAssertEqual(h.level.id, "escapement-31")
        XCTAssertEqual(h.level.pack, .escapement)
        XCTAssertEqual(store.access(h.level), .owned)
        XCTAssertEqual(store.state(.escapement), .owned)
        XCTAssertEqual(store.ledger.owned, [], "the harness's packs are not StoreKit's")
        XCTAssertFalse(h.level.keepsProgress)
        let game = Game(level: h.level)
        game.commit(rod: 0, steps: -4)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(stored(), before)
        XCTAssertNil(Best.load("escapement-31"))
        XCTAssertFalse(Best.started("escapement-31"))
        XCTAssertEqual(Store().access(h.level), .needsCard)
        XCTAssertEqual(Store().access(Harness(["UNSTIR_PACK": "lens", "UNSTIR_LEVEL": "3"]).level), .taste)
        Best.unlocked = false
    }
}
