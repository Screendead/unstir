// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What a ledge's row says (docs/slope.md, 2.2), as plain values: a tier's level on the menu, a pack's on its own
/// slope, the daily on its ledge. Whoever owns the column works these out; `SlopeLedgeRow` draws them.
struct SlopeLedge: Equatable {
    enum State {
        /// It has a best: a lit pebble, its marks filled by the best.
        case solved
        /// Started, no best yet: a dull pebble, undimmed, three hollow marks.
        case tried
        /// The one way on: the `next` pebble, its name large.
        case frontier
        /// The way on's pebble beside a row's ordinary words: the daily until it is solved.
        case next
        /// Open, and not the frontier: a dull pebble, undimmed.
        case open
        /// Closed: a dull pebble dimmed, every word at `ink4`; a tap rocks it and says what opens it.
        case closed
    }

    /// The stones and words of the place: the slope's warm ones, Prism's pale ones, or Escapement's engraving in the
    /// page's ink.
    enum Look { case warm, pale, engraved }

    /// "14"; nil where the row has none (the daily).
    var number: String?
    var name: String
    var state = State.open
    /// The result marks after the name, 0 to 3 filled; nil hides them (never started, closed).
    var marks: Int?
    /// "+2" before the marks, over par.
    var margin: String?
    /// A word in the marks' place: Escapement's result, which has no par, or "new".
    var word: String?
    /// Under the name: "4 rods · par 4", the daily's run. Nil leaves the line out.
    var facts: String?
    /// Being played beside the menu: "playing" in the facts' place.
    var playing = false
    /// What opens a closed row, said in the facts' place for two seconds when it is tapped.
    var opens: String?
    var look = Look.warm
    /// The pebble's glow where it is lit: its rock's, a pack's.
    var glow: Color?
    /// VoiceOver's label, value and hint for the whole row.
    var label = "", value = "", hint = ""

    var closed: Bool { state == .closed }
}

/// A ledge's row on a column's dive: the pebble on its ledge and, from 18 pt past the lip, its number, name and marks
/// over its facts. It is one control, its target the row from the screen's leading edge to the end of its words'
/// room. It belongs in a `SlopeLayer` (a `SlopeDive`'s or a `SlopeScene`'s content) and places itself from `view`.
/// Until the depth has opened (`near` 0) it is the pebble alone, too small to tap.
struct SlopeLedgeRow: View {
    let ledge: SlopeLedge
    let view: SlopeView
    /// The column's ledge it rests on.
    let n: Int
    /// How far the words have arrived, 0 to 1: they fade in as the depth opens.
    var near = 1.0
    /// The top bars' height: the words fade out as they rise to the bars.
    var bars: CGFloat = 0
    /// A closed row's line held up, for a still.
    var held = false
    /// A tap on an open row.
    let open: () -> Void
    /// A tap on a closed row, after the pebble has rocked and said why.
    var refused: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .title) private var leading = 28 * 1.15
    @State private var refusal = Refusal()

    private var lay: SlopeLay { view.lay }
    private var large: Bool { typeSize.isAccessibilitySize }
    private var frontier: Bool { ledge.state == .frontier }
    private var leads: Bool { frontier || ledge.state == .next }

    /// Where the words start, and the room they have before the trailing margin.
    static func words(_ view: SlopeView, _ n: Int, large: Bool) -> (x: CGFloat, width: CGFloat) {
        let x = large ? 96 : view.lip(n).x + 18
        return (x, max(view.size.width - x - 16, 80))
    }

    private var half: CGFloat { lay.half(ledge.state == .solved ? .lit : leads ? .next : .dull) }

    var body: some View {
        let seat = view.seat(n)
        if near <= 0 {
            pebble.seated(at: seat)
        } else {
            let at = Self.words(view, n, large: large), half = half
            // The first line's baseline under the row's top, as `Text` lays it out: the pebble is set from it.
            let ascent = frontier ? UIFont.systemFont(ofSize: leading, weight: .light).ascender
                : SlopeMeasure.font(.body, at: typeSize).ascender
            Button {
                if ledge.closed {
                    refuse()
                } else {
                    Sound.shared.play(.tap)
                    open()
                }
            } label: {
                words.frame(width: at.width, alignment: .leading).opacity(near).slopeUnderBars(bars)
                    .padding(.leading, at.x)
                    .hit(12, 0)
                    .overlay(alignment: Alignment(horizontal: .leading, vertical: .firstTextBaseline)) {
                        pebble
                            .alignmentGuide(.leading) { $0.width / 2 - seat.x }
                            .alignmentGuide(.firstTextBaseline) { $0.height * 0.93 - 0.6 * half + 0.38 * ascent }
                    }
            }
            .buttonStyle(SlopeLedgePress())
            .allowsHitTesting(near >= 1)
            .modifier(Speech((ledge.label, ledge.value, ledge.hint)))
            .slopeLine(CGPoint(x: 0, y: seat.y - half * 0.6))
        }
    }

    private var pebble: some View {
        let kind: SlopePebble.Kind = switch (ledge.look, ledge.state) {
        case (.engraved, _): .engraved
        case (_, .tried), (_, .open), (_, .closed): .dull
        case (.pale, _): .pale
        case (.warm, .frontier), (.warm, .next): .next
        case (.warm, .solved): .lit
        }
        return SlopeLedgePebble(kind: kind, width: half * 2, lean: SlopePebble.lean(n), glow: ledge.glow, breath: leads ? 3 : nil,
                                dimmed: ledge.closed, rocks: refusal.taps)
    }

    private func ink(_ ink: SlopeInk) -> Color {
        let ink = ledge.closed ? SlopeInk.ink4 : ink
        return ledge.look == .engraved ? Color.ink.opacity(ink.strength) : ink.colour
    }

    private var saying: Bool { (refusal.said || held) && ledge.opens != nil }

    private var words: some View {
        VStack(alignment: .leading, spacing: frontier ? 4 : 3) {
            if large {
                title(stacked: true)
            } else {
                ViewThatFits(in: .horizontal) {
                    title(stacked: false)
                    title(stacked: true)
                }
            }
            Group {
                if saying, let opens = ledge.opens {
                    Text(opens).font(.slope(.ui, .detail)).foregroundStyle(ledge.look == .engraved ? Color.ink : SlopeInk.ink.colour) // loc: verbatim localized by the row's maker
                } else if ledge.playing {
                    Text("playing").font(.slope(.ui, .detail)).foregroundStyle(ink(.ink2))
                } else if let facts = ledge.facts {
                    Text(facts).font(.slope(.data, frontier ? .label : .detail)).foregroundStyle(ink(frontier ? .ink2 : .ink3)) // loc: verbatim localized by the row's maker
                }
            }
            .transition(.opacity)
        }
        .multilineTextAlignment(.leading)
        .animation(.easeOut(duration: 0.2), value: saying)
    }

    /// The number and name, with the marks after the name on its baseline, or `stacked` on a line of their own under
    /// it where the name needs the room.
    private func title(stacked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                if let number = ledge.number {
                    Text(number).font(.slope(.data, frontier ? .body : .label)).foregroundStyle(ink(.ink3)) // loc: verbatim a number
                }
                Text(ledge.name) // loc: verbatim localized by the row's maker
                    .font(frontier ? .system(size: leading, weight: .light) : .slope(.ui, .body)).foregroundStyle(ink(.ink))
                    .fixedSize(horizontal: !stacked, vertical: true)
                if !stacked { result.padding(.leading, 3) }
            }
            if stacked { result }
        }
    }

    @ViewBuilder private var result: some View {
        if let word = ledge.word {
            Text(word).font(.slope(.data, .detail)).foregroundStyle(ink(ledge.state == .solved ? .ink2 : .ink)) // loc: verbatim localized by the row's maker
        } else if let marks = ledge.marks, !ledge.closed {
            ResultMarks(filled: marks, margin: ledge.margin)
        }
    }

    /// The pebble rocks, the knob's seized sound plays, and what opens the row stands for two seconds.
    private func refuse() {
        Sound.shared.play(.seized)
        let tap = refusal.tap()
        refused()
        Task {
            try? await Task.sleep(for: .seconds(Refusal.hold))
            refusal.lapse(tap)
        }
    }
}

