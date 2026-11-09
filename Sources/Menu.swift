// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

extension Level {
    /// Where leaving goes: a pack's level back to its card, a past daily to the archive.
    var back: String { "\u{2039} " + (pack?.name ?? (archived ? "archive" : "levels")) }

    /// A pack's level takes the pack's glow. Every twelve levels walk the grid's whole hue sweep, so the first screen shows all of it; whirlpool walks blood
    /// red through magenta to violet, vortex on from violet through blue to teal, maelstrom crimson down to bile. The daily is amber, endless cyan, the sandbox
    /// magenta.
    var colour: Color {
        if let pack { return Offer.pack(pack).glow }
        guard let n = Int(label) else { return sandbox ? .magenta : run == nil ? .amber : .neonCyan }
        let t = Double((n - 1) % 12) / 11
        return switch tier {
        case .plughole: oklch(0.639, 0.34, 190 + 240 * t)
        case .whirlpool: oklch(0.62, 0.3, 23 - 82 * t)
        case .vortex: oklch(0.66, 0.24, 300 - 110 * t)
        case .maelstrom: oklch(0.64, 0.3, 24 + 76 * t)
        }
    }
}

extension Tier {
    var sweep: LinearGradient {
        let colours: [Color] = switch self {
        case .plughole: [.neonCyan, .magenta, .amber]
        case .whirlpool: [.blood, .magenta, .violet]
        case .vortex: [.violet, Color(0x2F6BFF), Color(0x00D2C0)]
        case .maelstrom: [Color(0xFF1A2A), Color(0xD4200C), Color(0xB89A00)]
        }
        return LinearGradient(colors: colours, startPoint: .leading, endPoint: .trailing)
    }

    var glow: Color {
        switch self {
        case .plughole: .magenta
        case .whirlpool: .blood
        case .vortex: Color(0x3D5BFF)
        case .maelstrom: Color(0xE0101C)
        }
    }

    /// The tier `n` rungs up the ladder, or down for negative `n`, if there is one.
    func step(_ n: Int) -> Tier? {
        let i = Self.allCases.firstIndex(of: self)! + n
        return Self.allCases.indices.contains(i) ? Self.allCases[i] : nil
    }

    /// For VoiceOver: the tier, and if it is locked, what opens it.
    var spoken: String {
        guard let below, !isOpen() else { return rawValue }
        let par = below.atPar(), lit = par.filter { $0 }.count
        return "\(rawValue), locked, opens with every \(below.rawValue) level at par, \(lit) of \(par.count)"
    }

    /// The first level with no best, on an open tier: where the player is. Every level before it has a best, so it is
    /// open.
    func frontier(unlocked: Bool = Best.unlocked, _ best: (String) -> Best? = Best.load) -> Level? {
        isOpen(unlocked: unlocked, best) ? levels.first { best($0.id) == nil } : nil
    }

    /// The levels short of par, as runs of neighbours by index. The first of each run is open: the level before it is at
    /// par, or it is the first.
    func short(_ best: (String) -> Best? = Best.load) -> [ClosedRange<Int>] {
        atPar(best).enumerated().reduce(into: []) { runs, level in
            guard !level.element else { return }
            if let last = runs.last, last.upperBound == level.offset - 1 {
                runs[runs.count - 1] = last.lowerBound ... level.offset
            } else {
                runs.append(level.offset ... level.offset)
            }
        }
    }

    /// The row a launch centres on: the frontier, else the first level short of par. Nil, the top, once every level is
    /// at par or while the tier is locked.
    func landing(_ best: (String) -> Best? = Best.load) -> Level? {
        frontier(best) ?? (isOpen(best) ? levels.first { (best($0.id)?.over ?? 0) > 0 } : nil)
    }
}

extension Level {
    /// The row the menu, or a pack's card, centres on once this level is left: after a solve the one after it, which
    /// "next ›" opens, or itself as its list's last; a past daily itself, in the archive. Nil for today's daily, endless
    /// and the sandbox, which sit outside the tier's rows.
    func focus(solved: Bool) -> Level? {
        if archived { return self }
        let list = pack?.levels ?? tier.levels
        guard let i = list.firstIndex(where: { $0.id == id }) else { return nil }
        return list[solved ? min(i + 1, list.count - 1) : i]
    }
}

/// The tank's own twist as one rod about `centre`: the menu stirs a tier's list away and unstirs the next into place.
struct Stirred: ViewModifier, Animatable {
    var angle: Double
    /// 0 to 1: the list dims and greys as it goes.
    var fade: Double
    var centre: CGPoint
    var radius: CGFloat
    @Environment(\.displayScale) private var scale

    nonisolated var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(angle, fade) }
        set { (angle, fade) = (newValue.first, newValue.second) }
    }

    func body(content: Content) -> some View {
        content
            .layerEffect(
                // A low plateau: the whole disc shears, where the tank's 0.6 would spin the middle rows as a block. The
                // disc's radius stays under 1, which the shader would take for the swirl, turned inside out.
                ShaderLibrary.unstir(.float2(centre), .float(radius), .floatArray([0, 0, 0.9999, Float(angle)]),
                                     .float(1), .float(30), .float(0.1), .float(0.1), .float(Float(Tank.lensEdge)), .float(Float(scale)), .float(Float(0.3 * fade)),
                                     .float3(0, 0, -1), .float(0)),
                // Samples stay in the disc, which reaches past the view's edges by no more than this. The effect draws
                // its margin too, so a wider one is wasted work.
                maxSampleOffset: CGSize(width: max(radius - centre.x, 0), height: max(radius - centre.y, 0)),
                isEnabled: angle != 0 || fade != 0)
            .opacity(1 - 0.8 * fade)
    }
}

