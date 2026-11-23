// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What the shelf sells: a pack, or the bundle (`complete`), which grants `Pack.bundled`.
enum Offer: Hashable, Sendable {
    /// The bundle's name wherever a player reads it, and the App Store's display name with it (Jack's pick, M1).
    static let bundleName = "Triptych I"

    /// A count of packs in words.
    static func countWord(_ n: Int) -> String {
        guard n >= 2, n <= 6 else { return "\(n)" }
        return [String(localized: "two", comment: "A count of packs or levels, in words"),
                String(localized: "three", comment: "A count of packs or levels, in words"),
                String(localized: "four", comment: "A count of packs or levels, in words"),
                String(localized: "five", comment: "A count of packs or levels, in words"),
                String(localized: "six", comment: "A count of packs or levels, in words")][n - 2]
    }

    case pack(Pack)
    case complete

    static let all: [Offer] = Pack.allCases.map(Offer.pack) + [.complete]

    /// The covers the dock shows. A pack goes on sale only once it has levels past its taste, and the bundle only once
    /// every pack it grants is on sale (Jack, 2026-10-26, S1); a build outside Release shows every cover, so the shop can
    /// be looked at.
    static func shelf(release: Bool = Build.release, ready: (Pack) -> Bool = { $0.levels.count > $0.taste }) -> [Offer] {
        guard release else { return all }
        let sold = Pack.sold(release: release), packs = sold.filter(ready)
        return packs.map(Offer.pack) + (Pack.bundled.allSatisfy(packs.contains) ? [.complete] : [])
    }

    /// The pack a completion's card points to: the first on the shelf the player doesn't own, other than the one just
    /// completed; none once every pack is owned.
    @MainActor static func pointer(after completed: Completion?, shelf: [Offer] = Offer.shelf(),
                                   owned: (Pack) -> Bool = { Store.shared.state($0) == .owned }) -> Pack? {
        guard let completed else { return nil }
        return unowned(except: completed.pack, shelf: shelf, owned: owned)
    }

    /// The first pack on the shelf the player doesn't own, other than `except`.
    @MainActor static func unowned(except: Pack? = nil, shelf: [Offer] = Offer.shelf(),
                                   owned: (Pack) -> Bool = { Store.shared.state($0) == .owned }) -> Pack? {
        shelf.compactMap(\.pack).first { $0 != except && !owned($0) }
    }

    /// The pack "more puzzles in the packs ›" opens, once, on the card of the free ladder's last level (Jack's call M6,
    /// round 14); none where the card already points to a pack from a completion, once it has shown, or once every pack is
    /// owned.
    @MainActor static func ladderEnd(_ level: Level, completed: Completion?, shown: Bool, shelf: [Offer] = Offer.shelf(),
                                     owned: (Pack) -> Bool = { Store.shared.state($0) == .owned }) -> Pack? {
        guard level.pack == nil, level.run == nil, level.id == Tier.allCases.last?.levels.last?.id, !shown,
              pointer(after: completed, shelf: shelf, owned: owned) == nil else { return nil }
        return unowned(shelf: shelf, owned: owned)
    }

    /// The offer a promoted purchase of product `id` buys, if this build sells it.
    static func promoted(_ id: String, release: Bool = Build.release) -> Offer? {
        all.first { $0.productID == id && ($0.pack.map { Pack.sold(release: release).contains($0) } ?? true) }
    }

    /// What the bundle saves over buying the `bundled` packs not `owned` one by one (a pending pack is unowned): nil
    /// unless it saves something and every price that takes is known (Jack's call C7, round 13).
    static func saving(amounts: [String: Decimal], owned: Set<Pack>, bundled: [Pack] = Pack.bundled) -> Decimal? {
        let left = bundled.filter { !owned.contains($0) }.map { amounts[$0.productID] }
        guard !left.isEmpty, let complete = amounts[Pack.triptychID], !left.contains(nil) else { return nil }
        let saving = left.compactMap { $0 }.reduce(0, +) - complete
        return saving > 0 ? saving : nil
    }

