// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The result on the slope (docs/slope.md, 5): no card, but lines set on open water under the solved tank, then stones
/// on the terrace. One layout for every finish, the words and stones changing with it: what the old card says, in the
/// slope's voices and inks. `ResultCard` hands over to it while the slope is on, so `LevelView` measures it as it
/// measured the card and the finished tank gives way by what it lacks.
struct SlopeResult: View {
    let game: Game
    let onNext: (Level) -> Void
    let onLook: (Tier) -> Void
    let again: () -> Void
    let now: Date?
    let onOffer: (Pack) -> Void
    /// The pack "more puzzles in the packs ›" opens, read as the result appears, which spends its one showing.
    @State private var packs: Pack?
    @State private var placed = CGRect.zero
    @AccessibilityFocusState private var focused: Bool
    @Environment(\.page) private var page

    /// The slope world is on: until the integrator's own switch lands, UNSTIR_SLOPE=world, which names no harness stage,
    /// so the app runs as it does with the slope's screens. No Release build reads it.
    static let on: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.environment["UNSTIR_SLOPE"] == "world"
        #else
        false
        #endif
    }()

    /// The lines arrive as the old card did, 0.3 s after it is placed; the stones half a second after them.
    static let lines = 0.3, stones = 0.8

    var body: some View {
        let way = ResultCard.Way(game)
        VStack(spacing: 22) {
            VStack(spacing: 12) {
                summary(way)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(game.finishSpoken) // loc: verbatim localized by Game
                    .accessibilityFocused($focused)
                pointer
            }
            .modifier(SlopeArrival(after: Self.lines))
            SlopeResultStones(game: game, way: way, onNext: onNext, onLook: onLook, again: again, now: now)
                .modifier(SlopeArrival(after: Self.stones))
        }
        .padding(.horizontal, 4)
        .background(alignment: .top) {
            SlopeLightSettling(top: placed.minY, width: placed.width)
        }
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { placed = $0 }
        .onAppear {
            focused = true
            guard packs == nil, let pack = Offer.ladderEnd(game.level, completed: game.completed, shown: Best.packsPointed)
            else { return }
            packs = pack
            if game.storesProgress { Best.packsPointed = true }
        }
    }

    /// The marks, the verdict, the facts, what clean takes, the best line and a completion: today's lines in today's
    /// order and colours, one element for VoiceOver.
    private func summary(_ way: ResultCard.Way) -> some View {
        VStack(spacing: 5) {
            if let run = game.level.run {
                Text("moves \(game.moves)").font(.slope(.data, .label)).foregroundStyle(page.slope(.ink2))
                Group {
                    if game.spilled && run.tank > run.best {
                        Text("tanks cleared \(run.tank) \u{00B7} ").foregroundStyle(page.slope(.ink2))
                            + Text("new best").foregroundStyle(page.signal(.lime))
                    } else {
                        (game.spilled ? Text("tanks cleared \(run.tank) \u{00B7} best \(Best.tanks)",
                                             comment: "Endless's card, spilled. Tanks cleared, then the best run's")
                            : Text("tank \(run.tank + 1) \u{00B7} brim \(game.brim) / \(Run.room)",
                                   comment: "Endless's card. The tank, then the brim's notches of its room"))
                            .foregroundStyle(page.slope(.ink2))
                    }
                }
                .font(.slope(.data, .label))
            } else {
                // Escapement has no par, so no marks; nor has the sandbox, where nothing counts.
                let par = game.level.ratchets.isEmpty
                if par && !game.level.sandbox {
                    ResultMarks(filled: ResultMarks.filled(clean: game.clean, over: game.over), card: true, glows: !page.paper)
                        .padding(.bottom, 9)
                }
                Group {
                    if game.clean {
                        Text("clean").foregroundStyle(page.signal(.lime)).shadow(color: page.glow(.lime.opacity(0.7)), radius: 6)
                    } else if par && game.over == 0 {
                        Text("at par").foregroundStyle(page.signal(.amber))
                    } else {
                        Text("solved").foregroundStyle(page.slope(.ink))
                    }
                }
                .font(.slope(.ui, .body, .medium))
                // The tone on the words, not the line, so the margin keeps its magenta whole.
                let quiet = page.slope(.ink2)
                let facts = par ? Text("moves \(game.moves) \u{00B7} par \(game.par)") : Text("moves \(game.moves)")
                Group {
                    if par && game.over > 0 {
                        facts.foregroundStyle(quiet) + Text(verbatim: " \u{00B7} ").foregroundStyle(quiet)
                            + Text(verbatim: "+\(game.over)").foregroundStyle(page.signal(.magenta))
                    } else {
                        facts.foregroundStyle(quiet)
                    }
                }
                .font(.slope(.data, .label))
                if !game.clean && (!par || game.over == 0) {
                    (game.firstTry || !Best.cleanNeedsFirstTry(game.level.id) ? Text("clean needs no undo or reset")
                        : Text("clean counts on the first try"))
                        .font(.slope(.ui, .detail)).foregroundStyle(page.slope(.ink3))
                }
            }
            if let b = game.bests, let line = ResultCard.bestLine(was: b.was, now: b.now, par: game.level.ratchets.isEmpty) {
                Text(line).font(.slope(.data, .label)).foregroundStyle(page.slope(.ink2)) // loc: verbatim localized by bestLine
            }
            if let done = game.completed {
                // In its colour with its glow (Jack's call COMPLETION = A).
                Text(done.line).font(.slope(.ui, .body, .medium)).foregroundStyle(page.signal(way.accent)) // loc: verbatim localized by Completion
                    .shadow(color: page.glow(way.accent.opacity(0.8)), radius: 6)
                    .padding(.top, 8)
            }
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// One quiet pointer to the packs: a completion's to the first pack unowned, or once, the end of the ladder's.
    @ViewBuilder private var pointer: some View {
        if let pack = Offer.pointer(after: game.completed) {
            quiet(Text("try \(pack.name) \u{203A}"), spoken: Text("Try \(pack.name)")) { onOffer(pack) }
        } else if let pack = packs {
            quiet(Text("more puzzles in the packs \u{203A}"), spoken: Text("More puzzles in the packs")) { onOffer(pack) }
        }
    }

    private func quiet(_ words: Text, spoken: Text, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            words.font(.slope(.ui, .detail)).foregroundStyle(page.slope(.ink3)).hit()
        }
        .buttonStyle(Sounding())
        .accessibilityLabel(spoken) // loc: verbatim each a key at the call
    }
}

