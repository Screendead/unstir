// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A hollow's ground (SlopePack.metal): dark water between two jambs, a ledge at depth `ledge` and a floor at `floor`
/// of a frame `size`, lit from `source` in the offer's own beams; Escapement's is the page, the same rock engraved.
/// The one place the inside's ground is drawn, so the foundation's own can take it over.
struct HollowGround: View {
    let offer: Offer
    let size: CGSize
    let ledge: CGFloat
    let floor: CGFloat
    let source: CGPoint
    @Environment(\.displayScale) private var scale

    /// Escapement's inside, its dive and its levels are paper.
    static func paper(_ offer: Offer) -> Bool { offer == .pack(.escapement) }

    /// The cover's light, leading beam first: Lens's magenta, Prism's white split in three, the bundle's warm.
    static func beams(_ offer: Offer) -> [SIMD3<Float>] {
        switch offer {
        case .pack(.prism): [SIMD3(1, 0.16, 0.16), SIMD3(0.16, 1, 0.3), SIMD3(0.2, 0.4, 1)]
        case .pack(.lens): [SIMD3(0.85, 0.1, 0.62), SIMD3(1, 0.17, 0.84), SIMD3(0.62, 0.12, 0.9)]
        case .pack(.escapement): [SIMD3(0, 0, 0), SIMD3(0, 0, 0), SIMD3(0, 0, 0)]
        case .pack(.firstStir), .complete: [SIMD3(1, 0.62, 0.3), SIMD3(1, 0.78, 0.45), SIMD3(1, 0.66, 0.5)]
        }
    }

    /// The floor's top at `x` of a frame `width` across, for a floor at depth `floor`: the shader's.
    static func floor(_ x: CGFloat, width: CGFloat, at floor: CGFloat) -> CGFloat { floor + 8 * sin(x * 440 / width * 0.012 + 0.5) }

    /// Where a stone's middle stands on the ledge, from the leading edge of a frame `width` across.
    static func seat(width: CGFloat) -> CGFloat { 94 * width / 440 }

    var body: some View {
        let beams = Self.beams(offer)
        Rectangle().fill(.black)
            .colorEffect(ShaderLibrary.slopeInside(
                .float2(size), .float(scale), .float4(ledge, floor, Self.paper(offer) ? 1 : 0, 0), .float2(source),
                .float3(beams[0].x, beams[0].y, beams[0].z), .float3(beams[1].x, beams[1].y, beams[1].z),
                .float3(beams[2].x, beams[2].y, beams[2].z)))
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A pack's hollow opened (docs/slope.md, 8.2 to 8.6), or Triptych I's: its inside, where the pack is shown, tried,
/// bought and restored, and under its floor the pack's own slope, where a level is picked. It takes the place of
/// `PackCard` and is handed what that was. It brings itself in and out: the cover rises from `from`, the hollow's place
/// on the screen, and Escapement's page spreads from there; the way back draws it in again before `onBack`.
struct SlopePack: View {
    let offer: Offer
    /// The harness's clip time, else the clip runs; it also holds every arrival, for a still.
    var clock: Double?
    /// The pack's own, unless the harness lists placeholders.
    var levels: [Level]
    /// UNSTIR_CARDSCROLL: opens on the pack's slope.
    var scrolled = false
    /// The ledge the pack's slope opens on: the pack's level just left, or after a solve the one after it.
    var focus: Level?
    /// Opened by a level past the taste: it opens on buying, under a line that says the free levels are played.
    var arrived = false
    /// Where the way back goes: the menu, or Triptych I's hollow when this one was opened from it.
    var backTo = Shop.menu
    /// The hollow's opening on the screen, which the cover rises out of; nil arrives in place.
    var from: CGPoint?
    let onBack: () -> Void
    let onPlay: (Level) -> Void
    /// Triptych I's inside opens a pack's from its name.
    var onOffer: (Offer) -> Void = { _ in }
    /// Beside the menu in a wide window, not over it, so VoiceOver reaches both.
    var beside = false
    /// Its way out closes it rather than going to the menu, which isn't under it.
    var closes = false
    /// Bumped by the edge swipe (2.11): it does what the way back on screen does, rising from the pack's slope to
    /// the inside, or leaving the inside.
    var swiped = 0
    var store = Store.shared
    /// The harness's: sinks to the pack's slope by itself, then rises from a closed ledge, for a film.
    var demo = false

    @State private var buying = false
    @State private var landings = 0
    @State private var pulses = 0
    /// On the pack's own slope, under the floor.
    @State private var diving: Bool
    /// Risen from a closed ledge: the inside opens on buying.
    @State private var sent = false
    /// The inside has arrived: false on the way in and on the way out.
    @State private var entered = false
    @State private var leaving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    init(offer: Offer, clock: Double? = nil, levels: [Level], scrolled: Bool = false, focus: Level? = nil, arrived: Bool = false,
         backTo: String = Shop.menu, from: CGPoint? = nil, onBack: @escaping () -> Void, onPlay: @escaping (Level) -> Void,
         onOffer: @escaping (Offer) -> Void = { _ in }, beside: Bool = false, closes: Bool = false, swiped: Int = 0,
         store: Store = .shared, demo: Bool = false) {
        self.swiped = swiped
        self.demo = demo
        self.offer = offer
        self.clock = clock
        self.levels = levels
        self.scrolled = scrolled
        self.focus = focus
        self.arrived = arrived
        self.backTo = backTo
        self.from = from
        self.onBack = onBack
        self.onPlay = onPlay
        self.onOffer = onOffer
        self.beside = beside
        self.closes = closes
        self.store = store
        let onSlope = !levels.isEmpty && !arrived && (scrolled || focus.map { f in levels.contains { $0.id == f.id } } == true)
        _diving = State(initialValue: onSlope)
    }

    private var paper: Bool { HollowGround.paper(offer) }
    private var page: Page { paper ? .book : .night }
    private var held: Bool { clock != nil }

    var body: some View {
        let state = store.state(offer)
        GeometryReader { geo in
            let size = geo.whole, insets = geo.safeAreaInsets
            ZStack {
                // Under the inside and the slope as one gives way to the other: the page, or the hollow's dark.
                (paper ? Color.bone : Color(0x06070B))
                if diving {
                    PackSlope(offer: offer, levels: levels, start: focus ?? Shop.landing(levels, owned: state == .owned), clock: clock, insets: insets,
                              onRise: { rise(buying: false) }, onPlay: onPlay, onClosed: { rise(buying: true) }, store: store)
                        .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom))
                            .combined(with: .opacity))
                } else {
                    HollowInside(offer: offer, clock: clock, levels: levels, arrived: arrived, sent: sent,
                                 back: Shop.rise(to: backTo, beside: beside || closes), from: from, size: size, insets: insets,
                                 entered: entered || held, settles: !leaving, buying: buying, pulses: pulses,
                                 onBack: leave, onPlay: onPlay, onOffer: onOffer, onBuy: buy, onDive: dive, store: store)
                        .transition(reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .top), removal: .move(edge: .top))
                            .combined(with: .opacity))
                }
            }
            .frame(width: size.width, height: size.height)
            // The page spreads from the cover as a soft-edged wash; the dark inside comes up out of the slope's own dark.
            .modifier(Wash(shown: entered || held ? 1 : 0, at: from ?? CGPoint(x: size.width / 2, y: size.height * 0.3), size: size,
                           spreads: paper && !reduceMotion))
            .ignoresSafeArea()
        }
        .environment(\.page, page)
        // The status bar turns dark over the page, as over an Escapement level.
        .preferredColorScheme(paper && !beside ? .light : nil)
        .accessibilityAddTraits(beside ? [] : .isModal)
        .accessibilityAction(.escape) { diving ? rise(buying: false) : leave() }
        .task { await store.fetchPrices() }
        // A promoted purchase buys as the stone does, once the launch knows what the player owns.
        .onChange(of: store.promoted, initial: true) {
            guard store.promoted == offer else { return }
            store.promoted = nil
            Task {
                await store.settled()
                guard store.state(offer) != .owned, store.canPay, !buying else { return }
                buy(offer)
            }
        }
        .onAppear {
            Log.write("card \(offer.key) opens")
            if state == .owned { store.said(offer) }
            if let pack = offer.pack {
                Analytics.shared.cardSeen(pack)
                Marks.seen(pack, fits: pack.fits())
            }
            withAnimation(reduceMotion ? .easeOut(duration: 0.24) : .easeOut(duration: 0.6)) { entered = true }
        }
        .onChange(of: Reading(state: state, ready: store.firstReadDone)) { old, new in
            // Until the launch's first read has finished, an owned pack reads as unowned: that read is no change, even
            // when it lands past `Store.readLimit`.
            guard old.ready, new.state != old.state else { return }
            let unshared = offer.pack.map(store.unshared) ?? false
            if let tag = new.state.tag(unshared: unshared) { AccessibilityNotification.Announcement("\(offer.name) \(tag.word)").post() } // loc: verbatim a name, then a word localized by Purchase
            // A purchase, an approval or a restore landing here: the solve's chime, and the closed pebbles light in turn.
            if Shop.lands(old.state, new.state, ready: old.ready) {
                landings += 1
                store.landed = true
                Sound.shared.play(.solve)
                // An approved Ask to Buy landing here is said by the landing, not the menu.
                store.said(offer)
            }
        }
        .haptic(.success, trigger: landings)
        .onChange(of: swiped) { diving ? rise(buying: false) : leave() }
        .task {
            guard demo else { return }
            try? await Task.sleep(for: .seconds(3.5))
            dive()
            try? await Task.sleep(for: .seconds(3))
            rise(buying: true)
        }
    }

    private struct Reading: Equatable {
        let state: Purchase
        let ready: Bool
    }

    private func buy(_ o: Offer) {
        buying = true
        Task {
            await store.purchase(o.productID)
            buying = false
        }
    }

    /// Through the floor, onto the pack's own slope.
    private func dive() {
        guard !levels.isEmpty, !diving else { return }
        Log.write("card \(offer.key) dives")
        withAnimation(reduceMotion ? .easeOut(duration: 0.24) : .easeOut(duration: 0.9)) { diving = true }
    }

    /// Back up to the inside; from a closed ledge, to buying, whose stone pulses.
    private func rise(buying: Bool) {
        sent = buying
        withAnimation(reduceMotion ? .easeOut(duration: 0.24) : .easeOut(duration: 0.9)) { diving = false }
        if buying { pulses += 1 }
    }

    /// The inside draws back to its hollow, then goes.
    private func leave() {
        guard !leaving else { return }
        leaving = true
        withAnimation(reduceMotion ? .easeIn(duration: 0.24) : .easeIn(duration: 0.45)) {
            entered = false
        } completion: {
            onBack()
        }
    }
}

