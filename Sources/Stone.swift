// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A smooth stone resting on the slope, lit from up and to the left, where the sun is (docs/slope.md, 1.4). It is
/// the slope's one mark: a level's pebble on its ledge, and with words beside it (`Stone`) every control.
struct SlopePebble: View {
    enum Kind {
        /// Done, switched on, or able to act: pale and warm, with a glow.
        case lit
        /// The one way on: the brightest, its glow breathing.
        case next
        /// Closed, or switched off: the water's own grey, no glow or highlight.
        case dull
        /// Prism's: cool white.
        case pale
        /// On Escapement's paper: an ink outline hatched on its shaded side.
        case engraved
    }

    var kind = Kind.lit
    /// The stone's width in points; it is 0.72 as tall (`SlopeLay.half` is half of it on a ledge).
    var width: CGFloat
    /// Each stone lies a little off level, its own way.
    var lean = Angle.zero
    /// The glow's colour: a tier's or a pack's, amber while armed; warm when nil.
    var glow: Color?
    /// The glow swells and falls over this many seconds: 3 for the way on, 1.2 while something is pending. Reduce
    /// Motion holds it full.
    var breath: Double?
    /// A dull stone drawn at 0.9: a closed level's, a control with nothing to act on. A level that is open but
    /// unsolved is dull and whole.
    var dimmed = false

    /// How a stone numbered `n` leans.
    static func lean(_ n: Int) -> Angle { .radians(0.22 * sin(Double(n) * 1.7 + 0.5)) }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.slopeStill) private var stilled
    @State private var swollen = false

    private var stops: [Color] {
        switch kind {
        case .lit: [Color(0xFFFBEE), Color(0xE8DAC0), Color(0x968470)]
        case .next: [Color(0xFFFFFA), Color(0xFAF0D6), Color(0xC4AA82)]
        case .dull: [Color(0x687A82), Color(0x42545E), Color(0x222E38)]
        case .pale: [Color(0xECF0F6), Color(0xC4CCD8), Color(0x707888)]
        case .engraved: [.bone, .bone, .bone]
        }
    }

    var body: some View {
        let height = width * 0.72, rx = width / 2
        ZStack {
            if kind != .dull, kind != .engraved {
                let light = glow ?? (kind == .pale ? Color(0xE2ECFF) : Color(0xFFE8B4))
                let reach = rx * (kind == .next ? 5.9 : 2.9), strength = kind == .next ? 0.24 : 0.3
                Circle().fill(RadialGradient(colors: [light.opacity(strength), light.opacity(0)], center: .center, startRadius: 0, endRadius: reach))
                    .frame(width: reach * 2, height: reach * 2)
                    .opacity(breath != nil && !reduceMotion && !swollen ? 0.86 : 1)
            }
            if kind == .engraved {
                engraving(height)
            } else {
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
                .opacity(dimmed ? 0.9 : 1)
            }
        }
        .frame(width: width, height: height)
        .alignmentGuide(.stoneSeat) { $0[.bottom] - 0.07 * $0.height }
        .alignmentGuide(.stoneMiddle) { $0[HorizontalAlignment.center] }
        .onAppear {
            guard let breath, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: breath / 2).repeatForever(autoreverses: true)) { swollen = true }
        }
        .onChange(of: stilled) {
            // Still water: the glow breathes out and holds, and breathes again at a touch.
            guard let breath, !reduceMotion else { return }
            let out = Animation.easeInOut(duration: breath / 2)
            withAnimation(stilled ? out : out.repeatForever(autoreverses: true)) { swollen = !stilled }
        }
        .accessibilityHidden(true)
    }

    /// The paper's stone: its outline, heavier underneath, and a few strokes of hatching on the side away from the sun.
    private func engraving(_ height: CGFloat) -> some View {
        ZStack {
            Ellipse().fill(Color.bone)
            Ellipse().stroke(Color.ink, lineWidth: 1)
            Ellipse().trim(from: 0.02, to: 0.42).stroke(Color.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            Canvas { context, size in
                for i in 0 ..< 4 {
                    let x = size.width * (0.5 + 0.1 * CGFloat(i))
                    var stroke = Path()
                    stroke.move(to: CGPoint(x: x, y: size.height * (0.86 - 0.05 * CGFloat(i))))
                    stroke.addLine(to: CGPoint(x: x + size.width * 0.12, y: size.height * (0.56 - 0.02 * CGFloat(i))))
                    context.stroke(stroke, with: .color(.ink), lineWidth: 0.8)
                }
            }
            .clipShape(Ellipse())
        }
        .frame(width: width, height: height)
        .rotationEffect(lean)
    }
}

extension VerticalAlignment {
    private enum StoneSeat: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context[.bottom] }
    }

    /// A pebble's underside, a little into the sand: what `rested(at:)` sets on the ground, through whatever the
    /// pebble stands in (a `Stone` and its words).
    static let stoneSeat = VerticalAlignment(StoneSeat.self)
}

extension HorizontalAlignment {
    private enum StoneMiddle: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat { context[HorizontalAlignment.center] }
    }

    /// A pebble's middle.
    static let stoneMiddle = HorizontalAlignment(StoneMiddle.self)
}

