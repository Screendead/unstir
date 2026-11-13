// Copyright © 2026 Jack Lusher. All rights reserved.

import StoreKit
import StoreKitTest
import XCTest
@testable import Unstir

/// The entitlement rules, without StoreKit.
final class LedgerTests: XCTestCase {
    func testTheBundleGrantsItsThreePacks() {
        var ledger = Ledger()
        ledger.record(Pack.triptychID, .owned)
        XCTAssertEqual(ledger.owned, Set(Pack.bundled))
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

    /// Closing a card forgets a failed attempt, Triptych I's too, and nothing else.
    func testForgettingFailuresLeavesEveryOtherState() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .failed)
        ledger.record(Pack.triptychID, .failed)
        ledger.record(Pack.escapement.productID, .pending)
        ledger.forgetFailures()
        XCTAssertEqual(ledger.state(.lens), .unowned)
        XCTAssertEqual(ledger.state(.firstStir), .unowned)
        XCTAssertEqual(ledger.state(.escapement), .pending)
    }

    /// Triptych I's failure shows on Triptych I's card, never on a pack's.
    func testCompletesFailureStaysOnItsOwnCard() {
        var ledger = Ledger()
        ledger.record(Pack.triptychID, .failed)
        XCTAssertEqual(ledger.state(.lens), .unowned)
        ledger.record(Pack.triptychID, .pending)
        XCTAssertEqual(ledger.state(.lens), .pending)
    }

    /// A pack waiting only on Triptych I's Ask to Buy reads as pending, but its card has no request of its own to send again.
    @MainActor func testAPackWaitingOnCompleteHasNothingOfItsOwnToAskAgain() {
        var ledger = Ledger()
        ledger.record(Pack.triptychID, .pending)
        XCTAssertEqual(ledger.state(.lens), .pending)
        XCTAssertFalse(ledger.asked(Pack.lens.productID))
        XCTAssertTrue(ledger.asked(Pack.triptychID))
        let store = Store()
        store.pretend(ledger)
        XCTAssertFalse(store.asked(.pack(.lens)))
        XCTAssertTrue(store.asked(.complete))
        ledger.record(Pack.lens.productID, .pending)
        XCTAssertTrue(ledger.asked(Pack.lens.productID))
    }

    /// The entitlements reread after a revocation own the product again when it was bought since.
    func testOwnedAfterARevocationOwnsAgain() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .owned)
        ledger.record(Pack.lens.productID, .revoked)
        ledger.record(Pack.lens.productID, .owned)
        XCTAssertEqual(ledger.state(.lens), .owned)
    }

    /// A child asks, asks again and cancels the sheet, or asks again offline: the parent's answer is still outstanding.
    func testCancellingASecondPurchaseKeepsAskToBuyPending() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .pending)
        ledger.record(Pack.lens.productID, .unowned)
        XCTAssertEqual(ledger.state(.lens), .pending)
        ledger.record(Pack.lens.productID, .failed)
        XCTAssertEqual(ledger.state(.lens), .pending)
        ledger.forgetFailures()
        XCTAssertEqual(ledger.state(.lens), .pending)
        ledger.record(Pack.lens.productID, .owned)
        XCTAssertEqual(ledger.state(.lens), .owned)
    }

    /// A family's share ended is told from a refund, through the pack's own product or Triptych I, until it is owned again.
    func testAShareEndedIsNoRefund() {
        var ledger = Ledger()
        ledger.record(Pack.lens.productID, .owned)
        ledger.record(Pack.lens.productID, .revoked, shared: true)
        XCTAssertEqual(ledger.state(.lens), .revoked)
        XCTAssertTrue(ledger.unshared(.lens))
        ledger.record(Pack.triptychID, .revoked)
        XCTAssertFalse(ledger.unshared(.escapement))
        ledger.record(Pack.triptychID, .revoked, shared: true)
        XCTAssertTrue(ledger.unshared(.escapement))
        ledger.record(Pack.lens.productID, .revoked)
        XCTAssertFalse(ledger.unshared(.lens))
        ledger.record(Pack.lens.productID, .owned)
        XCTAssertFalse(ledger.unshared(.lens))
    }

    /// Triptych I revoked takes back only what it alone granted.
    func testRevokedCompleteKeepsAPackBoughtOnItsOwn() {
        var ledger = Ledger()
        ledger.record(Pack.triptychID, .owned)
        ledger.record(Pack.escapement.productID, .owned)
        ledger.record(Pack.triptychID, .revoked)
        XCTAssertEqual(ledger.owned, [.escapement])
        XCTAssertEqual(ledger.state(.lens), .revoked)
        ledger.record(Pack.lens.productID, .pending)
        XCTAssertEqual(ledger.state(.lens), .pending)
    }

    /// The card tells being offline, a storefront without the pack and purchases turned off apart from the rest.
    func testEachFailureSaysWhy() {
        XCTAssertEqual(Failure(StoreKitError.networkError(URLError(.notConnectedToInternet))), .offline)
        XCTAssertEqual(Failure(URLError(.timedOut)), .offline)
        XCTAssertEqual(Failure(StoreKitError.notAvailableInStorefront), .storefront)
        XCTAssertEqual(Failure(Product.PurchaseError.purchaseNotAllowed), .refused)
        XCTAssertEqual(Failure(StoreKitError.userCancelled), .cancelled)
        XCTAssertEqual(Failure(StoreKitError.unknown), .other)
        XCTAssertNil(Failure.other.words)
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
        forgetRequests()
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
        forgetRequests()
    }

    /// A purchase under Ask to Buy saves its request, and a request saved within the day waits again on every later
    /// launch's read, so one left by an earlier test would hold the next test's card at pending.
    private func forgetRequests() {
        for id in Pack.productIDs { Asked.remove(id) }
    }

    /// StoreKit's reads lag a purchase by up to a second or so on the simulator.
    private func eventually(_ what: String, _ check: () async -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(30)
        while !(await check()) {
            guard ContinuousClock.now < deadline else { return XCTFail("timed out waiting for \(what)") }
            try await Task.sleep(for: .milliseconds(200))
        }
    }

    /// The products StoreKit itself holds as owned, read past the app's ledger.
    private func entitled() async -> Set<String> {
        var ids: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil { ids.insert(t.productID) }
        }
        return ids
    }

    /// The iOS 27.2 simulator's test session can record a refund made as a purchase's `finish` returns without sending
    /// it to `Transaction.updates` (two runs of three; never after a read of `Transaction.unfinished`, a few
    /// milliseconds), so a refund waits until StoreKit lists nothing unfinished.
    private func finished() async throws {
        try await eventually("StoreKit to finish the purchases") {
            for await _ in Transaction.unfinished { return false }
            return true
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
        XCTAssertNotEqual(store.price(Pack.lens.productID), store.price(Pack.triptychID))
    }

    /// The gate waits for the launch's first read, which `start` finishes before it returns.
    func testTheStoreIsReadyOnceItHasReadTheEntitlements() async throws {
        let store = Store()
        XCTAssertFalse(store.ready)
        await store.settled()
        await store.start()
        XCTAssertTrue(store.ready)
        await store.settled()
    }

    /// Offline, the entitlements are still read from the device, so the first read ends and a card's "checking
    /// purchases…" gives way to its state, its price saying the App Store is unreachable. The fetch fails by
    /// `Store.loadProducts`, as the runner's test session (Xcode 26, iOS 26.2) still served the products under a simulated
    /// `.loadProducts` error.
    func testOfflineTheFirstReadStillEnds() async throws {
        let store = Store()
        store.loadProducts = { _ in throw URLError(.notConnectedToInternet) }
        await store.start()
        XCTAssertTrue(store.ready)
        XCTAssertEqual(store.pricing, .unreachable)
    }

    /// A first read that stalls holds the cards at "checking purchases…" only until the limit, and carries on past it.
    func testAStalledFirstReadReadiesTheStoreAtTheLimit() async throws {
        XCTAssertEqual(Store().readLimit, .seconds(5))
        let store = Store()
        store.readLimit = .milliseconds(200)
        let (stall, release) = AsyncStream<Void>.makeStream()
        store.firstRead = { store in
            for await _ in stall {}
            await store.refresh()
        }
        await store.start()
        XCTAssertTrue(store.ready)
        XCTAssertFalse(store.firstReadDone)
        await store.settled()
        release.finish()
        try await eventually("the stalled read to land") { store.firstReadDone }
        XCTAssertTrue(store.ready)
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
        await store.purchase(Pack.triptychID)
        XCTAssertEqual(store.ledger.owned, Set(Pack.bundled))
        try await relaunch(owns: Set(Pack.bundled))
    }

    func testRefundRevokesThePack() async throws {
        let store = Store()
        await store.start()
        await store.purchase(.firstStir)
        await store.purchase(Pack.triptychID)
        XCTAssertEqual(store.ledger.owned, Set(Pack.allCases))
        try await finished()
        let complete = try XCTUnwrap(session.allTransactions().first { $0.productIdentifier == Pack.triptychID })
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
        try await finished()
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
        // The iOS 27.2 simulator's test session marks the declined request failed and still has StoreKit sign and send
        // its purchase, the same in every field as an approval's, where iOS 26.5's sends nothing. No app could tell
        // that from an approval, so there the test holds the app to what StoreKit granted and goes no further.
        let granted = await entitled()
        XCTAssertEqual(Set(store.ledger.owned.map(\.productID)), granted)
        try XCTSkipUnless(granted.isEmpty, "this runtime's test session grants a declined Ask to Buy")
        XCTAssertEqual(store.ledger.owned, [])
        // StoreKit sends nothing for a decline, so the card still waits, and asking again sends the parent a new request.
        XCTAssertEqual(store.state(.lens), .pending)
        await store.purchase(.lens)
        XCTAssertEqual(store.state(.lens), .pending)
        let again = session.allTransactions().filter { $0.pendingAskToBuyConfirmation }
        XCTAssertEqual(again.count, 1)
        XCTAssertNotEqual(again.first?.identifier, asked.identifier)
        // Left waiting, the request holds up the next test's approval.
        try session.declineAskToBuyTransaction(identifier: try XCTUnwrap(again.first).identifier)
        try await Task.sleep(for: .seconds(2))
        try await relaunch(owns: [])
    }

    func testFailedPurchaseGrantsNothing() async throws {
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))), forAPI: .purchase)
        let store = Store()
        await store.start()
        await store.purchase(.lens)
        XCTAssertEqual(store.state(.lens), .failed)
        XCTAssertEqual(store.failures[Pack.lens.productID], .offline)
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

    /// A restore that syncs says what it found that wasn't owned before; one whose sync fails says so and reads nothing,
    /// keeping what was known.
    func testRestoreReadsWhatWasBoughtOnlyAfterASync() async throws {
        let store = Store()
        await store.purchase(.escapement)
        let next = Store()
        try await eventually("restore to find the purchase") {
            let found = await next.restore()
            return found == .found([.escapement]) && next.ledger.owned == [.escapement]
        }
        let again = await next.restore()
        XCTAssertEqual(again, .nothing)
        try await session.setSimulatedError(.generic(.networkError(URLError(.notConnectedToInternet))),
                                            forAPI: .appStoreSync)
        let offline = Store()
        let synced = await offline.restore()
        XCTAssertEqual(synced, .failed)
        XCTAssertEqual(offline.ledger.owned, [])
        let resynced = await next.restore()
        XCTAssertEqual(resynced, .failed)
        XCTAssertEqual(next.ledger.owned, [.escapement])
        try await session.setSimulatedError(nil, forAPI: .appStoreSync)
    }
}
