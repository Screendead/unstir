// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The last of a pack's levels, or of the last tier's, given a best (Jack's call C8, round 13).
enum Completion: Equatable {
    case pack(Pack), free

    var pack: Pack? { if case .pack(let p) = self { p } else { nil } }

    var line: String {
        switch self {
        case .pack(let p): "\(p.name) complete \u{00B7} \(p.levels.count) \(p.noun)"
        case .free: "every tier unstirred"
        }
    }

    /// The line as VoiceOver says it, without the middle dot.
    var spoken: String {
        switch self {
        case .pack(let p): "\(p.name) complete, \(p.levels.count) \(p.noun)."
        case .free: "Every tier unstirred."
        }
    }
}

/// No way back of its own (Jack's call D4 = A, round 13): the header's back control stays on screen above it and the edge
/// swipe leaves too.
struct ResultCard: View {
    let game: Game
    let onNext: (Level) -> Void
    let onLook: (Tier) -> Void
    @AccessibilityFocusState private var focused: Bool
    /// A reset from the card, for another go at a solve that wasn't clean.
    let again: () -> Void
    /// The harness's clock for the daily's next one; nil reads the time.
    let now: Date?
    let onOffer: (Pack) -> Void
    /// The pack "more puzzles in the packs ›" opens, read as the card appears, which spends its one showing.
    @State private var packs: Pack?
    @Environment(\.page) private var page

    /// What the card says of the level's best: whether this solve beat the one before, by what the card names (clean,
    /// then over par), and nothing on a first solve, which a daily's first on its day is over a best the archive saved
    /// (`Best.standing` puts it first). Escapement has no par, so its marks are clean and solved.
    static func bestLine(was: Best?, now: Best, par: Bool) -> String? {
        guard let was, (was.archived == true) == (now.archived == true) else { return nil }
        func mark(_ b: Best) -> String { b.clean == true ? "clean" : !par ? "solved" : b.over == 0 ? "par" : "+\(b.over)" }
        return now.standing < was.standing ? "new best \u{00B7} was \(mark(was))" : "best \u{00B7} \(mark(was))"
    }

