// Copyright © 2026 Jack Lusher. All rights reserved.

import MessageUI
import SwiftUI

/// Settings on the slope (docs/slope.md, 9.1): the surface high, "settings" in the air, and a ledge per row of the
/// settings' own sandstone column, each switch a stone on its ledge, lit when on. Every switch and link of
/// `SettingsSheet` is here with its behaviour; the editors' switch is compiled only where that sheet's is.
struct SlopeSettings: View {
    /// The menu's, so its title gains or drops the mark as the switch moves.
    @Binding var supporter: Bool
    var back: () -> Void
    var clock: Double?

    @State private var music = Settings.music
    @State private var sounds = Settings.sounds
    @State private var haptics = Settings.haptics
    /// Nil until chosen, so the switch shows Differentiate Without Colour's state until then.
    @State private var letters = Letters.choice
    @State private var unlocked = Best.unlocked
    @State private var mailing = false
    @State private var reading = false
    /// Each row's stone drops in from 26 pt above its ledge, 140 ms apart.
    @State private var arrived = false
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    var store = Store.shared

    private enum Kind { case toggle(Binding<Bool>, (Bool) -> Void, log: String), restore, report, policy }

    private struct Row {
        let name: String
        /// Beside the name: "on" or "off", or nothing.
        let state: String?
        let detail: String
        let kind: Kind
        var stone: Bool { if case .toggle = kind { true } else { false } }
        var on: Bool { if case let .toggle(b, _, _) = kind { b.wrappedValue } else { true } }
    }

    private var rows: [Row] {
        var rows: [Row] = []
        func toggle(_ name: LocalizedStringResource, _ detail: String, _ mirror: Binding<Bool>, _ keep: @escaping (Bool) -> Void) {
            rows.append(Row(name: String(localized: name), state: mirror.wrappedValue ? Self.on : Self.off, detail: detail,
                            kind: .toggle(mirror, keep, log: name.key)))
        }
        toggle(ConsentWords.music, ConsentWords.musicDetail, $music) {
            Settings.music = $0
            Sound.shared.music($0)
        }
        toggle(ConsentWords.sounds, ConsentWords.soundsDetail, $sounds) {
            Settings.sounds = $0
            Sound.shared.sounds($0)
            // The switch's own tap went out while sounds were off.
            if $0 { Sound.shared.play(.tap) }
        }
        toggle(ConsentWords.haptics, ConsentWords.hapticsDetail, $haptics) { Settings.haptics = $0 }
        toggle(ConsentWords.letters, ConsentWords.lettersDetail,
               Binding(get: { letters ?? differentiate }, set: { letters = $0 })) { Letters.choice = $0 }
        if store.bought {
            toggle(ConsentWords.supporter, ConsentWords.supporterDetail, $supporter) { Settings.supporter = $0 }
        }
        #if EDITORS || DEBUG
        if Build.editorsSwitch {
            toggle(ConsentWords.editors, ConsentWords.editorsDetail, $unlocked) { Best.unlocked = $0 }
        }
        #endif
        let analytics = Analytics.shared
        if analytics.shown {
            let yes = analytics.consent == .yes
            // Its own words stand in for on/off and the explanation.
            rows.append(Row(name: ConsentWords.analytics, state: nil, detail: yes ? ConsentWords.analyticsOn : ConsentWords.analyticsOff,
                            kind: .toggle(Binding(get: { analytics.consent == .yes }, set: { _ in }), { analytics.decide($0) }, log: "")))
        }
        rows.append(Row(name: ConsentWords.restore, state: nil, detail: store.restoreNote ?? ConsentWords.restoreDetail, kind: .restore))
        // Today's sheet offers it with or without a support address, sharing the log where there is none.
        rows.append(Row(name: ConsentWords.report + " \u{2197}", state: nil, detail: ConsentWords.reportDetail, kind: .report))
        rows.append(Row(name: ConsentWords.policy + " \u{2197}", state: nil, detail: ConsentWords.policyDetail, kind: .policy))
        return rows
    }

