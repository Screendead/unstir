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

private func glowRing(_ colour: Color, _ width: CGFloat, _ underlay: CGFloat, under: Color? = nil) -> some View {
    ZStack {
        Circle().stroke(under ?? colour.opacity(0.22), lineWidth: underlay)
        Circle().stroke(colour, lineWidth: width)
    }
}

@MainActor @Observable
final class Game {
    private(set) var level: Level
    private(set) var stack: [Twist]
    /// Stirs since the last reset, newest last: turns of one rod in a row are one stir, and undo commits a stir's negation.
    private(set) var history: [Twist] = []
    /// Whether the next turn of the newest stir's rod joins it. A stir turned back to nothing, or undone, is gone, and the
    /// one before it stays shut.
    private var open = false
    var moves: Int { history.count }
    /// Every commit and undo, for the commit flash: a joined turn leaves `moves` alone.
    private(set) var turns = 0
    /// A reset gives the moves back but costs the clean, and so does an undo.
    private(set) var resets = 0
    private(set) var undos = 0
    private(set) var bank = Best.undos
    /// A win the fine pass is still confirming: an undo or reset then would throw it away.
    private var checking = false
    /// Twists that stacked a new entry: the warning haptic.
    private(set) var pushes = 0
    private(set) var hints = 0
    private(set) var seconds = 0
    private(set) var hint: Twist?
    private(set) var cancels = 0
    private(set) var cancelledRod = 0
    /// The rod and outcome of the newest commit or undo, for the commit flash.
    private(set) var lastCommit: (rod: Int, result: Commit)?
    /// Starts when the opening ends or is skipped; a reset's replay does not restart it.
    private var start: Date?
    /// False once an earlier visit touched a rod or took a hint: a daily is then practice, and nothing else can be clean.
    let firstTry: Bool

    init(level: Level) {
        self.level = level
        stack = level.scramble
        firstTry = level.run != nil || !Best.started(level.id)
    }

    /// Practice saves nothing.
    var counts: Bool { firstTry || !level.id.hasPrefix("daily-") }

    /// The sandbox starts on the clean picture, so it is never solved, which keeps it from finishing or saving.
    var solved: Bool { stack.isEmpty && !level.sandbox }
    var par: Int { level.scramble.count }
    var over: Int { max(moves - par, 0) }
    /// Endless: the first move over par spills the run.
    var runOver: Bool { level.run != nil && over > 0 }
    var finished: Bool { solved || runOver }
    var clean: Bool { over == 0 && hints == 0 && resets == 0 && undos == 0 && firstTry }

    func commit(rod: Int, steps: Int) {
        guard !finished else { return }
        let result = stack.commit(rod: rod, steps: steps, in: level.layout)
        guard result != .refused else { Log.write("commit \(Twist(rod: rod, steps: steps)) refused"); return }
        if open, history.last?.rod == rod {
            history[history.count - 1].steps += steps
            if history.last!.steps == 0 { history.removeLast(); open = false }
        } else {
            history.append(Twist(rod: rod, steps: steps))
            open = true
        }
        lastCommit = (rod, result)
        turns += 1
        if result == .pushed { pushes += 1 }
        if result == .cancelled { cancels += 1; cancelledRod = rod }
        hint = nil
        Log.write("commit \(Twist(rod: rod, steps: steps)) \(result) moves=\(moves) pushes=\(pushes) stack=\(stack.count) \(stack)")
        settle()
    }

    func undo() {
        // The sandbox counts nothing, so its undos are free.
        guard !finished, !checking, level.sandbox || bank > 0, let last = history.popLast() else { return }
        stack.commit(rod: last.rod, steps: -last.steps, in: level.layout)
        // A white flash whatever the stack did: undo bumps neither pushes nor cancels, so no alarm or thunk may show.
        lastCommit = (last.rod, .reduced)
        open = false
        turns += 1
        if !level.sandbox {
            undos += 1
            bank -= 1
            Best.undos = bank
        }
        hint = nil
        Log.write("undo \(last) moves=\(moves) bank=\(bank) pushes=\(pushes) stack=\(stack.count) \(stack)")
        settle()
    }