    var body: some View {
        let run = game.level.run
        // A pack level's tier is plughole's by default, so a pack takes its own colour first.
        let tierAccent: Color = switch game.level.tier {
        case .plughole: .neonCyan
        case .vortex: game.level.tier.glow
        case .whirlpool, .maelstrom: .blood
        }
        let accent = game.level.pack.map { Offer.pack($0).glow } ?? tierAccent
        let next = run != nil ? game.nextTank : (game.level.pack?.levels ?? game.level.tier.levels).drop(while: { $0.id != game.level.id }).dropFirst().first
        VStack(spacing: 26) {
            VStack(spacing: 10) {
                VStack(spacing: 8) {
                    if let run {
                        Text("moves \(game.moves)")
                        if game.spilled && run.tank > run.best {
                            Text("tanks cleared \(run.tank) \u{00B7} ") + Text("new best").foregroundStyle(Color.lime)
                        } else {
                            Text(game.spilled ? "tanks cleared \(run.tank) \u{00B7} best \(Best.tanks)"
                                 : "tank \(run.tank + 1) \u{00B7} brim \(game.brim) / \(Run.room)")
                        }
                    } else if !game.level.ratchets.isEmpty {
                        // Escapement has no par: a solve always spends the budget to the last tick (Jack's call EL1, round
                        // 11), so the ticks say nothing.
                        Text("solved in \(game.moves) moves")
                        if game.clean {
                            Text("clean").fontWeight(.semibold).foregroundStyle(page.signal(.lime)).shadow(color: page.glow(.lime), radius: 3)
                        } else {
                            Text(game.firstTry ? "solved \u{00B7} clean needs no reset or undo" : "clean counts on the first try")
                                .foregroundStyle(page.signal(.amber))
                        }
                    } else {
                        Text("moves \(game.moves) \u{00B7} par \(game.par)")
                        if game.clean {
                            Text("clean").fontWeight(.semibold).foregroundStyle(page.signal(.lime)).shadow(color: page.glow(.lime), radius: 3)
                        } else if game.over > 0 {
                            Text("+\(game.over) over par").foregroundStyle(page.signal(.magenta))
                        } else {
                            Text(game.firstTry ? "at par \u{00B7} clean needs no reset or undo" : "clean counts on the first try")
                                .foregroundStyle(page.signal(.amber))
                        }
                    }
                    if let b = game.bests, let line = Self.bestLine(was: b.was, now: b.now, par: game.level.ratchets.isEmpty) {
                        Text(line).opacity(0.6)
                    }
                    if let done = game.completed {
                        Text(done.line).fontWeight(.semibold).foregroundStyle(accent).shadow(color: page.glow(accent), radius: 3)
                            .padding(.top, 4)
                    }
                }
                .font(.ui(.label))
                // Focus lands on the finish itself: an announcement before a focus move is cut short.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(game.finishSpoken)
                .accessibilityFocused($focused)
                if let pack = Offer.pointer(after: game.completed) {
                    // Quiet: the card's way on is still next, or up a notch.
                    Button { onOffer(pack) } label: { Text("try \(pack.name) \u{203A}").hit() }
                        .font(.ui(.detail)).opacity(0.6)
                        .accessibilityLabel("Try \(pack.name)")
                } else if let pack = packs {
                    Button { onOffer(pack) } label: { Text("more puzzles in the packs \u{203A}").hit() }
                        .font(.ui(.detail)).opacity(0.6)
                        .accessibilityLabel("More puzzles in the packs")
                }
            }
            // Wrapped, so a card with none, a clean solve of a list's last level, keeps no gap for the row.
            if game.offersAgain || game.shareText != nil || next != nil {
                HStack(spacing: 32) {
                    if game.offersAgain {
                        Button(action: again) { Text("again \u{21BA}").hit() }.buttonStyle(Sounding(effect: .reset))
                            .accessibilityLabel("Again")
                    }
                    if let share = game.shareText {
                        ShareButton(items: { [share] }) { Text("share \u{2197}").hit() }
                            .foregroundStyle(page.signal(.amber)).shadow(color: page.glow(.amber), radius: 4)
                            .accessibilityLabel("Share result")
                    }
                    if let next {
                        // Past a pack's free taste, unowned, next opens its card: the button says so.
                        let gate = Store.shared.card(for: next)
                        let label = game.spilled ? "new run \u{203A}" : gate.map { "more in \($0.name) \u{203A}" } ?? "next \u{203A}"
                        Button { onNext(next) } label: { Text(label).hit() }
                            .foregroundStyle(accent).shadow(color: page.glow(accent), radius: 4)
                            .accessibilityLabel(game.spilled ? "New run" : run != nil ? "Next tank" : "Next level")
                    }
                }
                .font(.ui(.button))
            }
            if let day = Share.day(of: game.level.id), !game.level.archived {
                TimelineView(.everyMinute) { t in
                    Text(Daily.untilNext(day: day, now: now ?? t.date)).font(.ui(.detail)).opacity(0.55)
                        .accessibilityLabel(Daily.untilNext(day: day, now: now ?? t.date, spoken: true))
                }
            }
            if let up = game.opened ?? (game.level.id == game.level.tier.levels.last?.id ? game.level.tier.step(1) : nil) {
                TierUp(from: game.level.tier, to: up, onNext: onNext, onLook: onLook)
            }
        }
        .onAppear {
            focused = true
            guard packs == nil, let pack = Offer.ladderEnd(game.level, completed: game.completed, shown: Best.packsPointed)
            else { return }
            packs = pack
            if game.storesProgress { Best.packsPointed = true }
        }
    }
}

