// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The first launch's question on the slope (docs/slope.md, 9.2): no card and no scrim. The menu under it draws its
/// ground at `SlopeConsent.light` of its light, its words and pebbles hidden, and these words stand centred in the
/// open water from 0.34 of the screen. Yes and no are one control twice, on one bowed sill: neither picked out.
struct SlopeConsent: View {
    /// The ground's light while it asks.
    static let light = 0.35

    @State private var sends = Analytics.shared.opensSends
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 14) {
                    Text(ConsentWords.title).font(.slope(.name, .title)).ink(.ink) // loc: verbatim localized by ConsentWords
                        .accessibilityAddTraits(.isHeader)
                    Text(ConsentWords.body).font(.slope(.ui, .body)).ink(.ink2) // loc: verbatim localized by ConsentWords
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.3)) { sends.toggle() }
                    } label: {
                        Text(sends ? ConsentWords.hideLink : ConsentWords.sendsLink).font(.slope(.ui, .label)).ink(.ink) // loc: verbatim localized by ConsentWords
                            .frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(Sounding())
                    .accessibilityValue(sends ? Text("shown", comment: "VoiceOver: the consent's list of what is sent, open") // loc: verbatim each a key
                                        : Text("hidden", comment: "VoiceOver: the consent's list of what is sent, shut"))
                    if sends {
                        Text(ConsentWords.sends).font(.slope(.ui, .detail)).ink(.ink2) // loc: verbatim localized by ConsentWords
                            .fixedSize(horizontal: false, vertical: true)
                            .transition(.opacity)
                    }
                    sill.padding(.top, 18)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, geo.size.height * 0.34 - geo.safeAreaInsets.top)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        // Nothing under it takes a touch until it is answered.
        .background(Color.clear.contentShape(Rectangle()).onTapGesture {}.accessibilityHidden(true).ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    /// Two lit stones of one size on one bowed ledge, each word under its stone.
    private var sill: some View {
        HStack(alignment: .top, spacing: 64) {
            answer(ConsentWords.yes, true)
            answer(ConsentWords.no, false)
        }
        .background(alignment: .top) {
            Bow().fill(LinearGradient(colors: [Color(0xD9B98A), Color(0x8A6A48).opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: 230, height: 22).offset(y: 22)
                .accessibilityHidden(true)
        }
    }

    private func answer(_ word: String, _ yes: Bool) -> some View {
        Button { Analytics.shared.decide(yes) } label: {
            VStack(spacing: 10) {
                SlopePebble(kind: .lit, width: 26, lean: SlopePebble.lean(yes ? 2 : 5))
                Text(word).font(.slope(.ui, .body, .medium)).ink(.ink) // loc: verbatim localized by ConsentWords
            }
            .frame(minWidth: 64, minHeight: 64).contentShape(Rectangle())
        }
        .buttonStyle(Sounding())
    }

    /// The sill's top, bowed a few points, its underside drawn back to nothing.
    private struct Bow: Shape {
        func path(in r: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: r.minX, y: r.minY + 6))
            p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + 5), control: CGPoint(x: r.midX, y: r.minY - 4))
            p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY + 6), control: CGPoint(x: r.midX, y: r.maxY + 6))
            p.closeSubpath()
            return p
        }
    }
}

#if DEBUG
/// UNSTIR_SLOPEF=settings or =consent: piece F's screens alone over the slope, for shots before the integrator's hooks.
struct SlopeFHarness: View {
    let stage: String
    @State private var supporter = false

    init?(_ env: [String: String]) {
        guard let stage = env["UNSTIR_SLOPEF"] else { return nil }
        self.stage = stage
    }

    var body: some View {
        if stage == "consent" {
            GeometryReader { geo in
                let size = CGSize(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
                let column = SlopeColumn.main(size: size, type: .large)
                SlopeScene(column: column, focus: 0, at: SlopeScene<EmptyView>.overview(column, holding: 0, height: size.height), z: 0,
                           look: SlopeLook(light: SlopeConsent.light), clock: 0) { _ in EmptyView() }
            }
            .overlay { SlopeConsent() }
            .background(Color.black.ignoresSafeArea())
        } else {
            SlopeSettings(supporter: $supporter, back: {}, clock: 0)
        }
    }
}
#endif