    /// False when refused, so the caller skips the opening replay.
    @discardableResult func reset() -> Bool {
        guard !checking else { return false }
        stack = level.scramble
        history = []
        open = false
        hint = nil
        resets += 1
        Log.write("reset resets=\(resets) pushes=\(pushes) stack=\(stack.count) \(stack)")
        return true
    }

    func startClock() { start = start ?? .now }

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

    /// Rings the newest twist that can come off now.
    func showHint() {
        guard hint == nil, !finished, let i = level.layout.removable(stack).last else { return }
        hints += 1
        Best.start(level.id)
        hint = Twist(rod: stack[i].rod, steps: -stack[i].steps)
        Log.write("hint \(hint!) hints=\(hints)")
        settle()
    }

    private func settle() {
        // Refusing a win the picture already shows is the bug players hit, and a residual under half a pixel is invisible.
        // Only the coarse pass runs here: the fine one takes ~0.1 s exactly when it passes, which would hitch the win.
        if !stack.isEmpty && level.layout.same(stack, [], at: Tank.samples, within: Tank.halfPixel) {
            let stack = stack, layout = level.layout
            checking = true
            Task {
                let solved = await Task.detached(priority: .userInitiated) { layout.looksSolved(stack) }.value
                self.checking = false
                // A move made meanwhile settled itself.
                guard self.stack == stack else { return }
                if solved {
                    Log.write("looks solved \(stack)")
                    self.stack = []
                }
                self.finish()
            }
            return
        }
        finish()
    }

    private func finish() {
        guard finished else { return }
        hint = nil
        seconds = Int(Date.now.timeIntervalSince(start ?? .now))
        Log.write("\(solved ? "solved" : "spilled") \(level.id) moves=\(moves) par=\(par) hints=\(hints) seconds=\(seconds) counts=\(counts)")
        if let run = level.run {
            if solved { Best.tanks = max(Best.tanks, run.tank + 1) }
        } else if solved && counts {
            Best(over: over, hints: hints, seconds: seconds, clean: clean).save(level.id)
        }
    }
}

struct LevelView: View {
    @State private var game: Game
    @State private var liveRod: Int?
    @State private var liveAngle = 0.0
    /// Scales every committed angle; the open winds it 0 to 1, all rods at once, so it shows nothing about order.
    @State private var wind = 1.0
    @State private var drag: (rod: Int, last: Double, start: CGPoint)?
    @State private var tick = 0
    @State private var ticks = 0
    @State private var settling = false
    @State private var showResult: Bool
    /// Scramble entries on screen during the opening; nil once the tank is the player's.
    @State private var shown: Int?
    @State private var replays = 0
    @State private var snap = CGSize.zero
    @Environment(\.displayScale) private var scale
    @Environment(\.scenePhase) private var phase
    private let still: Bool
    private let autoplay: Bool
    private let bench: Bool
    /// UNSTIR_WAVE: the solve wave held at this radius.
    private let frozenWave: Double?
    /// UNSTIR_CLOCK: the Nightmare+ background held at this many seconds.
    private let frozenClock: Double?
    /// Nightmare+: its background's clock starts at zero on every visit.
    @State private var opened = Date.now
    let onExit: () -> Void
    let onNext: (Level) -> Void