    /// Whether the bundle is on offer: once every price `saving` takes is in, while it saves; while none is in (loading,
    /// unreachable, or no product came back), only while none of the `bundled` packs is owned, when it holds them all
    /// for less; and with some in but not all, as when the App Store sells the packs here but not the bundle, never.
    /// The prices decide, never whether a fetch is running, so with none of its packs owned a card's fetch never moves
    /// the dock under it.
    static func offersComplete(amounts: [String: Decimal], owned: Set<Pack>, bundled: [Pack] = Pack.bundled) -> Bool {
        let left = bundled.filter { !owned.contains($0) }
        guard !left.isEmpty else { return false }
        let needed = [Pack.triptychID] + left.map(\.productID)
        if needed.allSatisfy({ amounts[$0] != nil }) { return saving(amounts: amounts, owned: owned, bundled: bundled) != nil }
        return left.count == bundled.count && needed.allSatisfy { amounts[$0] == nil }
    }

    /// Whether this build sells it.
    var sold: Bool { pack.map { Pack.sold().contains($0) } ?? true }

    /// Some of what it sells is still to come.
    var arriving: Bool { (pack.map { [$0] } ?? Pack.bundled).contains { $0.levels.count < $0.planned } }

    /// A pack's prefix, or "complete", as the harness names it and the clip's file is named.
    init?(name: String) {
        if name == "complete" { self = .complete } else if let p = Pack(rawValue: name) { self = .pack(p) } else { return nil }
    }

    var key: String {
        switch self {
        case .pack(let p): p.rawValue
        case .complete: "complete"
        }
    }

    var pack: Pack? { if case .pack(let p) = self { p } else { nil } }

    var name: String { pack?.name ?? Offer.bundleName }

    var productID: String { pack?.productID ?? Pack.triptychID }

    var pitch: String {
        switch self {
        case .pack(.firstStir): String(localized: "a story told backwards", comment: "First Stir's pitch, on its card")
        case .pack(.lens): String(localized: "some rods zoom instead of turning", comment: "Lens's pitch, on its card")
        case .pack(.escapement): String(localized: "clocks tick after every move, on a budget of ticks",
                                        comment: "Escapement's pitch, on its card")
        case .pack(.prism): String(localized: "each rod stirs only some colours", comment: "Prism's pitch, on its card")
        case .complete: String(localized: "three packs, for less", comment: "The bundle's pitch, on its card")
        }
    }

    /// What the pack assumes of the player, as its card says it.
    var assumes: String {
        switch self {
        case .pack(.firstStir): String(localized: "anyone \u{00B7} an evening, not a challenge", comment: "Who First Stir is for")
        case .pack(.lens): String(localized: "after plughole", comment: "Who Lens is for. The first tier, in lower case")
        case .pack(.escapement): String(localized: "hard \u{00B7} composed problems", comment: "Who Escapement is for")
        case .pack(.prism): String(localized: "after plughole \u{00B7} reading by colour",
                                   comment: "Who Prism is for. The first tier, in lower case")
        case .complete: String(localized: "after plughole, then harder",
                               comment: "Who the bundle is for. The first tier, in lower case")
        }
    }

    var holds: String {
        switch self {
        case .pack(.firstStir): String(localized: "\(Pack.firstStir.counted(Pack.firstStir.planned)) in five chapters",
                                       comment: "What First Stir holds. Its levels counted")
        case .pack(.lens): String(localized: "\(Pack.lens.counted(Pack.lens.planned)) in four issues",
                                  comment: "What Lens holds. Its levels counted")
        case .pack(.escapement): String(localized: "\(Pack.escapement.counted(Pack.escapement.planned)) in five chapters",
                                        comment: "What Escapement holds. Its levels counted")
        case .pack(.prism): String(localized: "\(Pack.prism.counted(Pack.prism.planned)) in five trays",
                                   comment: "What Prism holds. Its levels counted")
        case .complete: String(localized: "\(Pack.named(Pack.bundled)) \u{00B7} \(Pack.bundled.map(\.planned).reduce(0, +)) levels",
                               comment: "What the bundle holds. Its packs, then their levels")
        }
    }

    /// The dock's header once its Ask to Buy is approved.
    var yours: String { String(localized: "\(name) is yours", comment: "The dock's header once an Ask to Buy is approved") }
    /// A line under the facts, owned or not.
    var note: String? {
        self == .pack(.prism) ? String(localized: "letters for colour-blind play, in settings", comment: "Prism's card, under its facts") : nil
    }

