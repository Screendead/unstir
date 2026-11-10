// Copyright © 2026 Jack Lusher. All rights reserved.

import MessageUI
import SafariServices
import SwiftUI

/// Every word the question and the settings sheet say.
enum ConsentWords {
    static let title = "Help improve Unstir?"
    static let body = "Let the game tell us how you play. Never who you are."
    static let sendsLink = "What does it send? \u{203A}"
    static let hideLink = "Hide the list \u{2039}"
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
    static let music = "music"
    static let musicDetail = "the beds under the menu and the levels"
    static let sounds = "sounds"
    static let soundsDetail = "every effect and button"
    static let haptics = "haptics"
    static let hapticsDetail = "the tank's knocks and taps"
    static let report = "report a problem"
    static let reportDetail = "with the log: touches, moves, purchases and errors"
    static let policy = "privacy policy"
    static let restore = "restore purchases"
    static let restoreDetail = "packs bought on this Apple ID"
    static let policyDetail = "what the game keeps, and why"
    static let letters = "colour letters"
    static let lettersDetail = "R, G and B on Prism's knobs"
    static let supporter = "supporter mark"
    static let supporterDetail = "\u{2726} by the title and in the daily's share line"
    static let editors = "open every tier"
    static let editorsDetail = "every level and pack too, without buying"
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
            Color.scrim.ignoresSafeArea()
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
            Text(ConsentWords.title).font(.ui(.title))
                .accessibilityAddTraits(.isHeader)
            Text(ConsentWords.body)
                .font(.ui(.label)).foregroundStyle(Color.text2).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { sends.toggle() }
            } label: {
                Text(sends ? ConsentWords.hideLink : ConsentWords.sendsLink).font(.ui(.label))
                    .foregroundStyle(Color.neonCyan)
                    .frame(minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(Sounding())
            .accessibilityValue(sends ? "shown" : "hidden")
            if sends {
                Text(ConsentWords.sends)
                    .font(.ui(.label)).foregroundStyle(Color.text2).lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
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

    /// Both secondary: a consent must not nudge.
    private func answer(_ word: String, _ yes: Bool) -> some View {
        UnstirButton(.secondary) { Analytics.shared.decide(yes) } label: {
            Text(word).frame(maxWidth: .infinity)
        }
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
                Capsule().strokeBorder(on ? Color.neonCyan : Color.line, lineWidth: 1)
                Circle().fill(on ? Color.neonCyan : Color.text3).padding(4)
                    .shadow(color: on ? .neonCyan : .clear, radius: 5)
            }
            .frame(width: 50, height: 28)
            .animation(reduceMotion ? .easeInOut(duration: 0.15) : .snappy(duration: 0.25), value: on)
        }
    }
}

/// The gear's sheet: music, sounds, haptics, the colour letters, the supporter mark once a pack is owned, the analytics
/// switch where the build has analytics, restore, a report of a problem and the privacy policy, and the version under them, on `surface`, sized to what it holds.
struct SettingsSheet: View {
    /// The presenting window's height, which in Split View or on a folding phone's displays is not the screen's.
    let window: CGFloat
    /// The most the sheet may rise from the window's foot, where something must stay clear above it: the tabletop's
    /// fold. Nil anywhere else.
    var room: CGFloat? = nil
    /// Apple's guideline 5.1.1(i) wants it reachable in the app. Info.plist's `PolicyURL`, set outside the repo, or
    /// the plain github.com page where the build has none.
    static var policy: URL {
        let set = (Bundle.main.object(forInfoDictionaryKey: "PolicyURL") as? String).flatMap(URL.init(string:))
        return set.flatMap { ["https", "http"].contains($0.scheme) ? $0 : nil }
            ?? URL(string: "https://github.com/Screendead/unstir/blob/master/docs/privacy-policy.md")!
    }

    /// Info.plist's `SupportAddress`, set outside the repo; nil where the build has none.
    static var support: String? {
        (Bundle.main.object(forInfoDictionaryKey: "SupportAddress") as? String).flatMap { $0.contains("@") ? $0 : nil }
    }

    @State private var height: CGFloat = 220
    // Mirrors of the stored switches, so each moves as it is tapped.
    @State private var music = Settings.music
    @State private var sounds = Settings.sounds
    @State private var haptics = Settings.haptics
    /// Nil until chosen, so the switch shows Differentiate Without Colour's state until then.
    @State private var letters = Letters.choice
    /// The menu's, so its title gains or drops the mark behind the sheet as the switch moves.
    @Binding var supporter: Bool
    @State private var unlocked = Best.unlocked
    @State private var mailing = false
    @State private var reading = false
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    var store = Store.shared