/// How the whole hollow shows: Escapement's page as a wash that spreads from the cover, a growing soft-edged circle;
/// every other, and every one under Reduce Motion, as a fade.
private struct Wash: ViewModifier, Animatable {
    var shown: Double
    let at: CGPoint
    let size: CGSize
    let spreads: Bool

    nonisolated var animatableData: Double {
        get { shown }
        set { shown = newValue }
    }

    func body(content: Content) -> some View {
        if spreads {
            let reach = hypot(max(at.x, size.width - at.x), max(at.y, size.height - at.y)) + 80
            content.mask {
                Rectangle().fill(RadialGradient(stops: [.init(color: .black, location: 0), .init(color: .black, location: 0.82),
                                                        .init(color: .clear, location: 1)],
                                                center: UnitPoint(x: at.x / size.width, y: at.y / size.height),
                                                startRadius: 0, endRadius: max(reach * shown * 1.22, 0.01)))
            }
        } else {
            content.opacity(shown)
        }
    }
}

/// The slope's own water is what scrolled words go out into: the system's blur and dimming under the status bar and
/// over the home indicator are left off.
private struct BareEdges: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) { content.scrollEdgeEffectHidden(true, for: .all) } else { content }
    }
}

/// An arrival that overshoots a touch and comes to rest (1.5): `1 - exp(-6x) * cos(5x)`.
private func settle(_ x: Double) -> Double { 1 - exp(-6 * x) * cos(5 * x) }

/// The cover rising out of its hollow to the clip's place, growing as it comes.
private struct Rise: ViewModifier, Animatable {
    /// 0 in the hollow, 1 in place.
    var p: Double
    let from: CGSize
    let scale: CGFloat
    /// Arriving, it settles; leaving, it eases.
    let settles: Bool

    nonisolated var animatableData: Double {
        get { p }
        set { p = newValue }
    }

    func body(content: Content) -> some View {
        let s = settles ? settle(p) : p * p * (3 - 2 * p)
        content.scaleEffect(scale + (1 - scale) * s).offset(x: from.width * (1 - s), y: from.height * (1 - s))
    }
}

