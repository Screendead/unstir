// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A smooth stone resting on the slope, lit from up and to the left, where the sun is. It is the slope's one mark: a
/// level's pebble on its ledge, and with a word beside it (`SlopeStone`) every control that was a capsule.
struct SlopePebble: View {
    enum Kind {
        /// Done, or switched on: pale and warm, with a glow.
        case lit
        /// The one to take next: the brightest. Its wider glow is the caller's, as it breathes.
        case next
        /// Not yet reached, or switched off: the water's own grey, no highlight.
        case dull
        /// Prism's: cool white.
        case pale
    }

    var kind = Kind.lit
    /// The stone's width in points; it is 0.72 as tall.
    var width: CGFloat
    /// Each stone lies a little off level, its own way.
    var lean = Angle.zero
    /// The glow's colour, a tier's light (`Slope.light`); warm when nil.
    var glow: Color?

    /// How a stone numbered `n` leans.
    static func lean(_ n: Int) -> Angle { .radians(0.22 * sin(Double(n) * 1.7 + 0.5)) }

    private var stops: [Color] {
        switch kind {
        case .lit: [Color(0xFFFBEE), Color(0xE8DAC0), Color(0x968470)]
        case .next: [Color(0xFFFFFA), Color(0xFAF0D6), Color(0xC4AA82)]
        case .dull: [Color(0x687A82), Color(0x42545E), Color(0x222E38)]
        case .pale: [Color(0xECF0F6), Color(0xC4CCD8), Color(0x707888)]
        }
    }

    var body: some View {
        let height = width * (kind == .dull ? 0.66 : 0.72), rx = width / 2
        ZStack {
            if kind != .dull {
                let light = glow ?? (kind == .pale ? Color(0xE2ECFF) : Color(0xFFE8B4))
                Circle().fill(RadialGradient(colors: [light.opacity(0.3), light.opacity(0)], center: .center, startRadius: 0, endRadius: rx * 2.9))
                    .frame(width: rx * 5.8, height: rx * 5.8)
            }
            // The shadow where it rests.
            Ellipse().fill(.black.opacity(0.3)).frame(width: width * 1.02, height: height * 0.3).offset(x: 1, y: height * 0.46)
            ZStack {
                Ellipse().fill(RadialGradient(stops: [.init(color: stops[0], location: 0), .init(color: stops[1], location: 0.45),
                                                      .init(color: stops[2], location: 1)],
                                              center: UnitPoint(x: 0.36, y: 0.3), startRadius: 0, endRadius: rx * 1.45))
                if kind != .dull {
                    Ellipse().fill(.white.opacity(0.75)).frame(width: width * 0.26, height: height * 0.15)
                        .rotationEffect(.radians(-0.2)).offset(x: -rx * 0.3, y: -height * 0.24)
                }
            }
            .frame(width: width, height: height)
            .rotationEffect(lean)
            .opacity(kind == .dull ? 0.9 : 1)
        }
        .frame(width: width, height: height)
    }
}

extension View {
    /// Sets the view in a top-leading `ZStack` with its `anchor` at `point`, its frame its own, so what reads frames
    /// (a scroll's targets, VoiceOver, a tap) finds it where it is drawn.
    func slopePlace(_ point: CGPoint, anchor: UnitPoint = .center) -> some View {
        alignmentGuide(.leading) { $0.width * anchor.x - point.x }
            .alignmentGuide(.top) { $0.height * anchor.y - point.y }
    }

    /// A pebble set on its seat (`Slope.Frame.seat`, as `point` gives it): its underside a little into the sand.
    func seated(at seat: CGPoint) -> some View { slopePlace(seat, anchor: UnitPoint(x: 0.5, y: 0.93)) }
}

/// A stone with words beside it, to tap: the slope's button. The words keep their size at every Dynamic Type setting
/// and the stone grows a little with them; the target is 44 points at the least, whatever is drawn. Pressed, the
/// stone settles into the sand and dims. It sounds as every button does.
struct SlopeStone<Label: View>: View {
    var kind = SlopePebble.Kind.lit
    /// The stone after the words, as on a screen's trailing side.
    var trailing = false
    var glow: Color?
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            Face(kind: kind, trailing: trailing, glow: glow, label: label)
        }
        .buttonStyle(Sounding(presses: true))
    }

    private struct Face: View {
        var kind: SlopePebble.Kind
        var trailing: Bool
        var glow: Color?
        @ViewBuilder var label: () -> Label

        @Environment(\.buttonPressed) private var pressed
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @ScaledMetric(relativeTo: .body) private var grain = 1.0

        var body: some View {
            let width = (kind == .dull ? 17 : 20) * min(grain, 1.4)
            HStack(spacing: 12) {
                if trailing { words }
                SlopePebble(kind: kind, width: width, lean: .radians(trailing ? 0.1 : -0.08), glow: glow)
                    .offset(y: pressed && !reduceMotion ? 1.5 : 0)
                    .brightness(pressed ? -0.12 : 0)
                if !trailing { words }
            }
            .frame(minWidth: SlopeStone.target, minHeight: SlopeStone.target)
            .contentShape(Rectangle())
            .animation(reduceMotion ? nil : .snappy(duration: 0.16), value: pressed)
        }

        private var words: some View {
            label().font(.slope(.plain, .body)).foregroundStyle(Color.text.opacity(kind == .dull ? 0.82 : 1))
                .opacity(pressed ? 0.7 : 1)
        }
    }
}

extension SlopeStone {
    /// Apple's smallest target.
    static var target: CGFloat { 44 }
}

extension SlopeStone where Label == Text {
    init(_ words: Text, kind: SlopePebble.Kind = .lit, trailing: Bool = false, glow: Color? = nil, action: @escaping () -> Void) {
        self.init(kind: kind, trailing: trailing, glow: glow, action: action) { words }
    }
}
