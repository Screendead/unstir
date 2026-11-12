// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import UIKit

/// A frost day's seized knobs drawn frozen, in place of maelstrom's dull cap and red slash: a glazed cap, and over the
/// knobs' discs one pane of frosted glass (`FrostPane`), which thaws away when the solve lands.
enum FrostLook {
    /// UNSTIR_FROSTLOOK=jammed draws a frost day's seized knobs as maelstrom's, for a shot beside the frozen ones.
    static let on = ProcessInfo.processInfo.environment["UNSTIR_FROSTLOOK"] != "jammed"

    static let ice = Color(0xBFE8FF)
    static let glazed = [(0, 0xFFFFFF), (0.18, 0xD4EEFC), (0.55, 0x6FA3C4), (1, 0x1F3A4E)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }
    /// The seconds the ice takes to melt off once the solve lands, and to dissolve under Reduce Motion.
    static let thaw = 0.8, dissolve = 0.3

    /// A frozen knob's disc in the tank's frame, in points.
    struct Disc: Hashable, Sendable {
        let x, y, r: CGFloat
        var centre: CGPoint { CGPoint(x: x, y: y) }
    }

    private struct Key: Hashable, Sendable {
        let discs: [Disc]
        let seed: Int
        let scale: CGFloat
    }
    @MainActor private static var baked: (key: Key, image: UIImage)?

    /// The box round `discs`, which the pane's image fills.
    static func bounds(_ discs: [Disc]) -> CGRect {
        discs.reduce(CGRect.null) { $0.union(CGRect(x: $1.x - $1.r, y: $1.y - $1.r, width: 2 * $1.r, height: 2 * $1.r)) }.integral
    }

    /// The pane of ice over `discs`, baked once for a level on a glass, off the main actor, and kept: a still tank, a
    /// drag and a turn all draw the kept image.
    @MainActor static func pane(_ discs: [Disc], seed: Int, scale: CGFloat) async -> UIImage {
        let key = Key(discs: discs, seed: seed, scale: scale)
        if let baked, baked.key == key { return baked.image }
        let image = await Task.detached(priority: .userInitiated) { bake(discs, seed: seed, scale: scale) }.value
        baked = (key, image)
        return image
    }

    /// The kept pane, if it is the one asked for.
    @MainActor static func kept(_ discs: [Disc], seed: Int, scale: CGFloat) -> UIImage? {
        baked.flatMap { $0.key == Key(discs: discs, seed: seed, scale: scale) ? $0.image : nil }
    }

