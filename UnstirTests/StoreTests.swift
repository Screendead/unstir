// Copyright © 2026 Jack Lusher. All rights reserved.

import StoreKit
import StoreKitTest
import XCTest
@testable import Unstir

/// The entitlement rules, without StoreKit.
final class LedgerTests: XCTestCase {
    func testCompleteGrantsEveryPack() {
        var ledger = Ledger()
        ledger.record(Pack.completeID, .owned)
        XCTAssertEqual(ledger.owned, Set(Pack.allCases))
    }

    func testOnlyARevocationTakesAPackAway() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .owned)
        for state in [Purchase.pending, .failed, .unowned] {
            ledger.record(Pack.lens.productID, state)
            XCTAssertEqual(ledger.state(.lens), .owned)
        }
        ledger.record(Pack.lens.productID, .revoked)
        XCTAssertEqual(ledger.state(.lens), .revoked)
        ledger.record(Pack.lens.productID, .pending)
        XCTAssertEqual(ledger.state(.lens), .pending)
    }

    /// Closing a card forgets a failed attempt, Complete's too, and nothing else.
    func testForgettingFailuresLeavesEveryOtherState() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .failed)
        ledger.record(Pack.completeID, .failed)
        ledger.record(Pack.escapement.productID, .pending)
        ledger.forgetFailures()
        XCTAssertEqual(ledger.state(.lens), .unowned)
        XCTAssertEqual(ledger.state(.firstStir), .unowned)
        XCTAssertEqual(ledger.state(.escapement), .pending)
    }

    /// Complete's failure shows on Complete's card, never on a pack's.
    func testCompletesFailureStaysOnItsOwnCard() {
        var ledger = Ledger()
        ledger.record(Pack.completeID, .failed)
        XCTAssertEqual(ledger.state(.lens), .unowned)
        ledger.record(Pack.completeID, .pending)
        XCTAssertEqual(ledger.state(.lens), .pending)
    }

    /// The entitlements reread after a revocation own the product again when it was bought since.
    func testOwnedAfterARevocationOwnsAgain() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .owned)
        ledger.record(Pack.lens.productID, .revoked)
        ledger.record(Pack.lens.productID, .owned)
        XCTAssertEqual(ledger.state(.lens), .owned)
    }

    /// A child asks, taps buy again and cancels the sheet: the parent's answer is still outstanding.
    func testCancellingASecondPurchaseKeepsAskToBuyPending() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .pending)
        ledger.record(Pack.lens.productID, .unowned)
        XCTAssertEqual(ledger.state(.lens), .pending)
        ledger.record(Pack.lens.productID, .owned)
        XCTAssertEqual(ledger.state(.lens), .owned)
    }

    /// Complete revoked takes back only what it alone granted.
    func testRevokedCompleteKeepsAPackBoughtOnItsOwn() {
        var ledger = Ledger()
        ledger.record(Pack.completeID, .owned)
        ledger.record(Pack.escapement.productID, .owned)
        ledger.record(Pack.completeID, .revoked)
        XCTAssertEqual(ledger.owned, [.escapement])
        XCTAssertEqual(ledger.state(.lens), .revoked)
        ledger.record(Pack.lens.productID, .pending)
        XCTAssertEqual(ledger.state(.lens), .pending)
    }

    func testTheTasteIsFreeAndThePackIsNot() {
        for pack in Pack.allCases {
            XCTAssertEqual((1...pack.taste).map { pack.access($0, owned: [], unlocked: false) },
                           Array(repeating: .taste, count: pack.taste))
            XCTAssertEqual(pack.access(pack.taste + 1, owned: [], unlocked: false), .needsCard)
            XCTAssertEqual(pack.access(pack.taste + 1, owned: [pack], unlocked: false), .owned)
            XCTAssertEqual(pack.access(pack.taste + 1, owned: Set(Pack.allCases).subtracting([pack]), unlocked: false),
                           .needsCard)
        }
    }

    /// Only StoreKit opens a pack in Release: never the developer unlock, never the harness.
    func testNothingButAPurchaseOpensAPackInRelease() {
        XCTAssertEqual(Pack.lens.access(4, owned: [], unlocked: true, release: true), .needsCard)
        XCTAssertEqual(Pack.lens.access(4, owned: [], unlocked: false, harness: [.lens], release: true), .needsCard)
        XCTAssertEqual(Pack.lens.access(4, owned: [.lens], unlocked: false, release: true), .owned)
        XCTAssertEqual(Pack.lens.access(4, owned: [], unlocked: true, release: false), .owned)
        XCTAssertEqual(Pack.lens.access(4, owned: [], unlocked: false, harness: [.lens], release: false), .owned)
    }

    /// A revoked pack shows the card past its taste, and its bests stay.
    @MainActor func testARevokedPackKeepsItsProgress() {
        let id = Pack.lens.id(5)
        defer { UserDefaults.standard.removeObject(forKey: "best.\(id)") }
        Best(over: 0, seconds: 30).save(id)
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .owned)
        ledger.record(Pack.lens.productID, .revoked)
        XCTAssertEqual(Pack.lens.access(5, owned: ledger.owned, unlocked: false), .needsCard)
        XCTAssertEqual(Pack.lens.access(2, owned: ledger.owned, unlocked: false), .taste)
        XCTAssertEqual(Best.load(id)?.over, 0)
    }
}

