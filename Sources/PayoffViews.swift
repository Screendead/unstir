// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The curtain call, laid over the stage: a veil on the glass and, over it, the tier's or the pack's name in its own
/// sweep above its stamp, or for the game each tier's name in turn and the completion's line, with the credit under
/// the rim. On paper the veil is bone, the name the plate's vermilion and the rest ink, with no glow.
///
/// The words are never scaled to fit. They take the column's `width`, a name too long at the display role set in the
/// smaller one, and report whether every line lies inside the glass (`Payoff.fits`): where one doesn't,
/// `place` stands them under a glass that has given up the room, with no veil, as nothing is over the picture.
struct PayoffCurtain: View {
    enum Place: Equatable {
        case over
        /// The words' top, down from the stage's.
        case under(CGFloat)
    }

    let payoff: Payoff
    let r: CGFloat
    let width: CGFloat
    let t: Double
    let place: Place
    /// Whether the lines fit over the glass, and the height they take under it.
    let measured: (_ over: Bool, _ height: CGFloat) -> Void
    let skip: () -> Void
    @State private var lines: [Int: CGRect] = [:]
    @State private var height: CGFloat = 0
    @State private var creditHeight: CGFloat = 0
    @Environment(\.page) private var page

    private static let space = "curtain"
    /// Between the stamp, or the rim, and the credit.
    private static let creditGap: CGFloat = 14

    /// How far from the glass's centre a name runs, as a share of its radius.
    private static let nameReach = 0.86

    private func up(_ line: Int) -> Double { min(max((t - payoff.rises(line)) / 0.45, 0), 1) }

    private struct Measure: Equatable {
        var lines: [Int: CGRect]
        var height, credit, r: CGFloat
    }

    var body: some View {
        let shown = min(max(t / 0.5, 0), 1) * (1 - min(max((t - payoff.lifts) / 0.4, 0), 1))
        let paper = payoff.paper, whole = payoff.whole
        Circle().fill(paper ? Color.bone.opacity(0.86) : Color.black.opacity(0.64)).frame(width: 2 * r, height: 2 * r)
            .opacity(place == .over ? 1 : 0)
            .frame(width: 2 * PlayLayout.rim * r, height: 2 * PlayLayout.rim * r)
            .overlay { if place == .over { words } }
            .overlay(alignment: .bottom) {
                if place == .over, whole { credit.alignmentGuide(.bottom) { $0[.top] }.offset(y: Self.creditGap) }
            }
            .overlay(alignment: .top) {
                if case .under(let top) = place {
                    VStack(spacing: Self.creditGap) {
                        words
                        if whole { credit }
                    }
                    .offset(y: top)
                }
            }
            .opacity(shown)
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(payoff.spoken) // loc: verbatim localized by Payoff
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text("Goes on to the result.", comment: "VoiceOver: the curtain call's hint, as activating it skips to the result card"))
            .accessibilityAction { skip() }
            .onChange(of: Measure(lines: lines, height: height, credit: creditHeight, r: r), initial: true) {
                guard lines.count == payoff.parts.count + 1, height > 0, !whole || creditHeight > 0 else { return }
                measured(Payoff.fits(Array(lines.values), height: height, r: r),
                         height + (whole ? Self.creditGap + creditHeight : 0))
            }
    }

    /// The names and the stamp, each line's place in the block read for the fit.
    private var words: some View {
        let tiers = payoff.parts, whole = payoff.whole, paper = payoff.paper
        return VStack(spacing: whole ? 10 : 8) {
            ForEach(Array(tiers.enumerated()), id: \.offset) { i, tier in
                ViewThatFits(in: .horizontal) {
                    if !whole { name(tier, .display, tracking: 5, line: i) }
                    name(tier, .displaySmall, tracking: 4, line: i)
                }
                // A name keeps clear of the rim wherever it stands, so one this wide takes the smaller role on every phone.
                .frame(maxWidth: min(width, 2 * Self.nameReach * r))
                .opacity(up(i)).scaleEffect(payoff.still ? 1 : 0.92 + 0.08 * up(i))
            }
            Text(payoff.stamp).font(.ui(.stamp)).foregroundStyle(page.ink) // loc: verbatim localized by Payoff
                .shadow(color: paper ? .clear : .white.opacity(0.5), radius: 6)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { lines[tiers.count] = $0 }
                .padding(.top, whole ? 10 : 2).opacity(up(tiers.count))
        }
        .multilineTextAlignment(.center)
        .frame(width: width)
        .fixedSize(horizontal: false, vertical: true)
        .coordinateSpace(.named(Self.space))
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
    }

    /// The name's own width is read, not the frame that bounds it.
    private func name(_ part: Payoff.Part, _ role: TypeRole, tracking: CGFloat, line: Int) -> some View {
        Text(part.name.localizedUppercase) // loc: verbatim localized by Tier, and a pack's name is never translated
            .font(.ui(role)).tracking(tracking).lineLimit(1).fixedSize()
            .foregroundStyle(LinearGradient(colors: payoff.paper ? [.plateVermilion] : part.colours, startPoint: .leading, endPoint: .trailing))
            // Its place from the block, its size its own: the frame in the block shrinks while the name scales up.
            .onGeometryChange(for: CGRect.self) { proxy in
                let frame = proxy.frame(in: .named(Self.space)), size = proxy.size
                return CGRect(x: frame.midX - size.width / 2, y: frame.midY - size.height / 2, width: size.width, height: size.height)
            } action: { lines[line] = $0 }
            .shadow(color: payoff.paper ? .clear : part.glow.opacity(0.9), radius: 14)
    }

    private var credit: some View {
        Text(Payoff.Credit.shown) // loc: verbatim localized by Payoff
            .font(.ui(.detail)).foregroundStyle(page.ink).tone(page.tone(.text3))
            .multilineTextAlignment(.center)
            .frame(width: width)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { creditHeight = $0 }
            .opacity(up(payoff.parts.count + 1))
    }
}
