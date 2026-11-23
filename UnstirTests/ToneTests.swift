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

    // MARK: The slope

    /// What Slope.metal draws at each of `points` (screen points) for `lay` seen from `top`, motes off, as sRGB.
    private func ground(_ lay: SlopeLay, top: CGFloat, size: CGSize, at points: [SIMD2<Float>]) throws -> [SIMD4<Float>] {
        let kit = try ShaderKit("Slope.metal", helpersOnly: false, kernels: """
            kernel void probe(device const float *g [[buffer(0)]], device const float2 *at [[buffer(1)]],
                              device float4 *out [[buffer(2)]], constant float2 &size [[buffer(3)]],
                              uint id [[thread_position_in_grid]]) {
                out[id] = float4(slopeGround(at[id], size, float4(1.0, 3.0, 0.0, 0.0), float4(0.0, 0.0, 0.0, 1.0),
                                             float4(1.0, 0.86, 0.6, 0.0), 0.0, g), 1.0);
            }
            """)
        let g = try kit.buffer(lay.uniforms(top: top)), at = try kit.buffer(points)
        let out = try kit.buffer(SIMD4<Float>.self, count: points.count)
        var screen = SIMD2<Float>(Float(size.width), Float(size.height))
        try kit.run("probe", count: points.count) { enc in
            enc.setBuffer(g, offset: 0, index: 0)
            enc.setBuffer(at, offset: 0, index: 1)
            enc.setBuffer(out, offset: 0, index: 2)
            enc.setBytes(&screen, length: 8, index: 3)
        }
        return kit.read(out, as: SIMD4<Float>.self)
    }

    /// The slope's inks keep their floors on what the shader draws (docs/slope.md, 1.4): `ink` to `ink3` read at 4.5:1
    /// and `ink4` at 3:1 over the water beside the shelf, where every row's words stand (from x = 180 at the overview,
    /// from 18 pt past the ninth lip in the dive), from each ink's `shallowest` down to the drop-off; and `ink` over the rock's heart in the dive, where a
    /// hollow's name goes. In the 300 pt under its `shallowest`, where the sun's rays reach, one pixel in a thousand
    /// may fall short, a ray's brightest thread; deeper, none.
    func testTheSlopesInksReadOnItsWater() throws {
        let size = CGSize(width: 440, height: 956)
        let column = SlopeColumn.main(size: size)
        let rays: CGFloat = 300
        var sunlit: [SlopeInk: (short: Int, of: Int)] = [:], deep: [SlopeInk: Int] = [:], heart = 0, rock = 0
        for z in [0, 1] as [CGFloat] {
            let lay = SlopeLay(column, z: z), travel = lay.travel(height: size.height)
            let words = z == 0 ? 180 : Float(column.lip + 8 * column.step + 18)
            let tops = z == 0 ? [SlopeLay.overview(height: size.height).top]
                : Array(stride(from: travel.lowerBound, through: travel.upperBound, by: size.height))
            for top in tops {
                var points: [SIMD2<Float>] = []
                for y in stride(from: Float(1), to: Float(size.height), by: 5) where top + CGFloat(y) > SlopeInk.ink.shallowest {
                    for x in stride(from: Float(21), to: Float(size.width) - 16, by: 5) where x >= words || (z == 1 && x < 76) {
                        points.append(SIMD2(x, y))
                    }
                }
                guard !points.isEmpty else { continue }
                for (point, colour) in zip(points, try ground(lay, top: top, size: size, at: points)) {
                    let under = Color(red: Double(colour.x), green: Double(colour.y), blue: Double(colour.z))
                    let depth = top + CGFloat(point.y)
                    if point.x >= words {
                        for ink in SlopeInk.allCases where depth > ink.shallowest {
                            let short = ratio(ink.colour, on: under) < (ink == .ink4 ? 3 : 4.5)
                            if depth < ink.shallowest + rays {
                                sunlit[ink, default: (0, 0)].of += 1
                                if short { sunlit[ink, default: (0, 0)].short += 1 }
                            } else if short {
                                deep[ink, default: 0] += 1
                            }
                        }
                    } else if depth < lay.tops[lay.count - 1] {
                        rock += 1
                        if ratio(SlopeInk.ink.colour, on: under) < 4.5 { heart += 1 }
                    }
                }
            }
        }
        for ink in SlopeInk.allCases {
            let lit = try XCTUnwrap(sunlit[ink])
            XCTAssertGreaterThan(lit.of, 4000)
            XCTAssertLessThan(Double(lit.short), 0.001 * Double(lit.of), "\(ink) in the sun")
            XCTAssertEqual(deep[ink, default: 0], 0, "\(ink) in the deep")
        }
        XCTAssertGreaterThan(rock, 4000)
        XCTAssertLessThan(Double(heart), 0.001 * Double(rock), "the rock's heart")
    }

    /// A pebble Swift seats on a ledge rests on the rock the shader draws at both zooms that rest, the overview and the
    /// dive: the point just over its seat is water and the point just under it is the ledge's lit top. (Half open, a
    /// ledge's top is shorter than its pebble and the ledge above stands over the seat.)
    func testAPebblesSeatIsOnTheDrawnRock() throws {
        let size = CGSize(width: 440, height: 956)
        func luminance(_ c: SIMD4<Float>) -> Double { self.luminance((Double(c.x), Double(c.y), Double(c.z))) }
        for z in [0, 1] as [CGFloat] {
            let lay = SlopeLay(.main(size: size), z: z)
            for n in [0, 3, 7, 11, 20, 29] {
                let seat = lay.seat(n), top = seat.y - 300
                let got = try ground(lay, top: top, size: size, at: [SIMD2(Float(seat.x), 298.8), SIMD2(Float(seat.x), 301.2)])
                XCTAssertGreaterThan(luminance(got[1]), luminance(got[0]) * 1.5 + 0.02, "ledge \(n) at zoom \(z)")
            }
        }
    }

    /// Every stone's target is 44 pt either way at the least, whatever its words and state.
    @MainActor func testEveryStoneIsFortyFourEitherWay() {
        for size in [DynamicTypeSize.xSmall, .large, .accessibility3] {
            for state in [StoneState.lit, .next, .dull] {
                let host = UIHostingController(rootView: Stone(Text(verbatim: "a"), state: state) {}.dynamicTypeSize(size))
                let fitted = host.sizeThatFits(in: CGSize(width: 400, height: 400))
                XCTAssertGreaterThanOrEqual(min(fitted.width, fitted.height), SlopePebble.target, "\(state) at \(size)")
            }
        }
    }
}
