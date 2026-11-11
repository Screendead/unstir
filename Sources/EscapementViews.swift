// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Escapement's standing hint (Jack's call, 2026-10-25): the clock's disc marked at all times, a dashed edge and a faint
/// wash creeping in from it, so every turn that reaches in reads as reaching into the clock.
struct ClockHint: View {
    let radius: CGFloat
    /// A clock run out: the dashes grey and the wash gone, as its ratchet greys, `lands` seconds after the change.
    var spent = false
    var lands = 0.0
    @Environment(\.page) private var page

    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.clear, page.accent.opacity(spent ? 0 : 0.2)], center: .center,
                                         startRadius: 0.55 * radius, endRadius: radius))
            Circle().stroke(spent ? Color(0x6E7686).opacity(0.5) : page.accent.opacity(0.9),
                            style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        }
        .frame(width: 2 * radius, height: 2 * radius)
        .animation(.easeOut(duration: 0.25).delay(spent ? lands : 0), value: spent)
    }
}

/// Escapement's clock knob: a 12-tooth ratchet wheel that turns clockwise only, a tooth a tick, its index read against a
/// vermilion sub-dial fixed to the glass, and the pawl that drops into it. `pawl` 0 rests in a gap, 1 is lifted clear
/// as a tick rides it out. Its hub, fixed to the glass, is a split-flap card of the ticks the clock has left (Jack's call
/// ES2, round 12), which flips as each of its ticks starts to turn. Run out, the wheel, the sub-dial and the card go
/// grey, the card at 0, and the pawl amber, locked in its gap.
struct RatchetView: View {
    let angle: Double
    let size: CGFloat
    /// The radius of the dark plate it sits on, which a tap must land on to wait.
    var plate: CGFloat = 0
    /// The level has the waiting move, so the plate is ringed as its target.
    var waits = false
    let pawl: Double
    let lit: Bool
    let stopped: Bool
    /// A wound-back clock's: mirrored, so it ticks anticlockwise.
    var back = false
    /// The hub's count, flipping from `was` to `owed` as `fall` runs 0 to 1, as `FlipCounter`'s do.
    var owed = 0
    var was: Int?
    var fall = 1.0
    var still = false

