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

        XCTAssertEqual(Pack.allCases.map(\.prefix), ["first-stir", "lens", "escapement"])
        XCTAssertEqual(Pack.allCases.map { $0.id(1) }, ["first-stir-1", "lens-1", "escapement-1"])
        XCTAssertEqual(Pack.allCases.map(\.productID), ["com.screendead.Unstir.pack.firststir",
                                                        "com.screendead.Unstir.pack.lens",
                                                        "com.screendead.Unstir.pack.escapement"])
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
                    "tank.turned", "swirled", "endless.tanks"]
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
    }

    /// A pack's level whose id doesn't parse needs the card, even unlocked: it never plays as a level in no pack.
    @MainActor func testAMistypedPackIdFailsClosed() {
        for id in ["lens_7", "Lens-7", "lens-", "escapement-7"] {
            let level = Level(id: id, pack: .lens, label: "", title: "", layout: .tri, scramble: [])
            XCTAssertEqual(Store().access(level), .needsCard, id)
        }
        XCTAssertNil(Store().access(Level(id: "L7", label: "", title: "", layout: .tri, scramble: [])))
    }

    /// A pack's ids never read as another pack's or a tier's.
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
        XCTAssertEqual(Pack.allCases.map(ledger.state), [.pending, .failed, .revoked])
        let complete = try XCTUnwrap(Harness.purchases(["UNSTIR_STORE": "complete:revoked", "UNSTIR_OWNED": "lens"],
                                                       release: false))
        XCTAssertEqual(Pack.allCases.map(complete.state), [.revoked, .owned, .revoked])
        XCTAssertEqual(Harness.purchases(["UNSTIR_STORE": "lens:unowned"], release: false)?.state(.lens), .unowned)
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
        for key in ["best.lens-5", "started.lens-5"] { UserDefaults.standard.removeObject(forKey: key) }
        let before = stored()
        let h = Harness(["UNSTIR_OWNED": "complete", "UNSTIR_PACK": "lens", "UNSTIR_LEVEL": "5"])
        let store = Store()
        store.pretend(try XCTUnwrap(h.purchases))
        XCTAssertEqual(h.level.id, "lens-5")
        XCTAssertEqual(h.level.pack, .lens)
        XCTAssertEqual(store.access(h.level), .owned)
        XCTAssertEqual(store.state(.escapement), .owned)
        XCTAssertEqual(store.ledger.owned, [], "the harness's packs are not StoreKit's")
        XCTAssertFalse(h.level.keepsProgress)
        let game = Game(level: h.level)
        game.commit(rod: 0, steps: -4)
        XCTAssertTrue(game.solved)
        XCTAssertEqual(stored(), before)
        XCTAssertNil(Best.load("lens-5"))
        XCTAssertFalse(Best.started("lens-5"))
        XCTAssertEqual(Store().access(h.level), .needsCard)
        XCTAssertEqual(Store().access(Harness(["UNSTIR_PACK": "lens", "UNSTIR_LEVEL": "3"]).level), .taste)
        Best.unlocked = false
    }
}
