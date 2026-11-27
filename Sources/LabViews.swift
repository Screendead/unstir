// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What a knob shows of the fifth chapter's candidate rules (`LabRules`), Debug prototypes only.
struct LabKnob: Equatable {
    /// Keys: the colour of each key and ward pair, by pair.
    static let pairs = [Color(0xFFC24A), Color(0xFF7A9C), Color(0x9CF06A)]

    /// A key's marks on its fixed dial, in steps, each in its pair's colour.
    var marks: [(steps: Int, colour: Color)] = []
    /// A ward's keyhole: its pair's colour, and whether its key stands on the mark.
    var ward: (colour: Color, open: Bool)?
    /// Ebb and flow: the sense the knob turns next, +1 clockwise or -1, or 0 either way.
    var sense = 0

    static func == (a: LabKnob, b: LabKnob) -> Bool {
        a.marks.map(\.steps) == b.marks.map(\.steps) && a.ward?.open == b.ward?.open && a.sense == b.sense
    }

    /// Knob `k`'s on `game`'s level.
    @MainActor static func of(_ k: Int, in game: Game) -> LabKnob? {
        let lab = game.level.lab, slot = game.slot(of: k)
        guard !lab.isEmpty else { return nil }
        let wards = lab.keys.keys.sorted()
        var out = LabKnob()
        for (i, w) in wards.enumerated() {
            let key = lab.keys[w]!
            if key.key == slot { out.marks.append((key.mark, pairs[i % pairs.count])) }
            if w == slot { out.ward = (pairs[i % pairs.count], game.kind(of: k) == .working) }
        }
        out.sense = game.labSense(k)
        return out
    }
}

extension LabKnob {
    /// Drawn behind the knob, fixed while it turns: each mark a notch on the dial pointing in, and the next sense an arc
    /// over the dial's top with its head the way the knob may go.
    func dial(size: CGFloat) -> some View {
        let rim = size / 2
        return ZStack {
            // A ring in the pair's colour round a key and round its ward, so the two read as one pair.
            if let ward {
                Circle().strokeBorder(ward.colour.opacity(ward.open ? 1 : 0.7), lineWidth: 1.5).padding(-5)
                    .shadow(color: ward.open ? ward.colour : .clear, radius: 4)
            }
            ForEach(Array(marks.enumerated()), id: \.offset) { i, m in
                Circle().strokeBorder(m.colour.opacity(0.7), lineWidth: 1.5).padding(-5 - 3 * CGFloat(i))
            }
            ForEach(Array(marks.enumerated()), id: \.offset) { _, m in
                let t = Double(m.steps) * Tank.step
                Path { p in
                    let c = CGPoint(x: rim, y: rim)
                    func at(_ r: CGFloat, _ a: Double) -> CGPoint { CGPoint(x: c.x + r * sin(a), y: c.y - r * cos(a)) }
                    p.move(to: at(rim + 4, t))
                    p.addLine(to: at(rim + 15, t - 0.3))
                    p.addLine(to: at(rim + 15, t + 0.3))
                    p.closeSubpath()
                }
                .fill(m.colour)
                .shadow(color: m.colour, radius: 3)
            }
            if sense != 0 {
                let a0 = -0.5, a1 = 0.5, r = rim + 9
                Path { p in
                    p.addArc(center: CGPoint(x: rim, y: rim), radius: r, startAngle: .radians(a0 - .pi / 2),
                             endAngle: .radians(a1 - .pi / 2), clockwise: false)
                }
                .stroke(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                // The head at the end the knob may turn towards.
                let tip = sense > 0 ? a1 : a0, back = tip - Double(sense) * 0.22
                Path { p in
                    func at(_ r: CGFloat, _ a: Double) -> CGPoint { CGPoint(x: rim + r * sin(a), y: rim - r * cos(a)) }
                    p.move(to: at(r, tip + Double(sense) * 0.06))
                    p.addLine(to: at(r + 4, back))
                    p.addLine(to: at(r - 4, back))
                    p.closeSubpath()
                }
                .fill(Color.white.opacity(0.95))
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }

    /// Drawn over the cap, upright: a ward's keyhole, dark in its colour's outline while locked, lit while open.
    @ViewBuilder func cap(size: CGFloat) -> some View {
        if let ward {
            let hole = Path { p in
                let w = size, c = CGPoint(x: w / 2, y: w / 2 - w * 0.08)
                p.addEllipse(in: CGRect(x: c.x - w * 0.14, y: c.y - w * 0.14, width: w * 0.28, height: w * 0.28))
                p.move(to: CGPoint(x: c.x - w * 0.07, y: c.y + w * 0.06))
                p.addLine(to: CGPoint(x: c.x + w * 0.07, y: c.y + w * 0.06))
                p.addLine(to: CGPoint(x: c.x + w * 0.12, y: c.y + w * 0.36))
                p.addLine(to: CGPoint(x: c.x - w * 0.12, y: c.y + w * 0.36))
                p.closeSubpath()
            }
            ZStack {
                hole.fill(ward.open ? ward.colour : Color.black.opacity(0.85))
                hole.stroke(ward.colour.opacity(ward.open ? 1 : 0.8), lineWidth: 1)
            }
            .shadow(color: ward.open ? ward.colour : .clear, radius: 4)
            .frame(width: size, height: size)
            .allowsHitTesting(false)
        }
    }
}

/// The keel (`LabRules.keel`): a scale across the bezel's top, a step a notch, and a bead at the tank's list, every
/// knob's turns summed; the turn that would carry it past an end stops there.
struct KeelGauge: View {
    let r: CGFloat
    let list: Int
    let keel: Int
    /// The list a turn in hand would leave.
    var live: Double?

    var body: some View {
        let pitch = 0.07, radius = 1.0225 * r
        func at(_ a: Double, _ rr: CGFloat) -> CGPoint { CGPoint(x: r + rr * sin(a), y: r - rr * cos(a)) }
        let now = max(-Double(keel), min(Double(keel), live ?? Double(list)))
        let full = abs(now) >= Double(keel) - 0.01
        return ZStack {
            Path { p in
                p.addArc(center: CGPoint(x: r, y: r), radius: radius, startAngle: .radians(-pitch * Double(keel) - .pi / 2),
                         endAngle: .radians(pitch * Double(keel) - .pi / 2), clockwise: false)
            }
            .stroke(Color.black.opacity(0.75), style: StrokeStyle(lineWidth: 0.04 * r, lineCap: .round))
            Path { p in
                for i in -keel...keel {
                    let a = Double(i) * pitch, long = i == 0 || abs(i) == keel
                    p.move(to: at(a, radius - (long ? 0.02 : 0.012) * r))
                    p.addLine(to: at(a, radius + (long ? 0.02 : 0.012) * r))
                }
            }
            .stroke(Color.white.opacity(0.8), lineWidth: 1.2)
            Circle().fill(full ? Color.amber : Color.white)
                .frame(width: 0.036 * r, height: 0.036 * r)
                .shadow(color: full ? .amber : .white, radius: 3)
                .position(at(now * pitch, radius))
        }
        .frame(width: 2 * r, height: 2 * r)
        .allowsHitTesting(false)
    }
}
