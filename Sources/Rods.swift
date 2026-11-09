// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

struct RodView: View {
    let angle: Double
    let size: CGFloat
    var seized = false
    var grabbed = false
    /// A lens's knob, whose cap carries an iris.
    var lens = false
    /// Prism's: the colour of the channels the rod stirs, on its ticks, pointer and a jewel at the cap's centre.
    var tint: Color?
    /// Prism's channels, spelt out under the knob in the swatches' letters where colour alone mustn't carry them.
    var channels: Channels?
    @Environment(\.channelLetters) private var letters
    @Environment(\.displayScale) private var scale
    private static let knob = [(0, 0xF4F6FA), (0.25, 0x7A8292), (0.6, 0x2E333D), (1, 0x15181E)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }
    private static let dull = [(0, 0x6E737C), (0.25, 0x3C414A), (0.6, 0x1E2127), (1, 0x101216)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }

    var body: some View {
        // Whole device pixels out from a pixel-snapped centre, so at rest the upright and level ticks land crisp.
        let rim = px(size / 2), width = px(2 / 3)
        let lit = seized ? Color(0x5A606C) : tint ?? .neonCyan
        ZStack {
            Circle().fill(RadialGradient(stops: seized ? Self.dull : Self.knob, center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0,
                                         endRadius: size * 0.95))
            Circle().strokeBorder(Color.black.opacity(0.8), lineWidth: 1.2)
            ticks(rim - px(2), rim - px(1 / 3)).stroke(lit.opacity(0.8), lineWidth: width)
            if grabbed { ticks(rim - px(2), rim - px(1 / 3)).stroke(Color.live, lineWidth: width) }
            if lens {
                iris.stroke(Color.magenta.opacity(0.3), lineWidth: 3)
                iris.stroke(Color.magenta, lineWidth: 1)
            }
            if let tint {
                Circle().fill(tint.opacity(0.3)).frame(width: size * 0.34, height: size * 0.34)
                Circle().fill(tint).overlay(Circle().strokeBorder(Color.black.opacity(0.6), lineWidth: 0.5))
                    .frame(width: size * 0.2, height: size * 0.2)
            }
            // Off-centre so a half turn reads as pointing down, not as untouched.
            Capsule().fill(lit.opacity(0.25)).frame(width: 6, height: size * 0.3 + 4).offset(y: -size * 0.3)
            Capsule().fill(lit).frame(width: 2, height: size * 0.3).offset(y: -size * 0.3)
            if seized {
                Capsule().fill(Color.blood).frame(width: size * 0.95, height: 2.5).shadow(color: .blood, radius: 3)
                    .rotationEffect(.degrees(-35))
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.radians(angle))
        .overlay(alignment: .bottom) {
            // Upright, off the turning cap.
            if letters, let channels {
                Text(channels.letters).font(.mono(9, .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 3).background(Capsule().fill(Color.black.opacity(0.75)))
                    .fixedSize().offset(y: 12).accessibilityHidden(true)
            }
        }
        .background {
            Circle().strokeBorder(Color.black.opacity(0.7), lineWidth: 3).padding(-3)
            ticks(rim + px(2 / 3), rim + px(8 / 3)).stroke(lit.opacity(0.5), lineWidth: width)
            // Lit inside the knob's own footprint, so the picture round it stays in view.
            if grabbed {
                ticks(rim + px(2 / 3), rim + px(8 / 3)).stroke(Color.live, lineWidth: width)
                Self.band(.live)
            }
        }
    }

    /// A ring along the outer edge of the knob's dark band, where it covers none of the picture.
    static func band(_ colour: Color) -> some View { Circle().strokeBorder(colour, lineWidth: 1).padding(-3) }

    private func px(_ points: CGFloat) -> CGFloat { (points * scale).rounded() / scale }

    /// Six blades, each swept from the cap's edge in to a corner of the aperture, so the iris turns with the knob.
    private var iris: Path {
        Path { p in
            let c = CGPoint(x: size / 2, y: size / 2), outer = size * 0.4, inner = size * 0.14
            func at(_ r: CGFloat, _ a: Double) -> CGPoint { CGPoint(x: c.x + r * sin(a), y: c.y - r * cos(a)) }
            for i in 0..<6 {
                let a = Double(i) * .pi / 3
                p.move(to: at(outer, a))
                p.addQuadCurve(to: at(inner, a + 1.3), control: at(outer * 0.62, a + 0.85))
                p.addLine(to: at(inner, a + 1.3 + .pi / 3))
            }
        }
    }

    /// One radial mark per 30-degree step, from radius `a` out to `b`.
    private func ticks(_ a: CGFloat, _ b: CGFloat) -> Path {
        var p = Path()
        for i in 0..<12 {
            let t = Double(i) * Tank.step
            p.move(to: CGPoint(x: size / 2 + a * sin(t), y: size / 2 - a * cos(t)))
            p.addLine(to: CGPoint(x: size / 2 + b * sin(t), y: size / 2 - b * cos(t)))
        }
        return p
    }
}
