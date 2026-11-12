// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import UIKit

/// A frost day's seized knobs drawn frozen, in place of maelstrom's dull cap and red slash: a glazed cap, and over the
/// knob's whole disc a sheet of frosted glass (`FrostDisc`), which thaws away when the solve lands.
enum FrostLook {
    /// UNSTIR_FROSTLOOK=jammed draws a frost day's seized knobs as maelstrom's, for a shot beside the frozen ones.
    static let on = ProcessInfo.processInfo.environment["UNSTIR_FROSTLOOK"] != "jammed"

    static let ice = Color(0xBFE8FF)
    static let glazed = [(0, 0xFFFFFF), (0.18, 0xD4EEFC), (0.55, 0x6FA3C4), (1, 0x1F3A4E)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }
    /// The seconds the ice takes to melt off once the solve lands, and to dissolve under Reduce Motion.
    static let thaw = 0.8, dissolve = 0.3

    private struct Key: Hashable { let side, core, knob: Int }
    @MainActor private static var baked: [Key: UIImage] = [:]

    /// The sheet of ice over a disc of `radius` points round a cap `core` wide, baked once for each size and knob: a
    /// still tank, a drag and a turn all draw the kept image.
    @MainActor static func sheet(radius: CGFloat, core: CGFloat, knob: Int, scale: CGFloat) -> UIImage {
        let key = Key(side: Int((2 * radius * scale).rounded()), core: Int((core * scale).rounded()), knob: knob)
        if let image = baked[key] { return image }
        // A rotation or a new glass asks for other sizes: the old ones go.
        if baked.count >= 8 { baked.removeAll() }
        let image = bake(radius: radius, core: core, knob: knob, scale: scale)
        baked[key] = image
        return image
    }

