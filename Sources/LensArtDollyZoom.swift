// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation
import simd

// Lens's panels for levels 62 to 67, the chapter Dolly zoom.

extension LensArt {
    /// This chapter's drawn panels by their level's number.
    static let dollyZoom: [Int: Halftone.Panel] = [62: loupe, 63: stereoscope, 64: ophthalmoscope, 65: sextant, 66: theodolite, 67: spectroscope]

    /// A frame's tone from its last band's end, in degrees clockwise from three o'clock, up to `end`.
    fileprivate struct Band: Sendable {
        var end: Double
        var tone: Tone
    }

    /// A lens's glass, a flat tone out to `glass`, in a frame out to `rim` whose tone changes along it, so a neighbour's
    /// twist that slides the rim along itself shows. Both stay inside the core: hex's cores are 0.032 apart.
    fileprivate struct Glass: Sendable {
        var centre: P
        var glass: Double
        var rim: Double
        var tone: Tone
        var bands: [Band]

        func tone(at p: P) -> Tone? {
            let d = p - centre, r2 = simd_length_squared(d)
            guard r2 < rim * rim else { return nil }
            if r2 < glass * glass { return tone }
            var a = atan2(d.y, d.x) * 180 / .pi
            if a < 0 { a += 360 }
            for b in bands where a < b.end { return b.tone }
            return bands[0].tone
        }
    }

    fileprivate static func glass(_ centre: P, _ tone: Tone, frame: [(Double, Tone)], glass: Double = 0.2, rim: Double = 0.258) -> Glass {
        Glass(centre: centre, glass: glass, rim: rim, tone: tone, bands: frame.map { Band(end: $0.0, tone: $0.1) })
    }

    /// The glasses first, then the fills, the first that holds a point giving its tone, over `ground`. Each stroke is
    /// cut into pieces of eight segments, so a pixel measures only the pieces whose boxes reach it.
    fileprivate static func drawn(_ name: String, glasses: [Glass], fills: [Fill], strokes: [Halftone.Stroke],
                                  ground: @escaping @Sendable (P) -> Tone) -> Halftone.Panel {
        let short = strokes.flatMap { s in
            stride(from: 0, to: s.points.count - 1, by: 8).map { stroke(Array(s.points[$0...min($0 + 8, s.points.count - 1)]), s.width) }
        }
        return Halftone.Panel(name: name, tones: { p in
            for g in glasses { if let t = g.tone(at: p) { return t } }
            for f in fills where f.holds(p) { return f.tone }
            return ground(p)
        }, strokes: short)
    }

    /// A polygon's edges, stepped every 0.01 so `keep` can cut them where a glass lies over them.
    fileprivate static func edges(_ polygon: [P], _ width: Double, keep: (P) -> Bool) -> [Halftone.Stroke] {
        let q = closed(polygon)
        let line = (1..<q.count).flatMap { j in span(q[j - 1], q[j], max(Int(simd_distance(q[j - 1], q[j]) / 0.01), 1)).dropLast() } + [q[0]]
        return runs(line, width, keep: keep)
    }

    /// A circle in `pieces` arcs of eight segments each.
    fileprivate static func hoop(_ c: P, _ r: Double, _ width: Double, pieces: Int = 6) -> [Halftone.Stroke] {
        [stroke(circle(c, r, 8 * pieces), width)]
    }
}

// MARK: - 62: Loupe