    var free: String {
        switch self {
        case .pack(let p): String(localized: "levels 1\u{2013}\(p.taste) free, no purchase", comment: "A pack's card: its free levels")
        case .complete: String(localized: "each pack's first 3 levels", comment: "The bundle's card: what is free")
        }
    }

    var sweep: [Color] {
        switch self {
        case .pack(.firstStir): [Color(0xFFC857), Color(0xFF6FA5), Color(0x7A7CFF)]
        case .pack(.lens): [.neonCyan, .magenta, Color(0xFFE600)]
        case .pack(.escapement): [Color(0xF3EAD8), Color(0xD8402A)]
        case .pack(.prism): [Color(0xFF2A2A), Color(0x2AFF5A), Color(0x3A6BFF)]
        case .complete: [Color(0xFFC857), .neonCyan, Color(0xD8402A)]
        }
    }

    var glow: Color {
        switch self {
        case .pack(.firstStir): Color(0xFFC857)
        case .pack(.lens): .magenta
        case .pack(.escapement): Color(0xD8402A)
        case .pack(.prism): .white
        case .complete: .neonCyan
        }
    }

    /// The pack's levels; before it has any, a Debug build lists `placeholders` of the harness's stand-ins.
    func levels(placeholders: Int = 0) -> [Level] {
        guard let pack else { return [] }
        #if DEBUG
        if pack.levels.isEmpty, placeholders > 0 { return (1...placeholders).map(pack.placeholder) }
        #endif
        return pack.levels
    }

    var gradient: LinearGradient { LinearGradient(colors: sweep, startPoint: .leading, endPoint: .trailing) }
}

extension Store {
    /// The bundle is owned once its own product or every pack it grants is.
    func state(_ offer: Offer) -> Purchase {
        switch offer {
        case .pack(let p): return state(p)
        case .complete:
            let l = harness ?? ledger
            if Pack.bundled.allSatisfy({ l.state($0) == .owned }) { return .owned }
            return l.products[Pack.triptychID] ?? .unowned
        }
    }

    /// Its own product waits on Ask to Buy, so asking again re-sends that request.
    func asked(_ offer: Offer) -> Bool { (harness ?? ledger).asked(offer.productID) }

    /// The pack whose card a level shows instead of playing: one past its taste that the player doesn't own.
    func card(for level: Level) -> Pack? { access(level) == .needsCard ? level.pack : nil }

    /// A level this build may open: any outside a pack but a sandbox it withholds, and a pack's that the build sells.
    func opens(_ level: Level, release: Bool = Build.release) -> Bool {
        (!level.sandbox || Level.playsSandbox(release: release)) && access(level, release: release) != .withheld
    }
}

extension Store {
    /// A restore that finds nothing changes no state, so VoiceOver hears what it came to here.
    func restoreAndAnnounce() async {
        await restore()
        if let note = restoreNote { AccessibilityNotification.Announcement(note).post() } // loc: verbatim localized by restoreNote
    }

    /// What the last restore came to, on a card and in settings; nil before one.
    var restoreNote: String? {
        if restoring { return String(localized: "restoring\u{2026}", comment: "Restore purchases, running") }
        return switch restored {
        case .found(let packs): String(localized: "restored \(Pack.named(Pack.sold().filter(packs.contains)))",
                                       comment: "Restore purchases, done. The packs it found")
        case .nothing: String(localized: "nothing to restore on this Apple ID", comment: "Restore purchases, nothing found")
        case .failed: String(localized: "couldn't reach the App Store", comment: "Restore purchases, failed")
        case nil: nil
        }
    }
}

extension Failure {
    /// Said under the failed purchase; nil where "the purchase didn't go through" is all there is to say.
    var words: String? {
        switch self {
        case .offline: String(localized: "No connection. Try again when you're online.", comment: "A purchase failed, offline")
        case .storefront: String(localized: "Not sold in your country's App Store.", comment: "A purchase failed: not sold here")
        case .refused: String(localized: "In-app purchases are turned off on this iPhone.",
                              comment: "Purchases are barred on this phone")
        case .cancelled, .other: nil
        }
    }
}