/// What a stone is doing (1.4). The look follows: lit, the way on, dull, armed in amber, or pending.
enum StoneState {
    /// A control that can act; a switch that is on.
    case lit
    /// The one way on. One stone a screen.
    case next
    /// Switched off, or with nothing to act on. It still takes its tap, to say why.
    case dull
    /// Waiting on a second tap, as reset: its glow and words amber.
    case armed
    /// Waiting on an answer, as a purchase: its glow breathing, its words quieter.
    case pending
}

/// A stone with words beside it, to tap: the slope's one control. The words keep their size at every Dynamic Type
/// setting and the stone grows a little with them; the target is the stone and its words together, never under 44
/// points either way. Touched, the stone sinks 2 points and draws in to 0.97. `refused` rocks it when it changes, as a
/// closed level's does, with the `seized` sound. It sounds as every button does.
struct Stone<Label: View>: View {
    var state = StoneState.lit
    /// Prism's own controls are pale, and every stone on Escapement's paper engraved.
    var pale = false
    var engraved = false
    /// The stone after the words: the words stand on the open-water side.
    var trailing = false
    /// A tier's or a pack's colour for the way on's glow, and its ink for the words.
    var glow: Color?
    var ink: Color?
    /// Bump it to refuse a tap.
    var refused = 0
    /// What a tap sounds: undo's and reset's are their own.
    var effect = Sound.Effect.tap
    /// How far the pebble stands under its words' middle: on the lone terrace the pebble rests on the sand while its
    /// words stay over the water above it.
    var sunk: CGFloat = 0
    var action: () -> Void
    @ViewBuilder var label: () -> Label

    var body: some View {
        Button(action: action) {
            Face(state: state, pale: pale, engraved: engraved, trailing: trailing, glow: glow, ink: ink, refused: refused, sunk: sunk,
                 label: label)
        }
        .buttonStyle(Sounding(effect: effect, presses: true))
    }

    private struct Face: View {
        var state: StoneState
        var pale: Bool
        var engraved: Bool
        var trailing: Bool
        var glow: Color?
        var ink: Color?
        var refused: Int
        var sunk: CGFloat
        @ViewBuilder var label: () -> Label

        @Environment(\.buttonPressed) private var pressed
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @ScaledMetric(relativeTo: .body) private var grain = 1.0

        private var kind: SlopePebble.Kind {
            if engraved { return .engraved }
            switch state {
            case .dull: return .dull
            case .next: return pale ? .pale : .next
            case .lit, .armed, .pending: return pale ? .pale : .lit
            }
        }

        var body: some View {
            let width = (state == .next ? 25 : state == .dull ? 17 : 20) * min(grain, 1.4)
            HStack(spacing: 12) {
                if trailing { words }
                SlopePebble(kind: kind, width: width, lean: .radians(trailing ? 0.1 : -0.08),
                            glow: state == .armed ? Page.night.stop : glow,
                            breath: state == .next ? 3 : state == .pending ? 1.2 : nil, dimmed: state == .dull)
                    .modifier(StoneRock(refused: refused, still: reduceMotion))
                    .alignmentGuide(VerticalAlignment.center) { $0[VerticalAlignment.center] - sunk }
                    .offset(y: pressed && !reduceMotion ? 2 : 0)
                    .scaleEffect(pressed ? 0.97 : 1)
                    .brightness(pressed && reduceMotion ? -0.12 : 0)
                if !trailing { words }
            }
            .frame(minWidth: SlopePebble.target, minHeight: SlopePebble.target)
            .contentShape(Rectangle())
            .animation(.easeOut(duration: 0.2), value: pressed)
            .onChange(of: refused) { Sound.shared.play(.seized) }
        }

        private var words: some View {
            let colour: Color = engraved ? .ink : state == .armed ? Page.night.stop : ink ?? SlopeInk.ink.colour
            return label().font(.slope(.ui, .body, state == .next ? .medium : nil)).foregroundStyle(colour)
                .opacity(engraved ? 1 : state == .dull ? SlopeInk.ink4.strength : state == .pending ? SlopeInk.ink2.strength : 1)
        }
    }
}

/// A refused stone rocks 6° either way twice in 0.3 s; under Reduce Motion it stays where it is.
private struct StoneRock: ViewModifier {
    var refused: Int
    var still: Bool

    func body(content: Content) -> some View {
        let reach = still ? 0.0 : 6.0
        content.keyframeAnimator(initialValue: 0.0, trigger: refused) { stone, degrees in
            stone.rotationEffect(.degrees(degrees), anchor: .bottom)
        } keyframes: { _ in
            CubicKeyframe(reach, duration: 0.05)
            CubicKeyframe(-reach, duration: 0.08)
            CubicKeyframe(reach, duration: 0.07)
            CubicKeyframe(-reach, duration: 0.06)
            CubicKeyframe(0, duration: 0.04)
        }
    }
}

extension SlopePebble {
    /// Apple's smallest target, which no stone's is under either way.
    static let target: CGFloat = 44
}

extension Stone where Label == Text {
    init(_ words: Text, state: StoneState = .lit, pale: Bool = false, engraved: Bool = false, trailing: Bool = false,
         glow: Color? = nil, ink: Color? = nil, refused: Int = 0, effect: Sound.Effect = .tap, sunk: CGFloat = 0,
         action: @escaping () -> Void) {
        self.init(state: state, pale: pale, engraved: engraved, trailing: trailing, glow: glow, ink: ink, refused: refused, effect: effect,
                  sunk: sunk, action: action) { words }
    }
}
