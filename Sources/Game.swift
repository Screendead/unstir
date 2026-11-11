// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

@MainActor @Observable
final class Game {
    /// A stack entry, and whether a turn of the player's pushed it: any other is one of the scramble's, perhaps changed
    /// since by turns that merged into it. A run's brim and the heal's note read it. An entry merging into another
    /// leaves its mark behind and hands over its tags, First Stir's vignettes, so a pop plays every tag either carried.
    struct Entry: Stacked, Equatable {
        var twist: Twist
        var pushed: Bool
        var tags: Set<Int> = []

        mutating func absorb(_ other: Entry) { tags.formUnion(other.tags) }
    }

    private(set) var level: Level
    private(set) var entries: [Entry]
    var stack: [Twist] { entries.map(\.twist) }
    /// Stirs since the last reset, newest last: turns of one rod in a row are one stir, and undo commits a stir's negation.
    /// A rod stir names the rod the stack names (the slot under the knob turned). A turn of the tank is rod `Game.tank`,
    /// in steps of the layout's symmetry.
    var history: [Twist] { stirs.map(\.twist) }
    /// A stir of `history` and what its undo puts back, as the stir began.
    private struct Stir {
        var twist: Twist
        /// The stack and the clock: a pack's undo puts them back whole.
        let entries: [Entry]
        let clock: Clock
        let heals: Int
        /// Whether the stir before it was open.
        let wasOpen: Bool
    }
    private var stirs: [Stir] = []
    nonisolated static let tank = -1
    /// Whether the next turn of the newest stir's rod joins it. A stir turned back to nothing is gone, and the one before
    /// it stays shut; an undone one is as if never made, so the one before it is open again if it was then.
    private var open = false
    /// The newest stir while the next turn of its rod, or of the tank, would join it.
    var openStir: Twist? { open ? stirs.last?.twist : nil }
    var moves: Int { stirs.count }
    /// The tank's steps clockwise of home, unwrapped, so an undo swings the glass by exactly the stir it takes off.
    var position: Int { stirs.reduce(0) { $1.twist.rod == Game.tank ? $0 + $1.twist.steps : $0 } }
    /// Every commit and undo, for the commit flash: a joined turn leaves `moves` alone.
    private(set) var turns = 0
    /// A reset gives the moves back but costs the clean, and so does an undo.
    private(set) var resets = 0
    private(set) var undos = 0
    private(set) var bank: Int
    /// What the day's refill added as this level opened.
    private(set) var refilled = 0
    /// What the undo control's badge shows: this opening's refill, or one earlier that day whose badge never showed.
    private(set) var badge = 0
    /// No refill's badge has shown before: this one says what it adds.
    let firstRefill: Bool
    /// The day of the bank's last refill, `Best.refill`'s `last`.
    private var refillDay: String?
    /// `Best.trustedNow`'s anchor, which starts afresh where the caller set the bank.
    private var anchor: Best.Anchor?
    /// False when the caller set the bank, which then lasts only as long as this game.
    private let storesBank: Bool
    /// A win the fine pass is still confirming: an undo or reset then would throw it away.
    private var checking = false
    /// Twists that stacked a new entry: the warning haptic.
    private(set) var pushes = 0
    private(set) var seconds = 0
    private(set) var cancels = 0
    private(set) var cancelledRod = 0
    /// Heals since the level opened or was reset, for the heal's rising note: moves that popped one of the scramble's
    /// entries. The heal that solves sounds as the solve, so a heal counts only once the win check has had its say.
    private(set) var heals = 0
    /// The rod and outcome of the newest commit or undo, for the commit flash.
    private(set) var lastCommit: (rod: Int, result: Commit)?
    /// Turns a full stack refused (`Tank.maxStack`), and the knob of the last, which shakes.
    private(set) var refusals = 0
    private(set) var refusedKnob = 0
    /// The tier this solve opened, on whichever level was the last to reach par: the card goes up a notch.
    private(set) var opened: Tier?
    /// What this solve completed, the one that gave the last of a pack's levels, or of the last tier's, a best.
    private(set) var completed: Completion?
    /// The tier this solve finished, the one that gave the last of its levels a best, for its curtain call (`Payoff`).
    private(set) var tierDone: Tier?
    /// The level's best before this solve and this solve's own, for the card's line; nil where nothing is saved.
    private(set) var bests: (was: Best?, now: Best)?
    /// Starts when the opening ends or is skipped; a reset's replay does not restart it. Nil while the app is away, with
    /// the time played before then in `elapsed`.
    private var start: Date?
    private var elapsed: TimeInterval = 0
    /// Away from the front after the clock started: it runs again on coming back.
    private var paused = false
    /// False once an earlier visit committed a move, or after "again" on a solved daily: a daily is then practice, and
    /// nothing else can be clean.
    private(set) var firstTry: Bool
    /// Escapement's demonstration is on the stack: its commits are not the player's, so they try nothing.
    private(set) var demoing = false
    /// The calls that succeeded since the level opened, for its resume (Jack's call C2, round 13); the demonstration's
    /// are not the player's.
    private(set) var actions: [Resume.Action] = []
    /// Inside `Game.resumed`: the line was the player's already, so nothing is spent, logged or saved again.
    private(set) var replaying = false
    /// The replay has a call left after this one, which the try could make only on a tank the fine pass didn't call
    /// solved, or after "again", which deals afresh whatever it called.
    private var replayGoesOn = false
    /// Only a plain launch's level saves its try: never the harness's, the sandbox, a placeholder, a clip or a test.
    let storesResume: Bool
    /// Whether the player has ever turned the tank, on any level: the rim shows how until they have.
    private(set) var tankTurned: Bool
    /// False when the caller set `tankTurned`, which then lasts only as long as this game.
    private let storesTankTurned: Bool
    /// Whether the player has ever stirred with the swirl, on any level: the rim shows how until they have.
    private(set) var swirled: Bool
    /// False when the caller set `swirled`, which then lasts only as long as this game.
    private let storesSwirled: Bool
    /// False under the harness: its bests, started flags and endless's best last only this launch.
    let storesProgress: Bool
    /// The swirl's breath shows what the rim does only until the player has stirred with it once.
    var breathes: Bool { level.layout.swirl != nil && !swirled }
    /// Endless: notches on the brim, carried from tank to tank through the run. A red flash (a push) adds one, which
    /// stays when the stir is turned back; a heal of one of the scramble's own entries settles one, and cancelling the
    /// player's own push does not. Full, it spills the run.
    private(set) var brim: Int
    /// Every change of `brim`, for the rim to play.
    private(set) var brimEvents: [Brim.Event] = []

