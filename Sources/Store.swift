// Copyright © 2026 Jack Lusher. All rights reserved.

import Observation
import StoreKit

/// Where a player stands with one product.
enum Purchase: String, CaseIterable, Sendable {
    /// `failed` is the last attempt's error; `revoked` a refund, or a family member's purchase no longer shared.
    case unowned, owned, pending, failed, revoked
}

/// Each product's latest `Purchase`, and what that makes of each pack.
struct Ledger: Equatable, Sendable {
    private(set) var products: [String: Purchase] = [:]

    /// Once owned, only a revocation takes a product away: a later attempt that fails, waits or is cancelled is not one.
    /// A cancelled sheet leaves an Ask to Buy still waiting on its parent.
    mutating func record(_ id: String, _ state: Purchase) {
        if products[id] == .owned && state != .revoked { return }
        if products[id] == .pending && state == .unowned { return }
        products[id] = state
    }

    /// Owned through its own product or Complete; otherwise its own product's state, else Complete's.
    func state(_ pack: Pack) -> Purchase {
        let own = products[pack.productID] ?? .unowned, complete = products[Pack.completeID] ?? .unowned
        if own == .owned || complete == .owned { return .owned }
        return own != .unowned ? own : complete
    }

    var owned: Set<Pack> { Set(Pack.allCases.filter { state($0) == .owned }) }
}

/// The App Store's side of the packs. Nothing here is stored: StoreKit keeps every purchase, and `start` reads them
/// back on each launch, on any device, family members' included.
@MainActor @Observable
final class Store {
    static let shared = Store()

    /// What StoreKit has granted, the only grant a Release build honours.
    private(set) var ledger = Ledger()
    /// The harness's states for this launch, in place of StoreKit's; always nil in Release.
    private(set) var harness: Ledger?
    @ObservationIgnored private var products: [String: Product] = [:]
    @ObservationIgnored private var updates: Task<Void, Never>?

    func state(_ pack: Pack) -> Purchase { (harness ?? ledger).state(pack) }

    /// Nil for a level in no pack.
    func access(_ level: Level) -> Pack.Access? {
        guard let pack = level.pack, let number = pack.number(of: level.id) else { return nil }
        return pack.access(number, owned: ledger.owned, harness: harness?.owned ?? [])
    }

    /// Set before `start`, which then leaves StoreKit alone for the launch.
    func pretend(_ ledger: Ledger) {
        guard !Build.release else { return }
        harness = ledger
    }

    /// Listens for purchases made or revoked elsewhere (Ask to Buy approvals, refunds, other devices, Family Sharing) and
    /// for any left unfinished, then reads what the player owns.
    func start() async {
        guard harness == nil, updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.apply(result) }
        }
        await refresh()
    }

    func refresh() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil { ledger.record(t.productID, .owned) }
        }
    }

    /// Only a transaction the App Store signed grants anything. Unverified ones are left unfinished. An old purchase's
    /// revocation can arrive after the product was bought again, so a revocation rereads the entitlements, and a live one
    /// owns it again.
    func apply(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let t) = result else { return }
        if t.revocationDate == nil {
            ledger.record(t.productID, .owned)
        } else {
            ledger.record(t.productID, .revoked)
            await refresh()
        }
        await t.finish()
    }

    func purchase(_ pack: Pack) async { await purchase(pack.productID) }

    func purchase(_ id: String) async {
        do {
            guard let product = try await product(id) else { return ledger.record(id, .failed) }
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified = result else { return ledger.record(id, .failed) }
                await apply(result)
            case .pending: ledger.record(id, .pending)
            case .userCancelled: ledger.record(id, .unowned)
            @unknown default: ledger.record(id, .failed)
            }
        } catch {
            Log.write("purchase \(id) failed: \(error)")
            ledger.record(id, .failed)
        }
    }

    /// False when the player cancels the App Store sign-in or it fails; what was already known stays.
    @discardableResult
    func restore() async -> Bool {
        do {
            try await AppStore.sync()
        } catch {
            Log.write("restore failed: \(error)")
            return false
        }
        await refresh()
        return true
    }

    /// Fetched again for an id the last fetch lacked, so a product missing once is not missing all launch.
    private func product(_ id: String) async throws -> Product? {
        if products[id] == nil {
            for p in try await Product.products(for: Pack.productIDs) { products[p.id] = p }
        }
        return products[id]
    }
}