    var body: some View {
        let rt = size / 2, rr = size / 2 * 0.74
        let c = CGPoint(x: size, y: size)
        func at(_ a: Double, _ rad: CGFloat) -> CGPoint { CGPoint(x: c.x + rad * sin(a), y: c.y - rad * cos(a)) }
        // Each tooth from its root: a steep rise, then a long slope back down to the next root.
        let wheel = Path { p in
            for i in 0..<12 {
                let a0 = Double(i) * Tank.step
                if i == 0 { p.move(to: at(a0, rr)) } else { p.addLine(to: at(a0, rr)) }
                p.addLine(to: at(a0 + 0.035, rt))
                p.addLine(to: at(a0 + Tank.step, rr))
            }
            p.closeSubpath()
        }
        let dial = Path { p in
            for i in 0..<12 {
                let a = Double(i) * Tank.step
                p.move(to: at(a, rt + 4))
                p.addLine(to: at(a, rt + (i == 0 ? 11 : 7)))
            }
        }
        // The pawl trails the free turn: its tip points clockwise from its pivot and rests in a gap against a tooth's
        // steep face, so a turn back drives that face end-on at the pivot and jams, and a turn on lifts it up the slope.
        let tipA = Double.pi / 2 - 0.03
        let pivot = at(tipA - 0.58, rt * 1.55), tip = at(tipA, rr + (rt - rr) * 0.25 + CGFloat(pawl) * (rt - rr) * 1.1)
        let steel = Color(0xB8BECA)
        return ZStack {
            let backing = max(size + 6, 2 * plate)
            Circle().fill(Color.black.opacity(0.75)).frame(width: backing, height: backing).position(c)
            if waits {
                Circle().stroke(Color.live.opacity(lit ? 1 : 0.35), lineWidth: 1).frame(width: backing, height: backing).position(c)
            }
            dial.stroke(stopped ? Color(0x6E7686).opacity(0.6) : Color.vermilion.opacity(0.9), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            ZStack {
                wheel.fill(RadialGradient(stops: [.init(color: Color(0xE6EAF2), location: 0), .init(color: Color(0x6E7686), location: 0.5),
                                                  .init(color: Color(0x262A33), location: 1)],
                                          center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: size))
                wheel.stroke(Color.black.opacity(0.85), lineWidth: 1)
                // The index, so each tick's step reads at a glance against the sub-dial; the hub's card covers its root.
                Path { $0.move(to: at(0, rr * 0.84)); $0.addLine(to: at(0, rr * 0.99)) }
                    .stroke(Color.vermilion, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            .rotationEffect(.radians(angle), anchor: .center)
            .saturation(stopped ? 0 : 1)
            .opacity(stopped ? 0.55 : 1)
            // The hub as wide as reads its card, the teeth and the index outside it.
            Circle().fill(Color.black.opacity(0.85)).frame(width: rr * 1.6, height: rr * 1.6).position(c)
            // Unmirrored, so a wound-back clock's count reads; its corners just inside the hub's ring.
            FlipCounter(value: owed, was: was ?? owed, fall: fall, digits: 1, still: still, spent: stopped, height: rr * 1.25)
                .scaleEffect(x: back ? -1 : 1)
                .position(c)
            Circle().stroke(stopped ? Color.amber : steel, lineWidth: 1.2).frame(width: rr * 1.6, height: rr * 1.6).position(c)
            Path { $0.move(to: pivot); $0.addLine(to: tip) }.stroke(Color.black.opacity(0.9), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            Path { $0.move(to: pivot); $0.addLine(to: tip) }.stroke(stopped ? Color.amber : steel,
                                                                   style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            Circle().fill(Color(0xD8DCE4)).frame(width: 4, height: 4).position(pivot)
        }
        .frame(width: 2 * size, height: 2 * size)
        // Wheel, pawl and all, so it turns anticlockwise.
        .scaleEffect(x: back ? -1 : 1)
        .animation(.easeOut(duration: 0.12), value: pawl == 1)
        .animation(.easeOut(duration: 0.25), value: stopped)
    }
}

/// Escapement's tick counts as a split-flap clock, the header's and each hub's: a card per digit, hinged across its
/// middle. As `value` takes over from `was`, the old digit's top half falls over the hinge onto its bottom half, `fall`
/// 0 to 0.5, uncovering the new digit's top, and the new digit's bottom half lands, 0.5 to 1. Under Reduce Motion it
/// swaps without the fall.
struct FlipCounter: View {
    let value: Int
    let was: Int
    let fall: Double
    let digits: Int
    var still = false
    /// Spent with twists left, the cards go vermilion.
    var out = false
    /// A hub's whose clock has run out: grey ink on grey-edged cards.
    var spent = false
    /// The header's cards are `standard` tall; a hub's fit inside it.
    var height: CGFloat = FlipCounter.standard
    static let standard: CGFloat = 26
    private var width: CGFloat { height * 19 / 26 }

    var body: some View {
        let new = Self.digits(of: value, digits), old = Self.digits(of: was, digits)
        HStack(spacing: 2) {
            ForEach(0..<digits, id: \.self) { i in
                card(new[i], old[i], fall: still || new[i] == old[i] ? 1 : fall)
            }
        }
    }

    static func digits(of n: Int, _ count: Int) -> [Character] {
        Array(String(String(max(n, 0)).suffix(count)).leftPadded(to: count))
    }

    private var ink: Color { out ? .vermilion : spent ? Color(0x6E7686) : Color(0xF2F4F8) }

    private func face(_ d: Character, top: Bool) -> some View {
        let w = width, h = height, k = height / 26
        return ZStack {
            UnevenRoundedRectangle(topLeadingRadius: top ? 3 * k : 0, bottomLeadingRadius: top ? 0 : 3 * k,
                                   bottomTrailingRadius: top ? 0 : 3 * k, topTrailingRadius: top ? 3 * k : 0)
                .fill(LinearGradient(colors: top ? [Color(0x23262E), Color(0x181A20)] : [Color(0x15171C), Color(0x0D0E11)],
                                     startPoint: .top, endPoint: .bottom))
            Text(verbatim: String(d)).font(.system(size: h * 0.74, weight: .bold, design: .monospaced))
                .foregroundStyle(ink).shadow(color: ink.opacity(spent ? 0 : 0.55), radius: 3 * k)
                .frame(width: w, height: h)
                .frame(width: w, height: h / 2, alignment: top ? .top : .bottom)
        }
        .frame(width: w, height: h / 2)
        .clipped()
    }

    private func card(_ d: Character, _ o: Character, fall p: Double) -> some View {
        let h = height, k = height / 26
        // The top half falls, gathering speed; the bottom half lands and settles.
        let first = pow(min(p / 0.5, 1), 2), second = 1 - pow(1 - max((p - 0.5) / 0.5, 0), 2)
        return VStack(spacing: 0) {
            ZStack {
                face(d, top: true)
                if p < 0.5 {
                    face(o, top: true)
                        .overlay(Color.black.opacity(0.5 * first))
                        .rotation3DEffect(.degrees(-90 * first), axis: (x: 1, y: 0, z: 0), anchor: .bottom, perspective: 0.6)
                }
            }
            ZStack {
                face(p < 1 ? o : d, top: false)
                    .overlay(Color.black.opacity(p > 0.5 && p < 1 ? 0.35 * (1 - second) : 0))
                if p > 0.5 && p < 1 {
                    face(d, top: false)
                        .overlay(Color.black.opacity(0.5 * (1 - second)))
                        .rotation3DEffect(.degrees(90 * (1 - second)), axis: (x: 1, y: 0, z: 0), anchor: .top, perspective: 0.6)
                }
            }
        }
        .frame(width: width, height: h)
        // The hinge, and its pins at either edge.
        .overlay {
            ZStack {
                Rectangle().fill(Color.black).frame(height: max(k, 0.5))
                // Too small to read on a hub's card, where they only cut into the digit.
                if height >= 20 {
                    HStack {
                        Capsule().fill(Color(0x8C94A6)).frame(width: 2 * k, height: 4 * k)
                        Spacer()
                        Capsule().fill(Color(0x8C94A6)).frame(width: 2 * k, height: 4 * k)
                    }
                    .padding(.horizontal, -k)
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 3 * k).stroke((out ? Color.vermilion : Color(0x5A6272)).opacity(spent ? 0.5 : 0.8),
                                                             lineWidth: 0.75))
    }
}

private extension String {
    func leftPadded(to n: Int) -> String { String(repeating: "0", count: max(n - count, 0)) + self }
}

/// Escapement: what a tank whose clocks all stopped with twists left shows beside its stamp: nothing more (as built), the
/// count of twists left where a pushed tick's count would stand, or a ring round each knob still twisted.
enum StopLook: String, Sendable { case stamp, left, rings }

/// Escapement: "out of ticks." stamped by the clock once the budget is spent with twists left.
struct LostStamp: View {
    var size: CGFloat = 76
    @State private var landed = false
    @Environment(\.page) private var page
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text("out of ticks.").font(.system(size: size, weight: .bold, design: .serif)).italic().fixedSize()
            .foregroundStyle(page.accent)
            .shadow(color: page.ground.opacity(0.9), radius: 8)
            .rotationEffect(.degrees(-6))
            .scaleEffect(landed || reduceMotion ? 1 : 1.3)
            .opacity(landed ? 1 : 0)
            .onAppear { withAnimation(.easeOut(duration: 0.16)) { landed = true } }
            .allowsHitTesting(false)
    }
}
