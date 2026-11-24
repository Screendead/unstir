// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

extension Offer {
    /// The levels its cover stirs, each with the stack it stirs it by: its clip's, as the clip opens, so the dock shows
    /// what the card plays; the bundle's, each pack it grants.
    var covers: [(level: Level, stack: [Game.Entry])] { Clip.of(self).reels.map { ($0.level, $0.opening) } }
}

/// An offer's cover in a tank: its clip's level on its own picture, as the game draws it, stirred by the stack its clip
/// opens on, the level's own deal for every pack but Lens (`Reel.lensOpening`). `clock` nil holds it so; otherwise the
/// loop at that time: clean, stirred in bottom first, then unstirred top first a move at a time. Triptych I's shows a wedge of each pack's, cut from the centre, the first
/// centred at the top, each on its own loop. Its knobs are drawn as the game draws them, each turned by its rod's share
/// of the stack, and a clock's ratchet counts what it owes, so a cover shows how its pack plays (Jack, round 16); a
/// wedge whose key knob (a clock, else a lens, else a masked rod) falls outside it is turned to bring it in.
struct PackTank: View {
    let offer: Offer
    let side: CGFloat
    var clock: Double?

    static let period = 7.0

    var body: some View {
        let levels = offer.covers, span = 360 / Double(levels.count), start = -90 - span / 2, r = side / 2
        ZStack {
            ForEach(levels.indices, id: \.self) { k in
                let from = start + span * Double(k)
                tank(levels[k].level, levels[k].stack)
                    .rotationEffect(.degrees(levels.count > 1 ? Self.turn(levels[k].level, into: from + span / 2, span: span) : 0))
                    .clipShape(Wedge(from: from, to: from + span))
            }
            if levels.count > 1 {
                Path { p in
                    for k in levels.indices {
                        let a = (start + span * Double(k)) * .pi / 180
                        p.move(to: CGPoint(x: r, y: r))
                        p.addLine(to: CGPoint(x: r + r * cos(a), y: r + r * sin(a)))
                    }
                }
                .stroke(Color.white.opacity(0.85), lineWidth: 0.5)
            }
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .overlay { Bezel(r: r) }
        .accessibilityHidden(true)
    }

    private func tank(_ level: Level, _ stack: [Game.Entry]) -> some View {
        let wind = clock.map { Self.wind(stack.count, at: $0) } ?? Array(repeating: 1, count: stack.count)
        // The entries wound away are the identity, so they leave the shader's stack.
        let on = zip(stack, wind).filter { $0.1 > 0 }
        var stir = Unstirred(stack: on.map(\.0.twist), layout: level.layout, lenses: level.lenses, masks: level.masks,
                             liveRod: nil, liveAngle: 0, side: side, fillEntries: level.picture.fillEntries)
        stir.shares = on.map(\.1)
        return LevelPicture(level: level, played: Reel.played(level, on.map(\.0)), wound: stack.count - on.count, side: side,
                            stir: stir)
            .overlay { controls(level, on: on.map { ($0.0.twist, $0.1) }) }
    }

    private func controls(_ level: Level, on: [(Twist, Double)]) -> some View {
        let layout = level.layout, rods = layout.rods, r = side / 2, core = 2 * Tank.coreRadius * r
        func at(_ k: Int) -> CGPoint { CGPoint(x: r + rods[k].x * r, y: r + rods[k].y * r) }
        func angle(_ k: Int) -> Double { on.filter { $0.0.rod == k }.reduce(0) { $0 + Double($1.0.steps) * $1.1 } * Tank.step }
        return ZStack {
            ForEach(rods.indices.filter { $0 != layout.swirl }, id: \.self) { k in
                if k == level.clocks.first?.rod {
                    ClockHint(radius: min(rods[k].z * r, r - 4)).position(at(k))
                    RatchetView(angle: angle(k), size: LevelView.ratchetSize(core), plate: LevelView.ratchetReach * r, pawl: 0,
                                lit: false, stopped: false, owed: level.owed(k, on: on.map(\.0)), still: true)
                        .position(at(k))
                } else {
                    RodView(angle: angle(k), size: core, seized: level.kind(of: k) != .working, grabbed: false,
                            lens: level.lenses.contains(k), tint: level.tint(of: k))
                        .position(at(k))
                }
            }
        }
        .frame(width: side, height: side)
        .environment(\.page, level.page)
    }

    /// Degrees to turn a wedge's level so its key knob sits inside the wedge centred at `mid`, or 0 where it already does.
    static func turn(_ level: Level, into mid: Double, span: Double) -> Double {
        let rods = level.layout.rods
        guard let key = level.clocks.first?.rod ?? level.lenses.min() ?? level.masks.filter { $0.value != .white }.keys.min()
                ?? rods.indices.first, rods[key].x != 0 || rods[key].y != 0 else { return 0 }
        let at = atan2(rods[key].y, rods[key].x) * 180 / .pi
        let off = (at - mid).truncatingRemainder(dividingBy: 360), wrapped = off > 180 ? off - 360 : off < -180 ? off + 360 : off
        return abs(wrapped) < span / 2 - 15 ? 0 : -wrapped
    }

    /// Each entry's share of its turn, 0 clean to 1 stirred, `t` seconds into the clip.
    static func wind(_ m: Int, at t: Double) -> [Double] {
        let t = t.truncatingRemainder(dividingBy: period)
        func ease(_ x: Double) -> Double { let c = min(max(x, 0), 1); return c * c * (3 - 2 * c) }
        return (0..<m).map { k in
            let dIn = 1.2 / Double(m), dOut = 3.2 / Double(m)
            if t < 2.6 { return ease((t - 1.0 - Double(k) * dIn) / dIn) }
            return 1 - ease((t - 3.2 - Double(m - 1 - k) * dOut) / (0.8 * dOut))
        }
    }
}

/// A wedge from the centre between two angles in degrees, clockwise from three o'clock; the whole frame at 360.
private struct Wedge: Shape {
    let from: Double, to: Double