    /// Escapement's clocks between moves. Every let-go is a move of its own and final: its ticks land with it, and a
    /// grab of the same knob again is the next move (Jack's call E1, round 9).
    struct Clock {
        /// Ticks standing on each clock, by rod, for its ratchet wheel.
        var ticks: [Int: Int] = [:]
        /// Out of ticks: no clock has a tick left to spend and twists are still on the picture, so no move is left.
        var lost = false
        /// The clock whose tick pushed last, and the one that stopped last.
        var pushed: Int?
        var stopped: Int?
    }
    private(set) var escapement = Clock()
    /// Escapement: the newest move's ticks in the order they landed, each clock's with the stack it changed and whether
    /// it pushed, for the view to play them in turn.
    private(set) var tick: [(stack: [Twist], rod: Int, dir: Int, pushed: Bool)] = []
    /// Escapement: whether the newest move's own stir pushed, which then takes the move's one push sound, and when its
    /// ticks landed, the lift they and the solve are timed from.
    private(set) var stirPushed = false
    @ObservationIgnored private(set) var landed = ContinuousClock.now
    /// Escapement: every move's ticks, the newest clock whose tick pushed (where the out-of-ticks stamp goes), and each
    /// clock's stops, as its rod emptied.
    private(set) var tickEvents = 0
    private(set) var tickPushes = 0
    var pushedClock: Int? { escapement.pushed }
    var lastStopped: Int? { escapement.stopped }
    private(set) var clockStops = 0
    private(set) var stops: [Int: Int] = [:]
    var lost: Bool { escapement.lost }
    /// Escapement: each clock's steps the wrong way round, a pushed tick's. Only its own ticks reach a clock, so nothing
    /// ever takes them off.
    func overdue(_ clock: Int) -> Int {
        let dir = level.woundBack.contains(clock) ? -1 : 1
        return stack.filter { $0.rod == clock && $0.steps * dir > 0 }.reduce(0) { $0 + abs($1.steps) }
    }
    /// Escapement: a pushed tick stands on the stack, so no line from here unstirs the tank: the caption says so until
    /// an undo takes it back or the ticks run out (Jack's call C14, round 13).
    var deadTick: Bool { !finished && level.clocks.contains { overdue($0.rod) > 0 } }
    /// With the bank empty undo can't take the tick back, so the words point only at reset (Jack's call, round 13).
    var deadTickWords: String {
        bank == 0 ? String(localized: "That tick can't come back. Reset.", comment: "Escapement: a pushed tick, no undo left")
            : String(localized: "That tick can't come back. Undo, or again.", comment: "Escapement: a pushed tick")
    }
    /// The line under the tank: Escapement's word on a pushed tick, a scene's time, else the level's note.
    var caption: String {
        if deadTick { return deadTickWords }
        #if FIRST_STIR
        if let sceneClock { return sceneClock }
        #endif
        return level.note
    }
    /// Escapement: the ticks clock `clock` has left, its hub's count (Jack's call ES2, round 12). Only its own ticks
    /// change its rod's steps, each by one whether it merges or pushes, so this is what it owed as dealt less its ticks:
    /// nothing needs storing, and undo and reset bring it back with the stack.
    func owed(_ clock: Int) -> Int { level.owed(clock, on: stack) }
    /// Escapement: the ticks left to spend, the header's count: every clock's together.
    var budget: Int { level.budget(on: stack) }
    /// Escapement: whether the clock on `rod` still runs, holding an entry.
    func running(_ rod: Int) -> Bool { entries.contains { $0.twist.rod == rod } }
    /// Escapement: whether the clock on `rod` ticks after the next move: it holds an entry and has a tick left. A clean
    /// line empties its rod exactly as its count reaches 0; after a pushed tick the rod never empties, and the count
    /// stops it.
    func canTick(_ rod: Int) -> Bool { owed(rod) > 0 && running(rod) }