/// The result's stones on the terrace (5.2): again leading; the way on trailing, with next in the middle where up a
/// notch takes the trailing seat, and share in the middle or, alone, trailing; under them the daily's next. Where the
/// seats can't each hold their words on one line, up a notch takes a terrace of its own above the rest.
///
/// It stands in for the play screen's terrace until that piece's seats land: then `leading`, `middle`, `trailing` and
/// `upper` fill them as they are.
struct SlopeResultStones: View {
    let game: Game
    let way: ResultCard.Way
    let onNext: (Level) -> Void
    let onLook: (Tier) -> Void
    let again: () -> Void
    let now: Date?
    @Environment(\.page) private var page

    /// The stones after again, in seat order: share, next, up a notch; the last takes the trailing seat.
    private enum Kind { case share(String), next(Level), up(Tier) }

    private var ways: [Kind] {
        var ways: [Kind] = []
        if let share = game.shareText { ways.append(.share(share)) }
        if let next = way.next { ways.append(.next(next)) }
        if let up = way.up { ways.append(.up(up)) }
        return ways
    }

    var body: some View {
        VStack(spacing: 10) {
            ViewThatFits(in: .horizontal) {
                row(ways)
                // Up a notch on a terrace of its own, the rest under it.
                if let last = ways.last, case .up = last {
                    VStack(spacing: 10) {
                        HStack { Spacer(minLength: 0); stone(last, trailing: true) }
                        row(Array(ways.dropLast()))
                    }
                }
            }
            if let day = Share.day(of: game.level.id), !game.level.archived {
                TimelineView(.everyMinute) { t in
                    Text(Daily.untilNext(day: day, now: now ?? t.date)).font(.slope(.data, .detail)).foregroundStyle(page.slope(.ink3)) // loc: verbatim localized by Daily
                        .accessibilityLabel(Daily.untilNext(day: day, now: now ?? t.date, spoken: true)) // loc: verbatim localized by Daily
                }
            }
        }
    }

    /// Again leading, the last trailing and one before it in the middle.
    private func row(_ ways: [Kind]) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            if game.offersAgain { againStone }
            Spacer(minLength: 16)
            if ways.count > 1 {
                stone(ways[ways.count - 2], trailing: false)
                Spacer(minLength: 16)
            }
            if let last = ways.last { stone(last, trailing: true) }
        }
    }

    private var pale: Bool { game.level.pack == .prism }

    private var againStone: some View {
        Stone(Text("again \u{21BA}"), pale: pale, engraved: page.paper, action: again)
            .fixedSize()
            .accessibilityLabel("Again")
    }

    @ViewBuilder private func stone(_ kind: Kind, trailing: Bool) -> some View {
        switch kind {
        case .share(let share):
            let leads = !way.nextLeads && !way.upLeads
            Stone(Text("share \u{2197}"), state: leads ? .next : .lit, pale: pale, engraved: page.paper, trailing: trailing,
                  glow: leads ? .amber : nil, ink: leads ? page.signal(.amber) : nil) {
                ShareSheet.present([share])
            }
            .fixedSize()
            .accessibilityLabel("Share result")
        case .next(let next):
            let glow = game.level.pack.map { Offer.pack($0).glow } ?? game.level.tier.glow
            Stone(Text(verbatim: way.label(game)), state: way.nextLeads ? .next : .lit, pale: pale, engraved: page.paper, // loc: verbatim localized by Way
                  trailing: trailing, glow: way.nextLeads ? glow : nil, ink: way.nextLeads ? page.signal(way.accent) : nil) {
                onNext(next)
            }
            .fixedSize()
            .accessibilityLabel(game.spilled ? Text("New run", comment: "VoiceOver: starts a new endless run") // loc: verbatim each a key
                                : game.level.run != nil ? Text("Next tank", comment: "VoiceOver: endless's card, the next tank")
                                : Text("Next level", comment: "VoiceOver: the card's next level"))
        case .up(let to):
            SlopeUpANotch(from: game.level.tier, to: to, onNext: onNext, onLook: onLook)
                .fixedSize()
        }
    }
}

