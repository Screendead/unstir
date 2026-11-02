// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What VoiceOver says where the screen shows glyphs, short counts or colour.
enum Spoken {
    static func count(_ n: Int, _ noun: String) -> String { "\(n) \(noun)\(n == 1 ? "" : "s")" }

    /// A layout's rods, the swirl named apart, since it has no knob.
    static func rods(_ layout: Layout) -> String {
        layout.base.map { count($0.rods.count, "rod") + " and a swirl" } ?? count(layout.rods.count, "rod")
    }

    /// The menu's way on: the tier's first level without a best.
    static func next(_ level: Level) -> String { "Next: level \(Int(level.label) ?? 0), \(level.title)" }

    /// Where a level's back button goes: a pack's level returns to its card.
    static func back(_ level: Level) -> String { "Back to " + (level.pack?.name ?? (level.archived ? "the archive" : "levels")) }

    /// The archive's row on the menu: shut until any purchase, then how much of it is at par.
    static func archiveRow(open: Bool, days: Int, atPar: Int) -> (label: String, value: String, hint: String) {
        ("Daily archive", open ? "\(atPar) of \(days) at par" : "locked, comes with any pack", "\(days) past dailies")
    }

    /// A day of the archive: its date in words, its result, and its shape.
    static func archiveDay(_ date: Date, level: Level, mark: Archive.Mark) -> (label: String, value: String, hint: String) {
        (date.formatted(.dateTime.weekday(.wide).day().month(.wide)), mark.spoken, "\(rods(level.layout)), par \(level.par)")
    }

    /// A menu row: its name, its result or why it is shut, and its shape. `needs` is the level whose solve opens it, and
    /// `gate` the tier below a closed tier, every level of which at par opens it. `started`: a move committed, no best
    /// yet. `new`: the daily or endless, marked until either is opened.
    static func row(_ level: Level, result: Best?, tanks: Int, detail: String?, enabled: Bool, needs: Level?, gate: Tier? = nil,
                    started: Bool = false, new: Bool = false) -> (label: String, value: String, hint: String) {
        let numbered = Int(level.label)
        let label = numbered.map { "Level \($0), \(level.title)." } ?? (level.id.hasPrefix("daily-") ? "Today's daily" : level.title)
        let value: String
        if !enabled {
            let what = needs.map { n in
                // A tier's own row names the level alone; a mode opens on a level of a tier.
                let number = Int(n.label).map(String.init) ?? n.label
                return numbered != nil && n.tier == level.tier ? "level \(number)" : "\(n.tier.name) level \(number)"
            }
            value = what.map { "locked, solve \($0) first" } ?? gate.map { "locked, par every \($0.name) level first" } ?? "locked"
        } else if level.run != nil {
            // Started, for a run: one is saved, which the row continues.
            let best = tanks > 0 ? "best \(count(tanks, "tank"))" : nil
            value = started ? ["run in progress", best].compactMap { $0 }.joined(separator: ", ") : best ?? (new ? "new" : "not played")
        } else if let result {
            value = result.clean == true ? "clean" : result.over == 0 ? "at par" : "\(result.over) over par"
        } else {
            value = level.sandbox ? "" : new ? "new" : started ? "tried" : "not played"
        }
        let hint = detail.map { $0.replacingOccurrences(of: " \u{00B7} ", with: ", ") } ?? "\(rods(level.layout)), par \(level.par)"
        return (label, value, hint)
    }
}

extension Game {
    /// The header's count, and what its colour says at and past par. Endless and the sandbox have no par.
    var movesSpoken: String {
        guard level.run == nil, !level.sandbox else { return Spoken.count(moves, "move") }
        return "\(Spoken.count(moves, "move")), par \(par)" + (moves == par ? ", at par" : moves > par ? ", over par" : "")
    }

    /// The tank's value: Escapement's ticks left, a run's brim, or the header's count.
    var tankSpoken: String {
        if !level.ratchets.isEmpty { return "\(budget) ticks left" }
        return level.run == nil ? movesSpoken : "\(movesSpoken), brim \(brim) of \(Run.room)"
    }

    /// The card's account of how the level ended, where VoiceOver lands as it shows.
    var finishSpoken: String { ended + (completed.map { " \($0.spoken)" } ?? "") }

    private var ended: String {
        let moved = Spoken.count(moves, "move")
        if lost { return "Out of ticks on move \(moves)." }
        if let run = level.run {
            return spilled ? "Spilled. \(Spoken.count(run.tank, "tank")) cleared." : "Unstirred. \(moved). Brim \(brim) of \(Run.room)."
        }
        if !level.ratchets.isEmpty { return "Unstirred. \(moved), \(level.budget) ticks." + (clean ? " Clean." : "") }
        return "Unstirred. \(moved), par \(par). " + (clean ? "Clean." : over > 0 ? "\(over) over par." : "At par.")
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
        content.accessibilityLabel(label).accessibilityValue(value).accessibilityHint(hint)
    }
}