    /// `firstTry`: a resumed try's, as it began; its first move has since marked the level started.
    init(level: Level, tankTurned: Bool? = nil, swirled: Bool? = nil, bank: (undos: Int, refilled: String?)? = nil,
         storesProgress: Bool = true, firstTry: Bool? = nil, storesResume: Bool = false) {
        self.level = level
        self.storesProgress = storesProgress
        self.storesResume = storesResume && !level.sandbox && level.keepsProgress
        entries = Self.dealt(level)
        brim = level.run?.brim ?? 0
        // A best counts as started: iCloud brings bests to a phone where their levels never were (`Sync`).
        self.firstTry = level.run != nil || (firstTry ?? !(Best.started(level.id) || Best.load(level.id) != nil))
        keptOnItsDay = level.archived && Best.load(level.id).map { $0.archived != true } ?? false
        self.tankTurned = tankTurned ?? Best.tankTurned
        storesTankTurned = tankTurned == nil
        self.swirled = swirled ?? Best.swirled
        storesSwirled = swirled == nil
        if let bank {
            self.bank = bank.undos
            refillDay = bank.refilled
        } else {
            self.bank = Best.undos
            refillDay = Best.refilled
            anchor = Best.anchor
        }
        storesBank = bank == nil
        firstRefill = !Best.refillShown
    }

    /// The scramble's entries. In a story each holds back the vignette in its own rod's core, if that core has one.
    nonisolated static func dealt(_ level: Level) -> [Entry] {
        #if FIRST_STIR
        level.scramble.map { Entry(twist: $0, pushed: false, tags: level.story?.vignettes.intersection([$0.rod]) ?? []) }
        #else
        level.scramble.map { Entry(twist: $0, pushed: false) }
        #endif
    }

    /// The story's vignettes played: each once no entry holds it back. A function of the stack alone, so undo and reset
    /// unplay them, and a win the fine pass calls on a stack that only looks solved plays the rest.
    var played: Set<Int> {
        #if FIRST_STIR
        level.story.map { $0.vignettes.subtracting(entries.flatMap(\.tags)) } ?? []
        #else
        []
        #endif
    }

    /// Practice saves nothing. A past daily from the archive plays as any level, unless its day kept a best: that best
    /// stands, so the archive never takes a day off the days running.
    var counts: Bool { level.archived ? !keptOnItsDay : firstTry || !level.id.hasPrefix("daily-") }
    private let keptOnItsDay: Bool

    /// The result card's "again": any finish that isn't clean, but endless's. On the daily it plays as practice (Jack's
    /// call P1 = B, 2026-11-01).
    var offersAgain: Bool { level.run == nil && !clean }

    /// The sandbox starts on the clean picture, so it is never solved, which keeps it from finishing or saving.
    var solved: Bool { stack.isEmpty && !level.sandbox }
    var par: Int { level.par }
    /// Endless has no par.
    var over: Int { level.run == nil ? max(moves - par, 0) : 0 }
    var spilled: Bool { level.run != nil && brim >= Run.room }
    var finished: Bool { solved || spilled || lost }
    var clean: Bool { over == 0 && resets == 0 && undos == 0 && firstTry }

    /// The daily's share line, on its day; nil on any other level.
    var shareText: String? {
        guard !level.archived else { return nil }
        return Share.day(of: level.id).map {
            Share.text(day: $0, moves: moves, par: par, firstTry: firstTry, clean: clean, undos: undos, resets: resets,
                       supporter: Store.shared.bought && Settings.supporter)
        }
    }

    func slot(of knob: Int) -> Int { level.layout.slot(of: knob, at: position) }
    func knob(over slot: Int) -> Int { level.layout.knob(over: slot, at: position) }

