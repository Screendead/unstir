// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Prototype: a frost day's seized knobs drawn frozen, in place of maelstrom's dull cap and red slash. UNSTIR_FROSTLOOK
/// picks one for the launch: `rime` (a frost crystal on the cap, ice needles creeping in from the disc's edge), `glaze`
/// (a glazed cap and a sheet of ice over the disc) or `crack` (a cracked ice cap and frost round its band). All are
/// static vector drawing, so a still tank draws them once; the glaze's sheet is one translucent disc over the picture.
enum FrostLook: String {
    case rime, glaze, crack

    static let chosen = ProcessInfo.processInfo.environment["UNSTIR_FROSTLOOK"].flatMap(Self.init(rawValue:))

    static let ice = Color(0xBFE8FF), deep = Color(0x3E6F92)
    static let cap = [(0, 0xF4FCFF), (0.3, 0xA8D2EA), (0.65, 0x46708C), (1, 0x172633)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }
    static let glazed = [(0, 0xFFFFFF), (0.18, 0xD4EEFC), (0.55, 0x6FA3C4), (1, 0x1F3A4E)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }

    /// A fixed scatter in 0..<1 for needle `i` of disc `k`, so each disc's rime is its own and never flickers.
    static func jitter(_ i: Int, _ k: Int) -> Double {
        var x = UInt64(i &* 7919 &+ k &* 104_729 &+ 1)
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        return Double((x ^ (x >> 31)) % 10_000) / 10_000
    }
}

extension Level {
    /// A frost day's daily: its seized knobs are frozen, not jammed.
    var frosty: Bool { id.hasPrefix("daily-") && !seized.isEmpty }
}

/// What a frozen knob's cap carries over its ice, turning with the cap.
struct FrostCap: View {
    let look: FrostLook
    let size: CGFloat

    var body: some View {
        switch look {
        case .rime:
            crystal.stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
                .shadow(color: FrostLook.ice, radius: 1.5)
        case .glaze:
            ZStack {
                // The glaze's gloss, high on the cap where the light falls.
                Ellipse().fill(LinearGradient(colors: [.white.opacity(0.75), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: size * 0.55, height: size * 0.3).offset(x: -size * 0.1, y: -size * 0.22)
                Circle().strokeBorder(FrostLook.ice.opacity(0.9), lineWidth: 1).padding(1.5)
            }
        case .crack:
            ZStack {
                cracks.stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                    .offset(x: 0.5, y: 0.5)
                cracks.stroke(Color(0x0B1A26).opacity(0.85), style: StrokeStyle(lineWidth: 0.8, lineCap: .round, lineJoin: .round))
            }
        }
    }

    /// Six arms from the centre, each with two pairs of side branches.
    private var crystal: Path {
        Path { p in
            let c = CGPoint(x: size / 2, y: size / 2), arm = size * 0.4
            func at(_ r: CGFloat, _ a: Double, from o: CGPoint = c) -> CGPoint { CGPoint(x: o.x + r * sin(a), y: o.y - r * cos(a)) }
            for i in 0..<6 {
                let a = Double(i) * .pi / 3 + .pi / 6
                p.move(to: c)
                p.addLine(to: at(arm, a))
                for (f, len) in [(0.45, 0.16), (0.72, 0.1)] {
                    let o = at(arm * f, a)
                    p.move(to: o); p.addLine(to: at(size * len, a + 0.9, from: o))
                    p.move(to: o); p.addLine(to: at(size * len, a - 0.9, from: o))
                }
            }
        }
    }

    /// From a strike just off the centre: five cracks out to the cap's edge, bent at each step, two of them forked.
    private var cracks: Path {
        Path { p in
            let o = CGPoint(x: size * 0.46, y: size * 0.54), edge = size * 0.47
            for i in 0..<5 {
                var a = Double(i) * 2 * .pi / 5 + 0.4 + FrostLook.jitter(i, 9) * 0.6
                var pt = o
                p.move(to: pt)
                for s in 1...4 {
                    a += (FrostLook.jitter(i * 4 + s, 3) - 0.5) * 0.7
                    pt = CGPoint(x: pt.x + edge / 4 * sin(a), y: pt.y - edge / 4 * cos(a))
                    p.addLine(to: pt)
                    if s == 2, i % 2 == 0 {
                        let b = a + 0.8, fork = CGPoint(x: pt.x + edge * 0.3 * sin(b), y: pt.y - edge * 0.3 * cos(b))
                        p.addLine(to: fork)
                        p.move(to: pt)
                    }
                }
            }
            // A ring of the strike's own.
            p.addEllipse(in: CGRect(x: o.x - size * 0.07, y: o.y - size * 0.07, width: size * 0.14, height: size * 0.14))
        }
    }
}

/// What a frozen knob's disc carries, fixed in the frame as the tank turns under it. `radius`: the disc's, `core`: the
/// knob's cap, `k` seeds the rime.
struct FrostDisc: View {
    let look: FrostLook
    let radius: CGFloat
    let core: CGFloat
    let k: Int

    var body: some View {
        switch look {
        case .rime:
            ZStack {
                Circle().stroke(FrostLook.ice.opacity(0.45), lineWidth: 1.5).blur(radius: 1.5)
                needles(from: radius, depth: radius * 0.16, count: 96)
                    .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
            }
            .frame(width: 2 * radius, height: 2 * radius)
        case .glaze:
            ZStack {
                Circle().fill(RadialGradient(colors: [FrostLook.ice.opacity(0.06), FrostLook.ice.opacity(0.26)],
                                             center: .center, startRadius: core / 2, endRadius: radius))
                // A sheen high on the ice, where the bezel's light would catch it.
                Circle().trim(from: 0.58, to: 0.78).stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .padding(radius * 0.12)
                Circle().strokeBorder(FrostLook.ice.opacity(0.8), lineWidth: 1)
            }
            .frame(width: 2 * radius, height: 2 * radius)
        case .crack:
            // Frost round the knob's band only: the disc's picture stays clear.
            needles(from: core / 2 + 10, depth: -7, count: 40, spread: 0.5)
                .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
                .shadow(color: FrostLook.ice, radius: 2)
                .frame(width: core + 34, height: core + 34)
        }
    }

    /// `count` needles from radius `r` inward by up to `depth` (outward where negative), each its own length, and every
    /// third with a barb, as hoar frost grows.
    private func needles(from r: CGFloat, depth: CGFloat, count: Int, spread: Double = 1) -> Path {
        Path { p in
            let c = r + max(0, -depth)
            for i in 0..<count {
                let a = (Double(i) + FrostLook.jitter(i, k) * 0.6) * 2 * .pi / Double(count)
                let len = depth * (1 - spread + spread * FrostLook.jitter(i + 500, k))
                let tilt = (FrostLook.jitter(i + 900, k) - 0.5) * 0.5
                let from = CGPoint(x: c + r * sin(a), y: c - r * cos(a))
                let to = CGPoint(x: c + (r - len) * sin(a + tilt * Double(len) / Double(r)),
                                 y: c - (r - len) * cos(a + tilt * Double(len) / Double(r)))
                p.move(to: from)
                p.addLine(to: to)
                if i % 3 == 0 {
                    let mid = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2), b = a + 0.9 * (tilt < 0 ? -1 : 1)
                    p.move(to: mid)
                    p.addLine(to: CGPoint(x: mid.x - len * 0.35 * sin(b), y: mid.y + len * 0.35 * cos(b)))
                }
            }
        }
    }
}
