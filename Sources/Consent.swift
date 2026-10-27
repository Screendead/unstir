// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Every word the question and the settings sheet say.
enum ConsentWords {
    static let title = "Help improve Unstir?"
    static let body = "Let the game tell us how you play. Never who you are."
    static let sendsLink = "What does it send? \u{203A}"
    static let sends = "If you say yes, the game tells us how you play: which puzzles you finish, how many moves and "
        + "undos they take, which days you play, which packs you buy, and roughly which country you're in. It never "
        + "sends your name, your Apple ID, or anything that tells us who you are. You can change your mind any time in "
        + "settings."
    static let yes = "Yes"
    static let no = "No"

    static let settings = "settings"
    static let analytics = "analytics"
    static let analyticsOn = "on \u{00B7} how you play, never who you are"
    static let analyticsOff = "off \u{00B7} nothing is sent"
    static let sendLog = "send log"
    static let sendLogDetail = "what the game noted as you played, for a bug"
}

/// The first launch's question, over the menu, which waits for an answer. Yes and no are the same control: same type,
/// colour, size and weight in the row, neither one picked out.
struct ConsentCard: View {
    let tier: Tier
    /// The link's list, under the line once tapped; UNSTIR_CONSENT=sends opens with it shown.
    @State private var sends = Analytics.shared.opensSends
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.78).ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {}
                .accessibilityHidden(true)
            // Scrolls only where the words outgrow the screen.
            ViewThatFits(in: .vertical) {
                card
                ScrollView { card.padding(.vertical, 20) }.scrollBounceBehavior(.basedOnSize)
            }
        }
        .foregroundStyle(Color.text)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(ConsentWords.title).font(.mono(15, .semibold))
                .accessibilityAddTraits(.isHeader)
            Text(ConsentWords.body)
                .font(.mono(12)).opacity(0.6).lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            if sends {
                Text(ConsentWords.sends)
                    .font(.mono(12)).opacity(0.6).lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            } else {
                Button {
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { sends = true }
                } label: {
                    Text(ConsentWords.sendsLink).font(.mono(12)).foregroundStyle(Color.neonCyan)
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(Sounding())
            }
            HStack(spacing: 14) {
                answer(ConsentWords.yes, true)
                answer(ConsentWords.no, false)
            }
            .padding(.top, 8)
        }
        .padding(22)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(tier.sweep, lineWidth: 1).opacity(0.7))
        .shadow(color: tier.glow.opacity(0.35), radius: 18)
        .padding(.horizontal, 20)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private func answer(_ word: String, _ yes: Bool) -> some View {
        Button { Analytics.shared.decide(yes) } label: {
            Text(word).font(.mono(15, .medium))
                .frame(maxWidth: .infinity, minHeight: 44)
                .overlay(Capsule().strokeBorder(Color.text.opacity(0.4), lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(Sounding())
    }
}

/// A switch drawn in the game's line: a hairline capsule off, lit cyan on.
struct NeonToggle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(alignment: .center, spacing: 12) {
                configuration.label
                Spacer(minLength: 8)
                Knob(on: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(Sounding())
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(configuration.isOn ? "on" : "off")
    }

    private struct Knob: View {
        let on: Bool
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            ZStack(alignment: on ? .trailing : .leading) {
                Capsule().fill(on ? Color.neonCyan.opacity(0.18) : .clear)
                Capsule().strokeBorder(on ? Color.neonCyan : Color.text.opacity(0.4), lineWidth: 1)
                Circle().fill(on ? Color.neonCyan : Color.text.opacity(0.5)).padding(4)
                    .shadow(color: on ? .neonCyan : .clear, radius: 5)
            }
            .frame(width: 50, height: 28)
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .snappy(duration: 0.25), value: on)
        }
    }
}

/// The gear's sheet: the analytics switch and the log, black, sized to what it holds.
struct SettingsSheet: View {
    @State private var height: CGFloat = 220

    var body: some View {
        let analytics = Analytics.shared
        VStack(alignment: .leading, spacing: 10) {
            Text(ConsentWords.settings).font(.mono(11, .semibold)).opacity(0.5).padding(.top, 26)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) {
                Toggle(isOn: Binding(get: { analytics.consent == .yes }, set: { analytics.decide($0) })) {
                    row(ConsentWords.analytics,
                        analytics.consent == .yes ? ConsentWords.analyticsOn : ConsentWords.analyticsOff)
                }
                .toggleStyle(NeonToggle())
                .padding(.vertical, 12)
                Rectangle().fill(Color.text.opacity(0.12)).frame(height: 1)
                ShareLink(item: Log.url) {
                    HStack(alignment: .center, spacing: 12) {
                        row(ConsentWords.sendLog, ConsentWords.sendLogDetail)
                        Spacer(minLength: 8)
                        Text("\u{2197}").font(.mono(15, .medium)).foregroundStyle(Color.amber)
                            .shadow(color: .amber, radius: 4)
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .shareTap()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .foregroundStyle(Color.text)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents([.height(height)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(0x0B0C10))
        .presentationCornerRadius(24)
    }

    private func row(_ name: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.mono(14))
            Text(detail).font(.mono(11)).opacity(0.4)
        }
    }
}
