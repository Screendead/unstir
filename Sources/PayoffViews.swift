// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What a payoff draws round the glass, behind the tank and scaled with it: option a's halo, the light the whirl
/// leaves behind the bezel, and option b's tally. `t` is the seconds in, endless once it has played.
struct PayoffRim: View {
    let payoff: Payoff
    /// The glass's radius; the bezel runs out to `PlayLayout.rim` of it.
    let r: CGFloat
    let t: Double

    var body: some View {
        switch payoff.option {
        case .a: halo
        case .b: tally
        case .c: EmptyView()
        }
    }

    private func light(_ colours: [Color]) -> some View {
        let sweep = AngularGradient(colors: colours + [colours[0]], center: .center, angle: .degrees(-90))
        return ZStack {
            Circle().stroke(sweep, lineWidth: 0.2 * r).blur(radius: 0.08 * r)
            Circle().stroke(sweep, lineWidth: 0.05 * r).blur(radius: 0.012 * r)
        }
        .frame(width: 2 * PlayLayout.rim * r, height: 2 * PlayLayout.rim * r)
    }

    /// The game's halo wears each tier's colours as its picture passes, then all four's.
    private var halo: some View {
        ZStack {
            if let tier = payoff.passing(at: t) { light(tier.colours).opacity(0.8) }
            light(payoff.tiers.flatMap(\.colours)).opacity(payoff.halo(at: t))
        }
        .allowsHitTesting(false)
    }

    private static func colour(_ mark: Payoff.Mark) -> Color {
        switch mark {
        case .clean: .lime
        case .par: .amber
        case .solved: .text
        case .none: .text4
        }
    }

    /// A segment of the bezel for each level, clockwise from twelve, lit in its best's colour as the card names it:
    /// clean lime, par amber, solved in the text's own. The game's four tiers take a quarter each, under an arc in
    /// the tier's glow.
    private var tally: some View {
        let band = (PlayLayout.rim - 1) * r, marks = payoff.marks, tiers = payoff.tiers
        let lit = payoff.lit(at: t), each = marks.count / tiers.count
        // The arc a tier's segments share, less a gap either side of it, and each segment's own gap.
        let span = 2 * Double.pi / Double(tiers.count), edge = tiers.count > 1 ? 0.03 : 0.0
        let slot = (span - 2 * edge) / Double(each), gap = slot * 0.16
        func arc(_ from: Double, _ to: Double, at radius: CGFloat) -> Path {
            Path { $0.addArc(center: CGPoint(x: 0, y: 0), radius: radius, startAngle: .radians(from - .pi / 2),
                             endAngle: .radians(to - .pi / 2), clockwise: false) }
        }
        return Canvas { context, size in
            context.translateBy(x: size.width / 2, y: size.height / 2)
            // The track the count runs along.
            context.stroke(arc(0, 2 * .pi, at: r + band / 2), with: .color(.black.opacity(0.55 * min(max(t / 0.2, 0), 1))),
                           lineWidth: band * 0.86)
            for pass in 0 ..< 2 {
                var layer = context
                if pass == 0 { layer.addFilter(.blur(radius: band * 0.7)) }
                for i in 0 ..< lit {
                    let from = Double(i / each) * span + edge + Double(i % each) * slot + gap / 2
                    // The newest flashes white as it lights.
                    let fresh = i == lit - 1 && lit < marks.count
                    layer.stroke(arc(from, from + slot - gap, at: r + band / 2), with: .color(fresh ? .white : Self.colour(marks[i])),
                                 lineWidth: band * 0.7)
                }
                guard tiers.count > 1 else { continue }
                for (q, tier) in tiers.enumerated() where lit > q * each {
                    let full = min(Double(lit - q * each) / Double(each), 1)
                    layer.stroke(arc(Double(q) * span + edge, Double(q) * span + edge + (span - 2 * edge) * full, at: r + band + 5),
                                 with: .color(tier.glow), lineWidth: 2)
                }
            }
        }
        .frame(width: 2 * PlayLayout.rim * r + 40, height: 2 * PlayLayout.rim * r + 40)
        .allowsHitTesting(false)
    }
}

/// Option a's game: the other tiers' last pictures, drawn over the solved one inside what the shader samples, each
/// shown from one whirl's held beat to the next's, so the whirl lets go on a picture it did not wind.
struct PayoffRelay: View {
    let payoff: Payoff
    let side: CGFloat
    let t: Double

    var body: some View {
        ZStack {
            ForEach(Array(payoff.relay.enumerated()), id: \.offset) { j, level in
                PictureLayer(picture: level.picture, side: side, seed: Int(level.label) ?? 0,
                             clock: level.picture.clock(max(t, 0), still: false), panel: level.panel)
                    .background(Color.black)
                    .opacity(payoff.relayed(j, at: t))
            }
        }
    }
}

/// Option c: the curtain call, over the glass it dims: the tier's name in its own sweep and "unstirred.", or for the
/// game each tier's name in turn, the completion's line and the credit.
struct PayoffCurtain: View {
    let payoff: Payoff
    let r: CGFloat
    let t: Double

    private func up(_ line: Int) -> Double { min(max((t - payoff.rises(line)) / 0.45, 0), 1) }

    var body: some View {
        let tiers = payoff.tiers, whole = payoff.whole
        let shown = min(max(t / 0.5, 0), 1) * (1 - min(max((t - payoff.lifts) / 0.4, 0), 1))
        ZStack {
            Circle().fill(Color.black.opacity(0.64)).frame(width: 2 * r, height: 2 * r)
            VStack(spacing: whole ? 10 : 8) {
                ForEach(Array(tiers.enumerated()), id: \.offset) { i, tier in
                    Text(tier.name.uppercased()) // loc: verbatim localized by Tier
                        .font(.ui(whole ? .displaySmall : .display)).tracking(whole ? 4 : 5)
                        .foregroundStyle(tier.sweep).shadow(color: tier.glow.opacity(0.9), radius: 14)
                        .opacity(up(i)).scaleEffect(payoff.still ? 1 : 0.92 + 0.08 * up(i))
                }
                Text(payoff.stamp).font(.ui(.stamp)) // loc: verbatim localized by Payoff
                    .shadow(color: .white.opacity(0.5), radius: 6)
                    .padding(.top, whole ? 10 : 2).opacity(up(tiers.count))
                if whole {
                    Text(Payoff.credit) // loc: verbatim localized by Payoff
                        .font(.ui(.detail)).tone(.text3).padding(.top, 14).opacity(up(tiers.count + 2))
                }
            }
            .multilineTextAlignment(.center)
            .frame(width: 2 * r)
            .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(shown)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

extension Payoff {
    /// The glass as the payoff has it at `t`: option a's whirl over the stack and the light it lets go on, option c's
    /// turn.
    func dress(_ glass: inout Unstirred, at t: Double) {
        glass.extra = entries(at: t)
        glass.turn += turn(at: t)
        let ring = wave(at: t)
        if ring >= 0 { glass.wave = SIMD3(0, 0, ring) }
    }
}