/// Level 62's name: a jeweller's bench on black velvet, a cut diamond side on in the middle, its facets catching the
/// light, a diamond paper folded open at the upper left with loose stones on it, and a gold ring and tweezers below,
/// with four loupes laid over the rest: a folding loupe, its case swung out on its hinge, over the upper right core,
/// and three in black barrels banded in chrome over the top, lower right and lower left. Under them what the jeweller
/// is looking for: a feather of a flaw in a brilliant's table, the anchor of the assay office in its shield, a step-cut
/// emerald and its garden, and 750 struck in its oval inside a band.
extension LensArt {
    static let loupe: Halftone.Panel = {
        let flaw = P(0, -0.56), anchor = P(0.485, -0.28), emerald = P(0.485, 0.28), fineness = P(-0.485, 0.28)
        let chrome = Tone(0.45, 0.45, 0.45), dark = Tone.zero, velvet = c(0.16)
        let glasses = [
            glass(flaw, c(0.6), frame: [(30, chrome), (55, dark), (120, y(0.8)), (150, chrome), (200, dark), (240, chrome), (290, m(0.7)), (320, dark), (360, chrome)]),
            glass(anchor, y(0.75), frame: [(15, chrome), (100, dark), (140, chrome), (330, dark), (360, chrome)]),
            glass(emerald, m(0.55), frame: [(40, chrome), (70, dark), (120, chrome), (150, y(0.8)), (175, dark), (230, chrome), (260, c(0.75)), (300, dark), (360, chrome)]),
            glass(fineness, y(0.5), frame: [(20, chrome), (50, m(0.7)), (75, dark), (150, chrome), (180, dark), (250, c(0.75)), (300, chrome), (320, dark), (360, m(0.7))]),
        ]
        // The diamond side on: its crown's facets and its pavilion's, as (polygon, tone).
        let g = P(0.06, -0.02), w = 0.27
        let table = [g + P(-0.14, -0.13), g + P(0.14, -0.13)], girdle = [g + P(-w, -0.04), g + P(w, -0.04)], culet = g + P(0, 0.3)
        let facets: [([P], Tone)] = [
            ([girdle[0], table[0], g + P(-0.07, -0.04)], c(0.85)), ([table[0], table[1], g + P(0.07, -0.04), g + P(-0.07, -0.04)], chrome),
            ([table[1], girdle[1], g + P(0.07, -0.04)], m(0.5)),
            ([girdle[0], g + P(-0.07, -0.04), culet], c(0.5)), ([g + P(-0.07, -0.04), g + P(0.07, -0.04), culet], c(0.9)),
            ([g + P(0.07, -0.04), girdle[1], culet], Tone(0.5, 0, 0.6)),
        ]
        let paper = [P(-0.98, -0.3), P(-0.52, -0.82), P(-0.12, -0.52), P(-0.52, -0.02)], lining = [P(-0.52, -0.82), P(-0.12, -0.52), P(-0.42, -0.42)]
        let stones = [P(-0.7, -0.36), P(-0.36, -0.3), P(-0.58, -0.6)]
        let gold = P(0.14, 0.62), tongs = [bar(P(-0.34, 0.98), P(-0.04, 0.42), 0.05), bar(P(-0.22, 1.0), P(0.0, 0.44), 0.05)]
        let folder = anchor + P(0.28, -0.2)
        var fills = facets.map { fill($0.0, $0.1) } + stones.map { disc($0, 0.035, c(0.85)) }
        fills += [fill(lining, c(0.7)), fill(paper, chrome), disc(gold + P(0.0, -0.16), 0.04, c(0.85)), ring(gold, 0.09, 0.15, y(0.85)),
                  disc(folder, 0.14, chrome)] + tongs.map { fill($0, chrome) }

        var s: [Halftone.Stroke] = []
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        // The diamond's facet edges and its fire.
        for (q, _) in facets { s += edges(q, mid, keep: clear) }
        s += glint(g + P(-0.04, -0.09), 0.09, hair) + glint(g + P(0.13, 0.06), 0.06, hair)
        // The paper, its fold and the stones on it; the ring, its stone; the tweezers; the folding loupe's case and hinge.
        s += edges(paper, mid, keep: clear) + runs(span(lining[1], lining[2], 30) + span(lining[2], lining[0], 30), mid, keep: clear)
        for st in stones { s.append(stroke(closed((0..<8).map { polar(st, 0.035, 45 * Double($0) + 22.5) }), mid)) }
        s += hoop(gold, 0.15, mid, pieces: 4) + hoop(gold, 0.09, mid, pieces: 3)
        s.append(stroke(closed((0..<8).map { polar(gold + P(0, -0.16), 0.04, 45 * Double($0) + 22.5) }), mid))
        for q in tongs { s += edges(q, mid, keep: clear) }
        s += runs(arc(folder, 0.14, 0, 360, 40), bold, keep: clear) + runs(arc(folder, 0.1, 0, 360, 30), hair, keep: clear)
        s.append(stroke(circle(anchor + P(0.2, -0.13), 0.022, 10), mid))
        // Each loupe's barrel.
        for gl in glasses {
            s += hoop(gl.centre, gl.rim, bold)
            s += hoop(gl.centre, gl.glass, mid)
        }
        // A brilliant from above, its table and star facets, and the feather of a flaw in it.
        let b = flaw + P(0.024, -0.016)
        let oct = (0..<8).map { polar(b, 0.05, 45 * Double($0) + 22.5) }, tab = (0..<8).map { polar(b, 0.026, 45 * Double($0)) }
        s.append(stroke(closed(oct), 0.0038))
        s.append(stroke(closed(tab), 0.003))
        for k in 0..<8 { s.append(stroke([tab[k], oct[k], tab[(k + 1) % 8]], 0.0018)) }
        s.append(stroke(curve(b + P(-0.01, 0.012), b + P(0.004, 0.0), b + P(0.016, 0.014), 6), 0.0026))
        for t in [0.3, 0.6] { s.append(stroke([b + P(-0.01 + 0.026 * t, 0.012 - 0.004 * t), b + P(-0.004 + 0.026 * t, 0.022)], 0.0016)) }
        // The anchor in its shield.
        let a = anchor + P(0.026, -0.014)
        s.append(stroke(closed([a + P(-0.04, -0.046), a + P(0.04, -0.046), a + P(0.04, 0.0)] + arc(a + P(0, 0.0), 0.04, 0, 180, 10).dropFirst() + [a + P(-0.04, 0.0)]), 0.0034))
        s.append(stroke([a + P(0, -0.032), a + P(0, 0.03)], 0.0036))
        s += hoop(a + P(0, -0.036), 0.006, 0.0026, pieces: 1)
        s.append(stroke([a + P(-0.016, -0.018), a + P(0.016, -0.018)], 0.003))
        s.append(stroke(arc(a + P(0, 0.008), 0.024, 20, 160, 10), 0.0034))
        // A step-cut emerald, its steps and the garden inside.
        let e = emerald + P(0.026, 0.02)
        for (k, r) in [(0, 0.05), (1, 0.034), (2, 0.018)] {
            let cut = 0.012 - 0.004 * Double(k), h = r * 0.7
            s.append(stroke(closed([e + P(-r + cut, -h), e + P(r - cut, -h), e + P(r, -h + cut), e + P(r, h - cut), e + P(r - cut, h), e + P(-r + cut, h), e + P(-r, h - cut), e + P(-r, -h + cut)]), k == 0 ? 0.0038 : 0.0022))
        }
        s.append(stroke(curve(e + P(-0.03, 0.02), e + P(-0.01, -0.01), e + P(0.02, 0.016), 6), 0.0018))
        // The fineness struck inside a band: 750 in its oval.
        let f = fineness + P(-0.022, -0.024)
        s.append(stroke(ellipse(f, 0.05, 0.026, 24), 0.0034))
        let d = 0.022, h = 0.012, x0 = f.x - 0.034
        s.append(stroke([P(x0, f.y - h), P(x0 + 0.016, f.y - h), P(x0 + 0.006, f.y + h)], 0.003))
        s.append(stroke([P(x0 + d + 0.016, f.y - h), P(x0 + d, f.y - h), P(x0 + d, f.y - 0.002)] + arc(P(x0 + d + 0.007, f.y + 0.004), 0.008, 220, 500, 10).dropFirst(), 0.003))
        s.append(stroke(ellipse(P(x0 + 2 * d + 0.008, f.y), 0.008, h, 12), 0.003))
        return drawn("loupe", glasses: glasses, fills: fills, strokes: s) { _ in velvet }
    }()
}

// MARK: - 63: Stereoscope