    /// A turn of knob `rod`, which stirs whatever fluid the tank has brought under it.
    func commit(rod: Int, steps: Int) {
        guard !finished else { return }
        if !level.ratchets.isEmpty { return clockCommit(knob: rod, steps: steps) }
        let slot = self.slot(of: rod), was = entries, playedWas = played
        // Every entry of the scramble's that pops is a heal, even where an entry that the merge lets fall cancels it.
        var healed = 0
        let result = level.kind(of: rod) != .working ? .refused
            : entries.commit(Entry(twist: Twist(rod: slot, steps: steps), pushed: true), in: level.layout,
                             lenses: level.lenses, masks: level.masks, popped: { if !$0.pushed { healed += 1 } })
        guard result != .refused else {
            log("commit \(Twist(rod: rod, steps: steps)) refused")
            if level.kind(of: rod) == .working { refuse(rod) }
            return
        }
        started()
        if rod == level.layout.swirl, !swirled {
            swirled = true
            if storesSwirled { Best.swirled = true; GameCenter.shared.report() }
        }
        let brimWas = brim
        // Joins by slot: a turn of the tank between two turns of one knob is a stir of its own.
        if open, stirs.last?.twist.rod == slot {
            stirs[stirs.count - 1].twist.steps += steps
            if stirs.last!.twist.steps == 0 { stirs.removeLast(); open = false }
        } else {
            stirs.append(Stir(twist: Twist(rod: slot, steps: steps), entries: was, clock: escapement, heals: heals,
                              wasOpen: open))
            open = true
        }
        lastCommit = (rod, result)
        turns += 1
        if result == .pushed {
            pushes += 1
            if level.run != nil { brim += 1 }
        }
        // The heal ring marks only a commit that pops one of the scramble's entries, and a story's only one that plays
        // a vignette: cancelling the player's own push flashes white, as a merge (Jack's call SND2 = A, round 16).
        let heals = level.isStory ? !played.isSubset(of: playedWas) : healed > 0
        if heals { cancels += 1; cancelledRod = rod }
        settleBrim(healed)
        noteBrim(from: brimWas)
        log("commit \(Twist(rod: rod, steps: steps)) slot=\(slot) \(result) moves=\(moves) pushes=\(pushes) "
            + "\(level.run == nil ? "" : "brim=\(brim) ")stack=\(stack.count) \(stack)")
        record(.turn(knob: rod, steps: steps))
        settle(healed: healed > 0)
    }

    /// Before the settle, whose finish clears the save: a save after it would bring a finished try back.
    private func record(_ action: Resume.Action) {
        guard !demoing else { return }
        actions.append(action)
        Resume.save(self)
    }

    /// A replay's lines would repeat the try's, which the log already holds.
    private func log(_ line: @autoclosure () -> String) {
        if !replaying { Log.write(line()) }
    }

    /// A level counts as tried on its first committed move; a look, a touch or a turn let go where it began, is free
    /// (Jack's call C3, round 13).
    private func started() {
        guard !level.sandbox && level.keepsProgress && !demoing else { return }
        if Best.start(level.id, store: storesProgress) && storesProgress { Sync.shared.saved() }
    }

    private func refuse(_ knob: Int) {
        refusals += 1
        refusedKnob = knob
    }

    private func settleBrim(_ heals: Int) {
        if level.run != nil { brim = max(brim - heals, 0) }
    }

    private func noteBrim(from was: Int) {
        // A replayed change is long over, so the rim opens on it settled.
        if brim != was {
            brimEvents.append(Brim.Event(from: was, to: brim, time: replaying ? 0 : Date.now.timeIntervalSinceReferenceDate))
        }
    }

    /// The tank stir a turn of `steps` would leave open: joined to the open one, a whole turn dropped, and the short way
    /// round, so an undo swings the glass at most half a turn, which is not always back the way it came. 0 is none.
    func tankStir(after steps: Int) -> Int {
        let order = level.layout.order
        var net = (steps + (openStir?.rod == Game.tank ? openStir!.steps : 0)) % order
        if 2 * net > order { net -= order } else if 2 * net <= -order { net += order }
        return net
    }

    /// Turns the glass `steps` of the layout's symmetry clockwise, knobs staying put. It pushes no entry: the stack keeps
    /// naming slots. Turns of the tank in a row are one stir, gone once they net a whole turn.
    func turnTank(_ steps: Int) {
        let order = level.layout.order
        guard !finished, steps % order != 0 else { return }
        started()
        if !tankTurned {
            tankTurned = true
            if storesTankTurned { Best.tankTurned = true; GameCenter.shared.report() }
        }
        let joins = open && stirs.last?.twist.rod == Game.tank
        let net = tankStir(after: steps)
        var stir = joins ? stirs.removeLast()
            : Stir(twist: Twist(rod: Game.tank, steps: 0), entries: entries, clock: escapement, heals: heals, wasOpen: open)
        open = net != 0
        if open {
            stir.twist.steps = net
            stirs.append(stir)
        }
        log("tank \(steps) position=\(position) moves=\(moves)")
        record(.tank(steps))
        settle()
    }