struct MenuView: View {
    /// UNSTIR_TIERDEMO: switches tiers on a timer through the same calls a finger makes.
    let demo: Bool
    /// Handed on to the settings sheet, which takes the system's and not one set on the views round it (the harness's).
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The harness's tier, or a closed tier's gate a result card looked at.
    let start: Tier?
    let onPick: (Level) -> Void
    /// The pack card over the menu, opened from the dock or by a level that needs it.
    @Binding var card: Offer?
    /// The archive's calendar over the menu.
    @Binding var archive: Bool
    /// Where the tapped cover sits, for the card to grow from.
    @State private var cardFrom = UnitPoint.center
    /// UNSTIR_CLOCK: the dock's and the card's clips held that many seconds in.
    let clock: Double?
    /// UNSTIR_CARDLEVELS: placeholder levels the card lists before its pack has any.
    let placeholders: Int
    /// UNSTIR_SHELFDEMO: opens Lens's card from the dock and back, through the calls a finger makes.
    let shelfDemo: Bool
    /// UNSTIR_CARDSCROLL: the card opens scrolled to its levels.
    let cardScroll: Bool
    /// The row the list, or the card, centres on as it opens: the level just left, or on launch the tier's landing.
    let focus: Level?
    /// UNSTIR_LOCKTAP: a locked row held tapped.
    let held: String?
    /// Drawn under a level a back swipe is sliding off.
    let peeking: Bool
    /// The level playing beside the menu on the open Duo, whose row the list follows; nil anywhere else.
    let playing: Level?
    /// The trailing half as the playing level lays it out, the list's beside it, in the menu's space, once it has.
    let slot: CGRect?
    /// The playing level's result or lost card covers the list beside it: the list goes, the level's card in its place.
    let covered: Bool
    /// Bumped by every level opened, left or finished: a menu that stays up beside play reads its rows, its run and
    /// its dailies afresh then, as a menu built anew on each return does.
    let revision: Int
    /// Endless's saved run, as the root last read it.
    let run: Resume?
    /// The slot the list is drawn in beside play: it glides there from its own half, and back.
    @State private var at: CGRect?
    /// Built beside a playing level, the list waits unseen for the level's first layout rather than gliding from the
    /// half the tank has.
    @State private var unplaced: Bool
    /// The focused row's id until its flash has started, so a later rebuild of its tier's list doesn't flash it again.
    @State private var flashing: String?
    /// `focus` for the card up as the menu opens, gone once a card is opened or closed, so a dock tap opens at the top.
    @State private var cardFocus: Level?
    /// The pack whose card a level past its taste opened, for this showing of it.
    let arrived: Pack?
    /// The tier picked in the strip, open or not. `shown` trails it while the old list stirs away, and `listed`, the
    /// scroll view's own list, trails that to the end of the switch: rebuilding it stalls a frame (about 40 ms on the
    /// simulator), unseen once the stir has settled over it.
    @State private var picked: Tier
    @State private var shown: Tier
    @State private var listed: Tier
    @State private var spin = 0.0
    @State private var fade = 0.0
    @State private var busy = false
    /// A drag let go short, springing back.
    @State private var settling = false
    /// Decided on a drag's first move: sideways stirs, anything else scrolls.
    @State private var sideways: Bool?
    /// Resets when a drag ends or is cancelled; `onEnded` runs only when it ends.
    @GestureState private var dragging = false
    /// The scroll view's height and its bottom safe area: the list draws on under the home indicator.
    @State private var viewport: CGFloat = 0
    /// The window's whole height, bars and all, which sizes the settings sheet.
    @State private var window: CGFloat = 800
    /// The window's bottom safe area, under which a sheet runs on.
    @State private var bottom: CGFloat = 0
    /// The pack dock's height: the scroll view counts it in its bottom safe area, but the list ends at it.
    @State private var dock: CGFloat = 0
    /// The tier's list in the scroll view's space.
    @State private var list = CGRect.zero
    @State private var scroller: ScrollViewProxy?
    /// The list has opened on its focus.
    @State private var centred = false
    /// Mid-switch, the incoming tier's landing row in its list's own space, measured on the stirred copy: the scroll
    /// view still holds the outgoing list, so it scrolls to a mark placed there instead.
    @State private var mark: CGRect?
    /// The mark has moved and the list scrolls to it once it is laid out there.
    @State private var arriving = false
    @Namespace private var strip
    /// The gear's sheet.
    @Binding var settings: Bool
    /// The settings' supporter mark switch, mirrored here as the sheet moves it.
    @State private var supporter = Settings.supporter
    /// A pack's card opened from Complete's, so its back returns there while it is still the card up.
    @State private var cameFrom: CameFrom?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var phase
    /// UNSTIR_FOLD's fold, in the harness window's points.
    @Environment(\.harnessFold) private var harnessFold
    /// Where the list goes, and a card or the archive, from the window as last measured.
    @State private var layout = MenuLayout.column
    /// When the daily row was dealt: a menu left up past midnight, or coming back to the front, deals the new day's.
    @State private var today: Date
    /// Today's daily and its run, worked out once a day rather than on every frame of a swipe. The menu is built anew
    /// each time it comes up, so a solve's run shows on return.
    @State private var daily: (level: Level, run: Int)
    /// The archive's days dealt, and how many are at par, with the daily: dealing thirty tanks is too slow for every
    /// frame of a swipe.
    @State private var past: (days: [(date: Date, level: Level)], atPar: Int)
    /// `lead` for the shown tier, once a tier rather than on every frame of a swipe.
    @State private var leading: Lead
    /// Endless's saved run, which its row continues (Jack's call C2, round 13).
    @State private var saved: Resume?
    /// When a first tap armed the endless row's "new run", which then says "new run? tap again" for `ResetArm.window`.
    @State private var newRunArmed: Date?
    @AccessibilityFocusState private var newRunFocused: Bool
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    /// How far the outgoing list turns at its centre before the incoming one takes its place.
    private var turn: Double { reduceMotion ? 0 : 1.6 * .pi }
    /// The list's fade at the swap. At 1 the list read as black for about 0.3 s.
    private let dim = 0.55

    /// `start`: the harness's tier, shown even when locked. `frozen`: UNSTIR_TIERSPIN, the list held mid-twist.
    init(start: Tier? = nil, demo: Bool = false, frozen: (spin: Double, fade: Double)? = nil, settings: Binding<Bool>,
         card: Binding<Offer?>, archive: Binding<Bool> = .constant(false), clock: Double? = nil, placeholders: Int = 0, shelfDemo: Bool = false,
         cardScroll: Bool = false, focus: Level? = nil, held: String? = nil, arrived: Pack? = nil, run: Resume? = nil,
         peeking: Bool = false, playing: Level? = nil, slot: CGRect? = nil, revision: Int = 0, covered: Bool = false,
         onPick: @escaping (Level) -> Void) {
        self.start = start
        self.playing = playing
        self.slot = slot
        self.covered = covered
        self.revision = revision
        self.run = run
        _unplaced = State(initialValue: playing != nil)
        self.demo = demo
        _settings = settings
        self.onPick = onPick
        _card = card
        _archive = archive
        self.clock = clock
        self.placeholders = placeholders
        self.shelfDemo = shelfDemo
        self.cardScroll = cardScroll
        self.focus = focus
        self.held = held
        self.peeking = peeking
        self.arrived = arrived
        _flashing = State(initialValue: focus?.id)
        _saved = State(initialValue: run)
        _cardFocus = State(initialValue: focus)
        // A tier's own level left lands on its tier, which "up a notch" may have opened since the menu was last up; beside
        // play, the playing level's tier.
        let tier = start ?? (playing ?? focus).flatMap { f in f.tier.levels.contains { $0.id == f.id } ? f.tier : nil } ?? Tier.stored()
        _picked = State(initialValue: tier)
        _shown = State(initialValue: tier)
        _listed = State(initialValue: tier)
        let now = Date.now
        _today = State(initialValue: now)
        _daily = State(initialValue: Self.daily(now))
        _past = State(initialValue: Self.past(now))
        _leading = State(initialValue: Self.lead(tier: tier))
        if let frozen {
            _spin = State(initialValue: frozen.spin)
            _fade = State(initialValue: frozen.fade)
            _busy = State(initialValue: true)
        }
    }

    /// What the menu leads with (Jack's call C4, round 13). `modes`: the daily and endless, which draw on every layout, so
    /// they open, and show, after the first hex level. `sandbox`: the build has it (`Level.playsSandbox`), its row at the
    /// list's end. `next`: once plughole 01 has a best, the tier's frontier, if it has one.
    typealias Lead = (modes: Bool, sandbox: Bool, next: Level?)
    static func lead(tier: Tier, unlocked: Bool = Best.unlocked, release: Bool = Build.release,
                     best: (String) -> Best? = Best.load) -> Lead {
        (unlocked || best(Level.plughole[22].id) != nil, Level.playsSandbox(release: release),
         best(Level.plughole[0].id) != nil ? tier.frontier(unlocked: unlocked, best) : nil)
    }

    private static func daily(_ day: Date) -> (level: Level, run: Int) { (Level.daily(day), Daily.run(today: day)) }

    private static func past(_ day: Date) -> (days: [(date: Date, level: Level)], atPar: Int) {
        let days = Archive.days(today: day).map { ($0, Level.daily($0, archived: true)) }
        return (days, days.filter { Best.load($0.1.id)?.over == 0 }.count)
    }

