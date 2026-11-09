// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What VoiceOver says where the screen shows glyphs, short counts or colour. Each string is localized here, a whole
/// phrase to a key; a count's key varies by plural in the catalog.
enum Spoken {
    static func count(_ n: Int, _ noun: String) -> String { "\(n) \(noun)\(n == 1 ? "" : "s")" }

    /// A layout's rods, the swirl named apart, since it has no knob.
    static func rods(_ layout: Layout) -> String {
        if let base = layout.base {
            return String(localized: "\(base.rods.count) rods and a swirl",
                          comment: "VoiceOver: a swirl layout's knobs, then its swirl")
        }
        return String(localized: "\(layout.rods.count) rods", comment: "VoiceOver: a layout's rods")
    }

    /// The menu's way on: the tier's first level without a best.
    static func next(_ level: Level) -> String {
        String(localized: "Next: level \(Int(level.label) ?? 0), \(level.title)",
               comment: "VoiceOver: the menu's next button. Level number, then its title")
    }

    /// Where a level's back button goes: a pack's level returns to its card.
    static func back(_ level: Level) -> String {
        if let pack = level.pack { return String(localized: "Back to \(pack.name)",
                                                 comment: "VoiceOver: the back button. A pack's name") }
        return level.archived ? String(localized: "Back to the archive",
                                       comment: "VoiceOver: the back button of a daily opened from the archive")
            : String(localized: "Back to levels", comment: "VoiceOver: the back button, to the menu")
    }

    /// The archive's row on the menu: shut until any purchase, then how much of it is at par.
    static func archiveRow(open: Bool, days: Int, atPar: Int) -> (label: String, value: String, hint: String) {
        (String(localized: "Daily archive", comment: "VoiceOver: the menu's archive row"),
         open ? String(localized: "\(atPar) of \(days) at par",
                       comment: "VoiceOver: the archive row's value. Days at par, of days")
             : String(localized: "locked, comes with any pack",
                      comment: "VoiceOver: the archive row, shut until a purchase"),
         String(localized: "\(days) past dailies", comment: "VoiceOver: the archive row's hint"))
    }

    /// A day of the archive: its date in words, its result, and its shape.
    static func archiveDay(_ date: Date, level: Level, mark: Archive.Mark) -> (label: String, value: String, hint: String) {
        (date.formatted(.dateTime.weekday(.wide).day().month(.wide)), mark.spoken, shape(level))
    }

    /// A row's hint: its rods and par.
    private static func shape(_ level: Level) -> String {
        String(localized: "\(rods(level.layout)), par \(level.par)", comment: "VoiceOver: a level's rods, then its par")
    }

    /// A menu row: its name, its result or why it is shut, and its shape. `needs` is the level whose solve opens it, and
    /// `gate` the tier below a closed tier, every level of which at par opens it. `started`: a move committed, no best
    /// yet. `new`: the daily or endless, marked until either is opened.
    static func row(_ level: Level, result: Best?, tanks: Int, detail: String?, enabled: Bool, needs: Level?, gate: Tier? = nil,
                    started: Bool = false, new: Bool = false) -> (label: String, value: String, hint: String) {
        let numbered = Int(level.label)
        let label = numbered.map { String(localized: "Level \($0), \(level.title).",
                                          comment: "VoiceOver: a menu row. Level number, then its title") }
            ?? (level.id.hasPrefix("daily-") ? String(localized: "Today's daily",
                                                      comment: "VoiceOver: the menu's daily row") : level.title)
        let notPlayed = String(localized: "not played", comment: "VoiceOver: a menu row with no best")
        let fresh = String(localized: "new", comment: "VoiceOver: the daily or endless row, until either is opened")
        let value: String
        if !enabled {
            if let n = needs {
                // A tier's own row names the level alone; a mode opens on a level of a tier.
                let number = Int(n.label).map(String.init) ?? n.label
                value = numbered != nil && n.tier == level.tier
                    ? String(localized: "locked, solve level \(number) first",
                             comment: "VoiceOver: a shut row. The level number that opens it")
                    : String(localized: "locked, solve \(n.tier.name) level \(number) first",
                             comment: "VoiceOver: a shut mode. The tier, then the level number, that opens it")
            } else if let gate {
                value = String(localized: "locked, par every \(gate.name) level first",
                               comment: "VoiceOver: a row of a shut tier. The tier below")
            } else {
                value = String(localized: "locked", comment: "VoiceOver: a shut menu row")
            }
        } else if level.run != nil {
            // Started, for a run: one is saved, which the row continues.
            if started {
                value = tanks > 0 ? String(localized: "run in progress, best \(tanks) tanks",
                                           comment: "VoiceOver: the endless row, a run saved. Its best")
                    : String(localized: "run in progress", comment: "VoiceOver: the endless row, a run saved")
            } else {
                value = tanks > 0 ? String(localized: "best \(tanks) tanks",
                                           comment: "VoiceOver: the endless row. The most tanks a run cleared")
                    : new ? fresh : notPlayed
            }
        } else if let result {
            value = result.clean == true ? String(localized: "clean",
                                                  comment: "VoiceOver: a row's best, solved with nothing wasted")
                : result.over == 0 ? String(localized: "at par", comment: "VoiceOver: a row's best")
                : String(localized: "\(result.over) over par", comment: "VoiceOver: a row's best. Moves over par")
        } else {
            value = level.sandbox ? "" : new ? fresh : started ? String(localized: "tried",
                                                                        comment: "VoiceOver: a row started, with no best")
                : notPlayed
        }
        let hint = detail.map { $0.replacingOccurrences(of: " \u{00B7} ", with: ", ") } ?? shape(level)
        return (label, value, hint)
    }
}