extension View {
    /// Words on a column that fade out as their first line rises to the top bars, `bars` tall, and are gone before it
    /// reaches them.
    func slopeUnderBars(_ bars: CGFloat) -> some View {
        visualEffect { words, place in
            let frame = place.frame(in: .global)
            return words.opacity(bars > 0 ? min(max((frame.minY + min(frame.height, 30) - bars) / 28, 0), 1) : 1)
        }
    }
}

/// A row's press reaches its pebble, which sinks as any stone does. The row sounds itself: a tap as it opens, the
/// seized knob as it refuses.
private struct SlopeLedgePress: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.environment(\.buttonPressed, configuration.isPressed)
    }
}

/// A ledge's pebble as a control's stone: touched it sinks 2 points and draws in, refused it rocks 6° either way
/// twice (1.4). Reduce Motion keeps it still and darkens it under the finger instead.
struct SlopeLedgePebble: View {
    var kind: SlopePebble.Kind
    var width: CGFloat
    var lean = Angle.zero
    var glow: Color?
    var breath: Double?
    var dimmed = false
    /// Bump it to rock the pebble.
    var rocks = 0

    @Environment(\.buttonPressed) private var pressed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        SlopePebble(kind: kind, width: width, lean: lean, glow: glow, breath: breath, dimmed: dimmed)
            .keyframeAnimator(initialValue: 0.0, trigger: rocks) { stone, degrees in
                stone.rotationEffect(.degrees(reduceMotion ? 0 : degrees), anchor: .bottom)
            } keyframes: { _ in
                CubicKeyframe(6, duration: 0.05)
                CubicKeyframe(-6, duration: 0.08)
                CubicKeyframe(6, duration: 0.07)
                CubicKeyframe(-6, duration: 0.06)
                CubicKeyframe(0, duration: 0.04)
            }
            .offset(y: pressed && !reduceMotion ? 2 : 0)
            .scaleEffect(pressed ? 0.97 : 1)
            .brightness(pressed && reduceMotion ? -0.12 : 0)
            .animation(.easeOut(duration: 0.2), value: pressed)
    }
}

/// The slope's words measured before they are drawn, where a column needs their height to make room for them: a
/// header's, a row's that wraps.
enum SlopeMeasure {
    static func font(_ size: SlopeSize, at type: DynamicTypeSize) -> UIFont {
        .preferredFont(forTextStyle: size.ui, compatibleWith: UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(type)))
    }

    /// A line of the size.
    static func line(_ size: SlopeSize, at type: DynamicTypeSize) -> CGFloat { font(size, at: type).lineHeight }

    /// The height of `text` wrapped to `width`, to within a line of how `Text` sets it: the faces differ a little in
    /// width, so a caller leaves a line's slack where a wrap is close.
    static func height(_ text: String, _ size: SlopeSize, width: CGFloat, at type: DynamicTypeSize) -> CGFloat {
        let font = font(size, at: type)
        let box = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                  options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [.font: font], context: nil)
        return max((box.height / font.lineHeight).rounded(), 1) * font.lineHeight
    }
}

private extension SlopeSize {
    var ui: UIFont.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title: .title1
        case .body: .body
        case .label: .subheadline
        case .detail: .footnote
        }
    }
}