    var body: some View {
        laidOut
        .modifier(Refreshed(revision: revision, playing: playing?.id, start: start, refresh: refresh, follow: followPlaying,
                            look: look))
        // Wide, the trailing half holds one at a time, as both stay live there: the one opened last, from the list,
        // the dock or the root (a gate, a promoted purchase), closes the other, which would lie unseen and still read
        // to VoiceOver under it. Unfolding with a card over the archive keeps the card, the one in sight.
        .onChange(of: card) { if layout.wide, card != nil, archive { withAnimation(.snappy(duration: 0.42)) { archive = false } } }
        .onChange(of: archive) { if layout.wide, archive, card != nil { show(nil) } }
        .onChange(of: layout.wide) { if layout.wide, card != nil, archive { archive = false } }
        // The root changes the card too (a level parking it, a gate, a result card's pointer): beside play this menu
        // outlives those changes, so where a card came from lasts only while that card stays up.
        .onChange(of: card) { cameFrom = cameFrom?.kept(as: card) }
        // A drag, or a card or the settings closing, wakes the dock as a touch on the window does, as does a level beside
        // it leaving.
        .onChange(of: card == nil && !archive && !settings && playing == nil) { Power.shared.touched() }
        // The editors' switch changes which rows the lead shows, the daily's and endless's among them.
        .onChange(of: settings) { if !settings { leading = Self.lead(tier: shown) } }
        .background {
            // Builds the effect's pipeline before the first switch, which would otherwise stall on it. Beside play there
            // is no stir, and the square would show on Escapement's paper.
            if playing == nil {
                Color.black.frame(width: 2, height: 2).drawingGroup()
                    .modifier(Stirred(angle: 0.1, fade: 0, centre: .zero, radius: 1))
            }
        }
        // Not beside play, where the level lies under the menu and keeps its touches.
        .background { if playing == nil { Color.black } }
        .onChange(of: dragging) {
            if dragging { Power.shared.touched() }
            // Cancelled, so `onEnded` never ran.
            if !dragging, sideways != nil {
                if sideways == true { released(0, predicted: 0) }
                sideways = nil
            }
        }
        .onChange(of: phase) { if phase == .active { today = .now } }
        .onChange(of: today) {
            daily = Self.daily(today)
            past = Self.past(today)
        }
        // Bests iCloud brought: the rows read them afresh, but these are kept.
        .onChange(of: Sync.revision.count) {
            daily = Self.daily(today)
            past = Self.past(today)
            leading = Self.lead(tier: shown)
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            today = .now
        }
        .task { if demo { await tour() } }
        .task { if shelfDemo { await shelfTour() } }
    }