extension Game {
    /// The header's count, and what its colour says at and past par. Endless and the sandbox have no par.
    var movesSpoken: String {
        let moved = Self.moved(moves)
        guard level.run == nil, !level.sandbox else { return moved }
        if moves == par { return String(localized: "\(moved), par \(par), at par",
                                        comment: "VoiceOver: the header. Moves, then par") }
        if moves > par { return String(localized: "\(moved), par \(par), over par",
                                       comment: "VoiceOver: the header. Moves, then par") }
        return String(localized: "\(moved), par \(par)", comment: "VoiceOver: the header. Moves, then par")
    }

    private static func moved(_ moves: Int) -> String { String(localized: "\(moves) moves", comment: "Moves played") }

    /// The tank's value: Escapement's ticks left, a run's brim, or the header's count.
    var tankSpoken: String {
        if !level.ratchets.isEmpty { return String(localized: "\(budget) ticks left",
                                                   comment: "VoiceOver: Escapement's tank. Ticks left") }
        return level.run == nil ? movesSpoken
            : String(localized: "\(movesSpoken), brim \(brim) of \(Run.room)",
                     comment: "VoiceOver: endless's tank. Moves, then the brim's notches of its room")
    }

    /// The card's account of how the level ended, where VoiceOver lands as it shows.
    var finishSpoken: String {
        guard let completed else { return ended }
        return String(localized: "\(ended) \(completed.spoken)",
                      comment: "VoiceOver: the result card. How the level ended, then what it completed")
    }

    private var ended: String {
        let moved = Self.moved(moves)
        if lost { return String(localized: "Out of ticks on move \(moves).",
                                comment: "VoiceOver: Escapement's lost card") }
        if let run = level.run {
            return spilled ? String(localized: "Spilled. \(run.tank) tanks cleared.",
                                    comment: "VoiceOver: endless's card, the run spilled")
                : String(localized: "Unstirred. \(moved). Brim \(brim) of \(Run.room).",
                         comment: "VoiceOver: endless's card, a tank cleared")
        }
        if !level.ratchets.isEmpty {
            return clean ? String(localized: "Unstirred. \(moved), \(level.budget) ticks. Clean.",
                                  comment: "VoiceOver: Escapement's card")
                : String(localized: "Unstirred. \(moved), \(level.budget) ticks.",
                         comment: "VoiceOver: Escapement's card")
        }
        if clean { return String(localized: "Unstirred. \(moved), par \(par). Clean.",
                                 comment: "VoiceOver: the result card") }
        if over > 0 { return String(localized: "Unstirred. \(moved), par \(par). \(over) over par.",
                                    comment: "VoiceOver: the result card") }
        return String(localized: "Unstirred. \(moved), par \(par). At par.", comment: "VoiceOver: the result card")
    }
}

/// The opening's "tap to skip" names a tap on the tank, which VoiceOver can't make: while it shows, the caption is the
/// skip itself.
struct SkipButton: ViewModifier {
    let on: Bool
    let skip: () -> Void

    func body(content: Content) -> some View {
        if on {
            content.accessibilityLabel("Skip the opening").accessibilityAddTraits(.isButton).accessibilityAction { skip() }
        } else {
            content
        }
    }
}

/// A row's spoken label, value and hint, in place of its texts read one after another.
struct Speech: ViewModifier {
    let label: String, value: String, hint: String

    init(_ spoken: (label: String, value: String, hint: String)) { (label, value, hint) = spoken }

    func body(content: Content) -> some View {
        content.accessibilityLabel(label).accessibilityValue(value).accessibilityHint(hint) // loc: verbatim localized by Spoken
    }
}
