// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreHaptics
import SwiftUI
import simd

extension Color {
    init(_ hex: UInt32) {
        self.init(red: Double(hex >> 16 & 0xFF) / 255, green: Double(hex >> 8 & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }

    static let text = Color(0xEDEFF7)
    /// SwiftUI already has a `cyan`.
    static let neonCyan = Color(0x00F0FF)
    static let magenta = Color(0xFF2BD6)
    static let amber = Color(0xFFB000)
    static let lime = Color(0x7CFF4F)
    static let blood = Color(0xFF1438)
    static let violet = Color(0x9A2CFF)
    static let alarm = Color(0xFF3B6B)
    /// Escapement's clock, from the packs mock-up's plate, lifted to read on black.
    static let vermilion = Color(0xFF5A36)
    /// The grid never uses white, so the live ring cannot be mistaken for a line.
    static let live = Color(0xF2F4FA)
}

extension Font {
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

extension CaseIterable where Self: Equatable, AllCases == [Self] {
    /// The first case follows the last.
    var next: Self {
        let all = Self.allCases
        return all[(all.firstIndex(of: self)! + 1) % all.count]
    }
}

/// The chrome bezel just outside glass of radius `r`.
struct Bezel: View {
    let r: CGFloat
    @Environment(\.displayScale) private var scale
    private static let chrome = AngularGradient(stops: [(0, 0x2A2E37), (0.139, 0x8C94A6), (0.333, 0x282C34), (0.486, 0x5A6272),
                                                        (0.653, 0x16181E), (0.833, 0xAEB6C6), (1, 0x2A2E37)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }, center: .center)

    var body: some View {
        ZStack {
            Circle().strokeBorder(Self.chrome, lineWidth: 0.045 * r).padding(-0.045 * r)
            Circle().strokeBorder(Color.white.opacity(0.35), lineWidth: 1 / scale).padding(-1 / scale)
        }
    }
}

private func glowRing(_ colour: Color, _ width: CGFloat, _ underlay: CGFloat, under: Color? = nil) -> some View {
    ZStack {
        Circle().stroke(under ?? colour.opacity(0.22), lineWidth: underlay)
        Circle().stroke(colour, lineWidth: width)
    }
}

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
    private(set) var history: [Twist] = []
    /// The stack and the clock as each stir of `history` began: a pack's undo puts them back whole.
    private var before: [(entries: [Entry], clock: Clock)] = []
    nonisolated static let tank = -1
    /// Whether the next turn of the newest stir's rod joins it. A stir turned back to nothing is gone, and the one before
    /// it stays shut; an undone one is as if never made, so the one before it is open again if it was then.
    private var open = false
    /// For each stir in `history`, whether the one before it was open when it began.
    private var openBefore: [Bool] = []
    /// The newest stir while the next turn of its rod, or of the tank, would join it.
    var openStir: Twist? { open ? history.last : nil }
    var moves: Int { history.count }
    /// The tank's steps clockwise of home, unwrapped, so an undo swings the glass by exactly the stir it takes off.
    var position: Int { history.reduce(0) { $1.rod == Game.tank ? $0 + $1.steps : $0 } }
    /// Every commit and undo, for the commit flash: a joined turn leaves `moves` alone.
    private(set) var turns = 0
    /// A reset gives the moves back but costs the clean, and so does an undo.
    private(set) var resets = 0
    private(set) var undos = 0
    private(set) var bank: Int
    /// What the day's refill added as this level opened, for the undo control to show.
    private(set) var refilled = 0
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
    /// `heals` as each stir of `history` began.
    private var healsBefore: [Int] = []
    /// Whether an undo takes back the heals its stir made: temporary, for Jack to hear both (`Sound.stepsHealsBack`).
    var stepsHealsBack = Sound.stepsHealsBack
    /// The rod and outcome of the newest commit or undo, for the commit flash.
    private(set) var lastCommit: (rod: Int, result: Commit)?
    /// Starts when the opening ends or is skipped; a reset's replay does not restart it.
    private var start: Date?
    /// False once an earlier visit touched a rod: a daily is then practice, and nothing else can be clean.
    let firstTry: Bool
    /// Whether the player has ever turned the tank, on any level: the rim shows how until they have.
    private(set) var tankTurned: Bool
    /// False when the caller set `tankTurned`, which then lasts only as long as this game.
    private let storesTankTurned: Bool
    /// Whether the player has ever stirred with the swirl, on any level: the rim shows how until they have.
    private(set) var swirled: Bool
    /// False when the caller set `swirled`, which then lasts only as long as this game.
    private let storesSwirled: Bool
    /// The swirl's breath shows what the rim does only until the player has stirred with it once.
    var breathes: Bool { level.layout.swirl != nil && !swirled }
    /// Endless: notches on the brim, carried from tank to tank through the run. A red flash (a push) adds one, which
    /// stays when the stir is turned back; a heal of one of the scramble's own entries settles one, and cancelling the
    /// player's own push does not. Full, it spills the run.
    private(set) var brim: Int
    /// Every change of `brim`, for the rim to play.
    private(set) var brimEvents: [Brim.Event] = []

    /// Escapement's clock between moves. Every let-go is a move of its own and final: its tick lands with it, and a
    /// grab of the same knob again is the next move (Jack's call E1, round 9).
    struct Clock {
        /// Ticks standing, for the ratchet wheel.
        var ticks = 0
        /// A tick pushed, so the stack can never empty, or the clock stopped with twists still on the picture (Jack's
        /// call E2, round 9).
        var lost = false
    }
    private(set) var escapement = Clock()
    /// Escapement: the stack the latest tick changed, for the view to play the tick over it.
    private(set) var tick: [Twist]?
    /// Escapement: every tick, every one that pushed (the ratchet's red flash), and every one that emptied the clock
    /// rod, which then stops.
    private(set) var tickEvents = 0
    private(set) var tickPushes = 0
    private(set) var clockStops = 0
    var lost: Bool { escapement.lost }
    /// Escapement: the clock rod's positive steps. Only +1 ticks reach the clock, so no tick ever takes them off.
    var overdue: Int { stack.filter { $0.rod == level.clock && $0.steps > 0 }.reduce(0) { $0 + $1.steps } }

    init(level: Level, tankTurned: Bool? = nil, swirled: Bool? = nil, bank: (undos: Int, refilled: String?)? = nil) {
        self.level = level
        entries = Self.dealt(level)
        brim = level.run?.brim ?? 0
        firstTry = level.run != nil || !Best.started(level.id)
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
    }

    /// The scramble's entries. In a story each holds back the vignette in its own rod's core, if that core has one.
    private static func dealt(_ level: Level) -> [Entry] {
        level.scramble.map { Entry(twist: $0, pushed: false, tags: level.story?.vignettes.intersection([$0.rod]) ?? []) }
    }

    /// The story's vignettes played: each once no entry holds it back. A function of the stack alone, so undo and reset
    /// unplay them, and a win the fine pass calls on a stack that only looks solved plays the rest.
    var played: Set<Int> {
        level.story.map { $0.vignettes.subtracting(entries.flatMap(\.tags)) } ?? []
    }

    /// Practice saves nothing.
    var counts: Bool { firstTry || !level.id.hasPrefix("daily-") }

    /// The sandbox starts on the clean picture, so it is never solved, which keeps it from finishing or saving.
    var solved: Bool { stack.isEmpty && !level.sandbox }
    var par: Int { level.par }
    /// Endless has no par.
    var over: Int { level.run == nil ? max(moves - par, 0) : 0 }
    var spilled: Bool { level.run != nil && brim >= Run.room }
    var finished: Bool { solved || spilled || lost }
    var clean: Bool { over == 0 && resets == 0 && undos == 0 && firstTry }

    /// What each move did to the stack, oldest first: read once the level has settled, since the fine pass may empty the
    /// stack after the last move.
    var marks: [Share.Mark] {
        history.indices.map { i in
            let size = before[i].entries.count, after = i + 1 < before.count ? before[i + 1].entries.count : entries.count
            return history[i].rod == Game.tank ? .tank : after < size ? .healed : after > size ? .pushed : .merged
        }
    }

    /// The daily's share line; nil on any other level.
    var shareText: String? {
        Share.day(of: level.id).map {
            Share.text(day: $0, moves: moves, par: par, firstTry: firstTry, clean: clean, undos: undos, resets: resets,
                       marks: marks)
        }
    }

    func slot(of knob: Int) -> Int { level.layout.slot(of: knob, at: position) }
    func knob(over slot: Int) -> Int { level.layout.knob(over: slot, at: position) }

    /// A turn of knob `rod`, which stirs whatever fluid the tank has brought under it.
    func commit(rod: Int, steps: Int) {
        guard !finished else { return }
        if level.clock != nil { return clockCommit(knob: rod, steps: steps) }
        let slot = self.slot(of: rod), was = entries, playedWas = played
        // Every entry of the scramble's that pops is a heal, even where an entry that the merge lets fall cancels it.
        var healed = 0
        let result = level.kind(of: rod) != .working ? .refused
            : entries.commit(Entry(twist: Twist(rod: slot, steps: steps), pushed: true), in: level.layout,
                             lenses: level.lenses, popped: { if !$0.pushed { healed += 1 } })
        guard result != .refused else { Log.write("commit \(Twist(rod: rod, steps: steps)) refused"); return }
        if rod == level.layout.swirl, !swirled {
            swirled = true
            if storesSwirled { Best.swirled = true }
        }
        let brimWas = brim
        // Joins by slot: a turn of the tank between two turns of one knob is a stir of its own.
        if open, history.last?.rod == slot {
            history[history.count - 1].steps += steps
            if history.last!.steps == 0 {
                history.removeLast(); openBefore.removeLast(); before.removeLast(); healsBefore.removeLast(); open = false
            }
        } else {
            history.append(Twist(rod: slot, steps: steps))
            openBefore.append(open)
            before.append((was, escapement))
            healsBefore.append(heals)
            open = true
        }
        lastCommit = (rod, result)
        turns += 1
        if result == .pushed {
            pushes += 1
            if level.run != nil { brim += 1 }
        }
        // A run's heal ring marks only what settles the brim, and a story's only a commit that plays a vignette:
        // cancelling the player's own push flashes white, as a merge.
        let heals = level.story != nil ? !played.isSubset(of: playedWas) : level.run == nil ? result == .cancelled : healed > 0
        if heals { cancels += 1; cancelledRod = rod }
        settleBrim(healed)
        noteBrim(from: brimWas)
        Log.write("commit \(Twist(rod: rod, steps: steps)) slot=\(slot) \(result) moves=\(moves) pushes=\(pushes) "
                  + "\(level.run == nil ? "" : "brim=\(brim) ")stack=\(stack.count) \(stack)")
        settle(healed: healed > 0)
    }

    private func settleBrim(_ heals: Int) {
        if level.run != nil { brim = max(brim - heals, 0) }
    }

    private func noteBrim(from was: Int) {
        if brim != was { brimEvents.append(Brim.Event(from: was, to: brim, time: Date.now.timeIntervalSinceReferenceDate)) }
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
        if !tankTurned {
            tankTurned = true
            if storesTankTurned { Best.tankTurned = true }
        }
        let joins = open && history.last?.rod == Game.tank
        let net = tankStir(after: steps)
        let wasOpen = joins ? openBefore.removeLast() : open
        let was = joins ? before.removeLast() : (entries, escapement)
        let healsWere = joins ? healsBefore.removeLast() : heals
        if joins { history.removeLast() }
        open = net != 0
        if open {
            history.append(Twist(rod: Game.tank, steps: net))
            openBefore.append(wasOpen)
            before.append(was)
            healsBefore.append(healsWere)
        }
        Log.write("tank \(steps) position=\(position) moves=\(moves)")
        settle()
    }

    /// Escapement: a let-go is a move, a commit of its turn and then the clock's tick, and it is final: the same knob
    /// turned again is another move with its own tick (Jack's call E1, round 9). A tick that pushes loses at once.
    private func clockCommit(knob: Int, steps: Int) {
        let slot = self.slot(of: knob)
        var next = entries
        var healed = 0
        let result = level.kind(of: knob) != .working ? .refused
            : next.commit(Entry(twist: Twist(rod: slot, steps: steps), pushed: true), in: level.layout, lenses: level.lenses,
                          popped: { if !$0.pushed { healed += 1 } })
        // A full stack refuses the tick as it would a push, so it refuses the move.
        guard result != .refused, !tickRefused(next) else {
            Log.write("commit \(Twist(rod: knob, steps: steps)) refused")
            return
        }
        before.append((entries, escapement))
        healsBefore.append(heals)
        openBefore.append(open)
        history.append(Twist(rod: slot, steps: steps))
        entries = next
        // Final, so no later turn joins it.
        open = false
        lastCommit = (knob, result)
        turns += 1
        if result == .pushed { pushes += 1 }
        if result == .cancelled { cancels += 1; cancelledRod = knob }
        healed += landTick()
        Log.write("commit \(Twist(rod: knob, steps: steps)) \(result) moves=\(moves) stack=\(stack)\(lost ? " lost" : "")")
        settle(healed: healed > 0)
    }

    /// Escapement's waiting move, a tap on the ratchet: it only ticks. Once the clock has stopped there is nothing to
    /// wait for.
    func wait(on ratchet: Int) {
        guard !finished, let e = level.clock, slot(of: ratchet) == e, entries.contains(where: { $0.twist.rod == e })
        else { return }
        guard !tickRefused(entries) else { Log.write("wait refused"); return }
        before.append((entries, escapement))
        healsBefore.append(heals)
        openBefore.append(open)
        history.append(Twist(rod: e, steps: 1))
        open = false
        lastCommit = (ratchet, .reduced)
        turns += 1
        let healed = landTick()
        Log.write("wait moves=\(moves) stack=\(stack)\(lost ? " lost" : "")")
        settle(healed: healed > 0)
    }

    /// Escapement: the clock's tick after a move, while the clock rod holds an entry. It loses the tank if it pushes, or
    /// if it stops the clock with twists still on the picture. It returns how many of the scramble's entries it popped.
    @discardableResult private func landTick() -> Int {
        guard let e = level.clock, entries.contains(where: { $0.twist.rod == e }) else { return 0 }
        let from = stack
        var healed = 0
        let result = entries.commit(Entry(twist: Twist(rod: e, steps: 1), pushed: true), in: level.layout, lenses: level.lenses,
                                    popped: { if !$0.pushed { healed += 1 } })
        guard result != .refused else { return 0 }
        escapement.ticks += 1
        tick = from
        tickEvents += 1
        if result == .pushed { tickPushes += 1; escapement.lost = true }
        if !entries.contains(where: { $0.twist.rod == e }) {
            clockStops += 1
            if !entries.isEmpty { escapement.lost = true }
        }
        Log.write("tick \(result) stack=\(stack)")
        return healed
    }

    /// Escapement: whether a full stack would refuse the tick after a move that leaves `entries`.
    private func tickRefused(_ entries: [Entry]) -> Bool {
        guard let e = level.clock, entries.contains(where: { $0.twist.rod == e }) else { return false }
        var copy = entries
        return copy.commit(Entry(twist: Twist(rod: e, steps: 1), pushed: true), in: level.layout, lenses: level.lenses) == .refused
    }

    /// Escapement: the opening's demonstration plays on a stack of its own, through the real rules.
    func demo(_ stack: [Twist]) {
        entries = stack.map { Entry(twist: $0, pushed: false) }
        restart()
    }

    /// Escapement: back to the level's own scramble once the demonstration is over, as if nothing had been played.
    func endDemo() {
        entries = Self.dealt(level)
        restart()
        start = nil
    }

    private func restart() {
        history = []
        openBefore = []
        before = []
        healsBefore = []
        heals = 0
        open = false
        escapement = Clock()
        tick = nil
    }

    /// Endless has none: it would take back a red flash. A pack's puts the stack back as the stir found it, marks, tags
    /// and the clock's tick and all; elsewhere it commits the stir's negation.
    func undo() {
        // The sandbox counts nothing, so its undos are free. A lost tank can be undone.
        guard !solved, !spilled, !checking, level.run == nil, level.sandbox || bank > 0, let last = history.popLast()
        else { return }
        let was = before.removeLast()
        let healsWere = healsBefore.removeLast()
        if stepsHealsBack { heals = healsWere }
        if level.pack != nil || level.clock != nil {
            entries = was.entries
            escapement = was.clock
            tick = nil
        } else if last.rod != Game.tank {
            // What the negation brings back of the scramble's is the scramble's again, so taking it off once more heals.
            let scrambles = { (e: [Entry]) in e.filter { !$0.pushed }.count }
            let negation = Twist(rod: last.rod, steps: -last.steps)
            entries.commit(Entry(twist: negation, pushed: scrambles(was.entries) <= scrambles(entries)), in: level.layout,
                           lenses: level.lenses)
        }
        if last.rod != Game.tank {
            // A white flash whatever the stack did: undo bumps neither pushes nor cancels, so no alarm or thunk may show.
            lastCommit = (knob(over: last.rod), .reduced)
            turns += 1
        }
        open = openBefore.removeLast()
        if !level.sandbox {
            undos += 1
            bank -= 1
            if storesBank { Best.undos = bank }
            Analytics.shared.undid()
        }
        Log.write("undo \(last) moves=\(moves) bank=\(bank) pushes=\(pushes) stack=\(stack.count) \(stack)")
        settle()
    }

    /// False when refused, so the caller skips the opening replay. Endless has none: it would bring back entries the brim
    /// has already settled on.
    @discardableResult func reset() -> Bool {
        guard !checking, level.run == nil else { return false }
        entries = Self.dealt(level)
        restart()
        resets += 1
        Log.write("reset resets=\(resets) pushes=\(pushes) stack=\(stack.count) \(stack)")
        return true
    }

    func startClock() { start = start ?? .now }

    /// The day's refill of the bank (`Best.refill`), as the level opens on `today`. The sandbox and endless spend no
    /// undos, so they take no refill.
    func refill(today: String) {
        guard !level.sandbox, level.run == nil else { return }
        let added = Best.refill(&bank, last: &refillDay, today: today)
        if storesBank {
            Best.undos = bank
            Best.refilled = refillDay
        }
        guard let added else { return }
        refilled = added
        Log.write("undo refill +\(added) bank=\(bank)")
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
            .endless(spilled ? Run(seed: .random(in: .min ... .max)) : Run(seed: $0.seed, tank: $0.tank + 1, brim: brim))
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
        level.layout.removable(stack, lenses: level.lenses).reversed().map { Twist(rod: knob(over: stack[$0].rod), steps: -stack[$0].steps) }
            .first { level.kind(of: $0.rod) == .working }
    }

    /// A knob's two-step turn that would push a new entry, a red flash: what the harness's brim demo wastes.
    var wasting: Twist? {
        level.layout.rods.indices.filter { level.kind(of: $0) == .working }.lazy.compactMap { k -> Twist? in
            var s = self.stack
            return s.commit(rod: self.slot(of: k), steps: 2, in: self.level.layout, lenses: self.level.lenses) == .pushed ? Twist(rod: k, steps: 2) : nil
        }.first
    }

    /// `healed`: the move that led here healed one of the scramble's entries.
    private func settle(healed: Bool = false) {
        // Refusing a win the picture already shows is the bug players hit, and a residual under half a pixel is invisible.
        // Only the coarse pass runs here: the fine one takes ~0.1 s exactly when it passes, which would hitch the win.
        if !spilled && !entries.isEmpty && level.layout.same(stack, [], at: Tank.samples, within: Tank.halfPixel, lenses: level.lenses) {
            let stack = stack, layout = level.layout, lenses = level.lenses
            checking = true
            Task {
                let solved = await Task.detached(priority: .userInitiated) { layout.looksSolved(stack, lenses: lenses) }.value
                self.checking = false
                // A move made meanwhile settled itself.
                guard self.stack == stack else { return }
                if solved {
                    Log.write("looks solved \(stack)")
                    // The tank's last heal, where the move that made it healed none of the scramble's entries itself.
                    if !healed && self.entries.contains(where: { !$0.pushed }) {
                        let was = self.brim
                        self.settleBrim(1)
                        self.noteBrim(from: was)
                    }
                    // A story's vignettes left play with the solve wave, which rings for them.
                    self.entries = []
                }
                self.finish(healed: healed)
            }
            return
        }
        finish(healed: healed)
    }

    private func finish(healed: Bool) {
        if healed && !finished { heals += 1 }
        guard finished else { return }
        seconds = Int(Date.now.timeIntervalSince(start ?? .now))
        Log.write("\(solved ? "solved" : lost ? "lost" : "spilled") \(level.id) moves=\(moves) "
                  + "\(level.run == nil ? "par=\(par)" : "brim=\(brim)") seconds=\(seconds) counts=\(counts)")
        if let run = level.run {
            if solved { Best.tanks = max(Best.tanks, run.tank + 1) }
        } else if solved && counts && level.keepsProgress {
            Best(over: over, seconds: seconds, clean: clean).save(level.id)
        }
        Analytics.shared.finished(self)
    }
}

/// What a finger on the tank holds.
enum Grab: Equatable {
    case rod(Int)
    case rim
    /// A seized knob's disc, or a socket's: it holds nothing, and the knob shakes.
    case seized(Int)
    /// A ratchet's disc: it holds nothing, and a tap waits.
    case ratchet(Int)
    case nothing
}

struct LevelView: View {
    @State private var game: Game
    @State private var liveRod: Int?
    @State private var liveAngle = 0.0
    /// The tank's turn in hand, in radians clockwise, while a finger holds the rim; nil when it is not held.
    @State private var liveTurn: Double?
    /// Two fingers' twist, on top of `liveTurn`.
    @GestureState private var spin: Double?
    /// The two-finger twist has the tank, and only its own onEnded lets go: `spin` may reset before that folds the twist
    /// into `liveTurn`, and the finger's drag may end on either side of it.
    @State private var spun = false
    /// Solved, the glass eases to the nearest home: the level ends wherever the tank stands.
    @State private var eased: Bool
    /// Scales every committed angle; the open winds it 0 to 1, all rods at once, so it shows nothing about order.
    @State private var wind = 1.0
    /// The touch it belongs to, what it holds, and the finger's last angle about that.
    @State private var drag: (start: CGPoint, grab: Grab, last: Double)?
    /// Where the finger has been since it landed, timed from when the drag was taken up, and what it held there, for
    /// the log's one line when the drag ends.
    @State private var path: (grab: Grab, down: Date, trail: Trail<SIMD2<Double>>)?
    /// A two-finger twist's rotation since it began, logged when it ends.
    @State private var twist: (down: Date, trail: Trail<Double>)?
    /// The finger's latest point in tank units, kept after it lifts so a count left showing stays put.
    @State private var finger: SIMD2<Double>?
    /// UNSTIR_FINGER: the fingertip drawn down where it landed, and what it turns about (the tank's centre for the rim
    /// and the swirl).
    @State private var ghost: (at: SIMD2<Double>, pivot: SIMD2<Double>, rim: Bool)?
    /// The knob, or `Game.tank`, touched last: its open stir's count stays up, faint, after letting go.
    @State private var counted: Int?
    @State private var grabs = 0
    /// The seized knob touched last, and every such touch: it shakes, the rim pulses and a thud plays.
    @State private var jammed: Int?
    @State private var jams = 0
    /// Escapement: a finger is on the ratchet.
    @State private var pressing = false
    /// Escapement: the demonstration of the clock is playing, before the problem winds in.
    @State private var demoing = false
    /// Escapement: the tank dips to black between the demonstration and the problem, so the problem's clean opening
    /// frame never reads as the demonstration solved.
    @State private var demoDip = 0.0
    @State private var detent = Detent(step: Tank.step)
    @State private var ticks = 0
    @State private var tankTicks = 0
    @State private var settling = false
    @State private var showResult: Bool
    /// Scramble entries on screen during the opening; nil once the tank is the player's.
    @State private var shown: Int?
    @State private var replays = 0
    /// The day's refill as the badge shows it: set once the opening is over, and only once, so a reset's opening doesn't
    /// show it again.
    @State private var badge = 0
    @State private var snap = CGSize.zero
    @Environment(\.displayScale) private var scale
    @Environment(\.scenePhase) private var phase
    private let still: Bool
    private let autoplay: Bool
    /// UNSTIR_PACE: the seconds autoplay and UNSTIR_MOVES wait before each move.
    private let pace: Double
    /// UNSTIR_BARE: the picture drawn unstirred, as the stack has played it.
    private let bare: Bool
    private let moves: [Twist]?
    private let fingered: Bool
    private let bench: Bool
    /// UNSTIR_WAVE: the solve wave held at this radius.
    private let frozenWave: Double?
    /// UNSTIR_CLOCK: a live background, and the rim's ghost finger, held at this many seconds.
    private let frozenClock: Double?
    /// UNSTIR_SHAKE: a seized knob's shake and the rim's pulse held this many seconds in.
    private let frozenShake: Double?
    /// UNSTIR_TODAY: the day the level opens on, for the bank's refill.
    private let today: String?
    /// UNSTIR_BREATH: the swirl's breath held this many seconds into the tank's first rest.
    private let frozenBreath: Double?
    /// UNSTIR_REST: seconds at rest before a drawn fingertip lands.
    private let rest: Double
    /// The swirl's breath while the tank rests, and the last one a touch, the opening or the win cut, fading out.
    @State private var breath: Breath?
    @State private var faded: Breath?
    /// Either moves the picture now: the picture's timeline runs only then.
    @State private var breathing = false
    /// Something has been let go since the opening, so the next rest waits longer.
    @State private var lifted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// A live picture: its clock starts at zero on every visit.
    @State private var opened = Date.now
    /// Endless: the picture's colours round the rim as the stack stirs it (Brim.colours), once worked out.
    @State private var rimColours: (hue: [Float], lines: [Float])?
    /// Endless: the brim changed lately enough that the rim is still moving.
    @State private var brimMoving = false
    /// The picture has landed and struck.
    @State private var struck = false
    private let brimDemo: Bool
    private let shareSheet: Bool
    let onExit: () -> Void
    let onNext: (Level) -> Void

    init(level: Level, harness: Harness?, onExit: @escaping () -> Void, onNext: @escaping (Level) -> Void) {
        let game = Game(level: level, tankTurned: harness?.tankTurned, swirled: harness?.swirled, bank: harness?.bank)
        game.turnTank(harness?.tank ?? 0)
        if let h = harness, h.screen == "result" || h.screen == "clean" || h.wave != nil {
            // Solved through the real commit path; "result" first wastes two stirs, so taking them back costs moves.
            if h.screen == "result", let top = game.stack.last {
                let count = level.layout.rods.count, home = game.knob(over: top.rod)
                let wrong = (1..<count).map { (home + $0) % count }.filter { level.kind(of: $0) == .working }
                if let w = wrong.first {
                    game.commit(rod: w, steps: 2)
                    game.commit(rod: wrong[1 % wrong.count], steps: 1)
                }
            }
            // A seized knob's twists come off once a turn of the tank brings them under a working one; a tank no turn
            // helps is left as it is.
            var idle = 0
            while !game.finished, idle < level.layout.order {
                if let t = game.reachable { game.commit(rod: t.rod, steps: t.steps); idle = 0 } else { game.turnTank(1); idle += 1 }
            }
        }
        if let t = harness?.turned { game.commit(rod: t.rod, steps: t.steps) }
        for m in harness?.played ?? [] {
            if level.kind(of: m.rod) == .ratchet { game.wait(on: m.rod) } else { game.commit(rod: m.rod, steps: m.steps) }
        }
        _game = State(initialValue: game)
        let live = harness?.live, angle = (live?.steps ?? 0) * Tank.step, turn = harness?.tankLive.map { $0 * .pi / 180 }
        _liveRod = State(initialValue: live?.rod)
        _liveAngle = State(initialValue: angle)
        _liveTurn = State(initialValue: turn)
        _counted = State(initialValue: harness?.turned?.rod)
        if let p = harness?.touch {
            // The finger that went down at p, carried round with the turn it holds.
            let grab: Grab = live.map { .rod($0.rod) } ?? (turn != nil ? .rim : LevelView.grab(level.layout, motion: level.motion, kind: level.kind(of:), at: p))
            let pivot = live.map { SIMD2(level.layout.rods[$0.rod].x, level.layout.rods[$0.rod].y) } ?? .zero
            let a = live != nil ? angle : turn ?? 0, d = p - pivot
            _drag = State(initialValue: (.zero, grab, 0))
            _finger = State(initialValue: pivot + SIMD2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a)))
            switch grab {
            case .rod(let k): _liveRod = State(initialValue: k); _counted = State(initialValue: k)
            case .rim: _liveTurn = State(initialValue: turn ?? 0); _counted = State(initialValue: Game.tank)
            case .seized(let k), .ratchet(let k): _jammed = State(initialValue: k)
            case .nothing: break
            }
        }
        // A spill's card waits for the pour, so a harness launch that spills shows it only if held past then.
        _showResult = State(initialValue: game.finished && harness?.wave == nil
                            && (!game.spilled || (harness?.clock ?? 0) >= Brim.card))
        _eased = State(initialValue: game.solved)
        still = harness?.still ?? false
        autoplay = harness?.autoplay ?? false
        pace = harness?.pace ?? 0.3
        bare = harness?.bare ?? false
        moves = harness?.moves
        fingered = harness?.finger ?? false
        brimDemo = harness?.brimDemo ?? false
        shareSheet = harness?.shareSheet ?? false
        bench = harness?.bench ?? false
        frozenWave = harness?.wave
        frozenClock = harness?.clock
        frozenShake = harness?.shake
        today = harness?.today
        frozenBreath = harness?.breath
        rest = harness?.rest ?? 2
        _shown = State(initialValue: still || level.sandbox ? nil : 0)
        self.onExit = onExit
        self.onNext = onNext
    }