    /// The column, the dock where it lies apart and a card or the archive, where the window puts them.
    private var laidOut: some View {
        let analytics = Analytics.shared
        // The menu waits for the question's answer, for VoiceOver too; beside play, until the level leaves.
        let asking = analytics.asks && analytics.consent == .undecided && playing == nil
        let fold = harnessFold
        return placedColumn(asking: asking)
        // The tabletop's dock lies below the fold, under a card or the archive.
        .overlay(alignment: .topLeading) { tabletopDock(asking: asking) }
        // Over the menu or beside the list, in one place in the tree, so a card or the archive up as the phone folds or
        // unfolds keeps its identity and its scroll (Jack's call d4-pose = B, round 16).
        .overlay(alignment: .topLeading) { sheets(asking: asking) }
        .onGeometryChange(for: MenuLayout.self) {
            MenuLayout.of(size: $0.size, insets: $0.safeAreaInsets, fold: PlayLayout.fold($0, harness: fold))
        } action: { layout = $0 }
        // The list moves halves as a level opens beside it or leaves, in one glide (Jack's call DUOMENU = B, round 16);
        // built beside play, it waits for the level's first layout and appears there.
        .onChange(of: playing == nil ? nil : slot, initial: true) { _, slot in
            let glide = !unplaced && !reduceMotion
            // The slot changes as the phone folds or opens further: the playing row stays in sight. Once the list has its
            // new size, as a scroll view mid-glide centres on the size it is passing through.
            withAnimation(glide ? .smooth(duration: 0.45) : nil) { at = slot } completion: {
                guard at != nil, let p = playing, listed.levels.contains(where: { $0.id == p.id }) else { return }
                withAnimation(reduceMotion ? nil : .snappy(duration: 0.4)) { scroller?.scrollTo(p.id, anchor: .center) }
            }
            if slot != nil { unplaced = false }
        }
        .overlay {
            if asking { ConsentCard(tier: shown).transition(.opacity) }
        }
        .animation(.easeOut(duration: 0.25), value: asking)
        .onGeometryChange(for: CGFloat.self) { $0.size.height + $0.safeAreaInsets.top + $0.safeAreaInsets.bottom } action: {
            window = $0
        }
        .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.bottom } action: { bottom = $0 }
        // The tabletop's settings keep to the half lying flat, as the dock and a card do.
        .sheet(isPresented: $settings) {
            SettingsSheet(window: window, room: layout.dock.map { $0.height + bottom }, supporter: $supporter)
                .dynamicTypeSize(typeSize)
        }
    }

    /// Where the list goes now: beside play, the slot the level leaves it, once there.
    private var placed: MenuLayout { at.map(layout.beside) ?? layout }

    /// A menu that stays up beside play, or wide between levels, isn't built anew on each return, so it reads afresh
    /// what a new one would.
    private func refresh() {
        guard layout.wide else { return }
        daily = Self.daily(today)
        past = Self.past(today)
        leading = Self.lead(tier: shown)
        saved = run
    }

    /// The playing level's row, and no row lit; once it leaves, the row left, lit however often it is left, as a
    /// focus that stays the same changes nothing.
    private func followPlaying() {
        guard playing != nil else { return refocus() }
        flashing = nil
        follow(playing)
    }

    /// The row left once a level beside the list closes, lit once, as a new menu lights it.
    private func refocus() {
        guard layout.wide, playing == nil, let focus else { return }
        cardFocus = focus
        flashing = reduceMotion ? nil : focus.id
        follow(focus)
    }

    /// A closed tier's gate, looked at from a result card, on a menu that stayed up.
    private func look() {
        if layout.wide, let start, start != picked { select(start) }
    }

    /// The column where `placed` puts it: a phone's whole screen, the split's leading half, beside play the trailing
    /// half, the tabletop's upright half.
    private func placedColumn(asking: Bool) -> some View {
        let wide = layout.wide, placed = self.placed
        // Beside play, or in the tabletop, the list has a height of its own.
        let sized = placed.dock != nil || at != nil
        return column
            .frame(width: placed.list?.width, height: sized ? placed.list?.height : nil)
            // The level's ground lies under the menu beside play.
            .background { if playing != nil { Color.black } }
            .offset(x: placed.list?.minX ?? 0, y: placed.list?.minY ?? 0)
            // With the level's card, which fades in as it does.
            .opacity(unplaced || covered ? 0 : 1)
            .animation(.easeOut(duration: 0.4).delay(0.3), value: covered)
            .allowsHitTesting(!covered)
            // Wide, a card or the archive opens beside the list, which stays live; beside play it opens over the list.
            .accessibilityHidden(asking || covered || (!wide || playing != nil) && (card != nil || archive))
            .frame(maxWidth: wide ? .infinity : nil, maxHeight: sized ? .infinity : nil, alignment: .topLeading)
    }

    @ViewBuilder private func tabletopDock(asking: Bool) -> some View {
        if let d = placed.dock {
            dock(over: covering)
                .frame(width: d.width).frame(height: d.height, alignment: .bottom)
                .offset(x: d.minX, y: d.minY)
                .accessibilityHidden(asking || card != nil || archive)
        }
    }

    /// A pack's card or the archive: over the menu on a phone, beside the list wide, and beside play over the whole
    /// trailing half, as a phone's covers the menu.
    private func sheets(asking: Bool) -> some View {
        let wide = layout.wide, side = placed.side
        return ZStack {
            archiveView(beside: wide && playing == nil)
            cardView(beside: wide && playing == nil)
        }
        .frame(width: side?.width, height: side?.height)
        .frame(maxWidth: wide ? nil : .infinity, maxHeight: wide ? nil : .infinity)
        .padding(.leading, side?.minX ?? 0)
        .padding(.top, placed.dock == nil ? 0 : side?.minY ?? 0)
        .accessibilityHidden(asking)
    }

    /// Beside play a card or the archive starts 16 pt past the fold, where the level's own ground shows under its
    /// result card, Escapement's paper too: its ground runs on to the fold, and a point under the card, so the two
    /// edges' antialiasing leaves no seam on a fractional pixel.
    @ViewBuilder private var bleed: some View {
        if playing != nil { Color.black.frame(width: PlayLayout.margin + 1).offset(x: -PlayLayout.margin) }
    }

    /// A card or the archive lies over the dock: on a phone, beside play and in the tabletop, not beside the split's list.
    private var covering: Bool { (card != nil || archive) && (!layout.splits || playing != nil) }

    /// The title, the tier strip and the tier's list over the dock: the whole menu on a phone, its leading half wide,
    /// and beside play the trailing half, title and gear too (Jack's call s5b-title = B).
    private var column: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                title.simultaneousGesture(swipe)
                Spacer(minLength: 8)
                Button { settings = true } label: {
                    // Grown no further than its 44 pt target holds, as a bar's icons stop.
                    Image(systemName: "gearshape").font(.system(.body, weight: .light)).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(Sounding()).opacity(0.5)
                .accessibilityLabel("Settings")
            }
            .padding(.leading, 20).padding(.trailing, 10).padding(.top, 28)
            // The strip keeps the picked name in view itself, so a sideways drag on it is the switcher's, as on the list.
            tiers.padding(.top, 6).scrollDisabled(true).simultaneousGesture(swipe)
            ScrollViewReader { proxy in
                ScrollView { rows(leading) }
                .onAppear {
                    scroller = proxy
                    arrive()
                }
            }
            // Once a drag is taken as sideways, the list stops scrolling under the stir.
            .scrollDisabled(sideways == true)
            .overlay(alignment: .topLeading) { twisted }
            .onGeometryChange(for: CGFloat.self) { $0.size.height + $0.safeAreaInsets.bottom } action: { viewport = $0 }
            .simultaneousGesture(swipe)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if layout.dock == nil {
                    dock(over: covering).onGeometryChange(for: CGFloat.self) { $0.size.height } action: { dock = $0 }
                }
            }
        }
        .foregroundStyle(Color.text)
    }

    /// Held still under a card, the settings or a level sliding off, beside a playing level, whose tank the GPU is
    /// for, when the phone saves power, or once nobody touches it. A card or the archive beside the list leaves it in
    /// sight and live.
    @ViewBuilder private func dock(over: Bool) -> some View {
        if !Offer.shelf().isEmpty && PackDock.shown() {
            PackDock(open: { show($0, from: $1) }, held: clock,
                     paused: over || settings || peeking || playing != nil || Power.shared.saving || Power.shared.idle,
                     covered: over || settings)
                .equatable()
        }
    }

    /// Centres `level`'s row, switching to its tier if the list shows another. A pack's level, the daily and endless
    /// have no row in a tier's list.
    private func follow(_ level: Level?) {
        guard layout.wide, let level, level.tier.levels.contains(where: { $0.id == level.id }) else { return }
        if level.tier != picked {
            select(level.tier, quiet: true)
        } else {
            DispatchQueue.main.async { withAnimation(.snappy(duration: 0.4)) { scroller?.scrollTo(level.id, anchor: .center) } }
        }
    }

    /// The way on; the modes once open; then the tier's rule and rows, and where the build has the sandbox, its row at
    /// the end under "anything goes" (Jack's call D2 = A, round 13), so the list leads with 01.
    private func rows(_ lead: Lead) -> some View {
        let sandbox = LevelRow(level: .sandbox, detail: "any picture, any rods \u{00B7} nothing counts", enabled: true,
                               pick: pick, refuse: refuse)
        return VStack(alignment: .leading, spacing: 0) {
            wayOn(lead).padding(.top, 10).id(Self.top)
            VStack(alignment: .leading, spacing: 0) {
                if lead.modes {
                    // Marked until either is first opened.
                    let new = !Best.modesSeen, (day, run) = daily
                    LevelRow(level: day, detail: run < 2 ? nil
                                 : "\(day.layout.rods.count) rods \u{00B7} par \(day.par) \u{00B7} \(run) days running",
                             enabled: true, new: new, playing: playing?.id == day.id, pick: pick, refuse: refuse)
                    // Unsaid until the store has read what the player owns, so an owner never meets the lock.
                    ArchiveRow(open: Store.shared.ready ? Archive.open : nil, days: past.days.count, atPar: past.atPar,
                               pick: openArchive, refuse: refuse)
                    let kept = saved?.run
                    LevelRow(level: .endless(kept ?? Run(seed: .random(in: .min ... .max))),
                             detail: kept.map {
                                 "continue \u{00B7} tank \($0.tank + 1) \u{00B7} brim \(saved?.brim ?? $0.brim)"
                                     + (Best.tanks > 0 ? " \u{00B7} best \(Best.tanks)" : "")
                             } ?? "deeper every tank \u{00B7} eight wrong stirs and it spills",
                             best: kept == nil && Best.tanks > 0 ? Text("best \(Best.tanks)") : nil, enabled: true,
                             new: new && kept == nil, continues: kept != nil, playing: playing?.run != nil, pick: pick,
                             refuse: refuse)
                        // On the title's line, where every row's mark sits and "Endless" leaves room.
                        .overlay(alignment: Alignment(horizontal: .trailing, vertical: .firstTextBaseline)) {
                            if kept != nil { newRun }
                        }
                }
            }
            .padding(.top, lead.modes ? 22 : 8)
            TierList(tier: listed, pick: pick, refuse: refuse, flash: flashing, held: held, playing: playing?.id,
                     revision: revision).equatable()
                .overlay(alignment: .topLeading) {
                    Color.clear.frame(width: 1, height: mark?.height ?? 1).id(Self.mark)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { _ in
                            guard arriving else { return }
                            arriving = false
                            scroller?.scrollTo(Self.mark, anchor: .center)
                        }
                        .padding(.top, mark?.minY ?? 0)
                }
                .opacity(stirring ? 0 : 1)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: {
                    list = $0
                    arrive()
                }
            if lead.sandbox {
                HStack(spacing: 10) {
                    Text("anything goes").font(.ui(.detail, .semibold)).opacity(0.55)
                    Rectangle().frame(height: 1).opacity(0.2)
                }
                .padding(.top, 22).padding(.bottom, 8)
                sandbox
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    /// The shown tier's frontier, a tap away, once plughole 01 has a best; until then an empty line (Jack's call D1 = A,
    /// round 13: the tank's rule left the menu for the App Store page).
    @ViewBuilder private func wayOn(_ lead: Lead) -> some View {
        if let next = lead.next {
            Button { pick(next) } label: {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("next: ").opacity(0.55)
                    Text(next.label).fontWeight(.semibold).foregroundStyle(next.colour).shadow(color: next.colour, radius: 4)
                    Text(" \u{00B7} \(next.title) \u{203A}").opacity(0.8)
                }
                .font(.ui(.label)).lineLimit(1).hit()
            }
            // Plain: `pick` taps, as a row does.
            .buttonStyle(.plain)
            .accessibilityLabel(Spoken.next(next))
        } else {
            // A line's height still, so a tier swap, or 01's first best, moves nothing below it.
            Text(" ").font(.ui(.label)).hidden()
        }
    }

    /// The card grows out of its cover, or fades in under Reduce Motion; `beside` the list, it comes in from the
    /// trailing edge, as the archive does.
    @ViewBuilder private func cardView(beside: Bool) -> some View {
        if let card {
            PackCard(offer: card, clock: clock, levels: card.levels(placeholders: placeholders), scrolled: cardScroll,
                     // A menu that stays up wide brings back the card a level beside it was opened from, centred on that
                     // level's row as a menu built anew centres it.
                     focus: cardFocus ?? (layout.wide && focus?.pack != nil && focus?.pack == card.pack ? focus : nil),
                     arrived: card.pack != nil && card.pack == arrived,
                     backTo: returns?.name ?? PackCard.menu,
                     onBack: { back() }, onPlay: { onPick($0) }, onOffer: { next in
                         show(next)
                         cameFrom = CameFrom(back: card, card: next)
                     }, beside: beside, closes: Self.closes(playing: playing != nil, covered: covered))
                .background(alignment: .leading) { bleed }
                .id(card)
                .transition(reduceMotion ? .opacity
                            : beside ? .move(edge: .trailing).combined(with: .opacity)
                            : .scale(scale: 0.15, anchor: cardFrom).combined(with: .opacity))
                .zIndex(1)
        }
    }

    /// A card over a playing level's result card, which covers the menu beside it, closes onto that card rather than
    /// going to the menu (Jack's call s5b-back = B); over the menu beside play it goes to the menu.
    nonisolated static func closes(playing: Bool, covered: Bool) -> Bool { playing && covered }

    /// The calendar, over the menu as a card is, or beside the list as a card is, from its row.
    @ViewBuilder private func archiveView(beside: Bool) -> some View {
        if archive {
            ArchiveView(days: past.days, today: today, focus: focus?.archived == true ? focus?.id : nil, beside: beside,
                        onBack: { withAnimation(.snappy(duration: 0.42)) { archive = false } },
                        onPlay: { onPick($0) })
                .background(alignment: .leading) { bleed }
                .transition(reduceMotion ? .opacity : .move(edge: .trailing).combined(with: .opacity))
                .zIndex(1)
        }
    }

    private func openArchive() {
        guard !twisting else { return }
        Sound.shared.play(.tap)
        Log.write("archive shown")
        withAnimation(.snappy(duration: 0.42)) { archive = true }
    }

    private func show(_ offer: Offer?, from: UnitPoint = .center) {
        cameFrom = nil
        Log.write(offer.map { "card \($0.key) shown" } ?? "card closed")
        cardFocus = nil
        if offer != nil { cardFrom = from }
        withAnimation(.snappy(duration: 0.42)) { card = offer }
    }

    /// The card a pack's card was opened from, while it is still on offer: Complete stops saving once a pack is bought.
    private var returns: Offer? { cameFrom?.returns(card: card, offersComplete: Store.shared.offersComplete) }

    /// That card, or the menu.
    private func back() {
        show(returns)
    }

    /// The menu, Lens's cover tapped, its card's clip played through, then back.
    private func shelfTour() async {
        func pause(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        await pause(4.5)
        show(.pack(.lens), from: UnitPoint(x: 0.375, y: 0.88))
        await pause(7.2)
        show(nil)
    }

    /// While it turns, the list is drawn again, cut to the part on screen, over the scroll view, and that is what
    /// twists: a layer effect blanks a scroll view, and on the whole list its margin is too big. Flattened first, or
    /// with a margin the effect draws only some of the rows. The cut takes in the list's side margins, where the rows'
    /// hairlines lie.
    private var twisted: some View {
        let w = list.width, m = list.minX, top = band.lowerBound, h = band.upperBound - top
        return ZStack(alignment: .top) {
            if stirring {
                TierList(tier: shown, pick: pick, refuse: refuse, report: reach, revision: revision).equatable()
                    .fixedSize(horizontal: false, vertical: true).frame(width: w)
                    // An alignment guide on a lone child moves nothing, so the copy drew the list from its top.
                    .offset(y: -top)
            }
        }
        .frame(width: w + 2 * m, height: h, alignment: .top)
        .clipped()
        .drawingGroup()
        .modifier(Stirred(angle: spin, fade: fade, centre: CGPoint(x: m + w / 2, y: h / 2), radius: reach))
        // The effect draws its sampling margin too, opaque.
        .clipped()
        .padding(.top, list.minY + top)
        .allowsHitTesting(false)
    }

    private var twisting: Bool { busy || settling || sideways == true }
    /// The stirred copy is up: never beside play.
    private var stirring: Bool { twisting && playing == nil }

    /// The list's visible part, in its own space.
    private var band: ClosedRange<CGFloat> {
        let top = max(-list.minY, 0)
        // The dock's last height under the list, which the tabletop's lies apart from.
        let under = layout.dock == nil ? dock : 0
        return top ... max(min(viewport - under - list.minY, list.height), top + 1)
    }

    /// The middle of the list's visible part, in the scroll view's space.
    private var pivot: CGFloat { list.minY + (band.lowerBound + band.upperBound) / 2 }

    /// Out to the visible part's corners.
    private var reach: CGFloat { hypot(list.width, band.upperBound - band.lowerBound) / 2 }

    /// Cuts to the new tier's sweep at the swap: a gradient doesn't interpolate, and a cross-fade runs through grey.
    private var title: some View {
        let supporter = Store.shared.bought && self.supporter
        return HStack(alignment: .top, spacing: 2) {
            Text("UNSTIR").font(.ui(.display)).tracking(8)
                .foregroundStyle(shown.sweep).shadow(color: shown.glow.opacity(0.6), radius: 12)
            if supporter { SupporterMark(sweep: shown.sweep, glow: shown.glow).padding(.top, 3) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(supporter ? "Unstir, supporter" : "Unstir").accessibilityAddTraits(.isHeader)
    }

    /// Every tier by name. A strip wider than the screen moves only to keep the picked name in view, so a sideways drag
    /// on it is the switcher's.
    private var tiers: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Tier.allCases, id: \.self) { t in
                        if t != Tier.allCases.first {
                            Text("\u{00B7}").font(.ui(.chip)).opacity(0.3).padding(.horizontal, 7).frame(height: 36)
                        }
                        // Silent itself: `go` sounds a switch as it starts, however it starts.
                        Button { select(t) } label: { name(t) }
                            .buttonStyle(.plain)
                            .id(t)
                    }
                }
                .padding(.leading, 20)
                // Past the trailing fade, so the last name reads whole once scrolled to.
                .padding(.trailing, 40)
            }
            .scrollIndicators(.hidden)
            // Names run out into the black at the edges, so a strip wider than the screen reads as running on past them.
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.04),
                                         .init(color: .black, location: 0.9), .init(color: .clear, location: 1)],
                                 startPoint: .leading, endPoint: .trailing))
            .onChange(of: picked) { withAnimation { proxy.scrollTo(picked, anchor: .center) } }
            .onAppear { proxy.scrollTo(picked, anchor: .center) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tier")
        .accessibilityValue(picked.spoken)
        .accessibilityAdjustableAction { direction in
            let n = switch direction {
            case .increment: 1
            case .decrement: -1
            @unknown default: 0
            }
            if let t = picked.step(n) { select(t) }
        }
    }

    private func name(_ t: Tier) -> some View {
        let isPicked = t == picked, open = t.isOpen()
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                Text(t.rawValue).font(.ui(.chip, isPicked ? .semibold : .regular))
                    .foregroundStyle(isPicked ? AnyShapeStyle(t.sweep)
                                              : AnyShapeStyle(Color.text.opacity(open ? 0.6 : 0.36)))
                    .shadow(color: isPicked ? t.glow.opacity(0.8) : .clear, radius: 7)
                if !open {
                    Image(systemName: "lock.fill").font(.ui(.detail, .semibold)).imageScale(.small)
                        .foregroundStyle(isPicked ? t.glow : Color.text.opacity(0.36))
                }
            }
            .frame(height: 36)
            // The underline slides to the picked name as soon as it is picked; the list follows once it has stirred
            // away.
            if isPicked {
                Capsule().fill(t.sweep).frame(height: 2).shadow(color: t.glow, radius: 4)
                    .matchedGeometryEffect(id: "underline", in: strip)
            } else {
                Color.clear.frame(height: 2)
            }
        }
        .padding(.bottom, 6)
        .contentShape(Rectangle())
    }

    /// `quiet`: the list follows a level rather than a finger on the strip, so no switch sounds.
    private func select(_ t: Tier, quiet: Bool = false) {
        // A sideways drag that lifts over a name is the swipe's, which has already sprung back or switched.
        guard !twisting else { return }
        if t == shown, !busy {
            withAnimation(.snappy(duration: 0.5)) { land(on: t) }
            return
        }
        guard let from = Tier.allCases.firstIndex(of: shown), let to = Tier.allCases.firstIndex(of: t) else { return }
        go(to: t, turning: to > from ? 1 : -1, quiet: quiet)
    }

    /// The outgoing list stirs away, then the incoming one unstirs, turning on the same way. Beside a playing tank the
    /// list cuts to the new tier instead, so no stir takes the GPU from the tank.
    private func go(to t: Tier, turning dir: Double, quiet: Bool = false) {
        guard t != shown, !busy else { return }
        if !quiet { Sound.shared.play(.tier) }
        Tier.store(t)
        guard playing == nil else {
            withAnimation(.snappy(duration: 0.35)) { picked = t }
            shown = t
            listed = t
            leading = Self.lead(tier: t)
            DispatchQueue.main.async { land(on: t) }
            return
        }
        busy = true
        withAnimation(.snappy(duration: 0.35)) { picked = t }
        withAnimation(.easeIn(duration: 0.32)) {
            spin = dir * turn
            fade = dim
        } completion: {
            shown = t
            leading = Self.lead(tier: t)
            // Under the stir's peak, so the jump never shows: a landing row scrolls in once the copy has measured it.
            mark = nil
            if !t.isOpen() {
                scroller?.scrollTo(TierList.heading, anchor: .top)
            } else if t.landing() == nil {
                scroller?.scrollTo(Self.top, anchor: .top)
            }
            spin = -dir * turn
            withAnimation(.easeOut(duration: 0.62)) {
                spin = 0
                fade = 0
            } completion: {
                listed = t
                busy = false
            }
        }
    }

    private static let top = "top", mark = "mark"

    /// Unanimated, under the dip that brings the menu in, once the rows are laid out and the scroll view's reader is in
    /// hand, whichever comes last.
    private func arrive() {
        guard !centred, let scroller, list.height > 0 else { return }
        centred = true
        DispatchQueue.main.async {
            if let focus = playing ?? focus, listed.levels.contains(where: { $0.id == focus.id }) {
                scroller.scrollTo(focus.id, anchor: .center)
            }
            flashing = nil
        }
    }

    /// The tier's landing row centred, or beside play the playing level's; a locked tier's header, over its gate, at the
    /// top; else the top.
    private func land(on t: Tier) {
        if let p = playing, t.levels.contains(where: { $0.id == p.id }) {
            scroller?.scrollTo(p.id, anchor: .center)
        } else if let row = t.landing() {
            scroller?.scrollTo(row.id, anchor: .center)
        } else {
            scroller?.scrollTo(t.isOpen() ? Self.top : TierList.heading, anchor: .top)
        }
    }

    /// The stirred copy's landing row, measured. Mid-switch, the mark moves there and the outgoing list scrolls to it,
    /// so the incoming list unstirs, and is then rebuilt, centred on its landing.
    private func reach(_ row: CGRect) {
        guard shown != listed, mark == nil else { return }
        mark = row
        arriving = true
    }

    /// A drag is the strip's once its first 15 points run at least twice as far sideways as up or down; the scroll view
    /// keeps anything steeper, and the drag is then ignored to its end.
    nonisolated static func isSideways(_ move: CGSize) -> Bool { abs(move.width) > 2 * abs(move.height) }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 15)
            .updating($dragging) { _, dragging, _ in dragging = true }
            .onChanged { v in moved(v.translation, from: v.startLocation.y) }
            .onEnded { v in lifted(v.translation.width, predicted: v.predictedEndTranslation.width) }
    }

    private func moved(_ move: CGSize, from y: CGFloat) {
        if sideways == nil { sideways = Self.isSideways(move) }
        // Beside play the drag stirs nothing; let go far enough, it still switches.
        if sideways == true, playing == nil { dragged(move.width, at: y) }
    }

    private func lifted(_ dx: CGFloat, predicted: CGFloat) {
        if sideways == true { released(dx, predicted: predicted) }
        sideways = nil
    }

    /// A sideways drag stirs the list about the middle of the screen, the way the finger pulls it: leftward below the
    /// middle turns clockwise. Left heads for the next tier; with none that way it barely gives.
    private func dragged(_ dx: CGFloat, at y: CGFloat) {
        guard !busy else { return }
        let next = shown.step(dx < 0 ? 1 : -1)
        let hand = y > pivot ? 1.0 : -1.0
        let angle = -Double(dx) / 120 * hand * (next == nil ? 0.2 : 1)
        spin = reduceMotion ? 0 : angle
        fade = min(abs(angle) / (1.6 * .pi), 1) * dim
    }

    private func released(_ dx: CGFloat, predicted: CGFloat) {
        guard !busy else { return }
        if let next = shown.step(dx < 0 ? 1 : -1), abs(dx) > 70 || abs(predicted) > 200 {
            go(to: next, turning: spin < 0 ? -1 : 1)
        } else {
            settling = true
            withAnimation(.spring(duration: 0.4)) {
                spin = 0
                fade = 0
            } completion: {
                settling = false
            }
        }
    }

    /// Plughole, swiped to whirlpool, swiped to vortex, then plughole tapped in the strip.
    private func tour() async {
        func pause(_ s: Double) async { try? await Task.sleep(for: .seconds(s)) }
        // A finger's leftward swipe below the middle of the list, at 60 Hz, easing out, then let go.
        func swipe(_ dx: CGFloat) async {
            let y = pivot + 0.25 * reach
            for i in 1...20 {
                let t = Double(i) / 20
                moved(CGSize(width: dx * (1 - (1 - t) * (1 - t)), height: 0), from: y)
                await pause(1 / 60)
            }
            lifted(dx, predicted: 1.8 * dx)
        }
        await pause(1.6)
        await swipe(-140)
        await pause(2.8)
        await swipe(-140)
        await pause(3.4)
        select(.plughole)
    }

    /// Over the endless row's trailing edge while a run is saved: a second tap within the window drops the run and
    /// starts another, so a slip never loses one; under VoiceOver it stays armed until focus leaves, as reset does.
    /// Plain, as the rows are: a touch that ends a stir neither arms it nor taps.
    private var newRun: some View {
        Button {
            guard !twisting else { return }
            let tap = ResetArm.tap(now: .now, armedAt: newRunArmed, played: true, held: voiceOver)
            newRunArmed = tap.armedAt
            guard tap.reset else {
                AccessibilityNotification.Announcement("Tap again for a new run").post()
                return Sound.shared.play(.tap)
            }
            Resume.remove("endless")
            saved = nil
            pick(.endless(Run(seed: .random(in: .min ... .max))), anew: true)
        } label: {
            Text(newRunArmed == nil ? "new run" : "new run? tap again").font(.ui(.detail)).lineLimit(1).opacity(0.55).hit()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(newRunArmed == nil ? "New run" : "New run, tap again to confirm")
        .accessibilityHint("Drops the saved run and starts another.")
        .accessibilityFocused($newRunFocused)
        .onChange(of: newRunFocused) { if !newRunFocused && voiceOver { newRunArmed = nil } }
        .task(id: newRunArmed) {
            // VoiceOver's announcement and its double tap take longer than the window.
            guard newRunArmed != nil, !voiceOver, (try? await Task.sleep(for: .seconds(ResetArm.window))) != nil else { return }
            newRunArmed = nil
        }
    }

    /// A touch that ends a stir must not open the row it lifted over, nor tap. The row of the level playing beside the
    /// menu opens nothing, as it is open: endless's row would deal a new run over the one playing. `anew`: a new run.
    private func pick(_ level: Level) { pick(level, anew: false) }

    private func pick(_ level: Level, anew: Bool) {
        guard !twisting, Self.opens(level, playing: playing, anew: anew) else { return }
        Sound.shared.play(.tap)
        onPick(level)
    }

    /// Whether a row opens its level: always, but beside play the playing level's own row, as endless's row would deal
    /// a new run over the one playing; `anew` is endless's new run.
    nonisolated static func opens(_ level: Level, playing: Level?, anew: Bool = false) -> Bool {
        anew || playing?.id != level.id
    }

    /// A locked row tapped sounds as a seized knob does, unless the touch ends a stir.
    private func refuse() -> Bool {
        guard !twisting else { return false }
        Sound.shared.play(.seized)
        return true
    }
}