extension Pricing {
    /// In a price's place on the buy pill while there is none.
    var words: String? {
        switch self {
        case .fetching: String(localized: "price loading", comment: "The buy pill, in the price's place while it loads")
        case .unreachable: String(localized: "App Store unreachable", comment: "The buy pill, in the price's place, no App Store")
        case .fetched: nil
        }
    }
}

extension Purchase {
    /// The dock's glyph beside a cover's name.
    var mark: String? {
        switch self {
        case .owned: "checkmark"
        case .pending: "hourglass"
        case .unowned, .failed, .revoked: nil
        }
    }

    /// The shelf's one word for a state, nil when there is nothing to say. `unshared`: revoked as a family's share
    /// ended, not a refund, as the card's status says it.
    func tag(unshared: Bool = false) -> (word: String, colour: Color)? {
        switch self {
        case .unowned: nil
        case .owned: (String(localized: "owned", comment: "A pack's state"), .lime)
        case .pending: (String(localized: "waiting for approval", comment: "A pack's state: an Ask to Buy sent"), .amber)
        case .failed: (String(localized: "purchase failed", comment: "A pack's state"), .magenta)
        case .revoked: (unshared ? String(localized: "no longer shared with you", comment: "A pack's state: a family's share ended")
                        : String(localized: "no longer on this Apple ID", comment: "A pack's state: refunded"), Color.text2)
        }
    }
}

/// What each pack's cover has shown: whether its card has opened since the pack fit the player, and how many levels it
/// had then, so the cover says "new" once for each (Jack's call C6, round 13).
enum Marks {
    /// False for a harnessed launch, whose cards' openings last only that launch.
    @MainActor static var stored = true

    static func fitKey(_ pack: Pack) -> String { "shelf.fit.\(pack.rawValue)" }
    static func levelsKey(_ pack: Pack) -> String { "shelf.levels.\(pack.rawValue)" }

    /// It fits and its card hasn't opened since, or an update added levels since it last opened.
    static func new(_ pack: Pack, fits: Bool, in defaults: UserDefaults = .standard) -> Bool {
        let seen = defaults.integer(forKey: levelsKey(pack))
        return (fits && !defaults.bool(forKey: fitKey(pack))) || (seen > 0 && pack.levels.count > seen)
    }

    /// Its card has opened.
    @MainActor static func seen(_ pack: Pack, fits: Bool, store: Bool = stored, in defaults: UserDefaults = .standard) {
        var marks: [String: Any] = [levelsKey(pack): pack.levels.count]
        if fits { marks[fitKey(pack)] = true }
        if store { for (key, value) in marks { defaults.set(value, forKey: key) } } else { defaults.register(defaults: marks) }
    }

    /// The line under a cover's name: "new", else how many of an unowned pack's free levels are solved, else nothing.
    static func line(_ pack: Pack, owned: Bool, fits: Bool, played: Int?) -> (words: String, spoken: String, new: Bool)? {
        if new(pack, fits: fits) {
            let new = String(localized: "new", comment: "Under a pack's cover, until its card opens")
            return (new, new, true)
        }
        guard !owned, let played else { return nil }
        return (String(localized: "\(played)/\(pack.taste) free", comment: "Under a pack's cover: its free levels solved, of all"),
                String(localized: "\(played) of \(pack.taste) free levels solved",
                       comment: "VoiceOver: a pack's cover. Its free levels solved, of all"), false)
    }
}

/// The rules a pack's card and the dock follow, apart from how either is drawn.
enum Shop {
    static var menu: String { String(localized: "menu", comment: "A pack's card: its back button, to the menu") }

    /// The way out's words and VoiceOver's. Beside the list the menu is already in sight, so going back to it closes
    /// the card (Jack's call d4-menuback = B, round 16); back to Triptych I's card reads as ever.
    static func back(to: String, beside: Bool) -> (text: String, spoken: String) {
        beside && to == menu
            ? ("\u{2715} " + String(localized: "close", comment: "A pack's card beside the menu: closes it"),
               String(localized: "Close", comment: "VoiceOver: a pack's card beside the menu, its close button"))
            : ("\u{2039} \(to)", String(localized: "Back", comment: "VoiceOver: a pack's card, its back button"))
    }