    var body: some View {
        GeometryReader { geo in
            // The rim sits outside the glass, 0.045 of the radius on each side.
            let side = min(geo.size.width, geo.size.height - 290) / 1.045
            VStack(spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Button("\u{2039} levels", action: leave)
                    Spacer()
                    if game.level.sandbox {
                        control(game.level.picture.rawValue, game.nextPicture)
                        // A turn in hand, or snapping to commit, names a rod of the current layout.
                        control(game.level.layout.rawValue) { if liveRod == nil { game.nextLayout() } }
                    } else {
                        // Endless has no par; its brim is on the rim.
                        Text(game.level.run == nil ? "moves \(game.moves) / par \(game.par)" : "moves \(game.moves)")
                            // On black the wasted-twist alarm reads at full contrast, whatever the picture shows.
                            .keyframeAnimator(initialValue: 0.0, trigger: game.pushes) { text, t in
                                text.foregroundStyle(t > 0.5 ? Color.alarm : Color.text)
                            } keyframes: { _ in
                                // Red for 0.4 s. A trailing MoveKeyframe never lands, so the ramp ends the flash.
                                MoveKeyframe(1.0)
                                LinearKeyframe(0.0, duration: 0.8)
                            }
                            .opacity(showResult ? 0 : 1)
                    }
                }
                .font(.mono(13))
                .padding(.top, 8)
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(game.level.label).foregroundStyle(game.level.colour).shadow(color: game.level.colour, radius: 4)
                    // Endless's tank beside its name, where it can't read as the brim's count.
                    Text(game.level.title + (game.level.run.map { ", tank \($0.tank + 1)" } ?? ""))
                }
                .font(.mono(15, .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
                Spacer(minLength: 12)
                let reveal = AnyTransition.opacity.animation(.easeOut(duration: 0.4).delay(0.3))
                tank(side)
                    .overlay(alignment: .top) {
                        // A spill says so over the tank itself.
                        if showResult && game.solved {
                            Text("unstirred.").font(.mono(22, .semibold))
                                .shadow(color: .white.opacity(0.5), radius: 6)
                                .offset(y: -62)
                                .transition(reveal)
                        }
                    }
                // The play controls fade rather than leave, and the result is an overlay, so the solved tank stays
                // exactly where it was played.
                Text(demoing ? "tap to skip" : shown == nil ? game.counts ? game.level.note : "Practice: only the first try counts."
                     : game.level.replay ? "watch the stir \u{00B7} tap to skip" : "tap to skip")
                    .font(.mono(12)).opacity(showResult ? 0 : 0.55).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .top)
                    .padding(.top, 14)
                    .overlay(alignment: .top) {
                        if showResult && game.lost {
                            LostCard(game: game, onExit: leave, again: { if game.reset() { replays += 1 } })
                                .padding(.top, 14)
                                .transition(reveal)
                        } else if showResult {
                            ResultCard(game: game, onExit: leave, onNext: onNext)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 14)
                                .transition(reveal)
                        }
                    }
                Spacer(minLength: 12)
                HStack {
                    // Only a turn of the tank swings back: animated, a rod's undo would glide the stack's shader floats too.
                    control(game.level.sandbox ? "undo" : "undo \u{00B7} \(game.bank)") {
                        withAnimation(game.history.last?.rod == Game.tank ? .snappy(duration: 0.3) : nil) { game.undo() }
                    }
                        // With nothing to take back it does nothing, so it only taps.
                        .buttonStyle(Sounding(effect: game.history.isEmpty ? .tap : .undo))
                        // The plain button style does not grey a disabled label.
                        .disabled(!game.level.sandbox && game.bank == 0)
                        .opacity(!game.level.sandbox && game.bank == 0 ? 0.35 : 1)
                        .overlay(alignment: .topTrailing) { refillBadge }
                    Spacer()
                    control("reset") { if game.reset() { replays += 1 } }
                        .buttonStyle(Sounding(effect: .reset))
                }
                // Endless has neither (`Game.undo`, `Game.reset`); hidden rather than gone, so its tank sits where every
                // other level's does.
                .disabled(settling || game.finished || shown != nil || demoing || game.level.run != nil)
                .opacity(showResult || game.level.run != nil ? 0 : 1)
                .accessibilityHidden(game.level.run != nil)
                .padding(.bottom, 8)
            }
        }
        .foregroundStyle(Color.text)
        .tint(Color.text)
        .padding(.horizontal, 16)
        .background(Color.black)
        .task(id: replays) {
            if !game.level.demo.isEmpty && replays == 0 && !still { await clockDemo() }
            if !game.level.sandbox, replays > 0 || !still { await open() }
            if autoplay && replays == 0 { await play() }
            if let moves, replays == 0 { await play(moves) }
            if brimDemo && replays == 0 { await demo() }
        }
        .task(id: game.stack) {
            guard game.level.run != nil else { return }
            let stack = game.stack, layout = game.level.layout, turn = Double(game.position) * layout.tankStep
            let colours = await Task.detached(priority: .userInitiated) { Brim.colours(stack, layout: layout, turn: turn) }.value
            // A later stack's may already have landed.
            guard !Task.isCancelled else { return }
            rimColours = colours
        }
        .task(id: game.brimEvents.count) {
            guard let last = game.brimEvents.last, frozenClock == nil else { return }
            brimMoving = true
            let spill = last.to >= Run.room
            let left = (spill ? Brim.spillSettle : Brim.settle) - (Date.now.timeIntervalSinceReferenceDate - last.time)
            guard (try? await Task.sleep(for: .seconds(max(left, 0)))) != nil else { return }
            brimMoving = false
        }
        .task {
            // A launch that spilled before the view appeared has no change of `finished` to bring the card.
            guard game.spilled, !showResult, frozenClock == nil, let last = game.brimEvents.last else { return }
            let left = Brim.card - (Date.now.timeIntervalSinceReferenceDate - last.time)
            guard (try? await Task.sleep(for: .seconds(max(left, 0)))) != nil else { return }
            withAnimation(.easeIn(duration: 0.3)) { showResult = true }
        }
        .task {
            guard shareSheet, let text = game.shareText, (try? await Task.sleep(for: .seconds(1))) != nil,
                  let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?
                      .rootViewController else { return }
            root.present(UIActivityViewController(activityItems: [text], applicationActivities: nil), animated: false)
        }
        .task {
            // Past the picture's first render, so the bake does not land in the numbers.
            guard bench, (try? await Task.sleep(for: .seconds(1))) != nil else { return }
            Bench(drive: { liveRod = 0; liveAngle = 3 * sin(2 * $0) },
                  still: game.level.picture.isLive ? { liveRod = nil; liveAngle = 0 } : nil).start()
        }
        .onChange(of: shown == nil, initial: true) {
            // The clock's demonstration is not the player's tank.
            guard !demoing else { return }
            if shown == nil { game.startClock(); badge = game.refilled } else { lifted = false }
        }
        .onChange(of: touching) { if touching && shown == nil { lifted = true } }
        .onChange(of: resting, initial: true) {
            let t = Date.now.timeIntervalSinceReferenceDate
            if resting {
                breath = Breath(start: t, wait: lifted ? Breath.later : Breath.first)
            } else if var b = breath {
                b.cut = t
                faded = b
                breath = nil
            }
        }
        .task(id: [breath, faded]) {
            while true {
                let t = Date.now.timeIntervalSinceReferenceDate
                let motion = [breath, faded].compactMap { $0?.motion(at: t) }
                breathing = motion.contains { $0.moving }
                guard let next = motion.compactMap(\.until).min(),
                      (try? await Task.sleep(for: .seconds(max(next - t, 0.001)))) != nil else { return }
            }
        }
        .onChange(of: game.finished) {
            // An undo or reset from the lost card.
            guard game.finished else { showResult = false; return }
            // The fine pass can call the win ~0.1 s after the commit: a finger down in that gap would hold its turn frozen
            // over the win, then have the commit refused on lift.
            endPath(); endTwist()
            drag = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; spun = false
            // Its own transaction: an animated one also glides every shader argument that changed with the win, the wave's
            // centre among them.
            if game.solved { withAnimation(.easeInOut(duration: 0.9)) { eased = true } }
            Task {
                // A spill's card waits for the pour and the word; a lost clock's for its stamp.
                try? await Task.sleep(for: .seconds(game.spilled ? Brim.card : game.lost ? 0.7 : 1.4))
                guard game.finished else { return }
                withAnimation(.easeIn(duration: 0.3)) { showResult = true }
                Log.write("result shown")
            }
        }
        // SwiftUI never calls onEnded for a cancelled drag (lock, Siri, a call), so drop the uncommitted turn here. Only on
        // the way out: the launch's own turn to active would drop a finger the harness holds.
        .onChange(of: phase) {
            guard phase != .active else { return }
            endPath(); endTwist()
            if drag != nil || spun {
                Log.write("\(phase) drops drag \(state)"); drag = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; spun = false
            }
        }
        .onAppear {
            let rules = game.level.run.map { "tank \($0.tank) brim \($0.brim)" } ?? "par \(game.par)"
            let pack = game.level.pack.map { p in
                " \(p.rawValue) \(Store.shared.state(p)), \(Store.shared.access(game.level).map { "\($0)" } ?? "")"
            } ?? ""
            Log.write("level \(game.level.id) opens, \(rules)\(pack) \(game.stack)")
            // Not in Game.init: SwiftUI reruns LevelView.init for a level it already shows, on a game it then drops.
            if let today { game.refill(today: today) } else { game.refill() }
            // Where there is no opening, onChange's initial call may run before the refill.
            if shown == nil { badge = game.refilled }
        }
        .onChange(of: phase) {
            if phase == .background { Analytics.shared.suspended(game) }
            if phase == .active { Analytics.shared.resumed() }
        }
        .onDisappear { endPath(); endTwist(); Log.write("level \(game.level.id) exits \(state)") }
    }

    /// Back to the menu, the only way out short of a finish or the next tank.
    private func leave() {
        Analytics.shared.left(game)
        onExit()
    }

    /// Everything that decides what the tank draws, as the log shows it.
    private var state: String {
        "shown=\(Log.opt(shown)) wind=\(wind) live=\(Log.opt(liveRod)) angle=\(liveAngle) turn=\(liveTurn.map { "\($0)" } ?? "nil") "
            + "drag=\(drag.map { "\($0.grab)" } ?? "nil") settling=\(settling) position=\(game.position) "
            + "moves=\(game.moves) pushes=\(game.pushes) stack=\(game.stack.count) \(game.stack)"
    }

    private var stack: [Twist] { shown.map { Array(game.stack.prefix($0)) } ?? game.stack }
    /// A finger, two, or a drawn fingertip is on the tank, or a turn is still settling from one.
    private var touching: Bool { drag != nil || liveRod != nil || liveTurn != nil || spun || ghost != nil }
    /// The tank is the player's and untouched, and the game breathes: its breath may run. Never under Reduce Motion,
    /// and never in a harness launch that holds the clock.
    private var resting: Bool {
        game.breathes && !reduceMotion && frozenClock == nil && frozenBreath == nil && shown == nil
            && !game.finished && !touching
    }
    /// The swirl's breath on the picture now, in radians.
    private var breathAngle: Double {
        if let frozenBreath { return game.breathes ? Breath(start: 0, wait: Breath.first).angle(at: frozenBreath) : 0 }
        guard breathing else { return 0 }
        let t = Date.now.timeIntervalSinceReferenceDate
        return (breath?.angle(at: t) ?? 0) + (faded?.angle(at: t) ?? 0)
    }
    private var rods: [SIMD3<Double>] { game.level.layout.rods }
    /// The rods with a knob: all but a swirl, which is held from the rim.
    private var knobs: [Int] { rods.indices.filter { $0 != game.level.layout.swirl } }
    private func centre(_ k: Int) -> SIMD2<Double> { SIMD2(rods[k].x, rods[k].y) }

    /// Replay levels play the scramble forward from the clean picture, so the last rod seen turning is the top of the
    /// stack. The rest wind every twist in together from the clean picture.
    private func open() async {
        Log.write("open starts \(state)")
        defer { Log.write("open ends\(Task.isCancelled ? ", cancelled" : "") \(state)") }
        let scramble = game.stack
        // A reset can land while a finger holds the rim.
        endPath(); endTwist()
        shown = 0; liveRod = nil; liveAngle = 0; drag = nil; liveTurn = nil; spun = false
        if !game.level.replay { wind = 0; shown = scramble.count }
        defer { if demoDip > 0 { withAnimation(.easeOut(duration: 0.3)) { demoDip = 0 } } }
        guard await pause(demoDip > 0 ? 0.3 : 1) else { return }
        if demoDip > 0 { withAnimation(.easeInOut(duration: 1.4)) { demoDip = 0 } }
        if game.level.replay {
            for (i, t) in scramble.enumerated() {
                let d = 0.12 * Double(abs(t.steps))
                liveRod = game.knob(over: t.rod)
                withAnimation(.easeInOut(duration: d)) { liveAngle = Double(t.steps) * Tank.step }
                guard await pause(d) else { return }
                shown = i + 1; liveRod = nil; liveAngle = 0
                // Lets liveAngle render at 0 before the next rod animates from it.
                guard await pause(0.15) else { return }
            }
        } else {
            withAnimation(.easeInOut(duration: 1.4)) { wind = 1 }
            guard await pause(1.4) else { return }
        }
        shown = nil
    }

    /// False once the opening is skipped or replaced.
    private func pause(_ seconds: Double) async -> Bool {
        (try? await Task.sleep(for: .seconds(seconds))) != nil && shown != nil
    }

    /// UNSTIR_AUTOPLAY: turns each right twist in view, or the tank a step when none is under a working knob, then lets go
    /// through the same path as a finger.
    private func play() async {
        while !game.finished {
            let t = game.reachable
            guard (try? await Task.sleep(for: .seconds(pace))) != nil else { return }
            if let t {
                liveRod = t.rod
                withAnimation(.easeInOut(duration: 0.4)) { liveAngle = Double(t.steps) * Tank.step }
            } else {
                liveTurn = 0
                withAnimation(.easeInOut(duration: 0.4)) { liveTurn = game.level.layout.tankStep }
            }
            guard (try? await Task.sleep(for: .seconds(0.4))) != nil else { return }
            if let t { release(t.rod) } else { releaseTank() }
        }
    }

    /// UNSTIR_MOVES: a given line, at autoplay's pace and through the same releases.
    private func play(_ moves: [Twist]) async {
        if fingered { await hand(moves); return }
        for m in moves {
            guard (try? await Task.sleep(for: .seconds(pace))) != nil, !game.finished else { return }
            if game.level.kind(of: m.rod) == .ratchet {
                game.wait(on: m.rod)
                continue
            }
            if m.rod == Game.tank {
                liveTurn = 0
                withAnimation(.easeInOut(duration: 0.4)) { liveTurn = Double(m.steps) * game.level.layout.tankStep }
            } else {
                liveRod = m.rod
                withAnimation(.easeInOut(duration: 0.4)) { liveAngle = Double(m.steps) * Tank.step }
            }
            guard (try? await Task.sleep(for: .seconds(0.4))) != nil else { return }
            if m.rod == Game.tank { releaseTank() } else { release(m.rod) }
        }
    }

    /// UNSTIR_FINGER: the line at a hand's pace, after a rest to read the tank untouched: each fingertip lands, holds a
    /// beat, turns at about a step a tenth of a second and lifts, and the next waits for the heal or push to show.
    private func hand(_ moves: [Twist]) async {
        guard (try? await Task.sleep(for: .seconds(rest))) != nil else { return }
        for m in moves {
            guard !game.finished, await fingertip(m, while: { !game.finished }),
                  (try? await Task.sleep(for: .seconds(1.0))) != nil else { return }
        }
    }

    /// One move by a drawn fingertip, through the calls a finger makes: it lands where `grab` gives it the move's rod or
    /// the rim, holds a beat, rides the turn round and lifts; on a ratchet it taps. False once `going` fails.
    private func fingertip(_ m: Twist, while going: @escaping () -> Bool) async -> Bool {
        func pause(_ s: Double) async -> Bool { (try? await Task.sleep(for: .seconds(s))) != nil && going() }
        let level = game.level, layout = level.layout, both = layout.swirl != nil && level.motion != .none
        if level.kind(of: m.rod) == .ratchet {
            withAnimation(.easeOut(duration: 0.12)) { ghost = (centre(m.rod), centre(m.rod), false) }
            finger = centre(m.rod)
            guard await pause(0.45) else { return false }
            pressing = true
            guard await pause(0.18) else { return false }
            pressing = false
            game.wait(on: m.rod)
            // Gone before the tick lands, or the fingertip hides the ratchet turning.
            withAnimation(.easeOut(duration: 0.12)) { ghost = nil }
            return true
        }
        let rim = m.rod == Game.tank, swirl = m.rod == layout.swirl
        // The tank's up and left, the swirl's up and right, so the two read apart where both share the rim; a knob's
        // halfway out its disc.
        let at: SIMD2<Double> = rim ? 1.04 * SIMD2(-0.7071, -0.7071)
            : swirl ? (both ? 0.93 : 0.99) * SIMD2(0.7071, -0.7071)
            : centre(m.rod) + 0.5 * rods[m.rod].z * SIMD2(0.7071, -0.7071)
        let grab = Self.grab(layout, motion: level.motion, kind: level.kind(of:), at: at)
        if grab != (rim ? .rim : .rod(m.rod)) { Log.write("finger at \(Log.point(at)) holds \(grab), not \(m)") }
        withAnimation(.easeOut(duration: 0.12)) { ghost = (at, rim || swirl ? .zero : centre(m.rod), rim) }
        finger = at
        guard await pause(0.45) else { return false }
        let d = rim ? 0.45 * Double(abs(m.steps)) + 0.2 : 0.1 * Double(abs(m.steps)) + 0.25
        if rim {
            liveTurn = 0
            withAnimation(.easeInOut(duration: d)) { liveTurn = Double(m.steps) * layout.tankStep }
        } else {
            liveRod = m.rod; counted = m.rod
            withAnimation(.easeInOut(duration: d)) { liveAngle = Double(m.steps) * Tank.step }
        }
        guard await pause(d + 0.25) else { return false }
        withAnimation(.easeIn(duration: 0.12)) { ghost = nil }
        if rim { releaseTank() } else { release(m.rod) }
        return true
    }

    /// Escapement, before the first stir: a fingertip shows the clock working on the level's demonstration stack. Each
    /// heal hands the clock its seam and it ticks; a tap on the ratchet waits, and it ticks again. Then the tank dips to
    /// black and the problem winds in. A tap skips it.
    private func clockDemo() async {
        guard let e = game.level.clock else { return }
        demoing = true
        shown = nil
        game.demo(game.level.demo)
        Log.write("demo starts \(state)")
        let going = { demoing }
        func pause(_ s: Double) async -> Bool { (try? await Task.sleep(for: .seconds(s))) != nil && going() }
        var on = await pause(1.4)
        while on, let t = game.reachable {
            on = await fingertip(t, while: going)
            if on { on = await pause(0.9) }
        }
        if on, await fingertip(Twist(rod: e, steps: 1), while: going) { _ = await pause(1.6) }
        while settling { try? await Task.sleep(for: .seconds(0.05)) }
        withAnimation(.easeOut(duration: 0.2)) { ghost = nil }
        drag = nil; liveRod = nil; liveAngle = 0; pressing = false; counted = nil
        withAnimation(.easeIn(duration: 0.35)) { demoDip = 1 }
        try? await Task.sleep(for: .seconds(0.4))
        game.endDemo()
        demoing = false
        Log.write("demo ends \(state)")
    }

    /// UNSTIR_BRIMDEMO: the approved film's run of the brim, through the same path as a finger: two heals, then pushes
    /// until it spills, each let go at the film's time (plus a second for the picture to land).
    private func demo() async {
        let start = Date.now
        for (i, at) in [0.75, 1.35, 2.25, 2.80, 3.35, 3.90, 5.25].enumerated() {
            let lead = at + 1.0 - 0.62 - Date.now.timeIntervalSince(start)
            guard (try? await Task.sleep(for: .seconds(max(lead, 0)))) != nil, !game.finished,
                  let t = i < 2 ? game.reachable : game.wasting else { return }
            liveRod = t.rod
            withAnimation(.easeInOut(duration: 0.4)) { liveAngle = Double(t.steps) * Tank.step }
            guard (try? await Task.sleep(for: .seconds(0.4))) != nil else { return }
            release(t.rod)
        }
    }

    /// The day's refill, over the undo control's count once the opening is over and the control live. Always present, to
    /// see `badge` change.
    private var refillBadge: some View {
        KeyframeAnimator(initialValue: Self.refillTime, trigger: badge) { s in
            Text("+\(badge)").font(.mono(13)).foregroundStyle(Color.lime)
                .opacity(badge > 0 ? Self.refillShown(frozenClock ?? s) : 0)
        } keyframes: { _ in
            MoveKeyframe(0.0)
            LinearKeyframe(Self.refillTime, duration: Self.refillTime)
        }
        // Its trailing edge on the count's, just above the capsule.
        .offset(x: -22, y: -24)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Seconds from a refill until its count has gone.
    nonisolated private static let refillTime = 3.0

    /// The refill's count `s` seconds after the opening ends, or after the level opens where it has none: up after a
    /// beat, gone by `refillTime`.
    nonisolated static func refillShown(_ s: Double) -> Double {
        s < 0.3 ? 0 : s < 0.6 ? (s - 0.3) / 0.3 : s < 2.3 ? 1 : max(0, (refillTime - s) / (refillTime - 2.3))
    }

    private func control(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).font(.mono(15)).padding(.horizontal, 22).padding(.vertical, 10)
                .background(Capsule().fill(Color.white.opacity(0.05)))
                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
        }
    }

    /// The knob shows only the player's own turning, so it can neither give away nor misstate the scramble.
    private func turned(_ k: Int) -> Double {
        var position = 0, steps = 0
        for s in game.history {
            if s.rod == Game.tank {
                position += s.steps
            } else if game.level.layout.slot(of: k, at: position) == s.rod {
                steps += s.steps
            }
        }
        return Double(steps) * Tank.step
    }

    private func tank(_ side: CGFloat) -> some View {
        let r = side / 2
        func at(_ k: Int) -> CGPoint { CGPoint(x: r + rods[k].x * r, y: r + rods[k].y * r) }
        // A disc's lines, a swirl's too, kept clear of the bezel's own hairline at the glass's edge, as the tank's dial is.
        func disc(_ k: Int) -> CGFloat { min(rods[k].z * r, r - 4) }
        let core = 2 * Tank.coreRadius * r
        let probing = shown == nil ? liveRod : nil
        // The held rod's dial is fainter while letting go would cost nothing or a full stack would refuse the twist.
        // Only a full stack asks Array.commit's rule, which may sample the map: overlapping rods can commute (hex's hub
        // and its swirl).
        let commits = liveRod.map { k in
            let steps = Detent.steps(liveAngle, of: Tank.step)
            return steps != 0 && (game.stack.count < Tank.maxStack
                || game.stack.landing(rod: game.slot(of: k), steps: steps, in: game.level.layout, lenses: game.level.lenses) != nil)
        } ?? false
        let step = game.level.layout.tankStep
        let held = liveTurn.map { $0 + (spin ?? 0) }
        let turn = eased ? (Double(game.position) / Double(game.level.layout.order)).rounded() * 2 * .pi
            : Double(game.position) * step + (held ?? 0)
        let unstirred = Unstirred(stack: bare ? [] : stack, layout: game.level.layout, lenses: game.level.lenses, liveRod: liveRod.map(game.slot(of:)), liveAngle: liveAngle,
                                  wind: wind, side: side, haze: showResult ? min(0.12 * Double(game.over), 0.6) : 0, turn: turn,
                                  fillEntries: game.level.picture.fillEntries)
        // The wave is drawn on the screen, not the glass, so it holds still on the knob while the glass eases home.
        let source = game.history.last.map { $0.rod == Game.tank ? .zero : centre(game.knob(over: $0.rod)) } ?? centre(0)
        let frozenWave = frozenWave
        let flash = game.lastCommit
        // The player's own turning only, never the stack: the open stir a turn would join, plus the turn in hand.
        let stir = game.openStir
        func joined(_ rod: Int) -> Int { stir?.rod == rod ? stir!.steps : 0 }
        let rodCount: (k: Int, steps: Int, live: Bool)? = if let k = probing {
            (k, joined(game.slot(of: k)) + Detent.steps(liveAngle, of: Tank.step), true)
        } else if let k = counted, rods.indices.contains(k), held == nil, shown == nil, !game.finished {
            (k, joined(game.slot(of: k)), false)
        } else {
            nil
        }
        let tankCount: (steps: Int, live: Bool)? = if let held, shown == nil {
            (game.tankStir(after: Detent.steps(held, of: step)), true)
        } else if counted == Game.tank, shown == nil, !game.finished {
            (joined(Game.tank), false)
        } else {
            nil
        }
        // Out of the way while the tank is held.
        let lesson = shown == nil && !game.finished && held == nil
        // The swirl's too while it is held.
        let swirlLesson = lesson && !game.swirled && game.level.layout.swirl != nil && probing != game.level.layout.swirl
        let arc = (game.level.motion != .none && lesson && !game.tankTurned ? RimLesson.arc(r, .tank) : [])
            + (swirlLesson ? RimLesson.arc(r, .swirl) : [])
        // The clock's ratchet and its count want more room than a knob.
        let others: [(CGPoint, CGFloat)] = knobs.filter { $0 != rodCount?.k }
            .map { (at($0), ($0 == game.level.clock ? Self.ratchetSize(core) / 2 + 40 : core / 2) + Self.countRoom) }
            + arc.map { ($0, RimLesson.width + Self.countRoom) }
        // Endless: when the push that spilled the brim was made. UNSTIR_CLOCK holds the brim that long after its last change.
        let spillAt = game.spilled ? game.brimEvents.last?.time : nil
        // A live picture is the only kind that redraws while the player is still; 60 Hz is plenty for motion this slow.
        // Every other picture pauses the timeline, so nothing ticks, except while a spill stirs it together or the swirl
        // breathes.
        let moving = game.level.picture.isLive || spillAt != nil && brimMoving || breathing
        let tickNow = game.tick, clock = game.level.clock, playable = shown == nil
        return ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !moving || frozenClock != nil)) { timeline in
                let murk = spillAt.flatMap { at -> [Float]? in
                    let since = (frozenClock ?? timeline.date.timeIntervalSinceReferenceDate - at) - Brim.murk
                    return since > 0 ? Brim.murk(game.level.layout, seed: game.level.run?.seed ?? 0, at: since) : nil
                } ?? []
                let swirlBreath = game.level.layout.swirl.map { (rod: game.slot(of: $0), angle: breathAngle) }
                KeyframeAnimator(initialValue: 1.0, trigger: game.tickEvents) { p in
                    Group {
                        if let story = game.level.story {
                            StoryLayer(story: story, played: game.played, side: side, onStrike: { struck = true })
                        } else {
                            PictureLayer(picture: game.level.picture, side: side, seed: Int(game.level.label) ?? 0,
                                         clock: frozenClock ?? timeline.date.timeIntervalSince(opened), onStrike: { struck = true })
                        }
                    }
                        .keyframeAnimator(initialValue: -1.0, trigger: game.solved) { picture, w in
                            var u = unstirred
                            u.wave = SIMD3(Float(source.x), Float(source.y), Float(frozenWave ?? w))
                            u.breath = swirlBreath
                            // Escapement: a tick in flight, turned part way on the stack it changed.
                            if let t = tickNow, let clock, p < 1, playable {
                                u.stack = t
                                u.tick = (clock, p * Tank.step)
                            }
                            return picture.modifier(u).modifier(Murk(stirs: murk, side: side))
                        } keyframes: { _ in
                            // A light wave from the last-turned rod, over the clean picture. The animator holds its last value, so
                            // the band runs out past the farthest rim of any layout (1.56 from a ring rod) rather than parking on it.
                            MoveKeyframe(0.0)
                            LinearKeyframe(1.9, duration: 0.9, timingCurve: .easeOut)
                        }
                } keyframes: { _ in Self.tickKeys }
            }
            .clipShape(Circle())
            .opacity(1 - demoDip)
            if let clock, !game.finished {
                ClockHint(radius: disc(clock)).position(at(clock)).opacity(1 - demoDip).allowsHitTesting(false)
            }
            if let k = liveRod, shown != nil {
                glowRing(.magenta, 2.5, 6, under: .black.opacity(0.7))
                    .frame(width: 2 * disc(k), height: 2 * disc(k))
                    .position(at(k))
            }
            if let c = rodCount, c.live || c.steps != 0 {
                dial(at(c.k), disc(c.k), inner: dashes(c.k, r), from: turned(c.k) - Double(joined(game.slot(of: c.k))) * Tank.step,
                     to: turned(c.k) + (c.live ? liveAngle : 0), steps: c.steps, step: Tank.step)
                    .opacity(c.live ? (commits ? 1 : Self.idle) : Self.lifted)
            }
            if let c = tankCount, c.live || c.steps != 0 {
                // Inset clear of the bezel's own hairline at the glass's edge.
                let turns = held.map { Detent.steps($0, of: step) % game.level.layout.order != 0 } ?? false
                dial(CGPoint(x: r, y: r), r - 4, inner: r - 16, from: Double(game.position - joined(Game.tank)) * step,
                     to: Double(game.position) * step + (held ?? 0), steps: c.steps, step: step)
                    .opacity(c.live ? (turns ? 1 : Self.idle) : Self.lifted)
            }
            // Always present, so the first commit on a rod animates rather than inserting a view that never sees its trigger change.
            // The dial's hairline brightening as the finger lifts. An undo, which has no dial, flashes it too.
            let fk = flash?.rod ?? 0
            Circle().stroke(Color.live, lineWidth: Self.hairline)
                .frame(width: 2 * disc(fk), height: 2 * disc(fk))
                .keyframeAnimator(initialValue: 1.0, trigger: game.turns) { ring, t in
                    ring.opacity(t >= 1 ? 0 : 0.9 * (1 - t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 0.3, timingCurve: .easeOut)
                }
                .position(at(fk))
            Bezel(r: r)
            if game.level.motion != .none {
                Knurl(r: r, angle: turn, held: held != nil).opacity(showResult && !game.spilled ? 0 : 1)
            }
            // The picture's own colours, so they strike with it. A ZStack, not a Group, which would give the ring an
            // animator of its own that misses the strike when the colours land after it.
            ZStack {
                if let run = game.level.run, let rimColours {
                    // Moving for a while after each change, and all the while the room runs short.
                    BrimRing(r: r, brim: game.brim, events: game.brimEvents, base: run.brim, colours: rimColours, held: frozenClock,
                             paused: !(brimMoving || !game.spilled && game.brim >= Run.room - 1))
                }
            }
            .keyframeAnimator(initialValue: 0.0, trigger: struck) { ring, o in
                ring.opacity(o)
            } keyframes: { _ in PictureLayer.strike }
            if game.level.motion != .none {
                KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                    RimLesson(kind: .tank, r: r, showing: lesson && !game.tankTurned,
                              pulse: lesson && jammed != nil ? Self.pulse(frozenShake ?? s) : 0, clock: frozenClock)
                } keyframes: { _ in Self.jolt }
            }
            if game.level.layout.swirl != nil {
                // Inside the glass, in the middle of its grab: the tank's lesson keeps the bezel.
                RimLesson(kind: .swirl, r: r, showing: swirlLesson, pulse: 0, clock: frozenClock,
                          reach: ((game.level.motion == .none ? Self.rim : Self.swirlBand) + 1) / 2)
            }
            let ck = game.cancelledRod, across = 2 * disc(ck)
            Circle().stroke(Color.magenta, lineWidth: Self.hairline)
                .keyframeAnimator(initialValue: 1.0, trigger: game.cancels) { ring, t in
                    // Grown by frame, not scale, so the stroke stays a hairline out to the disc edge.
                    ring.frame(width: across * (0.3 + 0.7 * t), height: across * (0.3 + 0.7 * t)).opacity(t >= 1 ? 0 : 0.9 * (1 - t * t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 0.45, timingCurve: .easeOut)
                }
                .position(at(ck))
            ForEach(knobs, id: \.self) { k in
                // On a device pixel, so the knob's ticks can be.
                let p = at(k)
                if k == clock {
                    KeyframeAnimator(initialValue: 1.0, trigger: game.tickEvents) { t in
                        let flight = game.tick != nil && t < 1 ? 1 - t : 0
                        let ride = game.tick != nil && t < 1 ? sin(.pi * t) : 0
                        KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                            RatchetView(angle: (Double(game.escapement.ticks) - flight) * Tank.step
                                            + (jammed == k ? Self.shake(frozenShake ?? s) : 0),
                                        size: Self.ratchetSize(core), pawl: ride, lit: pressing,
                                        stopped: !game.stack.contains { $0.rod == k } && shown == nil && !demoing)
                        } keyframes: { _ in Self.jolt }
                    } keyframes: { _ in Self.tickKeys }
                    .position(x: (p.x * scale).rounded() / scale, y: (p.y * scale).rounded() / scale)
                } else {
                    KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                        RodView(angle: turned(k) + (probing == k ? liveAngle : 0) + (jammed == k ? Self.shake(frozenShake ?? s) : 0),
                                size: core, seized: game.level.kind(of: k) != .working, grabbed: probing == k,
                                lens: game.level.lenses.contains(game.slot(of: k)))
                    } keyframes: { _ in Self.jolt }
                        .position(x: (p.x * scale).rounded() / scale, y: (p.y * scale).rounded() / scale)
                }
            }
            // A spilled tank keeps its caps over the murk, and a lost one its clock.
            .opacity(showResult && !game.spilled && !game.lost ? 0 : 1)
            // A twist that stacked an entry: on the knob, as red would not read over the picture's red lines. After the
            // knobs, which would hide it. The swirl's is a ring just inside the glass's edge, over the picture, so a
            // hairline. One view either way, so the first push on either animates.
            let swirlPushed = fk == game.level.layout.swirl
            Circle().strokeBorder(Color.alarm, lineWidth: swirlPushed ? Self.hairline : 1)
                .padding(swirlPushed ? Self.swirlFlash - Self.hairline / 2 : -3)
                .frame(width: swirlPushed ? side : core, height: swirlPushed ? side : core)
                .keyframeAnimator(initialValue: 1.0, trigger: game.pushes) { ring, t in
                    ring.opacity(t >= 1 ? 0 : 1 - t)
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 0.4, timingCurve: .easeOut)
                }
                .position(at(fk))
            if let clock { clockMarks(at(clock), disc: disc(clock), size: Self.ratchetSize(core)) }
            if let spillAt {
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !brimMoving || frozenClock != nil)) { timeline in
                    SpillWords(r: r, at: frozenClock ?? timeline.date.timeIntervalSinceReferenceDate - spillAt)
                }
            }
            if let c = rodCount, c.steps != 0 {
                countLabel(c.steps).opacity(c.live ? 1 : 0.45)
                    .position(countSpot(at(c.k), reach: countReach(c.k, r), side: side, avoid: others))
            }
            if let c = tankCount, c.steps != 0 {
                countLabel(c.steps).opacity(c.live ? 1 : 0.45).position(countSpot(CGPoint(x: r, y: r), reach: 1.045 * r + 16, side: side))
            }
            if let ghost {
                // Turned with the stir it holds, about its pivot, so it rides the same animation round the arc.
                let a = ghost.rim ? held ?? 0 : liveAngle
                Circle().fill(Color.white.opacity(0.28)).overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
                    .frame(width: 40, height: 40)
                    .position(x: r + ghost.at.x * r, y: r + ghost.at.y * r)
                    .frame(width: side, height: side)
                    .rotationEffect(.radians(a), anchor: UnitPoint(x: (ghost.pivot.x + 1) / 2, y: (ghost.pivot.y + 1) / 2))
                    .allowsHitTesting(false)
            }
        }
        .frame(width: side, height: side)
        .keyframeAnimator(initialValue: 0.0, trigger: game.solved) { tank, t in
            tank.scaleEffect(1 + 0.02 * sin(t * .pi))
        } keyframes: { _ in CubicKeyframe(1.0, duration: 0.9) }
        // A level that turns, or swirls, reaches a finger on the bezel or just beyond it.
        .contentShape(Circle().inset(by: game.level.motion == .none && game.level.layout.swirl == nil ? 0 : -25))
        .gesture(twistGesture(r))
        // Not .none: that also switches off the gesture above.
        .simultaneousGesture(spinGesture, including: game.level.motion == .none ? .subviews : .all)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: grabs)
        .sensoryFeedback(.selection, trigger: ticks)
        .onChange(of: ticks) { Sound.shared.play(.tick) }
        .onChange(of: tankTicks) { Knock.clunk.play(); Sound.shared.play(.tank) }
        .sensoryFeedback(.impact(weight: .heavy), trigger: game.cancels)
        // Only on a new heal: not on a reset's return to 0, nor an undo's step back.
        .onChange(of: game.heals) { was, now in if now > was { Sound.shared.play(.heal(now)) } }
        .sensoryFeedback(.warning, trigger: game.pushes)
        // A push that spills a run sounds only as the spill.
        .onChange(of: game.pushes) { if !game.spilled { Sound.shared.play(.push) } }
        .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.9), trigger: game.tickEvents)
        .sensoryFeedback(.error, trigger: game.tickPushes)
        .sensoryFeedback(.success, trigger: game.solved) { _, solved in solved }
        // One sound for the end, as its card shows it.
        .onChange(of: game.finished) { if game.finished { Sound.shared.play(game.solved ? .solve : .spilled) } }
        // Keeps texture pixels on device pixels, so the untwisted picture is not blurred by half a pixel.
        .offset(snap)
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { o in
            snap = CGSize(width: (o.x * scale).rounded() / scale - o.x, height: (o.y * scale).rounded() / scale - o.y)
        }
        .padding(0.045 * r)
    }

    /// Escapement: a tick's flight, 0 to 1: a beat after the lift, then one 30-degree step of the clock's core.
    @KeyframesBuilder<Double> private static var tickKeys: some Keyframes<Double> {
        MoveKeyframe(0.0)
        LinearKeyframe(0.0, duration: 0.15)
        CubicKeyframe(1.0, duration: 0.3)
    }

    /// Escapement: the ratchet wheel's width, a knob and a half, so its teeth read.
    private static func ratchetSize(_ core: CGFloat) -> CGFloat { 1.5 * core }

    /// Escapement: what the clock at `c` shows round its ratchet: a red flash for a tick that pushed; while a pushed tick
    /// stands, a ring and its vermilion count; "lost." stamped by the clock once the tank is lost; the clock's disc
    /// lighting as it ticks; and a ring going out as the clock stops.
    private func clockMarks(_ c: CGPoint, disc: CGFloat, size: CGFloat) -> some View {
        let overdue = game.overdue, showing = shown == nil
        let badge = CGPoint(x: c.x + size / 2 + 30, y: c.y)
        let core = 2 * Tank.plateau * disc
        return ZStack {
            Circle().stroke(Color.alarm, lineWidth: 2).frame(width: size + 10, height: size + 10)
                .keyframeAnimator(initialValue: 1.0, trigger: game.tickPushes) { ring, t in
                    ring.opacity(t >= 1 ? 0 : 1 - t).scaleEffect(1 + 0.25 * t)
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 0.5, timingCurve: .easeOut)
                }
                .position(c)
            if overdue > 0 && showing {
                Circle().stroke(Color.vermilion, lineWidth: 1.5).frame(width: size + 8, height: size + 8).position(c)
                Text("+\(overdue)").font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundStyle(Color.vermilion)
                    .padding(.horizontal, 7).padding(.vertical, 1)
                    .background(Capsule().fill(Color.black.opacity(0.7)))
                    .overlay(Capsule().stroke(Color.vermilion, lineWidth: 1.5))
                    .position(badge)
                    .transition(.opacity)
            }
            // A clock stopped with twists left has no +1 to stamp beside, so the stamp keeps its place by the clock.
            if game.lost && showing { LostStamp(size: 50).position(x: badge.x - 6, y: badge.y + 30) }
            // The clock's disc lights as it ticks, so the eye goes where the tick acts.
            Circle().stroke(Color.vermilion, lineWidth: Self.hairline)
                .frame(width: 2 * disc, height: 2 * disc)
                .keyframeAnimator(initialValue: 1.0, trigger: game.tickEvents) { v, t in
                    v.opacity(t >= 1 ? 0 : 0.9 * sin(.pi * t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(0.25, duration: 0.15)
                    LinearKeyframe(1.0, duration: 0.6)
                }
                .position(c)
            Circle().stroke(Color.amber, lineWidth: 2)
                .keyframeAnimator(initialValue: 1.0, trigger: game.clockStops) { v, t in
                    v.frame(width: size + (core - size) * t, height: size + (core - size) * t).opacity(t >= 1 ? 0 : 0.9 * (1 - t * t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(0.0, duration: 0.3)
                    LinearKeyframe(1.0, duration: 0.7, timingCurve: .easeOut)
                }
                .position(c)
        }
        .allowsHitTesting(false)
    }

    /// Wide enough to read, too thin to hide the picture: 1.5 px on a 3x screen.
    private static let hairline: CGFloat = 0.5
    /// How far inside the glass's edge the swirl's push flashes.
    private static let swirlFlash: CGFloat = 5
    /// A drag's count: its dashes, and the trace under them. No glow and no dark band: with them the count hid the picture.
    private static let dash: CGFloat = 2, dashTone = 0.85, trace = hairline, traceTone = 0.4
    /// A dial's opacity while letting go would change nothing, and while its stir stays open after the finger lifts.
    private static let idle = 0.7, lifted = 0.45

    /// A turn's own count about `c`, angles clockwise from twelve: a hairline round the circle of `radius` with a long
    /// mark where the stir began, and on the circle of `inner` a dash per step from there the way the turn runs, over a
    /// trace out to `now`, where the turn stands.
    private func dial(_ c: CGPoint, _ radius: CGFloat, inner: CGFloat, from origin: Double, to now: Double, steps: Int,
                      step: Double) -> some View {
        func point(_ a: Double, _ radius: CGFloat) -> CGPoint { CGPoint(x: c.x + radius * sin(a), y: c.y - radius * cos(a)) }
        // Each arc moved to first: an arc appended to a path joins its current point with a line.
        func arc(_ p: inout Path, _ a: Double, _ b: Double) {
            p.move(to: point(a, inner))
            p.addArc(center: c, radius: inner, startAngle: .radians(a - .pi / 2), endAngle: .radians(b - .pi / 2), clockwise: b < a)
        }
        let dir = steps > 0 ? 1.0 : -1.0, gap = 3 / Double(inner)
        let dashes = Path { p in
            for i in 0..<abs(steps) { arc(&p, origin + dir * (Double(i) * step + gap), origin + dir * (Double(i + 1) * step - gap)) }
        }
        return ZStack {
            Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: 2 * radius, height: 2 * radius))
                .stroke(Color.live.opacity(0.6), lineWidth: Self.hairline)
            Path { $0.move(to: point(origin, radius)); $0.addLine(to: point(origin, radius - 10)) }
                .stroke(Color.live.opacity(0.6), lineWidth: Self.hairline)
            Path { arc(&$0, origin, now) }.stroke(Color.live.opacity(Self.traceTone), lineWidth: Self.trace)
            dashes.stroke(Color.live.opacity(Self.dashTone), lineWidth: Self.dash)
        }
    }

    private func countLabel(_ steps: Int) -> some View {
        Text(steps > 0 ? "+\(steps)" : "\u{2212}\(-steps)").font(.mono(13, .semibold)).foregroundStyle(Color.live)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(Color.black.opacity(0.6)))
    }

    /// Room for a count round its centre: half its width at two digits.
    private static let countRoom: CGFloat = 18

    /// The circle a rod's count's dashes run on: 14 pt inside its disc.
    private func dashes(_ k: Int, _ r: CGFloat) -> CGFloat { min(rods[k].z * r, r - 4) - 14 }

    /// How far from a rod's centre its count sits: off a knob's disc, but inside the swirl's, whose rim is the glass's
    /// edge, clear of its dashes.
    private func countReach(_ k: Int, _ r: CGFloat) -> CGFloat {
        k == game.level.layout.swirl ? dashes(k, r) - 6 - Self.countRoom : rods[k].z * r + 22
    }

    /// Where a turn's count sits: `reach` out from `c` on the far side from the finger, but never below it, where the
    /// hand is, swung the least that keeps it as far from each point in `avoid` as that point asks; kept on the screen.
    private func countSpot(_ c: CGPoint, reach: CGFloat, side: CGFloat, avoid: [(CGPoint, CGFloat)] = []) -> CGPoint {
        let r = side / 2, edge = 0.045 * r
        var d = finger.map { CGVector(dx: c.x - ($0.x + 1) * r, dy: min(c.y - ($0.y + 1) * r, 0)) } ?? CGVector(dx: 0, dy: -1)
        if hypot(d.dx, d.dy) < 1 { d = CGVector(dx: c.x > r ? -1 : 1, dy: 0) }
        let a = atan2(d.dy, d.dx), swings: [CGFloat] = [0] + (1...6).flatMap { [CGFloat($0), -CGFloat($0)] }
        let spots = swings.map { a + $0 * .pi / 12 }.filter { sin($0) < 1e-6 }.map { b in
            CGPoint(x: min(max(c.x + cos(b) * reach, 4 - edge), side + edge - 4), y: min(max(c.y + sin(b) * reach, -edge - 20), side + edge + 20))
        }
        func room(_ p: CGPoint) -> CGFloat { avoid.map { hypot(p.x - $0.0.x, p.y - $0.0.y) - $0.1 }.min() ?? 0 }
        return spots.first { room($0) >= 0 } ?? spots.max { room($0) < room($1) }!
    }

    private func twistGesture(_ r: CGFloat) -> some Gesture {
        func norm(_ p: CGPoint) -> SIMD2<Double> { SIMD2(Double(p.x / r - 1), Double(p.y / r - 1)) }
        return DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard !settling, !game.finished, shown == nil, !demoing else { return }
                let q = norm(v.location)
                let level = game.level
                // Keyed on the start point because a cancelled drag never reaches onEnded; a new touch starts afresh.
                if drag?.start != v.startLocation {
                    endPath()
                    drag = nil; liveRod = nil; liveAngle = 0; pressing = false
                    // A twist cancelled without onEnded leaves its turn behind.
                    if spin == nil { liveTurn = nil; spun = false; endTwist() }
                    // Where it landed: the first change seen can come later, once a release or a reset's stir settles.
                    let landed = norm(v.startLocation)
                    drag = (v.startLocation, Self.grab(level.layout, motion: level.motion, kind: level.kind(of:), at: landed), 0)
                    Log.write("touch \(drag!.grab) at \(Log.point(landed))")
                    path = (drag!.grab, v.time, Trail(gap: 0.03) { simd_distance($0, $1) })
                    path!.trail.add(landed, ms: 0)
                    // From the current point, so a drag picked up again after a reset's stir does not jump.
                    hold(from: q)
                }
                if let down = path?.down { path!.trail.add(q, ms: Self.ms(v.time, since: down)) }
                finger = q
                guard let g = drag, let pivot = pivot(g.grab) else { return }
                let d = q - pivot
                let a = atan2(d.y, d.x)
                let lens = lensHeld(g.grab)
                drag!.last = lens ? q.y : a
                // Two fingers turn the tank while they are down.
                guard !spun else { return }
                // Near the pivot the angle is noise; track it without turning.
                let da = lens ? Self.lensTurn(from: g.last, to: q.y)
                    : simd_length(d) > 0.1 ? atan2(sin(a - g.last), cos(a - g.last)) : 0
                if g.grab != .rim {
                    liveAngle += da
                    ticks += detent.turn(to: liveAngle)
                } else if let turn = liveTurn {
                    liveTurn = turn + da
                    tankTicks += detent.turn(to: turn + da)
                }
            }
            .onEnded { v in
                if demoing {
                    demoing = false
                    Log.write("skip demo")
                    return
                }
                if shown != nil {
                    // Past 1, so the value changes and cuts short a wind-in still animating towards 1.
                    shown = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; wind = 2
                    Log.write("skip \(state)")
                    return
                }
                // The lift can carry movement no change reported.
                if let down = path?.down { path!.trail.add(norm(v.location), ms: Self.ms(v.time, since: down)) }
                endPath()
                guard let g = drag else { return }
                drag = nil
                switch g.grab {
                case .rod(let k): release(k)
                case .rim: if !spun { releaseTank() }
                case .ratchet(let k):
                    pressing = false
                    // A tap on the ratchet itself waits; a drag, or a touch elsewhere on the clock's disc, is refused.
                    let start = norm(g.start), end = norm(v.location)
                    if simd_distance(start, end) < 0.06 && simd_distance(start, centre(k)) < Self.ratchetReach {
                        game.wait(on: k)
                    } else {
                        jammed = k; jams += 1; Knock.thud.play()
                    }
                case .seized, .nothing: break
                }
            }
    }

    /// The finger's travel up or down, in tank units, for one step of a lens (Jack, 2026-10-26).
    static let lensPitch = 0.15

    /// A lens follows the finger up and down, not round: the angle the detent counts for a finger gone from height `y0`
    /// to `y` (tank units, down positive). Up zooms in, a positive step (Jack, 2026-10-26).
    static func lensTurn(from y0: Double, to y: Double) -> Double { (y0 - y) / lensPitch * Tank.step }

    private func lensHeld(_ grab: Grab) -> Bool {
        if case .rod(let k) = grab { game.level.lenses.contains(game.slot(of: k)) } else { false }
    }

    private func pivot(_ grab: Grab) -> SIMD2<Double>? {
        switch grab {
        case .rod(let k): centre(k)
        case .rim: .zero
        case .seized, .ratchet, .nothing: nil
        }
    }

    /// Takes up what the drag holds, its angle counted from `point`, where the finger is when the drag is taken up. A
    /// seized knob refuses it.
    private func hold(from point: SIMD2<Double>) {
        if case .seized(let k)? = drag?.grab {
            jammed = k
            jams += 1
            Knock.thud.play()
            Sound.shared.play(.seized)
        }
        if case .ratchet? = drag?.grab { pressing = true; grabs += 1 }
        guard let g = drag, let pivot = pivot(g.grab) else { return }
        let d = point - pivot
        drag!.last = lensHeld(g.grab) ? point.y : atan2(d.y, d.x)
        if case .rod(let k) = g.grab {
            liveRod = k; counted = k; grabs += 1; detent = Detent(step: Tank.step)
        } else {
            liveTurn = 0; counted = Game.tank; detent = Detent(step: game.level.layout.tankStep)
        }
        if !game.level.sandbox && game.level.keepsProgress { Best.start(game.level.id) }
    }

    /// What a finger landing at `point` (tank units) holds, settled there so the rod that lights is the rod that turns.
    /// The rim wins over the discs that reach it: past `rim` it holds the level's motion where it has one, and the
    /// swirl where there is one. Where there are both, the glass's own edge from `swirlBand` holds the swirl and the
    /// bezel and beyond the motion. Otherwise the disc whose centre is nearest, in its own radius, wins, never the
    /// swirl, whose centre would win everywhere; a knob that can't be turned and wins holds nothing rather than passing
    /// the finger to a neighbour.
    nonisolated static func grab(_ layout: Layout, motion: Level.Motion, kind: (Int) -> Level.Knob,
                                 at point: SIMD2<Double>) -> Grab {
        let out = simd_length(point)
        switch (layout.swirl, motion == .none) {
        case (.some, false) where out >= 1: return .rim
        case (let s?, false) where out > swirlBand: return .rod(s)
        case (let s?, true) where out > rim: return .rod(s)
        case (nil, false) where out > rim: return .rim
        default: break
        }
        let rods = layout.rods
        func depth(_ k: Int) -> Double { simd_distance(point, SIMD2(rods[k].x, rods[k].y)) / rods[k].z }
        guard let k = rods.indices.filter({ $0 != layout.swirl && depth($0) < 1 }).min(by: { depth($0) < depth($1) })
        else { return .nothing }
        switch kind(k) {
        case .working: return .rod(k)
        case .seized, .socket: return .seized(k)
        case .ratchet: return .ratchet(k)
        }
    }

    /// Escapement: how far from the clock's centre a tap waits, in tank units: the ratchet and a finger's slack.
    nonisolated static let ratchetReach = 0.16

    /// Where the rim's grab starts, in tank units: about 13 pt into the glass on a Pro Max.
    nonisolated static let rim = 0.93
    /// Where a level has both a swirl and a motion, the swirl's grab starts here, so the glass's edge it holds is
    /// as wide as a fingertip, about 27 pt on a Pro Max; the turn keeps the bezel and the 25 pt beyond it, about 34 pt.
    nonisolated static let swirlBand = 0.86

    /// The seized knob's shake and the rim's pulse both run on this clock, in seconds.
    @KeyframesBuilder<Double> private static var jolt: some Keyframes<Double> {
        MoveKeyframe(0.0)
        LinearKeyframe(1.0, duration: 1.0)
    }

    /// A seized knob's turn `s` seconds after a finger lands on it: a few degrees each way, dying out in 0.4 s.
    nonisolated static func shake(_ s: Double) -> Double {
        s < 0.4 ? 5 * .pi / 180 * sin(2 * .pi * s / 0.12) * (1 - s / 0.4) : 0
    }

    /// The rim's pulse `s` seconds after a seized knob is touched: up in 0.15 s, gone by 0.9 s.
    nonisolated static func pulse(_ s: Double) -> Double {
        s < 0.15 ? sin(.pi / 2 * s / 0.15) : s < 0.9 ? cos(.pi / 2 * (s - 0.15) / 0.75) : 0
    }

    /// Two fingers twisted anywhere on the tank turn it, taking over from a rod the first finger held.
    private var spinGesture: some Gesture {
        RotateGesture()
            .updating($spin) { v, spin, _ in spin = v.rotation.radians }
            .onChanged { v in
                guard !settling, !game.finished, shown == nil else { return }
                if !spun { endPath(); twist = (v.time, Trail(gap: 0.05) { abs($0 - $1) }) }
                spun = true
                if let down = twist?.down { twist!.trail.add(v.rotation.radians, ms: Self.ms(v.time, since: down)) }
                if liveTurn == nil {
                    drag?.grab = .rim; liveRod = nil; liveAngle = 0; liveTurn = 0; counted = Game.tank
                    Log.write("spin \(state)")
                    detent = Detent(step: game.level.layout.tankStep)
                }
                tankTicks += detent.turn(to: liveTurn! + v.rotation.radians)
            }
            .onEnded { v in
                guard spun else { return }
                spun = false
                if let down = twist?.down { twist!.trail.add(v.rotation.radians, ms: Self.ms(v.time, since: down)) }
                endTwist()
                guard shown == nil, let turn = liveTurn else { return }
                liveTurn = turn + v.rotation.radians
                // The end can carry rotation no change reported, and it commits.
                tankTicks += detent.turn(to: liveTurn!)
                releaseTank()
            }
    }

    private static func ms(_ time: Date, since down: Date) -> Int { Int((time.timeIntervalSince(down) * 1000).rounded()) }

    private func endPath() {
        guard let p = path else { return }
        Log.write("path \(p.grab) \(p.trail.line(Log.point))")
        path = nil
    }

    private func endTwist() {
        guard let t = twist else { return }
        Log.write("twist \(t.trail.line { String(format: "%.3f", $0) })")
        twist = nil
    }

    private func releaseTank() {
        guard !settling, let turn = liveTurn else { return }
        let step = game.level.layout.tankStep, steps = Detent.steps(turn, of: step)
        Log.write("release tank angle=\(turn) steps=\(steps)")
        settling = true
        counted = Game.tank
        withAnimation(.snappy(duration: 0.3)) {
            liveTurn = Double(steps) * step
        } completion: {
            liveTurn = nil
            settling = false
            game.turnTank(steps)
        }
    }

    private func release(_ k: Int) {
        let steps = Detent.steps(liveAngle, of: Tank.step)
        Log.write("release \(k) angle=\(liveAngle) steps=\(steps)")
        settling = true
        counted = k
        withAnimation(.snappy(duration: 0.22)) {
            liveAngle = Double(steps) * Tank.step
        } completion: {
            liveRod = nil
            liveAngle = 0
            settling = false
            guard steps != 0 else { return }
            game.commit(rod: k, steps: steps)
        }
    }
}