/// What a menu that stays up between levels follows: `refresh` on each level opened, left or finished, `follow` the
/// level playing beside it and the row left as it leaves, and `look` a tier a result card points at.
private struct Refreshed: ViewModifier {
    let revision: Int
    let playing: String?
    let start: Tier?
    let refresh: () -> Void
    let follow: () -> Void
    let look: () -> Void

    func body(content: Content) -> some View {
        content
            .onChange(of: revision) { refresh() }
            .onChange(of: playing) { follow() }
            .onChange(of: start) { look() }
    }
}

/// A tier's rule and rows, and a locked tier's gate. Compared by what changes its rows (the tier, the unlock, the row
/// playing beside it, the menu's revision and the row lit), never by a frame of a drag or a stir, so neither rebuilds it.
private struct TierList: View, Equatable {
    let tier: Tier
    let pick: (Level) -> Void
    let refuse: () -> Bool
    /// The row that flashes as it appears.
    var flash: String?
    /// UNSTIR_LOCKTAP: the locked row held tapped.
    var held: String?
    /// Given the landing row's frame in the list's own space, once laid out.
    var report: ((CGRect) -> Void)?
    /// The level playing beside the menu: its hairline stays lit.
    var playing: String?
    /// The menu's, so a menu that stays up beside play redraws the rows' results as levels finish.
    var revision = 0
    /// Read as the menu redraws, so the editors' switch opens the rows as its sheet closes.
    var unlocked = Best.unlocked