/// Level 63's name: a hand stereoscope from above, its hood over the upper left and top cores with an eyepiece in each,
/// its rod running down through the hub to the holder that grips a card of Egypt in its two arched photographs over
/// the lower right and bottom cores, its turned handle down to the lower left, and a second card, of Paris, laid by it
/// over the upper right. What the five lenses show: through the left eyepiece an obelisk, through the right a felucca
/// under sail on the Nile; on the card the pyramid in the sun and a camel; and on the spare the Eiffel
/// tower.
extension LensArt {
    static let stereoscope: Halftone.Panel = {
        let left = P(-0.485, -0.28), right = P(0, -0.56), paris = P(0.485, -0.28), camel = P(0.485, 0.28), pyramid = P(0, 0.56)
        let along = P(0.866, -0.5), across = P(0.5, 0.866), dark = Tone.zero, wood = y(0.65), brass = Tone(0, 0.35, 0.8), paper = Tone(0.4, 0.4, 0.4)
        let hood = (left + right) / 2, card = (camel + pyramid) / 2
        let glasses = [
            glass(left, y(0.8), frame: [(30, brass), (60, dark), (150, brass), (175, paper), (260, brass), (290, dark), (360, brass)]),
            glass(right, c(0.7), frame: [(70, brass), (95, dark), (200, brass), (225, paper), (320, brass), (345, dark), (360, brass)]),
            glass(paris, m(0.65), frame: [(30, y(0.8)), (60, dark), (110, paper), (140, y(0.8)), (175, dark), (205, c(0.7)), (250, paper), (290, dark), (330, y(0.8)), (360, paper)]),
            glass(camel, y(0.5), frame: [(40, paper), (70, dark), (120, m(0.7)), (150, paper), (185, dark), (215, c(0.7)), (250, m(0.7)), (290, paper), (320, dark), (360, m(0.7))]),
            glass(pyramid, m(0.45), frame: [(20, paper), (45, dark), (130, paper), (150, c(0.7)), (250, paper), (280, dark), (360, paper)]),
        ]
        func box(_ c: P, _ u: P, _ half: Double, _ height: Double) -> [P] {
            let v = P(-u.y, u.x) * height
            return [c - u * half - v, c + u * half - v, c + u * half + v, c - u * half + v]
        }
        let mask = squircle(hood, 0.66, 0.32, degrees: -30, 28), cardFace = box(card, along, 0.58, 0.29)
        let spare = box(paris + P(0.03, -0.02), P(cos(0.2), sin(0.2)), 0.38, 0.3)
        let rod = bar(hood, card - across * 0.3, 0.11), joint = hood + across * 0.42, handle = bar(joint, P(-0.62, 0.78), 0.1)
        let knob = P(-0.47, 0.5), slide = card - across * 0.36
        let fills = [disc(joint, 0.07, brass), fill(bar(slide - along * 0.14, slide + along * 0.14, 0.07), brass), disc(knob, 0.085, wood), fill(mask, m(0.6)),
                     fill(rod, wood), fill(handle, wood), fill(cardFace, paper), fill(spare, Tone(0.3, 0.3, 0.3))]

        var s: [Halftone.Stroke] = []
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        // The hood, the rod and its slide, the handle and its turning, the card's edge and the holder's wires, the spare card.
        s += edges(mask, bold, keep: clear)
        s += runs(span(rod[0], rod[1], 40), mid, keep: clear) + runs(span(rod[3], rod[2], 40), mid, keep: clear)
        s.append(stroke(closed(bar(slide - along * 0.14, slide + along * 0.14, 0.07)), mid))
        s += hoop(joint, 0.07, mid, pieces: 2)
        s += runs(span(handle[0], handle[1], 40), mid, keep: clear) + runs(span(handle[3], handle[2], 40), mid, keep: clear)
        s += hoop(knob, 0.085, mid, pieces: 3)
        for t in [0.62, 0.7] { s.append(stroke([joint + (P(-0.62, 0.78) - joint) * t + P(-0.05, -0.03), joint + (P(-0.62, 0.78) - joint) * t + P(0.05, 0.03)], hair)) }
        s += edges(cardFace, bold, keep: clear)
        for side in [-1.0, 1.0] { s += runs(span(slide + along * (0.14 * side), card + along * (0.55 * side) - across * 0.2, 20), mid, keep: clear) }
        s += edges(spare, mid, keep: clear)
        // Each eyepiece's and photograph's rims.
        for g in glasses {
            s += hoop(g.centre, g.rim, bold)
            s += hoop(g.centre, g.glass, mid)
        }
        // Through the left eyepiece: an obelisk, its signs, and the desert's line.
        let ob = left + P(0.026, -0.01)
        s.append(stroke(closed([ob + P(-0.014, 0.05), ob + P(-0.009, -0.04), ob + P(0, -0.056), ob + P(0.009, -0.04), ob + P(0.014, 0.05)]), 0.0036))
        for k in 0..<4 { s.append(stroke([ob + P(-0.004, -0.028 + 0.018 * Double(k)), ob + P(0.004, -0.022 + 0.018 * Double(k))], 0.0022)) }
        s += runs(span(left + P(-0.17, 0.064), left + P(0.17, 0.064), 34), 0.0024) { abs($0.x - ob.x) > 0.016 }
        // Through the right: a felucca under its lateen sail, and the water.
        let fe = right + P(-0.02, 0.0)
        s.append(stroke(curve(fe + P(-0.05, 0.03), fe + P(0, 0.054), fe + P(0.05, 0.026), 10) + [fe + P(-0.05, 0.03)], 0.0036))
        s.append(stroke([fe + P(0.004, 0.034), fe + P(0.004, -0.03)], 0.003))
        s.append(stroke(closed([fe + P(-0.046, 0.02), fe + P(0.05, -0.064), fe + P(0.014, 0.022)]), 0.0032))
        for k in 0..<2 { s.append(stroke(curve(fe + P(-0.06 + 0.05 * Double(k), 0.07), fe + P(-0.045 + 0.05 * Double(k), 0.062), fe + P(-0.03 + 0.05 * Double(k), 0.07), 4), 0.0022)) }
        // On the spare card: the Eiffel tower.
        let ef = paris + P(0.024, 0.004)
        s.append(stroke([ef + P(-0.034, 0.05), ef + P(-0.006, -0.03), ef + P(0, -0.07)], 0.0034))
        s.append(stroke([ef + P(0.034, 0.05), ef + P(0.006, -0.03), ef + P(0, -0.07)], 0.0034))
        s.append(stroke(arc(ef + P(0, 0.05), 0.018, 180, 360, 8), 0.0026))
        for (yy, w) in [(0.016, 0.022), (-0.03, 0.009)] { s.append(stroke([ef + P(-w, yy), ef + P(w, yy)], 0.0026)) }
        s.append(stroke([ef + P(0, -0.07), ef + P(0, -0.084)], 0.002))
        // On the card: the pyramid in the sun, its courses; and a camel.
        let py = pyramid + P(-0.022, -0.016)
        s.append(stroke(closed([py + P(-0.05, 0.03), py + P(0.0, -0.03), py + P(0.05, 0.03)]), 0.0036))
        for k in 1...2 { let yy = -0.03 + 0.02 * Double(k), w = 0.05 * (yy + 0.03) / 0.06; s.append(stroke([py + P(-w, yy), py + P(w, yy)], 0.0018)) }
        s += hoop(py + P(0.05, -0.05), 0.012, 0.003, pieces: 1)
        s += runs(span(pyramid + P(-0.17, 0.014), pyramid + P(0.17, 0.014), 34), 0.0024) { abs($0.x - py.x) > 0.05 }
        let cm = camel + P(0.024, -0.008)
        // Its back over the hump, the neck rising well above it to the head, the belly, the legs in two angled pairs.
        s.append(stroke([cm + P(-0.034, 0.004)] + curve(cm + P(-0.034, 0.004), cm + P(-0.012, -0.044), cm + P(0.01, -0.002), 10)
            + curve(cm + P(0.01, -0.002), cm + P(0.03, -0.006), cm + P(0.032, -0.05), 8) + [cm + P(0.052, -0.046), cm + P(0.05, -0.038), cm + P(0.036, -0.036)], 0.0036))
        s.append(stroke(curve(cm + P(-0.032, 0.006), cm + P(-0.008, 0.016), cm + P(0.022, 0.004), 8) + [cm + P(0.036, -0.03)], 0.003))
        for (a, b) in [(P(-0.026, 0.01), P(-0.036, 0.05)), (P(-0.018, 0.012), P(-0.01, 0.05)), (P(0.008, 0.01), P(0.0, 0.05)), (P(0.016, 0.008), P(0.026, 0.05))] {
            s.append(stroke([cm + a, cm + b], 0.0026))
        }
        s.append(stroke([cm + P(-0.034, 0.004), cm + P(-0.042, 0.026)], 0.002))
        return drawn("stereoscope", glasses: glasses, fills: fills, strokes: s) { _ in c(0.22) }
    }()
}

// MARK: - 64: Ophthalmoscope

