// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What the shelf sells: a pack, or the bundle (`complete`, its old name), which grants `Pack.bundled`.
enum Offer: Hashable, Sendable {
    /// The bundle's name wherever a player reads it, and the App Store's display name with it (Jack's pick, M1).
    static let bundleName = "Triptych I"

    /// A count of packs in words.
    static func countWord(_ n: Int) -> String { n < 2 || n > 6 ? "\(n)" : ["two", "three", "four", "five", "six"][n - 2] }

    case pack(Pack)
    case complete

    static let all: [Offer] = Pack.allCases.map(Offer.pack) + [.complete]

    /// The covers the dock shows. A pack goes on sale only once it has levels past its taste, and the bundle only once
    /// every pack it grants is on sale (Jack, 2026-10-26, S1); a build outside Release shows every cover, so the shop can
    /// be looked at.
    static func shelf(release: Bool = Build.release, ready: (Pack) -> Bool = { $0.levels.count > $0.taste }) -> [Offer] {
        guard release else { return all }
        let sold = Pack.sold(release: release), packs = sold.filter(ready)
        return packs.map(Offer.pack) + (Pack.bundled.allSatisfy(packs.contains) ? [.complete] : [])
    }

    /// The pack a completion's card points to: the first on the shelf the player doesn't own, other than the one just
    /// completed; none once every pack is owned.
    @MainActor static func pointer(after completed: Completion?, shelf: [Offer] = Offer.shelf(),
                                   owned: (Pack) -> Bool = { Store.shared.state($0) == .owned }) -> Pack? {
        guard let completed else { return nil }
        return unowned(except: completed.pack, shelf: shelf, owned: owned)
    }

    /// The first pack on the shelf the player doesn't own, other than `except`.
    @MainActor static func unowned(except: Pack? = nil, shelf: [Offer] = Offer.shelf(),
                                   owned: (Pack) -> Bool = { Store.shared.state($0) == .owned }) -> Pack? {
        shelf.compactMap(\.pack).first { $0 != except && !owned($0) }
    }

    /// The pack "more puzzles in the packs ›" opens, once, on the card of the free ladder's last level (Jack's call M6,
    /// round 14); none where the card already points to a pack from a completion, once it has shown, or once every pack is
    /// owned.
    @MainActor static func ladderEnd(_ level: Level, completed: Completion?, shown: Bool, shelf: [Offer] = Offer.shelf(),
                                     owned: (Pack) -> Bool = { Store.shared.state($0) == .owned }) -> Pack? {
        guard level.pack == nil, level.run == nil, level.id == Tier.allCases.last?.levels.last?.id, !shown,
              pointer(after: completed, shelf: shelf, owned: owned) == nil else { return nil }
        return unowned(shelf: shelf, owned: owned)
    }

    /// The offer a promoted purchase of product `id` buys, if this build sells it.
    static func promoted(_ id: String, release: Bool = Build.release) -> Offer? {
        all.first { $0.productID == id && ($0.pack.map { Pack.sold(release: release).contains($0) } ?? true) }
    }

    /// What the bundle saves over buying the `bundled` packs not `owned` one by one (a pending pack is unowned): nil
    /// unless it saves something and every price that takes is known (Jack's call C7, round 13).
    static func saving(amounts: [String: Decimal], owned: Set<Pack>, bundled: [Pack] = Pack.bundled) -> Decimal? {
        let left = bundled.filter { !owned.contains($0) }.map { amounts[$0.productID] }
        guard !left.isEmpty, let complete = amounts[Pack.completeID], !left.contains(nil) else { return nil }
        let saving = left.compactMap { $0 }.reduce(0, +) - complete
        return saving > 0 ? saving : nil
    }

    /// Whether the bundle is on offer: once every price `saving` takes is in, while it saves; while none is in (loading,
    /// unreachable, or no product came back), only while none of the `bundled` packs is owned, when it holds them all
    /// for less; and with some in but not all, as when the App Store sells the packs here but not the bundle, never.
    /// The prices decide, never whether a fetch is running, so with none of its packs owned a card's fetch never moves
    /// the dock under it.
    static func offersComplete(amounts: [String: Decimal], owned: Set<Pack>, bundled: [Pack] = Pack.bundled) -> Bool {
        let left = bundled.filter { !owned.contains($0) }
        guard !left.isEmpty else { return false }
        let needed = [Pack.completeID] + left.map(\.productID)
        if needed.allSatisfy({ amounts[$0] != nil }) { return saving(amounts: amounts, owned: owned, bundled: bundled) != nil }
        return left.count == bundled.count && needed.allSatisfy { amounts[$0] == nil }
    }

    /// Whether this build sells it.
    var sold: Bool { pack.map { Pack.sold().contains($0) } ?? true }

    /// Some of what it sells is still to come.
    var arriving: Bool { (pack.map { [$0] } ?? Pack.bundled).contains { $0.levels.count < $0.planned } }

    /// A pack's prefix, or "complete", as the harness names it and the clip's file is named.
    init?(name: String) {
        if name == "complete" { self = .complete } else if let p = Pack(rawValue: name) { self = .pack(p) } else { return nil }
    }

    var key: String {
        switch self {
        case .pack(let p): p.rawValue
        case .complete: "complete"
        }
    }

    var pack: Pack? { if case .pack(let p) = self { p } else { nil } }

    var name: String { pack?.name ?? Offer.bundleName }

    var productID: String { pack?.productID ?? Pack.completeID }

    var pitch: String {
        switch self {
        case .pack(.firstStir): "a story told backwards"
        case .pack(.lens): "some rods zoom instead of turning"
        case .pack(.escapement): "clocks tick after every move, on a budget of ticks"
        case .pack(.prism): "each rod stirs only some colours"
        case .complete: "three packs, for less"
        }
    }

    /// What the pack assumes of the player, as its card says it.
    var assumes: String {
        switch self {
        case .pack(.firstStir): "anyone \u{00B7} an evening, not a challenge"
        case .pack(.lens): "after plughole"
        case .pack(.escapement): "hard \u{00B7} composed problems"
        case .pack(.prism): "after plughole \u{00B7} reading by colour"
        case .complete: "after plughole, then harder"
        }
    }