/// The swirl's standing cue: while the tank rests, the swirl sloshes the picture once through its own map and settles,
/// then again every `every` seconds, so the player sees that the rim swirls before touching it. It moves only the
/// picture, never the game.
struct Breath: Equatable {
    /// When the rest began, in seconds since the reference date, and how long it waits before its first slosh.
    let start: Double
    let wait: Double
    /// When a touch, the opening or the win ended the rest.
    var cut: Double?

    /// The first rest waits for the picture to land and strike; one after a lift waits longer, so no move is answered
    /// by a slosh.
    static let first = 1.5, later = 10.0
    /// A slosh repeats this often while the rest lasts, and fades out over `fade` once the rest is cut.
    static let every = 12.0, fade = 0.25
    /// A slosh's length: two of its swings, so it ends where its sine does, at 0.
    static let length = 3.2
    static let lead = 0.1

    /// The swirl's turn `p` seconds into a slosh: a swing of 12 degrees damped as it goes, so it peaks near 8 (as in the
    /// pitch's film), 0 at both ends.
    static func slosh(_ p: Double) -> Double {
        p <= 0 || p >= length ? 0 : 12 * .pi / 180 * sin(2 * .pi * p / (length / 2)) * exp(-p)
    }

    /// The swirl's turn at `t`, faded out from wherever a cut caught it, so the picture never jumps.
    func angle(at t: Double) -> Double {
        guard let p = phase(at: t) else { return 0 }
        let a = Self.slosh(p)
        guard let cut, t > cut else { return a }
        guard t < cut + Self.fade else { return 0 }
        let f = 1 - (t - cut) / Self.fade
        return a * f * f * (3 - 2 * f)
    }

