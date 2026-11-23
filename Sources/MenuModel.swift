// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

extension Tier {
    /// The tier `n` rungs up the ladder, or down for negative `n`, if there is one.
    func step(_ n: Int) -> Tier? {
        let i = Self.allCases.firstIndex(of: self)! + n
        return Self.allCases.indices.contains(i) ? Self.allCases[i] : nil
    }

    /// The first level with no best, on an open tier: where the player is. Every level before it has a best, so it is
    /// open.
    func frontier(unlocked: Bool = Best.unlocked, _ best: (String) -> Best? = Best.load) -> Level? {
        isOpen(unlocked: unlocked, best) ? levels.first { best($0.id) == nil } : nil
    }

    /// The levels not yet solved, as runs of neighbours by index. The first of each run is open: the level before it has
    /// a best, or it is the first.
    func short(_ best: (String) -> Best? = Best.load) -> [ClosedRange<Int>] {
        solved(best).enumerated().reduce(into: []) { runs, level in
            guard !level.element else { return }
            if let last = runs.last, last.upperBound == level.offset - 1 {
                runs[runs.count - 1] = last.lowerBound ... level.offset
            } else {
                runs.append(level.offset ... level.offset)
            }
        }
    }

    /// The row a launch centres on: the frontier, else the first level short of par. Nil, the top, once every level is
    /// at par or while the tier is locked.
    func landing(_ best: (String) -> Best? = Best.load) -> Level? {
        frontier(best) ?? (isOpen(best) ? levels.first { (best($0.id)?.over ?? 0) > 0 } : nil)
    }
}

extension Level {
    /// The row the menu, or a pack's card, centres on once this level is left: after a solve the one after it, which
    /// "next ›" opens, or itself as its list's last; a past daily itself, in the archive. Nil for today's daily, endless
    /// and the sandbox, which sit outside the tier's rows.
    func focus(solved: Bool) -> Level? {
        if archived { return self }
        let list = pack?.levels ?? tier.levels
        guard let i = list.firstIndex(where: { $0.id == id }) else { return nil }
        return list[solved ? min(i + 1, list.count - 1) : i]
    }
}

/// What the menu shows and what its rows do, apart from how it draws them.
@MainActor enum Menu {
    /// What the menu leads with (Jack's call C4, round 13). `modes`: the daily and endless, which draw on every layout, so
    /// they open, and show, after the first hex level. `sandbox`: the build has it (`Level.playsSandbox`), its row at the
    /// list's end.
    typealias Lead = (modes: Bool, sandbox: Bool)
    static func lead(unlocked: Bool = Best.unlocked, release: Bool = Build.release,
                     best: (String) -> Best? = Best.load) -> Lead {
        (unlocked || best(Level.plughole[22].id) != nil, Level.playsSandbox(release: release))
    }

    /// The daily row's line under its title, a frost day's (the only daily that seizes knobs) and a run of days from
    /// two, and the row's detail for VoiceOver, its shape and that line. Nil on a plain day before a run.
    static func dailyLines(_ day: Level, run: Int) -> (under: String?, detail: String?) {
        let frost = !day.seized.isEmpty, running = run >= 2
        let under: String? = switch (frost, running) {
        case (true, true): String(localized: "frost day \u{00B7} \(run) days running",
                                  comment: "The daily's row on a frost day, two knobs frozen: then the days in a row solved, from two")
        case (true, false): String(localized: "frost day", comment: "The daily's row on a frost day, two knobs frozen")
        case (false, true): String(localized: "\(run) days running", comment: "The daily's row: the days in a row solved, from two")
        case (false, false): nil
        }
        return (under, under.map {
            String(localized: "\(day.layout.rods.count) rods \u{00B7} par \(day.par) \u{00B7} \($0)",
                   comment: "VoiceOver: the daily's row. Its rods, its par, then a frost day or the days in a row solved")
        })
    }

    /// Whether a row opens its level: always, but beside play the playing level's own row, as endless's row would deal
    /// a new run over the one playing; `anew` is endless's new run.
    nonisolated static func opens(_ level: Level, playing: Level?, anew: Bool = false) -> Bool {
        anew || playing?.id != level.id
    }

    /// A card over a playing level's result card, which covers the menu beside it, closes onto that card rather than
    /// going to the menu (Jack's call s5b-back = B); over the menu beside play it goes to the menu.
    nonisolated static func closes(playing: Bool, covered: Bool) -> Bool { playing && covered }

    /// Whether row `i` of an open tier's `levels` opens: the first, every row under the developer or editors' unlock,
    /// else a row whose level before it has a best.
    static func reached(_ i: Int, of levels: [Level], unlocked: Bool) -> Bool {
        unlocked || i == 0 || Best.load(levels[i - 1].id) != nil
    }

    /// What a closed row says for two seconds when tapped: on a locked tier, what opens the tier (`below` is the tier
    /// under it); on an open one, the level before it. Nil for a row that opens.
    static func closedLine(_ i: Int, of levels: [Level], below: Tier?, open: Bool, reached: Bool) -> String? {
        !open ? below.map {
            String(localized: "solve every \($0.word) level to open", comment: "A shut tier's row, tapped. The tier below")
        } : reached ? nil : String(localized: "solve \(levels[i - 1].label) to open",
                                   comment: "A shut row, tapped. The level number before it")
    }

    /// A locked tier's gate: each level of the tier `below` it, solved or not, and how many are, its lit ticks.
    static func gate(_ below: Tier) -> (solved: [Bool], lit: Int) {
        let solved = below.solved()
        return (solved, solved.filter { $0 }.count)
    }
}

/// A closed row's refusal: a tap shakes it and says what opens it, for `hold` from the last tap.
struct Refusal: Equatable {
    static let hold = 2.0
    /// Every tap refused: each shakes the row.
    private(set) var taps = 0
    /// What opens the row is being said.
    private(set) var said = false

    /// A tap refused; `lapse` takes its number back once `hold` has passed.
    mutating func tap() -> Int {
        taps += 1
        said = true
        return taps
    }

    /// The line goes, unless a later tap has said it again.
    mutating func lapse(_ tap: Int) { if taps == tap { said = false } }
}

/// Endless's "new run" while a run is saved, as reset's two taps (`ResetArm`): a first tap arms it, and a second
/// within `ResetArm.window`, or under VoiceOver before focus leaves, drops the run and starts another.
struct NewRunArm: Equatable {
    private(set) var armedAt: Date?
    var armed: Bool { armedAt != nil }

    /// A tap: true when it starts a new run, else it has armed.
    mutating func tap(now: Date = .now, held: Bool) -> Bool {
        let tap = ResetArm.tap(now: now, armedAt: armedAt, played: true, held: held)
        armedAt = tap.armedAt
        return tap.reset
    }

    mutating func disarm() { armedAt = nil }
}

/// A pack's card opened from another card's link, Triptych I's: back returns there while that pack's card is still the
/// one up, never once the card has changed, closed or been put away under a level, then opened again.
struct CameFrom: Equatable {
    let back: Offer
    let card: Offer

    /// Kept across a change of card only while the card is still the one it opened.
    func kept(as now: Offer?) -> CameFrom? { now == card ? self : nil }

    /// Where back goes, while Triptych I still saves anything.
    func returns(card now: Offer?, offersComplete: Bool) -> Offer? {
        guard now == card, back != .complete || offersComplete else { return nil }
        return back
    }
}
