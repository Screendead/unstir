// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

extension Level {
    /// Every twelve levels walk the grid's whole hue sweep, so the first screen shows all of it; whirlpool walks blood
    /// red through magenta to violet, vortex on from violet through blue to teal, maelstrom crimson down to bile. The daily is amber, endless cyan, the sandbox
    /// magenta.
    var colour: Color {
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
    func frontier(_ best: (String) -> Best? = Best.load) -> Level? {
        isOpen(best) ? levels.first { best($0.id) == nil } : nil
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
    /// "next ›" opens, or itself as its list's last. Nil for the daily, endless and the sandbox, which sit at the top.
    func focus(solved: Bool) -> Level? {
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
    let onPick: (Level) -> Void
    /// The pack card over the menu, opened from the dock or by a level that needs it.
    @Binding var card: Offer?
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
    /// The focused row's id until its flash has started, so a later rebuild of its tier's list doesn't flash it again.
    @State private var flashing: String?
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
    /// The pack dock's height: the scroll view counts it in its bottom safe area, but the list ends at it.
    @State private var dock: CGFloat = 0
    /// The tier's list in the scroll view's space.
    @State private var list = CGRect.zero
    @State private var scroller: ScrollViewProxy?
    /// The list has opened on its focus.
    @State private var arrived = false
    /// Mid-switch, the incoming tier's landing row in its list's own space, measured on the stirred copy: the scroll
    /// view still holds the outgoing list, so it scrolls to a mark placed there instead.
    @State private var mark: CGRect?
    /// The mark has moved and the list scrolls to it once it is laid out there.
    @State private var arriving = false
    @Namespace private var strip
    /// The gear's sheet; UNSTIR_SETTINGS=1 opens with it up.
    @State private var settings: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far the outgoing list turns at its centre before the incoming one takes its place.
    private var turn: Double { reduceMotion ? 0 : 1.6 * .pi }
    /// The list's fade at the swap. At 1 the list read as black for about 0.3 s.
    private let dim = 0.55

    /// `start`: the harness's tier, shown even when locked. `frozen`: UNSTIR_TIERSPIN, the list held mid-twist.
    init(start: Tier? = nil, demo: Bool = false, frozen: (spin: Double, fade: Double)? = nil, settings: Bool = false,
         card: Binding<Offer?>, clock: Double? = nil, placeholders: Int = 0, shelfDemo: Bool = false,
         cardScroll: Bool = false, focus: Level? = nil, held: String? = nil, onPick: @escaping (Level) -> Void) {
        self.demo = demo
        _settings = State(initialValue: settings)
        self.onPick = onPick
        _card = card
        self.clock = clock
        self.placeholders = placeholders
        self.shelfDemo = shelfDemo
        self.cardScroll = cardScroll
        self.focus = focus
        self.held = held
        _flashing = State(initialValue: focus?.id)
        // A tier's own level left lands on its tier, which "up a notch" may have opened since the menu was last up.
        let tier = start ?? focus.flatMap { f in f.tier.levels.contains { $0.id == f.id } ? f.tier : nil } ?? Tier.stored()
        _picked = State(initialValue: tier)
        _shown = State(initialValue: tier)
        _listed = State(initialValue: tier)
        if let frozen {
            _spin = State(initialValue: frozen.spin)
            _fade = State(initialValue: frozen.fade)
            _busy = State(initialValue: true)
        }
    }

    var body: some View {
        // Daily and endless draw on every layout, so they open after the first hex level.
        let modes = Best.unlocked || Best.load(Level.plughole[22].id) != nil
        let analytics = Analytics.shared
        // The menu waits for the question's answer, for VoiceOver too.
        let asking = analytics.asks && analytics.consent == .undecided
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                title.simultaneousGesture(swipe)
                Spacer(minLength: 8)
                Button { settings = true } label: {
                    Image(systemName: "gearshape").font(.system(size: 17, weight: .light))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(Sounding()).opacity(0.5)
                .accessibilityLabel("Settings")
            }
            .padding(.leading, 20).padding(.trailing, 10).padding(.top, 28)
            // The strip keeps the picked name in view itself, so a sideways drag on it is the switcher's, as on the list.
            tiers.padding(.top, 6).scrollDisabled(true).simultaneousGesture(swipe)
            ScrollViewReader { proxy in
                ScrollView { rows(modes: modes) }
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
                if !Offer.shelf().isEmpty {
                    PackDock(open: { show($0, from: $1) }, held: clock, paused: card != nil)
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { dock = $0 }
                }
            }
        }
        .foregroundStyle(Color.text)
        .accessibilityHidden(card != nil || asking)
        .overlay { cardView }
        .overlay {
            if asking { ConsentCard(tier: shown).transition(.opacity) }
        }
        .animation(.easeOut(duration: 0.25), value: asking)
        .sheet(isPresented: $settings) { SettingsSheet() }
        .background {
            // Builds the effect's pipeline before the first switch, which would otherwise stall on it.
            Color.black.frame(width: 2, height: 2).drawingGroup()
                .modifier(Stirred(angle: 0.1, fade: 0, centre: .zero, radius: 1))
        }
        .background(Color.black)
        .onChange(of: dragging) {
            // Cancelled, so `onEnded` never ran.
            if !dragging, sideways != nil {
                if sideways == true { released(0, predicted: 0) }
                sideways = nil
            }
        }
        .task { if demo { await tour() } }
        .task { if shelfDemo { await shelfTour() } }
    }

    /// The modes, then the tier's rule and rows.
    private func rows(modes: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Every stir in this tank has an exact inverse.")
                .font(.mono(13)).opacity(0.55).padding(.top, 10).id(Self.top)
            // Daily and endless say what opens them while they're shut.
            let shut = "opens after plughole \(Level.plughole[22].label)"
            LevelRow(level: Level.daily(), detail: modes ? nil : shut, enabled: modes, pick: pick, refuse: refuse)
                .padding(.top, 22)
            LevelRow(level: .endless(Run(seed: .random(in: .min ... .max))),
                     detail: modes ? "deeper every tank \u{00B7} wrong stirs fill the brim" : shut,
                     best: Best.tanks > 0 ? Text("best \(Best.tanks)") : nil, enabled: modes, pick: pick, refuse: refuse)
            LevelRow(level: .sandbox, detail: "any picture, any rods \u{00B7} nothing counts", enabled: true,
                     pick: pick, refuse: refuse)
            TierList(tier: listed, pick: pick, refuse: refuse, flash: flashing, held: held).equatable()
                .overlay(alignment: .topLeading) {
                    Color.clear.frame(width: 1, height: mark?.height ?? 1).id(Self.mark)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: { _ in
                            guard arriving else { return }
                            arriving = false
                            scroller?.scrollTo(Self.mark, anchor: .center)
                        }
                        .padding(.top, mark?.minY ?? 0)
                }
                .opacity(twisting ? 0 : 1)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .scrollView) } action: {
                    list = $0
                    arrive()
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    /// The card grows out of its cover, or fades in under Reduce Motion.
    @ViewBuilder private var cardView: some View {
        if let card {
            PackCard(offer: card, clock: clock, levels: card.levels(placeholders: placeholders), scrolled: cardScroll,
                     focus: focus, onBack: { show(nil) }, onPlay: { onPick($0) })
                .transition(reduceMotion ? .opacity : .scale(scale: 0.15, anchor: cardFrom).combined(with: .opacity))
                .zIndex(1)
        }
    }

    private func show(_ offer: Offer?, from: UnitPoint = .center) {
        Log.write(offer.map { "card \($0.key) shown" } ?? "card closed")
        if offer != nil { cardFrom = from }
        withAnimation(.snappy(duration: 0.42)) { card = offer }
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
    /// with a margin the effect draws only some of the rows.
    private var twisted: some View {
        let w = list.width, top = band.lowerBound, h = band.upperBound - top
        return ZStack(alignment: .top) {
            if twisting {
                TierList(tier: shown, pick: pick, refuse: refuse, report: reach).equatable()
                    .fixedSize(horizontal: false, vertical: true).frame(width: w)
                    // An alignment guide on a lone child moves nothing, so the copy drew the list from its top.
                    .offset(y: -top)
            }
        }
        .frame(width: w, height: h, alignment: .top)
        .clipped()
        .drawingGroup()
        .modifier(Stirred(angle: spin, fade: fade, centre: CGPoint(x: w / 2, y: h / 2), radius: reach))
        // The effect draws its sampling margin too, opaque.
        .clipped()
        .padding(.leading, list.minX)
        .padding(.top, list.minY + top)
        .allowsHitTesting(false)
    }

    private var twisting: Bool { busy || settling || sideways == true }

    /// The list's visible part, in its own space.
    private var band: ClosedRange<CGFloat> {
        let top = max(-list.minY, 0)
        return top ... max(min(viewport - dock - list.minY, list.height), top + 1)
    }

    /// The middle of the list's visible part, in the scroll view's space.
    private var pivot: CGFloat { list.minY + (band.lowerBound + band.upperBound) / 2 }

    /// Out to the visible part's corners.
    private var reach: CGFloat { hypot(list.width, band.upperBound - band.lowerBound) / 2 }

    /// Cuts to the new tier's sweep at the swap: a gradient doesn't interpolate, and a cross-fade runs through grey.
    private var title: some View {
        Text("UNSTIR").font(.system(size: 34, weight: .black).width(.expanded)).tracking(8)
            .foregroundStyle(shown.sweep).shadow(color: shown.glow.opacity(0.6), radius: 12)
    }

    /// Every tier by name. Scrolls sideways once there are more than fit, keeping the picked one in view.
    private var tiers: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(Tier.allCases, id: \.self) { t in
                        if t != Tier.allCases.first {
                            Text("\u{00B7}").font(.mono(15)).opacity(0.3).padding(.horizontal, 7).frame(height: 36)
                        }
                        // Silent itself: `go` sounds a switch as it starts, however it starts.
                        Button { select(t) } label: { name(t) }
                            .buttonStyle(.plain)
                            .id(t)
                    }
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            // Names run out into the black at the edges, so a strip wider than the screen reads as one that scrolls.
            .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.04),
                                         .init(color: .black, location: 0.9), .init(color: .clear, location: 1)],
                                 startPoint: .leading, endPoint: .trailing))
            .onChange(of: picked) { withAnimation { proxy.scrollTo(picked, anchor: .center) } }
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
                Text(t.rawValue).font(.mono(15, isPicked ? .semibold : .regular))
                    .foregroundStyle(isPicked ? AnyShapeStyle(t.sweep)
                                              : AnyShapeStyle(Color.text.opacity(open ? 0.6 : 0.36)))
                    .shadow(color: isPicked ? t.glow.opacity(0.8) : .clear, radius: 7)
                if !open {
                    Image(systemName: "lock.fill").font(.system(size: 9, weight: .semibold))
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

    private func select(_ t: Tier) {
        if t == shown, !busy {
            withAnimation(.snappy(duration: 0.5)) { land(on: t) }
            return
        }
        guard let from = Tier.allCases.firstIndex(of: shown), let to = Tier.allCases.firstIndex(of: t) else { return }
        go(to: t, turning: to > from ? 1 : -1)
    }

    /// The outgoing list stirs away, then the incoming one unstirs, turning on the same way.
    private func go(to t: Tier, turning dir: Double) {
        guard t != shown, !busy else { return }
        busy = true
        Sound.shared.play(.tier)
        Tier.store(t)
        withAnimation(.snappy(duration: 0.35)) { picked = t }
        withAnimation(.easeIn(duration: 0.32)) {
            spin = dir * turn
            fade = dim
        } completion: {
            shown = t
            // Under the stir's peak, so the jump never shows: a landing row scrolls in once the copy has measured it.
            mark = nil
            if t.landing() == nil { scroller?.scrollTo(Self.top, anchor: .top) }
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
        guard !arrived, let scroller, list.height > 0 else { return }
        arrived = true
        DispatchQueue.main.async {
            if let focus, listed.levels.contains(where: { $0.id == focus.id }) { scroller.scrollTo(focus.id, anchor: .center) }
            flashing = nil
        }
    }

    /// The tier's landing row centred, or the top where it has none.
    private func land(on t: Tier) {
        if let row = t.landing() { scroller?.scrollTo(row.id, anchor: .center) } else { scroller?.scrollTo(Self.top, anchor: .top) }
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
        if sideways == true { dragged(move.width, at: y) }
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

    /// A touch that ends a stir must not open the row it lifted over, nor tap.
    private func pick(_ level: Level) {
        guard !twisting else { return }
        Sound.shared.play(.tap)
        onPick(level)
    }

    /// A locked row tapped sounds as a seized knob does, unless the touch ends a stir.
    private func refuse() -> Bool {
        guard !twisting else { return false }
        Sound.shared.play(.seized)
        return true
    }
}

/// A tier's rule and rows, and a locked tier's gate. Compared by tier alone, so a frame of a drag or a stir doesn't
/// rebuild it: nothing else it reads changes while the menu is up.
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

    nonisolated static func == (a: Self, b: Self) -> Bool { a.tier == b.tier }

    private static let space = "tierList"

    var body: some View {
        let open = tier.isOpen()
        return VStack(alignment: .leading, spacing: 0) {
            header(open: open)
            if !open, let below = tier.below { gate(below) }
            let levels = tier.levels, frontier = tier.frontier(), landing = report == nil ? nil : tier.landing()
            ForEach(Array(levels.enumerated()), id: \.element.id) { i, level in
                let reached = Best.unlocked || i == 0 || Best.load(levels[i - 1].id) != nil
                let opens = !open ? tier.below.map { "par every \($0.rawValue) level to open" }
                    : reached ? nil : "solve \(levels[i - 1].label) to open"
                LevelRow(level: level, enabled: open && reached, opens: opens, frontier: level.id == frontier?.id,
                         flash: level.id == flash, held: level.id == held, pick: pick, refuse: refuse)
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
            Text(tier.rawValue).font(.mono(11, .semibold)).foregroundStyle(tier.sweep)
            Rectangle().fill(tier.sweep).frame(height: 1).opacity(0.8)
            Text(open ? "\(par.filter { $0 }.count)/\(par.count) at par" : "locked").font(.mono(11)).opacity(0.4)
        }
        .padding(.top, 14).padding(.bottom, 8)
    }

    /// What opens a locked tier: a tick per level of the tier below, lit once that level is at par.
    @ViewBuilder private func gate(_ below: Tier) -> some View {
        let par = below.atPar(), lit = par.filter { $0 }.count
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 11, weight: .semibold))
                Text("opens with every \(below.rawValue) level at par").font(.mono(12))
                Spacer(minLength: 0)
                Text("\(lit)/\(par.count)").font(.mono(13, .semibold))
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
        .padding(.bottom, lit == par.count ? 12 : 0)
        shortList(below)
    }

    /// The levels still short of par, each run a button that opens its first.
    @ViewBuilder private func shortList(_ below: Tier) -> some View {
        let runs = below.short(), levels = below.levels
        if !runs.isEmpty {
            Flow {
                Text("short:").font(.mono(12)).opacity(0.45).frame(minHeight: 36).padding(.trailing, 2)
                ForEach(Array(runs.enumerated()), id: \.offset) { i, run in
                    let first = levels[run.lowerBound], last = levels[run.upperBound]
                    if i > 0 { Text("\u{00B7}").font(.mono(12)).opacity(0.3).frame(minHeight: 36) }
                    Button { pick(first) } label: {
                        Text(run.count == 1 ? first.label : "\(first.label)\u{2013}\(last.label)")
                            .font(.mono(12, .semibold)).foregroundStyle(first.colour)
                            .shadow(color: first.colour.opacity(0.6), radius: 3)
                            .padding(.horizontal, 6).frame(minWidth: 32, minHeight: 36).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(run.count == 1 ? "\(below.rawValue) \(first.label), short of par"
                                        : "\(below.rawValue) \(first.label) to \(last.label), short of par")
                    .accessibilityHint("Opens \(below.rawValue) \(first.label)")
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
    let pick: (Level) -> Void
    /// A tap on a locked row: false while a stir is under the finger.
    let refuse: () -> Bool
    @State private var lit = 0.0
    @State private var said = false
    @State private var taps = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let result = Best.load(level.id)
        let rods = level.layout.base.map { "\($0.rods.count) rods + swirl" } ?? "\(level.layout.rods.count) rods"
        let saying = (said || held) && opens != nil
        return Button { enabled ? pick(level) : tapped() } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // A locked number stays bright enough that the hue walk still reads on first launch.
                Text(level.label).font(.mono(13, .semibold)).foregroundStyle(level.colour)
                    .shadow(color: enabled ? level.colour : .clear, radius: 4).opacity(enabled ? 1 : 0.7)
                    .frame(width: 34, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title).font(.mono(14)).multilineTextAlignment(.leading).opacity(enabled ? 1 : 0.38)
                    if saying, let opens {
                        Text(opens).font(.mono(11)).foregroundStyle(level.colour).transition(.opacity)
                    } else {
                        Text(detail ?? rods + " \u{00B7} par \(level.par)").font(.mono(11))
                            // A locked row's own detail is its reason, as on the daily, so it stays readable.
                            .opacity(enabled || detail != nil ? 0.32 : 0.12).transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: saying)
                Spacer(minLength: 8)
                Group {
                    if let best {
                        best.opacity(0.55)
                    } else if let result, result.clean == true {
                        Text("clean").fontWeight(.semibold).foregroundStyle(Color.lime).shadow(color: .lime, radius: 3)
                    } else if let result, result.over == 0 {
                        Text("par").foregroundStyle(Color.amber)
                    } else if let result {
                        Text("+\(result.over)").foregroundStyle(Color.magenta)
                    }
                }
                .font(.mono(11))
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
        .accessibilityValue(enabled ? "" : "locked, \(opens ?? detail ?? "")")
        // In the list's left margin, clear of the number.
        .overlay(alignment: .leading) {
            Capsule().fill(level.colour).frame(width: 2).padding(.vertical, 13).shadow(color: level.colour, radius: 4)
                .offset(x: -11).opacity(max(lit, frontier ? 0.75 : 0)).allowsHitTesting(false)
        }
        .onAppear {
            guard flash, !reduceMotion else { return }
            lit = 1
            withAnimation(.easeOut(duration: 1.4).delay(0.35)) { lit = 0 }
        }
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
