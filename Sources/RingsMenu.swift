// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Whether the rings are the menu (docs/rings.md), until Jack signs them off as the default. A launch with
/// UNSTIR_MENU=rings stores it and one with any other UNSTIR_MENU clears it, so the phone's home screen keeps
/// opening it; a harnessed launch without the variable clears it too, as it does the developer unlock, and so does
/// the test host. A probe: Debug holds it, and a Release build only with PROBES=YES.
enum RingsFlag {
    static let key = "menu.rings"

    /// Leave a launch a plain one, as UNSTIR_UNLOCK does.
    static let phone = ["UNSTIR_MENU", "UNSTIR_RINGSTOUR"]

    static var on: Bool {
        #if PROBES || DEBUG
        UserDefaults.standard.bool(forKey: key)
        #else
        false
        #endif
    }

    static func read(_ env: [String: String], harnessed: Bool) {
        #if PROBES || DEBUG
        if let menu = env["UNSTIR_MENU"] {
            UserDefaults.standard.set(menu == "rings", forKey: key)
        } else if harnessed || env["XCTestConfigurationFilePath"] != nil {
            UserDefaults.standard.set(false, forKey: key)
        }
        #endif
    }
}

/// The rings as the root's menu: `RingsView` under what covers it, a pack's card, the settings sheet and the consent
/// question, each the old menu's own. It takes what `MenuView` takes of the root, bar the archive, endless and the
/// list beside play, which are step two's.
struct RingsMenu: View {
    /// A closed tier a result card looked at, or the harness's.
    let start: Tier?
    /// The level just left, or on a launch the stored tier's landing: its ring opens in front.
    let focus: Level?
    @Binding var settings: Bool
    @Binding var card: Offer?
    var clock: Double?
    var day: Date?
    var placeholders = 0
    var cardScroll = false
    var arrived: Pack?
    var revision = 0
    /// Endless's saved run, as the root reads it for the menu.
    var endless: Resume?
    let onPick: (Level) -> Void

    @State private var today = Date.now
    @State private var supporter = Settings.supporter
    @State private var window: CGFloat = 800
    @State private var cameFrom: CameFrom?
    @Environment(\.scenePhase) private var phase
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// What of the store the covers show, as one number, read here so a purchase or the launch's read draws them again.
    private var stored: Int {
        let store = Store.shared
        var hasher = Hasher()
        hasher.combine(store.ready)
        hasher.combine(store.shelved)
        for pack in Pack.allCases { hasher.combine(store.state(pack)) }
        return hasher.finalize()
    }

    private var tier: Tier {
        start ?? focus.flatMap { level in Tier.allCases.first { $0.levels.contains { $0.id == level.id } } } ?? Tier.stored()
    }

    /// The ring in front as the menu opens: the one of the level just left (endless's; the archive's for a daily, today's
    /// or past, while the archive is open), else the tier's.
    private var opening: RingsHue {
        guard start == nil, let focus else { return .tier(tier) }
        if focus.run != nil { return .endless }
        if focus.id.hasPrefix("daily-"), focus.archived || Store.shared.ready && Archive.open { return .today }
        return .tier(tier)
    }

    var body: some View {
        let analytics = Analytics.shared
        let asking = analytics.asks && analytics.consent == .undecided
        RingsHost(state: RingsView.State(revision: revision &+ (Sync.built ? Sync.revision.count : 0), day: day ?? today, store: stored,
                                         endless: endless),
                  opening: opening, onPick: onPick, onOffer: { show($0) }, onSettings: { settings = true })
            .ignoresSafeArea()
            .allowsHitTesting(card == nil && !asking)
            .accessibilityHidden(card != nil || asking)
            .overlay { cardView }
            .overlay { if asking { ConsentCard(tier: tier).transition(.opacity) } }
            .animation(.easeOut(duration: 0.25), value: asking)
            .onChange(of: card) { cameFrom = cameFrom?.kept(as: card) }
            .onChange(of: phase) { if phase == .active { today = .now } }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in today = .now }
            .onGeometryChange(for: CGFloat.self) { $0.size.height + $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } action: {
                window = $0
            }
            .sheet(isPresented: $settings) {
                SettingsSheet(window: window, supporter: $supporter).dynamicTypeSize(typeSize)
            }
    }

    /// The pack's card over the rings, as the old menu lays it over its list.
    @ViewBuilder private var cardView: some View {
        if let card {
            let returns = cameFrom?.returns(card: card, offersComplete: Store.shared.offersComplete)
            PackCard(offer: card, clock: clock, levels: card.levels(placeholders: placeholders), scrolled: cardScroll,
                     focus: focus?.pack != nil && focus?.pack == card.pack ? focus : nil,
                     arrived: card.pack != nil && card.pack == arrived,
                     backTo: returns?.name ?? PackCard.menu,
                     onBack: { show(returns) }, onPlay: { onPick($0) }, onOffer: { next in
                         show(next)
                         cameFrom = CameFrom(back: card, card: next)
                     })
                .id(card)
                .transition(.opacity)
                .zIndex(1)
        }
    }

    private func show(_ offer: Offer?) {
        cameFrom = nil
        if offer == nil { Log.write("card closed") }
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.3)) { card = offer }
    }
}

private struct RingsHost: UIViewRepresentable {
    let state: RingsView.State
    let opening: RingsHue
    let onPick: (Level) -> Void
    let onOffer: (Offer) -> Void
    let onSettings: () -> Void

    func makeUIView(context: Context) -> RingsView {
        let view = RingsView(state: state, opening: opening)
        wire(view)
        return view
    }

    func updateUIView(_ view: RingsView, context: Context) {
        RingsCount.updates += 1
        wire(view)
        view.update(state)
    }

    private func wire(_ view: RingsView) {
        view.onPick = onPick
        view.onOffer = onOffer
        view.onSettings = onSettings
    }
}