/// Level 64's name: an ophthalmoscope face on as the doctor holds it, its wheel of lenses on a knurled handle, a thumb
/// on the wheel's edge by the window that reads its power. Over the hub is its sight hole and the patient's dilated eye
/// in it, a blue iris round a pupil glowing red, and in the red the back of the eye, the optic disc and its vessels.
/// The wheel's three other lenses, over the top, lower right and upper left cores, each focus nearer into the eye: the
/// lashes at the lid's edge, the spokes of a cataract in the eye's lens, and floaters drifting in the vitreous. Over the
/// upper right, which twists, the lamp's window: its bulb lit off to one side and the green filter swung half across.
extension LensArt {
    static let ophthalmoscope: Halftone.Panel = {
        let hole = P(0, 0), lashes = P(0, -0.56), lamp = P(0.485, -0.28), cataract = P(0.485, 0.28), floaters = P(-0.485, -0.28)
        let silver = Tone(0.42, 0.42, 0.42), dark = Tone.zero, wheel = 0.86, neck = (0.3, 0.68)
        let glasses = [
            glass(hole, Tone(0, 0.5, 0.8), frame: [(20, c(0.75)), (45, c(0.45)), (70, c(0.8)), (110, y(0.6)), (140, c(0.45)), (175, c(0.8)),
                                                    (215, c(0.5)), (240, y(0.6)), (280, c(0.8)), (315, c(0.45)), (360, c(0.75))], glass: 0.19),
            glass(lashes, y(0.7), frame: [(60, silver), (90, dark), (200, silver), (230, dark), (360, silver)]),
            glass(cataract, c(0.7), frame: [(60, silver), (100, dark), (125, y(0.85)), (150, silver), (185, m(0.75)), (215, silver), (250, dark), (360, silver)]),
            glass(floaters, c(0.55), frame: [(140, silver), (175, dark), (260, silver), (330, dark), (360, silver)]),
        ]
        let thumb = ellipse(P(-0.66, 0.44), 0.12, 0.2, degrees: 30, 32), readout = rect(-0.36, 0.5, -0.22, 0.6)
        let handle = rect(-0.1, 0.66, 0.16, 1), collar = rect(-0.12, 0.62, 0.18, 0.7), button = P(0.1, 0.82)
        let bulb = lamp + P(0.05, -0.06), filter = lamp + P(-0.07, 0.07)
        let fills = [disc(button, 0.035, m(0.85)), fill(thumb, Tone(0, 0.4, 0.55)), fill(readout, y(0.85)), fill(collar, m(0.75)),
                     disc(bulb, 0.12, y(0.9)), disc(filter, 0.1, Tone(0.6, 0, 0.6)), disc(lamp, 0.22, silver)]

        var s: [Halftone.Stroke] = []
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        // The wheel's edge and its knurling, the handle and its collar, its switch, the thumb and the window it reads by.
        let flank = asin(neck.0 / wheel) * 180 / .pi
        s += runs(arc(hole, wheel, 180 - flank, 360 + flank, 150), bold, keep: clear)
        s += runs(arc(hole, wheel - 0.06, 180 - flank, 360 + flank, 150), hair, keep: clear)
        for side in [-1.0, 1.0] {
            s += runs(span(P(0.03 + side * (0.13 + (wheel - 0.13) * 0.95), neck.0), P(0.03 + side * 0.13, neck.1), 20), bold, keep: clear)
        }
        s.append(stroke([handle[3], handle[0]], mid))
        s.append(stroke([handle[1], handle[2]], mid))
        s.append(stroke(closed(collar), mid))
        s += hoop(button, 0.035, mid, pieces: 2)
        s.append(stroke(closed(thumb), bold))
        s.append(stroke(ellipse(P(-0.595, 0.327), 0.05, 0.068, degrees: 30, 16), mid))
        s.append(stroke(closed(readout), mid))
        s.append(stroke([P(-0.31, 0.53), P(-0.27, 0.53), P(-0.29, 0.55), P(-0.27, 0.565), P(-0.29, 0.58), P(-0.31, 0.575)], hair))
        for g in glasses {
            s += hoop(g.centre, g.rim, bold)
            s += hoop(g.centre, g.glass, mid)
        }
        // In the sight hole, at the back of the eye: the optic disc, its cup, and its vessels branching away.
        let disc0 = hole + P(0.028, -0.012)
        s += hoop(disc0, 0.017, 0.0042, pieces: 2)
        s += hoop(disc0 + P(0.003, 0), 0.007, 0.0022, pieces: 1)
        for (a, l, fork) in [(-110.0, 0.07, -30.0), (-160, 0.06, 25), (150, 0.07, -25), (100, 0.06, 30)] {
            let from = polar(disc0, 0.016, a), mid0 = polar(disc0, l * 0.6, a + 10), end = polar(disc0, l, a - 5)
            s.append(stroke(curve(from, mid0, end, 8), 0.0034))
            s.append(stroke([mid0, polar(mid0, 0.03, a + fork)], 0.0022))
        }
        // The lashes at the lid's edge.
        let lid = lashes + P(-0.006, 0.024)
        s.append(stroke(curve(lid + P(-0.08, 0.012), lid + P(0, -0.024), lid + P(0.08, 0.012), 16), 0.0042))
        for k in -4...4 {
            let t = (Double(k) + 4) / 8, root = (1 - t) * (1 - t) * (lid + P(-0.08, 0.012)) + 2 * (1 - t) * t * (lid + P(0, -0.024)) + t * t * (lid + P(0.08, 0.012))
            s.append(stroke(curve(root, root + P(0.006 * Double(k), -0.03), root + P(0.012 * Double(k) + 0.012, -0.044), 6), 0.0026))
        }
        // The lamp's window: its rim, the bulb and its filament, the filter's disc on its pin.
        s += hoop(lamp, 0.22, bold) + hoop(bulb, 0.12, mid, pieces: 3) + hoop(filter, 0.1, mid, pieces: 3)
        s.append(stroke((0..<7).map { bulb + P(-0.045 + 0.015 * Double($0), $0 % 2 == 0 ? 0.01 : -0.01) }, mid))
        s.append(stroke([bulb + P(-0.045, 0.01), bulb + P(-0.05, 0.07)], hair))
        s.append(stroke([bulb + P(0.045, 0.01), bulb + P(0.05, 0.07)], hair))
        s += hoop(filter + P(-0.05, 0.03), 0.015, mid, pieces: 1)
        // A cataract: the lens's rim and the spokes clouding in from it.
        let lens0 = cataract + P(0.022, -0.02)
        s += hoop(lens0, 0.04, 0.0038, pieces: 3)
        for (a, l) in [(-60.0, 0.022), (10, 0.018), (80, 0.026), (150, 0.016), (215, 0.024)] {
            s.append(stroke([polar(lens0, 0.04, a - 7), polar(lens0, 0.04 - l, a), polar(lens0, 0.04, a + 7)], 0.0026))
        }
        // Floaters: two strands and a few rings, drifting.
        let fl = floaters + P(0.024, -0.016)
        s.append(stroke(curve(fl + P(-0.05, 0.02), fl + P(-0.02, -0.03), fl + P(0.01, 0.0), 10) + curve(fl + P(0.01, 0.0), fl + P(0.04, 0.03), fl + P(0.05, -0.02), 10), 0.0034))
        s.append(stroke(curve(fl + P(-0.03, 0.05), fl + P(0.0, 0.03), fl + P(0.03, 0.06), 10), 0.0026))
        for (at, r) in [(P(-0.04, -0.03), 0.008), (P(0.03, -0.04), 0.006), (P(0.0, 0.07), 0.007), (P(-0.06, 0.05), 0.005)] { s += hoop(fl + at, r, 0.0024, pieces: 1) }
        return drawn("ophthalmoscope", glasses: glasses, fills: fills, strokes: s) { p in
            if p.x > -0.1, p.x < 0.16, p.y > 0.66 { return Int((p.y - 0.66) / 0.04) % 2 == 0 ? silver : Tone(0.15, 0.15, 0.15) }
            // The head, black, narrowing from the wheel's widest to the handle.
            if p.y > neck.0 { return p.y < neck.1 && abs(p.x - 0.03) < 0.13 + (wheel - 0.13) * (neck.1 - p.y) / (neck.1 - neck.0) * 0.95 ? dark : m(0.28) }
            let r2 = simd_length_squared(p)
            if r2 < wheel * wheel {
                // The wheel's edge knurled.
                guard r2 > (wheel - 0.06) * (wheel - 0.06) else { return dark }
                var a = atan2(p.y, p.x) * 180 / .pi
                if a < 0 { a += 360 }
                return Int(a / 6) % 2 == 0 ? silver : dark
            }
            return m(0.28)
        }
    }()
}