    /// Frost as it grows on a watch glass, seeded by the knob so every launch draws the same crystals: a thin milk that
    /// thickens to the rim, mottled; feathered crystals grown in from the rim, most short and a few reaching half way
    /// to the cap; a crust of needles and a scatter of glints at the rim; and the glass's cold edge with the light
    /// caught high on its left. The middle stays almost clear, so the picture under it reads.
    static func bake(radius: CGFloat, core: CGFloat, knob: Int, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let side = 2 * radius, rect = CGRect(x: 0, y: 0, width: side, height: side)
        return UIGraphicsImageRenderer(size: rect.size, format: format).image { renderer in
            let g = renderer.cgContext, c = CGPoint(x: radius, y: radius), rgb = CGColorSpaceCreateDeviceRGB()
            var rng = SplitMix64(state: UInt64(knob + 1) &* 0x9E37_79B9 &+ 0xF205)
            func unit() -> CGFloat { CGFloat(rng.next() >> 11) / CGFloat(1 << 53) }
            func at(_ r: CGFloat, _ a: CGFloat, from o: CGPoint) -> CGPoint { CGPoint(x: o.x + r * cos(a), y: o.y + r * sin(a)) }
            func radial(_ stops: [(CGFloat, UIColor)]) {
                let gradient = CGGradient(colorsSpace: rgb, colors: stops.map(\.1.cgColor) as CFArray, locations: stops.map(\.0))!
                g.drawRadialGradient(gradient, startCenter: c, startRadius: 0, endCenter: c, endRadius: radius, options: [])
            }
            let ice = UIColor(red: 0.75, green: 0.91, blue: 1, alpha: 1), white = UIColor.white
            g.addEllipse(in: rect)
            g.clip()

            radial([(0, ice.withAlphaComponent(0.04)), (0.55, ice.withAlphaComponent(0.07)), (0.82, ice.withAlphaComponent(0.14)),
                    (1, ice.withAlphaComponent(0.34))])

            // The milk's mottle: two octaves of value noise, let through where it runs high and thickest at the rim.
            let n = 64
            let coarse = (0..<81).map { _ in unit() }, fine = (0..<1089).map { _ in unit() }
            func lattice(_ v: [CGFloat], _ cells: Int, _ x: Int, _ y: Int) -> CGFloat {
                let fx = CGFloat(x) * CGFloat(cells) / CGFloat(n), fy = CGFloat(y) * CGFloat(cells) / CGFloat(n)
                let i = min(Int(fx), cells - 1), j = min(Int(fy), cells - 1), u = fx - CGFloat(i), w = fy - CGFloat(j)
                func p(_ i: Int, _ j: Int) -> CGFloat { v[j * (cells + 1) + i] }
                return (p(i, j) * (1 - u) + p(i + 1, j) * u) * (1 - w) + (p(i, j + 1) * (1 - u) + p(i + 1, j + 1) * u) * w
            }
            var bytes = [UInt8](repeating: 0, count: n * n)
            for y in 0..<n {
                for x in 0..<n {
                    let v = 0.55 * lattice(coarse, 8, x, y) + 0.45 * lattice(fine, 32, x, y)
                    let t = min(max((v - 0.42) / 0.3, 0), 1)
                    bytes[y * n + x] = UInt8(255 * t * t * (3 - 2 * t))
                }
            }
            if let provider = CGDataProvider(data: Data(bytes) as CFData),
               let mask = CGImage(width: n, height: n, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: n,
                                  space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider,
                                  decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
                g.saveGState()
                g.interpolationQuality = .high
                g.clip(to: rect, mask: mask)
                radial([(0.35, white.withAlphaComponent(0)), (0.75, white.withAlphaComponent(0.12)), (1, white.withAlphaComponent(0.42))])
                g.restoreGState()
            }

            // Crystals by rank: stems, their branches and the branches' barbs, each rank finer and fainter.
            let ranks = [CGMutablePath(), CGMutablePath(), CGMutablePath()]
            func grow(_ o: CGPoint, _ a: CGFloat, _ length: CGFloat, rank: Int) {
                let bend = (unit() - 0.5) * 0.6, steps = max(Int(length / 2.6), 2)
                var p = o, tips: [(CGPoint, CGFloat, CGFloat)] = []
                ranks[rank].move(to: p)
                for s in 1...steps {
                    let t = CGFloat(s) / CGFloat(steps), dir = a + bend * t
                    p = at(length / CGFloat(steps), dir, from: p)
                    ranks[rank].addLine(to: p)
                    if rank < 2, s < steps {
                        let reach = length * (rank == 0 ? 0.4 : 0.45) * (1 - 0.85 * t) * (0.6 + 0.4 * unit())
                        for turn in [CGFloat(0.85), -0.85] where reach > 1.5 { tips.append((p, dir + turn + (unit() - 0.5) * 0.2, reach)) }
                    }
                }
                for (p, dir, reach) in tips { grow(p, dir, reach, rank: rank + 1) }
            }
            let stems = Int(2 * .pi * radius / 6)
            // The rime runs thick in some stretches of the rim and thin in others, and the long ferns grow from the thick.
            let patches = (0..<10).map { _ in unit() }
            for i in 0..<stems {
                let turn = (CGFloat(i) + unit() * 0.8) / CGFloat(stems), a = turn * 2 * .pi
                let at10 = turn * 10, i0 = Int(at10) % 10, f = at10 - at10.rounded(.down), ease = f * f * (3 - 2 * f)
                let thick = patches[i0] * (1 - ease) + patches[(i0 + 1) % 10] * ease
                let far = unit(), long = unit() < 0.06 + 0.32 * thick * thick
                grow(at(radius - 1, a, from: c), a + .pi + (unit() - 0.5) * 1.3,
                     radius * (long ? 0.2 + 0.3 * far * thick : (0.045 + 0.15 * thick) * (0.4 + 0.6 * far)), rank: 0)
            }
            let crust = CGMutablePath()
            for i in 0..<Int(2 * .pi * radius / 2.5) {
                let a = (CGFloat(i) + unit()) * 2 * .pi / (2 * .pi * radius / 2.5), o = at(radius, a, from: c)
                crust.move(to: o)
                crust.addLine(to: at(2 + 7 * unit() * unit(), a + .pi + (unit() - 0.5) * 1.1, from: o))
            }
            g.setLineCap(.round)
            g.setLineJoin(.round)
            func stroke(_ path: CGPath, _ width: CGFloat, _ color: UIColor) {
                g.addPath(path)
                g.setLineWidth(width)
                g.setStrokeColor(color.cgColor)
                g.strokePath()
            }
            // Each crystal's bloom on the glass, under it.
            stroke(ranks[0], 6, ice.withAlphaComponent(0.07))
            stroke(ranks[1], 3, ice.withAlphaComponent(0.07))
            stroke(crust, 0.7, white.withAlphaComponent(0.45))
            stroke(ranks[2], 0.5, white.withAlphaComponent(0.42))
            stroke(ranks[1], 0.7, white.withAlphaComponent(0.6))
            stroke(ranks[0], 1, white.withAlphaComponent(0.8))

            // Ground-glass grain over the whole sheet, then the glints, gathered at the rim.
            for _ in 0..<Int(radius * radius / 5) {
                let p = at(radius * sqrt(0.06 + 0.94 * unit()), unit() * 2 * .pi, from: c), d = 0.4 + 0.4 * unit()
                g.setFillColor(white.withAlphaComponent(0.08 + 0.16 * unit()).cgColor)
                g.fillEllipse(in: CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d))
            }
            for _ in 0..<Int(radius * radius / 40) {
                let u = unit(), p = at(radius * (1 - 0.42 * u * u), unit() * 2 * .pi, from: c), d = 0.5 + 0.9 * unit() * unit()
                g.setFillColor(white.withAlphaComponent(0.25 + 0.55 * unit()).cgColor)
                g.fillEllipse(in: CGRect(x: p.x - d / 2, y: p.y - d / 2, width: d, height: d))
            }

            func ring(inset: CGFloat, _ width: CGFloat, _ color: UIColor, from: CGFloat = 0, to: CGFloat = 2 * .pi) {
                let arc = CGMutablePath()
                arc.addArc(center: c, radius: radius - inset, startAngle: from, endAngle: to, clockwise: false)
                stroke(arc, width, color)
            }
            ring(inset: 3.5, 7, ice.withAlphaComponent(0.13))
            ring(inset: 0.75, 1.5, ice.withAlphaComponent(0.95))
            ring(inset: 5.5, 2.2, white.withAlphaComponent(0.7), from: .pi * 1.1, to: .pi * 1.42)
            ring(inset: 5.5, 1.4, white.withAlphaComponent(0.3), from: .pi * 0.16, to: .pi * 0.3)
        }
    }
}