    /// Whether the turn may be off 0 at `t`, and when that next changes, if it ever does. From `lead` before each slosh,
    /// since a sleep wakes late and a slosh starts at its fastest.
    func motion(at t: Double) -> (moving: Bool, until: Double?) {
        let end = cut.map { $0 + Self.fade } ?? .infinity, first = start + wait - Self.lead
        guard t < end else { return (false, nil) }
        guard let p = phase(at: t + Self.lead) else { return (false, first < end ? first : nil) }
        if p < Self.length + Self.lead { return (true, min(t + Self.length + Self.lead - p, end)) }
        let next = t + Self.every - p
        return (false, next < end ? next : nil)
    }

    /// How far into its latest slosh the rest is at `t`, nil before the first.
    private func phase(at t: Double) -> Double? {
        let s = t - start - wait
        return s > 0 ? s - (s / Self.every).rounded(.down) * Self.every : nil
    }
}

/// A turn's clicks: one each time what letting go would commit changes, at every half step, either way. So a rod's tick
/// and the tank's clunk land with the drag's count, and every step a turn commits has had one.
struct Detent {
    let step: Double
    /// What letting go now would commit.
    private(set) var steps = 0

    /// The steps letting go of a turn of `angle` commits: the nearest, so a turn past half a step takes the step.
    static func steps(_ angle: Double, of step: Double) -> Int { Int((angle / step).rounded()) }