    /// A purchase landing on the card: owned now, read after the launch's first read of the entitlements had finished,
    /// so an owner's card opened in that read's window never chimes.
    static func lands(_ old: Purchase, _ new: Purchase, ready: Bool) -> Bool { ready && old != .owned && new == .owned }

    /// Where an owner picks up: the first level without a best, then the first not at par; none once all are at par.
    static func pickUp(_ levels: [Level], best: (String) -> Best? = Best.load) -> Level? {
        levels.first { best($0.id) == nil } ?? levels.first { best($0.id)?.over != 0 }
    }

    /// The taste's first level without a best, or, once all have one, its first to replay.
    static func taste(_ levels: [Level], best: (String) -> Best? = Best.load) -> (level: Level, replay: Bool)? {
        let free = levels.prefix(levels.first?.pack?.taste ?? 0)
        if let level = free.first(where: { best($0.id) == nil }) { return (level, false) }
        return free.first.map { ($0, true) }
    }

    /// Over buying, when a level past the taste opened the card of a pack never owned: that the free levels are
    /// played, once every one has a best, else, for a player who skipped ahead (a row opens any free level), that they
    /// are free (Jack's call C1A = B, round 16). A refunded owner has the revocation's line instead.
    static func arrival(_ offer: Offer, _ levels: [Level], state: Purchase,
                        best: (String) -> Best? = Best.load) -> String? {
        guard let pack = offer.pack, levels.count > pack.taste, state != .owned, state != .revoked else { return nil }
        let free = Offer.countWord(pack.taste)
        let more = String(localized: "\(levels.count - pack.taste) more in \(pack.name).",
                          comment: "A pack's card, over buying: the levels past the free ones. How many, then the pack")
        return taste(levels, best: best)?.replay == true
            ? String(localized: "You've played the free \(free). \(more)",
                     comment: "A pack's card, over buying. The free levels counted in words, then the levels past them")
            : String(localized: "The first \(free) are free. \(more)",
                     comment: "A pack's card, over buying. The free levels counted in words, then the levels past them")
    }

    /// Play, until a level past the taste has been solved: then the owner continues.
    static func continues(_ levels: [Level], best: (String) -> Best? = Best.load) -> Bool {
        levels.contains { level in
            best(level.id) != nil && (level.pack.flatMap { $0.number(of: level.id) } ?? 0) > (level.pack?.taste ?? 0)
        }
    }

    /// The dock waits for plughole 09 (Jack's call C5, round 13). A pack owned or asked for keeps it after a reinstall
    /// that lost the bests.
    @MainActor static func shown(best: (String) -> Best? = Best.load, unlocked: Bool = Best.unlocked,
                      state: (Pack) -> Purchase = { Store.shared.state($0) }) -> Bool {
        best(Level.plughole[8].id) != nil || unlocked || Pack.sold().contains { ![.unowned, .failed].contains(state($0)) }
    }

    /// The approval the header says now: none while a card or the settings covers the dock, or before it shows.
    static func saying(_ approved: Offer?, covered: Bool, shelved: Bool) -> Offer? {
        covered || !shelved ? nil : approved
    }
}

// MARK: - The slope's rules (docs/slope.md, 8)

extension Shop {
    /// The slope's way out of a hollow: up, to the menu or to Triptych I's hollow; beside the menu it closes, as
    /// `back` does.
    static func rise(to: String, beside: Bool) -> (text: String, spoken: String) {
        let back = back(to: to, beside: beside)
        return (beside && to == menu ? back.text : "\u{2191} \(to)", back.spoken)
    }

    /// A line under the pack's stone: its words, the colour that carries its meaning, if one does, and whether the
    /// pending light leads it. `quiet` is an explanation, at the weaker ink.
    struct Line: Equatable {
        enum Signal { case lime, amber, magenta }
        var words: String
        var signal: Signal?
        var light = false
        var quiet = false
    }

    /// The ledge inside a hollow (8.3): the stone, its words, VoiceOver's, and what stands under it. No `stone` where
    /// nothing can be bought here; `live` where a tap buys or asks again.
    struct Ledge: Equatable {
        var stone: StoneState?
        var live = false
        var label = ""
        var spoken = ""
        /// The App Store's price, written after "buy".
        var price: String?
        var under: [Line] = []
    }

