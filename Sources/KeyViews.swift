// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What a knob shows of Charybdis's keys (`Ward`): a ring round each knob of a pair in the pair's colour, a notch on a
/// key's fixed dial at each mark it keys, and a keyhole on a ward's cap, dark while locked and lit while its key stands
/// on the mark. Pairs are told apart by colour and by their rings' stroke, solid, dashed or dotted, so colour never
/// carries it alone.
struct KeyKnob: Equatable {
    /// Gold, then rose, then green: none of them the grid's cyan, the push's red or the lens's magenta.
    static let colours = [Color(0xFFC24A), Color(0xFF7A9C), Color(0x9CF06A)]

    struct Part: Equatable {
        /// The pair's place among the level's wards, by slot: its colour and pips.
        var pair: Int
        /// A key's mark, in steps; nil on the ward's side.
        var mark: Int?
        /// Whether the key stands on the mark, so the ward turns.
        var open: Bool
        var colour: Color { KeyKnob.colours[pair % KeyKnob.colours.count] }
    }

    /// Each pair this knob keys, its mark among them.
    var keys: [Part] = []
    /// The pair whose ward this knob is.
    var ward: Part?

    /// Knob `k`'s on `game`'s level, nil where it is neither key nor ward.
    @MainActor static func of(_ k: Int, in game: Game) -> KeyKnob? {
        let wards = game.level.wards
        guard !wards.isEmpty else { return nil }
        let slot = game.slot(of: k)
        var out = KeyKnob()
        for (i, w) in wards.keys.sorted().enumerated() {
            let ward = wards[w]!, open = ward.open(stack: game.stack, dealt: game.level.scramble)
            if ward.key == slot { out.keys.append(Part(pair: i, mark: ward.mark, open: open)) }
            if w == slot { out.ward = Part(pair: i, open: open) }
        }
        return out.keys.isEmpty && out.ward == nil ? nil : out
    }

    /// The pairs round this knob, innermost first: its ward's, then each it keys.
    private var rings: [Part] { (ward.map { [$0] } ?? []) + keys }
}

extension KeyKnob {
    /// The ring's width and the gap between rings, in points.
    private static let line: CGFloat = 1.5, pitch: CGFloat = 5

    /// Drawn behind the knob, fixed while it turns: each pair's ring outside the knob's dark band, and each mark a notch on the outermost ring pointing in, lit while the key stands on it.
    func dial(size: CGFloat, reduceMotion: Bool) -> some View {
        let rim = size / 2, rings = self.rings
        let outer = rim + 5 + Self.pitch * CGFloat(rings.count - 1)
        return ZStack {
            ForEach(Array(rings.enumerated()), id: \.offset) { i, part in
                let radius = rim + 5 + Self.pitch * CGFloat(i)
                // A dark bed under the ring, so it reads over a busy picture.
                Circle().stroke(Color.black.opacity(0.6), lineWidth: Self.line + 2.5)
                    .frame(width: 2 * radius, height: 2 * radius)
                Circle().stroke(part.colour.opacity(part.open ? 1 : 0.75), style: Self.stroke(part.pair))
                    .frame(width: 2 * radius, height: 2 * radius)
                    .shadow(color: part.colour.opacity(part.open ? 0.8 : 0), radius: 3)
            }
            ForEach(Array(keys.enumerated()), id: \.offset) { _, part in
                let notch = Self.notch(at: Double(part.mark ?? 0) * Tank.step, from: rim + 3, to: outer + 8, size: size)
                notch.fill(part.colour)
                    .shadow(color: part.colour.opacity(part.open ? 0.9 : 0), radius: part.open ? 4 : 0)
                notch.stroke(Color.black.opacity(0.7), lineWidth: 0.75)
            }
        }
        .frame(width: size, height: size)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : .easeOut(duration: 0.3), value: self)
        .allowsHitTesting(false)
    }

    /// Drawn on the cap, turning with it: a ward's keyhole below the centre, opposite the pointer, a dark slot in its
    /// colour's outline while locked, lit and glowing while open.
    @ViewBuilder func cap(size: CGFloat, reduceMotion: Bool) -> some View {
        if let ward {
            let hole = Self.keyhole(size)
            ZStack {
                hole.fill(Color.black.opacity(0.85))
                hole.fill(ward.colour).opacity(ward.open ? 1 : 0)
                hole.stroke(ward.open ? Color.black.opacity(0.6) : ward.colour, lineWidth: 1)
            }
            .shadow(color: ward.colour.opacity(ward.open ? 0.9 : 0), radius: ward.open ? 5 : 0)
            .frame(width: size, height: size)
            .animation(reduceMotion ? .easeOut(duration: 0.15) : .easeOut(duration: 0.3), value: ward.open)
            .allowsHitTesting(false)
        }
    }

    /// A round head over a slot that widens away from the centre, between the cap's centre and its ticks: the pointer
    /// runs from 0.15 of the cap's width above the centre outwards.
    static func keyhole(_ w: CGFloat) -> Path {
        Path { p in
            let c = CGPoint(x: w / 2, y: w / 2 + w * 0.08), head = w * 0.1
            p.addEllipse(in: CGRect(x: c.x - head, y: c.y - head, width: 2 * head, height: 2 * head))
            p.move(to: CGPoint(x: c.x - w * 0.04, y: c.y + head * 0.7))
            p.addLine(to: CGPoint(x: c.x + w * 0.04, y: c.y + head * 0.7))
            p.addLine(to: CGPoint(x: c.x + w * 0.075, y: c.y + w * 0.29))
            p.addLine(to: CGPoint(x: c.x - w * 0.075, y: c.y + w * 0.29))
            p.closeSubpath()
        }
    }

    /// A wedge at angle `a` (clockwise from twelve) from radius `inner` out to `outer`, about the knob's centre.
    private static func notch(at a: Double, from inner: CGFloat, to outer: CGFloat, size: CGFloat) -> Path {
        Path { p in
            let c = CGPoint(x: size / 2, y: size / 2)
            func at(_ r: CGFloat, _ t: Double) -> CGPoint { CGPoint(x: c.x + r * sin(t), y: c.y - r * cos(t)) }
            let half = Double(5 / outer)
            p.move(to: at(inner, a))
            p.addLine(to: at(outer, a - half))
            p.addLine(to: at(outer, a + half))
            p.closeSubpath()
        }
    }

    /// The first pair's ring solid, the second's dashed, the third's dotted.
    private static func stroke(_ pair: Int) -> StrokeStyle {
        switch pair % 3 {
        case 0: StrokeStyle(lineWidth: line)
        case 1: StrokeStyle(lineWidth: line, dash: [4, 2.5])
        default: StrokeStyle(lineWidth: line + 0.5, lineCap: .round, dash: [0.01, 3.5])
        }
    }
}