/// Up a notch (5.2): two lines beside the way on, "up a notch" over the next tier's name, in that tier's colour and
/// glow. Closed, only after an unlock was on and is off, the stone is dull, the name at the closed ink with no chevron,
/// and under it how many levels are unsolved; a tap opens the menu's dive on that tier's gate. No lock is drawn.
private struct SlopeUpANotch: View {
    let from: Tier
    let to: Tier
    let onNext: (Level) -> Void
    let onLook: (Tier) -> Void

    var body: some View {
        let open = to.isOpen(), short = from.solved().filter { !$0 }.count
        let shortLine = String(localized: "\(short) \(from.word) levels unsolved",
                               comment: "The card's way up, the next tier shut. Levels unsolved, then their tier")
        VStack(alignment: .trailing, spacing: 0) {
            Stone(state: open ? .next : .dull, trailing: true, glow: to.glow, ink: open ? to.ink : nil) {
                open ? onNext(to.levels[0]) : onLook(to)
            } label: {
                VStack(alignment: .trailing, spacing: -2) {
                    if open {
                        Text("up a notch", comment: "The card's way up to the next tier")
                            .font(.slope(.place, .label)).foregroundStyle(SlopeInk.ink2.colour)
                    }
                    Text(verbatim: open ? "\(to.word) \u{203A}" : to.word).font(.slope(.name, .title)) // loc: verbatim localized by Tier.word
                }
            }
            if !open {
                // Under the stone's words, at a strength the dull stone's own words can't carry.
                Text(shortLine).font(.slope(.ui, .detail)).foregroundStyle(SlopeInk.ink2.colour) // loc: verbatim localized here
                    .padding(.trailing, 4)
                    .onTapGesture { onLook(to) }
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(open ? Text("Up a notch: \(to.name)", comment: "VoiceOver: the card's way up. The next tier") // loc: verbatim each a key
                            : Text("\(to.name), locked. \(shortLine), and solving every one opens it",
                                   comment: "VoiceOver: the card's way up, shut. The next tier, then how many levels are unsolved"))
        .accessibilityHint(open ? Text(verbatim: "") // loc: verbatim each a key
                           : Text("Shows which \(from.name) levels are unsolved", comment: "VoiceOver: the card's way up, shut. The tier below"))
        .accessibilityAddTraits(.isButton)
    }
}

/// Escapement's tank out of ticks, on its paper (5.3): what spent them, then undo leading and again trailing, engraved;
/// under them, an empty bank's word on when it refills. As the result, no way back of its own.
struct SlopeLost: View {
    let game: Game
    let notice: String?
    let undo: () -> Void
    let again: () -> Void
    @AccessibilityFocusState private var focused: Bool
    @Environment(\.page) private var page

    var body: some View {
        VStack(spacing: 22) {
            Text("out of ticks on move \(game.moves)").font(.slope(.ui, .body, .medium)).foregroundStyle(page.slope(.ink))
                .accessibilityLabel(game.finishSpoken).accessibilityFocused($focused) // loc: verbatim localized by Game
                .modifier(SlopeArrival(after: SlopeResult.lines))
            VStack(spacing: 10) {
                HStack(alignment: .bottom, spacing: 16) {
                    Stone(Text("undo \u{00B7} \(game.bank)"), state: game.bank == 0 ? .dull : .lit, engraved: page.paper, action: undo)
                        .fixedSize()
                        .accessibilityLabel("Undo, \(game.bank) left")
                    Spacer(minLength: 0)
                    Stone(Text("again \u{203A}"), engraved: page.paper, trailing: true, action: again)
                        .fixedSize()
                        .accessibilityLabel("Try again")
                }
                if let notice {
                    Text(notice).font(.slope(.place, .body)).foregroundStyle(page.slope(.ink)) // loc: verbatim localized by TankView
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }
            }
            .modifier(SlopeArrival(after: SlopeResult.stones))
        }
        .padding(.horizontal, 4)
        .onAppear { focused = true }
    }
}

/// "unstirred." over the solved tank (5.1): the place voice at display, in the stamp's place and by its rules, rising
/// 26 pt to it as it fades in. For the play screen's tank to set where it sets today's stamp.
struct SlopeStamp: View {
    @Environment(\.page) private var page

    var body: some View {
        Text("unstirred.").font(.slope(.place, .display)).foregroundStyle(page.ink)
            .shadow(color: page.glow(.white.opacity(0.35)), radius: 8)
            .modifier(SlopeArrival(after: 0, rise: 26))
    }
}

/// A line of words arriving (1.5): it fades in over 0.6 s while rising to its place and settling there, a touch past
/// and back; under Reduce Motion it fades in where it stands.
struct SlopeArrival: ViewModifier {
    let after: Double
    var rise: CGFloat = 16
    @State private var arrived = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .animation(.easeOut(duration: 0.6).delay(after)) { $0.opacity(arrived ? 1 : 0) }
            // The rise settles, the fade doesn't: `1 - exp(-6x) cos(5x)` is a spring of about this bounce.
            .animation(reduceMotion ? nil : .spring(duration: 1.1, bounce: 0.18).delay(after)) {
                $0.offset(y: arrived || reduceMotion ? 0 : rise)
            }
            .onAppear { arrived = true }
    }
}

/// Light settling (1.5): nine bright motes sink past the solved tank, either side of it, and come to rest round the
/// result over 3.4 s, then are gone. Drawn from the result's top (`top`, in the screen's space) up to the screen's,
/// the tank's edge taken as the result's width. Nothing under Reduce Motion.
struct SlopeLightSettling: View {
    let top: CGFloat
    let width: CGFloat
    @State private var start: Date?
    @State private var played = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.page) private var page