    /// Frost as it grows on a watch glass, one pane over the discs' union and seeded, so every launch draws the same
    /// crystals: breath frozen to a milk that is thick and mottled at the pane's edge and thins to a faint even veil in
    /// the middle, where the picture reads; hairline dendrites grown in from the edge, branching and fanning unevenly,
    /// most of them filigree a few points long, a few feathers reaching towards a cap, the rime thick in some stretches
    /// of the edge and thin in others; loose needles through the milk, a ground-glass grain, and the pane's cold edge.
    /// Where discs overlap nothing grows and no edge is drawn: the ice is one sheet.
    static func bake(_ discs: [Disc], seed: Int, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let box = bounds(discs)
        return UIGraphicsImageRenderer(size: box.size, format: format).image { renderer in
            let g = renderer.cgContext
            var rng = SplitMix64(state: UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9 &+ 0xF205)
            func unit() -> CGFloat { CGFloat(rng.next() >> 11) / CGFloat(1 << 53) }
            func at(_ r: CGFloat, _ a: CGFloat, from o: CGPoint) -> CGPoint { CGPoint(x: o.x + r * cos(a), y: o.y + r * sin(a)) }
            /// How far `p` is from the pane's edge towards a cap: 1 on the edge (and beyond), 0 at a disc's centre.
            func edge(_ p: CGPoint) -> CGFloat {
                discs.map { 1 - max($0.r - hypot(p.x - $0.x, p.y - $0.y), 0) / $0.r }.min() ?? 1
            }
            func covered(_ p: CGPoint, but k: Int) -> Bool {
                discs.indices.contains { $0 != k && hypot(p.x - discs[$0].x, p.y - discs[$0].y) < discs[$0].r - 0.5 }
            }
            let salt = rng.next()
            func lattice(_ x: Int, _ y: Int) -> CGFloat {
                var z = UInt64(truncatingIfNeeded: x) &* 0x9E37_79B9_7F4A_7C15 ^ UInt64(truncatingIfNeeded: y) &* 0xC2B2_AE3D_27D4_EB4F ^ salt
                z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
                z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
                return CGFloat((z ^ (z >> 31)) >> 11) / CGFloat(1 << 53)
            }
            func noise(_ p: CGPoint, _ cell: CGFloat) -> CGFloat {
                let fx = p.x / cell, fy = p.y / cell, i = Int(fx.rounded(.down)), j = Int(fy.rounded(.down))
                var u = fx - CGFloat(i), w = fy - CGFloat(j)
                u = u * u * (3 - 2 * u); w = w * w * (3 - 2 * w)
                return (lattice(i, j) * (1 - u) + lattice(i + 1, j) * u) * (1 - w) + (lattice(i, j + 1) * (1 - u) + lattice(i + 1, j + 1) * u) * w
            }
            let ice = UIColor(red: 0.78, green: 0.92, blue: 1, alpha: 1), white = UIColor.white
            g.translateBy(x: -box.minX, y: -box.minY)
            for d in discs { g.addEllipse(in: CGRect(x: d.x - d.r, y: d.y - d.r, width: 2 * d.r, height: 2 * d.r)) }
            g.clip()

            // The milk, worked out coarsely and drawn smoothed: the pane's own clip keeps its edge crisp.
            let pitch: CGFloat = 1.5, w = Int((box.width / pitch).rounded(.up)), h = Int((box.height / pitch).rounded(.up))
            var milk = [UInt8](repeating: 0, count: w * h * 4)
            for y in 0..<h {
                for x in 0..<w {
                    let p = CGPoint(x: box.minX + (CGFloat(x) + 0.5) * pitch, y: box.minY + (CGFloat(y) + 0.5) * pitch)
                    let t = min(max((edge(p) - 0.42) / 0.58, 0), 1), rim = pow(t * t * (3 - 2 * t), 1.5)
                    let mottle = 0.5 * noise(p, 26) + 0.3 * noise(p, 9) + 0.2 * noise(p, 3.5)
                    let a = min(0.075 + 0.05 * mottle + 0.44 * rim * (0.45 + 1.1 * mottle), 0.58)
                    let i = (y * w + x) * 4
                    milk[i] = UInt8(255 * 0.84 * a); milk[i + 1] = UInt8(255 * 0.94 * a); milk[i + 2] = UInt8(255 * a); milk[i + 3] = UInt8(255 * a)
                }
            }
            if let provider = CGDataProvider(data: Data(milk) as CFData),
               let image = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                                   space: CGColorSpaceCreateDeviceRGB(),
                                   bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue), provider: provider,
                                   decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
                g.saveGState()
                g.interpolationQuality = .high
                // The image's first row is the top one, and a context draws an image bottom up.
                g.translateBy(x: box.minX, y: box.minY + CGFloat(h) * pitch)
                g.scaleBy(x: 1, y: -1)
                g.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(w) * pitch, height: CGFloat(h) * pitch))
                g.restoreGState()
            }

            // Strokes by weight, heaviest first: a feather's spine, then ever finer and fainter hairlines.
            let weights: [(CGFloat, UIColor)] = [(0.9, white.withAlphaComponent(0.78)), (0.65, white.withAlphaComponent(0.66)),
                                                 (0.55, ice.withAlphaComponent(0.6)), (0.48, white.withAlphaComponent(0.48)),
                                                 (0.42, ice.withAlphaComponent(0.42)), (0.36, white.withAlphaComponent(0.32))]
            let strokes = weights.map { _ in CGMutablePath() }
            func grow(_ o: CGPoint, _ a: CGFloat, _ length: CGFloat, rank: Int) {
                let weight = min(rank + Int(unit() * 3), weights.count - 1), steps = max(Int(length / 1.8), 1)
                var p = o, dir = a, buds: [(CGPoint, CGFloat, CGFloat)] = []
                strokes[weight].move(to: p)
                for s in 1...steps {
                    dir += (unit() - 0.5) * 0.14
                    p = at(length / CGFloat(steps), dir, from: p)
                    strokes[weight].addLine(to: p)
                    // A spine and its branches bud on both sides at once, close set, which feathers them; the rest fork.
                    for side in [CGFloat(1), -1] where rank < 4 && unit() < (rank < 2 ? 0.72 : 0.24) {
                        let reach = length * (1 - 0.8 * CGFloat(s) / CGFloat(steps)) * (rank < 2 ? 0.14 + 0.26 * unit() : 0.2 + 0.4 * unit())
                        if reach > 1.1 { buds.append((p, dir + side * (0.8 + 0.35 * unit()), reach)) }
                    }
                }
                for (p, dir, reach) in buds { grow(p, dir, reach, rank: rank + 1) }
            }
            for (k, d) in discs.enumerated() {
                let patches = (0..<12).map { _ in unit() }, seeds = Int(2 * .pi * d.r / 1.6)
                for i in 0..<seeds {
                    let turn = (CGFloat(i) + unit()) / CGFloat(seeds), a = turn * 2 * .pi, o = at(d.r - 0.5, a, from: d.centre)
                    let at12 = turn * 12, i0 = Int(at12) % 12, f = at12 - at12.rounded(.down), ease = f * f * (3 - 2 * f)
                    let thick = patches[i0] * (1 - ease) + patches[(i0 + 1) % 12] * ease
                    let far = unit(), feather = unit() < 0.01 + 0.05 * thick * thick, lean = (unit() - 0.5) * 1.3
                    if covered(o, but: k) { continue }
                    grow(o, a + .pi + lean, d.r * (feather ? 0.16 + 0.3 * far * thick : 0.03 + 0.19 * thick * far * far),
                         rank: feather ? 0 : 1 + Int(unit() * 2))
                }
                // Loose needles lying in the milk, any way round, crowding towards the edge.
                for _ in 0..<Int(d.r * d.r / 2.2) {
                    let u = unit(), o = at(d.r * (1 - 0.6 * u * u), unit() * 2 * .pi, from: d.centre), e = edge(o), keep = unit()
                    let end = at(0.7 + 1.8 * unit() * unit(), unit() * 2 * .pi, from: o), weight = 3 + Int(unit() * 3)
                    if e < 0.58 || keep > e * e * e * e * 1.4 || covered(o, but: k) && hypot(o.x - d.x, o.y - d.y) > d.r * 0.5 && keep > 0.5 { continue }
                    strokes[weight].move(to: o)
                    strokes[weight].addLine(to: end)
                }
            }
            g.setLineCap(.round)
            g.setLineJoin(.round)
            for (path, weight) in zip(strokes, weights).reversed() {
                g.addPath(path)
                g.setLineWidth(weight.0)
                g.setStrokeColor(weight.1.cgColor)
                g.strokePath()
            }

            // Ground-glass grain over the whole pane, and a few glints at its edge.
            for d in discs {
                for i in 0..<Int(d.r * d.r / 3.2) {
                    let glint = i % 40 == 0, u = unit()
                    let p = at(d.r * (glint ? 1 - 0.3 * u * u : sqrt(0.02 + 0.98 * u)), unit() * 2 * .pi, from: d.centre)
                    let across = glint ? 0.7 + 0.6 * unit() : 0.35 + 0.35 * unit()
                    g.setFillColor(white.withAlphaComponent(glint ? 0.4 + 0.4 * unit() : 0.07 + 0.15 * unit()).cgColor)
                    g.fillEllipse(in: CGRect(x: p.x - across / 2, y: p.y - across / 2, width: across, height: across))
                }
            }

            // The pane's edge: each disc's rim where no other disc covers it.
            for (k, d) in discs.enumerated() {
                g.saveGState()
                for (j, other) in discs.enumerated() where j != k {
                    g.addRect(box.insetBy(dx: -8, dy: -8))
                    g.addEllipse(in: CGRect(x: other.x - other.r, y: other.y - other.r, width: 2 * other.r, height: 2 * other.r))
                    g.clip(using: .evenOdd)
                }
                for (inset, width, color) in [(3, 6, ice.withAlphaComponent(0.1)), (0.6, 1.2, ice.withAlphaComponent(0.85))] as [(CGFloat, CGFloat, UIColor)] {
                    g.addEllipse(in: CGRect(x: d.x - d.r, y: d.y - d.r, width: 2 * d.r, height: 2 * d.r).insetBy(dx: inset, dy: inset))
                    g.setLineWidth(width)
                    g.setStrokeColor(color.cgColor)
                    g.strokePath()
                }
                g.restoreGState()
            }
        }
    }
}