    nonisolated static func == (a: Self, b: Self) -> Bool {
        a.tier == b.tier && a.unlocked == b.unlocked && a.playing == b.playing && a.revision == b.revision && a.flash == b.flash
    }

    private static let space = "tierList"
    /// The header's id: the same on every tier, so mid-switch the outgoing list's header stands where the incoming one's
    /// will.
    static let heading = "heading"

    var body: some View {
        let open = tier.isOpen()
        return VStack(alignment: .leading, spacing: 0) {
            header(open: open)
            if !open, let below = tier.below { gate(below) }
            let levels = tier.levels, frontier = tier.frontier(), landing = report == nil ? nil : tier.landing()
            ForEach(Array(levels.enumerated()), id: \.element.id) { i, level in
                let reached = unlocked || i == 0 || Best.load(levels[i - 1].id) != nil
                let opens = !open ? tier.below.map { "par every \($0.rawValue) level to open" }
                    : reached ? nil : "solve \(levels[i - 1].label) to open"
                LevelRow(level: level, enabled: open && reached, opens: opens, frontier: level.id == frontier?.id,
                         flash: level.id == flash, held: level.id == held, needs: open && !reached ? levels[i - 1] : nil,
                         gate: open ? nil : tier.below, playing: level.id == playing, pick: pick, refuse: refuse)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frame in
                        if level.id == landing?.id { report?(frame) }
                    }
            }
        }
        .coordinateSpace(.named(Self.space))
    }

    /// The tier's rule, named, with its progress.
    private func header(open: Bool) -> some View {
        let par = tier.atPar()
        return HStack(spacing: 10) {
            Text(tier.rawValue).font(.ui(.detail, .semibold)).foregroundStyle(tier.sweep).fixedSize()
            Rectangle().fill(tier.sweep).frame(height: 1).opacity(0.8)
            Text(open ? "\(par.filter { $0 }.count)/\(par.count) at par" : "locked").font(.ui(.detail)).opacity(0.4)
        }
        .padding(.top, 14).padding(.bottom, 8)
        .id(Self.heading)
    }

    /// What opens a locked tier: a tick per level of the tier below, lit once that level is at par.
    @ViewBuilder private func gate(_ below: Tier) -> some View {
        let par = below.atPar(), lit = par.filter { $0 }.count
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.ui(.detail, .semibold))
                Text("opens with every \(below.rawValue) level at par").font(.ui(.label))
                Spacer(minLength: 0)
                Text("\(lit)/\(par.count)").font(.ui(.label, .semibold))
            }
            .foregroundStyle(tier.glow)
            .shadow(color: tier.glow.opacity(0.5), radius: 5)
            HStack(spacing: 0) {
                ForEach(Array(zip(below.levels, par).enumerated()), id: \.offset) { i, tick in
                    if i > 0 { Spacer(minLength: 0) }
                    Capsule().fill(tick.1 ? tick.0.colour : Color.text.opacity(0.24)).frame(width: 3, height: 16)
                        .shadow(color: tick.1 ? tick.0.colour : .clear, radius: 3)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Locked. Opens with every \(below.rawValue) level at par: \(lit) of \(par.count).")
        .padding(.top, 12)
        shortList(below)
    }

    /// The levels still short of par, each run a button that opens its first.
    @ViewBuilder private func shortList(_ below: Tier) -> some View {
        let runs = below.short(), levels = below.levels
        if !runs.isEmpty {
            Flow {
                Text("short:").font(.ui(.label)).opacity(0.45).frame(minHeight: 36).padding(.trailing, 2)
                ForEach(Array(runs.enumerated()), id: \.offset) { i, run in
                    let first = levels[run.lowerBound], last = levels[run.upperBound]
                    // One view with the dot after it, so a wrapped line never starts on a dot.
                    HStack(spacing: 0) {
                        Button { pick(first) } label: {
                            Text(run.count == 1 ? first.label : "\(first.label)\u{2013}\(last.label)")
                                .font(.ui(.label, .semibold)).foregroundStyle(first.colour)
                                .shadow(color: first.colour.opacity(0.6), radius: 3)
                                .padding(.horizontal, 6).frame(minWidth: 32, minHeight: 36).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(run.count == 1 ? "\(below.rawValue) \(first.label), short of par"
                                            : "\(below.rawValue) \(first.label) to \(last.label), short of par")
                        .accessibilityHint("Opens \(below.rawValue) \(first.label)")
                        if i < runs.count - 1 {
                            Text("\u{00B7}").font(.ui(.label)).opacity(0.3).frame(minHeight: 36).accessibilityHidden(true)
                        }
                    }
                }
            }
            .padding(.bottom, 6)
        }
    }
}

private struct LevelRow: View {
    let level: Level
    var detail: String?
    var best: Text?
    let enabled: Bool
    /// What opens a locked row, said for a moment when it is tapped.
    var opens: String?
    /// The first level without a best: its hairline stays lit.
    var frontier = false
    /// Its hairline lights once as the row appears, the row just left or the landing.
    var flash = false
    /// UNSTIR_LOCKTAP: a tap on this locked row held, its line up.
    var held = false
    /// What a shut row waits on, for VoiceOver: a level, or the tier below a closed tier.
    var needs: Level?
    var gate: Tier?
    /// The daily and endless, until either is first opened.
    var new = false
    /// Endless's row while a run is saved.
    var continues = false
    /// Playing beside the menu: its hairline stays lit at full, and it says so under its title.
    var playing = false
    let pick: (Level) -> Void
    /// A tap on a locked row: false while a stir is under the finger.
    let refuse: () -> Bool
    @State private var lit = 0.0
    @State private var said = false
    @State private var taps = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Room for a four-letter label ("past") at the label's size.
    @ScaledMetric(relativeTo: .subheadline) private var numberWidth = 40.0

    var body: some View {
        let result = Best.load(level.id)
        // At the accessibility sizes the number takes its own width and the result goes under the title, so the title
        // keeps the row's width.
        let large = typeSize.isAccessibilitySize
        // Started and no best yet: endless and the sandbox have none; a daily left on its first visit stays tried all day,
        // as practice saves no best.
        let tried = result == nil && level.run == nil && !level.sandbox && Best.started(level.id)
        let rods = level.layout.base.map { "\($0.rods.count) rods + swirl" } ?? "\(level.layout.rods.count) rods"
        let saying = (said || held) && opens != nil
        return Button { enabled ? pick(level) : tapped() } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // A locked number stays bright enough that the hue walk still reads on first launch.
                Text(level.label).font(.ui(.label, .semibold)).foregroundStyle(level.colour)
                    .shadow(color: enabled ? level.colour : .clear, radius: 4).opacity(enabled ? 1 : 0.7)
                    .frame(width: large ? nil : numberWidth, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title).font(.ui(.body)).multilineTextAlignment(.leading).opacity(enabled ? 1 : 0.38)
                    if saying, let opens {
                        Text(opens).font(.ui(.detail)).foregroundStyle(level.colour).transition(.opacity)
                    } else if playing {
                        // In place of its rods and par, which the level's header shows: the frontier's hairline is
                        // lit too, so the hairline alone can't say which row is in the tank.
                        Text("playing").font(.ui(.detail)).foregroundStyle(level.colour)
                    } else {
                        Text(detail ?? rods + " \u{00B7} par \(level.par)").font(.ui(.detail))
                            // A locked row's own detail is its reason, as on the daily, so it stays readable.
                            .opacity(enabled || detail != nil ? 0.32 : 0.12).transition(.opacity)
                    }
                    if large { mark(result, tried: tried) }
                }
                .animation(.easeOut(duration: 0.2), value: saying)
                Spacer(minLength: 8)
                if !large { mark(result, tried: tried) }
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
            .keyframeAnimator(initialValue: 0.0, trigger: taps) { row, x in
                row.offset(x: reduceMotion ? 0 : x)
            } keyframes: { _ in
                LinearKeyframe(-5.0, duration: 0.06)
                LinearKeyframe(4.0, duration: 0.08)
                LinearKeyframe(-2.0, duration: 0.07)
                LinearKeyframe(0.0, duration: 0.07)
            }
        }
        // Plain: `pick` taps, and only when it opens the row.
        .buttonStyle(.plain)
        .modifier(Speech(Self.spoken(Spoken.row(level, result: result, tanks: Best.tanks, detail: detail, enabled: enabled,
                                                needs: needs, gate: gate, started: tried || continues, new: new),
                                    playing: playing)))
        .rowHairline(level.colour, max(lit, playing ? 1 : frontier ? 0.75 : 0))
        .onAppear { if flash { light() } }
        // A menu that stays up wide flashes the row left without appearing anew.
        .onChange(of: flash) { if flash { light() } }
    }

    /// The playing level's row says so first, as its lit hairline shows it.
    static func spoken(_ s: (label: String, value: String, hint: String), playing: Bool) -> (label: String, value: String, hint: String) {
        playing ? (s.label, ["playing", s.value].filter { !$0.isEmpty }.joined(separator: ", "), s.hint) : s
    }

    /// The row's result, or what stands for one.
    private func mark(_ result: Best?, tried: Bool) -> some View {
        Group {
            if let best {
                best.opacity(0.55)
            } else if let result, result.clean == true {
                Text("clean").fontWeight(.semibold).foregroundStyle(Color.lime).shadow(color: .lime, radius: 3)
            } else if let result, result.over == 0 {
                Text("par").foregroundStyle(Color.amber)
            } else if let result {
                Text("+\(result.over)").foregroundStyle(Color.magenta)
            } else if new {
                // Plain white, unlike every result's colour.
                Text("new").opacity(0.8)
            } else if tried {
                Text("tried").opacity(0.4)
            }
        }
        .font(.ui(.detail))
    }

    private func light() {
        guard !reduceMotion else { return }
        lit = 1
        withAnimation(.easeOut(duration: 1.4).delay(0.35)) { lit = 0 }
    }

    /// A light shake, and what opens the row for two seconds.
    private func tapped() {
        guard refuse() else { return }
        taps += 1
        said = true
        let tap = taps
        Task {
            try? await Task.sleep(for: .seconds(2))
            if taps == tap { said = false }
        }
    }
}

