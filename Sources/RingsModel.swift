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
        /// Endless with no run saved: a new run is dealt as it plays, from a seed drawn then.
        var anew = false
        /// `facts` as short as it can say them, for accessibility type: "best 5 · par 4".
        var brief: String?
    }

    struct Ring: Equatable, Sendable {
        let hue: RingsHue
        let word: String
        let open: Bool
        /// "14/27 · 11 at par", or what opens a shut tier.
        let under: String
        let spots: [Spot]
        /// On a tier's ring, the bead the middle names and plays: the first level without a best, else the first short
        /// of par, else the first. Nil on a shut tier and the rings that aren't tiers.
        let way: Int?
        /// What the middle names and plays at rest: the way's level, today's daily on the archive's ring, endless's
        /// run. Nil on a shut ring.
        let lead: Spot?
        /// Endless with a run saved: the middle also offers a new one, armed by a first tap (`ResetArm`).
        var renews = false
        /// `under` as short as it can say it, for accessibility type: "14/27 · 11 par".
        var brief: String?
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

    /// `endless`: its saved run, as the root reads it for the menu.
    @MainActor init(today: Date, endless: Resume?) {
        let unlocked = Best.unlocked, modes = MenuView.lead(unlocked: unlocked).modes, store = Store.shared
        let tiers = Tier.allCases.map { tier in
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
                return Spot(level: level, number: level.label, name: level.title, bead: bead, shut: shut, facts: facts,
                            brief: Self.brief(level, best))
            }
            let solved = bests.filter { $0 != nil }.count, par = bests.filter { $0?.over == 0 }.count
            let under = open
                ? String(localized: "\(solved)/\(levels.count) \u{00B7} \(par) at par",
                         comment: "The rings' middle, under a tier's name. Levels solved, of all, then those at par")
                : tier.below.map {
                    String(localized: "opens with every \($0.word) level solved", comment: "A shut tier's gate. The tier below")
                } ?? ""
            let way = !open || levels.isEmpty ? nil : frontier ?? bests.firstIndex { ($0?.over ?? 0) > 0 } ?? 0
            let brief = String(localized: "\(solved)/\(levels.count) \u{00B7} \(par) par",
                               comment: "The rings' middle at accessibility type sizes, under a tier's name. Levels solved, of all, then those at par")
            return Ring(hue: .tier(tier), word: tier.word, open: open, under: under, spots: spots, way: way, lead: way.map { spots[$0] },
                        brief: open ? brief : nil)
        }
        // The daily and endless show once the old menu's would (`MenuView.lead`, Jack's call C4), the archive's ring
        // above plughole and endless's below maelstrom.
        rings = modes ? [Self.archive(today: today, store: store, unlocked: unlocked)] + tiers + [Self.endless(endless)] : tiers
        if modes {
            let level = Self.dealt(today, archived: false)
            daily = Today(level: level, title: level.title, under: MenuView.dailyLines(level, run: Daily.run(today: today)).under)
        } else {
            daily = nil
        }
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

    /// Each daily as dealt, by its day: the generator is frozen, and dealing thirty tanks on every read took 0.3 s of
    /// the main thread in a Debug build.
    @MainActor private static var dealing: [String: Level] = [:]

    @MainActor private static func dealt(_ day: Date, archived: Bool) -> Level {
        let key = Level.dailyID(day) + (archived ? " archived" : "")
        if let level = dealing[key] { return level }
        let level = Level.daily(day, archived: archived)
        dealing[key] = level
        return level
    }

    /// The archive's ring: a bead for each past daily, round today's in the middle. Shut, as the archive is, until a
    /// purchase (`Archive.open`), and until the store's first read so an owner never meets the lock.
    @MainActor private static func archive(today: Date, store: Store, unlocked: Bool) -> Ring {
        let days = Archive.days(today: today), open = store.ready && Archive.open
        func short(_ date: Date) -> String { date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) }
        let locked = String(localized: "unlocked by purchasing any pack")
        var atPar = 0
        let spots = days.map { day -> Spot in
            let level = dealt(day, archived: true), best = Best.load(level.id)
            if best?.over == 0 { atPar += 1 }
            let facts = best.map {
                String(localized: "solved in \(level.par + $0.over) \u{00B7} par \(level.par)",
                       comment: "The rings' middle, a solved level picked. Its best in moves, then its par")
            } ?? String(localized: "par \(level.par)", comment: "The rings' middle, an unsolved level picked. Its par")
            let bead: Bead = !open ? .dull : best.map { $0.over == 0 ? .par : .solved } ?? .dull
            return Spot(level: level, number: "", name: short(day), bead: bead, shut: open ? nil : locked, facts: facts,
                        brief: brief(level, best))
        }
        let under = !store.ready ? String(localized: "\(days.count) past dailies", comment: "The menu's archive row. Past dailies")
            : open ? String(localized: "\(days.count) past dailies \u{00B7} \(atPar) at par",
                            comment: "The menu's archive row. Past dailies, then how many are at par")
            : String(localized: "\(days.count) past dailies \u{00B7} comes with any pack",
                     comment: "The menu's archive row, shut until a purchase. Past dailies")
        let lead = Spot(level: dealt(today, archived: false), number: "", name: short(today), bead: .dull, shut: nil, facts: "")
        return Ring(hue: .today, word: String(localized: "today", comment: "The rings' archive ring, round today's daily"),
                    open: open, under: under, spots: spots, way: nil, lead: open ? lead : nil)
    }

    private static func brief(_ level: Level, _ best: Best?) -> String? {
        best.map {
            String(localized: "best \(level.par + $0.over) \u{00B7} par \(level.par)",
                   comment: "The rings' middle at accessibility type sizes, a solved level picked. Its best in moves, then its par")
        }
    }

    /// Endless's ring: no beads, its circle a neon tube; the middle continues the saved run, or deals a new one.
    @MainActor private static func endless(_ saved: Resume?) -> Ring {
        let run = saved?.run, best = Best.tanks
        let under: String = run.map {
            let tank = $0.tank + 1, brim = saved?.brim ?? $0.brim
            return best > 0
                ? String(localized: "tank \(tank) \u{00B7} brim \(brim) \u{00B7} best \(best)",
                         comment: "The rings' endless middle, a run saved: its tank, its brim, then the best run's tanks")
                : String(localized: "tank \(tank) \u{00B7} brim \(brim)", comment: "The rings' endless middle, a run saved: its tank, then its brim")
        } ?? (best > 0 ? String(localized: "best \(best)", comment: "Endless's row: the best run's tanks") : "")
        // A run's level, or a placeholder for one dealt as it plays: a seed drawn here would make every read new.
        let name = run == nil ? String(localized: "new run", comment: "The rings' endless middle with no run saved: deals one")
            : String(localized: "continue", comment: "The rings' endless middle: plays the saved run")
        let lead = Spot(level: .endless(run ?? Run(seed: 0)), number: "", name: name, bead: .dull, shut: nil, facts: "", anew: run == nil)
        let brief = run.map {
            String(localized: "tank \($0.tank + 1) \u{00B7} brim \(saved?.brim ?? $0.brim)",
                   comment: "The rings' endless middle, a run saved: its tank, then its brim")
        }
        return Ring(hue: .endless, word: String(localized: "endless", comment: "The rings' endless ring"), open: true, under: under,
                    spots: [], way: nil, lead: lead, renews: run != nil, brief: brief)
    }
}