/// The one rating request (Jack's call C20, round 13): on the card of the solve that opens whirlpool, a tier's worth of
/// play in and on a high. A launch that saw a purchase land skips it, and since that solve comes once, never asks.
/// `RootView` makes it, not the card: a tap on within the wait would take it with the card, for good.
@MainActor @Observable final class Review {
    static let shared = Review()
    /// The solve that opens whirlpool came this launch, and the request hasn't been made.
    var pending = false
    /// The launch's: a harnessed one, or the test host, never asks, and UNSTIR_REVIEW=log logs the request in place of
    /// making it.
    static var harnessed = false, logs = false
    /// 2 s after the card, which shows 1.4 s after the solve.
    static let wait = 3.4

    static func due(opened: Tier?, asked: Bool, harnessed: Bool, purchased: Bool) -> Bool {
        opened == .whirlpool && !asked && !harnessed && !purchased
    }
}

/// The solve that opens the next tier, and the last level of a tier, go on up the ladder, in the next tier's own
/// colours. A tier still closed keeps its glow behind a lock, says how many levels are short of par and opens the menu
/// on its gate, which shows which.
private struct TierUp: View {
    let from: Tier
    let to: Tier
    let onNext: (Level) -> Void
    let onLook: (Tier) -> Void
    @State private var glint = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let open = to.isOpen(), short = from.atPar().filter { !$0 }.count
        let shortLine = "\(short) \(from.name.lowercased()) level\(short == 1 ? "" : "s") short of par"
        Button { open ? onNext(to.levels[0]) : onLook(to) } label: {
            VStack(spacing: 6) {
                Text(open ? "up a notch" : shortLine)
                    .font(open ? .ui(.eyebrow) : .ui(.detail)).tracking(open ? 2 : 0).textCase(open ? .uppercase : nil).opacity(0.6)
                HStack(spacing: 10) {
                    if !open { Image(systemName: "lock.fill").font(.ui(.label, .semibold)) }
                    Text(to.name.uppercased()).font(.ui(.displaySmall)).tracking(4)
                    Text("\u{203A}").font(.ui(.displaySmall))
                }
                .foregroundStyle(to.sweep)
                .shadow(color: to.glow.opacity(glint ? 0.9 : 0.5), radius: glint ? 16 : 9)
            }
            .padding(.horizontal, 26).padding(.vertical, 14)
            .background { Capsule().strokeBorder(to.sweep, lineWidth: 1.5).shadow(color: to.glow, radius: glint ? 10 : 5) }
        }
        .buttonStyle(Sounding())
        .accessibilityLabel(open ? "Up a notch: \(to.name)" : "\(to.name), locked. \(shortLine), and par on every one opens it")
        .accessibilityHint(open ? "" : "Shows which \(from.name) levels are short of par")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever()) { glint = true }
        }
    }
}

/// Escapement's tank out of ticks: the move that spent them, undo (an empty bank says when it refills), and again, a
/// reset. As the result card, no way back of its own.
struct LostCard: View {
    let game: Game
    let notice: String?
    let undo: () -> Void
    let again: () -> Void
    @AccessibilityFocusState private var focused: Bool
    @Environment(\.page) private var page

    var body: some View {
        VStack(spacing: 26) {
            Text("out of ticks on move \(game.moves)").font(.ui(.label))
                .accessibilityLabel(game.finishSpoken).accessibilityFocused($focused)
            HStack(spacing: 32) {
                Button(action: undo) { Text("undo \u{00B7} \(game.bank)").hit() }
                    .buttonStyle(Sounding(effect: game.bank == 0 ? .tap : .undo))
                    .opacity(game.bank == 0 ? 0.35 : 1)
                    .accessibilityLabel("Undo, \(game.bank) left")
                Button(action: again) { Text("again \u{203A}").hit() }.buttonStyle(Sounding(effect: .reset))
                    .foregroundStyle(page.accent).shadow(color: page.glow(page.accent), radius: 4)
                    .accessibilityLabel("Try again")
            }
            .font(.ui(.button))
            if let notice { Text(notice).font(.ui(.label)).opacity(0.7).transition(.opacity) }
        }
        .onAppear { focused = true }
    }
}
