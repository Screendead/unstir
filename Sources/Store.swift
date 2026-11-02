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
    /// The products whose revocation was a family member's purchase no longer shared, not a refund.
    private(set) var unshared: Set<String> = []

    /// Once owned, only a revocation takes a product away: a later attempt that fails, waits or is cancelled is not one.
    /// A cancelled or failed second ask leaves an Ask to Buy still waiting on its parent.
    mutating func record(_ id: String, _ state: Purchase, shared: Bool = false) {
        if products[id] == .owned && state != .revoked { return }
        if products[id] == .pending && (state == .unowned || state == .failed) { return }
        products[id] = state
        if state == .revoked && shared { unshared.insert(id) } else { unshared.remove(id) }
    }

    /// The product itself waits on Ask to Buy, not only Complete that would grant it.
    func asked(_ id: String) -> Bool { products[id] == .pending }

    /// Revoked because the family stopped sharing it, through its own product or Complete.
    func unshared(_ pack: Pack) -> Bool {
        guard state(pack) == .revoked else { return false }
        return unshared.contains(products[pack.productID] == .revoked ? pack.productID : Pack.completeID)
    }

    /// Owned through its own product or Complete; otherwise its own product's state, else Complete's.
    func state(_ pack: Pack) -> Purchase {
        let own = products[pack.productID] ?? .unowned
        let complete = Pack.bundled.contains(pack) ? products[Pack.completeID] ?? .unowned : .unowned
        if own == .owned || complete == .owned { return .owned }
        // Complete's failed attempt was made on Complete's card, and says nothing about this pack.
        return own != .unowned ? own : complete == .failed ? .unowned : complete
    }

    var owned: Set<Pack> { Set(Pack.sold().filter { state($0) == .owned }) }

    /// Any purchase, a pack or the bundle.
    var bought: Bool { !owned.isEmpty }

    /// A failure belongs to the attempt, so it goes when the card that showed it closes.
    mutating func forgetFailures() {
        for (id, state) in products where state == .failed { products[id] = .unowned }
    }
}

extension Ledger {
    /// Of the products asked for on Ask to Buy, those now owned, whose approval is still to be said, and those revoked,
    /// forgotten unsaid. A declined request sends nothing, so it stays asked, and says nothing unless it is owned.
    func answers(to asked: Set<String>) -> (approved: Set<String>, revoked: Set<String>) {
        (asked.filter { products[$0] == .owned }, asked.filter { products[$0] == .revoked })
    }
}

/// The Ask to Buy requests made on this device, remembered only to say each approval once (Jack's call C21, round 13):
/// an approval arrives as any purchase made elsewhere does, so only this says it was asked for here.
enum Asked {
    static func key(_ id: String) -> String { "asked.\(id)" }
    static var all: Set<String> { Set(Pack.productIDs.filter { UserDefaults.standard.bool(forKey: key($0)) }) }
    static func add(_ id: String) { UserDefaults.standard.set(true, forKey: key(id)) }
    static func remove(_ id: String) { UserDefaults.standard.removeObject(forKey: key(id)) }
}

/// The App Store's side of the packs. Nothing that grants is stored: StoreKit keeps every purchase, and `start` reads
/// them back on each launch, on any device, family members' included; `Asked` only remembers a request to say its
/// approval.
@MainActor @Observable
final class Store {
    static let shared = Store()