    /// Follows the turn to `angle`, returning its clicks: more than one only when one move crosses several half steps.
    mutating func turn(to angle: Double) -> Int {
        let now = Self.steps(angle, of: step)
        defer { steps = now }
        return abs(now - steps)
    }
}

/// The tank's own haptics, on one engine.
@MainActor enum Knock {
    /// The tank's click (see `Detent`): a dull knock and a short low rumble dying under it, so it reads as neither a
    /// rod's tick nor the heal's heavy tap.
    case clunk
    /// A seized knob refusing a finger: heavier and duller than the clunk.
    case thud

    private static var running = false
    private static let engine: CHHapticEngine? = {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, let engine = try? CHHapticEngine() else { return nil }
        // Sendable, so not main-actor code: the engine calls these on its own queue. They only flag the engine, because
        // one stopped for a suspended app cannot start until the app is back.
        engine.stoppedHandler = { @Sendable _ in Task { @MainActor in running = false } }
        engine.resetHandler = { @Sendable in Task { @MainActor in running = false } }
        return engine
    }()
    private static let clunkPattern = knock(sharpness: 0.15, rumble: 0.75, length: 0.09, hold: 0.5)
    private static let thudPattern = knock(sharpness: 0, rumble: 1, length: 0.16, hold: 0.75)