// MARK: - 65: Sextant

/// Level 65's name: a brass sextant held up against the sea at sunset, its index arm swung down from the mirror at its
/// apex to the scale along its foot, coloured shades folded out beside the mirror and its telescope across the frame.
/// The five lenses are its glasses: the telescope's eyepiece over the upper right core, where the sun sits on the
/// horizon; the horizon glass over the upper left, half silvered, a ship hull down in its clear half; the reading
/// glass over the scale at the bottom, the vernier on forty degrees; and two holes in the cast frame low on each side,
/// the new moon and a star through the right and an island with its palm through the left.
extension LensArt {
    static let sextant: Halftone.Panel = {
        let pivot = P(0.06, -0.78), spread = 38.0, limb = (1.18, 1.4), sea = -0.05
        let eyepiece = P(0.485, -0.28), horizon = P(-0.485, -0.28), reader = P(0, 0.56), moonHole = P(0.485, 0.28), isleHole = P(-0.485, 0.28)
        let brass = y(0.72), dark = Tone.zero, silver = Tone(0.4, 0.4, 0.4)
        func onArc(_ degrees: Double, _ r: Double) -> P { pivot + r * P(sin(degrees * .pi / 180), cos(degrees * .pi / 180)) }
        let index = bar(pivot, reader, 0.08), tube = bar(P(-0.24, -0.28), P(0.27, -0.28), 0.12)
        let mirror = rect(pivot.x - 0.03, -0.95, pivot.x + 0.16, -0.78), hole = P(-0.17, 0.16), hinge = P(-0.1, -0.72)
        let shadeTones = [(158.0, m(0.85)), (182.0, Tone(0.7, 0, 0.6)), (206.0, c(0.9))]
        let shades = shadeTones.map { bar(polar(hinge, 0.02, $0.0), polar(hinge, 0.27, $0.0), 0.075) }
        let glasses = [
            glass(eyepiece, m(0.7), frame: [(40, dark), (95, silver), (130, dark), (215, silver), (250, dark), (360, y(0.9))]),
            glass(horizon, c(0.8), frame: [(70, brass), (100, m(0.7)), (200, brass), (225, dark), (360, brass)]),
            glass(reader, c(0.72), frame: [(30, dark), (75, brass), (160, dark), (190, y(0.95)), (300, dark), (360, brass)]),
            glass(moonHole, Tone(0.3, 0, 0.1), frame: [(50, silver), (90, dark), (240, silver), (275, dark), (360, silver)]),
            glass(isleHole, Tone(0.45, 0, 0.45), frame: [(120, silver), (150, dark), (290, silver), (320, dark), (360, silver)]),
        ]
        var sun = oval(P(-0.84, sea), 0.13, 0.13, y(0.9))
        sun.hi.y = sea
        let fills = zip(shades, shadeTones).map { fill($0.0, $0.1.1) }
            + [fill(mirror, c(0.75)), disc(pivot, 0.06, dark), fill(tube, dark), fill(index, silver), disc(hole, 0.11, c(0.42)), sun]

        var s: [Halftone.Stroke] = []
        // The frame: its two sides from the apex, the limb along its foot and the limb's scale, and a hole in its casting.
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        for side in [-spread, spread] { s += runs(span(pivot, onArc(side, limb.1), 40), bold, keep: clear) }
        s += runs(arc(pivot, limb.0, 90 - spread, 90 + spread, 120), mid, keep: clear) + runs(arc(pivot, limb.1, 90 - spread, 90 + spread, 120), bold, keep: clear)
        for k in -18...18 {
            let a = 2 * Double(k), long = k % 5 == 0, tick = [onArc(a, limb.1 - 0.02), onArc(a, long ? limb.0 + 0.02 : limb.0 + 0.1)]
            if tick.allSatisfy(clear) { s.append(stroke(tick, long ? mid : hair)) }
        }
        s += hoop(hole, 0.11, mid, pieces: 3)
        // The sea's horizon either side of the frame, the sun setting into it, and swell.
        for side in [-1.0, 1.0] {
            s += runs(span(P(side * 0.4, sea), P(side, sea), 30), mid) { p in simd_distance(p, eyepiece) > 0.26 && simd_distance(p, horizon) > 0.26 }
        }
        s.append(stroke(arc(P(-0.84, sea), 0.13, 180, 360, 12), mid))
        for at in [P(-0.86, 0.12), P(0.84, 0.08), P(-0.74, 0.62), P(0.8, 0.6), P(-0.9, 0.38), P(0.92, 0.32)] {
            s.append(stroke(curve(at + P(-0.05, 0), at + P(-0.025, -0.025), at, 5) + curve(at, at + P(0.025, 0.025), at + P(0.05, 0), 5), hair))
        }
        // The index arm on its pivot, the mirror over it, the shades folded out on their hinge.
        s += edges(index, mid, keep: clear)
        s.append(stroke(closed(mirror), bold))
        s.append(stroke([P(mirror[0].x + 0.04, -0.92), P(mirror[1].x - 0.03, -0.82)], hair))
        for q in shades { s.append(stroke(closed(q), mid)) }
        s += hoop(pivot, 0.06, bold, pieces: 2) + hoop(hinge, 0.025, mid, pieces: 1)
        // The telescope, banded.
        s += edges(tube, mid, keep: clear)
        for x in [-0.14, 0.04, 0.18] { s.append(stroke([P(x, -0.34), P(x, -0.22)], mid)) }
        // Every glass's rims.
        for g in glasses {
            s += hoop(g.centre, g.rim, bold)
            s += hoop(g.centre, g.glass, mid)
        }
        // Through the eyepiece: the sun on the horizon, and a gull.
        let e = eyepiece + P(0.024, -0.004)
        s += runs(span(eyepiece + P(-0.17, 0.012), eyepiece + P(0.17, 0.012), 34), 0.0028) { abs($0.x - e.x) > 0.024 }
        s.append(stroke(arc(e + P(0, 0.016), 0.028, 180, 360, 14), 0.0045))
        for k in 0..<5 { s.append(stroke([polar(e + P(0, 0.016), 0.036, 200 + 35 * Double(k)), polar(e + P(0, 0.016), 0.05, 200 + 35 * Double(k))], 0.003)) }
        for k in 0..<3 { s.append(stroke([e + P(-0.022 + 0.008 * Double(k), 0.024 + 0.008 * Double(k)), e + P(0.022 - 0.008 * Double(k), 0.024 + 0.008 * Double(k))], 0.0024)) }
        s.append(stroke(curve(e + P(-0.07, -0.05), e + P(-0.058, -0.064), e + P(-0.046, -0.05), 5) + curve(e + P(-0.046, -0.05), e + P(-0.034, -0.064), e + P(-0.022, -0.05), 5), 0.0024))
        // Through the horizon glass: the silvered half's edge and, in the clear half, a ship on the horizon.
        let h = horizon + P(-0.028, -0.004)
        s.append(stroke([horizon + P(0.012, -0.17), horizon + P(0.012, 0.17)], 0.0024))
        s += runs(span(horizon + P(-0.17, 0.02), horizon + P(0.012, 0.02), 30), 0.0028) { abs($0.x - h.x) > 0.03 }
        s.append(stroke(closed([h + P(-0.03, 0.012), h + P(0.03, 0.012), h + P(0.022, 0.024), h + P(-0.024, 0.024)]), 0.0034))
        s.append(stroke([h + P(0, 0.012), h + P(0, -0.04)], 0.003))
        s.append(stroke(closed([h + P(0.004, -0.036), h + P(0.026, 0.006), h + P(0.004, 0.006)]), 0.0026))
        s.append(stroke(closed([h + P(-0.004, -0.03), h + P(-0.024, 0.006), h + P(-0.004, 0.006)]), 0.0026))
        // Under the reading glass: the scale's degrees, forty marked, and the vernier's index against it.
        let v = reader + P(-0.006, -0.026)
        s.append(stroke([v + P(-0.07, 0), v + P(0.07, 0)], 0.0024))
        for k in -6...6 { s.append(stroke([v + P(0.011 * Double(k), 0), v + P(0.011 * Double(k), k % 5 == 0 ? -0.022 : -0.012)], 0.002)) }
        for k in -5...5 { s.append(stroke([v + P(0.0099 * Double(k), 0.006), v + P(0.0099 * Double(k), k == 0 ? 0.026 : 0.016)], 0.0018)) }
        let d = v + P(-0.012, -0.05)
        s.append(stroke([d + P(0.004, 0.012), d + P(-0.008, 0.012), d + P(0.0, -0.012), d + P(0.0, 0.018)], 0.0026))
        s.append(stroke(ellipse(d + P(0.022, 0.003), 0.008, 0.015, 14), 0.0026))
        // Through the right hole: the new moon and a star by it.
        let mo = moonHole + P(0.022, -0.018)
        s.append(stroke(arc(mo, 0.03, 60, 300, 18) + arc(mo + P(0.016, 0), 0.026, 240, 120, 14), 0.0038))
        s.append(stroke(star(mo + P(0.05, 0.03), 0.012), 0.0026))
        s.append(stroke(star(mo + P(-0.08, 0.07), 0.008), 0.002))
        // Through the left hole: an island, its palm, and the sea.
        let i = isleHole + P(-0.02, 0.012)
        s.append(stroke(curve(i + P(-0.06, 0.012), i + P(0, -0.024), i + P(0.06, 0.012), 12), 0.0034))
        s += runs(span(isleHole + P(-0.17, 0.024), isleHole + P(0.17, 0.024), 34), 0.0024) { abs($0.x - i.x) > 0.07 }
        s.append(stroke(curve(i + P(0.004, -0.006), i + P(0.014, -0.03), i + P(0.006, -0.056), 6), 0.004))
        for a in [-170.0, -130, -60, -20] { s.append(stroke(curve(i + P(0.006, -0.056), polar(i + P(0.006, -0.056), 0.02, a - 15), polar(i + P(0.006, -0.056), 0.036, a + 25), 6), 0.0034)) }
        return drawn("sextant", glasses: glasses, fills: fills, strokes: s) { p in
            // The frame, a sixth of a circle cast in brass from the apex, its limb inlaid in silver.
            let q = p - pivot, r = simd_length(q)
            if r < limb.1, abs(atan2(q.x, q.y)) < spread * .pi / 180 { return r < limb.0 ? brass : silver }
            return p.y < sea ? m(0.3) : c(0.42)
        }
    }()
}

