// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A closed tier's gate, its header on the slope (docs/slope.md, 2.3): its name, what opens it, the tier above as a
/// tally of small pebbles on one sill of its own rock, lit for each level solved, and the levels still short as runs,
/// each a quiet control that opens its first.
struct SlopeGate: View {
    let tier: Tier
    let below: Tier
    /// The closed tier's rock, which the sill is cut from.
    let rock: SlopeColumn.Rock
    /// The words' room.
    let width: CGFloat
    let pick: (Level) -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let gate = Menu.gate(below)
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tier.word).font(.slope(.place, .title)).ink(.ink4) // loc: verbatim localized by Tier.word
                Text(Menu.reason(tier) ?? "").font(.slope(.ui, .detail)).ink(.ink2) // loc: verbatim localized by Menu.reason
                SlopeTally(solved: gate.solved, rock: rock, glow: below.rock.light).frame(width: min(width, SlopeTally.full))
                    .padding(.top, 14)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(tier.spoken) // loc: verbatim localized by Tier.spoken
            .accessibilityAddTraits(.isHeader)
            short.padding(.top, 8)
        }
        .frame(width: width, alignment: .leading)
        .multilineTextAlignment(.leading)
    }

    /// The gate's height at a type size, for the room its stretch leaves over its first ledge.
    static func height(_ tier: Tier, below: Tier, width: CGFloat, at type: DynamicTypeSize) -> CGFloat {
        let runs = below.short().count
        // A run is about five characters and its dot; they wrap as a flow does.
        let label = SlopeMeasure.font(.label, at: type)
        let across = max(Int((width - 4 * label.pointSize) / (4.2 * label.pointSize)), 1)
        let lines = runs == 0 ? 0 : CGFloat((runs + across - 1) / across)
        return SlopeMeasure.line(.title, at: type) + 3
            + SlopeMeasure.height(Menu.reason(tier) ?? "", .detail, width: width, at: type)
            + 3 + 14 + SlopeTally.height + 8 + lines * max(label.lineHeight, 36)
    }

    /// "short: 21–27", each run in the ink of the tier above.
    @ViewBuilder private var short: some View {
        let runs = below.short(), levels = below.levels
        if !runs.isEmpty {
            SlopeFlow {
                Text("short:").font(.slope(.ui, .label)).ink(.ink3).frame(minHeight: 36).padding(.trailing, 4)
                    .accessibilityHidden(true)
                ForEach(Array(runs.enumerated()), id: \.offset) { i, run in
                    let first = levels[run.lowerBound], last = levels[run.upperBound]
                    // One view with the dot after it, so a wrapped line never starts on a dot.
                    HStack(spacing: 0) {
                        Button { pick(first) } label: {
                            Text(verbatim: run.count == 1 ? first.label : "\(first.label)\u{2013}\(last.label)")
                                .font(.slope(.ui, .label, .medium)).foregroundStyle(below.ink)
                                .padding(.horizontal, 6).frame(minWidth: 36, minHeight: 36).hit(4, 0)
                        }
                        .accessibilityLabel(run.count == 1 // loc: verbatim each a key
                            ? Text("\(below.word) \(first.label), unsolved", comment: "VoiceOver: a level not yet solved. Its tier, its number")
                            : Text("\(below.word) \(first.label) to \(last.label), unsolved",
                                   comment: "VoiceOver: levels not yet solved. Their tier, the first number, the last"))
                        .accessibilityHint(Text("Opens \(below.word) \(first.label)", comment: "VoiceOver: a level not yet solved. Its tier, its number"))
                        if i < runs.count - 1 {
                            Text(verbatim: "\u{00B7}").font(.slope(.ui, .label)).ink(.ink4).frame(minHeight: 36).accessibilityHidden(true)
                        }
                    }
                }
            }
        }
    }
}

extension Tier {
    /// The tier's rock on the slope.
    var rock: SlopeColumn.Rock {
        switch self {
        case .plughole: .sand
        case .whirlpool: .mauve
        case .vortex: .slate
        case .maelstrom: .basalt
        }
    }
}