    /// A transient and a rumble under it that holds at `hold` of its strength a third of the way through `length`.
    private static func knock(sharpness: Float, rumble: Float, length: TimeInterval, hold: Float) -> CHHapticPattern? {
        try? CHHapticPattern(events: [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: rumble),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness / 3),
            ], relativeTime: 0.005, duration: length),
        ], parameterCurves: [
            CHHapticParameterCurve(parameterID: .hapticIntensityControl, controlPoints: [
                .init(relativeTime: 0, value: 1), .init(relativeTime: length / 3, value: hold), .init(relativeTime: length + 0.005, value: 0),
            ], relativeTime: 0),
        ])
    }

    func play() {
        guard let engine = Self.engine, let pattern = self == .clunk ? Self.clunkPattern : Self.thudPattern else { return }
        if !Self.running {
            guard (try? engine.start()) != nil else { return }
            Self.running = true
        }
        // A player per knock, since a reset voids the old ones.
        try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
    }
}

/// Turns the glass by `turn`, applies the stack (plus the live twist on top) as inverse maps and samples the picture.
struct Unstirred: ViewModifier, Animatable {
    var stack: [Twist]
    var layout: Layout
    /// The rods whose steps magnify rather than turn.
    var lenses: Set<Int> = []
    var liveRod: Int?
    var liveAngle: Double
    var wind = 1.0
    var side: CGFloat
    /// Drains the colour towards grey.
    var haze = 0.0
    /// The glass's turn about the tank's centre, in radians clockwise.
    var turn = 0.0
    /// (x, y, radius) in tank units on the screen; a negative radius is off.
    var wave = SIMD3<Float>(0, 0, -1)
    /// A live picture's own cost per frame, in entries: it is redrawn under the shader every frame.
    var fillEntries = 0
    /// The swirl's breath, newest of all.
    var breath: (rod: Int, angle: Double)?
    /// Escapement: the clock's tick part way, on top of the stack and under the live twist.
    var tick: (rod: Int, angle: Double)?
    @Environment(\.displayScale) private var scale

