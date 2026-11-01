// Copyright © 2026 Jack Lusher. All rights reserved.

import Observation
import StoreKit

/// Where a player stands with one product.
enum Purchase: String, CaseIterable, Sendable {
    /// `failed` is the last attempt's error; `revoked` a refund, or a family member's purchase no longer shared.
    case unowned, owned, pending, failed, revoked
}

/// What the card says of a failed purchase.
enum Failure: String, Sendable {
    /// `refused`: purchases are turned off on the device. `cancelled` fails nothing, and is only a restore's.
    case offline, storefront, refused, cancelled, other

    init(_ error: Error) {
        switch error {
        case StoreKitError.networkError, is URLError: self = .offline
        case StoreKitError.notAvailableInStorefront: self = .storefront
        case Product.PurchaseError.purchaseNotAllowed: self = .refused
        case StoreKitError.userCancelled: self = .cancelled
        default: self = .other
        }
    }
}

/// Where the prices stand: `fetched` can still lack a product the App Store didn't return.
enum Pricing: Sendable { case fetching, fetched, unreachable }

enum Restored: Equatable, Sendable { case found(Set<Pack>), nothing, failed }

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
        let own = products[pack.productID] ?? .unowned
        let complete = Pack.sold().contains(pack) ? products[Pack.completeID] ?? .unowned : .unowned
        if own == .owned || complete == .owned { return .owned }
        // Complete's failed attempt was made on Complete's card, and says nothing about this pack.
        return own != .unowned ? own : complete == .failed ? .unowned : complete
    }

    var owned: Set<Pack> { Set(Pack.sold().filter { state($0) == .owned }) }

    /// A failure belongs to the attempt, so it goes when the card that showed it closes.
    mutating func forgetFailures() {
        for (id, state) in products where state == .failed { products[id] = .unowned }
    }
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
    /// Each product's price as the App Store gives it, for the player's storefront; missing until it is fetched.
    private(set) var prices: [String: String] = [:]
    private(set) var pricing = Pricing.fetching
    /// Why each product's last attempt failed, while the ledger holds it as failed.
    private(set) var failures: [String: Failure] = [:]
    /// The last restore's outcome, said alike by the cards and settings; nil before one, or after a cancelled sign-in.
    private(set) var restored: Restored?
    private(set) var restoring = false
    @ObservationIgnored private var payments: Bool?
    @ObservationIgnored private var products: [String: Product] = [:]
    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var attempt = 0

    func state(_ pack: Pack) -> Purchase { (harness ?? ledger).state(pack) }

    /// Nil for a level in no pack. A pack's level whose id names no number of that pack needs the card.
    func access(_ level: Level) -> Pack.Access? {
        guard let pack = level.pack else { return nil }
        guard let number = pack.number(of: level.id) else { return .needsCard }
        return pack.access(number, owned: ledger.owned, harness: harness?.owned ?? [])
    }

    func price(_ id: String) -> String? { prices[id] }

    /// Screen Time, or a child's account without Ask to Buy, can turn purchases off; read afresh as a card draws.
    var canPay: Bool { payments ?? AppStore.canMakePayments }

    /// Forgets every failed attempt, and any still running, so a card never opens on an error it didn't see happen.
    func forgetFailures() {
        attempt += 1
        ledger.forgetFailures()
        failures = [:]
        restored = nil
    }

    /// Set before `start`, which then leaves StoreKit alone for the launch.
    func pretend(_ ledger: Ledger, prices: [String: String] = [:], pricing: Pricing = .fetching,
                 failure: Failure = .other, canPay: Bool = true, restored: Restored? = nil) {
        guard !Build.release else { return }
        harness = ledger
        self.prices = prices
        self.pricing = pricing
        failures = ledger.products.filter { $0.value == .failed }.mapValues { _ in failure }
        payments = canPay
        self.restored = restored
    }

    /// Listens for purchases made or revoked elsewhere (Ask to Buy approvals, refunds, other devices, Family Sharing) and
    /// for any left unfinished, then reads what the player owns.
    func start() async {
        guard harness == nil, updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.apply(result) }
        }
        await refresh()
        await fetchPrices()
    }

    /// A failed fetch leaves the prices missing, and the card asks again when it opens.
    func fetchPrices() async {
        guard harness == nil, Pack.productIDs.contains(where: { prices[$0] == nil }) else { return }
        pricing = .fetching
        do {
            try await fetch()
            pricing = .fetched
        } catch {
            Log.write("products failed: \(error)")
            pricing = .unreachable
        }
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
        let started = attempt
        failures[id] = nil
        func failed(_ why: String, _ failure: Failure = .other) {
            Log.write("purchase \(id) failed: \(why)\(attempt == started ? "" : ", its card closed")")
            guard attempt == started else { return }
            ledger.record(id, .failed)
            if ledger.products[id] == .failed { failures[id] = failure }
        }
        do {
            guard let product = try await product(id) else { return failed("no such product") }
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let t) = result else { return failed("unverified") }
                // Not in `apply`, which also sees a reinstall's restore: only a purchase made here counts.
                if t.revocationDate == nil { Analytics.shared.purchased(t.productID) }
                await apply(result)
            case .pending: ledger.record(id, .pending)
            case .userCancelled: ledger.record(id, .unowned)
            @unknown default: failed("unknown result")
            }
        } catch {
            failed("\(error)", Failure(error))
        }
    }

    /// What a sync found that wasn't owned before it; nil when the player cancels the App Store sign-in. A failed sync
    /// keeps what was already known.
    @discardableResult
    func restore() async -> Restored? {
        let before = ledger.owned
        restoring = true
        defer { restoring = false }
        do {
            try await AppStore.sync()
        } catch {
            Log.write("restore failed: \(error)")
            restored = Failure(error) == .cancelled ? nil : .failed
            return restored
        }
        await refresh()
        let found = ledger.owned.subtracting(before)
        restored = found.isEmpty ? .nothing : .found(found)
        return restored
    }

    /// Fetched again for an id the last fetch lacked, so a product missing once is not missing all launch.
    private func product(_ id: String) async throws -> Product? {
        if products[id] == nil { try await fetch() }
        return products[id]
    }

    private func fetch() async throws {
        for p in try await Product.products(for: Pack.productIDs) {
            products[p.id] = p
            prices[p.id] = p.displayPrice
        }
    }
}