    var holds: String {
        switch self {
        case .pack(.firstStir): "\(Pack.firstStir.planned) \(Pack.firstStir.noun) in five chapters"
        case .pack(.lens): "\(Pack.lens.planned) \(Pack.lens.noun) in four issues"
        case .pack(.escapement): "\(Pack.escapement.planned) \(Pack.escapement.noun) in five chapters"
        case .pack(.prism): "\(Pack.prism.planned) \(Pack.prism.noun) in five trays"
        case .complete: "\(Pack.named(Pack.bundled)) \u{00B7} \(Pack.bundled.map(\.planned).reduce(0, +)) levels"
        }
    }

    /// The dock's header once its Ask to Buy is approved.
    var yours: String { "\(name) is yours" }
    /// A line under the facts, owned or not.
    var note: String? { self == .pack(.prism) ? "letters for colour-blind play, in settings" : nil }

    var free: String {
        switch self {
        case .pack(let p): "levels 1\u{2013}\(p.taste) free, no purchase"
        case .complete: "each pack's first 3 levels"
        }
    }

    var sweep: [Color] {
        switch self {
        case .pack(.firstStir): [Color(0xFFC857), Color(0xFF6FA5), Color(0x7A7CFF)]
        case .pack(.lens): [.neonCyan, .magenta, Color(0xFFE600)]
        case .pack(.escapement): [Color(0xF3EAD8), Color(0xD8402A)]
        case .pack(.prism): [Color(0xFF2A2A), Color(0x2AFF5A), Color(0x3A6BFF)]
        case .complete: [Color(0xFFC857), .neonCyan, Color(0xD8402A)]
        }
    }

    var glow: Color {
        switch self {
        case .pack(.firstStir): Color(0xFFC857)
        case .pack(.lens): .magenta
        case .pack(.escapement): Color(0xD8402A)
        case .pack(.prism): .white
        case .complete: .neonCyan
        }
    }

    /// The pack's levels; before it has any, a Debug build lists `placeholders` of the harness's stand-ins.
    func levels(placeholders: Int = 0) -> [Level] {
        guard let pack else { return [] }
        #if DEBUG
        if pack.levels.isEmpty, placeholders > 0 { return (1...placeholders).map(pack.placeholder) }
        #endif
        return pack.levels
    }

    var gradient: LinearGradient { LinearGradient(colors: sweep, startPoint: .leading, endPoint: .trailing) }
}

extension Store {
    /// The bundle is owned once its own product or every pack it grants is.
    func state(_ offer: Offer) -> Purchase {
        switch offer {
        case .pack(let p): return state(p)
        case .complete:
            let l = harness ?? ledger
            if Pack.bundled.allSatisfy({ l.state($0) == .owned }) { return .owned }
            return l.products[Pack.completeID] ?? .unowned
        }
    }

    /// Its own product waits on Ask to Buy, so asking again re-sends that request.
    func asked(_ offer: Offer) -> Bool { (harness ?? ledger).asked(offer.productID) }

    /// The pack whose card a level shows instead of playing: one past its taste that the player doesn't own.
    func card(for level: Level) -> Pack? { access(level) == .needsCard ? level.pack : nil }

    /// A level this build may open: any outside a pack, and a pack's that the build sells.
    func opens(_ level: Level) -> Bool { access(level) != .withheld }
}

extension Store {
    /// A restore that finds nothing changes no state, so VoiceOver hears what it came to here.
    func restoreAndAnnounce() async {
        await restore()
        if let note = restoreNote { AccessibilityNotification.Announcement(note).post() }
    }

    /// What the last restore came to, on a card and in settings; nil before one.
    var restoreNote: String? {
        if restoring { return "restoring\u{2026}" }
        return switch restored {
        case .found(let packs): "restored \(Pack.named(Pack.sold().filter(packs.contains)))"
        case .nothing: "nothing to restore on this Apple ID"
        case .failed: "couldn't reach the App Store"
        case nil: nil
        }
    }
}

extension Failure {
    /// Said under the failed purchase; nil where "the purchase didn't go through" is all there is to say.
    var words: String? {
        switch self {
        case .offline: "No connection. Try again when you're online."
        case .storefront: "Not sold in your country's App Store."
        case .refused: "In-app purchases are turned off on this iPhone."
        case .cancelled, .other: nil
        }
    }
}

extension Pricing {
    /// In a price's place on the buy pill while there is none.
    var words: String? {
        switch self {
        case .fetching: "price loading"
        case .unreachable: "App Store unreachable"
        case .fetched: nil
        }
    }
}

extension Purchase {
    /// The dock's glyph beside a cover's name.
    var mark: String? {
        switch self {
        case .owned: "checkmark"
        case .pending: "hourglass"
        case .unowned, .failed, .revoked: nil
        }
    }

    /// The shelf's one word for a state, nil when there is nothing to say. `unshared`: revoked as a family's share
    /// ended, not a refund, as the card's status says it.
    func tag(unshared: Bool = false) -> (word: String, colour: Color)? {
        switch self {
        case .unowned: nil
        case .owned: ("owned", .lime)
        case .pending: ("waiting for approval", .amber)
        case .failed: ("purchase failed", .magenta)
        case .revoked: (unshared ? "no longer shared with you" : "no longer on this Apple ID", Color.text.opacity(0.6))
        }
    }
}

extension Font {
    /// The game's mono at a text style's size, so it follows Dynamic Type.
    static func mono(_ style: Font.TextStyle, _ weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced, weight: weight)
    }
}

/// What each pack's cover has shown: whether its card has opened since the pack fit the player, and how many levels it
/// had then, so the cover says "new" once for each (Jack's call C6, round 13).
enum Marks {
    /// False for a harnessed launch, whose cards' openings last only that launch.
    @MainActor static var stored = true

    static func fitKey(_ pack: Pack) -> String { "shelf.fit.\(pack.rawValue)" }
    static func levelsKey(_ pack: Pack) -> String { "shelf.levels.\(pack.rawValue)" }

    /// It fits and its card hasn't opened since, or an update added levels since it last opened.
    static func new(_ pack: Pack, fits: Bool, in defaults: UserDefaults = .standard) -> Bool {
        let seen = defaults.integer(forKey: levelsKey(pack))
        return (fits && !defaults.bool(forKey: fitKey(pack))) || (seen > 0 && pack.levels.count > seen)
    }

    /// Its card has opened.
    @MainActor static func seen(_ pack: Pack, fits: Bool, store: Bool = stored, in defaults: UserDefaults = .standard) {
        var marks: [String: Any] = [levelsKey(pack): pack.levels.count]
        if fits { marks[fitKey(pack)] = true }
        if store { for (key, value) in marks { defaults.set(value, forKey: key) } } else { defaults.register(defaults: marks) }
    }