    nonisolated var animatableData: AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>> {
        get { AnimatablePair(AnimatablePair(liveAngle, wind), AnimatablePair(haze, turn)) }
        set { (liveAngle, wind, haze, turn) = (newValue.first.first, newValue.first.second, newValue.second.first, newValue.second.second) }
    }

    func body(content: Content) -> some View {
        let rods = layout.rods
        var floats: [Float] = []
        floats.reserveCapacity(4 * (stack.count + 1))
        func add(_ rod: Int, _ angle: Double) {
            floats.append(Float(rods[rod].x)); floats.append(Float(rods[rod].y))
            // A lens's entry is marked by a negative radius, and takes its flow's time for the angle.
            let lens = lenses.contains(rod)
            floats.append(Float(lens ? -rods[rod].z : rods[rod].z))
            floats.append(Float(lens ? angle / Tank.step * Tank.lensRate : angle))
        }
        for t in stack { add(t.rod, Double(t.steps) * Tank.step * min(wind, 1)) }
        if let tick { add(tick.rod, tick.angle) }
        if let liveRod { add(liveRod, liveAngle) }
        let breathes = breath.map { $0.angle != 0 } ?? false
        if breathes, let breath { add(breath.rod, breath.angle) }
        let n = floats.count / 4
        if floats.isEmpty { floats = [0, 0, 0, 0] }
        let r = side / 2
        // A live picture keeps four taps only to `Tank.fourTaps` entries less its fill: the same budget as without it.
        // Counted in committed entries, so a touch never changes the taps; the drag, the breath or a tick in flight rides
        // one over, within the 31 the shader's comment measured. Two at once, for the `Breath.fade` a touch takes to cut a
        // slosh or a grab within a tick's flight, drop to two taps at the budget's edge rather than run 32.
        let fourTaps = Float(Tank.fourTaps - fillEntries) + (liveRod != nil || breathes || tick != nil ? 1 : 0)
        return content.layerEffect(
            ShaderLibrary.unstir(.float2(r, r), .float(r), .floatArray(floats), .float(Float(n)), .float(fourTaps), .float(Float(Tank.plateau)),
                                 .float(Float(Tank.swirlPlateau)), .float(Float(Tank.lensEdge)), .float(Float(scale)), .float(Float(haze)), .float3(wave.x, wave.y, wave.z), .float(Float(turn))),
            maxSampleOffset: CGSize(width: side, height: side))
    }
}

struct PictureLayer: View {
    let picture: Picture
    let side: CGFloat
    /// A live picture: the level's seed and its clock in seconds.
    var seed = 0
    var clock = 0.0
    /// When the picture lands and starts to strike, for whatever strikes with it.
    var onStrike: () -> Void = {}
    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?

    /// The picture's opacity as it lands.
    @KeyframesBuilder<Double> static var strike: some Keyframes<Double> {
        // Black until the screen's 0.27 s dip in has landed, or the fade swallows the strike.
        MoveKeyframe(0.0)
        LinearKeyframe(0.0, duration: 0.25)
        MoveKeyframe(0.8)
        LinearKeyframe(0.8, duration: 0.04)
        MoveKeyframe(0.1)
        LinearKeyframe(0.1, duration: 0.06)
        MoveKeyframe(0.95)
        LinearKeyframe(0.95, duration: 0.03)
        MoveKeyframe(0.35)
        LinearKeyframe(0.35, duration: 0.05)
        LinearKeyframe(1.0, duration: 0.16, timingCurve: .easeOut)
    }

    var body: some View {
        ZStack {
            if picture.isLive, let data = picture.data(seed: seed, clock: clock) {
                Rectangle().fill(ShaderFunction(library: .default, name: "\(picture)")(
                    .float(side / 2), .float(2 / (side * scale)), .floatArray(data),
                    .float(Float(clock.truncatingRemainder(dividingBy: picture.period)))))
            } else if let image {
                Image(uiImage: image)
            } else {
                Color.black
            }
        }
        .frame(width: side, height: side)
        // Flickers on like a neon tube when the texture lands. Over black, opacity is a colour multiply the shader samples for free.
        // Transparent until then, which over black matches the placeholder and keeps a live picture from showing before the strike.
        .keyframeAnimator(initialValue: 0.0, trigger: image != nil) { picture, o in picture.opacity(o) } keyframes: { _ in Self.strike }
        .onChange(of: image != nil) { if image != nil { onStrike() } }
        // A live picture bakes nothing: the empty image only strikes the tube, once its data is ready.
        .task(id: [picture.rawValue, "\(seed)", "\(side)", "\(scale)"]) {
            if picture.isLive { await picture.prepare(seed: seed) }
            image = picture.isLive ? UIImage() : await picture.render(side: side, scale: scale)
        }
    }
}

/// How to turn the tank, or stir with the swirl, at the rim of glass of radius `r`: a two-headed arc and a ghost finger
/// rocking along it, one way and back, so it names the control and never the move. Each lies on the ring it teaches,
/// so on a level with both they point at different rings. The tank's is amber at the top, its arc just outside the
/// bezel and its finger on the bezel; the swirl's is cyan at the bottom, a thin arc just inside the glass's edge and
/// its finger there, in the middle of the swirl's grab. `pulse` (0 to 1) swells the tank's arc, and
/// brings it back for a moment once it has stopped showing.
struct RimLesson: View {
    enum Kind { case tank, swirl }
    let kind: Kind
    let r: CGFloat
    let showing: Bool
    let pulse: Double
    /// Holds the ghost finger this many seconds in.
    let clock: Double?
    /// The ghost finger's path, as a fraction of the glass's radius.
    var reach = 1.0225
    private static let span = 34 * Double.pi / 180, sweep = 26 * Double.pi / 180, period = 3.6
    /// The arc's stroke at the height of its pulse. Nothing of it, arrowheads included, lies further than this from its line.
    static let width: CGFloat = 14
    /// The tank's arc rides outside the bezel it turns; the swirl's lies inside the glass, a thin line over the picture.
    private static func radius(_ r: CGFloat, _ kind: Kind) -> CGFloat { kind == .tank ? 1.045 * r + 10 : r - 10 }
    /// Where the lesson sits, clockwise from twelve.
    private static func notch(_ kind: Kind) -> Double { kind == .tank ? 0 : .pi }

    /// Points along one arm of the arc, from its middle out to its tip.
    private static func arm(_ r: CGFloat, _ kind: Kind, _ dir: Double) -> [CGPoint] {
        (0...17).map { i in
            let t = Double(i) / 17, a = notch(kind) + dir * span * t
            return CGPoint(x: r + radius(r, kind) * sin(a), y: r - radius(r, kind) * cos(a))
        }
    }

    /// Points every 2° along the arc: whatever keeps off the arc keeps off these.
    static func arc(_ r: CGFloat, _ kind: Kind) -> [CGPoint] { arm(r, kind, -1).reversed() + arm(r, kind, 1) }

    private var arrow: Path {
        var p = Path()
        for dir in [-1.0, 1] {
            let points = Self.arm(r, kind, dir)
            p.addLines(points)
            let tip = points[points.count - 1], before = points[points.count - 2]
            let d = hypot(tip.x - before.x, tip.y - before.y)
            let head: CGFloat = kind == .tank ? 8 : 6
            let back = CGVector(dx: (before.x - tip.x) / d * head, dy: (before.y - tip.y) / d * head)
            let wing = CGVector(dx: -back.dy * 5 / 8, dy: back.dx * 5 / 8)
            p.move(to: CGPoint(x: tip.x + back.dx + wing.dx, y: tip.y + back.dy + wing.dy))
            p.addLine(to: tip)
            p.addLine(to: CGPoint(x: tip.x + back.dx - wing.dx, y: tip.y + back.dy - wing.dy))
        }
        return p
    }

    var body: some View {
        let colour = kind == .tank ? Color.amber : .neonCyan
        return ZStack {
            if showing {
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: clock != nil)) { timeline in
                    let a = Self.notch(kind) + Self.sweep * sin(2 * .pi * (clock ?? timeline.date.timeIntervalSinceReferenceDate) / Self.period)
                    Circle().fill(Color.live.opacity(0.22))
                        .overlay(Circle().stroke(Color.live.opacity(0.6), lineWidth: 1.5))
                        .shadow(color: .live.opacity(0.4), radius: 6)
                        .frame(width: 30, height: 30)
                        .position(x: r + reach * r * sin(a), y: r - reach * r * cos(a))
                }
            }
            if kind == .tank {
                arrow.stroke(colour.opacity(0.22 + 0.3 * pulse), style: StrokeStyle(lineWidth: Self.width - 6 * (1 - pulse), lineCap: .round, lineJoin: .round))
                arrow.stroke(colour, style: StrokeStyle(lineWidth: 3 + 1.5 * pulse, lineCap: .round, lineJoin: .round))
            } else {
                // Over the picture, so no glow: seated on a dark stroke, to read on a busy one.
                arrow.stroke(Color.black.opacity(0.6), style: StrokeStyle(lineWidth: 3.5, lineCap: .round, lineJoin: .round))
                arrow.stroke(colour, style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: 2 * r, height: 2 * r)
        .opacity(showing ? 1 : pulse)
    }
}

