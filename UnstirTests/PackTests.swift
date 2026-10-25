// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class PackTests: XCTestCase {
    /// Bests are stored under level ids and purchases under product ids, so a rename loses a player's progress or what
    /// they paid for. Every string here is a literal on purpose: change one only with a migration.
    func testStoredIdsAndProductIdsNeverChange() {
        XCTAssertEqual(Tier.allCases.map(\.rawValue), ["plughole", "whirlpool", "maelstrom"])
        XCTAssertEqual(Tier.allCases.map(\.prefix), ["L", "N", "M"])
        for (tier, prefix) in zip(Tier.allCases, ["L", "N", "M"]) {
            XCTAssertEqual(tier.levels.map(\.id), (1...27).map { "\(prefix)\($0)" })
        }
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
            for level in pack.levels {
                XCTAssertEqual(level.pack, pack)
                XCTAssertNotNil(pack.number(of: level.id), level.id)
            }
        }
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
}