    /// What StoreKit has granted, the only grant a Release build honours.
    private(set) var ledger = Ledger()
    /// The harness's states for this launch, in place of StoreKit's; always nil in Release.
    private(set) var harness: Ledger?
    /// Each product's price as the App Store gives it, for the player's storefront; missing until it is fetched.
    private(set) var prices: [String: String] = [:]
    /// Each price as a number, and the storefront's style to write one in, for Complete's saving.
    private(set) var amounts: [String: Decimal] = [:]
    @ObservationIgnored private var styles: [String: Decimal.FormatStyle.Currency] = [:]
    private(set) var pricing = Pricing.fetching
    /// Why each product's last attempt failed, while the ledger holds it as failed, or as pending after a failed ask again.
    private(set) var failures: [String: Failure] = [:]
    /// The last restore's outcome, said alike by the cards and settings; nil before one, or after a cancelled sign-in.
    private(set) var restored: Restored?
    private(set) var restoring = false
    /// Offers whose Ask to Buy approval is still to be said: by the landing on the offer's own card if it is up, else by
    /// the dock.
    private(set) var approved: [Offer] = []
    @ObservationIgnored private var payments: Bool?
    /// The launch's first read of the entitlements has finished, so a pack the player owns reads as owned.
    private(set) var ready = false
    /// A purchase, an approval or a restore landed on a card this launch, so the rating request keeps away.
    @ObservationIgnored var landed = false
    /// The offer a purchase started on the App Store's product page is buying (a promoted purchase): `RootView` opens its
    /// card, and the card buys it as its own buy does, which takes it.
    var promoted: Offer?
    @ObservationIgnored private var first: Task<Void, Never>?
    @ObservationIgnored private var products: [String: Product] = [:]
    @ObservationIgnored private var updates: Task<Void, Never>?
    @ObservationIgnored private var intents: Task<Void, Never>?
    @ObservationIgnored private var attempt = 0

    func state(_ pack: Pack) -> Purchase { (harness ?? ledger).state(pack) }

    func unshared(_ pack: Pack) -> Bool { (harness ?? ledger).unshared(pack) }

    /// The player owns a pack, by a purchase of their own, Complete or a family's share: what the supporter mark and the
    /// daily archive both open on.
    var bought: Bool { (harness ?? ledger).bought }

    /// Nil for a level in no pack. A pack's level whose id names no number of that pack needs the card.
    func access(_ level: Level) -> Pack.Access? {
        guard let pack = level.pack else { return nil }
        guard let number = pack.number(of: level.id) else { return .needsCard }
        return pack.access(number, owned: ledger.owned, harness: harness?.owned ?? [])
    }

    func price(_ id: String) -> String? { prices[id] }

    /// What the bundle saves on the packs it grants left unowned, in its own currency; nil while it saves nothing, or
    /// before every price it needs is in. The bundle owned owns all it grants, so it saves nothing.
    var saving: String? {
        guard let s = Offer.saving(amounts: amounts, owned: (harness ?? ledger).owned) else { return nil }
        return styles[Pack.completeID].map { s.formatted($0) }
    }

    /// Complete is on offer, on the dock and as a card to go back to: while it saves, or, while the prices are still
    /// loading, while none of its packs is owned, when it holds them for less, so a launch's dock keeps its cover.
    var offersComplete: Bool {
        if saving != nil { return true }
        return pricing == .fetching && amounts[Pack.completeID] == nil && Pack.bundled.allSatisfy { state($0) != .owned }
    }

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
    func pretend(_ ledger: Ledger, prices: [String: String] = [:], amounts: [String: Decimal] = [:],
                 pricing: Pricing = .fetching, failure: Failure = .other, canPay: Bool = true, restored: Restored? = nil,
                 approved: [Offer] = []) {
        guard !Build.release else { return }
        harness = ledger
        self.approved = approved
        self.prices = prices
        self.amounts = amounts
        styles = amounts.mapValues { _ in .currency(code: "USD").locale(Locale(identifier: "en_US")) }
        self.pricing = pricing
        failures = ledger.products.filter { $0.value == .failed || $0.value == .pending }.mapValues { _ in failure }
        payments = canPay
        self.restored = restored
        ready = true
    }

    /// UNSTIR_LANDS: a purchase landing in the harness's states, as an approval or a restore would.
    func land(_ id: String) { harness?.record(id, .owned) }

    /// A purchase the App Store's product page started, for an offer this build sells. Its product is kept, so the card's
    /// buy needs no fetch.
    func promote(_ id: String, product: Product? = nil) {
        guard let offer = Offer.promoted(id) else { return Log.write("promoted \(id): not sold here") }
        Log.write("promoted \(offer.key)")
        if let product { products[id] = product }
        promoted = offer
    }

