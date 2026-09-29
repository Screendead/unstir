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

/// An arc from `notch` (clockwise from twelve) as long as `angle`, arrowhead at its far end; positive runs clockwise.
private func arcArrow(center c: CGPoint, radius ar: CGFloat, from notch: Double, angle: Double) -> Path {
    let a0 = notch - Double.pi / 2, a = a0 + angle, dir = angle > 0 ? 1.0 : -1.0
    var p = Path()
    // Moved to first: an arc appended to a path joins its current point with a line.
    p.move(to: CGPoint(x: c.x + ar * cos(a0), y: c.y + ar * sin(a0)))
    p.addArc(center: c, radius: ar, startAngle: .radians(a0), endAngle: .radians(a), clockwise: angle < 0)
    let tip = CGPoint(x: c.x + ar * cos(a), y: c.y + ar * sin(a))
    let back = CGVector(dx: sin(a) * dir * 8, dy: -cos(a) * dir * 8)
    let wing = CGVector(dx: cos(a) * 5, dy: sin(a) * 5)
    p.move(to: CGPoint(x: tip.x + back.dx + wing.dx, y: tip.y + back.dy + wing.dy))
    p.addLine(to: tip)
    p.addLine(to: CGPoint(x: tip.x + back.dx - wing.dx, y: tip.y + back.dy - wing.dy))
    return p
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
    /// since by turns that merged into it. Only a run reads it, and a run has no undo.
    struct Entry: Stacked {
        var twist: Twist
        var pushed: Bool
    }

    private(set) var level: Level
    private var entries: [Entry]
    var stack: [Twist] { entries.map(\.twist) }
    /// Stirs since the last reset, newest last: turns of one rod in a row are one stir, and undo commits a stir's negation.
    /// A rod stir names the rod the stack names (the slot under the knob turned). A turn of the tank is rod `Game.tank`,
    /// in steps of the layout's symmetry.
    private(set) var history: [Twist] = []
    nonisolated static let tank = -1
    /// Whether the next turn of the newest stir's rod joins it. A stir turned back to nothing, or undone, is gone, and the
    /// one before it stays shut.
    private var open = false
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
    /// Endless: notches on the brim, carried from tank to tank through the run. A red flash (a push) adds one, which
    /// stays when the stir is turned back; a heal of one of the scramble's own entries settles one, and cancelling the
    /// player's own push does not. Full, it spills the run.
    private(set) var brim: Int
    /// Every change of `brim`, for the rim to play.
    private(set) var brimEvents: [Brim.Event] = []

    init(level: Level, tankTurned: Bool? = nil, bank: (undos: Int, refilled: String?)? = nil) {
        self.level = level
        entries = level.scramble.map { Entry(twist: $0, pushed: false) }
        brim = level.run?.brim ?? 0
        firstTry = level.run != nil || !Best.started(level.id)
        self.tankTurned = tankTurned ?? Best.tankTurned
        storesTankTurned = tankTurned == nil
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

    /// Practice saves nothing.
    var counts: Bool { firstTry || !level.id.hasPrefix("daily-") }

    /// The sandbox starts on the clean picture, so it is never solved, which keeps it from finishing or saving.
    var solved: Bool { stack.isEmpty && !level.sandbox }
    var par: Int { level.par }
    /// Endless has no par.
    var over: Int { level.run == nil ? max(moves - par, 0) : 0 }
    var spilled: Bool { level.run != nil && brim >= Run.room }
    var finished: Bool { solved || spilled }
    var clean: Bool { over == 0 && resets == 0 && undos == 0 && firstTry }

    func slot(of knob: Int) -> Int { level.layout.slot(of: knob, at: position) }
    func knob(over slot: Int) -> Int { level.layout.knob(over: slot, at: position) }

    /// A turn of knob `rod`, which stirs whatever fluid the tank has brought under it.
    func commit(rod: Int, steps: Int) {
        guard !finished else { return }
        let slot = self.slot(of: rod)
        // Every entry of the scramble's that pops is a heal, even where an entry that the merge lets fall cancels it.
        var healed = 0
        let result = level.seized.contains(rod) ? .refused
            : entries.commit(Entry(twist: Twist(rod: slot, steps: steps), pushed: true), in: level.layout,
                             popped: { if !$0.pushed { healed += 1 } })
        guard result != .refused else { Log.write("commit \(Twist(rod: rod, steps: steps)) refused"); return }
        let brimWas = brim
        // Joins by slot: a turn of the tank between two turns of one knob is a stir of its own.
        if open, history.last?.rod == slot {
            history[history.count - 1].steps += steps
            if history.last!.steps == 0 { history.removeLast(); open = false }
        } else {
            history.append(Twist(rod: slot, steps: steps))
            open = true
        }
        lastCommit = (rod, result)
        turns += 1
        if result == .pushed {
            pushes += 1
            if level.run != nil { brim += 1 }
        }
        if result == .cancelled { cancels += 1; cancelledRod = rod }
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
        if joins { history.removeLast() }
        open = net != 0
        if open { history.append(Twist(rod: Game.tank, steps: net)) }
        Log.write("tank \(steps) position=\(position) moves=\(moves)")
        settle()
    }

    /// Endless has none: it would take back a red flash.
    func undo() {
        // The sandbox counts nothing, so its undos are free.
        guard !finished, !checking, level.run == nil, level.sandbox || bank > 0, let last = history.popLast() else { return }
        if last.rod != Game.tank {
            entries.commit(Entry(twist: Twist(rod: last.rod, steps: -last.steps), pushed: true), in: level.layout)
            // A white flash whatever the stack did: undo bumps neither pushes nor cancels, so no alarm or thunk may show.
            lastCommit = (knob(over: last.rod), .reduced)
            turns += 1
        }
        open = false
        if !level.sandbox {
            undos += 1
            bank -= 1
            if storesBank { Best.undos = bank }
        }
        Log.write("undo \(last) moves=\(moves) bank=\(bank) pushes=\(pushes) stack=\(stack.count) \(stack)")
        settle()
    }

    /// False when refused, so the caller skips the opening replay. Endless has none: it would bring back entries the brim
    /// has already settled on.
    @discardableResult func reset() -> Bool {
        guard !checking, level.run == nil else { return false }
        entries = level.scramble.map { Entry(twist: $0, pushed: false) }
        history = []
        open = false
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
        level.layout = level.layout.next
        level.scramble = []
        // The rings parked on the last commit and cancel may name a rod the new layout lacks.
        lastCommit = nil
        cancelledRod = 0
        Log.write("layout \(level.layout)")
        reset()
    }

    /// The newest twist a working knob can take off now, as that knob's turn: what autoplay and the harness play.
    var reachable: Twist? {
        level.layout.removable(stack).reversed().map { Twist(rod: knob(over: stack[$0].rod), steps: -stack[$0].steps) }
            .first { !level.seized.contains($0.rod) }
    }

    /// A knob's two-step turn that would push a new entry, a red flash: what the harness's brim demo wastes.
    var wasting: Twist? {
        level.layout.rods.indices.filter { !level.seized.contains($0) }.lazy.compactMap { k -> Twist? in
            var s = self.stack
            return s.commit(rod: self.slot(of: k), steps: 2, in: self.level.layout) == .pushed ? Twist(rod: k, steps: 2) : nil
        }.first
    }

    /// `healed`: the move that led here healed one of the scramble's entries.
    private func settle(healed: Bool = false) {
        // Refusing a win the picture already shows is the bug players hit, and a residual under half a pixel is invisible.
        // Only the coarse pass runs here: the fine one takes ~0.1 s exactly when it passes, which would hitch the win.
        if !spilled && !entries.isEmpty && level.layout.same(stack, [], at: Tank.samples, within: Tank.halfPixel) {
            let stack = stack, layout = level.layout
            checking = true
            Task {
                let solved = await Task.detached(priority: .userInitiated) { layout.looksSolved(stack) }.value
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
                    self.entries = []
                }
                self.finish()
            }
            return
        }
        finish()
    }

    private func finish() {
        guard finished else { return }
        seconds = Int(Date.now.timeIntervalSince(start ?? .now))
        Log.write("\(solved ? "solved" : "spilled") \(level.id) moves=\(moves) "
                  + "\(level.run == nil ? "par=\(par)" : "brim=\(brim)") seconds=\(seconds) counts=\(counts)")
        if let run = level.run {
            if solved { Best.tanks = max(Best.tanks, run.tank + 1) }
        } else if solved && counts {
            Best(over: over, seconds: seconds, clean: clean).save(level.id)
        }
    }
}