    var body: some View {
        let analytics = Analytics.shared
        // Scrolls, with a large detent, only where large type outgrows the screen.
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(ConsentWords.settings).font(.ui(.title)).padding(.top, 26)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 0) {
                    switchRow(ConsentWords.music, ConsentWords.musicDetail, $music) {
                        Settings.music = $0
                        Sound.shared.music($0)
                    }
                    switchRow(ConsentWords.sounds, ConsentWords.soundsDetail, $sounds) {
                        Settings.sounds = $0
                        Sound.shared.sounds($0)
                        // The switch's own tap went out while sounds were off.
                        if $0 { Sound.shared.play(.tap) }
                    }
                    switchRow(ConsentWords.haptics, ConsentWords.hapticsDetail, $haptics) { Settings.haptics = $0 }
                    switchRow(ConsentWords.letters, ConsentWords.lettersDetail,
                              Binding(get: { letters ?? differentiate }, set: { letters = $0 })) { Letters.choice = $0 }
                    if store.bought {
                        switchRow(ConsentWords.supporter, ConsentWords.supporterDetail, $supporter) { Settings.supporter = $0 }
                    }
                    #if EDITORS || DEBUG
                    if Build.editorsSwitch {
                        switchRow(ConsentWords.editors, ConsentWords.editorsDetail, $unlocked) { Best.unlocked = $0 }
                    }
                    #endif
                    if analytics.shown {
                        Toggle(isOn: Binding(get: { analytics.consent == .yes }, set: { analytics.decide($0) })) {
                            row(ConsentWords.analytics,
                                analytics.consent == .yes ? ConsentWords.analyticsOn : ConsentWords.analyticsOff)
                        }
                        .toggleStyle(NeonToggle())
                        .padding(.vertical, 12)
                        rule
                    }
                    Button { Task { await store.restoreAndAnnounce() } } label: {
                        HStack(spacing: 12) {
                            row(ConsentWords.restore, store.restoreNote ?? ConsentWords.restoreDetail)
                            Spacer(minLength: 8)
                        }
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(Sounding())
                    .disabled(store.restoring)
                    rule
                    if let to = SettingsSheet.support, MFMailComposeViewController.canSendMail() {
                        Button { mailing = true } label: { outward(ConsentWords.report, ConsentWords.reportDetail) }
                            .buttonStyle(Sounding())
                            .sheet(isPresented: $mailing) { MailSheet(to: to).ignoresSafeArea() }
                    } else if let to = SettingsSheet.support {
                        // No account in Apple's Mail, as for most who use another mail app: the address, subject and
                        // device line ride in the share sheet into whichever app takes it.
                        ShareButton(items: { ["To: \(to)\n\n\(MailSheet.body)", SubjectItem(Log.url, subject: MailSheet.subject)] }) {
                            outward(ConsentWords.report, ConsentWords.reportDetail)
                        }
                    } else {
                        ShareButton(items: { [Log.url] }) { outward(ConsentWords.report, ConsentWords.reportDetail) }
                    }
                    rule
                    Button { reading = true } label: { outward(ConsentWords.policy, ConsentWords.policyDetail) }
                        .buttonStyle(Sounding())
                        .sheet(isPresented: $reading) { SafariSheet(url: SettingsSheet.policy).ignoresSafeArea() }
                }
                Text(SettingsSheet.version).font(.ui(.detail)).foregroundStyle(Color.text3).padding(.top, 6)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            .foregroundStyle(Color.text)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: .infinity, alignment: .top)
        .presentationDetents(Self.detents(content: height, window: window, room: room))
        .presentationDragIndicator(.visible)
        .presentationBackground(Color.surface)
        .presentationCornerRadius(24)
    }

    /// Sized to what it holds, scrolling where that outgrows the window, with a large detent, or `room`, at its height.
    static func detents(content: CGFloat, window: CGFloat, room: CGFloat?) -> Set<PresentationDetent> {
        if let room { return [.height(min(content, room))] }
        return content > window * 0.9 ? [.height(window * 0.6), .large] : [.height(content)]
    }

    /// "Unstir 1.0 (1)": the version and build, "Unstir 1.0 (1) editors" in the editors' build.
    static var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let build = "Unstir \(info["CFBundleShortVersionString"] as? String ?? "?") (\(info["CFBundleVersion"] as? String ?? "?"))"
        return Build.editors ? build + " editors" : build
    }

    private var rule: some View { Rectangle().fill(Color.rule).frame(height: 1) }

    /// A stored switch: `store` keeps the choice and acts on it, the mirror moves the knob.
    private func switchRow(_ name: String, _ detail: String, _ mirror: Binding<Bool>,
                           store: @escaping (Bool) -> Void) -> some View {
        VStack(spacing: 0) {
            Toggle(isOn: Binding(get: { mirror.wrappedValue }, set: {
                store($0)
                mirror.wrappedValue = $0
                Log.write("settings: \(name) \($0 ? "on" : "off")")
            })) {
                row(name, detail)
            }
            .toggleStyle(NeonToggle())
            .padding(.vertical, 12)
            rule
        }
    }

    /// A row that opens something outside the game's own screens, a mail or a web page, marked with the amber arrow.
    private func outward(_ name: String, _ detail: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            row(name, detail)
            Spacer(minLength: 8)
            Text("\u{2197}").font(.ui(.button)).foregroundStyle(Color.amber)
                .shadow(color: .amber, radius: 4)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private func row(_ name: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name).font(.ui(.body))
            Text(detail).font(.ui(.detail)).foregroundStyle(Color.text3)
        }
    }
}

/// "report a problem": a mail to the support address, its log attached and the device line in the body.
private struct MailSheet: UIViewControllerRepresentable {
    let to: String

    static var subject: String { "\(SettingsSheet.version): a problem" }
    /// The device line, the settings' switches with it, read as the report is written.
    static var body: String { "What happened:\n\n\n\u{2014}\n\(UnstirApp.device)\n" }
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients([to])
        mail.setSubject(MailSheet.subject)
        mail.setMessageBody(MailSheet.body, isHTML: false)
        if let log = try? Data(contentsOf: Log.url) {
            mail.addAttachmentData(log, mimeType: "text/plain", fileName: "unstir-log.txt")
        }
        return mail
    }

    func updateUIViewController(_ mail: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator { dismiss() } }

    @MainActor final class Coordinator: NSObject, @preconcurrency MFMailComposeViewControllerDelegate {
        let done: () -> Void
        init(done: @escaping () -> Void) { self.done = done }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult,
                                              error: Error?) {
            done()
        }
    }
}

/// The privacy policy, read in the app.
private struct SafariSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController { SFSafariViewController(url: url) }

    func updateUIViewController(_ safari: SFSafariViewController, context: Context) {}
}