    static var on: String { String(localized: "on", comment: "Settings: a switch's state, on") }
    static var off: String { String(localized: "off", comment: "Settings: a switch's state, off") }
    static var way: String { String(localized: "\u{2193} back into the water", comment: "Settings: the way back to the menu") }
    static var back: String { String(localized: "Back", comment: "VoiceOver: settings' way back") }

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            let rows = rows
            let large = typeSize.isAccessibilitySize
            let column = column(rows, size: size, large: large)
            let lay = SlopeLay(column, z: 1)
            SlopeDive(column: column, clock: clock, near: false) { view in
                SlopeLayer {
                    // The air over the surface, which a tap on returns.
                    Color.clear.contentShape(Rectangle())
                        .frame(width: size.width, height: 0.188 * size.height)
                        .onTapGesture(perform: back)
                        .accessibilityHidden(true)
                        .slopePlace(CGPoint(x: 0, y: view.y(-0.188 * size.height)), anchor: .topLeading)
                    Text(ConsentWords.settings).font(.slope(.place, .display)).ink(.ink) // loc: verbatim localized by ConsentWords
                        .accessibilityAddTraits(.isHeader)
                        .opacity(arrived ? 1 : 0)
                        .slopePlace(CGPoint(x: 32, y: view.y(-0.188 * size.height * 0.36)), anchor: .leading)
                    ForEach(Array(rows.enumerated()), id: \.offset) { n, row in
                        let x = words(view, n, large: large)
                        if row.stone {
                            SlopePebble(kind: row.on ? .lit : .dull, width: lay.half(row.on ? .lit : .dull) * 2, lean: SlopePebble.lean(n + 3),
                                        dimmed: !row.on)
                                .offset(y: arrived || reduceMotion ? 0 : -26)
                                .opacity(arrived ? 1 : 0)
                                .animation(reduceMotion ? nil : .spring(duration: 1.1, bounce: 0.3).delay(0.2 + 0.14 * Double(n)), value: arrived)
                                .animation(reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.4), value: row.on)
                                .seated(at: view.seat(n))
                        }
                        button(row, n)
                            .frame(width: size.width - x - 16, alignment: .leading)
                            .padding(.leading, x)
                            .opacity(arrived ? 1 : 0)
                            .animation(reduceMotion ? .easeOut(duration: 0.24) : .easeOut(duration: 0.6).delay(0.12 * Double(n + 1)), value: arrived)
                            .slopePlace(CGPoint(x: 0, y: view.seat(n).y - 14), anchor: .topLeading)
                    }
                    let foot = view.y(lay.foot)
                    let last = rows.count - 1
                    Text(verbatim: SettingsSheet.version).font(.slope(.data, .detail)).ink(.ink3)
                        .slopePlace(CGPoint(x: words(view, last, large: large), y: foot - 24), anchor: .topLeading)
                        .opacity(arrived ? 1 : 0)
                    Button(action: back) {
                        Text(Self.way).font(.slope(.ui, .detail)).ink(.ink2) // loc: verbatim localized above
                            .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(Sounding())
                    .accessibilityLabel(Self.back)
                    .opacity(arrived ? 1 : 0)
                    .slopePlace(CGPoint(x: size.width / 2, y: foot + 40), anchor: .top)
                }
                .animation(reduceMotion ? .easeOut(duration: 0.24) : .easeOut(duration: 0.6), value: arrived)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .gesture(DragGesture().onEnded { if $0.startLocation.x < 24, $0.translation.width > 80 { back() } })
        .onAppear { arrived = true }
        .sheet(isPresented: $reading) { SafariSheet(url: SettingsSheet.policy).ignoresSafeArea() }
        .sheet(isPresented: $mailing) { if let to = SettingsSheet.support { MailSheet(to: to).ignoresSafeArea() } }
    }

    /// Where a row's words start: 18 past its lip, or 96 at the accessibility sizes.
    private func words(_ view: SlopeView, _ n: Int, large: Bool) -> CGFloat { large ? 96 : view.lip(n).x + 18 }

    /// The settings' column: one sandstone stretch, a ledge per row, 74 apart or what the row's words need.
    private func column(_ rows: [Row], size: CGSize, large: Bool) -> SlopeColumn {
        let lip = large ? 62 : 132 - max(440 - size.width, 0) / 2
        let room = size.width - (large ? 96 : lip + 18 + 12) - 16
        let body = TypeRole.body.line(at: typeSize).height, detail = TypeRole.detail.line(at: typeSize).height
        let needs = rows.map { row -> CGFloat in
            let name = ceil(TypeRole.body.width(of: row.name + "   off", at: typeSize) / room)
            let under = ceil(TypeRole.detail.width(of: row.detail, at: typeSize) * 1.04 / room)
            return body * name + detail * under + 32
        }
        let stretch = SlopeColumn.Stretch(rock: .sand, terraces: Array(repeating: 1, count: rows.count), rows: needs)
        return SlopeColumn(stretches: [stretch], foot: .wall, pitch: 74, lip: lip, step: large ? 1.5 : 6, first: nil)
    }

    @ViewBuilder private func button(_ row: Row, _ n: Int) -> some View {
        let words = VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(row.name).font(.slope(.ui, .body)).ink(row.on ? .ink : .ink2) // loc: verbatim localized by ConsentWords
                if let state = row.state {
                    Text(state).font(.slope(.data, .detail)).ink(row.on ? .ink2 : .ink3) // loc: verbatim localized above
                        .accessibilityHidden(true)
                }
            }
            Text(row.detail).font(.slope(.ui, .detail)).ink(.ink3) // loc: verbatim localized by ConsentWords and Store
                .accessibilityHidden(row.stone)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .contentShape(Rectangle())
        switch row.kind {
        case let .toggle(mirror, keep, log):
            Button {
                let value = !mirror.wrappedValue
                keep(value)
                mirror.wrappedValue = value
                if !log.isEmpty { Log.write("settings: \(log) \(value ? "on" : "off")") }
            } label: { words }
            .buttonStyle(Sounding())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(row.name)
            .accessibilityValue(row.on ? Self.on : Self.off)
            .accessibilityHint(row.detail)
            .accessibilityAddTraits(.isToggle)
        case .restore:
            Button { Task { await store.restoreAndAnnounce() } } label: { words }
                .buttonStyle(Sounding())
                .disabled(store.restoring)
        case .report:
            if SettingsSheet.support != nil, MFMailComposeViewController.canSendMail() {
                Button { mailing = true } label: { words }.buttonStyle(Sounding())
            } else if let to = SettingsSheet.support {
                ShareButton(items: { ["To: \(to)\n\n\(MailSheet.body)", SubjectItem(Log.url, subject: MailSheet.subject)] }) { words }
            } else {
                ShareButton(items: { [Log.url] }) { words }
            }
        case .policy:
            Button { reading = true } label: { words }.buttonStyle(Sounding())
        }
    }
}