/// A line of the inside arriving in its turn: fading in over 0.6 s while it rises to its place and settles; under
/// Reduce Motion it fades in where it stands.
private struct Arrive: ViewModifier {
    let turn: Int
    let on: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let wait = on ? 0.5 + 0.13 * Double(turn) : 0
        content
            .offset(y: on || reduceMotion ? 0 : 14)
            .animation(.spring(response: 0.6, dampingFraction: 0.6).delay(wait), value: on)
            .opacity(on ? 1 : 0)
            .animation(.easeOut(duration: on ? 0.6 : 0.2).delay(wait), value: on)
    }
}

// MARK: - The inside

/// The inside of a hollow (8.2): the clip, the pack's name and what it is, the ledge with its stone (8.3), Triptych I's
/// line, the floor with the pack's levels as a tally (8.4), and restore. It scrolls where it is taller than the
/// screen, the way back staying pinned.
private struct HollowInside: View {
    let offer: Offer
    let clock: Double?
    let levels: [Level]
    let arrived: Bool
    /// Sent up from a closed ledge of the pack's slope: it opens on buying.
    let sent: Bool
    let back: (text: String, spoken: String)
    let from: CGPoint?
    let size: CGSize
    let insets: EdgeInsets
    let entered: Bool
    let settles: Bool
    let buying: Bool
    let pulses: Int
    let onBack: () -> Void
    let onPlay: (Level) -> Void
    let onOffer: (Offer) -> Void
    let onBuy: (Offer) -> Void
    let onDive: () -> Void
    let store: Store