    /// What the store's state puts on a hollow's ledge, for an offer not owned: every row of 8.3's table but the
    /// owner's, whose stone plays (`plays`). `asked`: the offer's own request waits on Ask to Buy, not Triptych I's
    /// alone. `failure`: why the product's last attempt failed.
    static func ledge(_ offer: Offer, state: Purchase, ready: Bool, buying: Bool, asked: Bool, unshared: Bool, canPay: Bool,
                      price: String?, pricing: Pricing, failure: Failure?) -> Ledge {
        guard ready else {
            let checking = String(localized: "checking purchases\u{2026}")
            return Ledge(stone: .pending, label: checking, spoken: checking)
        }
        guard canPay else { return Ledge(under: [Line(words: Failure.refused.words ?? "")]) }
        if state == .failed, failure == .storefront { return Ledge(under: [Line(words: Failure.storefront.words ?? "")]) }
        let unreachable = price == nil && pricing == .unreachable
        var ledge = Ledge(stone: price == nil ? .lit : .next, live: true, price: price)
        if price == nil, let words = pricing.words { ledge.under.append(Line(words: words, quiet: true)) }
        switch state {
        case .failed:
            ledge.label = String(localized: "try again", comment: "The buy pill, a purchase failed")
            ledge.spoken = String(localized: "Try Again \(offer.name)", comment: "VoiceOver: the buy pill, a purchase failed. The pack")
            ledge.under = [Line(words: String(localized: "the purchase didn't go through", comment: "A pack's card: its purchase failed"),
                                signal: .magenta)] + (failure?.words.map { [Line(words: $0, quiet: true)] } ?? []) + (unreachable ? ledge.under : [])
        case .revoked:
            ledge.label = unshared ? String(localized: "buy", comment: "The buy pill") : String(localized: "buy again", comment: "The buy pill, refunded")
            ledge.spoken = unshared ? String(localized: "Buy \(offer.name)", comment: "VoiceOver: the buy pill. The pack")
                : String(localized: "Buy Again \(offer.name)", comment: "VoiceOver: the buy pill, refunded. The pack")
            ledge.under.insert(Line(words: unshared
                ? String(localized: "\(offer.name) is no longer shared with you \u{00B7} your progress is kept",
                         comment: "A pack's card: a family's share ended. The pack")
                : String(localized: "\(offer.name) isn't on this Apple ID any more \u{00B7} your progress is kept",
                         comment: "A pack's card: refunded. The pack"), quiet: true), at: 0)
        case .pending where asked:
            ledge.stone = .lit
            ledge.label = String(localized: "asked", comment: "The buy pill, an Ask to Buy sent: tapped, sends it again")
            ledge.spoken = String(localized: "Ask again for \(offer.name)", comment: "VoiceOver: the buy pill, an Ask to Buy sent. The pack")
            ledge.under = [Line(words: String(localized: "waiting for approval", comment: "A pack's card: its Ask to Buy sent"),
                                signal: .amber, light: true),
                           Line(words: failure?.words
                                ?? String(localized: "Ask to Buy: the pack opens here once it's approved \u{00B7} tap asked to send it again.",
                                          comment: "A pack's card: its Ask to Buy sent. Asked is the buy pill's word"))]
        case .pending:
            // Waiting on Triptych I's request alone: the pack's own stone still buys it alone.
            ledge.label = String(localized: "buy", comment: "The buy pill")
            ledge.spoken = String(localized: "Buy \(offer.name)", comment: "VoiceOver: the buy pill. The pack")
            ledge.under.insert(contentsOf: [
                Line(words: String(localized: "\(Offer.bundleName) is waiting for approval", comment: "A pack's card: the bundle's Ask to Buy sent"),
                     signal: .amber, light: true),
                Line(words: failure?.words
                     ?? String(localized: "Ask to Buy: \(offer.name) opens here once \(Offer.bundleName) is approved.",
                               comment: "A pack's card: the bundle's Ask to Buy sent. The pack, then the bundle"))], at: 0)
        case .unowned, .owned:
            ledge.label = String(localized: "buy", comment: "The buy pill")
            ledge.spoken = String(localized: "Buy \(offer.name)", comment: "VoiceOver: the buy pill. The pack")
        }
        // The price is written after "buy" alone; every other label is its word, and VoiceOver's value still says it.
        if state == .failed || state == .revoked && !unshared || state == .pending && asked || buying { ledge.price = nil }
        if buying {
            ledge.stone = .pending
            ledge.live = false
            ledge.label = String(localized: "buying\u{2026}", comment: "The buy pill, a purchase running")
            ledge.spoken = String(localized: "Buying\u{2026} \(offer.name)", comment: "VoiceOver: the buy pill, a purchase running. The pack")
        }
        return ledge
    }