    func path(in rect: CGRect) -> Path {
        guard to - from < 360 else { return Path(rect) }
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: c)
        p.addArc(center: c, radius: rect.width, startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// A tank whose clip runs on the clock, unless the harness holds it at `held` seconds. Reduce Motion holds it stirred.
struct LoopingTank: View {
    let offer: Offer
    let side: CGFloat
    var held: Double?
    var offset = 0.0
    /// The dock runs at a lower rate, and stops under the card.
    var interval = 0.0
    var paused = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let held {
            PackTank(offer: offer, side: side, clock: held + offset)
        } else if reduceMotion {
            PackTank(offer: offer, side: side)
        } else {
            PausingTimeline(interval: interval > 0 ? interval : nil, paused: paused) { now in
                PackTank(offer: offer, side: side, clock: now + offset)
            }
        }
    }
}

/// The card's clip: the pack's own levels played live by the game (`Clip`), never a committed video.
struct PackClip: View {
    let offer: Offer
    let side: CGFloat
    var held: Double?
    @State private var seen = true

    var body: some View {
        ClipPlayer(clip: .of(offer), side: side, held: held, paused: !seen)
            .onGeometryChange(for: Bool.self) { Self.seen($0.size, in: $0.bounds(of: .scrollView)) } action: { seen = $0 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(offer.pitch.map { pitch in // loc: verbatim each a key
                Text("\(offer.name): \(pitch).", comment: "VoiceOver: a pack's clip. Its name, then its pitch")
            } ?? Text(verbatim: offer.name))
            .accessibilityAddTraits(.isImage)
    }

    /// Whether any of a view `size` across lies inside its scroll view's `viewport`, in its own space; with no scroll
    /// view, it shows.
    nonisolated static func seen(_ size: CGSize, in viewport: CGRect?) -> Bool {
        viewport.map { $0.intersects(CGRect(origin: .zero, size: size)) } ?? true
    }
}