/// What a finger on the tank holds.
enum Grab: Equatable {
    case rod(Int)
    case rim
    /// In two or more discs, before the finger has moved far enough to say which: the ones it could turn.
    case undecided([Int])
    /// A seized knob's disc: it holds nothing, and the knob shakes.
    case seized(Int)
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
    /// The touch it belongs to, where it was first seen (tank units), what it holds, and its last angle about that.
    @State private var drag: (start: CGPoint, from: SIMD2<Double>, grab: Grab, last: Double)?
    /// The finger's latest point in tank units, kept after it lifts so a count left showing stays put.
    @State private var finger: SIMD2<Double>?
    /// The knob, or `Game.tank`, touched last: its open stir's count stays up, faint, after letting go.
    @State private var counted: Int?
    @State private var grabs = 0
    /// The seized knob touched last, and every such touch: it shakes, the rim pulses and a thud plays.
    @State private var jammed: Int?
    @State private var jams = 0
    @State private var tick = 0
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
    private let bench: Bool
    /// UNSTIR_WAVE: the solve wave held at this radius.
    private let frozenWave: Double?
    /// UNSTIR_CLOCK: a live background, and the rim's ghost finger, held at this many seconds.
    private let frozenClock: Double?
    /// UNSTIR_SHAKE: a seized knob's shake and the rim's pulse held this many seconds in.
    private let frozenShake: Double?
    /// UNSTIR_TODAY: the day the level opens on, for the bank's refill.
    private let today: String?
    /// A live picture: its clock starts at zero on every visit.
    @State private var opened = Date.now
    /// Endless: the picture's colours round the rim as the stack stirs it (Brim.colours), once worked out.
    @State private var rimColours: (hue: [Float], lines: [Float])?
    /// Endless: the brim changed lately enough that the rim is still moving.
    @State private var brimMoving = false
    /// The picture has landed and struck.
    @State private var struck = false
    private let brimDemo: Bool
    let onExit: () -> Void
    let onNext: (Level) -> Void