    /// The ledge's and the floor's depths in the scrolled content, read from where the stone and the tally are laid.
    @State private var ledge: CGFloat = 722
    @State private var floor: CGFloat = 842
    /// How far the inside is scrolled, and how far past its foot it has been pulled.
    @State private var scroll: CGFloat = 0
    @State private var past: CGFloat = 0
    @AccessibilityFocusState private var spoken: Focus?
    private enum Focus: Hashable { case note, buy }
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.page) private var page
    @ScaledMetric(relativeTo: .largeTitle) private var nameSize = 44.2

    private static let space = "slope.inside"
    private var paper: Bool { page.paper }
    private var large: Bool { typeSize.isAccessibilitySize }
    private var pack: Pack? { offer.pack }

    private func ink(_ ink: SlopeInk) -> Color {
        // On paper every word is the page's ink, and what is `ink3` on water is `ink2` there.
        guard paper else { return ink.colour }
        switch ink {
        case .ink: return .ink
        case .ink2, .ink3: return Color.ink.opacity(TextTone.text2.alpha)
        case .ink4: return Color.ink.opacity(TextTone.text3.alpha)
        }
    }

    /// The clip: 290 across on the reference phone, no taller than 0.36 of the screen, smaller beside large words.
    private var side: CGFloat { min(large ? 200 : 290, size.width - 110, size.height * 0.36) }
    /// The clip's top: under the way back.
    private var top: CGFloat { insets.top + (size.height > 800 ? 84 : 58) }

    var body: some View {
        let state = store.state(offer)
        ScrollViewReader { reader in
            ScrollView(.vertical, showsIndicators: false) {
                column(state)
                    .frame(width: size.width)
                    .frame(minHeight: size.height, alignment: .top)
                    .background(alignment: .top) {
                        GeometryReader { content in
                            HollowGround(offer: offer, size: content.size, ledge: ledge, floor: pack == nil ? content.size.height + 400 : floor,
                                         source: CGPoint(x: size.width / 2, y: top + side / 2))
                        }
                    }
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frame in
                        scroll = -frame.minY
                        past = size.height - frame.maxY
                    }
            }
            .coordinateSpace(.named(Self.space))
            .scrollBounceBehavior(.always)
            .modifier(BareEdges())
            .onAppear {
                // The gate's arrival, and a closed ledge's, open on buying.
                if arrived || sent { reader.scrollTo("buy", anchor: .center) }
            }
            .task {
                // VoiceOver lands on a new screen's first element, the way back, after it appears; the wait lets that
                // land first.
                guard arrived || sent else { return }
                try? await Task.sleep(for: .milliseconds(600))
                spoken = arrived && Shop.arrival(offer, levels, state: store.state(offer)) != nil ? .note : .buy
            }
        }
        // A pull past the foot sinks through the floor.
        .onChange(of: past > 64) { if past > 64 { onDive() } }
        .overlay(alignment: .topLeading) { way }
        .animation(reduceMotion ? nil : .snappy(duration: 0.45), value: state)
    }

    /// The way back, pinned: scrolled words go out under it into the water's own shade.
    private var way: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(stops: [.init(color: paper ? .bone : Color(0x06070B), location: 0), .init(color: paper ? .bone : Color(0x06070B), location: 0.62),
                                   .init(color: (paper ? Color.bone : Color(0x06070B)).opacity(0), location: 1)], startPoint: .top, endPoint: .bottom)
                .frame(width: size.width, height: insets.top + 78)
                .opacity(min(max(scroll / 40, 0), 1))
                .allowsHitTesting(false)
            Button(action: onBack) {
                Text(back.text).font(.slope(.ui, .body)).foregroundStyle(ink(.ink)).hit() // loc: verbatim localized by Shop
            }
            .buttonStyle(Sounding())
            .accessibilityLabel(back.spoken) // loc: verbatim localized by Shop
            .padding(.leading, 28)
            .padding(.top, insets.top + 8)
        }
    }

    @ViewBuilder private func column(_ state: Purchase) -> some View {
        let owned = state == .owned
        VStack(spacing: 0) {
            PackClip(offer: offer, side: side, held: clock)
                .modifier(Rise(p: entered ? 1 : 0,
                               from: from.map { CGSize(width: $0.x - size.width / 2, height: $0.y - top - side / 2) } ?? .zero,
                               scale: from == nil || reduceMotion ? 1 : SlopeHollow.full / side, settles: settles))
                .animation(reduceMotion || clock != nil ? nil : settles ? .linear(duration: 1.3) : .easeIn(duration: 0.45), value: entered)
                .padding(.top, top)
            VStack(spacing: 0) {
                eyebrow(owned).padding(.top, 24)
                Text(verbatim: offer.name).font(.system(size: nameSize, weight: .light))
                    .foregroundStyle(paper ? Color.ink : offer.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
            }
            .modifier(Arrive(turn: 0, on: entered))
            if let pitch = offer.pitch {
                Text(pitch).font(.slope(.place, .body)).foregroundStyle(ink(.ink)) // loc: verbatim localized by Offer
                    .multilineTextAlignment(.center).padding(.top, 6)
                    .modifier(Arrive(turn: 1, on: entered))
            }
            facts(owned).padding(.top, 18)
                .modifier(Arrive(turn: 2, on: entered))
            VStack(spacing: 6) {
                if let note = offer.note { small(note) }
                if offer.arriving { small(String(localized: "More levels arrive in an update.")) }
            }
            .padding(.top, 10)
            .modifier(Arrive(turn: 3, on: entered))
            VStack(spacing: 0) {
                if arrived, let note = Shop.arrival(offer, levels, state: state) {
                    Text(note).font(.slope(.place, .body)).foregroundStyle(ink(.ink)) // loc: verbatim localized by Shop
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 22)
                        .accessibilityFocused($spoken, equals: .note)
                }
                counter(state).padding(.top, 24).id("buy")
                if store.ready, pack != nil, !owned, store.canPay, let saving = store.saving, Offer.hollows().contains(.complete) {
                    triptych(saving).padding(.top, 20)
                }
            }
            .modifier(Arrive(turn: 4, on: entered))
            Spacer(minLength: 34)
            VStack(spacing: 0) {
                if pack == nil {
                    bundled
                } else if !levels.isEmpty {
                    HollowFloor(offer: offer, levels: levels, owned: owned, width: size.width, action: onDive, store: store)
                        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.space)).minY + HollowFloor.sill } action: { floor = $0 }
                }
                if Pack.hollowed().contains(where: { store.state($0) != .owned }) { restore.padding(.top, 14) }
            }
            .modifier(Arrive(turn: 5, on: entered))
        }
        .padding(.horizontal, 44)
        .padding(.bottom, max(insets.bottom, 20) + 4)
    }

    private func eyebrow(_ owned: Bool) -> some View {
        (pack == nil
            ? owned ? Text("bundle", comment: "The bundle's hollow, over its name, owned")
                : Text("bundle \u{00B7} paid add-on", comment: "The bundle's hollow, over its name")
            : owned ? Text("pack", comment: "A pack's hollow, over its name, owned")
                : Text("pack \u{00B7} paid add-on", comment: "A pack's hollow, over its name"))
            .font(.slope(.data, .detail)).foregroundStyle(ink(.ink3))
            .multilineTextAlignment(.center)
    }

    /// Who it is for, the taste and what it holds; the bundle's saving. An owner's is home, not a shop: no taste, and
    /// its progress, on the floor, for what it holds.
    private func facts(_ owned: Bool) -> some View {
        VStack(spacing: 4) {
            if let assumes = offer.assumes { fact(assumes) }
            if !owned { fact(offer.free) }
            if !owned || pack == nil { fact(offer.holds) }
            if pack == nil, !owned, let saving = store.saving {
                fact(String(localized: "save \(saving)", comment: "The bundle's hollow: what it saves on the packs not owned. A price"))
            }
        }
    }

    private func fact(_ words: String) -> some View {
        Text(words).font(.slope(.ui, .label)).foregroundStyle(ink(.ink2)) // loc: verbatim localized by the caller
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    private func small(_ words: String, _ tone: SlopeInk = .ink3) -> some View {
        Text(words).font(.slope(.ui, .detail)).foregroundStyle(ink(tone)) // loc: verbatim localized by the caller
            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: The ledge

    /// The ledge (8.3): the pack's stone leading, the taste trailing, and under them what the store has to say.
    @ViewBuilder private func counter(_ state: Purchase) -> some View {
        let plays = state == .owned && store.ready ? Shop.plays(offer, levels) : nil
        let ledge = Shop.ledge(offer, state: state, ready: store.ready, buying: buying, asked: store.asked(offer),
                               unshared: pack.map(store.unshared) ?? false, canPay: store.canPay, price: store.price(offer.productID),
                               pricing: store.pricing, failure: store.failures[offer.productID])
        let owned = state == .owned && store.ready
        let taste = owned || !store.ready ? nil : Shop.taste(levels)
        let seat = HollowGround.seat(width: size.width)
        VStack(alignment: .leading, spacing: 8) {
            // The stone's row: its middle is where the ledge is cut, so the stone rests on it.
            Group {
                if large {
                    VStack(alignment: .leading, spacing: 6) {
                        stone(owned: owned, plays: plays, ledge: ledge)
                        if let taste { tasteControl(taste).padding(.leading, 37) }
                    }
                } else {
                    HStack(spacing: 12) {
                        stone(owned: owned, plays: plays, ledge: ledge)
                        Spacer(minLength: 0)
                        if let taste { tasteControl(taste) }
                    }
                }
            }
            .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.space)).minY } action: { self.ledge = $0 + 32 }
            let under = owned ? [Shop.owned(offer)] : ledge.under
            if !under.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(under.enumerated()), id: \.offset) { _, line in status(line) }
                }
                .padding(.leading, 37)
                .accessibilityElement(children: .combine)
                .id(state)
                .transition(reduceMotion ? .identity : .opacity.combined(with: .offset(y: 8)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Out of the centred column's margins: the stone stands where the ledge juts from the leading jamb.
        .padding(.leading, seat - 12.5 - 44)
        .padding(.trailing, 52 * size.width / 440 - 44)
    }

    /// The stone, or with nothing to buy here the words alone in its place.
    @ViewBuilder private func stone(owned: Bool, plays: (level: Level, label: String, spoken: String)?, ledge: Shop.Ledge) -> some View {
        let prism = offer == .pack(.prism)
        if owned {
            if let plays {
                Stone(state: .next, pale: prism, engraved: paper, glow: offer.glow, ink: paper ? nil : offer.ink) { onPlay(plays.level) } label: {
                    Text(plays.label).font(.slope(.ui, .body, .semibold)).fixedSize(horizontal: false, vertical: true) // loc: verbatim localized by Shop
                }
                .frame(height: 44)
                .accessibilityLabel(plays.spoken) // loc: verbatim localized by Shop
            } else {
                Color.clear.frame(width: 25, height: 44)
            }
        } else if let state = ledge.stone {
            Stone(state: state, pale: prism, engraved: paper, glow: offer.glow, ink: paper ? nil : offer.ink) { onBuy(offer) } label: {
                (Text(ledge.label) + Text(verbatim: ledge.price.map { " \($0)" } ?? "")) // loc: verbatim localized by Shop, then the App Store's price
                    .font(.slope(.ui, .body, .semibold)).fixedSize(horizontal: false, vertical: true)
            }
            .frame(minHeight: 44)
            .frame(height: large ? nil : 44)
            .disabled(!ledge.live)
            .background(alignment: .leading) { pulse }
            .accessibilityLabel(ledge.spoken) // loc: verbatim localized by Shop
            .accessibilityValue(store.ready ? store.price(offer.productID) ?? store.pricing.words ?? "" : "") // loc: verbatim the App Store's price, or localized by Pricing
            .accessibilityFocused($spoken, equals: .buy)
        } else {
            Color.clear.frame(width: 25, height: 44)
        }
    }

    /// A closed ledge sent the player here: the stone's glow swells once.
    private var pulse: some View {
        let light = offer == .pack(.prism) ? Color(0xE2ECFF) : offer.glow
        return Circle().fill(RadialGradient(colors: [light.opacity(0.5), light.opacity(0)], center: .center, startRadius: 0, endRadius: 60))
            .frame(width: 120, height: 120)
            .keyframeAnimator(initialValue: 0.0, trigger: pulses) { glow, swell in
                glow.scaleEffect(1 + 0.6 * swell).opacity(reduceMotion || paper ? 0 : swell)
            } keyframes: { _ in
                // Held while the inside rises back into place.
                LinearKeyframe(0, duration: 0.7)
                CubicKeyframe(1, duration: 0.3)
                CubicKeyframe(0, duration: 0.3)
            }
            .offset(x: 12.5 - 60)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func tasteControl(_ taste: (level: Level, replay: Bool)) -> some View {
        let n = pack?.taste ?? 3
        return Button { onPlay(taste.level) } label: {
            (taste.replay ? Text("replay 01\u{2013}\(String(format: "%02d", n)) \u{203A}",
                                 comment: "A pack's card: replays its free levels. The last's number")
                : Text("try \(n) free \u{203A}", comment: "A pack's card: plays its free levels. How many"))
                .font(.slope(.ui, .body)).foregroundStyle(ink(.ink))
                .fixedSize()
                .hit()
        }
        .buttonStyle(Sounding())
        .accessibilityLabel(taste.replay ? Text("Replay the \(n) free levels", comment: "VoiceOver: a pack's card. How many") // loc: verbatim each a key
                            : Text("Try the first \(n) levels free", comment: "VoiceOver: a pack's card. How many"))
    }

    /// A line under the stone: its colour says what it says on water; on paper it is ink.
    private func status(_ line: Shop.Line) -> some View {
        let colour: Color = switch line.signal {
        case .lime: page.signal(.lime)
        case .amber: page.signal(.amber)
        case .magenta: page.signal(.magenta)
        case nil: ink(line.quiet ? .ink3 : .ink2)
        }
        return HStack(alignment: .firstTextBaseline, spacing: 7) {
            if line.light { PendingLight() }
            Text(line.words).font(.slope(.ui, .detail)).foregroundStyle(colour) // loc: verbatim localized by Shop
                .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Triptych I's line, the bundle's packs, restore

    /// Buys the bundle instead. Its own failure is said here, beside the control that tried, never as the pack's.
    private func triptych(_ saving: String) -> some View {
        let complete = store.price(Pack.triptychID) ?? "", waits = store.state(.complete) == .pending
        // Non-breaking within each part, so a narrow phone or a large size wraps the line only before "· save".
        func joined(_ s: String) -> String { s.replacingOccurrences(of: " ", with: "\u{00A0}") }
        return VStack(spacing: 6) {
            Button { onBuy(.complete) } label: {
                (Text("or all \(Offer.countWord(Pack.bundled.count)) in \(joined(Offer.bundleName))\u{00A0}\u{00B7}\u{00A0}",
                      comment: "A pack's card: buys the bundle instead. Its packs counted in words, then its name")
                 + Text(verbatim: joined(complete)) + Text(verbatim: " ")
                 + Text(joined(String(localized: "\u{00B7} save \(saving) \u{203A}", comment: "A pack's card: what the bundle saves. A price")))) // loc: verbatim localized here
                    .font(.slope(.ui, .detail)).foregroundStyle(ink(waits ? .ink4 : .ink2))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .hit(10, 8)
            }
            .buttonStyle(Sounding())
            // Triptych I's own request is asked again only from Triptych I's hollow.
            .disabled(buying || waits)
            .accessibilityLabel("Buy \(Offer.bundleName), \(Pack.named(Pack.bundled))")
            .accessibilityValue("\(complete), saves \(saving)")
            if store.state(.complete) == .failed {
                Text("\(Offer.bundleName)'s purchase didn't go through").font(.slope(.ui, .detail)).foregroundStyle(page.signal(.magenta))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                if let why = store.failures[Pack.triptychID]?.words { small(why) }
            }
        }
    }

    /// In the floor's place in Triptych I's: each of its packs, with its progress, opening that pack's hollow.
    private var bundled: some View {
        VStack(spacing: 2) {
            ForEach(Pack.bundled, id: \.self) { pack in
                Button { onOffer(.pack(pack)) } label: {
                    (Text(verbatim: pack.name).font(.slope(.ui, .body)).foregroundStyle(ink(.ink))
                     + Text(verbatim: "  ") + Text(Shop.progress(pack.levels, pack: pack)).font(.slope(.data, .detail)).foregroundStyle(ink(.ink3)) // loc: verbatim localized by Shop
                     + Text(verbatim: " \u{203A}").font(.slope(.ui, .body)).foregroundStyle(ink(.ink2)))
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(Sounding())
                .accessibilityLabel(Text("Open \(pack.name)"))
                .accessibilityValue(Shop.progress(pack.levels, pack: pack)) // loc: verbatim localized by Shop
            }
        }
        .padding(.bottom, 10)
    }

    private var restore: some View {
        VStack(spacing: 4) {
            Button { Task { await store.restoreAndAnnounce() } } label: {
                Text(store.restoring ? store.restoreNote ?? ConsentWords.restore : ConsentWords.restore) // loc: verbatim localized by Store and ConsentWords
                    .font(.slope(.ui, .detail)).foregroundStyle(ink(.ink2))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).hit(16)
            }
            .buttonStyle(Sounding())
            .disabled(store.restoring)
            if !store.restoring, let note = store.restoreNote { small(note, .ink2) }
        }
    }
}

/// Ask to Buy's light: small, amber, breathing; on paper a still mark in the plate's vermilion.
private struct PendingLight: View {
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.page) private var page

    var body: some View {
        Group {
            if page.paper {
                Circle().strokeBorder(page.stop, lineWidth: 1.5)
            } else {
                Circle().fill(Color.amber).shadow(color: .amber, radius: on ? 5 : 2).opacity(on ? 1 : 0.5)
            }
        }
        .frame(width: 7, height: 7)
        .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 2 }
        .onAppear {
            if reduceMotion { on = true } else { withAnimation(.easeInOut(duration: 0.9).repeatForever()) { on = true } }
        }
        .accessibilityHidden(true)
    }
}

/// The floor of a hollow (8.4): the pack's levels as small pebbles resting on it, a group to a chapter, and under
/// them how many are at par. A count, too small to pick from: the whole floor is one control, which sinks to the
/// pack's own slope, as its line says.
private struct HollowFloor: View {
    let offer: Offer
    let levels: [Level]
    let owned: Bool
    let width: CGFloat
    let action: () -> Void
    let store: Store

    @Environment(\.page) private var page
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far under the control's top the floor's top lies.
    static let sill: CGFloat = 22

    var body: some View {
        let par = levels.filter { Best.load($0.id)?.over == 0 }.count
        Button(action: action) {
            VStack(spacing: 0) {
                tally.frame(height: Self.sill)
                (Text(verbatim: owned ? String(localized: "done \(Shop.progress(levels, pack: offer.pack))",
                                               comment: "An owned pack's hollow, on its floor: its progress. Levels at par, or solved, of all")
                           : Shop.progress(levels, pack: offer.pack))
                    .font(.slope(.data, .detail)).foregroundStyle(page.paper ? Color.ink.opacity(TextTone.text2.alpha) : SlopeInk.ink3.colour)
                 + Text(verbatim: " \u{00B7} ").font(.slope(.data, .detail)).foregroundStyle(page.paper ? Color.ink.opacity(TextTone.text2.alpha) : SlopeInk.ink3.colour)
                 + Text("levels \u{2193}", comment: "A pack's hollow, after its floor's count: sinks to the pack's levels")
                    .font(.slope(.ui, .detail)).foregroundStyle(page.paper ? Color.ink : SlopeInk.ink2.colour))
                    .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 26)
                    .padding(.bottom, 6)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(Sounding())
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(offer.pack == .escapement // loc: verbatim each a key
            ? Text("Levels, \(levels.count), \(par) solved", comment: "VoiceOver: Escapement's floor. Its levels, then how many are solved")
            : Text("Levels, \(levels.count), \(par) at par", comment: "VoiceOver: a pack's floor. Its levels, then how many are at par"))
    }

    /// The mock-up's row: groups 66 points apart on the reference phone, pebbles 9.4 apart, each on the floor's curve.
    private var tally: some View {
        let chapters = Shop.chapters(levels), k = width / 440
        let most = CGFloat(chapters.map(\.levels.count).max() ?? 1), groups = CGFloat(chapters.count)
        let step = 9.4 * k, pitch = groups > 1 ? min((311 * k - (most - 1) * step) / (groups - 1), 82 * k) : 0
        let span = pitch * (groups - 1) + (most - 1) * step, lead = (width - span) / 2
        let prism = offer == .pack(.prism)
        return GeometryReader { geo in
            // The control is centred in the screen, so its own frame's x is the screen's less its leading edge.
            let inset = (width - geo.size.width) / 2
            ZStack(alignment: .topLeading) {
                ForEach(Array(chapters.enumerated()), id: \.offset) { c, chapter in
                    ForEach(Array(chapter.levels.enumerated()), id: \.element.id) { i, level in
                        let x = lead + CGFloat(c) * pitch + CGFloat(i) * step
                        let open = store.access(level) != .needsCard, solved = Best.load(level.id) != nil
                        let n = (offer.pack?.number(of: level.id) ?? 1) - 1
                        let y = HollowGround.floor(x, width: width, at: Self.sill)
                        ZStack {
                            SlopePebble(kind: page.paper ? .engraved : .dull, width: 6.8, lean: SlopePebble.lean(n), dimmed: true)
                                .opacity(open ? 0 : page.paper ? 0.5 : 1)
                            // Lit with a best; without one paler, but the taste's, the way in, as bright as the way on.
                            SlopePebble(kind: page.paper ? .engraved : prism ? .pale : solved || owned ? .lit : .next, width: 8.4,
                                        lean: SlopePebble.lean(n), glow: prism || page.paper || solved || owned ? nil : offer.glow)
                                .opacity(open ? solved || !owned ? 1 : 0.5 : 0)
                        }
                        // A purchase landing lights the closed pebbles one after another.
                        .animation(reduceMotion ? nil : .easeOut(duration: 0.3).delay(0.06 * Double(max(0, n - (offer.pack?.taste ?? 0)))), value: open)
                        .position(x: x - inset, y: y - 2.6)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - The pack's own slope

extension SlopeColumn {
    /// A pack's own column (1.2, 8.4): a stretch per chapter, one terrace of its levels, in pale rock and still water
    /// over a floor, sized for the type as the main column is.
    static func pack(_ levels: [Level], size: CGSize, type: DynamicTypeSize) -> SlopeColumn {
        let large = type.isAccessibilitySize
        let row = TypeRole.body.line(at: type).height * (large ? 2 : 1) + TypeRole.detail.line(at: type).height
        let pitch = max(110, row + 60)
        let header = max(pitch, TypeRole.display.line(at: type).height * (large ? 2 : 1) + TypeRole.detail.line(at: type).height + 40)
        return SlopeColumn(stretches: Shop.chapters(levels).map { Stretch(rock: .pale, terraces: [$0.levels.count], header: header) },
                           foot: .floor, surface: false, pitch: pitch, lip: large ? 62 : 132 - max(440 - size.width, 0) / 2,
                           step: large ? 1.5 : 6, first: nil)
    }
}

/// A pack's own slope (8.4): the dive of a tier, a stretch per chapter and a ledge per level, where a pack's level is
/// picked. The levels past the taste are closed to a player without the pack: a tap on one rises to buying.
private struct PackSlope: View {
    let offer: Offer
    let levels: [Level]
    /// The ledge it lands on.
    let start: Level?
    let clock: Double?
    let insets: EdgeInsets
    let onRise: () -> Void
    let onPlay: (Level) -> Void
    let onClosed: () -> Void
    let store: Store

    /// How many ledges the slope shows open: all the store opens, but while a purchase lands one more every 60 ms.
    @State private var lit: Int
    /// Where the dive opened, kept as it was: a purchase landing moves the way on, not the camera.
    @State private var aim: SlopeAim?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.page) private var page

    init(offer: Offer, levels: [Level], start: Level?, clock: Double?, insets: EdgeInsets, onRise: @escaping () -> Void,
         onPlay: @escaping (Level) -> Void, onClosed: @escaping () -> Void, store: Store) {
        self.offer = offer
        self.levels = levels
        self.start = start
        self.clock = clock
        self.insets = insets
        self.onRise = onRise
        self.onPlay = onPlay
        self.onClosed = onClosed
        self.store = store
        let open = levels.prefix { store.access($0) != .needsCard }.count
        _lit = State(initialValue: open == levels.count ? .max : open)
        _aim = State(initialValue: start.flatMap { s in levels.firstIndex { $0.id == s.id } }.map { SlopeAim(ledge: $0) })
    }

    private var large: Bool { typeSize.isAccessibilitySize }
    private var noPar: Bool { offer.pack == .escapement }

    var body: some View {
        GeometryReader { geo in
            let size = geo.whole
            let column = SlopeColumn.pack(levels, size: size, type: typeSize)
            let owned = offer.pack.map { store.state($0) == .owned } ?? false
            // The way on: an owner's next level, or the first free one without a best.
            let next = Shop.landing(levels, owned: owned).flatMap { n in Best.load(n.id) == nil ? n.id : nil }
            let bars = insets.top + SlopeMeasure.line(.body, at: typeSize) + 34
            SlopeDive(column: column, aim: aim, look: SlopeLook(paper: page.paper ? 1 : 0, rock: .pale),
                      clock: clock, near: false) { view in
                SlopeLayer {
                    ForEach(Array(Shop.chapters(levels).enumerated()), id: \.offset) { s, chapter in
                        heading(chapter, stretch: s, view: view).slopeUnderBars(bars)
                    }
                    ForEach(Array(levels.enumerated()), id: \.element.id) { n, level in
                        let open = store.access(level) != .needsCard && n < lit
                        SlopeLedgeRow(ledge: ledge(level, open: open, next: level.id == next), view: view, n: n, bars: bars,
                                      open: { onPlay(level) }, refused: onClosed)
                    }
                }
            }
            .modifier(BareEdges())
            .overlay(alignment: .topLeading) {
                Button(action: onRise) {
                    Text(verbatim: "\u{2191} \(offer.name)").font(.slope(.ui, .body))
                        .foregroundStyle(page.paper ? Color.ink : SlopeInk.ink.colour)
                        .shadow(color: page.paper ? .clear : Color(0x03060A).opacity(0.8), radius: 4)
                        // On the page the rock's line gives way to the words, as an engraver leaves room for a legend.
                        .background { if page.paper { Color.bone.padding(-5).blur(radius: 4) } }
                        .hit()
                }
                .buttonStyle(Sounding())
                .accessibilityLabel(Text("Back", comment: "VoiceOver: a pack's card, its back button"))
                .padding(.leading, 28)
                .padding(.top, insets.top + 8)
                .accessibilitySortPriority(1)
            }
            // A purchase landing lights the closed ledges one after another, 60 ms apart.
            .onChange(of: owned) {
                guard owned, !reduceMotion, lit < levels.count else { return lit = .max }
                Task {
                    for n in lit ..< levels.count {
                        try? await Task.sleep(for: .milliseconds(60))
                        lit = n + 1
                    }
                    lit = .max
                }
            }
        }
    }

    /// A chapter's name over its first ledge, and under it how many of its levels are at par, or solved.
    private func heading(_ chapter: (name: String?, levels: [Level]), stretch s: Int, view: SlopeView) -> some View {
        let lay = view.lay, first = lay.ledge(stretch: s)
        let at = SlopeLedgeRow.words(view, first, large: large)
        let y = view.y(lay.headers[s]) + lay.column.stretches[s].header * 0.42
        return VStack(alignment: .leading, spacing: 3) {
            Text(chapter.name?.localizedLowercase ?? String(localized: "levels", comment: "A pack's card: its list's heading, where it has no chapters")) // loc: verbatim localized by the pack's table
                .font(.slope(.place, .title)).foregroundStyle(page.paper ? Color.ink : SlopeInk.ink.colour)
            Text(Shop.progress(chapter.levels, pack: offer.pack)).font(.slope(.data, .detail)) // loc: verbatim localized by Shop
                .foregroundStyle(page.paper ? Color.ink.opacity(SlopeInk.ink3.strength) : SlopeInk.ink3.colour)
        }
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: at.width, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .slopeLine(CGPoint(x: at.x, y: y))
    }

    /// What a level's ledge says (2.2): its number, name, result and facts. Escapement, which has no par, has its
    /// result in words and its rods alone for facts.
    private func ledge(_ level: Level, open: Bool, next: Bool) -> SlopeLedge {
        let best = Best.load(level.id), tried = best == nil && Best.started(level.id)
        let mark = Archive.Mark(best, started: tried)
        let rods = level.layout.base.map { String(localized: "\($0.rods.count) rods + swirl", comment: "A swirl layout's knobs, then its swirl") }
            ?? String(localized: "\(level.layout.rods.count) rods", comment: "VoiceOver: a layout's rods")
        let facts = noPar ? rods : String(localized: "\(rods) \u{00B7} par \(level.par)", comment: "A row's rods, then its par")
        let said = best.map {
            noPar ? ($0.over == 0 ? String(localized: "solved", comment: "VoiceOver: Escapement's best, solved")
                     : String(localized: "\($0.over) over par", comment: "VoiceOver: an archive day's best. Moves over par"))
                : Spoken.result($0)
        } ?? (tried ? String(localized: "tried", comment: "VoiceOver: a row started, with no best") : "")
        let word: String? = !noPar || !open ? nil
            : best.map { $0.over == 0 ? String(localized: "solved", comment: "A pack's row: Escapement's best") : "+\($0.over)" }
                ?? (tried ? String(localized: "tried", comment: "VoiceOver: a row started, with no best") : nil)
        return SlopeLedge(
            number: level.label, name: level.title,
            state: !open ? .closed : best != nil ? .solved : next ? .frontier : tried ? .tried : .open,
            marks: noPar || !open ? nil : ResultMarks.filled(mark), margin: ResultMarks.margin(mark), word: word, facts: facts,
            look: page.paper ? .engraved : offer == .pack(.prism) ? .pale : .warm,
            glow: offer == .pack(.prism) ? nil : next ? offer.glow : SlopeColumn.Rock.pale.light,
            label: String(localized: "Level \(Int(level.label) ?? 0), \(level.title).", comment: "VoiceOver: a menu row. Level number, then its title"),
            value: !open ? String(localized: "locked, needs the pack", comment: "VoiceOver: a pack's row past its free levels, unowned")
                : next ? [String(localized: "next", comment: "VoiceOver: the ledge that is the way on"), said].filter { !$0.isEmpty }.joined(separator: ", ")
                : said,
            hint: open ? facts : String(localized: "Shows where to buy \(offer.name)", comment: "VoiceOver: a pack's locked row. The pack"))
    }
}

private extension GeometryProxy {
    /// The whole screen's size, the safe areas in.
    var whole: CGSize {
        CGSize(width: size.width + safeAreaInsets.leading + safeAreaInsets.trailing,
               height: size.height + safeAreaInsets.top + safeAreaInsets.bottom)
    }
}

// MARK: - The harness

#if DEBUG
/// UNSTIR_SLOPE's stages for the packs, beside `SlopeHarness`'s, for shots and films. Debug builds only.
///
/// - `hollows`: the main column's dive at UNSTIR_SLOPEAT (a tier's level by its id, `L11`), stand-in pebbles and
///   names on its ledges, and every hollow on the shelf where it lies. The store's states, prices and bests are the
///   harness's own (UNSTIR_STORE, UNSTIR_OWNED, UNSTIR_PRICES, UNSTIR_BESTS).
/// - `inside`: UNSTIR_CARD's hollow opened, as `SlopePack` shows it: UNSTIR_CARDSCROLL=1 on the pack's slope,
///   UNSTIR_SLOPEFOCUS=prism-7 on that level's ledge, UNSTIR_ARRIVED=1 as a level past the taste opens it,
///   UNSTIR_SLOPEFROM=56,420 with its cover rising from that point. UNSTIR_LANDS lands its purchase.
struct SlopePackHarness: View {
    enum Stage: String { case hollows, inside }

    let stage: Stage
    let env: [String: String]
    let clock: Double?
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var opened: Offer?
    @State private var from: CGPoint?
    @State private var shut = false

    init?(_ env: [String: String], clock: Double?) {
        guard let stage = env["UNSTIR_SLOPE"].flatMap(Stage.init(rawValue:)) else { return nil }
        self.stage = stage
        self.env = env
        self.clock = clock
    }

    private var card: Offer { env["UNSTIR_CARD"].flatMap(Offer.init(name:)) ?? .pack(.prism) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if stage == .hollows { hollows }
            if let offer = stage == .inside && !shut ? card : opened {
                let point = env["UNSTIR_SLOPEFROM"].map { $0.split(separator: ",").compactMap { Double($0) } }
                SlopePack(offer: offer, clock: clock, levels: offer.levels(), scrolled: env["UNSTIR_CARDSCROLL"] == "1",
                          focus: env["UNSTIR_SLOPEFOCUS"].flatMap { id in offer.levels().first { $0.id == id } },
                          arrived: env["UNSTIR_ARRIVED"] == "1",
                          from: from ?? point.flatMap { $0.count == 2 ? CGPoint(x: $0[0], y: $0[1]) : nil },
                          onBack: { opened = nil; shut = true }, onPlay: { _ in }, onOffer: { opened = $0 }, demo: env["UNSTIR_SLOPEDEMO"] == "1")
                    .id(offer)
            }
        }
    }

    private var hollows: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            let column = Self.column(size: size, type: typeSize)
            let at = env["UNSTIR_SLOPEAT"].flatMap { id in Tier.allCases.flatMap(\.levels).first { $0.id == id } }.flatMap(SlopeColumn.ledge(of:))
            SlopeDive(column: column, aim: SlopeAim(ledge: at ?? SlopeColumn.ledge(tier: 0, level: 13)), clock: clock, near: !typeSize.isAccessibilitySize) { view in
                SlopeLayer {
                    ForEach(Array(Tier.plughole.levels.prefix(27).enumerated()), id: \.offset) { i, level in
                        let n = SlopeColumn.ledge(tier: 0, level: i + 1), seat = view.seat(n), done = Best.load(level.id) != nil
                        let x = typeSize.isAccessibilitySize ? SlopeHollow.wordsX : view.lip(n).x + 18
                        SlopePebble(kind: done ? .lit : .dull, width: view.lay.half(done ? .lit : .dull) * 2, lean: SlopePebble.lean(i + 1),
                                    glow: view.lay.rocks[n].light, dimmed: !done)
                            .seated(at: seat)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: "\(level.label)  \(level.title)").font(.slope(.ui, .body)).ink(done ? .ink : .ink4) // loc: verbatim a stand-in
                            Text(verbatim: "\(level.layout.rods.count) rods \u{00B7} par \(level.par)").font(.slope(.data, .detail)).ink(done ? .ink3 : .ink4) // loc: verbatim a stand-in
                        }
                        .frame(maxWidth: max(size.width - x - 16, 60), alignment: .leading)
                        .slopeLine(CGPoint(x: x, y: seat.y - 5))
                    }
                    if Shop.shown() {
                        // As the menu places them (`SlopeMenu`'s hollows).
                        let large = typeSize.isAccessibilitySize, lay = view.lay
                        ForEach(Offer.hollows().filter { $0 != .complete || Store.shared.offersComplete }, id: \.self) { offer in
                            let above = SlopeColumn.ledge(tier: 0, level: SlopeMenuPlan.hollowAfter(offer))
                            let y = large ? view.y(lay.tops[above] + lay.drops[above] - SlopeMenuPlan.hollowRow(typeSize) - 6)
                                : view.y(lay.between(above)) - SlopeHollow.full / 2
                            let spot = SlopeSpot(view: view, ledge: above, point: CGPoint(x: large ? 48 : 56, y: y), side: SlopeHollow.full, near: 1)
                            SlopeHollow(offer, on: spot, type: typeSize) { middle in
                                from = middle
                                opened = offer
                            }
                            .slopePlace(spot.point, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    /// The main column with each hollow's own row opened under its ledge at the accessibility sizes, as the menu lays it.
    static func column(size: CGSize, type: DynamicTypeSize) -> SlopeColumn {
        var column = SlopeColumn.main(size: size, type: type, header: TypeRole.body.line(at: type).height * 3.4)
        if type.isAccessibilitySize {
            let row = SlopeMeasure.line(.body, at: type) + SlopeMeasure.line(.detail, at: type) + 8
            var rows = [CGFloat](repeating: 0, count: 27)
            for offer in Offer.hollows() { rows[SlopeMenuPlan.hollowAfter(offer) - 1] = row + SlopeMenuPlan.hollowRow(type) + 60 }
            column.stretches[1].rows = rows
        }
        return column
    }
}
#endif