    /// Escapement: a let-go is a move, a commit of its turn and then the clocks' ticks, and it is final: the same knob
    /// turned again is another move with its own ticks (Jack's call E1, round 9).
    private func clockCommit(knob: Int, steps: Int) {
        let slot = self.slot(of: knob)
        var next = entries
        var healed = 0
        let result = level.kind(of: knob) != .working ? .refused
            : next.commit(Entry(twist: Twist(rod: slot, steps: steps), pushed: true), in: level.layout, lenses: level.lenses,
                          masks: level.masks, popped: { if !$0.pushed { healed += 1 } })
        // A full stack refuses a tick as it would a push, so it refuses the move.
        guard result != .refused, !ticksRefused(next) else {
            log("commit \(Twist(rod: knob, steps: steps)) refused")
            if level.kind(of: knob) == .working { refuse(knob) }
            return
        }
        started()
        stirs.append(Stir(twist: Twist(rod: slot, steps: steps), entries: entries, clock: escapement, heals: heals,
                          wasOpen: open))
        entries = next
        // Final, so no later turn joins it.
        open = false
        lastCommit = (knob, result)
        turns += 1
        if result == .pushed { pushes += 1 }
        stirPushed = result == .pushed
        // The move's own heal: a tick's pop is the clock's, not the knob's.
        if healed > 0 { cancels += 1; cancelledRod = knob }
        healed += landTicks()
        log("commit \(Twist(rod: knob, steps: steps)) \(result) moves=\(moves) stack=\(stack)\(lost ? " lost" : "")")
        record(.turn(knob: knob, steps: steps))
        settle(healed: healed > 0)
    }

    /// Escapement's waiting move, a tap on any ratchet: it only ticks the clocks. Once every clock has stopped there is
    /// nothing to wait for. False when refused.
    @discardableResult func wait(on ratchet: Int) -> Bool {
        guard !finished, level.kind(of: ratchet) == .ratchet, level.clocks.contains(where: { canTick($0.rod) }) else { return false }
        guard !ticksRefused(entries) else { log("wait refused"); refuse(ratchet); return false }
        started()
        stirs.append(Stir(twist: Twist(rod: slot(of: ratchet), steps: 1), entries: entries, clock: escapement, heals: heals,
                          wasOpen: open))
        open = false
        lastCommit = (ratchet, .reduced)
        turns += 1
        stirPushed = false
        let healed = landTicks()
        log("wait moves=\(moves) stack=\(stack)\(lost ? " lost" : "")")
        record(.wait(ratchet: ratchet))
        settle(healed: healed > 0)
        return true
    }

    /// Escapement: after a move, each clock with a tick left that still holds an entry as its turn comes ticks its step,
    /// clockwise from twelve, so one clock's tick can uncover the next's seam on the same move, and spends one of its
    /// own count. A tick that pushes buries an entry no continuation pops, but the tank plays on (Jack's call EL1, round
    /// 11); a clock stops once its count is spent (ES2, round 12), and once none can tick with twists still on the
    /// picture, the tank is out of ticks. It returns how many of the scramble's entries the ticks popped.
    @discardableResult private func landTicks() -> Int {
        tick = []
        var healed = 0
        for c in level.clocks where owed(c.rod) > 0 {
            let from = stack
            guard let result = Self.tick(&entries, on: c, in: level, popped: { if !$0.pushed { healed += 1 } }),
                  result != .refused else { continue }
            escapement.ticks[c.rod, default: 0] += 1
            tick.append((from, c.rod, c.dir, result == .pushed))
            if result == .pushed {
                tickPushes += 1
                escapement.pushed = c.rod
            }
            if owed(c.rod) == 0 {
                clockStops += 1
                stops[c.rod, default: 0] += 1
                escapement.stopped = c.rod
            }
        }
        guard !tick.isEmpty else { return healed }
        landed = .now
        tickEvents += 1
        // Without a pushed tick each clock's count is spent exactly as its rod empties. A stack the fine pass is about to
        // call solved is not out of ticks.
        if !entries.isEmpty, !level.clocks.contains(where: { canTick($0.rod) }),
           !level.layout.same(stack, [], at: Tank.samples, within: Tank.halfPixel, lenses: level.lenses, masks: level.masks) {
            escapement.lost = true
        }
        log("ticks \(tick.map { "\($0.rod):\($0.dir > 0 ? "+" : "-")" }.joined(separator: ",")) budget=\(budget) stack=\(stack)")
        return healed
    }