    init(level: Level, harness: Harness?, onExit: @escaping () -> Void, onNext: @escaping (Level) -> Void) {
        let game = Game(level: level, tankTurned: harness?.tankTurned, bank: harness?.bank)
        game.turnTank(harness?.tank ?? 0)
        if let h = harness, h.screen == "result" || h.screen == "clean" || h.wave != nil {
            // Solved through the real commit path; "result" first wastes two stirs, so taking them back costs moves.
            if h.screen == "result", let top = game.stack.last {
                let count = level.layout.rods.count, home = game.knob(over: top.rod)
                let wrong = (1..<count).map { (home + $0) % count }.filter { !level.seized.contains($0) }
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
        _game = State(initialValue: game)
        let live = harness?.live, angle = (live?.steps ?? 0) * Tank.step, turn = harness?.tankLive.map { $0 * .pi / 180 }
        _liveRod = State(initialValue: live?.rod)
        _liveAngle = State(initialValue: angle)
        _liveTurn = State(initialValue: turn)
        _counted = State(initialValue: harness?.turned?.rod)
        if let p = harness?.touch {
            // The finger that went down at p, carried round with the turn it holds.
            let grab: Grab = live.map { .rod($0.rod) } ?? (turn != nil ? .rim
                : LevelView.grab(level.layout, seized: level.seized, from: p, to: p, slop: 1))
            let pivot = live.map { SIMD2(level.layout.rods[$0.rod].x, level.layout.rods[$0.rod].y) } ?? .zero
            let a = live != nil ? angle : turn ?? 0, d = p - pivot
            _drag = State(initialValue: (.zero, p, grab, 0))
            _finger = State(initialValue: pivot + SIMD2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a)))
            switch grab {
            case .rod(let k): _liveRod = State(initialValue: k); _counted = State(initialValue: k)
            case .rim: _liveTurn = State(initialValue: turn ?? 0); _counted = State(initialValue: Game.tank)
            case .seized(let k): _jammed = State(initialValue: k)
            case .undecided, .nothing: break
            }
        }
        // A spill's card waits for the pour, so a harness launch that spills shows it only if held past then.
        _showResult = State(initialValue: game.finished && harness?.wave == nil
                            && (!game.spilled || (harness?.clock ?? 0) >= Brim.card))
        _eased = State(initialValue: game.solved)
        still = harness?.still ?? false
        autoplay = harness?.autoplay ?? false
        brimDemo = harness?.brimDemo ?? false
        bench = harness?.bench ?? false
        frozenWave = harness?.wave
        frozenClock = harness?.clock
        frozenShake = harness?.shake
        today = harness?.today
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
                    Button("\u{2039} levels", action: onExit)
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
                Text(shown == nil ? game.counts ? game.level.note : "Practice: only the first try counts."
                     : game.level.replay ? "watch the stir \u{00B7} tap to skip" : "tap to skip")
                    .font(.mono(12)).opacity(showResult ? 0 : 0.55).multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .top)
                    .padding(.top, 14)
                    .overlay(alignment: .top) {
                        if showResult {
                            ResultCard(game: game, onExit: onExit, onNext: onNext)
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
                        // The plain button style does not grey a disabled label.
                        .disabled(!game.level.sandbox && game.bank == 0)
                        .opacity(!game.level.sandbox && game.bank == 0 ? 0.35 : 1)
                        .overlay(alignment: .topTrailing) { refillBadge }
                    Spacer()
                    control("reset") { if game.reset() { replays += 1 } }
                }
                // Endless has neither (`Game.undo`, `Game.reset`); hidden rather than gone, so its tank sits where every
                // other level's does.
                .disabled(settling || game.finished || shown != nil || game.level.run != nil)
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
            if !game.level.sandbox, replays > 0 || !still { await open() }
            if autoplay && replays == 0 { await play() }
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
            // Past the picture's first render, so the bake does not land in the numbers.
            guard bench, (try? await Task.sleep(for: .seconds(1))) != nil else { return }
            Bench(drive: { liveRod = 0; liveAngle = 3 * sin(2 * $0) },
                  still: game.level.picture.isLive ? { liveRod = nil; liveAngle = 0 } : nil).start()
        }
        .onChange(of: shown == nil, initial: true) {
            if shown == nil { game.startClock(); badge = game.refilled }
        }
        .onChange(of: game.finished) {
            guard game.finished else { return }
            // The fine pass can call the win ~0.1 s after the commit: a finger down in that gap would hold its turn frozen
            // over the win, then have the commit refused on lift.
            drag = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; spun = false
            // Its own transaction: an animated one also glides every shader argument that changed with the win, the wave's
            // centre among them.
            if game.solved { withAnimation(.easeInOut(duration: 0.9)) { eased = true } }
            Task {
                // A spill's card waits for the pour and the word.
                try? await Task.sleep(for: .seconds(game.spilled ? Brim.card : 1.4))
                withAnimation(.easeIn(duration: 0.3)) { showResult = true }
                Log.write("result shown")
            }
        }
        // SwiftUI never calls onEnded for a cancelled drag (lock, Siri, a call), so drop the uncommitted turn here. Only on
        // the way out: the launch's own turn to active would drop a finger the harness holds.
        .onChange(of: phase) {
            if phase != .active, drag != nil || spun {
                Log.write("\(phase) drops drag \(state)"); drag = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; spun = false
            }
        }
        .onAppear {
            let rules = game.level.run.map { "tank \($0.tank) brim \($0.brim)" } ?? "par \(game.par)"
            Log.write("level \(game.level.id) opens, \(rules) \(game.stack)")
            // Not in Game.init: SwiftUI reruns LevelView.init for a level it already shows, on a game it then drops.
            if let today { game.refill(today: today) } else { game.refill() }
            // Where there is no opening, onChange's initial call may run before the refill.
            if shown == nil { badge = game.refilled }
        }
        .onDisappear { Log.write("level \(game.level.id) exits \(state)") }
    }

    /// Everything that decides what the tank draws, as the log shows it.
    private var state: String {
        "shown=\(Log.opt(shown)) wind=\(wind) live=\(Log.opt(liveRod)) angle=\(liveAngle) turn=\(liveTurn.map { "\($0)" } ?? "nil") "
            + "drag=\(drag.map { "\($0.grab)" } ?? "nil") settling=\(settling) position=\(game.position) "
            + "moves=\(game.moves) pushes=\(game.pushes) stack=\(game.stack.count) \(game.stack)"
    }

    private var stack: [Twist] { shown.map { Array(game.stack.prefix($0)) } ?? game.stack }
    private var rods: [SIMD3<Double>] { game.level.layout.rods }
    private func centre(_ k: Int) -> SIMD2<Double> { SIMD2(rods[k].x, rods[k].y) }

    /// Replay levels play the scramble forward from the clean picture, so the last rod seen turning is the top of the
    /// stack. The rest wind every twist in together from the clean picture.
    private func open() async {
        Log.write("open starts \(state)")
        defer { Log.write("open ends\(Task.isCancelled ? ", cancelled" : "") \(state)") }
        let scramble = game.stack
        // A reset can land while a finger holds the rim.
        shown = 0; liveRod = nil; liveAngle = 0; drag = nil; liveTurn = nil; spun = false
        if !game.level.replay { wind = 0; shown = scramble.count }
        guard await pause(1) else { return }
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
            guard (try? await Task.sleep(for: .seconds(0.3))) != nil else { return }
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
        .buttonStyle(.plain)
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
        let core = 2 * Tank.coreRadius * r
        let probing = shown == nil ? liveRod : nil
        // Solid once letting go would commit a twist; dashed while it would cost nothing or a full stack would refuse it.
        // Array.commit's overlap rule, checked without copying the stack or sampling the map every drag frame.
        let commits = liveRod.map { k in
            let s = game.slot(of: k)
            return Int((liveAngle / Tank.step).rounded()) != 0 && (game.stack.count < Tank.maxStack
                || game.stack.last { game.level.layout.overlaps($0.rod, s) }?.rod == s)
        } ?? false
        let step = game.level.layout.tankStep
        let held = liveTurn.map { $0 + (spin ?? 0) }
        let turn = eased ? (Double(game.position) / Double(game.level.layout.order)).rounded() * 2 * .pi
            : Double(game.position) * step + (held ?? 0)
        let unstirred = Unstirred(stack: stack, layout: game.level.layout, liveRod: liveRod.map(game.slot(of:)), liveAngle: liveAngle,
                                  wind: wind, side: side, haze: showResult ? min(0.12 * Double(game.over), 0.6) : 0, turn: turn,
                                  fillEntries: game.level.picture.fillEntries)
        // The wave is drawn on the screen, not the glass, so it holds still on the knob while the glass eases home.
        let source = game.history.last.map { $0.rod == Game.tank ? .zero : centre(game.knob(over: $0.rod)) } ?? centre(0)
        let frozenWave = frozenWave
        let flash = game.lastCommit
        let pending: [Int] = if shown == nil, case .undecided(let ks)? = drag?.grab { ks } else { [] }
        func lit(_ k: Int) -> Double { probing == k ? 1 : pending.contains(k) ? 0.45 : 0 }
        // The player's own turning only, never the stack: the open stir a turn would join, plus the turn in hand.
        let stir = game.openStir
        func joined(_ rod: Int) -> Int { stir?.rod == rod ? stir!.steps : 0 }
        let rodCount: (k: Int, steps: Int, live: Bool)? = if let k = probing {
            (k, joined(game.slot(of: k)) + Int((liveAngle / Tank.step).rounded()), true)
        } else if let k = counted, rods.indices.contains(k), held == nil, shown == nil, !game.finished {
            (k, joined(game.slot(of: k)), false)
        } else {
            nil
        }
        let tankCount: (steps: Int, live: Bool)? = if let held, shown == nil {
            (game.tankStir(after: Int((held / step).rounded())), true)
        } else if counted == Game.tank, shown == nil, !game.finished {
            (joined(Game.tank), false)
        } else {
            nil
        }
        // Out of the way while the tank is held.
        let lesson = shown == nil && !game.finished && held == nil
        let arc = !game.level.seized.isEmpty && lesson && !game.tankTurned ? RimLesson.arc(r) : []
        let others: [(CGPoint, CGFloat)] = rods.indices.filter { $0 != rodCount?.k }.map { (at($0), core / 2 + Self.countRoom) }
            + arc.map { ($0, RimLesson.width + Self.countRoom) }
        // Endless: when the push that spilled the brim was made. UNSTIR_CLOCK holds the brim that long after its last change.
        let spillAt = game.spilled ? game.brimEvents.last?.time : nil
        // A live picture is the only kind that redraws while the player is still; 60 Hz is plenty for motion this slow.
        // Every other picture pauses the timeline, so nothing ticks, except while a spill stirs it together.
        let moving = game.level.picture.isLive || spillAt != nil && brimMoving
        return ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !moving || frozenClock != nil)) { timeline in
                let murk = spillAt.flatMap { at -> [Float]? in
                    let since = (frozenClock ?? timeline.date.timeIntervalSinceReferenceDate - at) - Brim.murk
                    return since > 0 ? Brim.murk(game.level.layout, seed: game.level.run?.seed ?? 0, at: since) : nil
                } ?? []
                PictureLayer(picture: game.level.picture, side: side, seed: Int(game.level.label) ?? 0,
                             clock: frozenClock ?? timeline.date.timeIntervalSince(opened), onStrike: { struck = true })
                    .keyframeAnimator(initialValue: -1.0, trigger: game.solved) { picture, w in
                        var u = unstirred
                        u.wave = SIMD3(Float(source.x), Float(source.y), Float(frozenWave ?? w))
                        return picture.modifier(u).modifier(Murk(stirs: murk, side: side))
                    } keyframes: { _ in
                        // A light wave from the last-turned rod, over the clean picture. The animator holds its last value, so
                        // the band runs out past the farthest rim of any layout (1.56 from a ring rod) rather than parking on it.
                        MoveKeyframe(0.0)
                        LinearKeyframe(1.9, duration: 0.9, timingCurve: .easeOut)
                    }
            }
            .clipShape(Circle())
            if let held {
                // The tank's live ring: solid once letting go would turn it, dashed while it would come back where it was.
                let turns = Int((held / step).rounded()) % game.level.layout.order != 0
                Circle().inset(by: 1.5)
                    .stroke(Color.live.opacity(turns ? 1 : 0.65), style: StrokeStyle(lineWidth: turns ? 2 : 1.5, dash: turns ? [] : [6, 6]))
                    .shadow(color: .live.opacity(turns ? 0.6 : 0), radius: 4)
            }
            ForEach(rods.indices.filter { lit($0) > 0 }, id: \.self) { k in
                grabbed(lit(k), dashed: probing != k)
                    .frame(width: 2 * rods[k].z * r, height: 2 * rods[k].z * r)
                    .position(at(k))
            }
            if let k = liveRod {
                Group {
                    if shown != nil {
                        glowRing(.magenta, 2.5, 6, under: .black.opacity(0.7))
                    } else if commits {
                        Circle().stroke(Color.live, lineWidth: 2).shadow(color: .live.opacity(0.6), radius: 4)
                    } else {
                        Circle().stroke(Color.live.opacity(0.65), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                    }
                }
                .frame(width: 2 * rods[k].z * r, height: 2 * rods[k].z * r)
                .position(at(k))
            }
            if let k = probing {
                // Where the notch started: turn it back to here and letting go costs nothing.
                Capsule().fill(Color.live.opacity(0.7)).frame(width: 2.5, height: 16)
                    .offset(y: -rods[k].z * r)
                    .rotationEffect(.radians(turned(k)))
                    .position(at(k))
            }
            if held != nil {
                Capsule().fill(Color.live.opacity(0.7)).frame(width: 2.5, height: 16)
                    .offset(y: 8 - r)
                    .rotationEffect(.radians(Double(game.position) * step))
            }
            if let c = rodCount, c.steps != 0 {
                let from = turned(c.k) - Double(joined(game.slot(of: c.k))) * Tank.step
                stepArc(at(c.k), rods[c.k].z * r - 14, from: from, to: turned(c.k) + (c.live ? liveAngle : 0), steps: c.steps,
                        step: Tank.step)
                    .opacity(c.live ? 1 : 0.45)
            }
            if let c = tankCount, c.steps != 0 {
                stepArc(CGPoint(x: r, y: r), r - 16, from: Double(game.position - joined(Game.tank)) * step,
                        to: Double(game.position) * step + (held ?? 0), steps: c.steps, step: step)
                    .opacity(c.live ? 1 : 0.45)
            }
            // Always present, so the first commit on a rod animates rather than inserting a view that never sees its trigger change.
            // Black under the stroke, so red still reads over the grid's red and magenta lines.
            let fk = flash?.rod ?? 0, pushed = flash?.result == .pushed
            glowRing(pushed ? .alarm : .live, 2.5, 6, under: .black.opacity(0.7))
                .frame(width: 2 * rods[fk].z * r, height: 2 * rods[fk].z * r)
                .keyframeAnimator(initialValue: 1.0, trigger: game.turns) { ring, t in
                    ring.scaleEffect(1 + 0.05 * t).opacity(t >= 1 ? 0 : 0.9 * (1 - t))
                } keyframes: { _ in
                    // Full on the frame the live ring goes, so nothing blinks between them.
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: pushed ? 0.4 : 0.3, timingCurve: .easeOut)
                }
                .position(at(fk))
            Bezel(r: r)
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
            if !game.level.seized.isEmpty {
                KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                    RimLesson(r: r, showing: lesson && !game.tankTurned, pulse: lesson && jammed != nil ? Self.pulse(frozenShake ?? s) : 0,
                              clock: frozenClock)
                } keyframes: { _ in Self.jolt }
            }
            let ck = game.cancelledRod, disc = 2 * rods[ck].z * r
            glowRing(.magenta, 3, 12, under: .magenta.opacity(0.3))
                .keyframeAnimator(initialValue: 1.0, trigger: game.cancels) { ring, t in
                    // Grown by frame, not scale, so the stroke stays 3 pt out to the disc edge.
                    ring.frame(width: disc * (0.3 + 0.7 * t), height: disc * (0.3 + 0.7 * t)).opacity(t >= 1 ? 0 : 0.9 * (1 - t * t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 0.45, timingCurve: .easeOut)
                }
                .position(at(ck))
            ForEach(rods.indices, id: \.self) { k in
                // On a device pixel, so the knob's ticks can be.
                let p = at(k)
                KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                    RodView(angle: turned(k) + (probing == k ? liveAngle : 0) + (jammed == k ? Self.shake(frozenShake ?? s) : 0),
                            size: core, seized: game.level.seized.contains(k), grabbed: lit(k))
                } keyframes: { _ in Self.jolt }
                    .position(x: (p.x * scale).rounded() / scale, y: (p.y * scale).rounded() / scale)
            }
            // A spilled tank keeps its caps over the murk.
            .opacity(showResult && !game.spilled ? 0 : 1)
            if let spillAt {
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !brimMoving || frozenClock != nil)) { timeline in
                    SpillWords(r: r, at: frozenClock ?? timeline.date.timeIntervalSinceReferenceDate - spillAt)
                }
            }
            if let c = rodCount, c.steps != 0 {
                countLabel(c.steps).opacity(c.live ? 1 : 0.45)
                    .position(countSpot(at(c.k), reach: rods[c.k].z * r + 22, side: side, avoid: others))
            }
            if let c = tankCount, c.steps != 0 {
                countLabel(c.steps).opacity(c.live ? 1 : 0.45).position(countSpot(CGPoint(x: r, y: r), reach: 1.045 * r + 16, side: side))
            }
        }
        .frame(width: side, height: side)
        .keyframeAnimator(initialValue: 0.0, trigger: game.solved) { tank, t in
            tank.scaleEffect(1 + 0.02 * sin(t * .pi))
        } keyframes: { _ in CubicKeyframe(1.0, duration: 0.9) }
        // A level that turns reaches a finger on the bezel or just beyond it.
        .contentShape(Circle().inset(by: game.level.seized.isEmpty ? 0 : -25))
        .gesture(twistGesture(r))
        // Not .none: that also switches off the gesture above.
        .simultaneousGesture(spinGesture, including: game.level.seized.isEmpty ? .subviews : .all)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.7), trigger: grabs)
        .sensoryFeedback(.selection, trigger: ticks)
        .onChange(of: tankTicks) { Knock.clunk.play() }
        .sensoryFeedback(.impact(weight: .heavy), trigger: game.cancels)
        .sensoryFeedback(.warning, trigger: game.pushes)
        .sensoryFeedback(.success, trigger: game.solved) { _, solved in solved }
        // Keeps texture pixels on device pixels, so the untwisted picture is not blurred by half a pixel.
        .offset(snap)
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { o in
            snap = CGSize(width: (o.x * scale).rounded() / scale - o.x, height: (o.y * scale).rounded() / scale - o.y)
        }
        .padding(0.045 * r)
    }

    /// A disc a finger holds, or may be about to: a dark band under its edge, so the live ring reads on any picture, and
    /// a glowing halo just outside it. A disc still waiting on the finger's motion has no live ring, so it draws its own,
    /// dashed as nothing would commit.
    private func grabbed(_ strength: Double, dashed: Bool) -> some View {
        ZStack {
            Circle().stroke(Color.black.opacity(0.55 * strength), lineWidth: 8)
            Circle().stroke(Color.live.opacity(0.8 * strength), lineWidth: 2).shadow(color: .live.opacity(strength), radius: 6)
                .padding(-6)
            if dashed { Circle().stroke(Color.live.opacity(0.65), style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])) }
        }
    }

    /// A turn's own count round a circle about `c`, angles clockwise from twelve: one lit segment per step from `from`
    /// the way the turn runs, over a thin trace out to where it stands now.
    private func stepArc(_ c: CGPoint, _ radius: CGFloat, from origin: Double, to now: Double, steps: Int, step: Double) -> some View {
        // Each arc moved to first: an arc appended to a path joins its current point with a line.
        func arc(_ p: inout Path, _ a: Double, _ b: Double) {
            p.move(to: CGPoint(x: c.x + radius * sin(a), y: c.y - radius * cos(a)))
            p.addArc(center: c, radius: radius, startAngle: .radians(a - .pi / 2), endAngle: .radians(b - .pi / 2), clockwise: b < a)
        }
        let dir = steps > 0 ? 1.0 : -1.0, gap = 3 / Double(radius)
        let segments = Path { p in
            for i in 0..<abs(steps) { arc(&p, origin + dir * (Double(i) * step + gap), origin + dir * (Double(i + 1) * step - gap)) }
        }
        let trace = Path { arc(&$0, origin, now) }
        return ZStack {
            segments.stroke(Color.black.opacity(0.55), lineWidth: 7)
            trace.stroke(Color.live.opacity(0.5), lineWidth: 1.5)
            segments.stroke(Color.live, lineWidth: 3.5).shadow(color: .live.opacity(0.7), radius: 3)
        }
    }

    private func countLabel(_ steps: Int) -> some View {
        Text(steps > 0 ? "+\(steps)" : "\u{2212}\(-steps)").font(.mono(13, .semibold)).foregroundStyle(Color.live)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(Color.black.opacity(0.6)))
    }

    /// Room for a count round its centre: half its width at two digits.
    private static let countRoom: CGFloat = 18

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
                guard !settling, !game.finished, shown == nil else { return }
                let q = norm(v.location)
                let seized = game.level.seized, layout = game.level.layout
                // Keyed on the start point because a cancelled drag never reaches onEnded; a new touch starts afresh.
                if drag?.start != v.startLocation {
                    drag = nil; liveRod = nil; liveAngle = 0
                    // A twist cancelled without onEnded leaves its turn behind.
                    if spin == nil { liveTurn = nil; spun = false }
                    // From the current point, so a drag picked up again after a reset's stir does not jump.
                    drag = (v.startLocation, q, Self.grab(layout, seized: seized, from: q, to: q, slop: slop / r), 0)
                    Log.write("touch \(drag!.grab)")
                    tick = 0
                    hold()
                } else if case .undecided = drag!.grab {
                    let grab = Self.grab(layout, seized: seized, from: drag!.from, to: q, slop: slop / r)
                    if grab != drag!.grab {
                        drag!.grab = grab; Log.write("picked \(grab) by motion"); hold()
                        if let pivot = pivot(grab) {
                            let d = q - pivot
                            drag!.last = Self.pickedFrom(drag!.last, now: atan2(d.y, d.x))
                        }
                    }
                }
                finger = q
                guard let g = drag, let pivot = pivot(g.grab) else { return }
                let d = q - pivot
                let a = atan2(d.y, d.x)
                drag!.last = a
                // Two fingers turn the tank while they are down.
                guard !spun else { return }
                // Near the pivot the angle is noise; track it without turning.
                let da = simd_length(d) > 0.1 ? atan2(sin(a - g.last), cos(a - g.last)) : 0
                if g.grab != .rim {
                    liveAngle += da
                    let t = Int((liveAngle / Tank.step).rounded(.towardZero))
                    if t != tick { tick = t; ticks += 1 }
                } else if let turn = liveTurn {
                    liveTurn = turn + da
                    tickTank(turn + da)
                }
            }
            .onEnded { _ in
                if shown != nil {
                    // Past 1, so the value changes and cuts short a wind-in still animating towards 1.
                    shown = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; wind = 2
                    Log.write("skip \(state)")
                    return
                }
                guard let g = drag else { return }
                drag = nil
                switch g.grab {
                case .rod(let k): release(k)
                case .rim: if !spun { releaseTank() }
                case .undecided: Log.write("lifted undecided")
                case .seized, .nothing: break
                }
            }
    }

    /// A finger's travel before an overlap's rods are told apart by it.
    private let slop: CGFloat = 8

    private func pivot(_ grab: Grab) -> SIMD2<Double>? {
        switch grab {
        case .rod(let k): centre(k)
        case .rim: .zero
        case .undecided, .seized, .nothing: nil
        }
    }

    /// Takes up what the drag has just come to hold, its angle counted from where the finger was first seen, so the
    /// travel that picked a rod turns it too. A seized knob refuses it.
    private func hold() {
        if case .seized(let k)? = drag?.grab {
            jammed = k
            jams += 1
            Knock.thud.play()
        }
        guard let g = drag, let pivot = pivot(g.grab) else { return }
        let d = g.from - pivot
        drag!.last = atan2(d.y, d.x)
        if case .rod(let k) = g.grab { liveRod = k; counted = k; grabs += 1 } else { liveTurn = 0; counted = Game.tank }
        if !game.level.sandbox { Best.start(game.level.id) }
    }

    /// Motion within this of the best rod's tangent fits that rod too.
    nonisolated static let tie = 15 * Double.pi / 180

    /// Under half a step: the most a rod picked by motion catches up with the finger at once, so the pick alone never
    /// commits a step. Past it, near a centre, the rod trails the finger.
    nonisolated static let catchUp = 10 * Double.pi / 180

    /// The angle about its pivot that a rod picked by motion counts its turn from: where the finger went down, `down`,
    /// but no more than `catchUp` behind where it is, `now`.
    nonisolated static func pickedFrom(_ down: Double, now: Double) -> Double {
        now - min(max(atan2(sin(now - down), cos(now - down)), -catchUp), catchUp)
    }

    /// What a finger that went down at `start` and is now at `point` (tank units) holds. Where knobs are seized the rim
    /// wins over the discs that reach it. A lone disc is held at once. Where discs overlap, once the finger has moved
    /// `slop`, it holds the rod whose turn best explains the motion: the one whose tangent at `start` lies nearest the
    /// motion's line. Near the line between two centres the tangents agree, so among those within `tie` of the best the
    /// nearest centre, in its own disc's radius, wins. A seized knob that wins holds nothing, rather than passing the
    /// finger to a neighbour, and so does a finger only in seized discs, which takes the nearest.
    nonisolated static func grab(_ layout: Layout, seized: Set<Int>, from start: SIMD2<Double>, to point: SIMD2<Double>,
                                 slop: Double) -> Grab {
        if !seized.isEmpty && simd_length(start) > 0.93 { return .rim }
        let rods = layout.rods
        func centre(_ k: Int) -> SIMD2<Double> { SIMD2(rods[k].x, rods[k].y) }
        func held(_ k: Int) -> Grab { seized.contains(k) ? .seized(k) : .rod(k) }
        func nearest(_ ks: [Int]) -> Int {
            ks.min { simd_distance(start, centre($0)) / rods[$0].z < simd_distance(start, centre($1)) / rods[$1].z }!
        }
        let under = rods.indices.filter { simd_distance(start, centre($0)) < rods[$0].z }
        guard under.count > 1 else { return under.first.map(held) ?? .nothing }
        guard simd_distance(point, start) >= slop else {
            let free = under.filter { !seized.contains($0) }
            return free.isEmpty ? held(nearest(under)) : .undecided(free)
        }
        let move = simd_normalize(point - start)
        // No rod's centre lies inside another's disc, so start is never on a centre it is weighed against.
        let off = under.map { asin(min(abs(simd_dot(move, simd_normalize(start - centre($0)))), 1)) }
        let best = off.min()!
        return held(nearest(under.indices.filter { off[$0] < best + tie }.map { under[$0] }))
    }

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
                spun = true
                if liveTurn == nil {
                    drag?.grab = .rim; liveRod = nil; liveAngle = 0; liveTurn = 0; counted = Game.tank
                    Log.write("spin \(state)")
                    tick = 0
                }
                tickTank(liveTurn! + v.rotation.radians)
            }
            .onEnded { v in
                guard spun else { return }
                spun = false
                guard shown == nil, let turn = liveTurn else { return }
                liveTurn = turn + v.rotation.radians
                releaseTank()
            }
    }

    /// A heavier click than a rod's, once per step of the tank.
    private func tickTank(_ turn: Double) {
        let t = Int((turn / game.level.layout.tankStep).rounded(.towardZero))
        if t != tick { tick = t; tankTicks += 1 }
    }

    private func releaseTank() {
        guard !settling, let turn = liveTurn else { return }
        let step = game.level.layout.tankStep, steps = Int((turn / step).rounded())
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
        let steps = Int((liveAngle / Tank.step).rounded())
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

/// The tank's own haptics, on one engine.
@MainActor enum Knock {
    /// A step of the tank: a dull knock and a short low rumble dying under it, so it reads as neither a rod's tick nor
    /// the heal's heavy tap.
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
            floats.append(Float(rods[rod].z)); floats.append(Float(angle))
        }
        for t in stack { add(t.rod, Double(t.steps) * Tank.step * min(wind, 1)) }
        if let liveRod { add(liveRod, liveAngle) }
        let n = floats.count / 4
        if floats.isEmpty { floats = [0, 0, 0, 0] }
        let r = side / 2
        // A live picture keeps four taps only to `Tank.fourTaps` entries less its fill: the same budget as without it.
        // Counted in committed entries, so a touch never changes the taps; the drag rides one over, within the 31 the
        // shader's comment measured.
        let fourTaps = Float(Tank.fourTaps - fillEntries) + (liveRod == nil ? 0 : 1)
        return content.layerEffect(
            ShaderLibrary.unstir(.float2(r, r), .float(r), .floatArray(floats), .float(Float(n)), .float(fourTaps), .float(Float(Tank.plateau)),
                                 .float(Float(scale)), .float(Float(haze)), .float3(wave.x, wave.y, wave.z), .float(Float(turn))),
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
            image = picture.isLive ? UIImage() : picture.render(side: side, scale: scale)
        }
    }
}

