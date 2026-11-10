// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The text's tones round the game: `text` at five strengths over its ground, in place of thirteen opacities (Jack's
/// call DESIGN5 = A, the design pass's second change). Only `text4` falls under 4.5:1, and only inactive text takes
/// it, beside a lock or a state; `rule` is never text.
enum TextTone: CaseIterable {
    /// Primary copy, button labels, row titles.
    case text
    /// Details that carry meaning, notes, the count at rest, a fact's value.
    case text2
    /// Fact keys, section progress, restore, explanations: the floor for anything that means something.
    case text3
    /// Inactive only: a locked row's detail, a disabled label. It is also `line`, a control's stroke.
    case text4
    /// Separators.
    case rule

    var alpha: Double {
        switch self {
        case .text: 1
        case .text2: 0.72
        case .text3: 0.56
        case .text4: 0.40
        case .rule: 0.14
        }
    }
}

extension View {
    /// The tone over whatever ink the view inherits: `text` on black, the page's ink on Escapement's paper.
    func tone(_ tone: TextTone) -> some View { opacity(tone.alpha) }
}

extension Color {
    init(_ hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    static let text = Color(0xEDEFF7)
    static let text2 = tone(.text2)
    static let text3 = tone(.text3)
    static let text4 = tone(.text4)
    /// A control's stroke, at 3:1 as a component's edge needs.
    static let line = text4
    static let rule = tone(.rule)
    static func tone(_ tone: TextTone) -> Color { text.opacity(tone.alpha) }

    /// The settings sheet, the one lifted colour: a sheet with no edge on black reads as a hole.
    static let surface = Color(0x15171E)
    /// Under the consent card, light enough that the menu still reads as a place behind it.
    static let scrim = Color.black.opacity(0.6)

    /// SwiftUI already has a `cyan`.
    static let neonCyan = Color(0x00F0FF)
    static let magenta = Color(0xFF2BD6)
    static let amber = Color(0xFFB000)
    static let lime = Color(0x7CFF4F)
    static let blood = Color(0xFF1438)
    static let violet = Color(0x9A2CFF)
    static let alarm = Color(0xFF3B6B)
    /// Escapement's clock, from the packs mock-up's plate, lifted to read on black.
    static let vermilion = Color(0xFF5A36)
    /// The grid never uses white, so the live ring cannot be mistaken for a line.
    static let live = Color(0xF2F4FA)
    /// Vortex's text, its sweep's teal: its glow, at 4.1:1, stays a glow.
    static let vortexInk = Color(0x00D2C0)
    /// Maelstrom's text, its sweep's red, in place of whirlpool's blood.
    static let maelstromInk = Color(0xFF1A2A)
}

extension Tier {
    /// The tier's colour for words: "next ›", the gate's line. `glow` stays the shadow's.
    var ink: Color {
        switch self {
        case .plughole: .neonCyan
        case .whirlpool: .blood
        case .vortex: .vortexInk
        case .maelstrom: .maelstromInk
        }
    }
}

extension Offer {
    /// The pack's colour for words: its levels' numbers on the card, "next ›", "more in … ›". `glow` stays the shadow's.
    var ink: Color { self == .pack(.prism) ? .text : glow }
}