extension Level {
    /// A frost day's daily: its seized knobs are frozen, not jammed.
    var frosty: Bool { FrostLook.on && id.hasPrefix("daily-") && !seized.isEmpty }
    /// The seed of its ice, from its id, so each frost day grows its own crystals, the same on every phone.
    var frostSeed: Int { id.utf8.reduce(5381) { ($0 &* 33) ^ Int($1) } }
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

/// The ice over a frost day's frozen discs, one pane over their union, still in the frame with its knobs as the tank's
/// picture turns under it. `thaw` runs 0 to 1 as it melts: clear from each cap outwards, the edge's crystals last, or
/// with `still` (Reduce Motion) a plain dissolve. At rest it is the baked image alone, with no mask or effect to redraw.
struct FrostPane: View, Animatable {
    let discs: [FrostLook.Disc]
    let seed: Int
    var thaw: Double
    var still = false
    @Environment(\.displayScale) private var scale
    /// The pane once baked, with the discs it covers: a level's first frames draw none.
    @State private var baked: (discs: [FrostLook.Disc], image: UIImage)?

    nonisolated var animatableData: Double {
        get { thaw }
        set { thaw = newValue }
    }

    var body: some View {
        if discs.isEmpty {
            EmptyView()
        } else if thaw < 1, let image = baked?.discs == discs ? baked?.image : FrostLook.kept(discs, seed: seed, scale: scale) {
            let box = FrostLook.bounds(discs)
            let pane = Image(uiImage: image).frame(width: box.width, height: box.height)
            Group {
                if thaw <= 0 {
                    pane.transition(.identity)
                } else if still {
                    pane.opacity(1 - thaw).transition(.identity)
                } else {
                    let front = thaw * 1.25
                    let melt = [Gradient.Stop(color: .clear, location: min(max(front - 0.25, 0), 1)),
                                Gradient.Stop(color: .black, location: min(front, 1))]
                    pane.mask {
                        ZStack {
                            ForEach(discs, id: \.self) { d in
                                Circle().fill(RadialGradient(stops: melt, center: .center, startRadius: 0, endRadius: d.r))
                                    .frame(width: 2 * d.r, height: 2 * d.r).position(x: d.x - box.minX, y: d.y - box.minY)
                            }
                        }
                    }
                    .opacity(1 - pow(thaw, 4)).transition(.identity)
                }
            }
            .position(x: box.midX, y: box.midY)
        } else {
            Color.clear.task(id: discs) {
                baked = (discs, await FrostLook.pane(discs, seed: seed, scale: scale))
            }
        }
    }
}
