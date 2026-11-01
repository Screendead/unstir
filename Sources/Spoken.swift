// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What VoiceOver says where the screen shows glyphs, short counts or colour.
enum Spoken {
    static func count(_ n: Int, _ noun: String) -> String { "\(n) \(noun)\(n == 1 ? "" : "s")" }

    /// A layout's rods, the swirl named apart, since it has no knob.
    static func rods(_ layout: Layout) -> String {
        layout.base.map { count($0.rods.count, "rod") + " and a swirl" } ?? count(layout.rods.count, "rod")
    }

    /// Where a level's back button goes: a pack's level returns to its card.
    static func back(_ level: Level) -> String { "Back to " + (level.pack?.name ?? "levels") }

    /// A menu row: its name, its result or why it is shut, and its shape. `needs` is the level whose solve opens it, and
    /// `gate` the tier below a closed tier, every level of which at par opens it.
    static func row(_ level: Level, result: Best?, tanks: Int, detail: String?, enabled: Bool, needs: Level?, gate: Tier? = nil)
        -> (label: String, value: String, hint: String) {
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
            value = tanks > 0 ? "best \(count(tanks, "tank"))" : "not played"
        } else if let result {
            value = result.clean == true ? "clean" : result.over == 0 ? "at par" : "\(result.over) over par"
        } else {
            value = level.sandbox ? "" : "not played"
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
    var finishSpoken: String {
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