    /// An approval has been said, so it is never said again.
    func said(_ offer: Offer) {
        guard let i = approved.firstIndex(of: offer) else { return }
        approved.remove(at: i)
        if harness == nil { Asked.remove(offer.productID) }
    }

    /// Returns once the first read has finished, or at once before `start`.
    func settled() async { await first?.value }

    /// Listens for purchases made or revoked elsewhere (Ask to Buy approvals, refunds, other devices, Family Sharing) and
    /// for any left unfinished, then reads what the player owns.
    func start() async {
        guard harness == nil, updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates { await self?.apply(result) }
        }
        intents = Task { [weak self] in
            for await intent in PurchaseIntent.intents { self?.promote(intent.product.id, product: intent.product) }
        }
        let read = Task {
            await refresh()
            ready = true
        }
        first = read
        await read.value
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
            Log.write("products failed: \(Self.described(error))")
            pricing = .unreachable
        }
    }

    func refresh() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.revocationDate == nil { ledger.record(t.productID, .owned) }
        }
        answer()
    }

    /// An approval granted while the app was shut shows only as owned on the launch's read, so both reads come here.
    private func answer() {
        let (yes, no) = ledger.answers(to: Asked.all)
        for id in no { Asked.remove(id) }
        for offer in Offer.all where yes.contains(offer.productID) && !approved.contains(offer) { approved.append(offer) }
    }

    /// Only a transaction the App Store signed grants anything. Unverified ones are left unfinished. An old purchase's
    /// revocation can arrive after the product was bought again, so a revocation rereads the entitlements, and a live one
    /// owns it again.
    func apply(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let t) = result else { return }
        if t.revocationDate == nil {
            ledger.record(t.productID, .owned)
            answer()
        } else {
            ledger.record(t.productID, .revoked, shared: t.ownershipType == .familyShared)
            await refresh()
        }
        await t.finish()
    }

    func purchase(_ pack: Pack) async { await purchase(pack.productID) }

    func purchase(_ id: String) async {
        // The harness's states stand in for StoreKit's, so its purchase lands in them.
        if harness != nil { return land(id) }
        let started = attempt
        failures[id] = nil
        func failed(_ why: String, _ failure: Failure = .other) {
            Log.write("purchase \(id) failed: \(why)\(attempt == started ? "" : ", its card closed")")
            guard attempt == started else { return }
            ledger.record(id, .failed)
            if ledger.products[id] == .failed || ledger.products[id] == .pending { failures[id] = failure }
        }
        do {
            guard let product = try await product(id) else { return failed("no such product") }
            switch try await product.purchase() {
            case .success(let result):
                guard case .verified(let t) = result else { return failed("unverified") }
                // Not in `apply`, which also sees a reinstall's restore: only a purchase made here counts.
                if t.revocationDate == nil { Analytics.shared.purchased(t.productID) }
                await apply(result)
            case .pending:
                ledger.record(id, .pending)
                Asked.add(id)
            case .userCancelled: ledger.record(id, .unowned)
            @unknown default: failed("unknown result")
            }
        } catch {
            failed(Self.described(error), Failure(error))
        }
    }

    /// An error's type and message, never the error whole: the log can leave the phone, and an error's own description
    /// carries everything it wraps.
    private static func described(_ error: Error) -> String {
        "\(type(of: error)): \(error.localizedDescription)"
    }

    /// What a sync found that wasn't owned before it; nil when the player cancels the App Store sign-in. A failed sync
    /// keeps what was already known. Said only on the card it was asked from, as a purchase's failure is.
    @discardableResult
    func restore() async -> Restored? {
        let before = ledger.owned, started = attempt
        restoring = true
        defer { restoring = false }
        func said(_ outcome: Restored?) -> Restored? {
            if attempt == started { restored = outcome }
            return outcome
        }
        do {
            try await AppStore.sync()
        } catch {
            Log.write("restore failed: \(Self.described(error))")
            return said(Failure(error) == .cancelled ? nil : .failed)
        }
        await refresh()
        let found = ledger.owned.subtracting(before)
        return said(found.isEmpty ? .nothing : .found(found))
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
            amounts[p.id] = p.price
            styles[p.id] = p.priceFormatStyle
        }
    }
}