    /// Escapement: clock `clock`'s step through the ordinary commit, or nil while its rod holds no entry and it stands
    /// stopped.
    nonisolated static func tick(_ entries: inout [Entry], on clock: (rod: Int, dir: Int), in level: Level,
                                 popped: (Entry) -> Void = { _ in }) -> Commit? {
        guard entries.contains(where: { $0.twist.rod == clock.rod }) else { return nil }
        return entries.commit(Entry(twist: Twist(rod: clock.rod, steps: clock.dir), pushed: true), in: level.layout,
                              lenses: level.lenses, masks: level.masks, popped: popped)
    }

    /// Escapement: whether a full stack would refuse a tick after a move that leaves `entries`.
    private func ticksRefused(_ entries: [Entry]) -> Bool {
        var copy = entries
        for c in level.clocks where level.owed(c.rod, on: copy.map(\.twist)) > 0 {
            if Self.tick(&copy, on: c, in: level) == .refused { return true }
        }
        return false
    }

    /// Escapement: the opening's demonstration plays on a stack of its own, through the real rules.
    func demo(_ stack: [Twist]) {
        entries = stack.map { Entry(twist: $0, pushed: false) }
        demoing = true
        restart()
    }

    /// Escapement: back to the level's own scramble once the demonstration is over, as if nothing had been played.
    func endDemo() {
        entries = Self.dealt(level)
        demoing = false
        restart()
        start = nil
        elapsed = 0
        paused = false
    }

    private func restart() {
        stirs = []
        heals = 0
        open = false
        escapement = Clock()
        tick = []
    }

    /// Endless has none: it would take back a red flash. A pack's puts the stack back as the stir found it, marks, tags
    /// and the clock's tick and all; elsewhere it commits the stir's negation.
    func undo() {
        // The sandbox counts nothing, so its undos are free, and a replayed one was paid for when it was made. A lost
        // tank can be undone.
        guard !solved, !spilled, !checking, level.run == nil, level.sandbox || bank > 0 || replaying,
              let was = stirs.popLast() else { return }
        let last = was.twist
        heals = was.heals
        if level.pack != nil || !level.ratchets.isEmpty {
            entries = was.entries
            escapement = was.clock
            tick = []
        } else if last.rod != Game.tank {
            // What the negation brings back of the scramble's is the scramble's again, so taking it off once more heals.
            let scrambles = { (e: [Entry]) in e.filter { !$0.pushed }.count }
            let negation = Twist(rod: last.rod, steps: -last.steps)
            entries.commit(Entry(twist: negation, pushed: scrambles(was.entries) <= scrambles(entries)), in: level.layout,
                           lenses: level.lenses, masks: level.masks)
        }
        if last.rod != Game.tank {
            // A white flash whatever the stack did: undo bumps neither pushes nor cancels, so no alarm or thunk may show.
            lastCommit = (knob(over: last.rod), .reduced)
            turns += 1
        }
        open = was.wasOpen
        if !level.sandbox { undos += 1 }
        if !level.sandbox && !replaying {
            bank -= 1
            if storesBank { Best.undos = bank }
            Analytics.shared.undid()
        }
        log("undo \(last) moves=\(moves) bank=\(bank) pushes=\(pushes) stack=\(stack.count) \(stack)")
        record(.undo)
        settle()
    }

    /// False when refused, so the caller skips the opening replay. Endless has none: it would bring back entries the brim
    /// has already settled on. With nothing played it only replays the opening, so it costs no clean.
    @discardableResult func reset() -> Bool {
        guard !checking, level.run == nil else { return false }
        let played = !stirs.isEmpty
        if played { resets += 1 }
        // The daily counts only its first try's solve, so "again" from its card is practice.
        if solved && Share.day(of: level.id) != nil && !level.archived {
            firstTry = false
            bests = nil
        }
        entries = Self.dealt(level)
        restart()
        log("reset resets=\(resets) pushes=\(pushes) stack=\(stack.count) \(stack)")
        // One with nothing played changes nothing a replay needs.
        if played { record(.reset) }
        return true
    }

    func startClock(at now: Date = .now) { if !paused { start = start ?? now } }

    /// The level's clock stops while the app is away from the front, so a call or a night away never lands in a best.
    func pauseClock(at now: Date = .now) {
        guard let start else { return }
        elapsed += now.timeIntervalSince(start)
        self.start = nil
        paused = true
    }

    func resumeClock(at now: Date = .now) {
        guard paused else { return }
        paused = false
        start = now
    }

    /// Seconds played: from the opening's end, less any time away.
    func played(at now: Date = .now) -> TimeInterval { elapsed + (start.map { now.timeIntervalSince($0) } ?? 0) }

    /// The day's refill of the bank (`Best.refill`), as the level opens on `today`. The sandbox and endless spend no
    /// undos, so they take no refill.
    func refill(today: String) {
        guard !level.sandbox, level.run == nil else { return }
        let added = Best.refill(&bank, last: &refillDay, today: today)
        if storesBank {
            Best.undos = bank
            Best.refilled = refillDay
        }
        guard let added else {
            if storesBank, refillDay == today { badge = Best.unseenRefill }
            return
        }
        refilled = added
        badge = added
        if storesBank { Best.unseenRefill = added }
        Log.write("undo refill +\(added) bank=\(bank)")
    }