/// A tier's levels as small pebbles along one long sill, three groups of nine, lit for each solved: today's row of
/// ticks. A count, too small to pick from, and hidden from VoiceOver, which hears the count in the gate's words.
struct SlopeTally: View {
    let solved: [Bool]
    let rock: SlopeColumn.Rock
    /// The lit pebbles' glow: the rock they stand for, the tier above.
    var glow: Color?

    /// A pebble's half-width, the overview's (1.2), and the sill's whole length with its pebbles at rest.
    static let half: CGFloat = 3.9
    static let full: CGFloat = 27 * 8.8 + 2 * 9 + 16
    static let height: CGFloat = 26

    private var face: (lit: Color, dark: Color) {
        switch rock {
        case .sand: (Color(red: 0.74, green: 0.58, blue: 0.42), Color(red: 0.30, green: 0.22, blue: 0.17))
        case .mauve: (Color(red: 0.56, green: 0.34, blue: 0.56), Color(red: 0.20, green: 0.11, blue: 0.22))
        case .slate: (Color(red: 0.30, green: 0.42, blue: 0.68), Color(red: 0.08, green: 0.12, blue: 0.24))
        case .basalt: (Color(red: 0.52, green: 0.22, blue: 0.16), Color(red: 0.16, green: 0.05, blue: 0.05))
        case .pale: (Color(red: 0.62, green: 0.65, blue: 0.72), Color(red: 0.22, green: 0.24, blue: 0.29))
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, groups = CGFloat(max((solved.count + 8) / 9 - 1, 0))
            let step = (w - 16 - groups * 9) / CGFloat(max(solved.count, 1))
            // The sill's top bows 3 pt over its run and its ends taper into the water: no straight edge.
            let top: (CGFloat) -> CGFloat = { x in 13 - 3 * sin(.pi * x / w) + 0.8 * sin(x * 0.045 + 1) }
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: top(0) + 2))
                    for x in stride(from: CGFloat(0), through: w, by: 6) { p.addLine(to: CGPoint(x: x, y: top(x))) }
                    p.addQuadCurve(to: CGPoint(x: w * 0.42, y: top(w * 0.42) + 9), control: CGPoint(x: w * 0.86, y: top(w) + 11))
                    p.addQuadCurve(to: CGPoint(x: 0, y: top(0) + 2), control: CGPoint(x: w * 0.1, y: top(0) + 8))
                }
                .fill(LinearGradient(colors: [face.lit, face.dark], startPoint: .top, endPoint: .bottom))
                ForEach(Array(solved.enumerated()), id: \.offset) { i, lit in
                    let x = 8 + (CGFloat(i) + 0.5) * step + CGFloat(i / 9) * 9
                    let half = lit ? Self.half : 3.3
                    SlopePebble(kind: lit ? .lit : .dull, width: min(half * 2, step * 0.94), lean: SlopePebble.lean(i), glow: glow)
                        .position(x: x, y: top(x) - half * 0.72 * 0.86)
                }
            }
        }
        .frame(height: Self.height)
        .accessibilityHidden(true)
    }
}

/// Its views left to right, wrapping onto lines as wide as it is, each line's views on a common centre.
struct SlopeFlow: SwiftUI.Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = self.lines(subviews, width: proposal.width ?? .infinity)
        return CGSize(width: lines.map(\.width).max() ?? 0, height: lines.reduce(0) { $0 + $1.height })
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(subviews, width: bounds.width) {
            var x = bounds.minX
            for i in line.views {
                let size = subviews[i].sizeThatFits(.unspecified)
                subviews[i].place(at: CGPoint(x: x, y: y + line.height / 2), anchor: .leading, proposal: .unspecified)
                x += size.width
            }
            y += line.height
        }
    }

    private func lines(_ subviews: Subviews, width: CGFloat) -> [(views: [Int], width: CGFloat, height: CGFloat)] {
        var lines: [(views: [Int], width: CGFloat, height: CGFloat)] = []
        for (i, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            if let last = lines.last, last.width + size.width <= width {
                lines[lines.count - 1] = (last.views + [i], last.width + size.width, max(last.height, size.height))
            } else {
                lines.append(([i], size.width, size.height))
            }
        }
        return lines
    }
}
