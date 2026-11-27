// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// What the strand's menu shows, read once on the main actor at a rest and handed whole to the bake: nothing in it
/// is read again while the menu moves.
struct StrandModel: Equatable, Sendable {
    struct Row: Equatable, Sendable {
        let level: Level
        let number: String
        let name: String
        let facts: String
        /// Solved, or the way on.
        let lit: Bool
        let frontier: Bool
        /// Its tier is open and the level before it has a best.
        let open: Bool
        let marks: Int?
        let margin: String?
    }

    struct TierRows: Equatable, Sendable {
        let tier: Tier
        let word: String
        let open: Bool
        /// "13/27 at par", or what opens a closed tier.
        let under: String
        let rows: [Row]
    }

    struct Today: Equatable, Sendable {
        let level: Level
        let under: String?
        let marks: Int?
        let solved: Bool
    }

    struct Way: Equatable, Sendable {
        let tier: Int
        let level: Level
    }

    let tiers: [TierRows]
    /// Nil until the daily and endless show (`Menu.lead`).
    let daily: Today?
    let archive: String?
    let way: Way?
    let endlessLine: String?

    @MainActor init(today: Date, saved: Resume?) {
        let unlocked = Best.unlocked
        tiers = Tier.allCases.map { tier in
            let open = tier.isOpen(), levels = Array(tier.levels.prefix(27)), frontier = tier.frontier()?.id
            return TierRows(tier: tier, word: tier.word, open: open, under: open ? Menu.progress(tier) : Menu.reason(tier) ?? "",
                            rows: levels.enumerated().map { i, level in
                                let reached = open && Menu.reached(i, of: levels, unlocked: unlocked)
                                let result = Best.load(level.id)
                                let mark = Archive.Mark(result, started: result == nil && Best.started(level.id))
                                return Row(level: level, number: level.label, name: level.title, facts: Menu.facts(level),
                                           lit: reached && (result != nil || level.id == frontier), frontier: level.id == frontier,
                                           open: reached, marks: reached ? ResultMarks.filled(mark) : nil, margin: ResultMarks.margin(mark))
                            })
        }
        let stored = Tier.stored()
        way = ([stored] + Tier.allCases).lazy.compactMap { tier in
            tier.frontier().map { Way(tier: Tier.allCases.firstIndex(of: tier)!, level: $0) }
        }.first
        if Menu.lead(unlocked: unlocked).modes {
            let day = Level.daily(today), result = Best.load(day.id)
            let mark = Archive.Mark(result, started: result == nil && Best.started(day.id))
            daily = Today(level: day, under: Menu.dailyLines(day, run: Daily.run(today: today)).under, marks: ResultMarks.filled(mark),
                          solved: result != nil)
            archive = String(localized: "\(Archive.tally(today: today).days) past dailies", comment: "The menu's archive row. Past dailies")
        } else {
            daily = nil
            archive = nil
        }
        endlessLine = Menu.endlessLine(saved, tanks: Best.tanks)
    }
}
