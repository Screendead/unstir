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
}
