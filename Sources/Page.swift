// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

extension Color {
    /// Escapement's page: bone paper, black ink and the plate's one vermilion, from the packs mock-up.
    static let bone = Color(0xF3EAD8)
    static let ink = Color(0x1A1A1A)
    static let plateVermilion = Color(0xD8402A)
}

/// What a level is drawn on (Jack's call ESC-PAPER = B, round 16): every level plays on the night's black but
/// Escapement's, a problem book in bone paper and black ink with one vermilion accent. Night's colours are the play
/// screen's own, so every other level draws as it did.
struct Page: Equatable, Sendable {
    let paper: Bool

    static let night = Page(paper: false), book = Page(paper: true)

    var ground: Color { paper ? .bone : .black }
    var ink: Color { paper ? .ink : .text }
    /// The turn's hairlines, dashes and counts, and the lift's flash.
    var live: Color { paper ? .ink : .live }
    /// The clock's: on black, lifted to read there.
    var accent: Color { paper ? .plateVermilion : .vermilion }
    /// A clock stopping: amber on black, the plate's vermilion on paper, where amber doesn't read.
    var stop: Color { paper ? .plateVermilion : .amber }
    /// Lime, amber and magenta words don't read on bone, and the plate has one accent: on paper they are ink.
    func signal(_ colour: Color) -> Color { paper ? .ink : colour }
    /// Neon glows; paper has none.
    func glow(_ colour: Color) -> Color { paper ? .clear : colour }
    /// The text of the line under the tank: the stipulation, set in a serif on paper.
    var caption: Font { paper ? .system(size: 15, design: .serif) : .mono(12) }
    /// A finger the harness draws: white on black, ink on paper.
    func finger(diameter d: CGFloat) -> some View {
        Circle().fill(paper ? Color.ink.opacity(0.12) : Color.white.opacity(0.28))
            .overlay(Circle().stroke(paper ? Color.ink.opacity(0.8) : Color.white.opacity(0.7), lineWidth: paper ? 1.5 : 1))
            .frame(width: d, height: d)
    }

    /// The solve wave on paper: the shader's band only brightens what is lit, which on bone runs white, so an ink ring
    /// runs out instead, `w` its radius in tank units as the shader's, over `r` the glass's radius.
    @ViewBuilder func wave(_ w: Double, at c: CGPoint, r: CGFloat) -> some View {
        if paper && w > 0 && w < 1.9 {
            let e = w / 1.9
            ZStack {
                Circle().stroke(Color.ink.opacity(0.7 * (1 - e)), lineWidth: 2)
                    .frame(width: 2 * w * r, height: 2 * w * r)
                Circle().stroke(Color.ink.opacity(0.4 * (1 - e)), lineWidth: 1)
                    .frame(width: 1.7 * w * r, height: 1.7 * w * r)
            }
            .position(c)
            .allowsHitTesting(false)
        }
    }
}

extension EnvironmentValues {
    @Entry var page = Page.night
}

extension Level {
    var page: Page { pack == .escapement ? .book : .night }
}

extension Picture {
    /// Drawn on paper, ink on bone: Escapement's plate.
    var paper: Bool { self == .engineTurned }
    /// What shows before the bake lands, and under its fade.
    var ground: Color { paper ? .bone : .black }

    /// Escapement's plate (the packs mock-up's): engine-turning engraved in ink on bone paper, straight rays fanned from a
    /// point off the glass's lower left, whose cone just holds the glass, over barleycorn, upward chevrons on a lattice
    /// whose odd rows are shifted half a cell. Rays and chevrons both read up in every core, and nothing is concentric.
    /// Lines are at least 2.2 px wide: the shader's four taps average in squared light, which thins dark lines on a light
    /// ground. No glow. Below a 230 px radius (a dock cover's is 99) the lines would fill a chevron's half-width, so the
    /// lattice and the rays' spacing grow until it holds 1.7 lines: the plate in miniature, not ink.
    static func engineTurning(_ ctx: GraphicsContext, r: CGFloat, scale: CGFloat) {
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r + x * r, y: r + y * r) }
        ctx.fill(Path(CGRect(x: 0, y: 0, width: 2 * r, height: 2 * r)), with: .color(.bone))
        let width = max(0.005 * r, 2.2 / scale)
        let coarse = max(1, 1.7 * width / (0.015 * r))
        let from = SIMD2(-1.6, 1.4), rays = Int((90 / coarse).rounded())
        let first = -69.2 * Double.pi / 180, last = -13.1 * Double.pi / 180
        var lines = Path()
        for i in 0..<rays {
            let a = first + (last - first) * Double(i) / Double(rays - 1)
            lines.move(to: p(from.x, from.y))
            lines.addLine(to: p(from.x + 4 * cos(a), from.y + 4 * sin(a)))
        }
        let lattice = 0.08 * coarse, cells = Int(1 / lattice) + 1
        for j in -cells...cells {
            let off = j & 1 == 1 ? lattice / 2 : 0
            for i in -cells...cells {
                let x = Double(i) * lattice + off, y = Double(j) * lattice
                guard x * x + y * y < 1.1 else { continue }
                let w = 0.015 * coarse, h = 0.0075 * coarse
                lines.move(to: p(x - w, y + h))
                lines.addLine(to: p(x, y - h))
                lines.addLine(to: p(x + w, y + h))
            }
        }
        ctx.stroke(lines, with: .color(.ink), style: StrokeStyle(lineWidth: width, lineCap: .butt, lineJoin: .miter))
    }
}