// MARK: - 66: Theodolite

/// Level 66's name: a surveyor's theodolite on its tripod out on the hills on a sunny morning, its telescope between
/// its two standards at the top, the vertical circle on one side, its base over the hub and the tripod's legs spread
/// below. The five lenses: over the hub, the base's round level, its bubble off
/// the ring; over the upper right, the view down the telescope, the staff on the cross hairs; over the lower right the
/// compass needle and its north; over the bottom, down the plummet, the nail in its peg that marks the station; and
/// over the lower left the next station, a trig pillar on its hill.
extension LensArt {
    static let theodolite: Halftone.Panel = {
        let base = P(0, 0), view = P(0.485, -0.28), compass = P(0.485, 0.28), plummet = P(0, 0.56), pillar = P(-0.485, 0.28)
        let body = m(0.7), dark = Tone.zero, silver = Tone(0.4, 0.4, 0.4), wood = dark, field = y(0.55)
        let glasses = [
            glass(base, c(0.65), frame: [(40, body), (70, dark), (160, body), (185, silver), (300, body), (330, dark), (360, body)]),
            glass(view, y(0.7), frame: [(30, dark), (120, silver), (150, dark), (230, silver), (360, dark)]),
            glass(compass, m(0.5), frame: [(90, dark), (130, silver), (210, dark), (235, c(0.7)), (360, dark)]),
            glass(plummet, c(0.4), frame: [(20, silver), (50, dark), (140, silver), (180, dark), (290, silver), (320, body), (360, silver)]),
            glass(pillar, m(0.6), frame: [(100, dark), (125, silver), (250, dark), (280, m(0.7)), (360, dark)]),
        ]
        let sun = P(-0.62, -0.5), circle0 = P(-0.22, -0.56)
        let scope = bar(P(-0.3, -0.6), P(0.36, -0.6), 0.12), hood = bar(P(0.3, -0.6), P(0.44, -0.6), 0.16)
        let standards = [rect(-0.2, -0.66, -0.12, -0.2), rect(0.1, -0.66, 0.18, -0.2)], plate = rect(-0.26, -0.26, 0.26, -0.18)
        let legs = [bar(P(-0.06, 0.24), P(-0.62, 1.0), 0.07), bar(P(0.02, 0.26), P(0.12, 1.0), 0.07), bar(P(0.08, 0.24), P(0.66, 0.9), 0.07)]
        let hill = curve(P(-1, -0.04), P(-0.3, -0.24), P(0.2, -0.06), 16) + curve(P(0.2, -0.06), P(0.6, 0.08), P(1, -0.12), 16) + [P(1, 1), P(-1, 1)]
        let cloud = [P(0.3, -0.86), P(0.62, -0.8)].map { oval($0, 0.16, 0.06, Tone(0.4, 0.4, 0.4)) }
        var fills = [fill(hood, dark), fill(scope, dark), disc(circle0, 0.12, silver)] + standards.map { fill($0, body) } + [fill(plate, body)]
        fills += legs.map { fill($0, wood) } + cloud + [disc(sun, 0.14, y(0.95)), fill(hill, field)]

        var s: [Halftone.Stroke] = []
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        // The hills' line, the sun, the clouds.
        s += runs(Array(hill.dropLast(2)), mid, keep: clear)
        s += hoop(sun, 0.14, mid, pieces: 3)
        for k in 0..<8 { s += runs([polar(sun, 0.17, 45 * Double(k) + 10), polar(sun, 0.23, 45 * Double(k) + 10)], hair, keep: clear) }
        for c0 in [P(0.3, -0.86), P(0.62, -0.8)] { s.append(stroke(Array(ellipse(c0, 0.16, 0.06, 24)[12...24]) + arc(c0 + P(0.02, -0.02), 0.08, 0, -180, 10).reversed(), mid)) }
        // The telescope, its hood and eyepiece; the standards, the vertical circle with its scale and clamp; the plate.
        s += edges(scope, mid, keep: clear) + edges(hood, bold, keep: clear)
        s.append(stroke(closed(rect(-0.36, -0.63, -0.3, -0.57)), mid))
        for q in standards { s += edges(q, mid, keep: clear) }
        s += hoop(circle0, 0.12, bold, pieces: 4) + hoop(circle0, 0.03, mid, pieces: 1)
        for k in 0..<24 { s.append(stroke([polar(circle0, 0.1, 15 * Double(k)), polar(circle0, k % 6 == 0 ? 0.075 : 0.088, 15 * Double(k))], hair)) }
        s += edges(rect(0.18, -0.46, 0.26, -0.38), mid, keep: clear)
        s += edges(plate, mid, keep: clear)
        // The tripod's legs.
        for q in legs { s += runs(span(q[0], q[1], 30), mid, keep: clear) + runs(span(q[3], q[2], 30), mid, keep: clear) }
        // Each glass's rims.
        for g in glasses {
            s += hoop(g.centre, g.rim, bold)
            s += hoop(g.centre, g.glass, mid)
        }
        // The round level: its ring, and the bubble standing off it.
        s += hoop(base, 0.034, 0.0034, pieces: 2) + hoop(base, 0.07, 0.0022, pieces: 3)
        s += hoop(base + P(0.04, -0.026), 0.016, 0.0042, pieces: 2)
        s.append(stroke(arc(base + P(0.04, -0.026), 0.009, 200, 260, 4), 0.0026))
        // Down the telescope: the staff, its marks, and the cross hairs with their stadia.
        let st = view + P(0.026, 0)
        s.append(stroke(closed(rect(st.x - 0.014, st.y - 0.09, st.x + 0.014, st.y + 0.09)), 0.0034))
        for k in 0..<6 {
            let yy = st.y - 0.08 + 0.03 * Double(k)
            s.append(stroke([P(st.x - 0.014, yy), P(st.x, yy), P(st.x, yy + 0.012), P(st.x - 0.014, yy + 0.012)], 0.0026))
        }
        s += runs(span(view + P(-0.16, -0.004), view + P(0.16, -0.004), 32), 0.0022) { abs($0.x - st.x) > 0.016 }
        s.append(stroke([view + P(-0.004, -0.16), view + P(-0.004, -0.024)], 0.0022))
        s.append(stroke([view + P(-0.004, 0.024), view + P(-0.004, 0.16)], 0.0022))
        for dy in [-0.05, 0.05] { s.append(stroke([view + P(-0.03, dy), view + P(-0.008, dy)], 0.0022)) }
        // The compass: its card's ring, the needle swung a little east of the line, and north.
        let cc = compass + P(0.024, 0.014)
        s += hoop(cc, 0.05, 0.0034, pieces: 3)
        for k in 0..<12 { s.append(stroke([polar(cc, 0.05, 30 * Double(k)), polar(cc, k % 3 == 0 ? 0.038 : 0.044, 30 * Double(k))], 0.0018)) }
        s.append(stroke(closed([polar(cc, 0.042, -75), polar(cc, 0.007, 15), polar(cc, 0.036, 105), polar(cc, 0.007, 195)]), 0.003))
        let north = cc + P(-0.008, -0.068)
        s.append(stroke([north + P(0, 0.012), north + P(0, -0.012), north + P(0.016, 0.012), north + P(0.016, -0.012)], 0.003))
        // Down the plummet: its ring and cross on the nail in the peg's top, and the turf round it.
        let pm = plummet + P(0.022, -0.02)
        s += hoop(pm, 0.03, 0.003, pieces: 2)
        s.append(stroke([pm + P(-0.05, 0), pm + P(-0.034, 0)], 0.0024))
        s.append(stroke([pm + P(0.034, 0), pm + P(0.05, 0)], 0.0024))
        s.append(stroke([pm + P(0, 0.034), pm + P(0, 0.05)], 0.0024))
        s.append(stroke(closed(rect(pm.x - 0.022, pm.y - 0.018, pm.x + 0.022, pm.y + 0.018)), 0.0036))
        s += hoop(pm + P(0.004, -0.002), 0.007, 0.0036, pieces: 1)
        for x in [-0.07, -0.05, 0.06] { s.append(stroke([pm + P(x, 0.07), pm + P(x - 0.006, 0.05), pm + P(x + 0.004, 0.044)], 0.0018)) }
        // The next station: a trig pillar on its hill, its plate on top, and a flag.
        let tp = pillar + P(-0.022, 0.024)
        s.append(stroke(curve(pillar + P(-0.14, 0.09), tp + P(0, 0.01), pillar + P(0.14, 0.09), 16), 0.0026))
        s.append(stroke(closed([tp + P(-0.016, 0.028), tp + P(-0.01, -0.03), tp + P(0.01, -0.03), tp + P(0.016, 0.028)]), 0.0036))
        s.append(stroke([tp + P(-0.014, -0.034), tp + P(0.014, -0.034)], 0.003))
        s.append(stroke([tp + P(0.004, -0.034), tp + P(0.004, -0.08)], 0.0026))
        s.append(stroke(closed([tp + P(0.004, -0.08), tp + P(0.036, -0.07), tp + P(0.004, -0.058)]), 0.0026))
        return drawn("theodolite", glasses: glasses, fills: fills, strokes: s) { _ in c(0.3) }
    }()
}

