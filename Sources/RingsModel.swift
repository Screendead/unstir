// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// What the rings show (docs/rings.md), read once on the main actor at a rest and handed whole to the layers and
/// the bake: nothing in it is read again while the menu moves.
struct RingsModel: Equatable, Sendable {
    /// A bead's four looks.
    enum Bead: Hashable, Sendable { case dull, solved, par, next }

    struct Spot: Equatable, Sendable {
        let level: Level
        let number: String
        let name: String
        let bead: Bead
        /// What a tap says in place of opening it; nil where it opens.
        let shut: String?
        /// The middle's line once the bead is picked.
        let facts: String
    }

    struct Ring: Equatable, Sendable {
        let tier: Tier
        let word: String
        let open: Bool
        /// "14/27 · 11 at par", or what opens a shut tier.
        let under: String
        let spots: [Spot]
        /// The spot the middle names and plays: the first level without a best, else the first short of par, else
        /// the first. Nil on a shut tier.
        let way: Int?
    }

    struct Today: Equatable, Sendable {
        let level: Level
        let title: String
        let under: String?
    }

    struct Cover: Equatable, Sendable {
        let offer: Offer
        let pack: Pack
        let name: String
        let line: String?
        /// The line is the pack's own news ("new", "owned"), set in its light.
        let lit: Bool
    }

    let rings: [Ring]
    /// Nil until the daily shows (`MenuView.lead`, Jack's call C4).
    let daily: Today?
    /// Empty until the packs show (`PackDock.shown`, Jack's call C5) and the store has settled.
    let covers: [Cover]
    let packsLine: String?

    @MainActor init(today: Date) {
        let unlocked = Best.unlocked
        rings = Tier.allCases.map { tier in
            let open = tier.isOpen(), levels = tier.levels, bests = levels.map { Best.load($0.id) }
            let frontier = open ? bests.firstIndex { $0 == nil } : nil
            let spots = levels.indices.map { i -> Spot in
                let level = levels[i], best = bests[i]
                let reached = unlocked || i == 0 || bests[i - 1] != nil
                let shut: String? = !open ? tier.below.map {
                    String(localized: "solve every \($0.word) level to open", comment: "A shut tier's row, tapped. The tier below")
                } : reached ? nil : String(localized: "solve \(levels[i - 1].label) to open",
                                           comment: "A shut row, tapped. The level number before it")
                let facts = best.map {
                    String(localized: "solved in \(level.par + $0.over) \u{00B7} par \(level.par)",
                           comment: "The rings' middle, a solved level picked. Its best in moves, then its par")
                } ?? String(localized: "par \(level.par)", comment: "The rings' middle, an unsolved level picked. Its par")
                let bead: Bead = !open ? .dull : i == frontier ? .next : best.map { $0.over == 0 ? .par : .solved } ?? .dull
                return Spot(level: level, number: level.label, name: level.title, bead: bead, shut: shut, facts: facts)
            }
            let solved = bests.filter { $0 != nil }.count, par = bests.filter { $0?.over == 0 }.count
            let under = open
                ? String(localized: "\(solved)/\(levels.count) \u{00B7} \(par) at par",
                         comment: "The rings' middle, under a tier's name. Levels solved, of all, then those at par")
                : tier.below.map {
                    String(localized: "opens with every \($0.word) level solved", comment: "A shut tier's gate. The tier below")
                } ?? ""
            let way = !open || levels.isEmpty ? nil : frontier ?? bests.firstIndex { ($0?.over ?? 0) > 0 } ?? 0
            return Ring(tier: tier, word: tier.word, open: open, under: under, spots: spots, way: way)
        }
        if MenuView.lead(unlocked: unlocked).modes {
            let level = Level.daily(today)
            daily = Today(level: level, title: level.title, under: MenuView.dailyLines(level, run: Daily.run(today: today)).under)
        } else {
            daily = nil
        }
        let store = Store.shared
        if PackDock.shown(), store.shelved {
            covers = Offer.shelf().compactMap { offer in
                // Each pack that ships, as each has its cover; the bundle is a card's to offer.
                guard let pack = offer.pack, pack.ships else { return nil }
                let state = store.state(offer)
                let line = Marks.line(pack, owned: state == .owned || !store.ready, fits: pack.fits(), played: pack.tastePlayed())
                // A glyph beside the word, so owned reads without its colour.
                let tag = store.ready ? state.tag(unshared: store.unshared(pack)).map { state == .owned ? $0.word + " \u{2713}" : $0.word } : nil
                return Cover(offer: offer, pack: pack, name: offer.name, line: line?.words ?? tag,
                             lit: line?.new == true || (line == nil && state == .owned))
            }
            let owned = Pack.sold().filter { store.state($0) == .owned }.count
            packsLine = covers.isEmpty || owned == Pack.sold().count ? nil
                : String(localized: "packs \u{00B7} first 3 levels of each free", comment: "The rings' foot, under the packs' covers")
        } else {
            covers = []
            packsLine = nil
        }
    }
}