/// Purchases through StoreKit's local test session, against StoreKit/Unstir.storekit.
@MainActor
final class StoreTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["UNSTIR_STORE_TESTS"] == "1",
                          "StoreKit test sessions need a host app signed with get-task-allow: run scripts/test-store.sh")
        session = try SKTestSession(configurationFileNamed: "Unstir")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        let found = try await Product.products(for: Pack.productIDs)
        XCTAssertEqual(Set(found.map(\.id)), Set(Pack.productIDs), "the test session served no products")
        for product in found {
            XCTAssertEqual(product.type, .nonConsumable)
            XCTAssertTrue(product.isFamilyShareable, product.id)
        }
    }

    override func tearDown() async throws {
        session?.clearTransactions()
        session = nil
    }

    /// StoreKit's reads lag a purchase by up to a second or so on the simulator.
    private func eventually(_ what: String, _ check: () async -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(30)
        while !(await check()) {
            guard ContinuousClock.now < deadline else { return XCTFail("timed out waiting for \(what)") }
            try await Task.sleep(for: .milliseconds(200))
        }
    }

    /// What a new launch reads back.
    private func relaunch(owns packs: Set<Pack>) async throws {
        let next = Store()
        try await eventually("a launch to read \(packs.map(\.name))") {
            await next.refresh()
            return next.ledger.owned == packs
        }
    }

    /// The card shows the App Store's price, never one of the app's own.
    func testStartFetchesEveryPrice() async throws {
        let store = Store()
        await store.start()
        for id in Pack.productIDs { XCTAssertNotNil(store.price(id), id) }
        XCTAssertNotEqual(store.price(Pack.lens.productID), store.price(Pack.completeID))
    }

    func testPurchaseGrantsOnePack() async throws {
        let store = Store()
        await store.start()
        await store.purchase(.lens)
        XCTAssertEqual(store.state(.lens), .owned)
        XCTAssertEqual(store.ledger.owned, [.lens])
        XCTAssertEqual(store.state(.escapement), .unowned)
        XCTAssertEqual(store.access(Level(id: Pack.lens.id(4), pack: .lens, label: "", title: "", layout: .tri,
                                          scramble: [])), .owned)
        XCTAssertEqual(store.access(Level(id: Pack.escapement.id(4), pack: .escapement, label: "", title: "",
                                          layout: .tri, scramble: [])), .needsCard)
        try await relaunch(owns: [.lens])
    }

    func testCompleteGrantsAllThree() async throws {
        let store = Store()
        await store.start()
        await store.purchase(Pack.completeID)
        XCTAssertEqual(store.ledger.owned, Set(Pack.allCases))
        try await relaunch(owns: Set(Pack.allCases))
    }

    func testRefundRevokesThePack() async throws {
        let store = Store()
        await store.start()
        await store.purchase(.firstStir)
        await store.purchase(Pack.completeID)
        XCTAssertEqual(store.ledger.owned, Set(Pack.allCases))
        let complete = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == Pack.completeID })
        try session.refundTransaction(identifier: complete.identifier)
        try await eventually("the refund to reach the listener") { store.state(.lens) == .revoked }
        XCTAssertEqual(store.ledger.owned, [.firstStir])
        XCTAssertEqual(store.state(.escapement), .revoked)
        try await relaunch(owns: [.firstStir])
    }

    /// A refund of an old purchase that reaches the listener after the pack was bought again leaves it owned.
    func testALateRefundOfAnOldPurchaseKeepsTheNewOne() async throws {
        let store = Store()
        await store.start()
        await store.purchase(.lens)
        let first = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == Pack.lens.productID })
        try session.refundTransaction(identifier: first.identifier)
        try await eventually("the refund to reach the listener") { store.state(.lens) == .revoked }
        await store.purchase(.lens)
        XCTAssertEqual(store.state(.lens), .owned)
        try await relaunch(owns: [.lens])
        var old: VerificationResult<Transaction>?
        for await result in Transaction.all {
            if case .verified(let t) = result, t.id == UInt64(first.identifier), t.revocationDate != nil { old = result }
        }
        await store.apply(try XCTUnwrap(old, "the refunded purchase"))
        XCTAssertEqual(store.state(.lens), .owned)
    }

    func testAskToBuyWaitsForTheParent() async throws {
        session.askToBuyEnabled = true
        let store = Store()
        await store.start()
        await store.purchase(.escapement)
        XCTAssertEqual(store.state(.escapement), .pending)
        XCTAssertEqual(store.ledger.owned, [])
        let asked = try XCTUnwrap(session.allTransactions().first { $0.pendingAskToBuyConfirmation })
        try session.approveAskToBuyTransaction(identifier: asked.identifier)
        try await eventually("the approval to reach the listener") { store.state(.escapement) == .owned }
        XCTAssertEqual(store.ledger.owned, [.escapement])
    }

    func testAskToBuyDeclinedGrantsNothing() async throws {
        session.askToBuyEnabled = true
        let store = Store()
        await store.start()
        await store.purchase(.lens)
        let asked = try XCTUnwrap(session.allTransactions().first { $0.pendingAskToBuyConfirmation })
        try session.declineAskToBuyTransaction(identifier: asked.identifier)
        try await Task.sleep(for: .seconds(2))
        XCTAssertEqual(store.ledger.owned, [])
        try await relaunch(owns: [])
    }

    func testFailedPurchaseGrantsNothing() async throws {
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .purchase)
        let store = Store()
        await store.start()
        await store.purchase(.lens)
        XCTAssertEqual(store.state(.lens), .failed)
        XCTAssertEqual(store.ledger.owned, [])
        // Clearing the error alone leaves the session failing every purchase; a reset clears it.
        session.resetToDefaultState()
        session.disableDialogs = true
        await store.purchase(.lens)
        XCTAssertEqual(store.state(.lens), .owned)
    }

    /// A transaction the App Store didn't sign grants nothing.
    func testUnverifiedPurchaseGrantsNothing() async throws {
        try await session.setSimulatedError(.verification(.invalidSignature), forAPI: .verification)
        let store = Store()
        await store.start()
        await store.purchase(.lens)
        XCTAssertEqual(store.state(.lens), .failed)
        XCTAssertEqual(store.ledger.owned, [])
        await store.refresh()
        XCTAssertEqual(store.ledger.owned, [])
        try await session.setSimulatedError(nil, forAPI: .verification)
    }

    /// A restore that syncs reads what was bought; one whose sync fails says so and reads nothing, keeping what was known.
    func testRestoreReadsWhatWasBoughtOnlyAfterASync() async throws {
        let store = Store()
        await store.purchase(.escapement)
        let next = Store()
        try await eventually("restore to find the purchase") {
            let synced = await next.restore()
            return synced && next.ledger.owned == [.escapement]
        }
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))),
                                            forAPI: .appStoreSync)
        let offline = Store()
        let synced = await offline.restore()
        XCTAssertFalse(synced)
        XCTAssertEqual(offline.ledger.owned, [])
        let resynced = await next.restore()
        XCTAssertFalse(resynced)
        XCTAssertEqual(next.ledger.owned, [.escapement])
        try await session.setSimulatedError(nil, forAPI: .appStoreSync)
    }
}