    /// How far past the result's edges a mote may sink.
    private static let reach: CGFloat = 60

    /// The last mote's start and life.
    private static let span = 0.2 + 8 * 0.21 + 3.4

    var body: some View {
        ZStack(alignment: .top) {
            if width > 0, let start {
                TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
                    motes(timeline.date.timeIntervalSince(start))
                }
            }
        }
        .frame(width: max(width, 0) + 2 * Self.reach, height: 0, alignment: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task {
            guard !played, !reduceMotion, !page.paper else { return }
            played = true
            start = .now
            try? await Task.sleep(for: .seconds(Self.span))
            start = nil
        }
    }

    private func motes(_ t: Double) -> some View {
        Canvas { context, size in
            for k in 0 ..< 9 {
                let life = (t - 0.2 - Double(k) * 0.21) / 3.4
                guard life > 0, life < 1 else { continue }
                let side: CGFloat = k % 2 == 1 ? 1 : -1
                let x = size.width / 2 + side * (width * 0.45 + 6 + CGFloat(k * 37 % 30)) + 5 * sin(Double(k) * 2.1)
                // From near the screen's top to just under the result's lines, easing out.
                let from = 150 - top + max(top, 0), to = 140 + CGFloat(k * 53 % 60) + max(top, 0)
                let y = from + (to - from) * (1 - pow(1 - life, 3))
                let strength = 0.42 * sin(.pi * min(1, life * 1.15))
                let r: CGFloat = 7
                context.fill(Path(ellipseIn: CGRect(x: x - 3 * r, y: y - 3 * r, width: 6 * r, height: 6 * r)),
                             with: .radialGradient(Gradient(colors: [Color(0xFFEEC4).opacity(strength), Color(0xFFEEC4).opacity(0)]),
                                                   center: CGPoint(x: x, y: y), startRadius: 0, endRadius: 3 * r))
                context.fill(Path(ellipseIn: CGRect(x: x - 1.6, y: y - 1.6, width: 3.2, height: 3.2)),
                             with: .color(Color(0xFFF6E2).opacity(min(strength * 1.8, 1))))
            }
        }
        // From the screen's top to under the lines, the result's top `top` down it, and wide enough for the motes
        // beside the widest tank: a Canvas clips at its frame.
        .frame(width: width + 2 * Self.reach, height: max(top, 0) + 400)
        .offset(y: -max(top, 0))
    }
}

extension Page {
    /// A slope ink on this page: on Escapement's paper every word is the paper's ink, at the old tones.
    func slope(_ ink: SlopeInk) -> Color {
        guard paper else { return ink.colour }
        return switch ink {
        case .ink: self.ink
        case .ink2, .ink3: self.ink.opacity(TextTone.text2.alpha)
        case .ink4: self.ink.opacity(TextTone.text4.alpha)
        }
    }
}