extension Level {
    /// A frost day's daily: its seized knobs are frozen, not jammed.
    var frosty: Bool { FrostLook.on && id.hasPrefix("daily-") && !seized.isEmpty }
}

/// A frozen knob's cap over its glaze, turning with the cap: the gloss high on it, where the light falls, and a rim of ice.
struct FrostCap: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: size * 0.55, height: size * 0.3).offset(x: -size * 0.1, y: -size * 0.22)
            Circle().strokeBorder(FrostLook.ice.opacity(0.9), lineWidth: 1).padding(1.5)
        }
    }
}

/// The ice over a frozen knob's disc, upright in the frame as the tank turns under it. `thaw` runs 0 to 1 as it melts:
/// clear from the cap outwards, the rim's crystals last, or with `still` (Reduce Motion) a plain dissolve. At rest it
/// is the baked image alone, with no mask or effect to redraw.
struct FrostDisc: View, Animatable {
    let radius: CGFloat
    let core: CGFloat
    let knob: Int
    var thaw: Double
    var still = false
    @Environment(\.displayScale) private var scale

    nonisolated var animatableData: Double {
        get { thaw }
        set { thaw = newValue }
    }

    var body: some View {
        if thaw < 1 {
            let sheet = Image(uiImage: FrostLook.sheet(radius: radius, core: core, knob: knob, scale: scale))
                .frame(width: 2 * radius, height: 2 * radius)
            if thaw <= 0 {
                sheet.transition(.identity)
            } else if still {
                sheet.opacity(1 - thaw).transition(.identity)
            } else {
                let front = thaw * 1.25
                sheet.mask(RadialGradient(stops: [.init(color: .clear, location: min(max(front - 0.25, 0), 1)),
                                                  .init(color: .black, location: min(front, 1))],
                                          center: .center, startRadius: 0, endRadius: radius))
                    .opacity(1 - pow(thaw, 4)).transition(.identity)
            }
        }
    }
}
