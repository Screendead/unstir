// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What words on the slope lie over: the open water beside the ledges, or the heart of the rock, where a hollow's
/// name goes.
enum SlopeGrounding {
    case water, rock
}

extension Slope {
    /// The shallowest words may sit, in ledges under the surface: above it the surface's own light is too bright for
    /// any ink.
    static let shallowest = 1.2

    /// The brightest the ground gets under words `fathoms` ledges under the surface (a depth over `pitch`), as WCAG
    /// reckons luminance: the water's colour there with the sun's rays and the surface's glow on it, or the rock's lit
    /// heart. A bound on what Slope.metal draws, which `SlopeTests` holds it to.
    static func glare(_ ground: SlopeGrounding, fathoms: Double) -> Double {
        switch ground {
        case .water: 0.015 + 0.105 * exp(-fathoms / 13)
        case .rock: 0.017 + 0.135 * exp(-fathoms / 26)
        }
    }

    /// The ink for words of `tone` at that depth: the tone's own strength where that reads, and as much more as it
    /// takes to read at 4.5:1 over the brightest the ground gets there (3:1 for `text4`, which only inactive words
    /// take). In the sunlit shallows the quieter tones draw up towards the full ink; from plughole down they are the
    /// game's own.
    static func ink(_ tone: TextTone, on ground: SlopeGrounding = .water, fathoms: Double) -> Color {
        Color.text.opacity(strength(tone, on: ground, fathoms: fathoms))
    }

    static func strength(_ tone: TextTone, on ground: SlopeGrounding = .water, fathoms: Double) -> Double {
        guard tone != .rule else { return tone.alpha }
        let under = glare(ground, fathoms: max(fathoms, shallowest)), want = tone == .text4 ? 3.0 : 4.5
        // The ground as a grey of its luminance, and the ink laid over it at each strength, as the screen blends them.
        let grey = Self.gamma(under)
        var alpha = tone.alpha
        while alpha < 1, Self.ratio(alpha: alpha, grey: grey) < want { alpha += 0.01 }
        return min(alpha, 1)
    }

    private static func linear(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
    private static func gamma(_ l: Double) -> Double { l <= 0.0030353 ? l * 12.92 : 1.055 * pow(l, 1 / 2.4) - 0.055 }

    /// How `Color.text` at `alpha` reads over a grey ground.
    static func ratio(alpha: Double, grey: Double) -> Double {
        let ink = [0xED, 0xEF, 0xF7].map { Double($0) / 255 * alpha + grey * (1 - alpha) }
        let over = 0.2126 * linear(ink[0]) + 0.7152 * linear(ink[1]) + 0.0722 * linear(ink[2])
        return (over + 0.05) / (linear(grey) + 0.05)
    }

    /// A tier's light, for the few words that take its colour and for its pebbles' glow: sand's warm white, mauve's
    /// rose, slate's blue, basalt's ember. Each reads at 4.5:1 over its own tier's water and rock.
    static func light(tier: Int) -> Color {
        [Color(0xFFD18C), Color(0xFF9EDB), Color(0x8CC2FF), Color(0xFF8A5C)][min(max(tier, 0), 3)]
    }
}

extension Tier {
    /// The tier's light on the slope (`Slope.light`).
    var light: Color { Slope.light(tier: Tier.allCases.firstIndex(of: self) ?? 0) }
}

/// The slope's voices: who is speaking decides the face, the role its size. Every one is a text style, so it follows
/// Dynamic Type to the largest sizes; nothing on the slope shrinks to fit.
enum SlopeVoice {
    /// A level's name: SF Pro, light.
    case name
    /// The world's own words (a tier's name, "today", a hint): New York italic, light.
    case word
    /// Numbers and counts: SF Mono.
    case data
    /// Everything else: SF Pro.
    case plain
}

enum SlopeRole {
    /// 34 pt.
    case display
    /// 28 pt.
    case title
    /// 17 pt.
    case body
    /// 15 pt.
    case label
    /// 13 pt.
    case detail

    var style: Font.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title: .title
        case .body: .body
        case .label: .subheadline
        case .detail: .footnote
        }
    }
}

extension Font {
    static func slope(_ voice: SlopeVoice, _ role: SlopeRole, _ weight: Font.Weight? = nil) -> Font {
        switch voice {
        case .name: .system(role.style, design: .default, weight: weight ?? .light)
        case .word: .system(role.style, design: .serif, weight: weight ?? .light).italic()
        case .data: .system(role.style, design: .monospaced, weight: weight ?? .regular)
        case .plain: .system(role.style, design: .default, weight: weight ?? .regular)
        }
    }
}