    /// The line under a cover's name: "new", else how many of an unowned pack's free levels are solved, else nothing.
    static func line(_ pack: Pack, owned: Bool, fits: Bool, played: Int?) -> (words: String, spoken: String)? {
        if new(pack, fits: fits) { return ("new", "new") }
        guard !owned, let played else { return nil }
        return ("\(played)/\(pack.taste) free", "\(played) of \(pack.taste) free levels solved")
    }
}

// MARK: - Covers

extension Offer {
    /// The levels its cover stirs: its clip's, so the dock shows what the card plays; the bundle's, each pack it grants.
    var covers: [Level] { Clip.of(self).reels.map(\.level) }
}

/// An offer's cover in a tank: its clip's level on its own picture, as the game draws it, stirred by the level's own
/// dealt stack. `clock` nil holds it as dealt; otherwise the loop at that time: clean, stirred in bottom first, then
/// unstirred top first a move at a time. Complete's shows a wedge of each pack's, cut from the centre, the first
/// centred at the top, each on its own loop.
struct PackTank: View {
    let offer: Offer
    let side: CGFloat
    var clock: Double?

    static let period = 7.0

    var body: some View {
        let levels = offer.covers, span = 360 / Double(levels.count), start = -90 - span / 2, r = side / 2
        ZStack {
            ForEach(levels.indices, id: \.self) { k in
                tank(levels[k]).clipShape(Wedge(from: start + span * Double(k), to: start + span * Double(k + 1)))
            }
            if levels.count > 1 {
                Path { p in
                    for k in levels.indices {
                        let a = (start + span * Double(k)) * .pi / 180
                        p.move(to: CGPoint(x: r, y: r))
                        p.addLine(to: CGPoint(x: r + r * cos(a), y: r + r * sin(a)))
                    }
                }
                .stroke(Color.white.opacity(0.85), lineWidth: 0.5)
            }
        }
        .frame(width: side, height: side)
        .clipShape(Circle())
        .overlay { Bezel(r: r) }
        .accessibilityHidden(true)
    }

    private func tank(_ level: Level) -> some View {
        let dealt = Game.dealt(level)
        let wind = clock.map { Self.wind(dealt.count, at: $0) } ?? Array(repeating: 1, count: dealt.count)
        // The entries wound away are the identity, so they leave the shader's stack.
        let on = zip(dealt, wind).filter { $0.1 > 0 }
        var stir = Unstirred(stack: on.map(\.0.twist), layout: level.layout, lenses: level.lenses, masks: level.masks,
                             liveRod: nil, liveAngle: 0, side: side, fillEntries: level.picture.fillEntries)
        stir.shares = on.map(\.1)
        return LevelPicture(level: level, played: Reel.played(level, on.map(\.0)), wound: dealt.count - on.count, side: side)
            .modifier(stir)
    }

    /// Each entry's share of its turn, 0 clean to 1 stirred, `t` seconds into the clip.
    static func wind(_ m: Int, at t: Double) -> [Double] {
        let t = t.truncatingRemainder(dividingBy: period)
        func ease(_ x: Double) -> Double { let c = min(max(x, 0), 1); return c * c * (3 - 2 * c) }
        return (0..<m).map { k in
            let dIn = 1.2 / Double(m), dOut = 3.2 / Double(m)
            if t < 2.6 { return ease((t - 1.0 - Double(k) * dIn) / dIn) }
            return 1 - ease((t - 3.2 - Double(m - 1 - k) * dOut) / (0.8 * dOut))
        }
    }
}

/// A wedge from the centre between two angles in degrees, clockwise from three o'clock; the whole frame at 360.
private struct Wedge: Shape {
    let from: Double, to: Double