    init(level: Level, harness: Harness?, onExit: @escaping () -> Void, onNext: @escaping (Level) -> Void) {
        let game = Game(level: level)
        if let h = harness, h.screen == "result" || h.screen == "clean" || h.wave != nil {
            // Solved through the real commit path; "result" first wastes two stirs, so taking them back costs moves.
            if h.screen == "result", let top = game.stack.last {
                let wrong = (top.rod + 1) % level.layout.rods.count
                game.commit(rod: wrong, steps: 2)
                game.commit(rod: (wrong + 1) % level.layout.rods.count, steps: 1)
            }
            while !game.finished, let i = level.layout.removable(game.stack).last {
                game.commit(rod: game.stack[i].rod, steps: -game.stack[i].steps)
            }
        }
        if harness?.hint == true { game.showHint() }
        _game = State(initialValue: game)
        _liveRod = State(initialValue: harness?.live?.rod)
        _liveAngle = State(initialValue: (harness?.live?.steps ?? 0) * Tank.step)
        _showResult = State(initialValue: game.finished && harness?.wave == nil)
        still = harness?.still ?? false
        autoplay = harness?.autoplay ?? false
        bench = harness?.bench ?? false
        frozenWave = harness?.wave
        frozenClock = harness?.clock
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
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("moves \(game.moves) / par \(game.par)")
                                // On black the wasted-twist alarm reads at full contrast, whatever the picture shows.
                                .keyframeAnimator(initialValue: 0.0, trigger: game.pushes) { text, t in
                                    text.foregroundStyle(t > 0.5 ? Color.alarm : Color.text)
                                } keyframes: { _ in
                                    // Red for 0.4 s. A trailing MoveKeyframe never lands, so the ramp ends the flash.
                                    MoveKeyframe(1.0)
                                    LinearKeyframe(0.0, duration: 0.8)
                                }
                            if let run = game.level.run { Text("tank \(run.tank + 1)") }
                        }
                        .opacity(showResult ? 0 : 1)
                    }
                }
                .font(.mono(13))
                .padding(.top, 8)
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(game.level.label).foregroundStyle(game.level.colour).shadow(color: game.level.colour, radius: 4)
                    Text(game.level.title)
                }
                .font(.mono(15, .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 18)
                Spacer(minLength: 12)
                let reveal = AnyTransition.opacity.animation(.easeOut(duration: 0.4).delay(0.3))
                tank(side)
                    .overlay(alignment: .top) {
                        if showResult {
                            Text(game.solved ? "unstirred." : "spilled.").font(.mono(22, .semibold))
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
                    control(game.level.sandbox ? "undo" : "undo \u{00B7} \(game.bank)", game.undo)
                        // The plain button style does not grey a disabled label.
                        .disabled(!game.level.sandbox && game.bank == 0)
                        .opacity(!game.level.sandbox && game.bank == 0 ? 0.35 : 1)
                    Spacer()
                    // Endless: a reset would refill the moves, and a hint would spill the run. Undo spends the bank.
                    if game.level.run == nil {
                        control("reset") { if game.reset() { replays += 1 } }
                        if !game.level.sandbox {
                            Spacer()
                            control("hint", game.showHint)
                        }
                    }
                }
                .disabled(settling || game.finished || shown != nil)
                .opacity(showResult ? 0 : 1)
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
        }
        .task {
            // Past the picture's first render, so the bake does not land in the numbers.
            guard bench, (try? await Task.sleep(for: .seconds(1))) != nil else { return }
            Bench(drive: { liveRod = 0; liveAngle = 3 * sin(2 * $0) },
                  still: game.level.picture == .nightmarePlus ? { liveRod = nil; liveAngle = 0 } : nil).start()
        }
        .onChange(of: shown == nil, initial: true) { if shown == nil { game.startClock() } }
        .onChange(of: game.finished) {
            guard game.finished else { return }
            // The fine pass can call the win ~0.1 s after the commit: a finger down in that gap would hold its turn frozen
            // over the win, then have the commit refused on lift.
            drag = nil; liveRod = nil; liveAngle = 0
            Task {
                try? await Task.sleep(for: .seconds(1.4))
                withAnimation(.easeIn(duration: 0.3)) { showResult = true }
                Log.write("result shown")
            }
        }
        // SwiftUI never calls onEnded for a cancelled drag (lock, Siri, a call), so drop the uncommitted turn here.
        .onChange(of: phase) { if drag != nil { Log.write("\(phase) drops drag \(state)"); drag = nil; liveRod = nil; liveAngle = 0 } }
        .onAppear { Log.write("level \(game.level.id) opens, par \(game.par) \(game.stack)") }
        .onDisappear { Log.write("level \(game.level.id) exits \(state)") }
    }

    /// Everything that decides what the tank draws, as the log shows it.
    private var state: String {
        "shown=\(Log.opt(shown)) wind=\(wind) live=\(Log.opt(liveRod)) angle=\(liveAngle) drag=\(Log.opt(drag?.rod)) "
            + "settling=\(settling) moves=\(game.moves) pushes=\(game.pushes) stack=\(game.stack.count) \(game.stack)"
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
        shown = 0; liveRod = nil; liveAngle = 0; drag = nil
        if !game.level.replay { wind = 0; shown = scramble.count }
        guard await pause(1) else { return }
        if game.level.replay {
            for (i, t) in scramble.enumerated() {
                let d = 0.12 * Double(abs(t.steps))
                liveRod = t.rod
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

    /// UNSTIR_AUTOPLAY: turns each right twist in view, then lets go through the same path as a finger.
    private func play() async {
        while !game.finished, let i = game.level.layout.removable(game.stack).last {
            let t = game.stack[i]
            guard (try? await Task.sleep(for: .seconds(0.3))) != nil else { return }
            liveRod = t.rod
            withAnimation(.easeInOut(duration: 0.4)) { liveAngle = -Double(t.steps) * Tank.step }
            guard (try? await Task.sleep(for: .seconds(0.4))) != nil else { return }
            release(t.rod)
        }
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
        game.history.reduce(0) { $1.rod == k ? $0 + Double($1.steps) * Tank.step : $0 }
    }

    private func tank(_ side: CGFloat) -> some View {
        let r = side / 2
        func at(_ k: Int) -> CGPoint { CGPoint(x: r + rods[k].x * r, y: r + rods[k].y * r) }
        let core = 2 * Tank.coreRadius * r
        let probing = shown == nil ? liveRod : nil
        // Solid once letting go would commit a twist; dashed while it would cost nothing or a full stack would refuse it.
        // Array.commit's overlap rule, checked without copying the stack or sampling the map every drag frame.
        let commits = liveRod.map { k in
            Int((liveAngle / Tank.step).rounded()) != 0 && (game.stack.count < Tank.maxStack
                || game.stack.last { game.level.layout.overlaps($0.rod, k) }?.rod == k)
        } ?? false
        let animated = game.level.picture == .nightmarePlus
        let unstirred = Unstirred(stack: stack, layout: game.level.layout, liveRod: liveRod, liveAngle: liveAngle, wind: wind, side: side,
                                  haze: showResult ? min(0.12 * Double(game.over), 0.6) : 0, animated: animated)
        let source = rods[game.history.last?.rod ?? 0]
        let frozenWave = frozenWave
        let flash = game.lastCommit
        return ZStack {
            // Nightmare+ is the one tank that redraws while the player is still; 60 Hz is plenty for motion this slow.
            // Every other picture pauses the timeline, so nothing ticks.
            TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !animated || frozenClock != nil)) { timeline in
                PictureLayer(picture: game.level.picture, side: side, seed: Int(game.level.label) ?? 0,
                             clock: frozenClock ?? timeline.date.timeIntervalSince(opened))
                    .keyframeAnimator(initialValue: -1.0, trigger: game.solved) { picture, w in
                        var u = unstirred
                        u.wave = SIMD3(Float(source.x), Float(source.y), Float(frozenWave ?? w))
                        return picture.modifier(u)
                    } keyframes: { _ in
                        // A light wave from the last-turned rod, over the clean picture. The animator holds its last value, so
                        // the band runs out past the farthest rim of any layout (1.56 from a ring rod) rather than parking on it.
                        MoveKeyframe(0.0)
                        LinearKeyframe(1.9, duration: 0.9, timingCurve: .easeOut)
                    }
            }
            .clipShape(Circle())
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
            // Always present, like the flash ring below: a ring inserted with the hint never sees `hints` change.
            let hk = game.hint?.rod ?? 0
            glowRing(.amber, 2, 8)
                .frame(width: 2 * rods[hk].z * r, height: 2 * rods[hk].z * r)
                .keyframeAnimator(initialValue: 1.0, trigger: game.hints) { ring, s in ring.scaleEffect(s) } keyframes: { _ in
                    CubicKeyframe(1.07, duration: 0.25)
                    CubicKeyframe(1.0, duration: 0.35)
                }
                .opacity(game.hint != nil && liveRod == nil && shown == nil ? 1 : 0)
                .position(at(hk))
            if let k = probing {
                // Where the notch started: turn it back to here and letting go costs nothing.
                Capsule().fill(Color.live.opacity(0.7)).frame(width: 2.5, height: 16)
                    .offset(y: -rods[k].z * r)
                    .rotationEffect(.radians(turned(k)))
                    .position(at(k))
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
            if let h = game.hint {
                let arrow = hintArrow(center: at(h.rod), radius: core / 2 + 14, from: turned(h.rod), angle: Double(h.steps) * Tank.step)
                arrow.stroke(Color.amber.opacity(0.22), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                arrow.stroke(Color.amber, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
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
                RodView(angle: turned(k) + (probing == k ? liveAngle : 0), size: core)
                    .position(x: (p.x * scale).rounded() / scale, y: (p.y * scale).rounded() / scale)
            }
            .opacity(showResult ? 0 : 1)
        }
        .frame(width: side, height: side)
        .keyframeAnimator(initialValue: 0.0, trigger: game.solved) { tank, t in
            tank.scaleEffect(1 + 0.02 * sin(t * .pi))
        } keyframes: { _ in CubicKeyframe(1.0, duration: 0.9) }
        .contentShape(Circle())
        .gesture(twistGesture(r))
        .sensoryFeedback(.selection, trigger: ticks)
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

    /// An arc from the notch as long as the turn, arrowhead where the notch should stop; positive runs clockwise.
    private func hintArrow(center c: CGPoint, radius ar: CGFloat, from notch: Double, angle: Double) -> Path {
        let a0 = notch - Double.pi / 2, a = a0 + angle, dir = angle > 0 ? 1.0 : -1.0
        var p = Path()
        p.addArc(center: c, radius: ar, startAngle: .radians(a0), endAngle: .radians(a), clockwise: angle < 0)
        let tip = CGPoint(x: c.x + ar * cos(a), y: c.y + ar * sin(a))
        let back = CGVector(dx: sin(a) * dir * 8, dy: -cos(a) * dir * 8)
        let wing = CGVector(dx: cos(a) * 5, dy: sin(a) * 5)
        p.move(to: CGPoint(x: tip.x + back.dx + wing.dx, y: tip.y + back.dy + wing.dy))
        p.addLine(to: tip)
        p.addLine(to: CGPoint(x: tip.x + back.dx - wing.dx, y: tip.y + back.dy - wing.dy))
        return p
    }

    private func twistGesture(_ r: CGFloat) -> some Gesture {
        func norm(_ p: CGPoint) -> SIMD2<Double> { SIMD2(Double(p.x / r - 1), Double(p.y / r - 1)) }
        return DragGesture(minimumDistance: 0)
            .onChanged { v in
                guard !settling, !game.finished, shown == nil else { return }
                // Keyed on the start point because a cancelled drag never reaches onEnded; a new touch starts afresh.
                if drag?.start != v.startLocation {
                    drag = nil; liveRod = nil; liveAngle = 0
                    let q0 = norm(v.startLocation)
                    guard let k = rods.indices.filter({ simd_distance(q0, centre($0)) < rods[$0].z })
                        .min(by: { simd_distance(q0, centre($0)) < simd_distance(q0, centre($1)) }) else { return }
                    // From the current point, so a drag picked up again after a reset's stir does not jump.
                    let d0 = norm(v.location) - centre(k)
                    drag = (k, atan2(d0.y, d0.x), v.startLocation)
                    liveRod = k
                    Log.write("drag \(k)")
                    if !game.level.sandbox { Best.start(game.level.id) }
                    tick = 0
                }
                guard let (k, last, start) = drag else { return }
                let d = norm(v.location) - centre(k)
                let a = atan2(d.y, d.x)
                // Near the pivot the angle is noise; track it without turning the rod.
                if simd_length(d) > 0.1 { liveAngle += atan2(sin(a - last), cos(a - last)) }
                drag = (k, a, start)
                let t = Int((liveAngle / Tank.step).rounded(.towardZero))
                if t != tick { tick = t; ticks += 1 }
            }
            .onEnded { _ in
                if shown != nil {
                    // Past 1, so the value changes and cuts short a wind-in still animating towards 1.
                    shown = nil; liveRod = nil; liveAngle = 0; wind = 2
                    Log.write("skip \(state)")
                    return
                }
                guard let k = drag?.rod else { return }
                drag = nil
                release(k)
            }
    }

    private func release(_ k: Int) {
        let steps = Int((liveAngle / Tank.step).rounded())
        Log.write("release \(k) angle=\(liveAngle) steps=\(steps)")
        settling = true
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

/// Applies the stack (plus the live twist on top) as inverse maps and samples the picture.
struct Unstirred: ViewModifier, Animatable {
    var stack: [Twist]
    var layout: Layout
    var liveRod: Int?
    var liveAngle: Double
    var wind = 1.0
    var side: CGFloat
    /// Drains the colour towards grey.
    var haze = 0.0
    /// (x, y, radius) in tank units; a negative radius is off.
    var wave = SIMD3<Float>(0, 0, -1)
    /// Nightmare+: the picture under the shader is redrawn every frame too.
    var animated = false
    @Environment(\.displayScale) private var scale

    nonisolated var animatableData: AnimatablePair<AnimatablePair<Double, Double>, Double> {
        get { AnimatablePair(AnimatablePair(liveAngle, wind), haze) }
        set { (liveAngle, wind, haze) = (newValue.first.first, newValue.first.second, newValue.second) }
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
        // Nightmare+'s fill costs about four entries of four-tap work (Mac GPU microbench), so it keeps four taps only to
        // 26 entries: the same budget as 30 without it. Counted in committed entries, so a touch never changes the taps;
        // the drag rides one over, within the 31 the shader's comment measured.
        let fourTaps: Float = (animated ? 26 : 30) + (liveRod == nil ? 0 : 1)
        return content.layerEffect(
            ShaderLibrary.unstir(.float2(r, r), .float(r), .floatArray(floats), .float(Float(n)), .float(fourTaps), .float(Float(Tank.plateau)),
                                 .float(Float(scale)), .float(Float(haze)), .float3(wave.x, wave.y, wave.z)),
            maxSampleOffset: CGSize(width: side, height: side))
    }
}

struct PictureLayer: View {
    let picture: Picture
    let side: CGFloat
    /// Nightmare+: the level's seed and the background's clock in seconds.
    var seed = 0
    var clock = 0.0
    @Environment(\.displayScale) private var scale
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if picture == .nightmarePlus {
                // The shader's time terms repeat every 5 s and 2 s, so it gets the clock mod 10 and float32 keeps its precision.
                Rectangle().fill(ShaderLibrary.nightmarePlus(.float(side / 2), .float(2 / (side * scale)),
                                                             .floatArray(Picture.cells(seed: seed, t: clock)),
                                                             .float(Float(clock.truncatingRemainder(dividingBy: 10)))))
            } else if let image {
                Image(uiImage: image)
            } else {
                Color.black
            }
        }
        .frame(width: side, height: side)
        // Flickers on like a neon tube when the texture lands. Over black, opacity is a colour multiply the shader samples for free.
        // Transparent until then, which over black matches the placeholder and keeps Nightmare+ from showing before the strike.
        .keyframeAnimator(initialValue: 0.0, trigger: image != nil) { picture, o in picture.opacity(o) } keyframes: { _ in
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
        // Nightmare+ bakes nothing: the empty image only strikes the tube.
        .task(id: [picture.rawValue, "\(side)", "\(scale)"]) {
            image = picture == .nightmarePlus ? UIImage() : picture.render(side: side, scale: scale)
        }
    }
}

struct RodView: View {
    let angle: Double
    let size: CGFloat
    @Environment(\.displayScale) private var scale
    private static let knob = [(0, 0xF4F6FA), (0.25, 0x7A8292), (0.6, 0x2E333D), (1, 0x15181E)]
        .map { Gradient.Stop(color: Color($0.1), location: $0.0) }

    var body: some View {
        // Whole device pixels out from a pixel-snapped centre, so at rest the upright and level ticks land crisp.
        let rim = px(size / 2), width = px(2 / 3)
        ZStack {
            Circle().fill(RadialGradient(stops: Self.knob, center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.95))
            Circle().strokeBorder(Color.black.opacity(0.8), lineWidth: 1.2)
            ticks(rim - px(2), rim - px(1 / 3)).stroke(Color.neonCyan.opacity(0.8), lineWidth: width)
            // Off-centre so a half turn reads as pointing down, not as untouched.
            Capsule().fill(Color.neonCyan.opacity(0.25)).frame(width: 6, height: size * 0.3 + 4).offset(y: -size * 0.3)
            Capsule().fill(Color.neonCyan).frame(width: 2, height: size * 0.3).offset(y: -size * 0.3)
        }
        .frame(width: size, height: size)
        .rotationEffect(.radians(angle))
        .background {
            Circle().strokeBorder(Color.black.opacity(0.7), lineWidth: 3).padding(-3)
            ticks(rim + px(2 / 3), rim + px(8 / 3)).stroke(Color.neonCyan.opacity(0.5), lineWidth: width)
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
        let accent = game.level.nightmare ? Color.blood : .neonCyan
        let next: Level? = if let run {
            .endless(game.runOver ? Run(seed: .random(in: .min ... .max)) : Run(seed: run.seed, tank: run.tank + 1))
        } else {
            (game.level.plus ? Level.nightmarePlus : game.level.nightmare ? Level.nightmare : Level.all)
                .drop(while: { $0.id != game.level.id }).dropFirst().first
        }
        VStack(spacing: 26) {
            VStack(spacing: 8) {
                Text("moves \(game.moves) \u{00B7} par \(game.par) \u{00B7} hints \(game.hints) \u{00B7} "
                     + String(format: "%d:%02d", game.seconds / 60, game.seconds % 60))
                if game.clean {
                    Text("clean").fontWeight(.semibold).foregroundStyle(Color.lime).shadow(color: .lime, radius: 3)
                } else if game.over > 0 || game.hints > 0 {
                    Text(game.over > 0 ? "+\(game.over) over par" : "\(game.hints) hint\(game.hints == 1 ? "" : "s")")
                        .foregroundStyle(Color.magenta)
                } else {
                    Text(game.firstTry ? "at par \u{00B7} clean needs no reset or undo" : "clean counts on the first try")
                        .foregroundStyle(Color.amber)
                }
                if let run {
                    Text(game.runOver ? "tanks cleared \(run.tank + (game.solved ? 1 : 0)) \u{00B7} best \(Best.tanks)"
                         : "tank \(run.tank + 1)")
                }
            }
            .font(.mono(13))
            HStack(spacing: 40) {
                Button("\u{2039} levels", action: onExit)
                if let next {
                    Button(game.runOver ? "new run \u{203A}" : "next \u{203A}") { onNext(next) }
                        .foregroundStyle(accent).shadow(color: accent, radius: 4)
                }
            }
            .font(.mono(15, .medium))
        }
    }
}