    /// The refill's badge has shown.
    func refillSeen() {
        guard storesBank, badge > 0 else { return }
        Best.unseenRefill = 0
        Best.refillShown = true
    }

    /// The day's refill as the level opens with the clocks read as given: the day is `Best.trustedNow`'s, in `zone`.
    func refill(wall: Date = .now, uptime: TimeInterval = Best.uptime(), boot: String? = Best.bootSession,
                zone: TimeZone = .current) {
        guard !level.sandbox, level.run == nil else { return }
        let (now, ahead) = Best.trustedNow(wall: wall, uptime: uptime, boot: boot, anchor: &anchor)
        if storesBank { Best.anchor = anchor }
        let today = Best.day(now, in: zone)
        if let ahead, let last = refillDay, today <= last, Best.day(wall, in: zone) > last {
            Log.write(String(format: "undo refill held: clock ahead %.1fh", ahead / 3600))
        }
        refill(today: today)
    }

    /// Endless: the next tank, with the brim as this one left it, or a new run's first once the brim has spilled.
    var nextTank: Level? {
        level.run.map {
            .endless(spilled ? Run(seed: .random(in: .min ... .max))
                     : Run(seed: $0.seed, tank: $0.tank + 1, brim: brim, best: $0.best))
        }
    }

    /// Sandbox: the stir stays, to be seen on the next picture.
    func nextPicture() {
        level.picture = level.picture.next
        Log.write("picture \(level.picture)")
    }

    /// Sandbox: twists name rods, so new rods start on the clean picture.
    func nextLayout() {
        // A swirl layout has no place in allCases, so it steps on from its base.
        level.layout = (level.layout.base ?? level.layout).next
        level.scramble = []
        // The rings parked on the last commit and cancel may name a rod the new layout lacks.
        lastCommit = nil
        cancelledRod = 0
        Log.write("layout \(level.layout)")
        reset()
    }

    /// The newest twist a working knob can take off now, as that knob's turn: what autoplay and the harness play.
    var reachable: Twist? {
        level.layout.removable(stack, lenses: level.lenses, masks: level.masks).reversed().map { Twist(rod: knob(over: stack[$0].rod), steps: -stack[$0].steps) }
            .first { level.kind(of: $0.rod) == .working }
    }

    /// A knob's two-step turn that would push a new entry, a red flash: what the harness's brim demo wastes.
    var wasting: Twist? {
        level.layout.rods.indices.filter { level.kind(of: $0) == .working }.lazy.compactMap { k -> Twist? in
            var s = self.stack
            return s.commit(rod: self.slot(of: k), steps: 2, in: self.level.layout, lenses: self.level.lenses, masks: self.level.masks) == .pushed ? Twist(rod: k, steps: 2) : nil
        }.first
    }

    /// `healed`: the move that led here healed one of the scramble's entries.
    private func settle(healed: Bool = false) {
        // Refusing a win the picture already shows is the bug players hit, and a residual under half a pixel is invisible.
        // Only the coarse pass runs here: the fine one takes ~0.1 s exactly when it passes, which would hitch the win.
        if !spilled && !entries.isEmpty && level.layout.same(stack, [], at: Tank.samples, within: Tank.halfPixel, lenses: level.lenses, masks: level.masks) {
            let stack = stack, layout = level.layout, lenses = level.lenses, masks = level.masks
            // A replay has no frame to hitch, and only its last call can have left the answer unknown.
            if replaying { return confirm(!replayGoesOn && layout.looksSolved(stack, lenses: lenses, masks: masks), healed: healed) }
            checking = true
            Task {
                let solved = await Task.detached(priority: .userInitiated) { layout.looksSolved(stack, lenses: lenses, masks: masks) }.value
                self.checking = false
                // A move made meanwhile settled itself.
                guard self.stack == stack else { return }
                self.confirm(solved, healed: healed)
            }
            return
        }
        finish(healed: healed)
    }

    /// The fine pass's answer on a stack that looks solved.
    private func confirm(_ solved: Bool, healed: Bool) {
        if solved {
            log("looks solved \(stack)")
            // The tank's last heal, where the move that made it healed none of the scramble's entries itself.
            if !healed && entries.contains(where: { !$0.pushed }) {
                let was = brim
                settleBrim(1)
                noteBrim(from: was)
            }
            // A story's vignettes left play with the solve wave, which rings for them.
            entries = []
        }
        finish(healed: healed)
    }