    func path(in rect: CGRect) -> Path {
        guard to - from < 360 else { return Path(rect) }
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        p.move(to: c)
        p.addArc(center: c, radius: rect.width, startAngle: .degrees(from), endAngle: .degrees(to), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// A tank whose clip runs on the clock, unless the harness holds it at `held` seconds. Reduce Motion holds it stirred.
struct LoopingTank: View {
    let offer: Offer
    let side: CGFloat
    var held: Double?
    var offset = 0.0
    /// The dock runs at a lower rate, and stops under the card.
    var interval = 0.0
    var paused = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if let held {
            PackTank(offer: offer, side: side, clock: held + offset)
        } else if reduceMotion {
            PackTank(offer: offer, side: side)
        } else {
            PausingTimeline(interval: interval > 0 ? interval : nil, paused: paused) { now in
                PackTank(offer: offer, side: side, clock: now + offset)
            }
        }
    }
}

/// The card's clip: the pack's own levels played live by the game (`Clip`), never a committed video.
struct PackClip: View {
    let offer: Offer
    let side: CGFloat
    var held: Double?
    @State private var seen = true

    var body: some View {
        ClipPlayer(clip: .of(offer), side: side, held: held, paused: !seen)
            .onGeometryChange(for: Bool.self) { Self.seen($0.size, in: $0.bounds(of: .scrollView)) } action: { seen = $0 }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(offer.name): \(offer.pitch). " + (offer.pack == nil ? "A level from each pack, played." : "A level played."))
            .accessibilityAddTraits(.isImage)
    }

    /// Whether any of a view `size` across lies inside its scroll view's `viewport`, in its own space; with no scroll
    /// view, it shows.
    nonisolated static func seen(_ size: CGSize, in viewport: CGRect?) -> Bool {
        viewport.map { $0.intersects(CGRect(origin: .zero, size: size)) } ?? true
    }
}

// MARK: - The card

/// A pack's card, or Complete's: its clip, what it assumes, the free taste, the App Store's price, buy and restore, and
/// the pack's levels once it has them.
struct PackCard: View {
    let offer: Offer
    /// The harness's clip time, else the clip runs.
    var clock: Double?
    /// The pack's own, unless the harness lists placeholders.
    var levels: [Level]
    /// UNSTIR_CARDSCROLL: opens scrolled to the list.
    var scrolled = false
    /// The row it opens centred on, the pack's level just left, or after a solve the one after it.
    var focus: Level?
    /// Opened by a level past the taste: it opens on buying, under a line that says the free levels are played.
    var arrived = false
    /// Where back goes: the menu, or Complete's card when this card was opened from it.
    var backTo = PackCard.menu
    let onBack: () -> Void
    let onPlay: (Level) -> Void
    /// Complete's card opens a pack's card from its name.
    var onOffer: (Offer) -> Void = { _ in }
    /// Beside the menu's list in a wide window, not over it, so VoiceOver reaches both.
    var beside = false
    var store = Store.shared
    @State private var buying = false
    /// The focused row's hairline, lit once as the card opens on it.
    @State private var lit = 0.0
    @State private var landings = 0
    @State private var pulses = 0
    /// Where VoiceOver goes when the card sends the player to buying.
    @AccessibilityFocusState private var spoken: Focus?
    private enum Focus: Hashable { case note, buy }
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The facts' key column, grown with the keys' own type size.
    @ScaledMetric(relativeTo: .caption2) private var keyWidth = 52.0

    var body: some View {
        let state = store.state(offer)
        // Back is pinned over the scroll, so the card's way out shows at every scroll position, the gate's landing on
        // buying too (Jack's call C1B = A, round 16).
        VStack(alignment: .leading, spacing: 0) {
            // Padded below by all of hit()'s reach, as the scroll, laid over it, would take the rest of its target.
            let back = Self.back(to: backTo, beside: beside)
            Button(action: onBack) { Text(back.text).font(.mono(.subheadline, .medium)).hit() }
                .buttonStyle(Sounding()).padding(.top, 18).padding(.bottom, 14).opacity(0.8)
                .padding(.horizontal, 24)
                .accessibilityLabel(back.spoken)
            GeometryReader { g in
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            Text((offer.pack == nil ? "BUNDLE" : "PACK") + (state == .owned ? "" : " \u{00B7} PAID ADD-ON"))
                                .font(.mono(.caption2, .semibold)).tracking(2).opacity(0.42)
                                .padding(.top, 12)
                            Text(offer.name).font(.system(.largeTitle, weight: .black).width(.expanded)).tracking(2)
                                .foregroundStyle(offer.gradient).shadow(color: offer.glow.opacity(0.55), radius: 10).padding(.top, 6)
                                .accessibilityAddTraits(.isHeader)
                            Text(offer.pitch).font(.mono(.footnote)).opacity(0.62).padding(.top, 4)
                            // Bounded by the height too, so buy is still on the first screen of the smallest phone.
                            PackClip(offer: offer, side: min(typeSize.isAccessibilitySize ? 200 : 320, g.size.width - 48,
                                                             g.size.height * 0.36), held: clock)
                                .frame(maxWidth: .infinity).padding(.top, 28)
                            // An owner's card is home, not a shop: no taste to offer, and the pack's progress for what it holds.
                            VStack(alignment: .leading, spacing: 9) {
                                fact("for", Text(offer.assumes))
                                if state != .owned { fact("free", Text(offer.free)) }
                                if state == .owned, offer.pack != nil, !levels.isEmpty {
                                    fact("done", Text("\(levels.filter { Best.load($0.id)?.over == 0 }.count)/\(levels.count) \(noPar ? "solved" : "at par")"))
                                } else {
                                    fact("holds", holds)
                                        .accessibilityActions {
                                            // The names' links, which a combined element may not offer VoiceOver.
                                            if offer.pack == nil {
                                                ForEach(Pack.bundled, id: \.self) { pack in
                                                    Button("Open \(pack.name)") { onOffer(.pack(pack)) }
                                                }
                                            }
                                        }
                                }
                                if offer.pack == nil, state != .owned, let saving = store.saving {
                                    fact("save", Text("\(saving) on the packs you don't have"))
                                }
                            }
                            .padding(.top, 32)
                            if let note = offer.note { detail(note).padding(.top, 12) }
                            if offer.arriving {
                                Text("More levels arrive in an update.").font(.mono(.caption)).opacity(0.62).padding(.top, 12)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            // Buying comes before the list, so it is on the first screen whatever the pack holds.
                            if levels.isEmpty { Spacer(minLength: 24) }
                            VStack(alignment: .leading, spacing: 0) {
                                if arrived, let note = Self.arrival(offer, levels, state: state) {
                                    Text(note).font(.mono(.footnote)).opacity(0.85).padding(.bottom, 14)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityFocused($spoken, equals: .note)
                                }
                                status(state).id(state)
                                    .transition(reduceMotion ? .identity : .move(edge: .leading).combined(with: .opacity))
                                action(state).padding(.top, 14)
                            }
                            // Half inside the anchor, so a scroll to it leaves a margin above the note.
                            .padding(.top, levels.isEmpty ? 0 : 16)
                            .id("buy")
                            .padding(.top, levels.isEmpty ? 0 : 16)
                            if offer.pack != nil, state != .owned, store.canPay, let saving = store.saving,
                               Offer.shelf().contains(.complete) {
                                completeLine(saving).padding(.top, 14)
                            }
                            if Pack.sold().contains(where: { store.state($0) != .owned }) {
                                restore.padding(.top, 18).padding(.bottom, 10)
                            }
                            if !levels.isEmpty { list(reader).padding(.top, 26).padding(.bottom, 10).id("list") }
                        }
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity, minHeight: g.size.height, alignment: .topLeading)
                        .animation(reduceMotion ? nil : .snappy(duration: 0.45), value: state)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    // Scrolled words fade out under the pinned back instead of meeting it at a hard edge, and run on
                    // under the home indicator.
                    .mask {
                        VStack(spacing: 0) {
                            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 12)
                            Color.black
                        }
                        .padding(.bottom, -g.safeAreaInsets.bottom - 40)
                    }
                    .onAppear {
                        // The gate's arrival opens on buying, else UNSTIR_CARDSCROLL on the list, else on the row left.
                        if arrived {
                            reader.scrollTo("buy", anchor: .top)
                        } else if scrolled {
                            reader.scrollTo("list", anchor: .top)
                        } else if let focus, levels.contains(where: { $0.id == focus.id }) {
                            DispatchQueue.main.async { reader.scrollTo(focus.id, anchor: .center) }
                            if !reduceMotion {
                                lit = 1
                                withAnimation(.easeOut(duration: 1.4).delay(0.35)) { lit = 0 }
                            }
                        }
                    }
                    .task {
                        // VoiceOver lands on a new screen's first element, back, after it appears; the wait lets that land
                        // first.
                        guard arrived else { return }
                        try? await Task.sleep(for: .milliseconds(600))
                        spoken = Self.arrival(offer, levels, state: store.state(offer)) == nil ? .buy : .note
                    }
                }
            }
        }
        .foregroundStyle(Color.text)
        .background(Color.black.ignoresSafeArea())
        .accessibilityAddTraits(beside ? [] : .isModal)
        .accessibilityAction(.escape, onBack)
        .task { await store.fetchPrices() }
        // A promoted purchase buys as the card's buy does, once the launch knows what the player owns.
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
        }
        .onChange(of: Reading(state: state, ready: store.ready)) { old, new in
            // Until the launch's first read has finished, an owned pack reads as unowned: that read is no change.
            guard old.ready, new.state != old.state else { return }
            if let tag = new.state.tag(unshared: unshared) { AccessibilityNotification.Announcement("\(offer.name) \(tag.word)").post() }
            // A purchase, an approval or a restore landing here: the solve's chime, and the locks dissolve in turn.
            if Self.lands(old.state, new.state, ready: old.ready) {
                landings += 1
                store.landed = true
                Sound.shared.play(.solve)
                // An approved Ask to Buy landing here is said by the landing, not the dock.
                store.said(offer)
            }
        }
        .haptic(.success, trigger: landings)
    }

    static let menu = "menu"

    /// The way out's words and VoiceOver's. Beside the list the menu is already in sight, so going back to it closes
    /// the card (Jack's call d4-menuback = B, round 16); back to Complete's card reads as ever.
    static func back(to: String, beside: Bool) -> (text: String, spoken: String) {
        beside && to == menu ? ("\u{2715} close", "Close") : ("\u{2039} \(to)", "Back")
    }

    private struct Reading: Equatable {
        let state: Purchase
        let ready: Bool
    }

    /// A purchase landing on the card: owned now, read after the launch's first read of the entitlements had finished,
    /// so an owner's card opened in that read's window never chimes.
    static func lands(_ old: Purchase, _ new: Purchase, ready: Bool) -> Bool { ready && old != .owned && new == .owned }

    private var price: String? { store.price(offer.productID) }

    /// The bundle's names each pack, each opening that pack's card, so its taste is a tap away.
    private var holds: Text {
        guard offer.pack == nil else { return Text(offer.holds) }
        let sold = Pack.bundled
        var s = AttributedString()
        for (i, pack) in sold.enumerated() {
            if i > 0 { s += AttributedString(i == sold.count - 1 ? " and " : ", ") }
            var name = AttributedString(pack.name)
            name.link = URL(string: "unstir-pack:\(pack.rawValue)")
            name.underlineStyle = Text.LineStyle(pattern: .dot)
            s += name
        }
        s += AttributedString(" \u{00B7} \(sold.map(\.planned).reduce(0, +)) levels")
        return Text(s)
    }

    @ViewBuilder private func fact(_ key: String, _ value: Text) -> some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 0))
        layout {
            Text(key).font(.mono(.caption2)).opacity(0.38)
                .frame(width: typeSize.isAccessibilitySize ? nil : keyWidth, alignment: .leading)
            value.font(.mono(.footnote)).opacity(0.85).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .tint(Color.text)
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == "unstir-pack", let pack = Pack(rawValue: url.absoluteString.replacingOccurrences(of: "unstir-pack:", with: "")) else {
                return .discarded
            }
            onOffer(.pack(pack))
            return .handled
        })
    }

    /// Every level, those past the taste locked until the pack is owned, under a heading for each chapter where the
    /// pack has chapters, as the menu heads each tier.
    private func list(_ reader: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if levels.first?.chapter == nil { heading("levels", of: []) }
            ForEach(Array(levels.enumerated()), id: \.element.id) { i, level in
                if let chapter = level.chapter, i == 0 || levels[i - 1].chapter != chapter {
                    heading(chapter, of: levels.filter { $0.chapter == chapter }).padding(.top, i == 0 ? 0 : 18)
                }
                let open = store.access(level) != .needsCard, best = Best.load(level.id)
                let tried = best == nil && Best.started(level.id)
                // A locked row points at buying rather than doing nothing.
                Button {
                    if open { return onPlay(level) }
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { reader.scrollTo("buy", anchor: .top) }
                    pulses += 1
                    spoken = .buy
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(level.label).font(.mono(.footnote, .semibold)).foregroundStyle(offer.glow)
                            .opacity(open ? 1 : 0.5).frame(minWidth: 30, alignment: .leading)
                        Text(level.title).font(.mono(.subheadline)).multilineTextAlignment(.leading)
                            .opacity(open ? 1 : 0.38)
                        Spacer(minLength: 8)
                        if !open {
                            Image(systemName: "lock.fill").font(.caption2).opacity(0.4)
                                .transition(.opacity.combined(with: .scale(scale: 1.8)))
                        } else if let best {
                            Text(best.over == 0 ? atPar : "+\(best.over)").font(.mono(.caption2))
                                .foregroundStyle(best.over == 0 ? Color.amber : Color.magenta)
                        } else if tried {
                            Text("tried").font(.mono(.caption2)).opacity(0.4)
                        }
                    }
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.3 + 0.05 * Double(max(0, i - (offer.pack?.taste ?? 0)))),
                               value: open)
                }
                .buttonStyle(Sounding())
                .rowHairline(offer.glow, level.id == focus?.id ? lit : 0, inset: 10)
                .accessibilityValue(open ? best.map { $0.over == 0 ? (noPar ? "solved" : "at par") : "\($0.over) over par" }
                                        ?? (tried ? "tried" : "") : "locked, needs the pack")
                .accessibilityHint(open ? "" : "Shows where to buy \(offer.name)")
            }
        }
    }

    /// Escapement has no par (Jack's call EL1, round 11): its best is a solve, which spends the budget to the last tick.
    private var noPar: Bool { offer.pack == .escapement }
    private var atPar: String { noPar ? "solved" : "par" }

    /// A chapter's name and rule, with how many of its levels are at par, or solved.
    private func heading(_ name: String, of chapter: [Level]) -> some View {
        HStack(spacing: 10) {
            Text(name.lowercased()).font(.mono(.caption2, .semibold)).foregroundStyle(offer.gradient)
            Rectangle().fill(offer.gradient).frame(height: 1).opacity(0.8)
            if !chapter.isEmpty {
                Text("\(chapter.filter { Best.load($0.id)?.over == 0 }.count)/\(chapter.count) \(noPar ? "solved" : "at par")")
                    .font(.mono(.caption2))
                    .opacity(0.4)
            }
        }
        .padding(.bottom, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder private func status(_ state: Purchase) -> some View {
        switch state {
        case .unowned: EmptyView()
        case .owned:
            line(offer.pack == nil ? "\u{2713} owned \u{00B7} all \(Offer.countWord(Pack.bundled.count)) packs open" : "\u{2713} owned \u{00B7} every level open", .lime)
        case .pending:
            // A pack can wait on Complete's request alone, which only Complete's card asks again.
            let asked = store.asked(offer)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    PulsingDot(colour: .amber)
                    Text(asked ? "waiting for approval" : "\(Offer.bundleName) is waiting for approval")
                        .font(.mono(.footnote, .semibold)).foregroundStyle(Color.amber)
                }
                // Asking again failed, and the first request is still with the parent: the failure stands in for
                // Ask to Buy's explanation, so buy stays on the first screen of the smallest phone.
                if let why = store.failures[offer.productID]?.words {
                    detail(why)
                } else {
                    Text(asked ? "Ask to Buy: the pack opens here once it's approved \u{00B7} tap asked to send it again."
                         : "Ask to Buy: \(offer.name) opens here once \(Offer.bundleName) is approved.")
                        .font(.mono(.caption2)).opacity(0.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
        case .failed:
            VStack(alignment: .leading, spacing: 4) {
                line("the purchase didn't go through", .magenta)
                if let why = store.failures[offer.productID]?.words { detail(why) }
            }
            .accessibilityElement(children: .combine)
        case .revoked:
            // A refund or a family's share ended: said plainly, never as an alarm.
            line((unshared ? "\(offer.name) is no longer shared with you" : "\(offer.name) isn't on this Apple ID any more")
                 + " \u{00B7} your progress is kept", Color.text.opacity(0.6), glow: false)
        }
    }

    private func detail(_ s: String) -> some View {
        Text(s).font(.mono(.caption2)).opacity(0.5).fixedSize(horizontal: false, vertical: true)
    }

    private var unshared: Bool { offer.pack.map(store.unshared) ?? false }

    private func line(_ s: String, _ colour: Color, glow: Bool = true) -> some View {
        Text(s).font(.mono(.footnote, .semibold)).foregroundStyle(colour).shadow(color: colour.opacity(glow ? 0.6 : 0), radius: 4)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Owned, play; otherwise buy at the App Store's price, and the taste beside it.
    @ViewBuilder private func action(_ state: Purchase) -> some View {
        if state == .owned {
            // The bundle has no levels of its own: its owner goes on in the first pack with a level left to play.
            let pack = offer.pack == nil ? Pack.bundled.first(where: { Self.pickUp($0.levels) != nil }) : nil
            if let level = pack.flatMap({ Self.pickUp($0.levels) }) ?? next {
                let verb = Self.continues(pack?.levels ?? levels) ? "continue" : "play"
                let name = pack.map { $0.name + " " } ?? ""
                pill("\(verb) \(name)\(level.label) \u{203A}", trailing: nil, colour: .lime) { onPlay(level) }
                    .accessibilityLabel("\(verb.capitalized) \(pack?.name ?? offer.name), level \(level.label)")
            }
        } else {
            // A declined Ask to Buy sends no transaction, so an asked pill stays live: tapping it sends a new request.
            // A pack waiting only on Complete's request is bought alone.
            let asked = store.asked(offer)
            let label = switch state {
            case _ where buying: "buying\u{2026}"
            case .failed: "try again"
            case .revoked: unshared ? "buy" : "buy again"
            case .pending where asked: "asked"
            default: "buy"
            }
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                : AnyLayout(HStackLayout(spacing: 14))
            if !store.canPay { detail(Failure.refused.words ?? "").padding(.bottom, 12) }
            layout {
                if store.canPay {
                    pill(label, trailing: price ?? (unreachable ? nil : store.pricing.words), colour: offer.glow,
                         dim: price == nil) { buy(offer) }
                        .disabled(buying)
                        .keyframeAnimator(initialValue: 1.0, trigger: pulses) { pill, scale in
                            pill.scaleEffect(reduceMotion ? 1 : scale)
                        } keyframes: { _ in
                            // Held while the list scrolls up to it.
                            LinearKeyframe(1.0, duration: 0.35)
                            CubicKeyframe(1.08, duration: 0.14)
                            CubicKeyframe(1.0, duration: 0.3)
                        }
                        .accessibilityLabel(state == .pending && asked && !buying ? "Ask again for \(offer.name)"
                                            : "\(label.capitalized) \(offer.name)")
                        .accessibilityValue(price ?? store.pricing.words ?? "")
                        .accessibilityFocused($spoken, equals: .buy)
                }
                if let taste = Self.taste(levels) ?? Self.placeholder(offer).map({ (level: $0, replay: false) }) {
                    let (level, replay) = taste
                    let n = offer.pack?.taste ?? 3
                    Button { onPlay(level) } label: {
                        Text(replay ? "replay 01\u{2013}\(String(format: "%02d", n)) \u{203A}" : "try \(n) free \u{203A}")
                            .font(.mono(replay ? .caption : .footnote)).opacity(replay ? 0.5 : 0.7)
                    }
                    .buttonStyle(Sounding())
                    .accessibilityLabel(replay ? "Replay the \(n) free levels" : "Try the first \(n) levels free")
                }
            }
            // Under the pill, as a failure is said, since it wraps inside the pill on the smallest phone.
            if unreachable { detail(store.pricing.words ?? "").padding(.top, 10).accessibilityHidden(true) }
        }
    }

    private var unreachable: Bool { store.canPay && price == nil && store.pricing == .unreachable }

    private var next: Level? { levels.isEmpty ? Self.placeholder(offer) : Self.pickUp(levels) }

    /// Where an owner picks up: the first level without a best, then the first not at par; none once all are at par.
    static func pickUp(_ levels: [Level], best: (String) -> Best? = Best.load) -> Level? {
        levels.first { best($0.id) == nil } ?? levels.first { best($0.id)?.over != 0 }
    }

    /// The taste's first level without a best, or, once all have one, its first to replay.
    static func taste(_ levels: [Level], best: (String) -> Best? = Best.load) -> (level: Level, replay: Bool)? {
        let free = levels.prefix(levels.first?.pack?.taste ?? 0)
        if let level = free.first(where: { best($0.id) == nil }) { return (level, false) }
        return free.first.map { ($0, true) }
    }

    /// Over buying, when a level past the taste opened the card of a pack never owned: that the free levels are
    /// played, once every one has a best, else, for a player who skipped ahead (a row opens any free level), that they
    /// are free (Jack's call C1A = B, round 16). A refunded owner has the revocation's line instead.
    static func arrival(_ offer: Offer, _ levels: [Level], state: Purchase,
                        best: (String) -> Best? = Best.load) -> String? {
        guard let pack = offer.pack, levels.count > pack.taste, state != .owned, state != .revoked else { return nil }
        let free = Offer.countWord(pack.taste), more = "\(levels.count - pack.taste) more in \(pack.name)."
        return taste(levels, best: best)?.replay == true ? "You've played the free \(free). \(more)"
            : "The first \(free) are free. \(more)"
    }

    /// Play, until a level past the taste has been solved: then the owner continues.
    static func continues(_ levels: [Level], best: (String) -> Best? = Best.load) -> Bool {
        levels.contains { level in
            best(level.id) != nil && (level.pack.flatMap { $0.number(of: level.id) } ?? 0) > (level.pack?.taste ?? 0)
        }
    }

    /// Before a pack has levels, a Debug build plays its harness placeholder.
    private static func placeholder(_ offer: Offer) -> Level? {
        #if DEBUG
        offer.pack?.placeholder(1)
        #else
        nil
        #endif
    }

    private func pill(_ title: String, trailing: String?, colour: Color, dim: Bool = false,
                      _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack(spacing: 14) {
                Text(title).font(.mono(.subheadline, .semibold))
                if let trailing { Text(trailing).font(.mono(dim ? .caption : .subheadline)).opacity(dim ? 0.45 : 0.75) }
            }
            .padding(.horizontal, 22).padding(.vertical, 12).frame(minHeight: 46)
            .overlay { Capsule().strokeBorder(colour, lineWidth: 1).shadow(color: colour, radius: 5) }
            .contentShape(Capsule())
        }
        .buttonStyle(Sounding())
    }

    /// Complete's failure stays off the pack's own status, so it is said here, beside the button that tried.
    private func completeLine(_ saving: String) -> some View {
        let complete = store.price(Pack.completeID) ?? ""
        let quiet = Color.text.opacity(0.55)
        // Non-breaking within each part, so a narrow phone or a large size wraps the line only before "· save".
        func joined(_ s: String) -> String { s.replacingOccurrences(of: " ", with: "\u{00A0}") }
        return VStack(alignment: .leading, spacing: 6) {
            Button { buy(.complete) } label: {
                let all = Text("or all \(Offer.countWord(Pack.bundled.count)) in \(Offer.bundleName)\u{00A0}\u{00B7}\u{00A0}").foregroundStyle(quiet)
                let save = Text(joined("\u{00B7} save \(saving) \u{203A}")).foregroundStyle(quiet)
                Text("\(all)\(Text(joined(complete)).foregroundStyle(Color.text.opacity(0.75))) \(save)")
                .font(.mono(.caption))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                // Its failure line is 6 pt below.
                .hit(10, 8)
            }
            .buttonStyle(Sounding())
            // Complete's own request is asked again only from Complete's card.
            .disabled(buying || store.state(.complete) == .pending)
            .accessibilityLabel("Buy \(Offer.bundleName), \(Pack.named(Pack.bundled))")
            .accessibilityValue("\(complete), saves \(saving)")
            if store.state(.complete) == .failed {
                Text("\(Offer.bundleName)'s purchase didn't go through").font(.mono(.caption, .semibold)).foregroundStyle(Color.magenta)
                    .fixedSize(horizontal: false, vertical: true)
                if let why = store.failures[Pack.completeID]?.words { detail(why) }
            }
        }
    }

    private var restore: some View {
        Button { Task { await store.restoreAndAnnounce() } } label: {
            let words = restoreWords
            Text(store.restoring ? store.restoreNote ?? words : store.restoreNote.map { "\($0) \u{00B7} \(words)" } ?? words)
                .font(.mono(.caption2)).opacity(0.4).underline(pattern: .dot)
                .fixedSize(horizontal: false, vertical: true).hit(16)
        }
        .buttonStyle(Sounding())
        .disabled(store.restoring)
    }

    private var restoreWords: String { ConsentWords.restore }

    private func buy(_ o: Offer) {
        buying = true
        Task {
            await store.purchase(o.productID)
            buying = false
        }
    }
}

private struct PulsingDot: View {
    let colour: Color
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Circle().fill(colour).frame(width: 7, height: 7).shadow(color: colour, radius: on ? 6 : 2).opacity(on ? 1 : 0.45)
            .onAppear {
                if reduceMotion { on = true } else { withAnimation(.easeInOut(duration: 0.9).repeatForever()) { on = true } }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - The dock

/// The menu's shelf: a live cover per pack and Complete along the bottom, each opening its card. Out of step, so the
/// dock never stirs all at once. Equatable on what it is handed, since the menu redraws on every frame of a scroll and
/// each cover's marks read the saved bests.
struct PackDock: View, Equatable {
    /// The dock waits for plughole 09 (Jack's call C5, round 13). A pack owned or asked for keeps it after a reinstall
    /// that lost the bests.
    static func shown(best: (String) -> Best? = Best.load, unlocked: Bool = Best.unlocked,
                      state: (Pack) -> Purchase = { Store.shared.state($0) }) -> Bool {
        best(Level.plughole[8].id) != nil || unlocked || Pack.sold().contains { ![.unowned, .failed].contains(state($0)) }
    }

    let open: (Offer, UnitPoint) -> Void
    let held: Double?
    /// The card covers it.
    let paused: Bool
    /// A card or the settings sheet is over it, so an approval waits to be said until it shows.
    let covered: Bool
    var store = Store.shared
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Approvals already announced: a card or the settings covering the dock restarts the header's time, not its
    /// announcement.
    @State private var announced: Set<Offer> = []
    /// The covers' row, inside its padding.
    @State private var row: CGFloat = 0

    /// Caption2 at the dock's size, capped at xxxLarge as the dock is, down to the largest at which every word of every
    /// name, with its cover's glyph, fits its cover.
    private func nameSize(_ shelf: [Offer]) -> CGFloat {
        let category = UIContentSizeCategory(min(typeSize, .xxxLarge))
        let size = UIFontMetrics(forTextStyle: .caption2).scaledValue(for: 11, compatibleWith:
            UITraitCollection(preferredContentSizeCategory: category))
        guard row > 0, !shelf.isEmpty else { return size }
        let cover = row / CGFloat(shelf.count)
        let names = shelf.map { ($0.name, store.ready && store.state($0).mark != nil) }
        return size * Self.nameScale(names, cover: cover, width: { word in
            (word as NSString).size(withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: size, weight: .regular)]).width
        })
    }

    /// The one scale the row's names share: the smallest any word needs to fit its cover beside its glyph (12 pt),
    /// never below half.
    nonisolated static func nameScale(_ names: [(name: String, marked: Bool)], cover: CGFloat,
                                      width: (String) -> CGFloat) -> CGFloat {
        let fits = names.flatMap { name, marked in
            name.split(separator: " ").map { (cover - (marked ? 12 : 0)) / max(1, width(String($0))) }
        }
        return min(1, max(0.5, (fits.min() ?? 1) * 0.97))
    }

    nonisolated static func == (a: PackDock, b: PackDock) -> Bool {
        a.held == b.held && a.paused == b.paused && a.covered == b.covered
    }

    var body: some View {
        VStack(spacing: 10) {
            let owned = Pack.sold().filter { store.state($0) == .owned }
            // Complete only while it costs less than the packs left: owned, it saves nothing.
            let shelf = Offer.shelf().filter { $0 != .complete || store.offersComplete }
            HStack {
                if let yours = store.approved.first {
                    Text(yours.yours).font(.mono(.caption2, .semibold)).tracking(1).foregroundStyle(yours.glow)
                        .shadow(color: yours.glow.opacity(0.6), radius: 4).transition(.opacity)
                } else {
                    Text(owned.isEmpty ? "PACKS \u{00B7} PAID ADD-ONS" : "PACKS").font(.mono(.caption2, .semibold)).tracking(2)
                        .opacity(0.38).transition(.opacity)
                }
                Spacer()
                if typeSize < .xxLarge, owned.count < Pack.sold().count {
                    Text("first 3 levels of each free").font(.mono(.caption2)).opacity(0.3)
                }
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .animation(.easeInOut(duration: 0.4), value: store.approved.first)
            .task(id: Saying(offer: Self.saying(store.approved.first, covered: covered, shelved: store.shelved),
                             covered: covered || !store.shelved)) {
                // Held under UNSTIR_CLOCK, for its shot.
                guard let offer = Self.saying(store.approved.first, covered: covered, shelved: store.shelved) else { return }
                if announced.insert(offer).inserted { AccessibilityNotification.Announcement(offer.yours).post() }
                // Five seconds in sight: covered, it waits.
                guard held == nil else { return }
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                store.said(offer)
            }
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(shelf.enumerated()), id: \.element) { i, offer in
                    let x = (Double(i) + 0.5) / Double(shelf.count), state = store.state(offer)
                    // Unowned until the launch's first read has finished, so a pack's free levels wait for it.
                    let line = offer.pack.flatMap { Marks.line($0, owned: state == .owned || !store.ready, fits: $0.fits(),
                                                                played: $0.tastePlayed()) }
                    Button { open(offer, UnitPoint(x: x, y: 0.88)) } label: {
                        VStack(spacing: 8) {
                            LoopingTank(offer: offer, side: 66, held: held, offset: 1.75 * Double(i), interval: 1.0 / 30,
                                        paused: paused)
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                // A name breaks only between its words, each on a line of its own, at the row's
                                // one size, which shrinks until every word fits its cover rather than hyphenate.
                                ViewThatFits(in: .horizontal) {
                                    Text(offer.name).lineLimit(1)
                                    Text(offer.name.replacingOccurrences(of: " ", with: "\n"))
                                        .lineLimit(offer.name.split(separator: " ").count)
                                }
                                .font(.system(size: nameSize(shelf), design: .monospaced))
                                .opacity(0.7).multilineTextAlignment(.center)
                                // A glyph, so the state reads without its colour; a revocation is the card's to say.
                                if store.ready, let mark = state.mark {
                                    Image(systemName: mark).font(.system(size: 8, weight: .bold)).foregroundStyle(state.tag()?.colour ?? .text)
                                        .shadow(color: state.tag()?.colour ?? .clear, radius: 2)
                                        .accessibilityHidden(true)
                                }
                            }
                            // Its room kept without one, so a mark clearing never moves the dock.
                            let new = line?.words == "new"
                            Text(line?.words ?? " ").font(.mono(.caption2, new ? .semibold : .regular))
                                .foregroundStyle(new ? offer.glow : Color.text.opacity(0.45))
                                .shadow(color: new ? offer.glow.opacity(0.6) : .clear, radius: 3)
                                .padding(.top, -4)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(Sounding())
                    .accessibilityLabel("\(offer.name), \(offer.pack == nil ? Pack.named(Pack.bundled) : "pack")")
                    .accessibilityValue([(store.ready ? state.tag(unshared: offer.pack.map(store.unshared) ?? false)?.word : nil)
                                         ?? store.price(offer.productID), line?.spoken].compactMap { $0 }.joined(separator: ", "))
                    .accessibilityHint(offer.pitch)
                    .accessibilityShowsLargeContentViewer {
                        Text(offer.name)
                    }
                    .transition(.opacity)
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: shelf)
            .padding(.horizontal, 8)
            .onGeometryChange(for: CGFloat.self) { $0.size.width - 16 } action: { row = $0 }
        }
        // Unseen until the launch's read of what is owned and its price fetch have settled (`Store.shelved`), then a new
        // dock fading in whole, so neither the header nor the bundle's cover changes in sight as they land, unless a fetch outlasts the wait. Laid
        // out meanwhile from what is known so far, at first nothing owned and no prices, most players' settled dock,
        // so its height rarely moves.
        .opacity(store.shelved ? 1 : 0)
        .id(store.shelved)
        .transition(.opacity)
        .animation(reduceMotion ? nil : .easeIn(duration: 0.25), value: store.shelved)
        // A bar, like a tab bar: its names stop growing where four no longer fit, and a long press shows one large.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .background {
            // Opaque under the label, so the list scrolls away behind a short fade above it.
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 28)
                Color.black
            }
            .padding(.top, -28)
            .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle().fill(Offer.complete.gradient).frame(height: 0.5).opacity(0.45).padding(.horizontal, 20)
        }
    }

    /// The approval the header says now: none while a card or the settings covers the dock, or before it shows.
    static func saying(_ approved: Offer?, covered: Bool, shelved: Bool) -> Offer? {
        covered || !shelved ? nil : approved
    }

    private struct Saying: Equatable {
        let offer: Offer?
        let covered: Bool
    }
}