extension View {
    /// A row's hairline, in its list's left margin, clear of the number.
    func rowHairline(_ colour: Color, _ opacity: Double, inset: CGFloat = 13) -> some View {
        overlay(alignment: .leading) {
            Capsule().fill(colour).frame(width: 2).padding(.vertical, inset).shadow(color: colour, radius: 4)
                .offset(x: -11).opacity(opacity).allowsHitTesting(false)
        }
    }
}

/// Its views left to right, wrapping onto lines as wide as it is, each line's views on a common centre.
private struct Flow: SwiftUI.Layout {
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

/// The thank-you for a purchase (Jack's call M6, round 14): a four-pointed glint in hairline after the title, in the
/// tier's sweep, the glyph the daily's share line carries. It never moves or asks for anything.
struct SupporterMark: View {
    let sweep: LinearGradient
    let glow: Color

    var body: some View {
        Sparkle().stroke(sweep, lineWidth: 1).frame(width: 13, height: 13)
            .shadow(color: glow.opacity(0.7), radius: 3)
    }
}

/// Four points joined by curves bowed in to the centre.
private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY), r = min(rect.width, rect.height) / 2
        let tips = [CGPoint(x: c.x, y: c.y - r), CGPoint(x: c.x + r, y: c.y), CGPoint(x: c.x, y: c.y + r),
                    CGPoint(x: c.x - r, y: c.y)]
        var p = Path()
        p.move(to: tips[0])
        for k in 1...4 { p.addQuadCurve(to: tips[k % 4], control: c) }
        p.closeSubpath()
        return p
    }
}

/// A pack's card opened from another card's link, Complete's: back returns there while that pack's card is still the
/// one up, never once the card has changed, closed or been put away under a level, then opened again.
struct CameFrom: Equatable {
    let back: Offer
    let card: Offer

    /// Kept across a change of card only while the card is still the one it opened.
    func kept(as now: Offer?) -> CameFrom? { now == card ? self : nil }

    /// Where back goes, while Complete still saves anything.
    func returns(card now: Offer?, offersComplete: Bool) -> Offer? {
        guard now == card, back != .complete || offersComplete else { return nil }
        return back
    }
}