// MARK: - 67: Spectroscope

/// Level 67's name: Kirchhoff and Bunsen's spectroscope, a prism under its drum over the hub with brass tubes out to
/// the lower ring, a burner's flame at the end of the slit's tube, and the light it splits fanned out across the right
/// of the glass in six broad bands of colour. The five lenses: over the hub, the prism under the drum bending a ray
/// into a fan; over the top core the sun in eclipse, its corona and a flame of its edge, where helium was first seen;
/// over the upper left the slit, the flame between its jaws; over the lower left the eyepiece, sodium's two lines and
/// its name; and over the bottom the scale's tube, hydrogen's four lines and its letter.
extension LensArt {
    static let spectroscope: Halftone.Panel = {
        let drum = P(0, 0), sun = P(0, -0.56), slit = P(-0.485, -0.28), eye = P(-0.485, 0.28), scale = P(0, 0.56)
        let brass = y(0.65), dark = Tone.zero, flame = P(-0.78, -0.47)
        let bands = [Tone(0, 0.75, 0.55), y(0.9), Tone(0.55, 0, 0.75), c(0.85), Tone(0.7, 0.5, 0), m(0.75)]
        let fan = (-45.0, 45.0)
        let glasses = [
            glass(drum, c(0.5), frame: [(25, brass), (60, dark), (150, brass), (170, dark), (290, brass), (325, m(0.7)), (360, brass)]),
            glass(sun, m(0.5), frame: [(60, dark), (100, y(0.85)), (200, dark), (220, y(0.85)), (330, dark), (360, y(0.85))]),
            glass(slit, y(0.75), frame: [(30, brass), (140, dark), (175, brass), (250, dark), (360, brass)]),
            glass(eye, m(0.7), frame: [(80, dark), (110, brass), (230, dark), (265, c(0.7)), (360, dark)]),
            glass(scale, c(0.65), frame: [(50, brass), (75, dark), (200, brass), (235, dark), (300, brass), (330, dark), (360, brass)]),
        ]
        let tubes = [slit, eye, scale].map { bar(drum, $0, 0.13) }
        var fills = [oval(flame, 0.05, 0.085, y(0.9)), oval(flame + P(0, 0.03), 0.026, 0.04, c(0.8)), fill(rect(flame.x - 0.025, flame.y + 0.09, flame.x + 0.025, flame.y + 0.3), brass)]
        fills += tubes.map { fill($0, brass) }

        var s: [Halftone.Stroke] = []
        let clear = { (p: P) in glasses.allSatisfy { simd_distance(p, $0.centre) > $0.rim } }
        // The fan's bands and the card they fall on.
        for k in 0...6 {
            let a = fan.0 + (fan.1 - fan.0) * Double(k) / 6
            s += runs(span(polar(drum, 0.26, a), polar(drum, 0.97, a), 40), k == 0 || k == 6 ? mid : hair, keep: clear)
        }
        s.append(stroke(arc(drum, 0.93, fan.0 - 4, fan.1 + 4, 32), bold))
        // The tubes, banded where they join their glasses, the burner and its flame.
        for t in tubes {
            s += runs(span(t[0], t[1], 30), mid, keep: clear) + runs(span(t[3], t[2], 30), mid, keep: clear)
        }
        s.append(stroke(ellipse(flame, 0.05, 0.085, 20), mid))
        s.append(stroke(ellipse(flame + P(0, 0.03), 0.026, 0.04, 14), hair))
        s.append(stroke(closed(rect(flame.x - 0.025, flame.y + 0.09, flame.x + 0.025, flame.y + 0.3)), mid))
        s.append(stroke(closed(rect(flame.x - 0.07, flame.y + 0.3, flame.x + 0.07, flame.y + 0.34)), mid))
        for g in glasses {
            s += hoop(g.centre, g.rim, bold)
            s += hoop(g.centre, g.glass, mid)
        }
        // Under the drum: the prism, a ray into it and its fan out.
        let pr = drum + P(0.012, -0.026)
        s.append(stroke(closed([pr + P(0, -0.03), pr + P(0.028, 0.018), pr + P(-0.028, 0.018)]), 0.004))
        s.append(stroke([pr + P(-0.09, 0.02), pr + P(-0.016, -0.002)], 0.0034))
        for k in 0..<3 { s.append(stroke([pr + P(0.016, -0.002), pr + P(0.09, -0.02 + 0.026 * Double(k))], 0.0026)) }
        // The sun in eclipse: the moon's disc, the corona's streamers and a prominence.
        let ec = sun + P(-0.02, -0.022)
        s += hoop(ec, 0.026, 0.005, pieces: 2)
        for (a, l) in [(-80.0, 0.064), (-30, 0.044), (20, 0.058), (80, 0.04), (150, 0.062), (200, 0.042), (250, 0.054)] {
            s.append(stroke([polar(ec, 0.034, a), polar(ec, l, a + 8)], 0.003))
        }
        s.append(stroke(arc(polar(ec, 0.03, 120), 0.01, 120, 330, 8), 0.0036))
        // Through the slit's tube: its two jaws, and the flame standing between them.
        let sl = slit + P(0.03, -0.004)
        for x in [-0.026, 0.026] { s.append(stroke([sl + P(x, -0.07), sl + P(x, 0.07)], 0.004)) }
        let wick = sl + P(0, 0.02)
        s.append(stroke(arc(wick, 0.014, 0, 180, 10) + curve(wick + P(-0.014, 0), wick + P(-0.014, -0.036), wick + P(0.004, -0.07), 10)
            + curve(wick + P(0.004, -0.07), wick + P(0.016, -0.032), wick + P(0.014, 0), 10), 0.0042))
        s.append(stroke(arc(wick, 0.006, 0, 180, 6) + [wick + P(0.001, -0.028), wick + P(0.006, 0)], 0.0028))
        s.append(stroke([wick + P(0, 0.014), wick + P(0, 0.03)], 0.003))
        /// A strip of spectrum, its lines at `lines` (shares of the strip's length).
        func spectrum(_ at: P, _ lines: [Double]) {
            for dy in [-0.014, 0.014] { s.append(stroke([at + P(-0.06, dy), at + P(0.06, dy)], 0.0024)) }
            for x in lines { s.append(stroke([at + P(-0.06 + 0.12 * x, -0.014), at + P(-0.06 + 0.12 * x, 0.014)], 0.004)) }
        }
        // Through the eyepiece: sodium, its two lines close together, and its name.
        let na = eye + P(0.008, 0.026)
        spectrum(na, [0.55, 0.6])
        let n = na + P(-0.036, -0.05)
        s.append(stroke([n + P(0, 0.016), n + P(0, -0.016), n + P(0.02, 0.016), n + P(0.02, -0.016)], 0.0036))
        s.append(stroke(arc(n + P(0.038, 0.006), 0.009, 0, 360, 12) + [n + P(0.047, 0.016)], 0.0036))
        // Down the scale's tube: hydrogen, its four lines, and its letter.
        let hy = scale + P(-0.006, 0.026)
        spectrum(hy, [0.9, 0.5, 0.3, 0.18])
        let hh = hy + P(0.03, -0.048)
        s.append(stroke([hh + P(-0.011, -0.016), hh + P(-0.011, 0.016)], 0.0036))
        s.append(stroke([hh + P(0.011, -0.016), hh + P(0.011, 0.016)], 0.0036))
        s.append(stroke([hh + P(-0.011, 0), hh + P(0.011, 0)], 0.0036))
        return drawn("spectroscope", glasses: glasses, fills: fills, strokes: s) { p in
            // The fan of the split light, a band of colour for every fifteen degrees.
            let r2 = simd_length_squared(p)
            if p.x > 0, r2 < 0.93 * 0.93 {
                let a = atan2(p.y, p.x) * 180 / .pi
                if a > fan.0, a < fan.1 { return bands[min(Int((a - fan.0) / 15), 5)] }
            }
            return c(0.14)
        }
    }()
}