    /// The line under an owner's stone.
    static func owned(_ offer: Offer) -> Line {
        Line(words: offer.pack == nil
             ? String(localized: "\u{2713} owned \u{00B7} all \(Offer.countWord(Pack.bundled.count)) packs open",
                      comment: "The bundle's card, owned. Its packs, counted in words")
             : String(localized: "\u{2713} owned \u{00B7} every level open", comment: "A pack's card, owned"), signal: .lime)
    }

    /// An owner's stone: the level it plays, its words and VoiceOver's. The bundle, with no levels of its own, plays
    /// on in the first of its packs with a level left. Nil once every level is at par.
    static func plays(_ offer: Offer, _ levels: [Level], best: (String) -> Best? = Best.load)
        -> (level: Level, label: String, spoken: String)? {
        let pack = offer.pack == nil ? Pack.bundled.first { pickUp($0.levels, best: best) != nil } : nil
        guard let level = pack.flatMap({ pickUp($0.levels, best: best) }) ?? (offer.pack == nil ? nil : pickUp(levels, best: best)) else { return nil }
        let continues = continues(pack?.levels ?? levels, best: best), name = pack?.name ?? offer.name
        let label = switch (continues, pack) {
        case (true, let pack?): String(localized: "continue \(pack.name) \(level.label) \u{203A}",
                                       comment: "The bundle's card, owned: plays on. The pack, then the level number")
        case (true, nil): String(localized: "continue \(level.label) \u{203A}", comment: "An owned pack's card: plays on. The level number")
        case (false, let pack?): String(localized: "play \(pack.name) \(level.label) \u{203A}",
                                        comment: "The bundle's card, owned: plays. The pack, then the level number")
        case (false, nil): String(localized: "play \(level.label) \u{203A}", comment: "An owned pack's card: plays. The level number")
        }
        return (level, label, continues
            ? String(localized: "Continue \(name), level \(level.label)", comment: "VoiceOver: an owned card's play button. The pack, the level number")
            : String(localized: "Play \(name), level \(level.label)", comment: "VoiceOver: an owned card's play button. The pack, the level number"))
    }

    /// A pack's levels at par, of all, as its floor and each chapter count them; Escapement, with no par, counts its
    /// solves.
    static func progress(_ levels: [Level], pack: Pack?, best: (String) -> Best? = Best.load) -> String {
        let par = levels.filter { best($0.id)?.over == 0 }.count
        return pack == .escapement
            ? String(localized: "\(par)/\(levels.count) solved", comment: "Escapement's chapter. Levels solved, of all")
            : String(localized: "\(par)/\(levels.count) at par", comment: "A pack's chapter. Levels at par, of all")
    }

    /// A pack's levels by chapter, in order; one nameless run where it has no chapters.
    static func chapters(_ levels: [Level]) -> [(name: String?, levels: [Level])] {
        levels.reduce(into: []) { runs, level in
            if let last = runs.last, last.name == level.chapter { runs[runs.count - 1].levels.append(level) }
            else { runs.append((level.chapter, [level])) }
        }
    }

    /// Where a pack's own slope lands (8.4): an owner's next level, else the first free level without a best, else
    /// its first ledge.
    static func landing(_ levels: [Level], owned: Bool, best: (String) -> Best? = Best.load) -> Level? {
        (owned ? pickUp(levels, best: best) : taste(levels, best: best).flatMap { $0.replay ? nil : $0.level }) ?? levels.first
    }
}
