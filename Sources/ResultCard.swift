// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The last of a pack's levels, or of the last tier's, given a best (Jack's call C8, round 13).
enum Completion: Equatable {
    case pack(Pack), free

    var pack: Pack? { if case .pack(let p) = self { p } else { nil } }

    var line: String {
        switch self {
        case .pack(let p): String(localized: "\(p.name) complete \u{00B7} \(p.counted(p.levels.count))",
                                  comment: "The card of a pack's last level. The pack, then its levels counted")
        case .free: String(localized: "every tier unstirred", comment: "The card of the last tier's last level")
        }
    }

    /// The line as VoiceOver says it, without the middle dot.
    var spoken: String {
        switch self {
        case .pack(let p): String(localized: "\(p.name) complete, \(p.counted(p.levels.count)).",
                                  comment: "VoiceOver: the card of a pack's last level. The pack, then its levels counted")
        case .free: String(localized: "Every tier unstirred.", comment: "VoiceOver: the card of the last tier's last level")
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
    /// A reset from the card, for another go: a level's over par, the daily's short of clean (`Game.offersAgain`).
    let again: () -> Void
    /// The harness's clock for the daily's next one; nil reads the time.
    let now: Date?
    let onOffer: (Pack) -> Void
    /// The pack "more puzzles in the packs ›" opens, read as the card appears, which spends its one showing.
    @State private var packs: Pack?
    @Environment(\.page) private var page

    /// What the card says of the level's best: whether this solve beat the one before, by what the card names (clean
    /// where `keepsClean`, then over par), and nothing on a first solve, which a daily's first on its day is over a best
    /// the archive saved (`Best.standing` puts it first). Escapement has no par, so its only mark is solved.
    static func bestLine(was: Best?, now: Best, par: Bool, keepsClean: Bool) -> String? {
        guard let was, (was.archived == true) == (now.archived == true) else { return nil }
        func mark(_ b: Best) -> String {
            keepsClean && b.clean == true ? String(localized: "clean", comment: "The card's best line: the best before, solved with nothing wasted")
                : !par ? String(localized: "solved", comment: "The card's best line: Escapement's best before")
                : b.over == 0 ? String(localized: "par", comment: "The card's best line: the best before, at par") : "+\(b.over)"
        }
        return now.standing < was.standing
            ? String(localized: "new best \u{00B7} was \(mark(was))", comment: "The card: this solve beat the best. The best before")
            : String(localized: "best \u{00B7} \(mark(was))", comment: "The card: this solve didn't beat the best. The best")
    }

    var body: some View {
        let run = game.level.run
        // A pack level's tier is plughole's by default, so a pack takes its own colour first.
        let accent = game.level.pack.map { Offer.pack($0).ink } ?? game.level.tier.ink
        let next = run != nil ? game.nextTank : (game.level.pack?.levels ?? game.level.tier.levels).drop(while: { $0.id != game.level.id }).dropFirst().first
        let up = game.opened ?? (game.level.id == game.level.tier.levels.last?.id ? game.level.tier.step(1) : nil)
        // One primary: an open TierUp's, else next's, else share's; "again" never is.
        let upLeads = up?.isOpen() == true
        let nextLeads = next != nil && !upLeads
        // Marks, the verdict, the facts and what they need said, then the way on: the lines 4 apart, 16 between things.
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                VStack(spacing: 4) {
                    if let run {
                        Group {
                            Text("moves \(game.moves)")
                            if game.spilled && run.tank > run.best {
                                Text("tanks cleared \(run.tank) \u{00B7} ") + Text("new best").foregroundStyle(Color.lime)
                            } else {
                                game.spilled ? Text("tanks cleared \(run.tank) \u{00B7} best \(Best.tanks)",
                                                    comment: "Endless's card, spilled. Tanks cleared, then the best run's")
                                    : Text("tank \(run.tank + 1) \u{00B7} brim \(game.brim) / \(Run.room)",
                                           comment: "Endless's card. The tank, then the brim's notches of its room")
                            }
                        }
                        // The words' colour, not the line's opacity, so "new best" keeps its lime whole.
                        .foregroundStyle(Color.text2)
                    } else {
                        // Escapement has no par, so no marks; nor has the sandbox, where nothing counts.
                        let par = game.level.ratchets.isEmpty
                        if par && !game.level.sandbox {
                            ResultMarks(filled: ResultMarks.filled(clean: game.cleanShown, over: game.over), card: true)
                                .padding(.bottom, 4)
                        }
                        Group {
                            if game.cleanShown {
                                Text("clean").foregroundStyle(page.signal(.lime)).shadow(color: page.glow(.lime), radius: 6)
                            } else if par && game.over == 0 {
                                Text("at par").foregroundStyle(page.signal(.amber))
                            } else {
                                Text("solved")
                            }
                        }
                        .font(.ui(.headline))
                        // Escapement's ticks say nothing: a solve there always spends the budget to the last (Jack's
                        // call EL1, round 11). The tone is on the words, not the line, so the margin keeps its magenta
                        // whole (C11).
                        let quiet = page.ink.opacity(page.tone(.text2).alpha)
                        let facts = par ? Text("moves \(game.moves) \u{00B7} par \(game.par)") : Text("moves \(game.moves)")
                        if par && game.over > 0 {
                            facts.foregroundStyle(quiet) + Text(verbatim: " \u{00B7} ").foregroundStyle(quiet)
                                + Text(verbatim: "+\(game.over)").foregroundStyle(page.signal(.magenta))
                        } else {
                            facts.foregroundStyle(quiet)
                        }
                        if Best.keepsClean(game.level.id) && !game.clean && game.over == 0 {
                            (game.firstTry ? Text("clean needs no undo or reset") : Text("clean counts on the first try"))
                                .font(.ui(.detail)).tone(page.tone(.text3))
                        }
                    }
                    if let b = game.bests, let line = Self.bestLine(was: b.was, now: b.now, par: game.level.ratchets.isEmpty,
                                                                         keepsClean: Best.keepsClean(game.level.id)) {
                        Text(line).tone(.text2) // loc: verbatim localized by bestLine
                    }
                    if let done = game.completed {
                        Text(done.line).tone(page.tone(.text2)).padding(.top, 4) // loc: verbatim localized by Completion
                    }
                }
                .font(.ui(.label))
                // Focus lands on the finish itself: an announcement before a focus move is cut short.
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(game.finishSpoken)
                .accessibilityFocused($focused)
                if let pack = Offer.pointer(after: game.completed) {
                    // Quiet: the card's way on is still next, or up a notch.
                    UnstirButton(.quiet) { onOffer(pack) } label: { Text("try \(pack.name) \u{203A}") }
                        .font(.ui(.detail)).tone(page.tone(.text3))
                        .accessibilityLabel("Try \(pack.name)")
                } else if let pack = packs {
                    UnstirButton(.quiet) { onOffer(pack) } label: { Text("more puzzles in the packs \u{203A}") }
                        .font(.ui(.detail)).tone(page.tone(.text3))
                        .accessibilityLabel("More puzzles in the packs")
                }
            }
            // Wrapped, so a card with none, a clean solve of a list's last level, keeps no gap for the row.
            if game.offersAgain || game.shareText != nil || next != nil {
                ButtonRow {
                    if game.offersAgain {
                        UnstirButton(.secondary, effect: .reset, wide: true, action: again) { Text("again \u{21BA}") }
                            .accessibilityLabel("Again")
                    }
                    if let share = game.shareText {
                        // ShareButton's sheet, through the button's own face.
                        UnstirButton(nextLeads || upLeads ? .secondary : .primary, accent: .amber, wide: true) {
                            ShareSheet.present([share])
                        } label: { Text("share \u{2197}") }
                            .accessibilityLabel("Share result")
                    }
                    if let next {
                        // Past a pack's free taste, unowned, next opens its card: the button says so.
                        let gate = Store.shared.card(for: next)
                        let label = game.spilled ? String(localized: "new run \u{203A}", comment: "Endless's card, spilled: starts another run")
                            : gate.map { String(localized: "more in \($0.name) \u{203A}", comment: "The card's next, past a pack's free levels. The pack") }
                            ?? String(localized: "next \u{203A}", comment: "The card's next level or tank")
                        UnstirButton(nextLeads ? .primary : .secondary, accent: accent, wide: true) { onNext(next) } label: { Text(label) } // loc: verbatim localized here
                            .accessibilityLabel(game.spilled ? Text("New run", comment: "VoiceOver: starts a new endless run") // loc: verbatim each a key
                                                : run != nil ? Text("Next tank", comment: "VoiceOver: endless's card, the next tank")
                                                : Text("Next level", comment: "VoiceOver: the card's next level"))
                    }
                }
            }
            if let day = Share.day(of: game.level.id), !game.level.archived {
                TimelineView(.everyMinute) { t in
                    Text(Daily.untilNext(day: day, now: now ?? t.date)).font(.ui(.detail)).tone(page.tone(.text3)) // loc: verbatim localized by Daily
                        .accessibilityLabel(Daily.untilNext(day: day, now: now ?? t.date, spoken: true)) // loc: verbatim localized by Daily
                }
            }
            if let up {
                TierUp(from: game.level.tier, to: up, onNext: onNext, onLook: onLook)
            }
        }
        // With the play column's own 16, the gutter's 20.
        .padding(.horizontal, 4)
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
/// `RootView` makes it, not the card: a tap on within the wait would take it with the card, for good. Its wait starts as
/// the card shows (`Carded.shown`), never at the solve, so nothing that plays before the card has the request over it.
@MainActor @Observable final class Review {
    static let shared = Review()
    /// The solve that opens whirlpool came this launch, and its card has yet to show.
    var earned = false
    /// That solve's card has shown, or its level was left first, and the request hasn't been made.
    var pending = false
    /// The launch's: a harnessed one, or the test host, never asks, and UNSTIR_REVIEW=log logs the request in place of
    /// making it.
    static var harnessed = false, logs = false
    /// 2 s after the card shows.
    static let wait = 2.0

    func carded() {
        guard earned else { return }
        earned = false
        pending = true
    }

    static func due(opened: Tier?, asked: Bool, harnessed: Bool, purchased: Bool) -> Bool {
        opened == .whirlpool && !asked && !harnessed && !purchased
    }
}

/// What waits for a finish's card to show, so that nothing of the system's lands over the solve or what plays before
/// the card: the rating request's wait, and Game Center's report, whose banner shows over the card (Jack's call
/// G-banner = A). A level left before its card shows them then.
@MainActor enum Carded {
    static func shown() {
        Review.shared.carded()
        GameCenter.shared.report()
    }
}

/// The solve that opens the next tier, and the last level of a tier, go on up the ladder, in the next tier's own
/// colours. A tier still closed shows its sweep behind a lock, unfilled and still, says how many levels are unsolved and opens the menu
/// on its gate, which shows which.
private struct TierUp: View {
    let from: Tier
    let to: Tier
    let onNext: (Level) -> Void
    let onLook: (Tier) -> Void
    @State private var glint = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let open = to.isOpen(), short = from.solved().filter { !$0 }.count
        let shortLine = String(localized: "\(short) \(from.word) levels unsolved",
                               comment: "The card's way up, the next tier shut. Levels unsolved, then their tier")
        // A primary 56 tall in the tier's sweep and glow; closed, unfilled and still.
        Button { open ? onNext(to.levels[0]) : onLook(to) } label: {
            VStack(spacing: 4) {
                (open ? Text("up a notch", comment: "The card's way up to the next tier") : Text(shortLine)) // loc: verbatim a key, or localized here
                    .font(open ? .ui(.eyebrow) : .ui(.detail)).tracking(open ? 2 : 0).textCase(open ? .uppercase : nil).foregroundStyle(Color.text2)
                HStack(spacing: 10) {
                    if !open { Image(systemName: "lock.fill").font(.ui(.label, .semibold)) }
                    Text(to.name.localizedUppercase).font(.ui(.displaySmall)).tracking(4) // loc: verbatim localized by Tier.name
                    Text(verbatim: "\u{203A}").font(.ui(.displaySmall))
                }
                .foregroundStyle(to.sweep)
                .shadow(color: to.glow.opacity(glint ? 0.9 : 0.5), radius: glint ? 16 : 9)
            }
            .padding(.horizontal, 20).padding(.vertical, 6).frame(maxWidth: .infinity, minHeight: ButtonFace.tall)
            .background { if open { Capsule().fill(to.glow.opacity(ButtonFace.fill)) } }
            .overlay {
                Capsule().strokeBorder(to.sweep, lineWidth: 1).shadow(color: open ? to.glow : .clear, radius: glint ? 10 : 5)
            }
            .contentShape(Capsule())
            .modifier(Pressed())
        }
        .buttonStyle(Sounding(presses: true))
        .accessibilityLabel(open ? Text("Up a notch: \(to.name)", comment: "VoiceOver: the card's way up. The next tier") // loc: verbatim each a key
                            : Text("\(to.name), locked. \(shortLine), and solving every one opens it",
                                   comment: "VoiceOver: the card's way up, shut. The next tier, then how many levels are unsolved"))
        .accessibilityHint(open ? Text(verbatim: "") // loc: verbatim each a key
                           : Text("Shows which \(from.name) levels are unsolved", comment: "VoiceOver: the card's way up, shut. The tier below"))
        .onAppear {
            guard !reduceMotion, to.isOpen() else { return }
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
                UnstirButton(.secondary, effect: game.bank == 0 ? .tap : .undo, dim: game.bank == 0, action: undo) {
                    Text("undo \u{00B7} \(game.bank)")
                }
                    .accessibilityLabel("Undo, \(game.bank) left")
                UnstirButton(.primary, accent: page.accent, effect: .reset, action: again) { Text("again \u{203A}") }
                    .accessibilityLabel("Try again")
            }
            if let notice { Text(notice).font(.ui(.label)).tone(.text2).transition(.opacity) } // loc: verbatim localized by TankView
        }
        .onAppear { focused = true }
    }
}