    /// Every level of this level's pack, or of the last tier, has a best. A pack short of its plan isn't complete: its
    /// card still promises the rest.
    private var completion: Completion? {
        if let p = level.pack, p.levels.count < p.planned { return nil }
        let (list, done): ([Level], Completion) = if let p = level.pack { (p.levels, .pack(p)) } else {
            (Tier.allCases.last!.levels, .free)
        }
        guard list.contains(where: { $0.id == level.id }), list.allSatisfy({ Best.load($0.id) != nil }) else { return nil }
        return done
    }

    /// Every level of this level's tier has a best.
    private var wholeTier: Tier? {
        guard level.pack == nil, level.tier.levels.contains(where: { $0.id == level.id }),
              level.tier.levels.allSatisfy({ Best.load($0.id) != nil }) else { return nil }
        return level.tier
    }

    private func finish(healed: Bool) {
        if healed && !finished { heals += 1 }
        guard finished else { return }
        seconds = Int(played())
        log("\(solved ? "solved" : lost ? "lost" : "spilled") \(level.id) moves=\(moves) "
            + "\(level.run == nil ? "par=\(par)" : "brim=\(brim)") seconds=\(seconds) counts=\(counts)")
        if let run = level.run {
            if solved && storesProgress {
                Best.tanks = max(Best.tanks, run.tank + 1)
                Sync.shared.saved()
            }
            if spilled && storesProgress { Best.spilled = true }
        } else if solved && counts && level.keepsProgress {
            let up = level.pack == nil ? level.tier.step(1) : nil, shut = up.map { !$0.isOpen() } ?? false
            let best = Best(over: over, seconds: seconds, clean: clean, archived: level.archived ? true : nil)
            bests = (Best.load(level.id), best)
            let done = completion, whole = wholeTier
            best.save(level.id, store: storesProgress)
            if storesProgress { Sync.shared.saved() }
            if shut, let up, up.isOpen() {
                opened = up
                if up == .whirlpool { Review.shared.earned = true }
            }
            completed = done == nil ? completion : nil
            tierDone = whole == nil ? wholeTier : nil
        }
        // A replay passes through a lost tank its line then undid; `resumed` closes one that ends solved or spilled.
        guard !replaying else { return }
        close()
        Analytics.shared.finished(self)
    }

    /// A solve or a spill clears the try's save. A tank out of ticks keeps it, its losing move too, which `record` passed
    /// over as the move finished the try, so a back swipe off the lost card loses nothing: the level reopens on it, its
    /// undo still live, until again or a solve clears it (Jack's call, 2026-11-01, on C19). A cleared tank of a run saves
    /// the next one, empty, so the run outlasts the card.
    private func close() {
        guard storesResume else { return }
        if lost {
            Resume.save(Resume(of: self))
        } else if solved, let next = nextTank, let run = next.run {
            Resume.save(Resume(id: next.id, print: next.print, firstTry: true, run: run))
        } else {
            Resume.remove(level.id)
        }
    }

    /// The try `r` saved, replayed through the calls that made it, before any view shows it: nil, and the level opens
    /// afresh, where `r` was saved on a level that deals differently now, where the level refuses one of its calls, or
    /// where the line solved or spilled, as when the app died inside the solving move's fine pass, whose best its finish
    /// saves. A line that ends out of ticks opens on its lost card. The bank, the stored flags and the analytics stay as
    /// the try left them: the loss was counted as it happened.
    static func resumed(_ level: Level, from r: Resume, tankTurned: Bool? = nil, swirled: Bool? = nil,
                        bank: (undos: Int, refilled: String?)? = nil, storesProgress: Bool = true,
                        storesResume: Bool = true) -> Game? {
        guard r.version == 1, r.id == level.id, r.print == level.print else {
            Log.write("resume \(r.id) dropped: the level deals differently now")
            return nil
        }
        let game = Game(level: level, tankTurned: tankTurned, swirled: swirled, bank: bank, storesProgress: storesProgress,
                        firstTry: r.firstTry, storesResume: storesResume)
        game.replaying = true
        // Before the line, whose last call may finish the try and save its best with the time played.
        game.elapsed = r.seconds
        for (i, action) in r.actions.enumerated() {
            game.replayGoesOn = i + 1 < r.actions.count
            switch action {
            case .turn(let knob, let steps): game.commit(rod: knob, steps: steps)
            case .tank(let steps): game.turnTank(steps)
            case .wait(let ratchet): game.wait(on: ratchet)
            case .undo: game.undo()
            case .reset: game.reset()
            }
            guard game.actions.count == i + 1 else {
                Log.write("resume \(r.id) dropped: \(action), its call \(i + 1), refused")
                return nil
            }
        }
        game.replaying = false
        // The newest move's ticks are long played.
        game.tick = []
        Log.write("resume \(r.id) actions=\(r.actions.count) moves=\(game.moves) stack=\(game.stack.count) \(game.stack)")
        guard !game.finished || game.lost else {
            game.close()
            return nil
        }
        return game
    }
}
