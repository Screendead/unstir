// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

// MARK: - The card

/// A pack's card, or Triptych I's: its clip, what it assumes, the free taste, the App Store's price, buy and restore, and
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
    /// Where back goes: the menu, or Triptych I's card when this card was opened from it.
    var backTo = Shop.menu
    let onBack: () -> Void
    let onPlay: (Level) -> Void
    /// Triptych I's card opens a pack's card from its name.
    var onOffer: (Offer) -> Void = { _ in }
    /// Beside the menu's list in a wide window, not over it, so VoiceOver reaches both.
    var beside = false
    /// Its way out closes it rather than going to the menu, which isn't under it: over a playing level's result card
    /// beside the menu (Jack's call s5b-back = B).
    var closes = false
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
    @ScaledMetric(relativeTo: .footnote) private var keyWidth = 56.0

    var body: some View {
        let state = store.state(offer)
        // Back is pinned over the scroll, so the card's way out shows at every scroll position, the gate's landing on
        // buying too (Jack's call C1B = A, round 16).
        VStack(alignment: .leading, spacing: 0) {
            // Padded below by all of hit()'s reach, as the scroll, laid over it, would take the rest of its target.
            let back = Shop.back(to: backTo, beside: beside || closes)
            UnstirButton(.quiet, action: onBack) { Text(back.text).font(.ui(.button)) } // loc: verbatim localized by back
                .padding(.top, 18).padding(.bottom, 14)
                .padding(.horizontal, 24)
                .accessibilityLabel(back.spoken) // loc: verbatim localized by back
            GeometryReader { g in
                ScrollViewReader { reader in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            (offer.pack == nil
                                ? state == .owned ? Text("BUNDLE", comment: "The bundle's card, over its name, owned")
                                    : Text("BUNDLE \u{00B7} PAID ADD-ON", comment: "The bundle's card, over its name")
                                : state == .owned ? Text("PACK", comment: "A pack's card, over its name, owned")
                                    : Text("PACK \u{00B7} PAID ADD-ON", comment: "A pack's card, over its name"))
                                .font(.ui(.eyebrow)).tracking(2).foregroundStyle(Color.text3)
                                .padding(.top, 12)
                            Text(verbatim: offer.name).font(.ui(.display)).tracking(2)
                                .foregroundStyle(offer.gradient).shadow(color: offer.glow.opacity(0.55), radius: 10).padding(.top, 6)
                                .accessibilityAddTraits(.isHeader)
                            if let pitch = offer.pitch {
                                Text(pitch).font(.ui(.label)).foregroundStyle(Color.text2).padding(.top, 4) // loc: verbatim localized by Offer
                            }
                            // Bounded by the height too, so buy is still on the first screen of the smallest phone.
                            PackClip(offer: offer, side: min(typeSize.isAccessibilitySize ? 200 : 320, g.size.width - 48,
                                                             g.size.height * 0.36), held: clock)
                                .frame(maxWidth: .infinity).padding(.top, 28)
                            // An owner's card is home, not a shop: no taste to offer, and the pack's progress for what it holds.
                            VStack(alignment: .leading, spacing: 9) {
                                if let assumes = offer.assumes {
                                    fact(String(localized: "for", comment: "A pack's card: the key beside who it is for"),
                                         Text(assumes)) // loc: verbatim localized by Offer
                                }
                                if state != .owned {
                                    fact(String(localized: "free", comment: "A pack's card: the key beside its free levels"),
                                         Text(offer.free)) // loc: verbatim localized by Offer
                                }
                                if state == .owned, offer.pack != nil, !levels.isEmpty {
                                    let par = levels.filter { Best.load($0.id)?.over == 0 }.count
                                    fact(String(localized: "done", comment: "An owned pack's card: the key beside its progress"),
                                         noPar ? Text("\(par)/\(levels.count) solved", comment: "Escapement's progress. Levels solved, of all")
                                             : Text("\(par)/\(levels.count) at par", comment: "A pack's progress. Levels at par, of all"))
                                } else {
                                    fact(String(localized: "holds", comment: "A pack's card: the key beside what it holds"), holds)
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
                                    fact(String(localized: "save", comment: "The bundle's card: the key beside what it saves"),
                                         Text("\(saving) on the packs you don't have", comment: "The bundle's saving. A price"))
                                }
                            }
                            .padding(.top, 32)
                            if let note = offer.note { detail(note).padding(.top, 12) }
                            if offer.arriving {
                                Text("More levels arrive in an update.").font(.ui(.detail)).foregroundStyle(Color.text3).padding(.top, 12)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            // Buying comes before the list, so it is on the first screen whatever the pack holds.
                            if levels.isEmpty { Spacer(minLength: 24) }
                            VStack(alignment: .leading, spacing: 0) {
                                if arrived, let note = Shop.arrival(offer, levels, state: state) {
                                    Text(note).font(.ui(.label)).foregroundStyle(Color.text2).padding(.bottom, 14) // loc: verbatim localized by arrival
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityFocused($spoken, equals: .note)
                                }
                                // Before the launch's first read, an owner's card would offer buy: a promoted
                                // purchase at a cold launch can open it then.
                                if store.ready {
                                    status(state).id(state)
                                        .transition(reduceMotion ? .identity : .move(edge: .leading).combined(with: .opacity))
                                    action(state).padding(.top, 14)
                                } else {
                                    HStack(spacing: 8) {
                                        PulsingDot(colour: .text)
                                        Text("checking purchases\u{2026}").font(.ui(.headline)).foregroundStyle(Color.text2)
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                            }
                            // Half inside the anchor, so a scroll to it leaves a margin above the note.
                            .padding(.top, levels.isEmpty ? 0 : 16)
                            .id("buy")
                            .padding(.top, levels.isEmpty ? 0 : 16)
                            if store.ready, offer.pack != nil, state != .owned, store.canPay, let saving = store.saving,
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
                        spoken = Shop.arrival(offer, levels, state: store.state(offer)) == nil ? .buy : .note
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
        .onChange(of: Reading(state: state, ready: store.firstReadDone)) { old, new in
            // Until the launch's first read has finished, an owned pack reads as unowned: that read is no change, even
            // when it lands past `Store.readLimit`.
            guard old.ready, new.state != old.state else { return }
            if let tag = new.state.tag(unshared: unshared) { AccessibilityNotification.Announcement("\(offer.name) \(tag.word)").post() } // loc: verbatim a name, then a word localized by Purchase
            // A purchase, an approval or a restore landing here: the solve's chime, and the locks dissolve in turn.
            if Shop.lands(old.state, new.state, ready: old.ready) {
                landings += 1
                store.landed = true
                Sound.shared.play(.solve)
                // An approved Ask to Buy landing here is said by the landing, not the dock.
                store.said(offer)
            }
        }
        .haptic(.success, trigger: landings)
    }

    private struct Reading: Equatable {
        let state: Purchase
        let ready: Bool
    }

    private var price: String? { store.price(offer.productID) }

    /// The bundle's names each pack, each opening that pack's card, so its taste is a tap away.
    private var holds: Text {
        guard offer.pack == nil else { return Text(offer.holds) } // loc: verbatim localized by Offer
        // Pack names never translate, so each is found in the localized line.
        var s = AttributedString(offer.holds)
        for pack in Pack.bundled {
            guard let name = s.range(of: pack.name) else { continue }
            s[name].link = URL(string: "unstir-pack:\(pack.rawValue)")
            s[name].underlineStyle = Text.LineStyle(pattern: .dot)
        }
        return Text(s) // loc: verbatim localized by Offer
    }

    @ViewBuilder private func fact(_ key: String, _ value: Text) -> some View {
        let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 0))
        layout {
            Text(key).font(.ui(.detail)).foregroundStyle(Color.text3) // loc: verbatim localized by the caller
                .frame(width: typeSize.isAccessibilitySize ? nil : keyWidth, alignment: .leading)
            value.font(.ui(.label)).fixedSize(horizontal: false, vertical: true)
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
            if levels.first?.chapter == nil {
                heading(String(localized: "levels", comment: "A pack's card: its list's heading, where it has no chapters"), of: [])
            }
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
                        Text(verbatim: level.label).font(.ui(.label, .semibold)).foregroundStyle(offer.ink)
                            .opacity(open ? 1 : 0.5).frame(minWidth: 30, alignment: .leading)
                        Text(level.title).font(.ui(.body)).multilineTextAlignment(.leading)
                            .foregroundStyle(open ? Color.text : Color.text3)
                        Spacer(minLength: 8)
                        if !open {
                            Image(systemName: "lock.fill").font(.ui(.detail)).imageScale(.small).foregroundStyle(Color.text4)
                                .transition(.opacity.combined(with: .scale(scale: 1.8)))
                        } else if !noPar, case let mark = Archive.Mark(best, started: tried), let filled = ResultMarks.filled(mark) {
                            ResultMarks(filled: filled, margin: ResultMarks.margin(mark))
                        } else if let best {
                            Text(best.over == 0 ? atPar : "+\(best.over)").font(.ui(.detail)) // loc: verbatim localized by atPar, or a number
                                .foregroundStyle(best.over == 0 ? Color.amber : Color.magenta)
                        } else if tried {
                            Text("tried").font(.ui(.detail)).foregroundStyle(Color.text3)
                        }
                    }
                    .padding(.vertical, 9)
                    .contentShape(Rectangle())
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.4).delay(0.3 + 0.05 * Double(max(0, i - (offer.pack?.taste ?? 0)))),
                               value: open)
                }
                .buttonStyle(Sounding())
                .rowHairline(offer.glow, level.id == focus?.id ? lit : 0, inset: 10)
                .accessibilityValue(open ? best.map { // loc: verbatim each localized
                    noPar ? ($0.over == 0 ? String(localized: "solved", comment: "VoiceOver: Escapement's best, solved")
                             : String(localized: "\($0.over) over par", comment: "VoiceOver: an archive day's best. Moves over par"))
                        : Spoken.result($0)
                } ?? (tried ? String(localized: "tried", comment: "VoiceOver: a row started, with no best") : "")
                    : String(localized: "locked, needs the pack", comment: "VoiceOver: a pack's row past its free levels, unowned"))
                .accessibilityHint(open ? Text(verbatim: "") // loc: verbatim each a key
                                   : Text("Shows where to buy \(offer.name)", comment: "VoiceOver: a pack's locked row. The pack"))
            }
        }
    }

    /// Escapement has no par (Jack's call EL1, round 11): its best is a solve, which spends the budget to the last tick.
    private var noPar: Bool { offer.pack == .escapement }
    private var atPar: String {
        noPar ? String(localized: "solved", comment: "A pack's row: Escapement's best")
            : String(localized: "par", comment: "A pack's row: its best, at par")
    }

    /// A chapter's name and rule, with how many of its levels are at par, or solved.
    private func heading(_ name: String, of chapter: [Level]) -> some View {
        HStack(spacing: 10) {
            Text(name.localizedLowercase).font(.ui(.detail, .semibold)).foregroundStyle(offer.gradient).fixedSize() // loc: verbatim localized by the pack's table
            Rectangle().fill(offer.gradient).frame(height: 1).opacity(0.8)
            if !chapter.isEmpty {
                let par = chapter.filter { Best.load($0.id)?.over == 0 }.count
                (noPar ? Text("\(par)/\(chapter.count) solved", comment: "Escapement's chapter. Levels solved, of all")
                    : Text("\(par)/\(chapter.count) at par", comment: "A pack's chapter. Levels at par, of all"))
                    .font(.ui(.detail))
                    .foregroundStyle(Color.text3)
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
            line(offer.pack == nil
                 ? String(localized: "\u{2713} owned", comment: "A pack's card, owned")
                 : String(localized: "\u{2713} owned", comment: "A pack's card, owned"), .lime)
        case .pending:
            // A pack can wait on Triptych I's request alone, which only Triptych I's card asks again.
            let asked = store.asked(offer)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    PulsingDot(colour: .amber)
                    (asked ? Text("waiting for approval", comment: "A pack's card: its Ask to Buy sent")
                        : Text("\(Offer.bundleName) is waiting for approval", comment: "A pack's card: the bundle's Ask to Buy sent"))
                        .font(.ui(.headline)).foregroundStyle(Color.amber)
                }
                // Asking again failed, and the first request is still with the parent: the failure stands in for
                // Ask to Buy's explanation, so buy stays on the first screen of the smallest phone.
                if let why = store.failures[offer.productID]?.words {
                    detail(why)
                }
            }
            .accessibilityElement(children: .combine)
        case .failed:
            VStack(alignment: .leading, spacing: 4) {
                line(String(localized: "the purchase didn't go through", comment: "A pack's card: its purchase failed"), .magenta)
                if let why = store.failures[offer.productID]?.words { detail(why) }
            }
            .accessibilityElement(children: .combine)
        case .revoked:
            // A refund or a family's share ended: said plainly, never as an alarm.
            line(unshared ? String(localized: "\(offer.name) is no longer shared with you",
                                   comment: "A pack's card: a family's share ended. The pack")
                 : String(localized: "\(offer.name) isn't on this Apple ID any more",
                          comment: "A pack's card: refunded. The pack"), Color.text2, glow: false)
        }
    }

    private func detail(_ s: String) -> some View {
        Text(s).font(.ui(.detail)).foregroundStyle(Color.text3).fixedSize(horizontal: false, vertical: true) // loc: verbatim localized by the caller
    }

    private var unshared: Bool { offer.pack.map(store.unshared) ?? false }

    private func line(_ s: String, _ colour: Color, glow: Bool = true) -> some View {
        Text(s).font(.ui(.headline)).foregroundStyle(colour).shadow(color: colour.opacity(glow ? 0.6 : 0), radius: 4) // loc: verbatim localized by the caller
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Owned, play; otherwise buy at the App Store's price, and the taste beside it.
    @ViewBuilder private func action(_ state: Purchase) -> some View {
        if state == .owned {
            // The bundle has no levels of its own: its owner goes on in the first pack with a level left to play.
            let pack = offer.pack == nil ? Pack.bundled.first(where: { Shop.pickUp($0.levels) != nil }) : nil
            if let level = pack.flatMap({ Shop.pickUp($0.levels) }) ?? next {
                let continues = Shop.continues(pack?.levels ?? levels), name = pack?.name ?? offer.name
                let title = switch (continues, pack) {
                case (true, let pack?): String(localized: "continue \(pack.name) \(level.label) \u{203A}",
                                               comment: "The bundle's card, owned: plays on. The pack, then the level number")
                case (true, nil): String(localized: "continue \(level.label) \u{203A}", comment: "An owned pack's card: plays on. The level number")
                case (false, let pack?): String(localized: "play \(pack.name) \(level.label) \u{203A}",
                                                comment: "The bundle's card, owned: plays. The pack, then the level number")
                case (false, nil): String(localized: "play \(level.label) \u{203A}", comment: "An owned pack's card: plays. The level number")
                }
                pill(title, trailing: nil, colour: .lime) { onPlay(level) }
                    .accessibilityLabel(continues // loc: verbatim each a key
                        ? Text("Continue \(name), level \(level.label)", comment: "VoiceOver: an owned card's play button. The pack, the level number")
                        : Text("Play \(name), level \(level.label)", comment: "VoiceOver: an owned card's play button. The pack, the level number"))
            }
        } else {
            // A declined Ask to Buy sends no transaction, so an asked pill stays live: tapping it sends a new request.
            // A pack waiting only on Triptych I's request is bought alone.
            let asked = store.asked(offer)
            let label = switch state {
            case _ where buying: String(localized: "buying\u{2026}", comment: "The buy pill, a purchase running")
            case .failed: String(localized: "try again", comment: "The buy pill, a purchase failed")
            case .revoked: unshared ? String(localized: "buy", comment: "The buy pill")
                : String(localized: "buy again", comment: "The buy pill, refunded")
            case .pending where asked: String(localized: "asked", comment: "The buy pill, an Ask to Buy sent: tapped, sends it again")
            default: String(localized: "buy", comment: "The buy pill")
            }
            // As the pill says it, its words capitalized.
            let spoken = switch state {
            case _ where buying: String(localized: "Buying\u{2026} \(offer.name)", comment: "VoiceOver: the buy pill, a purchase running. The pack")
            case .failed: String(localized: "Try Again \(offer.name)", comment: "VoiceOver: the buy pill, a purchase failed. The pack")
            case .revoked: unshared ? String(localized: "Buy \(offer.name)", comment: "VoiceOver: the buy pill. The pack")
                : String(localized: "Buy Again \(offer.name)", comment: "VoiceOver: the buy pill, refunded. The pack")
            case .pending where asked: String(localized: "Ask again for \(offer.name)",
                                              comment: "VoiceOver: the buy pill, an Ask to Buy sent. The pack")
            default: String(localized: "Buy \(offer.name)", comment: "VoiceOver: the buy pill. The pack")
            }
            let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
                : AnyLayout(HStackLayout(spacing: 14))
            if !store.canPay { detail(Failure.refused.words ?? "").padding(.bottom, 12) }
            layout {
                if store.canPay {
                    pill(label, trailing: price ?? (unreachable ? nil : store.pricing.words), colour: offer.ink,
                         dim: price == nil, pending: buying) { buy(offer) }
                        .disabled(buying)
                        .keyframeAnimator(initialValue: 1.0, trigger: pulses) { pill, scale in
                            pill.scaleEffect(reduceMotion ? 1 : scale)
                        } keyframes: { _ in
                            // Held while the list scrolls up to it.
                            LinearKeyframe(1.0, duration: 0.35)
                            CubicKeyframe(1.08, duration: 0.14)
                            CubicKeyframe(1.0, duration: 0.3)
                        }
                        .accessibilityLabel(spoken) // loc: verbatim localized here
                        .accessibilityValue(price ?? store.pricing.words ?? "") // loc: verbatim the App Store's price, or localized by Pricing
                        .accessibilityFocused($spoken, equals: .buy)
                }
                if let taste = Shop.taste(levels) ?? Self.placeholder(offer).map({ (level: $0, replay: false) }) {
                    let (level, replay) = taste
                    let n = offer.pack?.taste ?? 3
                    UnstirButton(.secondary) { onPlay(level) } label: {
                        replay ? Text("replay 01\u{2013}\(String(format: "%02d", n)) \u{203A}",
                                      comment: "A pack's card: replays its free levels. The last's number")
                            : Text("try \(n) free \u{203A}", comment: "A pack's card: plays its free levels. How many")
                    }
                    .accessibilityLabel(replay ? Text("Replay the \(n) free levels", comment: "VoiceOver: a pack's card. How many") // loc: verbatim each a key
                                        : Text("Try the first \(n) levels free", comment: "VoiceOver: a pack's card. How many"))
                }
            }
            // Under the pill, as a failure is said, since it wraps inside the pill on the smallest phone.
            if unreachable { detail(store.pricing.words ?? "").padding(.top, 10).accessibilityHidden(true) }
        }
    }

    private var unreachable: Bool { store.canPay && price == nil && store.pricing == .unreachable }

    private var next: Level? { levels.isEmpty ? Self.placeholder(offer) : Shop.pickUp(levels) }

    /// Before a pack has levels, a Debug build plays its harness placeholder.
    private static func placeholder(_ offer: Offer) -> Level? {
        #if DEBUG
        offer.pack?.placeholder(1)
        #else
        nil
        #endif
    }

    /// The card's primary: buy in the pack's ink, the price in the label's colour; play in lime once owned.
    private func pill(_ title: String, trailing: String?, colour: Color, dim: Bool = false, pending: Bool = false,
                      _ tap: @escaping () -> Void) -> some View {
        UnstirButton(.primary, accent: colour, pending: pending, action: tap) {
            HStack(spacing: 14) {
                Text(title) // loc: verbatim localized by the caller
                // No price yet: what stands in for it is smaller and fainter.
                if let trailing { Text(trailing).font(dim ? .ui(.detail) : .ui(.button)).opacity(dim ? 0.45 : 1) } // loc: verbatim the App Store's price, or localized by Pricing
            }
        }
    }

    /// Triptych I's failure stays off the pack's own status, so it is said here, beside the button that tried.
    private func completeLine(_ saving: String) -> some View {
        let complete = store.price(Pack.triptychID) ?? ""
        let quiet = Color.text3
        // Non-breaking within each part, so a narrow phone or a large size wraps the line only before "· save".
        func joined(_ s: String) -> String { s.replacingOccurrences(of: " ", with: "\u{00A0}") }
        return VStack(alignment: .leading, spacing: 6) {
            Button { buy(.complete) } label: {
                let all = Text("or all \(Offer.countWord(Pack.bundled.count)) in \(Offer.bundleName)\u{00A0}\u{00B7}\u{00A0}",
                               comment: "A pack's card: buys the bundle instead. Its packs counted in words, then its name").foregroundStyle(quiet)
                let save = Text(joined(String(localized: "\u{00B7} save \(saving) \u{203A}", comment: "A pack's card: what the bundle saves. A price"))) // loc: verbatim localized here
                    .foregroundStyle(quiet)
                (all + Text(verbatim: joined(complete)).foregroundStyle(Color.text2) + Text(verbatim: " ") + save)
                .font(.ui(.detail))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                // Its failure line is 6 pt below.
                .hit(10, 8)
            }
            .buttonStyle(Sounding())
            // Triptych I's own request is asked again only from Triptych I's card.
            .disabled(buying || store.state(.complete) == .pending)
            .accessibilityLabel("Buy \(Offer.bundleName), \(Pack.named(Pack.bundled))")
            .accessibilityValue("\(complete), saves \(saving)")
            if store.state(.complete) == .failed {
                Text("\(Offer.bundleName)'s purchase didn't go through").font(.ui(.detail, .semibold)).foregroundStyle(Color.magenta)
                    .fixedSize(horizontal: false, vertical: true)
                if let why = store.failures[Pack.triptychID]?.words { detail(why) }
            }
        }
    }

    private var restore: some View {
        Button { Task { await store.restoreAndAnnounce() } } label: {
            let words = restoreWords
            Text(store.restoring ? store.restoreNote ?? words : store.restoreNote.map { "\($0) \u{00B7} \(words)" } ?? words) // loc: verbatim localized by Store and ConsentWords
                .font(.ui(.detail)).foregroundStyle(Color.text3)
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

/// The menu's shelf: a live cover per pack and Triptych I along the bottom, each opening its card. Out of step, so the
/// dock never stirs all at once. Equatable on what it is handed, since the menu redraws on every frame of a scroll and
/// each cover's marks read the saved bests.
struct PackDock: View, Equatable {
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

    /// The label role's size at the dock's, capped at xxxLarge as the dock is, down to the largest at which every word of
    /// every name, with its cover's glyph, fits its cover.
    private func nameSize(_ shelf: [Offer]) -> CGFloat {
        let category = UIContentSizeCategory(min(typeSize, .xxxLarge))
        let size = UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: 15, compatibleWith:
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
            // Triptych I only while it costs less than the packs left: owned, it saves nothing.
            let shelf = Offer.shelf().filter { $0 != .complete || store.offersComplete }
            HStack {
                if let yours = store.approved.first {
                    Text(yours.yours).font(.ui(.detail, .semibold)).tracking(1).foregroundStyle(yours.glow) // loc: verbatim localized by Offer
                        .shadow(color: yours.glow.opacity(0.6), radius: 4).transition(.opacity)
                } else {
                    (owned.isEmpty ? Text("PACKS \u{00B7} PAID ADD-ONS", comment: "The dock's header, nothing owned")
                        : Text("PACKS", comment: "The dock's header")).font(.ui(.detail, .semibold)).tracking(2)
                        .foregroundStyle(Color.text2).transition(.opacity)
                }
                Spacer()
                if typeSize < .xxLarge, owned.count < Pack.sold().count {
                    Text("first 3 levels of each free").font(.ui(.detail)).foregroundStyle(Color.text3)
                }
            }
            .padding(.horizontal, 20)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .animation(.easeInOut(duration: 0.4), value: store.approved.first)
            .task(id: Saying(offer: Shop.saying(store.approved.first, covered: covered, shelved: store.shelved),
                             covered: covered || !store.shelved)) {
                // Held under UNSTIR_CLOCK, for its shot.
                guard let offer = Shop.saying(store.approved.first, covered: covered, shelved: store.shelved) else { return }
                if announced.insert(offer).inserted { AccessibilityNotification.Announcement(offer.yours).post() } // loc: verbatim localized by Offer
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
                                    Text(verbatim: offer.name).lineLimit(1)
                                    Text(verbatim: offer.name.replacingOccurrences(of: " ", with: "\n"))
                                        .lineLimit(offer.name.split(separator: " ").count)
                                }
                                .font(.system(size: nameSize(shelf), design: .monospaced))
                                .foregroundStyle(Color.text2).multilineTextAlignment(.center)
                                // A glyph, so the state reads without its colour; a revocation is the card's to say.
                                if store.ready, let mark = state.mark {
                                    Image(systemName: mark).font(.system(size: 8, weight: .bold)).foregroundStyle(state.tag()?.colour ?? .text)
                                        .shadow(color: state.tag()?.colour ?? .clear, radius: 2)
                                        .accessibilityHidden(true)
                                }
                            }
                            // Its room kept without one, so a mark clearing never moves the dock.
                            let new = line?.new == true
                            Text(line?.words ?? " ").font(.ui(.detail, new ? .semibold : .regular)) // loc: verbatim localized by Marks
                                .foregroundStyle(new ? offer.ink : Color.text3)
                                .shadow(color: new ? offer.glow.opacity(0.6) : .clear, radius: 3)
                                .padding(.top, -4)
                        }
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(Sounding())
                    .accessibilityLabel(offer.pack == nil // loc: verbatim names alone, or a key
                        ? Text(verbatim: "\(offer.name), \(Pack.named(Pack.bundled))")
                        : Text("\(offer.name), pack", comment: "VoiceOver: a pack's cover. Its name"))
                    .accessibilityValue([(store.ready ? state.tag(unshared: offer.pack.map(store.unshared) ?? false)?.word : nil) // loc: verbatim localized by Purchase and Marks
                                         ?? store.price(offer.productID), line?.spoken].compactMap { $0 }.joined(separator: ", "))
                    .accessibilityHint(offer.pitch ?? "") // loc: verbatim localized by Offer
                    .accessibilityShowsLargeContentViewer {
                        Text(verbatim: offer.name)
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
            Rectangle().fill(Color.rule).frame(height: 1).padding(.horizontal, 20)
        }
    }

    private struct Saying: Equatable {
        let offer: Offer?
        let covered: Bool
    }
}
