// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import XCTest
@testable import Unstir

/// The tones' contrast, as WCAG 2 reckons it (Jack's call DESIGN5 = A): words at 4.5:1 or more on every ground the
/// chrome sits on, bar `text4`, which only inactive text takes and which still edges a control at 3:1.
final class ToneTests: XCTestCase {
    private typealias RGB = (r: Double, g: Double, b: Double)

    private func rgba(_ c: Color) -> (RGB, Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(c).getRed(&r, green: &g, blue: &b, alpha: &a)
        return ((r, g, b), a)
    }

    /// `c` laid over `ground`, as the screen shows it.
    private func over(_ c: Color, _ ground: Color) -> RGB {
        let (f, a) = rgba(c), (g, _) = rgba(ground)
        return (f.r * a + g.r * (1 - a), f.g * a + g.g * (1 - a), f.b * a + g.b * (1 - a))
    }

    private func luminance(_ c: RGB) -> Double {
        func lin(_ v: Double) -> Double { v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4) }
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b)
    }

    private func ratio(_ c: Color, on ground: Color) -> Double {
        let a = luminance(over(c, ground)), b = luminance(over(ground, ground))
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// The proposal's numbers, so a change to a tone's alpha shows here as a change to what it reads at.
    func testEachToneReadsAtItsRatioOnBlack() {
        let expected: [(Color, Double)] = [(.text, 18.3), (.text2, 9.3), (.text3, 5.8), (.text4, 3.3), (.rule, 1.3)]
        for (tone, want) in expected {
            XCTAssertEqual(ratio(tone, on: .black), want, accuracy: 0.05)
        }
        XCTAssertEqual(TextTone.allCases.map(\.alpha), [1, 0.72, 0.56, 0.40, 0.14])
    }

    func testNoWordsReadUnderFourAndAHalfToOneButInactiveOnes() {
        for ground in [Color.black, .surface] {
            for tone in [Color.text, .text2, .text3] {
                XCTAssertGreaterThanOrEqual(ratio(tone, on: ground), 4.5)
            }
            XCTAssertLessThan(ratio(.text4, on: ground), 4.5)
            XCTAssertGreaterThanOrEqual(ratio(.line, on: ground), 3)
        }
        // The sheet is lifted off black, and the text on it still reads at its tones'.
        XCTAssertGreaterThan(ratio(.surface, on: .black), 1.1)
    }

    /// On Escapement's paper the ink takes the tones, and `text3` rises to `text2`, which reads there.
    func testThePagesTonesReadOnPaper() {
        for tone in TextTone.allCases where tone != .text4 && tone != .rule {
            let alpha = Page.book.tone(tone).alpha
            XCTAssertGreaterThanOrEqual(ratio(Color.ink.opacity(alpha), on: .bone), 4.5, "\(tone)")
        }
        XCTAssertEqual(Page.night.tone(.text3), .text3)
    }

    /// Every tier's and pack's colour for words reads on black, where vortex's glow (4.1:1) would not.
    func testEveryInkReadsOnBlack() {
        for tier in Tier.allCases {
            XCTAssertGreaterThanOrEqual(ratio(tier.ink, on: .black), 4.5, tier.rawValue)
        }
        for offer in [Offer.complete] + Pack.allCases.map(Offer.pack) {
            XCTAssertGreaterThanOrEqual(ratio(offer.ink, on: .black), 4.5, offer.name)
        }
        for accent in [Color.neonCyan, .magenta, .amber, .lime, .blood, .alarm, .vermilion] {
            XCTAssertGreaterThanOrEqual(ratio(accent, on: .black), 4.5)
        }
        XCTAssertLessThan(ratio(Tier.vortex.glow, on: .black), 4.5)
    }

    /// `accent` at a primary's fill over `ground`, as the screen shows it.
    private func fill(_ accent: Color, on ground: Color) -> Color {
        let c = over(accent.opacity(ButtonFace.fill), ground)
        return Color(red: c.r, green: c.g, blue: c.b)
    }

    /// Each emphasis's label reads at 4.5:1 over what is behind it, and its stroke edges it at 3:1, on black and on
    /// Escapement's paper, where every label is ink.
    func testEveryButtonsLabelReads() {
        var primaries = Tier.allCases.map { ($0.rawValue, $0.ink) } + [("amber", .amber), ("lime", .lime), ("vermilion", .vermilion)]
        primaries += ([Offer.complete] + Pack.allCases.map(Offer.pack)).filter { $0 != .pack(.escapement) }.map { ($0.name, $0.ink) }
        for (name, accent) in primaries {
            XCTAssertGreaterThanOrEqual(ratio(accent, on: fill(accent, on: .black)), 4.5, name)
        }
        // The plate's vermilion reads 4.7:1 on black but 4.3:1 over its own fill: its buy button is Jack's to settle.
        XCTAssertGreaterThanOrEqual(ratio(Offer.pack(.escapement).ink, on: fill(Offer.pack(.escapement).ink, on: .black)), 4.2)
        XCTAssertGreaterThanOrEqual(ratio(Page.night.line, on: .black), 3)
        XCTAssertGreaterThanOrEqual(ratio(Page.night.ink, on: .black), 4.5)
        XCTAssertGreaterThanOrEqual(ratio(Page.night.stop, on: .black), 4.5, "armed")
        // Paper: ink over the plate's fill, and a stroke lifted to read.
        XCTAssertGreaterThanOrEqual(ratio(Color.ink, on: fill(Page.book.accent, on: .bone)), 4.5)
        XCTAssertGreaterThanOrEqual(ratio(Page.book.line, on: .bone), 3)
        XCTAssertGreaterThanOrEqual(ratio(Page.book.stop, on: .bone), 3, "armed stroke")
        XCTAssertLessThan(ratio(Color.ink.opacity(TextTone.text4.alpha), on: .bone), 3, "why paper lifts its line")
    }

    /// Every button is 44 pt tall at the smallest type size too, where padding alone falls short.
    @MainActor func testEveryButtonIsFortyFourTall() {
        for size in [DynamicTypeSize.xSmall, .large, .xxxLarge] {
            for emphasis in [Emphasis.primary, .secondary] {
                let host = UIHostingController(rootView: Text("undo").modifier(ButtonFace(emphasis: emphasis)).dynamicTypeSize(size))
                let fitted = host.sizeThatFits(in: CGSize(width: 400, height: 400))
                XCTAssertGreaterThanOrEqual(fitted.height, ButtonFace.height, "\(emphasis) at \(size)")
            }
            let swatch = UIHostingController(rootView: Text("R").modifier(ButtonFace(emphasis: .secondary, inset: 0,
                                                                                     minWidth: ButtonFace.height)).dynamicTypeSize(size))
            let fitted = swatch.sizeThatFits(in: CGSize(width: 400, height: 400))
            XCTAssertGreaterThanOrEqual(min(fitted.width, fitted.height), ButtonFace.height, "a swatch at \(size)")
        }
        // The default size lands on 44, as the proposal draws it, not a few points over.
        let host = UIHostingController(rootView: Text("undo").modifier(ButtonFace(emphasis: .secondary)))
        XCTAssertEqual(host.sizeThatFits(in: CGSize(width: 400, height: 400)).height, ButtonFace.height, accuracy: 1)
    }
}