/// Where the rim turns the tank, the bezel of glass of radius `r` is knurled, turning with the glass by `angle`, its ridges
/// amber as the tank's lesson and lit while the rim holds the glass.
struct Knurl: View {
    let r: CGFloat
    let angle: Double
    let held: Bool

    /// A milled edge across the bezel's steel: dark grooves between bright ridges, every few points.
    var body: some View {
        let count = Int((2 * .pi * r / 4).rounded())
        func lines(_ offset: Double, _ a: CGFloat, _ b: CGFloat) -> Path {
            Path { p in
                for i in 0..<count {
                    let t = (Double(i) + offset) * 2 * .pi / Double(count)
                    p.move(to: CGPoint(x: r + a * sin(t), y: r - a * cos(t)))
                    p.addLine(to: CGPoint(x: r + b * sin(t), y: r - b * cos(t)))
                }
            }
        }
        let a = r + 1.5, b = 1.045 * r - 0.5
        return ZStack {
            lines(0, a, b).stroke(Color.black.opacity(0.55), lineWidth: 1.2)
            // Amber even at rest, faintly: the tank's colour, as its lesson.
            lines(0.5, a, b).stroke(Color.amber.opacity(held ? 0.9 : 0.55), lineWidth: 0.6)
        }
        .rotationEffect(.radians(angle))
        .opacity(held ? 1 : 0.85)
        .frame(width: 2 * r, height: 2 * r)
        .allowsHitTesting(false)
    }
}

struct RodView: View {
    let angle: Double
    let size: CGFloat
    var seized = false
    var grabbed = false
    /// A lens's knob, whose cap carries an iris.
    var lens = false
    @Environment(\.displayScale) private var scale
    private static let knob = [(0, 0xF4F6FA), (0.25, 0x7A8292), (0.6, 0x2E333D), (1, 0x15181E)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }
    private static let dull = [(0, 0x6E737C), (0.25, 0x3C414A), (0.6, 0x1E2127), (1, 0x101216)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }

    var body: some View {
        // Whole device pixels out from a pixel-snapped centre, so at rest the upright and level ticks land crisp.
        let rim = px(size / 2), width = px(2 / 3)
        let lit = seized ? Color(0x5A606C) : .neonCyan
        ZStack {
            Circle().fill(RadialGradient(stops: seized ? Self.dull : Self.knob, center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0,
                                         endRadius: size * 0.95))
            Circle().strokeBorder(Color.black.opacity(0.8), lineWidth: 1.2)
            ticks(rim - px(2), rim - px(1 / 3)).stroke(lit.opacity(0.8), lineWidth: width)
            if grabbed { ticks(rim - px(2), rim - px(1 / 3)).stroke(Color.live, lineWidth: width) }
            if lens {
                iris.stroke(Color.magenta.opacity(0.3), lineWidth: 3)
                iris.stroke(Color.magenta, lineWidth: 1)
            }
            // Off-centre so a half turn reads as pointing down, not as untouched.
            Capsule().fill(lit.opacity(0.25)).frame(width: 6, height: size * 0.3 + 4).offset(y: -size * 0.3)
            Capsule().fill(lit).frame(width: 2, height: size * 0.3).offset(y: -size * 0.3)
            if seized {
                Capsule().fill(Color.blood).frame(width: size * 0.95, height: 2.5).shadow(color: .blood, radius: 3)
                    .rotationEffect(.degrees(-35))
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.radians(angle))
        .background {
            Circle().strokeBorder(Color.black.opacity(0.7), lineWidth: 3).padding(-3)
            ticks(rim + px(2 / 3), rim + px(8 / 3)).stroke(lit.opacity(0.5), lineWidth: width)
            // Lit inside the knob's own footprint, so the picture round it stays in view.
            if grabbed {
                ticks(rim + px(2 / 3), rim + px(8 / 3)).stroke(Color.live, lineWidth: width)
                Self.band(.live)
            }
        }
    }

    /// A ring along the outer edge of the knob's dark band, where it covers none of the picture.
    static func band(_ colour: Color) -> some View { Circle().strokeBorder(colour, lineWidth: 1).padding(-3) }

    private func px(_ points: CGFloat) -> CGFloat { (points * scale).rounded() / scale }

    /// Six blades, each swept from the cap's edge in to a corner of the aperture, so the iris turns with the knob.
    private var iris: Path {
        Path { p in
            let c = CGPoint(x: size / 2, y: size / 2), outer = size * 0.4, inner = size * 0.14
            func at(_ r: CGFloat, _ a: Double) -> CGPoint { CGPoint(x: c.x + r * sin(a), y: c.y - r * cos(a)) }
            for i in 0..<6 {
                let a = Double(i) * .pi / 3
                p.move(to: at(outer, a))
                p.addQuadCurve(to: at(inner, a + 1.3), control: at(outer * 0.62, a + 0.85))
                p.addLine(to: at(inner, a + 1.3 + .pi / 3))
            }
        }
    }

    /// One radial mark per 30-degree step, from radius `a` out to `b`.
    private func ticks(_ a: CGFloat, _ b: CGFloat) -> Path {
        var p = Path()
        for i in 0..<12 {
            let t = Double(i) * Tank.step
            p.move(to: CGPoint(x: size / 2 + a * sin(t), y: size / 2 - a * cos(t)))
            p.addLine(to: CGPoint(x: size / 2 + b * sin(t), y: size / 2 - b * cos(t)))
        }
        return p
    }
}

struct ResultCard: View {
    let game: Game
    let onExit: () -> Void
    let onNext: (Level) -> Void

    var body: some View {
        let run = game.level.run
        let accent: Color = switch game.level.tier {
        case .plughole: .neonCyan
        case .vortex: game.level.tier.glow
        case .whirlpool, .maelstrom: .blood
        }
        let next = run != nil ? game.nextTank : (game.level.pack?.levels ?? game.level.tier.levels).drop(while: { $0.id != game.level.id }).dropFirst().first
        let time = String(format: "%d:%02d", game.seconds / 60, game.seconds % 60)
        VStack(spacing: 26) {
            VStack(spacing: 8) {
                if let run {
                    Text("moves \(game.moves) \u{00B7} \(time)")
                    Text(game.spilled ? "tanks cleared \(run.tank) \u{00B7} best \(Best.tanks)"
                         : "tank \(run.tank + 1) \u{00B7} brim \(game.brim) / \(Run.room)")
                } else {
                    Text("moves \(game.moves) \u{00B7} par \(game.par) \u{00B7} \(time)")
                    if game.clean {
                        Text("clean").fontWeight(.semibold).foregroundStyle(Color.lime).shadow(color: .lime, radius: 3)
                    } else if game.over > 0 {
                        Text("+\(game.over) over par").foregroundStyle(Color.magenta)
                    } else {
                        Text(game.firstTry ? "at par \u{00B7} clean needs no reset or undo" : "clean counts on the first try")
                            .foregroundStyle(Color.amber)
                    }
                }
            }
            .font(.mono(13))
            HStack(spacing: 40) {
                Button("\u{2039} levels", action: onExit)
                if let share = game.shareText {
                    ShareLink(item: share) { Text("share \u{2197}") }
                        .shareTap()
                        .foregroundStyle(Color.amber).shadow(color: .amber, radius: 4)
                }
                if let next {
                    Button(game.spilled ? "new run \u{203A}" : "next \u{203A}") { onNext(next) }
                        .foregroundStyle(accent).shadow(color: accent, radius: 4)
                }
            }
            .font(.mono(15, .medium))
            if game.level.id == game.level.tier.levels.last?.id, let up = game.level.tier.step(1) {
                TierUp(from: game.level.tier, to: up, onNext: onNext, onExit: onExit)
            }
        }
    }
}

/// The last level of a tier goes on up the ladder, in the next tier's own colours. A tier still closed shows what
/// opens it and goes back to the levels.
private struct TierUp: View {
    let from: Tier
    let to: Tier
    let onNext: (Level) -> Void
    let onExit: () -> Void
    @State private var glint = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let open = to.isOpen()
        Button { open ? onNext(to.levels[0]) : onExit() } label: {
            VStack(spacing: 6) {
                Text(open ? "up a notch" : "par every \(from.name.lowercased()) level to open")
                    .font(.mono(11, .semibold)).tracking(open ? 3 : 0.5).textCase(open ? .uppercase : nil).opacity(0.6)
                HStack(spacing: 10) {
                    if !open { Image(systemName: "lock.fill").font(.system(size: 16, weight: .semibold)) }
                    Text(to.name.uppercased()).font(.system(size: 26, weight: .black).width(.expanded)).tracking(5)
                    if open { Text("\u{203A}").font(.system(size: 26, weight: .black)) }
                }
                .foregroundStyle(to.sweep)
                .shadow(color: to.glow.opacity(glint ? 0.9 : 0.5), radius: glint ? 16 : 9)
            }
            .padding(.horizontal, 26).padding(.vertical, 14)
            .background { Capsule().strokeBorder(to.sweep, lineWidth: 1.5).shadow(color: to.glow, radius: glint ? 10 : 5) }
            .opacity(open ? 1 : 0.45)
        }
        .buttonStyle(Sounding())
        .accessibilityLabel(open ? "Up a notch: \(to.name)" : "\(to.name), locked. Par every \(from.name) level to open it")
        .onAppear {
            guard open, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever()) { glint = true }
        }
    }
}

/// Escapement's standing hint (Jack's call, 2026-10-25): the clock's disc marked at all times, a dashed edge and a faint
/// wash creeping in from it, so every turn that reaches in reads as reaching into the clock.
struct ClockHint: View {
    let radius: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.clear, Color.vermilion.opacity(0.2)], center: .center,
                                         startRadius: 0.55 * radius, endRadius: radius))
            Circle().stroke(Color.vermilion.opacity(0.9), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        }
        .frame(width: 2 * radius, height: 2 * radius)
    }
}

/// Escapement's clock knob: a 12-tooth ratchet wheel that turns clockwise only, a tooth a tick, its index read against a
/// vermilion sub-dial fixed to the glass, and the pawl that drops into it. `pawl` 0 rests in a gap, 1 is lifted clear
/// as a tick rides it out. Stopped, it dims.
struct RatchetView: View {
    let angle: Double
    let size: CGFloat
    let pawl: Double
    let lit: Bool
    let stopped: Bool

    var body: some View {
        let rt = size / 2, rr = size / 2 * 0.74
        let c = CGPoint(x: size, y: size)
        func at(_ a: Double, _ rad: CGFloat) -> CGPoint { CGPoint(x: c.x + rad * sin(a), y: c.y - rad * cos(a)) }
        // Each tooth from its root: a steep rise, then a long slope back down to the next root.
        let wheel = Path { p in
            for i in 0..<12 {
                let a0 = Double(i) * Tank.step
                if i == 0 { p.move(to: at(a0, rr)) } else { p.addLine(to: at(a0, rr)) }
                p.addLine(to: at(a0 + 0.035, rt))
                p.addLine(to: at(a0 + Tank.step, rr))
            }
            p.closeSubpath()
        }
        let dial = Path { p in
            for i in 0..<12 {
                let a = Double(i) * Tank.step
                p.move(to: at(a, rt + 4))
                p.addLine(to: at(a, rt + (i == 0 ? 11 : 7)))
            }
        }
        let tipA = Double.pi / 6 + 0.25
        let pivot = at(1.35, rt * 1.55), tip = at(tipA, rr + (rt - rr) * 0.35 + CGFloat(pawl) * (rt - rr) * 1.1)
        let steel = Color(0xB8BECA)
        return ZStack {
            Circle().fill(Color.black.opacity(0.75)).frame(width: size + 6, height: size + 6).position(c)
            dial.stroke(Color.vermilion.opacity(0.9), style: StrokeStyle(lineWidth: 1, lineCap: .round))
            ZStack {
                wheel.fill(RadialGradient(stops: [.init(color: Color(0xE6EAF2), location: 0), .init(color: Color(0x6E7686), location: 0.5),
                                                  .init(color: Color(0x262A33), location: 1)],
                                          center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: size))
                wheel.stroke(Color.black.opacity(0.85), lineWidth: 1)
                Circle().stroke(Color.black.opacity(0.8), lineWidth: 1.2).frame(width: rr * 1.1, height: rr * 1.1).position(c)
                // The index, so each tick's step reads at a glance against the sub-dial.
                Path { $0.move(to: at(0, rr * 0.25)); $0.addLine(to: at(0, rr * 0.85)) }
                    .stroke(Color.vermilion, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            .rotationEffect(.radians(angle), anchor: .center)
            if lit {
                Circle().stroke(Color.live, lineWidth: 1).frame(width: size + 6, height: size + 6).position(c)
            }
            Path { $0.move(to: pivot); $0.addLine(to: tip) }.stroke(Color.black.opacity(0.9), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
            Path { $0.move(to: pivot); $0.addLine(to: tip) }.stroke(steel, style: StrokeStyle(lineWidth: 2.6, lineCap: .round))
            Circle().fill(Color(0xD8DCE4)).frame(width: 4, height: 4).position(pivot)
        }
        .frame(width: 2 * size, height: 2 * size)
        .opacity(stopped ? 0.5 : 1)
        .animation(.easeOut(duration: 0.12), value: pawl == 1)
    }
}

/// Escapement: "lost." stamped by the clock once a tick pushes or the clock stops with twists left.
struct LostStamp: View {
    var size: CGFloat = 76
    @State private var landed = false

    var body: some View {
        Text("lost.").font(.system(size: size, weight: .bold, design: .serif)).italic()
            .foregroundStyle(Color.vermilion)
            .shadow(color: .black.opacity(0.9), radius: 8)
            .rotationEffect(.degrees(-6))
            .scaleEffect(landed ? 1 : 1.3)
            .opacity(landed ? 1 : 0)
            .onAppear { withAnimation(.easeOut(duration: 0.16)) { landed = true } }
            .allowsHitTesting(false)
    }
}

/// Escapement's lost tank: the move it was lost on, undo if the bank has one, and again, a reset.
struct LostCard: View {
    let game: Game
    let onExit: () -> Void
    let again: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            // No par: beside a loss it reads as a score.
            Text("lost on move \(game.moves)").font(.mono(13))
            HStack(spacing: 32) {
                Button("\u{2039} levels", action: onExit)
                Button("undo \u{00B7} \(game.bank)") { game.undo() }
                    .disabled(game.bank == 0).opacity(game.bank == 0 ? 0.35 : 1)
                Button("again \u{203A}", action: again).foregroundStyle(Color.vermilion).shadow(color: .vermilion, radius: 4)
            }
            .font(.mono(15, .medium))
        }
    }
}
