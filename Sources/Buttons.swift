// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// How loudly a button asks (Jack's call DESIGN5 = A, the design pass's third change). One primary per screen says
/// where to tap; when two would compete, the second is secondary.
enum Emphasis {
    /// The one thing to do next: a stroke, a fill at 0.14 and a label in the accent, the stroke glowing.
    case primary
    /// Any other action: a `line` stroke round a label in the ink.
    case secondary
    /// Back controls and the small print: the label alone, set by the caller, with its 44 pt target drawn nowhere.
    case quiet
}

/// The look every button round the game wears, on its label, so a label that isn't a plain `Button`'s (a share
/// button's, Prism's held swatches) wears it too. Dimmed and pending are the caller's to say: the play screen's
/// controls are disabled wholesale through an opening or a settle without looking it, and undo at an empty bank stays
/// live to say when it refills.
struct ButtonFace: ViewModifier {
    var emphasis: Emphasis
    /// The primary's colour; a secondary given one stays plain, so a primary demoted beside another keeps its call site.
    var accent: Color? = nil
    /// Reset's second tap waiting (Jack's call C12, round 13): the stroke and label in amber.
    var armed = false
    /// Disabled-looking, as undo at an empty bank: the whole button at 0.4, the label unchanged.
    var dim = false
    /// Waiting on an answer, as a purchase: the whole button at 0.6.
    var pending = false
    /// The label's side padding; a swatch's letter keeps none inside its 44 pt.
    var inset: CGFloat = 20
    var minWidth: CGFloat = 0
    /// Takes the width it is given: a card's lone button, or its share of a `ButtonRow`.
    var wide = false
    /// A secondary's stroke of its own, as a swatch's channel, and its fill while `filled`, as a held swatch's.
    var edge: Color? = nil
    var strokeWidth: CGFloat = 1
    var filled = false

    static let height: CGFloat = 44
    /// TierUp's, the one taller button.
    static let tall: CGFloat = 56
    /// What a fill takes of its accent.
    static let fill = 0.14

    @Environment(\.page) private var page

    func body(content: Content) -> some View {
        Group {
            if emphasis == .quiet {
                content.hit()
            } else {
                let colour = colour
                content.font(.ui(.button)).foregroundStyle(label)
                    .padding(.horizontal, inset).padding(.vertical, 12)
                    .frame(minWidth: minWidth, maxWidth: wide ? .infinity : nil, minHeight: Self.height)
                    .background {
                        if emphasis == .primary || filled { Capsule().fill((edge ?? colour).opacity(Self.fill)) }
                    }
                    .overlay {
                        Capsule().strokeBorder(stroke, lineWidth: strokeWidth)
                            .shadow(color: emphasis == .primary ? page.glow(colour).opacity(0.5) : .clear, radius: 6)
                    }
                    .contentShape(Capsule())
                    .animation(.easeInOut(duration: 0.15), value: armed)
            }
        }
        .opacity(dim ? 0.4 : pending ? 0.6 : 1)
        .modifier(Pressed())
    }

    private var colour: Color { armed ? page.stop : emphasis == .primary ? accent ?? page.ink : page.ink }

    private var stroke: Color {
        armed || emphasis == .primary ? colour : edge ?? page.line
    }

    /// On paper an accent reads under 4.5:1 for words (the plate's vermilion 3.7:1 on bone, 3.1:1 over its own fill),
    /// so every label there is ink and the accent stays on the stroke and fill.
    private var label: Color {
        page.paper ? page.ink : armed || emphasis == .primary ? colour : page.ink
    }
}

/// Scale 0.97 while held, none under Reduce Motion: a button's press, which `Sounding(presses:)` hands its label.
struct Pressed: ViewModifier {
    @Environment(\.buttonPressed) private var pressed
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.scaleEffect(pressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: pressed)
    }
}

extension EnvironmentValues {
    @Entry var buttonPressed = false
}

extension View {
    func face(_ emphasis: Emphasis, accent: Color? = nil, armed: Bool = false, dim: Bool = false,
              pending: Bool = false) -> some View {
        modifier(ButtonFace(emphasis: emphasis, accent: accent, armed: armed, dim: dim, pending: pending))
    }
}

/// A button in one of the three emphases, sounding as it acts.
struct UnstirButton<Label: View>: View {
    let face: ButtonFace
    let effect: Sound.Effect
    let action: () -> Void
    let label: Label

    init(_ emphasis: Emphasis, accent: Color? = nil, effect: Sound.Effect = .tap, armed: Bool = false, dim: Bool = false,
         pending: Bool = false, wide: Bool = false, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        face = ButtonFace(emphasis: emphasis, accent: accent, armed: armed, dim: dim, pending: pending, wide: wide)
        self.effect = effect
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) { label.modifier(face) }.buttonStyle(Sounding(effect: effect, presses: true))
    }
}

/// A card's buttons, sharing its width equally, `gap` apart, so a lone one fills it. Where the longest label can't
/// have an equal share each keeps its own width and they share what is left; where they can't share a line they
/// stack, each the card's width.
struct ButtonRow: SwiftUI.Layout {
    static let gap: CGFloat = 12

    private func widths(_ subviews: Subviews, in width: CGFloat) -> [CGFloat]? {
        let ideal = subviews.map { $0.sizeThatFits(.unspecified).width }
        let room = width - Self.gap * CGFloat(subviews.count - 1), count = CGFloat(subviews.count)
        if (ideal.max() ?? 0) * count <= room { return ideal.map { _ in room / count } }
        let spare = room - ideal.reduce(0, +)
        return spare >= 0 ? ideal.map { $0 + spare / count } : nil
    }

    /// Each button's frame in a row `width` wide, from the row's top leading corner.
    private func frames(_ subviews: Subviews, in width: CGFloat) -> [CGRect] {
        guard !subviews.isEmpty else { return [] }
        if let widths = widths(subviews, in: width) {
            let height = zip(subviews, widths).map { $0.sizeThatFits(ProposedViewSize(width: $1, height: nil)).height }.max() ?? 0
            var x: CGFloat = 0
            return widths.map { w in
                defer { x += w + Self.gap }
                return CGRect(x: x, y: 0, width: w, height: height)
            }
        }
        var y: CGFloat = 0
        return subviews.map { view in
            let h = view.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
            defer { y += h + Self.gap }
            return CGRect(x: 0, y: y, width: width, height: h)
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ideal = subviews.map { $0.sizeThatFits(.unspecified).width }
        let width = proposal.width ?? ideal.reduce(Self.gap * CGFloat(max(subviews.count - 1, 0)), +)
        return CGSize(width: width, height: frames(subviews, in: width).map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (view, frame) in zip(subviews, frames(subviews, in: bounds.width)) {
            view.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                       proposal: ProposedViewSize(frame.size))
        }
    }
}