/// How to turn the tank, drawn over the bezel of glass of radius `r`: a two-headed amber arc just outside it at the top
/// and a ghost finger rocking along the rim under it, one way and back, so it names the control and never the move.
/// `pulse` (0 to 1) swells the arc, and brings it back for a moment once it has stopped showing.
struct RimLesson: View {
    let r: CGFloat
    let showing: Bool
    let pulse: Double
    /// Holds the ghost finger this many seconds in.
    let clock: Double?
    private static let span = 34 * Double.pi / 180, sweep = 26 * Double.pi / 180, period = 3.6
    /// The arc's stroke at the height of its pulse. Nothing of it, arrowheads included, lies further than this from its line.
    static let width: CGFloat = 14

    private static func radius(_ r: CGFloat) -> CGFloat { 1.045 * r + 10 }

    /// Points every 2° along the arc: whatever keeps off the arc keeps off these.
    static func arc(_ r: CGFloat) -> [CGPoint] {
        stride(from: -span, through: span, by: .pi / 90).map { CGPoint(x: r + radius(r) * sin($0), y: r - radius(r) * cos($0)) }
    }

    var body: some View {
        let c = CGPoint(x: r, y: r)
        var arrow = arcArrow(center: c, radius: Self.radius(r), from: 0, angle: Self.span)
        arrow.addPath(arcArrow(center: c, radius: Self.radius(r), from: 0, angle: -Self.span))
        return ZStack {
            if showing {
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: clock != nil)) { timeline in
                    let a = Self.sweep * sin(2 * .pi * (clock ?? timeline.date.timeIntervalSinceReferenceDate) / Self.period)
                    Circle().fill(Color.live.opacity(0.22))
                        .overlay(Circle().stroke(Color.live.opacity(0.6), lineWidth: 1.5))
                        .shadow(color: .live.opacity(0.4), radius: 6)
                        .frame(width: 30, height: 30)
                        .position(x: r + 1.0225 * r * sin(a), y: r - 1.0225 * r * cos(a))
                }
            }
            arrow.stroke(Color.amber.opacity(0.22 + 0.3 * pulse), style: StrokeStyle(lineWidth: Self.width - 6 * (1 - pulse), lineCap: .round, lineJoin: .round))
            arrow.stroke(Color.amber, style: StrokeStyle(lineWidth: 3 + 1.5 * pulse, lineCap: .round, lineJoin: .round))
        }
        .frame(width: 2 * r, height: 2 * r)
        .opacity(showing ? 1 : pulse)
    }
}

struct RodView: View {
    let angle: Double
    let size: CGFloat
    var seized = false
    /// 1 while a finger holds the knob, less while it may be about to.
    var grabbed = 0.0
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
            if grabbed > 0 {
                Circle().stroke(Color.live.opacity(grabbed), lineWidth: 2).shadow(color: .live.opacity(0.9 * grabbed), radius: 5)
                    .padding(-7)
            }
            Circle().strokeBorder(Color.black.opacity(0.7), lineWidth: 3).padding(-3)
            ticks(rim + px(2 / 3), rim + px(8 / 3)).stroke(lit.opacity(0.5), lineWidth: width)
        }
    }

    private func px(_ points: CGFloat) -> CGFloat { (points * scale).rounded() / scale }

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
        let accent = game.level.tier == .plughole ? Color.neonCyan : .blood
        let next = run != nil ? game.nextTank : game.level.tier.levels.drop(while: { $0.id != game.level.id }).dropFirst().first
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
                if let next {
                    Button(game.spilled ? "new run \u{203A}" : "next \u{203A}") { onNext(next) }
                        .foregroundStyle(accent).shadow(color: accent, radius: 4)
                }
            }
            .font(.mono(15, .medium))
        }
    }
}
