// Copyright © 2026 Jack Lusher. All rights reserved.

import CoreHaptics
import SwiftUI
import simd

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

/// UNSTIR_CLEAN: a part of the play screen kept where it lies but not drawn, so the tank stays where films crop it.
private struct Unseen: ViewModifier {
    let hidden: Bool
    init(_ hidden: Bool) { self.hidden = hidden }

    func body(content: Content) -> some View {
        content.opacity(hidden ? 0 : 1).allowsHitTesting(!hidden).accessibilityHidden(hidden)
    }
}

/// The edge swipe back (Jack's call C19, round 13). A touch landing within `band` of the screen's left edge is
/// undecided for its first `travel`; then rightward and mostly sideways it is the swipe, and anything else passes to
/// what it landed on, as iOS's own edge pan fails on motion that isn't away from the edge (Jack's call S2, round 13).
enum BackSwipe: Equatable {
    case undecided, swipe, pass

    static let band: CGFloat = 20
    static let travel: CGFloat = 10

    /// `start` in global points, `t` the travel since.
    static func decide(start: CGPoint, translation t: CGSize) -> BackSwipe {
        guard start.x < band else { return .pass }
        guard hypot(t.width, t.height) >= travel else { return .undecided }
        return t.width > 0 && t.width >= 2 * abs(t.height) ? .swipe : .pass
    }

    /// Let go `dx` across a screen `width` wide, heading for `predicted`, the swipe leaves; as iOS's own, a flick back
    /// left cancels it however far it had gone.
    static func commits(dx: CGFloat, predicted: CGFloat, width: CGFloat) -> Bool {
        predicted > width / 2 || dx > width / 3 && predicted >= dx - 8
    }

    /// An edge touch as the tank saw it land: `start` in the tank's points, `global` the same point on the screen.
    struct Edge: Equatable {
        let start: CGPoint
        let global: CGPoint
        let call: BackSwipe
    }

    /// The tank's view of a touch from `start`, in its own points, with its origin on the screen at `origin` now:
    /// recorded as it lands, before anything slides, and from then on read by its start alone, since the slide moves
    /// the tank's origin and with it where `start` would seem to lie. Nil: not an edge touch.
    static func edge(_ held: Edge?, start: CGPoint, origin: CGPoint, translation t: CGSize) -> Edge? {
        if let held, held.start == start {
            guard held.call == .undecided else { return held }
            return Edge(start: start, global: held.global, call: decide(start: held.global, translation: t))
        }
        let global = CGPoint(x: origin.x + start.x, y: origin.y + start.y)
        return global.x < band ? Edge(start: start, global: global, call: decide(start: global, translation: t)) : nil
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
    /// The column's room between the title line's foot and the glass's top, as laid out.
    @State private var titleGap: CGFloat?
    /// Prism: the channel whose swatch is held, drawn alone.
    @State private var isolated: Channels?
    private let letters: Bool
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @State private var liveAngle = 0.0
    /// The tank's turn in hand, in radians clockwise, while a finger holds the rim; nil when it is not held.
    @State private var liveTurn: Double?
    /// Two fingers' twist, on top of `liveTurn`.
    @GestureState private var spin: Double?
    /// The two-finger twist has the tank; its onEnded lets go, or the phase handler when the system cuts it off (C13),
    /// or a new touch that finds it cancelled. `spin` may reset before any of them folds the twist into `liveTurn`, and
    /// the finger's drag may end on either side of it.
    @State private var spun = false
    /// The twist's rotation as last reported, since it was taken up: drawn and let go in place of `spin`, which the
    /// system resets on its own clock.
    @State private var lastSpin = 0.0
    /// Where the twist began and the rotation it had when last let go: a twist whose fingers outlast a let-go the system
    /// forced turns on from there, never committing a rotation twice.
    @State private var spinBase = (start: CGPoint.zero, rotation: 0.0)
    /// Solved, the glass eases to the nearest home: the level ends wherever the tank stands.
    @State private var eased: Bool
    /// The solve's wave, swell and success haptic have landed: at the win, or on Escapement at its solving tick.
    @State private var waved: Bool
    /// Scales every committed angle; the open winds it 0 to 1, all rods at once, so it shows nothing about order.
    @State private var wind = 1.0
    /// The touch it belongs to, what it holds, and the finger's last angle about that.
    @State private var drag: (start: CGPoint, grab: Grab, last: Double)?
    /// A finger is down on the tank. It resets when the system cancels the touch too, which `drag` alone never sees.
    @GestureState private var holding = false
    /// Where the finger has been since it landed, timed from when the drag was taken up, and what it held there, for
    /// the log's one line when the drag ends.
    @State private var path: (grab: Grab, down: Date, trail: Trail<SIMD2<Double>>)?
    /// A two-finger twist's rotation since it began, logged when it ends.
    @State private var twist: (down: Date, trail: Trail<Double>)?
    /// The finger's latest point in tank units, kept after it lifts so a count left showing stays put.
    @State private var finger: SIMD2<Double>?
    /// Where the finger holding the stir landed: a lens's track keeps to the side away from it, so a thumb wobbling
    /// across the knob on its way up never flips it.
    @State private var landed: SIMD2<Double>?
    /// UNSTIR_FINGER: the fingertip drawn down where it landed, and what it turns about (the tank's centre for the rim
    /// and the swirl).
    @State private var ghost: (at: SIMD2<Double>, pivot: SIMD2<Double>, rim: Bool, lens: Bool)?
    /// The knob, or `Game.tank`, touched last: its open stir's count stays up, faint, after letting go.
    @State private var counted: Int?
    /// L1, left untouched after its opening: a ghost finger shows the knob's turn until the first stir commits.
    @State private var knobLesson = false
    /// When Lens 01's lesson last appeared, so each showing rides from the top; nil while it is hidden.
    @State private var lensLesson: Date?
    @State private var grabs = 0
    /// The seized knob touched last, and every such touch: it shakes, the rim pulses and a thud plays.
    @State private var jammed: Int?
    @State private var jams = 0
    /// Escapement: the ratchet a finger is on.
    @State private var pressing: Int?
    /// Escapement: the clock tapped last off its plate, and how far off, in tank units; every such tap.
    @State private var missed: (k: Int, by: Double)?
    @State private var misses = 0
    /// Escapement: every wait made, by a clock's plate or the wait control, so both light whichever was used: the
    /// control and the waited clock's plate (`waitedOn`) while `waitLit`. `waitHeld` presses the control ahead of the
    /// demonstration's or the harness's wait, as a finger would.
    @State private var waits = 0
    @State private var waitLit = false
    @State private var waitedOn: Int?
    @State private var waitHeld = false
    /// Escapement: the demonstration of the clock is playing, before the problem winds in.
    @State private var demoing = false
    /// Escapement: the tank dips to black between the demonstration and the problem, so the problem's clean opening
    /// frame never reads as the demonstration solved.
    @State private var demoDip = 0.0
    /// Escapement: the move whose ticks sound, by `game.tickEvents`; none as the view appears, so a resumed try's last
    /// ticks, long landed, stay silent.
    @State private var sounding: Int?
    /// Escapement: the newest tick landed, numbered so two alike in a row each change it, for its haptic.
    @State private var felt: Felt?
    private struct Felt: Equatable { var n: Int, haptic: SensoryFeedback }
    @State private var detent = Detent(step: Tank.step)
    @State private var ticks = 0
    @State private var tankTicks = 0
    @State private var settling = false
    @State private var showResult: Bool
    /// First Stir's last scene solved: the night forwards plays before the card.
    @State private var ending: Bool
    /// UNSTIR_ENDING=s: the night forwards held this many seconds in.
    private let frozenEnding: Double?
    /// Scramble entries on screen during the opening; nil once the tank is the player's.
    @State private var shown: Int?
    @State private var replays = 0
    /// Escapement: the demonstration has had its turn on opening, once the problem has been solved; outside the harness.
    private let demoRetired: Bool
    /// The last reset was of a tank with nothing played: the opening, a demonstration and all, plays again.
    @State private var fresh = false
    /// The day's refill as the badge shows it: set once the opening is over, and only once, so a reset's opening doesn't
    /// show it again.
    @State private var badge = 0
    /// Bumped by every touch: the screen stays awake for two minutes after the last.
    @State private var awake = 0
    @State private var awakeID = UUID()
    /// A touch that holds nothing until it lifts: one that skipped the clock's demonstration, as the problem has still
    /// to wind in, or one the window's change of pose let go, whose start lies in the tank's old frame.
    @State private var deadTouch: CGPoint?
    /// A two-finger twist the window's change of pose let go.
    @State private var deadSpin: CGPoint?
    /// Where the finger now on the tank landed, whether or not anything has taken it up yet.
    @State private var touchStart: CGPoint?
    /// How far the result or lost card reaches below the caption's top, which `PlayStack` makes room for.
    @State private var cardReach: CGFloat = 0
    /// The caption's top in the play screen's own space (`column`), where the card hangs from, with the tank at the
    /// size it was played at.
    @State private var captionTop: CGFloat?
    /// The play screen's safe area, in its own points whatever scales the window (the harness's poses).
    private static let column = "play"
    /// The play layout last laid out, so a change of pose glides from it and lets go of what the fingers hold.
    @State private var pose: PlayLayout?
    /// UNSTIR_FOLD: the fold the harness window draws, in its own points.
    @Environment(\.harnessFold) private var harnessFold
    @Environment(\.chromeMeasured) private var chromeMeasured
    @Environment(\.finishedMeasured) private var finishedMeasured
    /// The type size round the level, which its own text sees capped at `PlayLayout.typeCap`.
    @Environment(\.dynamicTypeSize) private var typeSize
    /// The level's note at full strength for its first seconds of play.
    @State private var noteLit = false
    /// Plughole 01's first open points at the settings under its note, once (Jack's call F3, round 14). State, as
    /// SwiftUI reruns the init after the flag is stored, and the line stays the visit out.
    @State private var pointing: Bool
    @State private var pointed = false
    /// Only a plain launch stores that it has; under the harness UNSTIR_FRESH shows it.
    private let storesPointing: Bool
    /// A line the caption shows for a few seconds in place of its own, saying why a control or a turn did nothing.
    @State private var notice: String?
    @State private var notices = 0
    /// An undo tapped while a let-go settles, taken once it has.
    @State private var undoQueued = false
    @State private var snap = CGSize.zero
    @Environment(\.displayScale) private var scale
    @Environment(\.scenePhase) private var phase
    private let still: Bool
    private let autoplay: Bool
    /// UNSTIR_PACE: the seconds autoplay and UNSTIR_MOVES wait before each move.
    private let pace: Double
    /// UNSTIR_BARE: the picture drawn unstirred, as the stack has played it.
    private let bare: Bool
    /// UNSTIR_CLEAN: the glass and its picture alone.
    private let clean: Bool
    private let moves: [Harness.Step]?
    private let fingered: Bool
    private let bench: Bool
    /// UNSTIR_TAPDRAG: that many drags drawn through the real let-go.
    private let tapDrags: Int?
    /// UNSTIR_WAVE: the solve wave held at this radius.
    private let frozenWave: Double?
    /// UNSTIR_CLOCK: a live background, and the rim and knob lessons' ghost fingers, held at this many seconds.
    private let frozenClock: Double?
    /// UNSTIR_SHAKE: a seized knob's shake and the rim's pulse held this many seconds in.
    private let frozenShake: Double?
    /// UNSTIR_TODAY: the day the level opens on, for the bank's refill.
    private let today: String?
    /// UNSTIR_BREATH: the swirl's breath held this many seconds into the tank's first rest.
    private let frozenBreath: Double?
    /// UNSTIR_REST: seconds at rest before a drawn fingertip lands.
    private let rest: Double
    /// The game replayed a saved line: the first opening, and Escapement's demonstration, don't play.
    private let resumed: Bool
    /// When a first tap armed the reset control, which then says "reset? tap again" for `ResetArm.window`, or under
    /// VoiceOver until a move or focus leaves it.
    @State private var armedAt: Date?
    @AccessibilityFocusState private var resetFocused: Bool
    /// UNSTIR_RESETARMED: the control armed for good, for stills.
    private let holdArmed: Bool
    /// The swirl's breath while the tank rests, and the last one a touch, the opening or the win cut, fading out.
    @State private var breath: Breath?
    @State private var faded: Breath?
    /// Either moves the picture now: the picture's timeline runs only then.
    @State private var breathing = false
    /// Something has been let go since the opening, so the next rest waits longer.
    @State private var lifted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityDimFlashingLights) private var dimFlashing
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    /// Under Reduce Motion the opening fades through black, by this much, in place of the wind-in.
    @State private var curtain = 0.0
    /// A live picture: its clock starts at zero on every visit.
    @State private var opened = Date.now
    /// Endless: the picture's colours round the rim as the stack stirs it (Brim.colours), once worked out.
    @State private var rimColours: (hue: [Float], lines: [Float])?
    /// Endless: the brim changed lately enough that the rim is still moving.
    @State private var brimMoving = false
    /// The picture has landed and struck.
    @State private var struck = false
    /// Lens: the panel's detail for the glass's size (`Halftone.Detail`), once baked, and whether the strike has ended.
    /// The detail is drawn past the layer, so it would not flicker with it: `crisp`, its share, rises only after.
    @State private var fine: Fine?
    @State private var lit = false
    @State private var crisp = 0.0
    private let brimDemo: Bool
    /// Escapement: what a tank lost to its last clock stopping shows, while Jack decides (UNSTIR_STOPLOOK).
    private let stopLook: StopLook
    private let shareSheet: Bool
    /// UNSTIR_NOW: the clock the daily's card reads the next daily from.
    private let now: Date?
    /// Back to the menu, with whether the level is solved.
    let onExit: (Bool) -> Void
    let onNext: (Level) -> Void
    /// Back to the menu on a tier other than the stored one: a closed tier's gate.
    let onLook: (Tier) -> Void
    /// A pack's card, from a completion's pointer.
    let onOffer: (Pack) -> Void
    /// The menu drawn under a back swipe, focused as leaving with whether the level is solved would; nil once the swipe
    /// has sprung back.
    let onPeek: (Bool?) -> Void
    /// The window would put the menu beside a split play screen (Jack's call DUOMENU = B, round 16).
    let besideMenu: Bool
    /// A level picked in the menu beside play: this one leaves for it through `onSwitch`, its try saved as leaving saves it.
    let switching: Level?
    let onSwitch: (Level) -> Void
    /// Where the menu goes beside play, the trailing half, in `RootView.space`.
    let onMenu: (CGRect) -> Void
    /// The level finished, its best saved: the menu beside it reads its rows afresh.
    let onFinish: () -> Void
    /// Beside the menu, whether a result or lost card covers it, as the half round the tank has no room for one.
    let onCover: (Bool) -> Void
    /// The back swipe's touch, by its global start, and what it decided.
    @State private var swipeTouch: (start: CGPoint, call: BackSwipe)?
    /// The same decision as the tank's gesture saw it: once made it holds, though a swipe's later course may no longer
    /// read as one.
    @State private var edgeTouch: BackSwipe.Edge?
    /// The system can cancel the swipe's touch, which its onEnded never sees.
    @GestureState private var swipeHeld = false
    /// How far across the screen the back swipe has slid the level, 0 to 1.
    @State private var swiped = 0.0
    /// The swipe let go past its threshold: the level is leaving.
    @State private var swipedAway = false
    @State private var width: CGFloat = 0
    /// The tank's origin in global points, where the edge band is.
    @State private var tankOrigin = CGPoint.zero
    /// UNSTIR_BACKSWIPE=0.4: the level held that far into a back swipe.
    private let heldSwipe: Double?
    /// UNSTIR_BACKSWIPE=run, or UNSTIR_EXIT=swipe: a second in, the swipe drawn by a fingertip, or only its commit.
    private let playsSwipe: Bool
    private let exitsBySwipe: Bool
    @State private var swipeFinger = false

    /// `resumed`: the try a save brought back (`Game.resumed`), built before the view, as SwiftUI reruns this init for a
    /// level it already shows. `storesResume`: the game built here saves its try, as on any launch but the harness's.
    init(level: Level, harness: Harness?, resumed: Game? = nil, storesResume: Bool = false,
         onExit: @escaping (Bool) -> Void, onNext: @escaping (Level) -> Void, onLook: @escaping (Tier) -> Void,
         onOffer: @escaping (Pack) -> Void, onPeek: @escaping (Bool?) -> Void = { _ in }, besideMenu: Bool = false,
         switching: Level? = nil, onSwitch: @escaping (Level) -> Void = { _ in }, onMenu: @escaping (CGRect) -> Void = { _ in },
         onFinish: @escaping () -> Void = {}, onCover: @escaping (Bool) -> Void = { _ in }) {
        self.besideMenu = besideMenu
        self.switching = switching
        self.onSwitch = onSwitch
        self.onMenu = onMenu
        self.onFinish = onFinish
        self.onCover = onCover
        let game = resumed ?? Game(level: level, tankTurned: harness?.tankTurned, swirled: harness?.swirled, bank: harness?.bank,
                                   storesProgress: harness?.harnessed != true, storesResume: storesResume)
        // A save with no line yet, a run's next tank, opens as any tank does.
        self.resumed = !(resumed?.actions.isEmpty ?? true)
        if resumed == nil { game.turnTank(harness?.tank ?? 0) }
        if resumed == nil, let h = harness, h.screen == "result" || h.screen == "clean" || h.wave != nil && h.played.isEmpty {
            // Solved through the real commit path, unless the harness plays a line, which Escapement's clocks need;
            // "result" first wastes two stirs, so taking them back costs moves.
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
        if resumed == nil, let t = harness?.turned { game.commit(rod: t.rod, steps: t.steps) }
        for m in resumed == nil ? harness?.played ?? [] : [] {
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
            // A lens's finger goes up and down instead.
            let lens = live.map { level.lenses.contains($0.rod) } ?? false
            _landed = State(initialValue: p)
            _finger = State(initialValue: lens ? p - SIMD2(0, angle / Tank.step * LevelView.lensPitch)
                                : pivot + SIMD2(d.x * cos(a) - d.y * sin(a), d.x * sin(a) + d.y * cos(a)))
            switch grab {
            case .rod(let k): _liveRod = State(initialValue: k); _counted = State(initialValue: k)
            case .rim: _liveTurn = State(initialValue: turn ?? 0); _counted = State(initialValue: Game.tank)
            case .seized(let k), .ratchet(let k): _jammed = State(initialValue: k)
            case .nothing: break
            }
        }
        // A spill's card waits for the pour, so a harness launch that spills shows it only if held past then.
        let ending = harness?.ending != nil && game.solved && level.endsFirstStir
        _ending = State(initialValue: ending)
        frozenEnding = harness?.ending.flatMap { $0 < 0 ? nil : $0 }
        _showResult = State(initialValue: game.finished && harness?.wave == nil && !ending
                            && (!game.spilled || (harness?.clock ?? 0) >= Brim.card(still: harness?.clock == nil && UIAccessibility.isReduceMotionEnabled)))
        _eased = State(initialValue: game.solved)
        _waved = State(initialValue: game.solved)
        still = harness?.still ?? false
        autoplay = harness?.autoplay ?? false
        pace = harness?.pace ?? 0.3
        bare = harness?.bare ?? false
        clean = harness?.clean ?? false
        moves = harness?.moves
        fingered = harness?.finger ?? false
        brimDemo = harness?.brimDemo ?? false
        stopLook = harness?.stopLook ?? .stamp
        shareSheet = harness?.shareSheet ?? false
        now = harness?.now
        bench = harness?.bench ?? false
        tapDrags = harness?.tapDrags
        _isolated = State(initialValue: harness?.swatch)
        letters = harness?.letters ?? false
        frozenWave = harness?.wave
        frozenClock = harness?.clock
        frozenShake = harness?.shake
        today = harness?.today
        frozenBreath = harness?.breath
        rest = harness?.rest ?? 2
        holdArmed = harness?.resetArmed ?? false
        _armedAt = State(initialValue: holdArmed ? .now : nil)
        demoRetired = harness == nil && Best.load(level.id) != nil
        let harnessed = harness?.harnessed == true
        _pointing = State(initialValue: Self.points(at: level, harnessed: harnessed, fresh: harness?.fresh == true,
                                                    pointed: Best.pointedAtSettings))
        storesPointing = !harnessed
        // A resumed try opens where it was left, with no opening.
        _shown = State(initialValue: still || level.sandbox || self.resumed ? nil : 0)
        self.onExit = onExit
        self.onNext = onNext
        self.onLook = onLook
        self.onOffer = onOffer
        self.onPeek = onPeek
        heldSwipe = harness?.backSwipe
        playsSwipe = harness?.backSwipeRun ?? false
        exitsBySwipe = harness?.exit == "swipe"
    }

    var body: some View {
        screen
            .dynamicTypeSize(...PlayLayout.typeCap)
            .statusBarHidden(clean)
            // The Info.plist's dark style draws the status bar white, which paper would swallow.
            .preferredColorScheme(page.paper ? .light : nil)
            .persistentSystemOverlays(clean ? .hidden : .automatic)
            // The level's edge, over the menu it slides off across: a hairline, as every line over the glass is.
            .overlay(alignment: .leading) {
                if swiped > 0 {
                    Rectangle().fill(Color.text.opacity(0.2)).frame(width: 0.5).ignoresSafeArea().allowsHitTesting(false)
                }
            }
            .offset(x: swiped * width)
            .background { if swiped > 0 { Color.black.opacity(0.4 * (1 - swiped)).ignoresSafeArea() } }
            .overlay(alignment: .leading) {
                if swipeFinger {
                    page.finger(diameter: 40).offset(x: swiped * width - 12).allowsHitTesting(false)
                }
            }
            .simultaneousGesture(backSwipe)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .onChange(of: swipeHeld) {
                // After onEnded, which may follow this, has had its say.
                guard !swipeHeld else { return }
                Task { if swipeTouch?.call == .swipe, !swipedAway { swipeTouch = nil; springBack() } }
            }
            .task {
                if let heldSwipe {
                    // After the first layout, which says whether the menu is beside the level, where nothing slides.
                    if besideMenu { try? await Task.sleep(for: .milliseconds(200)) }
                    if !beside { peek(); swiped = heldSwipe }
                }
                guard playsSwipe || exitsBySwipe, (try? await Task.sleep(for: .seconds(1))) != nil else { return }
                if !beside { peek() }
                if playsSwipe, !reduceMotion, !beside {
                    swipeFinger = true
                    withAnimation(.easeInOut(duration: 0.5)) { swiped = 0.45 }
                    guard (try? await Task.sleep(for: .seconds(0.5))) != nil else { return }
                    swipeFinger = false
                }
                swipeAway()
            }
    }

    /// The edge swipe back: the level follows the finger off over the menu, which `onPeek` draws under it, and past
    /// `BackSwipe.commits` leaves as ‹ levels does. Under Reduce Motion nothing slides; past the threshold it dips.
    private var backSwipe: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .updating($swipeHeld) { _, held, _ in held = true }
            .onChanged { v in
                guard !swipedAway else { return }
                if swipeTouch?.start != v.startLocation {
                    let call = BackSwipe.decide(start: v.startLocation, translation: v.translation)
                    guard call != .undecided else { return }
                    // A finger already holding the tank keeps it.
                    swipeTouch = (v.startLocation, call == .swipe && drag == nil && !spun ? .swipe : .pass)
                    guard swipeTouch?.call == .swipe else { return }
                    Log.write("back swipe")
                    if slides { peek() }
                }
                guard swipeTouch?.call == .swipe, slides, width > 0 else { return }
                swiped = max(0, v.translation.width) / width
            }
            .onEnded { v in
                guard swipeTouch?.start == v.startLocation, swipeTouch?.call == .swipe, !swipedAway else { return }
                swipeTouch = nil
                if BackSwipe.commits(dx: v.translation.width, predicted: v.predictedEndTranslation.width, width: width) {
                    swipeAway()
                } else {
                    springBack()
                }
            }
    }

    /// The level slides off over the menu under a back swipe; not under Reduce Motion, nor beside the menu, which is in
    /// sight already, so past the threshold the level leaves through the dip.
    private var slides: Bool { !reduceMotion && !beside }

    /// The menu is up beside this level: the window splits, as the open Duo held like a book does.
    private var beside: Bool { besideMenu && pose?.kind == .split }

    /// The menu under the level reads the endless run's save as it is built, so the save is written first, as leaving
    /// writes it.
    private func peek() {
        Resume.save(game)
        onPeek(game.solved)
    }

    private func swipeAway() {
        swipedAway = true
        Log.write("back swipe leaves")
        guard slides else { leave(); return }
        withAnimation(.easeOut(duration: 0.2)) { swiped = 1 } completion: { leave() }
    }

    private func springBack() {
        withAnimation(.spring(duration: 0.3)) { swiped = 0 } completion: {
            if swiped == 0, swipeTouch?.call != .swipe { onPeek(nil) }
        }
    }

    /// The play screen's way out and its count: moves against par, Escapement's ticks or the sandbox's controls.
    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            UnstirButton(.quiet, action: leave) { Text(game.level.back).font(.ui(.button)) } // loc: verbatim localized by Level.back
                .accessibilityLabel(Spoken.back(game.level))
            Spacer()
            if game.level.sandbox {
                // Each says what it steps through where there is room for it.
                ViewThatFits(in: .horizontal) {
                    sandboxControls(named: true)
                    sandboxControls(named: false)
                }
            } else if !game.level.ratchets.isEmpty {
                tickBudget.opacity(showResult && !game.lost ? 0 : 1)
            } else {
                // Endless has no par; its brim is on the rim.
                (game.level.run == nil ? Text("moves \(game.moves) / par \(game.par)", comment: "The play screen's count. Moves, then par")
                    : Text("moves \(game.moves)", comment: "The play screen's count, endless. Moves"))
                    // On black the wasted-twist alarm reads at full contrast, whatever the picture shows.
                    .keyframeAnimator(initialValue: 0.0, trigger: game.pushes) { [tone = countTone] text, t in
                        text.foregroundStyle(t > 0.5 ? Color.alarm : tone)
                    } keyframes: { _ in
                        // Red for 0.4 s. A trailing MoveKeyframe never lands, so the ramp ends the flash.
                        MoveKeyframe(1.0)
                        LinearKeyframe(0.0, duration: 0.8)
                    }
                    .opacity(showResult || ending ? 0 : 1)
                    .accessibilityLabel(game.movesSpoken)
            }
        }
        .font(.ui(.label))
        .padding(.top, 8)
        .modifier(Unseen(clean))
    }

    private var titleRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(game.level.label).fontWeight(.semibold).foregroundStyle(game.level.colour) // loc: verbatim a number, or localized by Level
                .shadow(color: page.glow(game.level.colour), radius: 4)
            // Endless's tank beside its name, where it can't read as the brim's count.
            Text(game.level.run.map { // loc: verbatim localized by Level and here
                String(localized: "\(game.level.title), tank \($0.tank + 1)", comment: "Endless's title. Its name, then the tank")
            } ?? game.level.title)
        }
        .font(.ui(.headline, .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .topLeading) {
            // In the gap above the title, so a pack level's tank sits where every other level's does.
            if let pack = game.level.pack {
                // The size the title's 18 pt gap holds.
                Text(verbatim: pack.name.uppercased()).font(.ui(.eyebrow)).tracking(2).dynamicTypeSize(.large) // loc: verbatim a pack's name, never translated
                    .foregroundStyle(game.level.colour).opacity(0.75)
                    .offset(y: -TypeRole.eyebrow.line(at: .large).height - 2)
                    .accessibilityHidden(true)
            }
        }
        .padding(.top, 18)
        .modifier(Unseen(clean))
    }

    /// How a card arrives, and the tank's shrink for it with it.
    private static let arrival = Animation.easeOut(duration: 0.4).delay(0.3)
    private var reveal: AnyTransition { .opacity.animation(Self.arrival) }
    /// Under Reduce Motion the tank takes its size for the card at once.
    private var shrinking: Animation? { reduceMotion ? nil : Self.arrival }

    /// The tank with what stands over it: the night forwards and "unstirred.". `shrink` scales the tank alone, picture,
    /// knobs and rim as one, about its top, for a card the column has no room for, and `drop` brings its top down for
    /// the word; `bounds` is the tank's pane in the glass's frame and `trackBounds` where a lens's track runs, both nil
    /// in the column; `filmFoot` where the night forwards' lines end, nil under the glass.
    private func stage(_ side: CGFloat, shrink: CGFloat, drop: CGFloat, words: CGFloat?, tabletop: Bool, bounds: CGRect?, trackBounds: CGRect?, filmFoot: CGFloat?) -> some View {
        tank(side, bounds: bounds, trackBounds: trackBounds)
            .animation(shrinking) { $0.scaleEffect(shrink, anchor: .top).offset(y: drop) }
            // Seen, not heard, as the tank is played by sight: direct touch lets a VoiceOver user drag on it.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Puzzle tank, \(Spoken.rods(game.level.layout))")
            .accessibilityValue(game.tankSpoken)
            .accessibilityHint("Played by sight: drag a knob to turn its rod.")
            .accessibilityAddTraits(.allowsDirectInteraction)
            .overlay {
                #if FIRST_STIR
                if ending {
                    NightForwardsFilm(side: side, foot: filmFoot, frozen: frozenEnding) {
                        withAnimation(.easeOut(duration: 0.5)) { ending = false }
                        withAnimation(.easeIn(duration: 0.3).delay(0.4)) { showResult = true }
                        Log.write("night forwards ended")
                    }
                    .transition(.opacity)
                }
                #endif
            }
            .overlay(alignment: .top) {
                // A spill says so over the tank itself.
                if showResult && game.solved && !clean, let words {
                    unstirred(fixed: tabletop).offset(y: -words).transition(reveal)
                }
            }
    }

    /// Fixed in the tabletop, whose upright half budgets `PlayLayout.wordsHeight` for it.
    private func unstirred(fixed: Bool = false) -> some View {
        Text("unstirred.").font(fixed ? .game(22, .semibold) : .ui(.stamp)).shadow(color: page.glow(.white.opacity(0.5)), radius: 6)
    }

    /// The caption, which the result and lost cards hang from: the play controls fade rather than leave, and the result
    /// is an overlay, so the solved tank stays exactly where it was played.
    private func caption(_ layout: PlayLayout, _ fit: PlayLayout.Finished?) -> some View {
        let toSkip = String(localized: "tap to skip", comment: "The caption over an opening's stir")
        let practice = game.level.archived
            ? String(localized: "Practice: this day's best was set on its day.", comment: "The caption of an archive day replayed")
            : String(localized: "Practice: only the first try counts.", comment: "The caption of a daily replayed")
        let opening = game.level.replay
            ? String(localized: "watch the stir \u{00B7} tap to skip", comment: "The caption over a replay's opening stir") : toSkip
        return Text(notice ?? (demoing ? toSkip : shown == nil ? game.counts ? game.caption : practice : opening)) // loc: verbatim localized here, by Game and by say
            .font(page.caption).opacity(captionOpacity)
            // Hung under the note rather than stacked, so plughole 01's tank sits where every level's does. Beside the
            // menu the gear is in sight, so there is nothing to point at (Jack's call r16c-pointer = C).
            .overlay(alignment: .bottom) {
                if pointing && !beside {
                    Self.pointer.font(.ui(.detail)).fixedSize()
                        .opacity(showResult || ending || shown != nil ? 0 : page.tone(.text3).alpha)
                        .animation(.easeOut(duration: 0.4), value: shown == nil)
                        .accessibilityLabel(Self.pointerSpoken) // loc: verbatim localized by pointerSpoken
                        .accessibilityHidden(showResult || ending || shown != nil)
                        // A gap below the note's last line.
                        .offset(y: TypeRole.detail.line(at: playType).height + 7)
                }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: Self.captionLines(paper: page.paper, type: playType), alignment: .top)
            .padding(.top, 14)
            .accessibilityHidden(showResult || ending)
            .modifier(SkipButton(on: demoing || shown != nil) { skip() })
            .overlay(alignment: .top) { if showResult { card(layout, fit) } }
            .modifier(Unseen(clean))
    }

    /// The result or lost card under the caption; in the split, over the menu in the trailing half, centred on the tank
    /// and headed by "unstirred.", as the half round the tank has no room for either. One place in the tree in every
    /// pose, so a change of pose moves the card rather than showing it again.
    ///
    /// The column's card keeps the player's Text Size: where it is taller than the room under the tank, the tank shrinks
    /// for it (`fit`), and only past the tank's least does the card scroll.
    private func card(_ layout: PlayLayout, _ fit: PlayLayout.Finished?) -> some View {
        let over = layout.kind == .split ? layout.menuPane : nil
        return ScrollView {
            VStack(spacing: 0) {
                if over != nil && game.solved && !clean { unstirred().padding(.bottom, 26) }
                if game.lost {
                    LostCard(game: game, notice: notice, undo: undo, again: reset)
                } else {
                    ResultCard(game: game, onNext: onNext, onLook: look, again: reset, now: now, onOffer: offer)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, over == nil ? 14 : 0)
            .frame(maxWidth: .infinity)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cardReach = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        // A card that fits draws its buttons' glow past its own edges.
        .scrollClipDisabled(fit?.scrolls != true)
        .frame(width: over?.width, height: fit?.height ?? cardReach)
        .offset(over.map { pane in
            // From the caption's place, under the stage and its ring; a card taller than the pane starts at its top.
            let top = max(pane.minY, min(layout.stage.midY - cardReach / 2, pane.maxY - cardReach))
            return CGSize(width: pane.midX - layout.tankPane.midX,
                          height: top - layout.stage.maxY - layout.halo.ring * layout.side / 2)
        } ?? .zero)
        .transition(reveal)
    }

    private var playType: DynamicTypeSize { min(typeSize, PlayLayout.typeCap) }

    /// The caption's room: two lines of the note at `type`, in the paper's serif or the label role.
    nonisolated static func captionLines(paper: Bool, type: DynamicTypeSize) -> CGFloat {
        2 * TypeRole.label.line(at: type, design: paper ? .serif : .monospaced).height
    }

    /// Only where colour can't carry the read, so for everyone else the read stays by colour.
    private var swatched: Bool {
        !game.level.masks.isEmpty && (letters || Letters.shown(system: differentiate) || isolated != nil)
    }

    @ViewBuilder private var swatches: some View {
        if swatched {
            ChannelSwatches(isolated: $isolated)
                .opacity(showResult || ending || shown != nil ? 0 : 1)
                .allowsHitTesting(!showResult && shown == nil)
                .modifier(Unseen(clean))
        }
    }

    /// The gap between the wait's own row and the row under it.
    nonisolated static let controlRows: CGFloat = 8

    /// Undo and reset, and on Escapement the wait: between them where the row holds all three on a line each, stepping
    /// aside while reset is armed, as "reset? tap again" needs the room; else on a row of its own over them
    /// (`PlayLayout.waitTakesARow`), where it stays. Where the row can't hold undo beside an armed reset on a line
    /// each, undo steps aside too until the reset is made or lapses, so no label wraps and the row keeps its height.
    private func controls(_ layout: PlayLayout) -> some View {
        let clocks = !game.level.ratchets.isEmpty, width = layout.chromePane.width
        let waitRow = PlayLayout.waitTakesARow(game.level, width: width, type: playType)
        let undoLabel = game.level.sandbox ? String(localized: "undo") : String(localized: "undo \u{00B7} \(game.bank)")
        let alone = armedAt != nil
            && !PlayLayout.rowHolds([undoLabel, String(localized: "reset? tap again")], width: width, type: playType)
        return VStack(spacing: Self.controlRows) {
            if waitRow { waitControl }
            HStack {
                if !alone {
                    // Only a turn of the tank swings back: animated, a rod's undo would glide the stack's shader floats
                    // too. An empty bank only says when it refills, so it only taps.
                    UnstirButton(.secondary, effect: spent ? .tap : .undo, dim: game.history.isEmpty || spent) {
                        if settling { undoQueued = true } else { undo() }
                    } label: {
                        if game.level.sandbox { Text("undo") } else { Text("undo \u{00B7} \(game.bank)") }
                    }
                        .accessibilityLabel(game.level.sandbox ? Text("Undo", comment: "VoiceOver: the undo button") // loc: verbatim each a key
                                            : Text("Undo, \(game.bank) left", comment: "VoiceOver: the undo button. Undos left"))
                        .disabled(game.history.isEmpty)
                        .overlay(alignment: .topTrailing) { refillBadge }
                }
                Spacer()
                if clocks && !waitRow && armedAt == nil {
                    waitControl
                    Spacer()
                }
                resetControl
            }
        }
        .task(id: waits) {
            guard waits > 0 else { return }
            waitLit = true
            guard (try? await Task.sleep(for: .seconds(Self.waitShown))) != nil else { return }
            waitLit = false
            waitedOn = nil
        }
        // Endless has neither (`Game.undo`, `Game.reset`); hidden rather than gone, so its tank sits where every
        // other level's does.
        .disabled(game.finished || shown != nil || demoing || game.level.run != nil || holding)
        .opacity(showResult || ending || game.level.run != nil ? 0 : 1)
        .accessibilityHidden(game.level.run != nil || showResult || ending)
        // 4 where the 40 pt capsules had 8, so the taller buttons leave the tank where it was.
        .padding(.bottom, 4)
        .modifier(Unseen(clean))
    }

    /// The play layout for the safe area `geo` measures: split at the fold where the system reports one, else at the
    /// window's middle where the window is wide.
    private func playLayout(_ geo: GeometryProxy) -> PlayLayout {
        func layout(width: CGFloat) -> PlayLayout {
            PlayLayout.of(size: geo.size, insets: geo.safeAreaInsets, fold: PlayLayout.fold(geo, harness: harnessFold),
                          halo: PlayLayout.Halo(game.level),
                          chrome: PlayLayout.Chrome(game.level, swatches: swatched, type: playType, width: width),
                          type: playType, scale: scale)
        }
        // The chrome's pane doesn't turn on the chrome's height, so its width says whether the wait takes a row.
        return layout(width: layout(width: .infinity).chromePane.width)
    }

    /// Beside the menu the trailing half is the menu's, black from the fold to the window's edge on Escapement's paper
    /// too, until a result or lost card takes it over on the level's own ground.
    @ViewBuilder private func menuGround(_ layout: PlayLayout, _ geo: GeometryProxy) -> some View {
        if besideMenu, page.paper, let menu = layout.menuPane {
            Color.black.padding(.leading, geo.safeAreaInsets.leading + PlayLayout.margin + (layout.tankPane.maxX + menu.minX) / 2)
                .opacity(showResult ? 0 : 1)
                .animation(.easeOut(duration: 0.4).delay(0.3), value: showResult)
                .ignoresSafeArea()
        }
    }


    /// How the column gives a card its room, down to `foot`, the safe area's: nil during play, so the
    /// tank is never other than the layout's; in the split and the tabletop, whose cards have their own places; and
    /// until the card and the caption's place are measured.
    /// `drop` is what "unstirred." needs of the tank's top, where it stands.
    private func finished(_ layout: PlayLayout, foot: CGFloat, drop: CGFloat) -> PlayLayout.Finished? {
        guard showResult, !clean, layout.kind == .column, let captionTop, cardReach > 0 else { return nil }
        return PlayLayout.finished(card: cardReach, room: foot - captionTop, stage: layout.side * PlayLayout.rim,
                                   drop: game.solved ? drop : 0)
    }

    private var screen: some View {
        GeometryReader { geo in
            let layout = playLayout(geo)
            let words: (words: CGFloat?, drop: CGFloat) = layout.kind == .column
                ? PlayLayout.columnWords(over: titleGap ?? .infinity, side: layout.side, type: playType) : (layout.words, 0)
            let foot = geo.size.height, fit = finished(layout, foot: foot, drop: words.drop)
            let stack = layout.kind == .column ? AnyLayout(VStackLayout(spacing: 0)) : AnyLayout(PlayStack(layout: layout, measured: chromeMeasured))
            stack {
                header.modifier(PlayPart.chrome(read: 5))
                titleRow.modifier(PlayPart.chrome(read: 4))
                Spacer(minLength: 12)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { titleGap = $0 }
                stage(layout.side, shrink: fit?.scale ?? 1, drop: fit?.drop ?? 0, words: words.words,
                      tabletop: layout.kind == .tabletop, bounds: layout.bounds, trackBounds: layout.trackBounds,
                      filmFoot: layout.filmFoot)
                    // Drawn at its new size at once; only the glide scales it there.
                    .animation(nil, value: layout)
                    .modifier(Glide(side: layout.side))
                    .modifier(PlayPart.stage(read: 3))
                caption(layout, fit)
                    // The card hangs from the caption unmeasured, over the controls it hides. In the tabletop the stack
                    // must make room for it, or it runs into "unstirred."; the split's goes over the menu.
                    .frame(minHeight: layout.kind == .tabletop && showResult ? cardReach : nil, alignment: .top)
                    // Drawn higher, not laid out higher: the stack, and so the top measured here, stay as played.
                    .animation(shrinking) { $0.modifier(Lift(by: fit?.lift ?? 0)) }
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(Self.column)).minY } action: { captionTop = $0 }
                    .modifier(PlayPart.chrome(read: 2))
                swatches.modifier(PlayPart.chrome(read: 1))
                Spacer(minLength: 12)
                controls(layout).modifier(PlayPart.chrome(read: 0))
                if besideMenu && layout.kind == .split {
                    Color.clear.accessibilityHidden(true)
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(RootView.space)) } action: { onMenu($0) }
                        .layoutValue(key: PlayPart.self, value: .menu)
                }
            }
            // VoiceOver reads the parts in the column's order, header to controls, whatever the pose puts where: by
            // place alone the tabletop's tank, below the fold, would come last.
            .accessibilityElement(children: .contain)
            // Not from a first measure, which can be empty, nor under Reduce Motion.
            .animation(pose.map { $0.side > 0 } == true && !reduceMotion ? .smooth(duration: 0.45) : nil, value: layout)
            .onChange(of: layout, initial: true) { was, now in
                if pose != nil, was != now {
                    Log.write("pose \(now.kind) side=\(Int(now.side))")
                    letGoOnResize()
                }
                pose = now
            }
            .onChange(of: fit, initial: true) {
                guard let fit, let captionTop else { return }
                finishedMeasured?(cardReach, foot - captionTop, fit)
                if fit.lift > 0 {
                    Log.write("card \(Int(cardReach)) over \(Int(foot - captionTop)): tank at \(Int((fit.scale * 100).rounded()))%\(fit.scrolls ? ", card scrolls" : "")")
                }
            }
            .modifier(TapHooks(moment: .init(window: tapWindow(side: layout.side), history: game.history,
                                             pixels: Double(layout.side * scale)),
                               motion: [liveAngle, liveTurn ?? 0, lastSpin]))
            .padding(.horizontal, PlayLayout.margin)
            .coordinateSpace(.named(Self.column))
            .background(alignment: .topLeading) { menuGround(layout, geo) }
        }
        .foregroundStyle(page.ink)
        .tint(page.ink)
        .background(page.ground)
        .environment(\.page, page)
        .accessibilityAction(.escape) { leave() }
        .task(id: replays) {
            let opens = replays > 0 || !resumed
            if opens && !game.level.demo.isEmpty && !still && (replays == 0 ? !demoRetired : fresh) { await clockDemo() }
            if opens, !game.level.sandbox, replays > 0 || !still { await open() }
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
            let left = Brim.card(still: reduceMotion) - (Date.now.timeIntervalSinceReferenceDate - last.time)
            guard (try? await Task.sleep(for: .seconds(max(left, 0)))) != nil else { return }
            withAnimation(.easeIn(duration: 0.3)) { showResult = true }
        }
        .task {
            guard shareSheet, let text = game.shareText, (try? await Task.sleep(for: .seconds(1))) != nil else { return }
            ShareSheet.present([text], animated: false)
        }
        .task {
            if let tapDrags { await tapDrag(tapDrags) }
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
            if shown == nil {
                game.startClock()
                badge = game.badge
                noteLit = frozenClock == nil && game.counts && !game.level.note.isEmpty && !game.level.isStory
                if pointing && !pointed {
                    pointed = true
                    if storesPointing { Best.pointedAtSettings = true }
                    if !beside { AccessibilityNotification.Announcement(Self.pointerSpoken).post() } // loc: verbatim localized by pointerSpoken
                }
            } else {
                lifted = false
            }
        }
        .onChange(of: beside && showResult, initial: true) { onCover($1) }
        .task(id: noteLit) {
            guard noteLit, (try? await Task.sleep(for: .seconds(4))) != nil else { return }
            withAnimation(.easeOut(duration: 0.6)) { noteLit = false }
        }
        // A tap anywhere skips the opening, as the caption says.
        .simultaneousGesture(TapGesture().onEnded { _ = skip() })
        .onChange(of: touching) {
            awake += 1
            if touching && shown == nil { lifted = true }
        }
        .task(id: [awake, game.finished ? 1 : 0]) {
            // Studying a tank takes longer than the screen's lock waits, but a level left alone still lets it sleep.
            Awake.hold(awakeID, !game.finished)
            guard !game.finished, (try? await Task.sleep(for: .seconds(120))) != nil else { return }
            Awake.hold(awakeID, false)
        }
        .onChange(of: settling) {
            guard !settling, undoQueued else { return }
            undoQueued = false
            if !game.finished { undo() }
        }
        .onChange(of: game.refusals) {
            // A full stack refuses as a seized knob does, and says what frees it.
            jammed = game.refusedKnob
            jams += 1
            Knock.thud.play()
            Sound.shared.play(.seized)
            say(String(localized: "the tank is full: undo or reset", comment: "Said when a full stack refuses a stir"))
        }
        .task(id: notices) {
            guard notice != nil, (try? await Task.sleep(for: .seconds(3))) != nil else { return }
            withAnimation(.easeOut(duration: 0.3)) { notice = nil }
        }
        .onChange(of: badge) {
            guard badge > 0 else { return }
            game.refillSeen()
            AccessibilityNotification.Announcement(String(localized: "\(badge) undos added, \(game.bank) in the bank",
                                                          comment: "VoiceOver: the day's refill. Undos added, then the bank")).post()
        }
        .task(id: [shown == nil, touching, game.history.isEmpty]) {
            // The first level shows its verb only to a player who has waited on it, and never once it has been solved.
            withAnimation(.easeOut(duration: 0.2)) { knobLesson = false }
            guard game.level.id == Tier.plughole.levels[0].id, Best.load(game.level.id) == nil, shown == nil, !touching,
                  game.history.isEmpty, (try? await Task.sleep(for: .seconds(KnobLesson.wait))) != nil else { return }
            withAnimation(.easeIn(duration: 0.4)) { knobLesson = true }
        }
        .onChange(of: lensLessonDue, initial: true) { _, due in
            if due {
                withAnimation(.easeIn(duration: 0.4)) { lensLesson = .now }
            } else if lensLesson != nil {
                withAnimation(.easeOut(duration: 0.2)) { lensLesson = nil }
            }
        }
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
            guard game.finished else { showResult = false; waved = false; return }
            onFinish()
            // The fine pass can call the win ~0.1 s after the commit: a finger down in that gap would hold its turn frozen
            // over the win, then have the commit refused on lift.
            endPath(); endTwist()
            drag = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; spun = false
            // A spill's card waits for the pour and the word; a lost clock's for its stamp; a solve's for its wave.
            let wait = game.spilled ? Brim.card(still: reduceMotion) : game.lost ? 0.7 : 1.4 + solveDelay
            if game.solved && solveDelay == 0 { landSolve(chime: true) }
            Task {
                try? await Task.sleep(for: .seconds(wait))
                guard game.finished else { return }
                if game.solved && game.level.endsFirstStir {
                    ending = true
                    Log.write("night forwards")
                    return
                }
                withAnimation(.easeIn(duration: 0.3)) { showResult = true }
                Log.write("result shown")
            }
        }
        // SwiftUI never calls onEnded for a cancelled drag (lock, Siri, a call), so let go here as the lift would, and
        // whichever of this and `holding`'s reset comes second finds nothing held (Jack's call C13, round 13). At once,
        // without the settle: nothing renders behind the lock, so its completion could wait for the return, or never
        // come, and the suspend below reads the game with the move in it. Not on .active: the launch's turn to active
        // would let go of a finger the harness holds. The .inactive step of a return finds nothing held.
        .onChange(of: phase) {
            if phase != .active {
                if drag != nil || spun { Log.write("\(phase) lets go \(state)") }
                // Not `else`: a twist holds the rim as its drag, which `cut` leaves to the twist's own let-go.
                if let g = drag { cut(g, now: true) }
                if spun { letGoSpin(lastSpin, now: true) }
                endPath(); endTwist()
            }
            if phase == .background { Analytics.shared.suspended(game); game.pauseClock(); Resume.save(game) }
            if phase == .active { Analytics.shared.resumed(); game.resumeClock(); if knocks { Knock.warm(hold: false) } }
        }
        .onAppear {
            let rules = game.level.run.map { "tank \($0.tank) brim \($0.brim)" } ?? "par \(game.par)"
            let pack = game.level.pack.map { p in
                " \(p.rawValue) \(Store.shared.state(p)), \(Store.shared.access(game.level).map { "\($0)" } ?? "")"
            } ?? ""
            Log.write("level \(game.level.id) opens, \(rules)\(pack) \(game.stack)")
            // Not in Game.init: SwiftUI reruns LevelView.init for a level it already shows, on a game it then drops.
            if knocks { Knock.warm() }
            if let today { game.refill(today: today) } else { game.refill() }
            // Where there is no opening, onChange's initial call may run before the refill.
            if shown == nil { badge = game.badge }
        }
        // A promoted purchase's card opens over the menu: the level leaves as its back does, so its quit and save go too.
        // Beside the menu the card opens over the trailing half, and the level plays on under it.
        .onChange(of: Store.shared.promoted) { if Store.shared.promoted != nil, !beside { leave() } }
        // A level picked in the menu beside this one: leave for it as leaving for the menu leaves, a finger let go.
        .onChange(of: switching) {
            guard let next = switching else { return }
            letGoOnResize()
            Analytics.shared.left(game)
            Resume.save(game)
            onSwitch(next)
        }
        .onDisappear {
            endPath(); endTwist()
            if knocks { Knock.rest() }
            Awake.hold(awakeID, false)
            Log.write("level \(game.level.id) exits \(state)")
        }
    }

    /// Out of `body`, whose one long expression an older compiler gives up on.
    private var resetControl: some View {
        // The tap that arms only taps; the one that resets sounds as a reset.
        UnstirButton(.secondary, effect: armedAt != nil || game.history.isEmpty ? .reset : .tap, armed: armedAt != nil,
                     action: tapReset) {
            if armedAt == nil { Text("reset") } else { Text("reset? tap again") }
        }
            // Its row never holds less than its one line: an armed reset has the row where undo can't share it.
            .fixedSize()
            .accessibilityLabel(armedAt == nil ? Text("Reset", comment: "VoiceOver: the reset button") // loc: verbatim each a key
                                : Text("Reset, tap again to confirm", comment: "VoiceOver: the reset button, armed"))
            .disabled(settling)
            .accessibilityFocused($resetFocused)
            .task(id: armedAt) {
                // VoiceOver's announcement and its double tap take longer than the window.
                guard armedAt != nil, !holdArmed, !voiceOver,
                      (try? await Task.sleep(for: .seconds(ResetArm.window))) != nil else { return }
                armedAt = nil
            }
            // Any move, undo or finish disarms it, so a second tap always resets what the first was shown.
            .onChange(of: game.history) { if !holdArmed { armedAt = nil } }
            .onChange(of: game.finished) { armedAt = nil }
            .onChange(of: resetFocused) { if !resetFocused && voiceOver { armedAt = nil } }
    }

    /// Escapement's wait, the move a tap on a clock's plate makes, named under the tank so no player has to find the
    /// plate.
    private var waitControl: some View {
        let lit = waitHeld || waitLit
        let live = game.canWait && !demoing && shown == nil && !holding
        let label = Text("wait", comment: "Escapement's play control: a move that only ticks the clocks")
        return UnstirButton(.secondary, dim: !(live || lit)) {
            if let k = waitRod { waitMove(on: k) }
        } label: {
            label
        }
        // Lit, the control inverts: an ink capsule under a label in the page's ground.
        .overlay {
            label.font(.ui(.button)).foregroundStyle(page.ground)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Capsule().fill(page.ink))
                .opacity(lit ? 1 : 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .scaleEffect(waitHeld ? 0.94 : 1)
        .animation(.easeOut(duration: 0.15), value: lit)
        .animation(.easeOut(duration: 0.12), value: waitHeld)
        .accessibilityLabel(String(localized: "Wait", comment: "VoiceOver: Escapement's wait control"))
        .accessibilityHint(String(localized: "The clocks tick and nothing turns.",
                                  comment: "VoiceOver: what Escapement's wait control does"))
        .disabled(!game.canWait)
    }

    /// The clock a wait from the control is made on: any ratchet waits, so the first that can still tick.
    private var waitRod: Int? {
        (game.level.clocks.first { game.canTick($0.rod) } ?? game.level.clocks.first)?.rod
    }

    /// Seconds the control and the plate stay lit after a wait.
    nonisolated static let waitShown = 0.6

    /// A wait on clock `k`, by its plate or the control. A wait no clock can take thuds, as a seized knob does; a full
    /// stack's refusal says so itself.
    private func waitMove(on k: Int) {
        let refusals = game.refusals
        if game.wait(on: k) {
            waitedOn = k
            waits += 1
        } else if !game.finished && game.refusals == refusals {
            jammed = k; jams += 1; Knock.thud.play()
        }
    }

    /// The harness's and the demonstration's wait through the control: pressed a beat, as a finger would, then made.
    private func pressWait(while going: @escaping () -> Bool = { true }) async -> Bool {
        guard let k = waitRod else { return false }
        waitHeld = true
        let on = (try? await Task.sleep(for: .seconds(0.35))) != nil && going()
        waitHeld = false
        if on { waitMove(on: k) }
        return on
    }

    /// The play screen's reset asks for a second tap; the cards' "again" resets at once, as a finished tank has nothing
    /// a slip could lose.
    private func tapReset() {
        let tap = ResetArm.tap(now: .now, armedAt: armedAt, played: !game.history.isEmpty, held: voiceOver)
        armedAt = tap.armedAt
        if tap.reset { reset() } else { AccessibilityNotification.Announcement(String(localized: "Tap again to reset", comment: "VoiceOver: reset, armed")).post() }
    }

    /// Seconds until the newest move's solve lands, at its last tick on Escapement (Jack's call tk-finish = B, round 16):
    /// 0 where no tick is still to come, as after a solve without one or a win the fine pass called past its last tick.
    private var solveDelay: Double {
        guard let at = game.solveAt else { return 0 }
        let d = game.landed + .seconds(at) - ContinuousClock.now
        return max(Double(d.components.seconds) + Double(d.components.attoseconds) * 1e-18, 0)
    }

    /// The solve's wave, swell, success haptic and, with `chime`, its sound, and the glass easing home, once.
    private func landSolve(chime: Bool) {
        guard game.solved, !waved else { return }
        waved = true
        if chime {
            Sound.shared.play(.solve)
            Sound.shared.resolve()
        }
        // Its own transaction: an animated one also glides every shader argument that changed with the win, the wave's
        // centre among them.
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.9)) { eased = true }
    }

    private func reset() {
        let untouched = game.history.isEmpty
        guard game.reset() else { return }
        fresh = untouched
        // The glass eases home on a solve; the next try turns it from where it stands.
        eased = false
        replays += 1
    }

    /// The tank's haptics can play here: a turn of the tank clunks, and a seized knob or a clock's disc thuds.
    private var knocks: Bool {
        game.level.motion != .none || game.level.layout.rods.indices.contains { game.level.kind(of: $0) != .working }
    }

    /// An empty bank says when it refills instead.
    private var spent: Bool { !game.level.sandbox && game.bank == 0 }
    private var page: Page { game.level.page }

    private func undo() {
        guard !spent else { return say(Self.refills) }
        withAnimation(game.history.last?.rod == Game.tank ? .snappy(duration: 0.3) : nil) { game.undo() }
    }

    nonisolated static var refills: String {
        String(localized: "undos refill +2 each day you play", comment: "Said when undo is tapped with none left")
    }

    /// Plughole 01's pointer to the settings sheet, drawn with the menu's own gear.
    static var pointer: Text { Text("sound, haptics, colour letters: \(Image(systemName: "gearshape")) on the menu") }
    nonisolated static var pointerSpoken: String {
        String(localized: "Sound, haptics and colour letters are in settings, the gear on the menu.",
               comment: "VoiceOver: plughole 01's pointer to the settings")
    }

    /// Whether this level opens pointing at the settings: plughole 01 until it has, or under the harness UNSTIR_FRESH.
    nonisolated static func points(at level: Level, harnessed: Bool, fresh: Bool, pointed: Bool) -> Bool {
        level.id == Tier.plughole.levels.first?.id && (harnessed ? fresh : !pointed)
    }

    /// A notice, or Escapement's dead tick, reads above the resting caption.
    private var captionOpacity: Double {
        if showResult || ending { return 0 }
        return notice != nil || game.deadTick || noteLit ? TextTone.text.alpha : TextTone.text2.alpha
    }

    /// Endless has no par to warn of.
    private var countTone: Color { game.level.run == nil ? Self.parTone(moves: game.moves, par: game.par) : .text2 }

    /// The header's count: amber at par, so the next move is over it, and magenta past it (Jack's call C11, round 13).
    nonisolated static func parTone(moves: Int, par: Int) -> Color {
        moves < par ? .text2 : moves == par ? .amber : .magenta
    }

    /// The solved picture's veil under the card, light enough that an over-par solve still shows what it unstirred
    /// (Jack's call C11, round 13).
    nonisolated static func haze(over: Int) -> Double { min(0.05 * Double(over), 0.2) }

    private func say(_ text: String) {
        notice = text
        notices += 1
        AccessibilityNotification.Announcement(text).post() // loc: verbatim localized by the caller
    }

    /// Back to the menu, the only way out short of a finish or the next tank.
    private func leave() {
        Analytics.shared.left(game)
        Resume.save(game)
        onExit(game.solved)
    }

    private func look(_ tier: Tier) {
        Analytics.shared.left(game)
        Resume.save(game)
        onLook(tier)
    }

    /// Beside the menu, the card opens over the trailing half and the level stays.
    private func offer(_ pack: Pack) {
        if !beside {
            Analytics.shared.left(game)
            Resume.save(game)
        }
        onOffer(pack)
    }

    /// Everything that decides what the tank draws, as the log shows it.
    private var state: String {
        "shown=\(Log.opt(shown)) wind=\(wind) live=\(Log.opt(liveRod)) angle=\(liveAngle) turn=\(liveTurn.map { "\($0)" } ?? "nil") "
            + "drag=\(drag.map { "\($0.grab)" } ?? "nil") settling=\(settling) position=\(game.position) "
            + "moves=\(game.moves) pushes=\(game.pushes) stack=\(game.stack.count) \(game.stack)"
    }

    private var stack: [Twist] { shown.map { Array(game.stack.prefix($0)) } ?? game.stack }
    /// A finger, two, or a drawn fingertip is on the tank, or a turn is still settling from one.
    /// Lens 01's lesson, out of the way while a finger is down or the card is up.
    private var lensLessonDue: Bool {
        shown == nil && !game.finished && !touching
            && LensLesson.shows(level: game.level, history: game.history, best: Best.load(game.level.id))
    }

    private var touching: Bool { drag != nil || liveRod != nil || liveTurn != nil || spun || ghost != nil }
    /// Endless's rim, and a spill's murk and words, held this many seconds after the brim's last change: UNSTIR_CLOCK's,
    /// or under Reduce Motion where it comes to rest.
    private var brimHeld: Double? { frozenClock ?? (reduceMotion ? Brim.rest(spilled: game.spilled) : nil) }
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
        defer { if curtain > 0 { withAnimation(.easeOut(duration: 0.2)) { curtain = 0 } } }
        guard await pause(demoDip > 0 ? 0.3 : 1) else { return }
        // A bake that outlasts the still (Lens's halftone on an old phone) would wind in over black or through the
        // strike's flicker, so the opening waits for the strike to land and settle. Only a picture that never lands
        // lets it go on, after 30 s.
        if !struck {
            for _ in 0..<600 where !struck { guard await pause(0.05) else { return } }
            guard await pause(PictureLayer.strikeLength(calm: reduceMotion || dimFlashing || game.level.picture.paper)) else { return }
        }
        if demoDip > 0 { withAnimation(.easeInOut(duration: 1.4)) { demoDip = 0 } }
        if game.level.replay {
            for (i, t) in scramble.enumerated() {
                let d = 0.2 * Double(abs(t.steps))
                liveRod = game.knob(over: t.rod)
                withAnimation(.easeInOut(duration: d)) { liveAngle = Double(t.steps) * Tank.step }
                guard await pause(d) else { return }
                shown = i + 1; liveRod = nil; liveAngle = 0
                // Lets liveAngle render at 0 before the next rod animates from it.
                guard await pause(0.15) else { return }
            }
            // A beat on the stirred picture before it is the player's.
            guard await pause(0.3) else { return }
        } else if reduceMotion {
            withAnimation(.easeIn(duration: 0.2)) { curtain = 1 }
            guard await pause(0.2) else { return }
            wind = 1
            withAnimation(.easeOut(duration: 0.2)) { curtain = 0 }
            guard await pause(0.2) else { return }
        } else {
            withAnimation(.easeInOut(duration: 1.4)) { wind = 1 }
            guard await pause(1.4) else { return }
        }
        shown = nil
    }

    /// Cuts the clock's demonstration or the opening short; false when neither is playing.
    @discardableResult private func skip() -> Bool {
        if demoing {
            demoing = false
            Log.write("skip demo")
            return true
        }
        guard shown != nil else { return false }
        // Past 1, so the value changes and cuts short a wind-in still animating towards 1.
        shown = nil; liveRod = nil; liveAngle = 0; liveTurn = nil; wind = 2
        Log.write("skip \(state)")
        return true
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
    private func play(_ moves: [Harness.Step]) async {
        if fingered { await hand(moves); return }
        for step in moves {
            guard (try? await Task.sleep(for: .seconds(pace))) != nil, !game.finished else { return }
            guard case .twist(let m) = step else {
                if !(await harnessed(step)) { return }
                continue
            }
            if game.level.kind(of: m.rod) == .ratchet {
                waitMove(on: m.rod)
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
    private func hand(_ moves: [Harness.Step]) async {
        guard (try? await Task.sleep(for: .seconds(rest))) != nil else { return }
        for step in moves {
            guard case .twist(let m) = step else {
                if !(await harnessed(step)) { return }
                continue
            }
            guard !game.finished, await fingertip(m, while: { !game.finished }),
                  (try? await Task.sleep(for: .seconds(1.0))) != nil else { return }
        }
    }

    /// UNSTIR_MOVES's other steps: an undo through the control, with its sound, a wait through the wait control, or a
    /// rest. False once the wait is cut.
    private func harnessed(_ step: Harness.Step) async -> Bool {
        switch step {
        case .twist: return true
        case .rest(let s): return (try? await Task.sleep(for: .seconds(s))) != nil
        case .undo:
            Sound.shared.play(spent ? .tap : .undo)
            undo()
            return (try? await Task.sleep(for: .seconds(1.0))) != nil
        case .wait:
            guard await pressWait() else { return false }
            return (try? await Task.sleep(for: .seconds(1.0))) != nil
        }
    }

    /// One move by a drawn fingertip, through the calls a finger makes: it lands where `grab` gives it the move's rod or
    /// the rim, holds a beat, rides the turn round and lifts; on a ratchet it taps. False once `going` fails.
    private func fingertip(_ m: Twist, while going: @escaping () -> Bool) async -> Bool {
        func pause(_ s: Double) async -> Bool { (try? await Task.sleep(for: .seconds(s))) != nil && going() }
        let level = game.level, layout = level.layout, both = layout.swirl != nil && level.motion != .none
        if level.kind(of: m.rod) == .ratchet {
            // Any step but 1 taps halfway out the clock's disc instead of on its ratchet.
            let at = centre(m.rod) + (m.steps == 1 ? 0 : 0.5 * rods[m.rod].z) * SIMD2(0.7071, -0.7071)
            withAnimation(.easeOut(duration: 0.12)) { ghost = (at, centre(m.rod), false, false) }
            finger = at
            guard await pause(0.45) else { return false }
            pressing = m.rod
            guard await pause(0.18) else { return false }
            tapped(m.rod, from: at, to: at)
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
        withAnimation(.easeOut(duration: 0.12)) { ghost = (at, rim || swirl ? .zero : centre(m.rod), rim, !rim && level.lenses.contains(game.slot(of: m.rod))) }
        finger = at; landed = at
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
    /// heal hands the clock its seam and it ticks; the wait control presses, its plate lighting with it, and it ticks
    /// again. Then the tank dips to black and the problem winds in. A tap skips it.
    private func clockDemo() async {
        guard !game.level.clocks.isEmpty else { return }
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
        // The wait is made on the control, which a player sees named, not on the plate.
        if on {
            say(Self.demoWait)
            if await pause(0.6), await pressWait(while: going) { _ = await pause(1.6) }
        }
        while settling { try? await Task.sleep(for: .seconds(0.05)) }
        notice = nil
        withAnimation(.easeOut(duration: 0.2)) { ghost = nil }
        drag = nil; liveRod = nil; liveAngle = 0; pressing = nil; counted = nil
        withAnimation(.easeIn(duration: 0.35)) { demoDip = 1 }
        try? await Task.sleep(for: .seconds(0.4))
        game.endDemo()
        demoing = false
        Log.write("demo ends \(state)")
    }

    /// The demonstration's caption as it waits on the control.
    nonisolated static let demoWait = String(localized: "wait: the clock ticks, nothing turns",
                                             comment: "Escapement's demonstration, as the wait control is pressed: a wait ticks the clock and turns no rod")

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
            (game.firstRefill ? Text("+\(badge) undos", comment: "Over the undo button: the day's first refill") : Text(verbatim: "+\(badge)"))
                .font(.ui(.detail)).foregroundStyle(page.signal(.lime))
                .opacity(badge > 0 ? Self.refillShown(frozenClock ?? s) : 0)
        } keyframes: { _ in
            MoveKeyframe(0.0)
            LinearKeyframe(Self.refillTime, duration: Self.refillTime)
        }
        // Its trailing edge on the count's, just above the capsule.
        .offset(x: -22, y: -TypeRole.detail.line(at: playType).height - 8)
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

    private func sandboxControls(named: Bool) -> some View {
        let picture = String(localized: game.level.picture.display)
        return HStack(spacing: 8) {
            sandboxControl(named ? String(localized: "picture: \(picture) \u{203A}", comment: "The sandbox's picture control. The picture")
                           : "\(picture) \u{203A}", game.nextPicture)
            // A turn in hand, or snapping to commit, names a rod of the current layout.
            sandboxControl(Self.layoutLabel(game.level.layout, named: named)) {
                if liveRod == nil { game.nextLayout() }
            }
        }
    }

    /// The sandbox's layout control. Where another layout has as many rods it names the layout too, or the tap from
    /// quad to eye would leave the label as it was.
    nonisolated static func layoutLabel(_ layout: Layout, named: Bool) -> String {
        let base = layout.base ?? layout, rods = layout.rods.count
        let shared = Layout.allCases.contains { $0 != base && $0.rods.count == base.rods.count }
        return switch (named, shared) {
        case (true, false): String(localized: "rods: \(rods) \u{203A}", comment: "The sandbox's layout control. Its rods")
        case (true, true): String(localized: "rods: \(rods) \u{00B7} \(String(localized: base.display)) \u{203A}",
                                  comment: "The sandbox's layout control. Its rods, then the layout")
        case (false, false): String(localized: "\(rods) rods \u{203A}", comment: "The sandbox's layout control, short. Its rods")
        case (false, true): "\(String(localized: base.display)) \u{203A}"
        }
    }

    /// Narrower than a secondary's 20 pt sides, so both fit the header beside the way out.
    private func sandboxControl(_ label: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label).modifier(ButtonFace(emphasis: .secondary, inset: 14)) // loc: verbatim localized by the caller
        }
        .buttonStyle(Sounding(presses: true))
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

    /// `bounds`: the tank's pane in the glass's frame, which counts keep inside, and `trackBounds` a lens's track; nil in
    /// the column.
    private func tank(_ side: CGFloat, bounds: CGRect?, trackBounds: CGRect?) -> some View {
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
                || game.stack.landing(rod: game.slot(of: k), steps: steps, in: game.level.layout, lenses: game.level.lenses, masks: game.level.masks) != nil)
        } ?? false
        let step = game.level.layout.tankStep
        let held = liveTurn.map { $0 + (spun ? lastSpin : 0) }
        let turn = eased ? (Double(game.position) / Double(game.level.layout.order)).rounded() * 2 * .pi
            : Double(game.position) * step + (held ?? 0)
        let unstirred = Unstirred(stack: bare ? [] : stack, layout: game.level.layout, lenses: game.level.lenses, masks: game.level.masks, liveRod: liveRod.map(game.slot(of:)), liveAngle: liveAngle,
                                  wind: wind, side: side, haze: showResult ? Self.haze(over: game.over) : 0, turn: turn,
                                  fillEntries: game.level.picture.fillEntries, isolate: isolated,
                                  whiteIsolate: differentiate, budget: Taps.shared.budget(pixels: Double(side * scale)),
                                  fine: fine, crisp: crisp)
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
        // In the split and the tabletop a lens turns only as far as its track shows inside the pane (Jack's call
        // d3-lenscap = B, round 16).
        func room(_ k: Int) -> ClosedRange<Int>? {
            game.level.lenses.contains(game.slot(of: k)) ? Self.trackRoom(knob: at(k).y, bounds: trackBounds) : nil
        }
        let heldRoom = liveRod.flatMap(room)
        // A lens's count runs up and down a track beside its knob, on the side away from the finger.
        let lensTrack: CGFloat? = rodCount.flatMap { c in
            guard game.level.lenses.contains(game.slot(of: c.k)) else { return nil }
            let side = (landed ?? finger).map { Self.trackSide(landing: $0.x, knob: rods[c.k].x) } ?? 1
            return Self.trackX(knob: at(c.k).x, core: core, side: side)
        }
        // Out of the way while the tank is held.
        let lesson = shown == nil && !game.finished && held == nil
        // The swirl's too while it is held.
        let swirlLesson = lesson && !game.swirled && game.level.layout.swirl != nil && probing != game.level.layout.swirl
        let arc = (game.level.motion != .none && lesson && !game.tankTurned ? RimLesson.arc(r, .tank) : [])
            + (swirlLesson ? RimLesson.arc(r, .swirl) : [])
        // A clock's ratchet and its count want more room than a knob.
        let others: [(CGPoint, CGFloat)] = knobs.filter { $0 != rodCount?.k }
            .map { (at($0), (game.level.ratchets.contains($0) ? Self.ratchetSize(core) / 2 + 40 : core / 2) + Self.countRoom) }
            + arc.map { ($0, RimLesson.width + Self.countRoom) }
            + (lensTrack.map { x in (-3...3).map { (CGPoint(x: x, y: at(rodCount!.k).y + CGFloat($0) * Self.trackPitch), Self.countRoom + 4) } } ?? [])
        // Endless: when the push that spilled the brim was made. UNSTIR_CLOCK holds the brim that long after its last change.
        let spillAt = game.spilled ? game.brimEvents.last?.time : nil
        // A live picture is the only kind that redraws while the player is still; 60 Hz is plenty for motion this slow,
        // and 30 Hz while the phone saves power.
        // Every other picture pauses the timeline, so nothing ticks, except while a spill stirs it together or the swirl
        // breathes. Under Reduce Motion a live picture and a spill hold still.
        let moving = !reduceMotion && (game.level.picture.isLive || spillAt != nil && brimMoving) || breathing
        let tickNow = game.tick, clocks = game.level.clocks, playable = shown == nil, page = page
        return ZStack {
            TimelineView(.animation(minimumInterval: 1.0 / (Power.shared.saving ? 30 : 60), paused: !moving || frozenClock != nil)) { timeline in
                let murk = spillAt.flatMap { at -> [Float]? in
                    let since = (brimHeld ?? timeline.date.timeIntervalSinceReferenceDate - at) - Brim.murk
                    return since > 0 ? Brim.murk(game.level.layout, seed: game.level.run?.seed ?? 0, at: since) : nil
                } ?? []
                let swirlBreath = game.level.layout.swirl.map { (rod: game.slot(of: $0), angle: breathAngle) }
                KeyframeAnimator(initialValue: Self.ticksDone, trigger: game.tickEvents) { p in
                    Group {
                        #if FIRST_STIR
                        if let scene = game.level.story?.scene {
                            SceneLayer(scene: scene, played: game.played, wound: game.wound, count: game.level.scramble.count, side: side,
                                       onStrike: { struck = true })
                        } else {
                            PictureLayer(picture: game.level.picture, side: side, seed: Int(game.level.label) ?? 0,
                                         clock: frozenClock ?? game.level.picture.clock(timeline.date.timeIntervalSince(opened), still: reduceMotion),
                                         panel: game.level.plate, onStrike: { struck = true })
                        }
                        #else
                        PictureLayer(picture: game.level.picture, side: side, seed: Int(game.level.label) ?? 0,
                                     clock: frozenClock ?? game.level.picture.clock(timeline.date.timeIntervalSince(opened), still: reduceMotion),
                                     panel: game.level.plate, onStrike: { struck = true })
                        #endif
                    }
                        .keyframeAnimator(initialValue: -1.0, trigger: waved) { picture, w in
                            var u = unstirred
                            // Under Reduce Motion the light swells where it stands instead of running out as a wave, but not on
                            // paper: contrast pivots on mid-grey, so bone would swell to white.
                            let calm = reduceMotion && frozenWave == nil, swells = calm && !page.paper
                            u.wave = SIMD3(Float(source.x), Float(source.y), calm || page.paper ? -1 : Float(frozenWave ?? w))
                            u.breath = swirlBreath
                            // Escapement: the move's ticks in turn, the one in flight turned part way on the stack it changed.
                            if p < Double(tickNow.count), playable {
                                let i = Int(max(p, 0)), t = tickNow[i]
                                u.stack = t.stack
                                u.tick = (t.rod, Self.flight(p, i) * Double(t.dir) * Tank.step)
                            }
                            let drawn = picture.modifier(u).modifier(Murk(stirs: murk, side: side))
                            // Only Reduce Motion pays for the contrast filter, over the hottest draw in the app.
                            return Group { if swells { drawn.contrast(1 + 0.5 * max(sin(.pi * w / 1.9), 0)) } else { drawn } }
                        } keyframes: { _ in
                            // A light wave from the last-turned rod, over the clean picture. The animator holds its last value, so
                            // the band runs out past the farthest rim of any layout (1.56 from a ring rod) rather than parking on it.
                            MoveKeyframe(0.0)
                            LinearKeyframe(1.9, duration: 0.9, timingCurve: .easeOut)
                        }
                } keyframes: { _ in Self.tickKeys }
            }
            .clipShape(Circle())
            .opacity((1 - demoDip) * (1 - curtain))
            .task(id: [game.level.id, "\(side)", "\(scale)"]) {
                guard game.level.picture == .halftone, !game.level.lenses.isEmpty else { return }
                let n = Int((side * scale).rounded()), panel = Halftone.panel(game.level.panel)
                let lenses = game.level.lenses.sorted().map { rods[$0] }
                let start = Date.now
                let detail = await Task.detached(priority: .userInitiated) { panel.detail(n, lenses: lenses) }.value
                // A detail baked for another size still draws true, a little coarser or finer, until this one lands.
                guard !Task.isCancelled, let made = Fine(detail) else { return }
                Log.write("halftone \(panel.name) \(n) px detail baked in \(Int(Date.now.timeIntervalSince(start) * 1000)) ms, \(made.bytes) bytes")
                fine = made
            }
            .task(id: struck) {
                let strike = PictureLayer.strikeLength(calm: reduceMotion || dimFlashing || game.level.picture.paper)
                guard struck, (try? await Task.sleep(for: .seconds(strike))) != nil else { return }
                lit = true
            }
            .onChange(of: lit && fine != nil) { _, ready in withAnimation(.easeOut(duration: 0.2)) { crisp = ready ? 1 : 0 } }
            if page.paper && !(reduceMotion && frozenWave == nil) {
                Color.clear.keyframeAnimator(initialValue: -1.0, trigger: waved) { v, w in
                    v.overlay { page.wave(frozenWave ?? w, at: CGPoint(x: r + source.x * r, y: r + source.y * r), r: r) }
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.9, duration: 0.9, timingCurve: .easeOut)
                }
                .clipShape(Circle())
                .allowsHitTesting(false)
            }
            // The bezel stays: it is the tank's steel, which no touch or state changes, so not interface.
            if clean {
                Bezel(r: r)
            } else {
                if !game.finished {
                    ForEach(clocks, id: \.rod) { c in
                        // Grey as its last tick lands, in the move's turn.
                        ClockHint(radius: disc(c.rod), spent: !game.canTick(c.rod) && shown == nil && !demoing,
                                  lands: Self.tickBeat + Self.tickTurn * Double((game.tick.firstIndex { $0.rod == c.rod } ?? -1) + 1))
                            .position(at(c.rod)).opacity(1 - demoDip).allowsHitTesting(false)
                    }
                }
                if let k = liveRod, shown != nil {
                    glowRing(.magenta, 2.5, 6, under: page.ground.opacity(0.7))
                        .frame(width: 2 * disc(k), height: 2 * disc(k))
                        .position(at(k))
                }
                if let c = rodCount, c.live || c.steps != 0 {
                    Group {
                        if let x = lensTrack {
                            track(at(c.k), disc(c.k), x: x, pitch: Self.trackPitch, steps: c.steps, bounds: trackBounds,
                                  now: Double(c.steps) + (c.live ? liveAngle / Tank.step - Double(Detent.steps(liveAngle, of: Tank.step)) : 0))
                        } else {
                            dial(at(c.k), disc(c.k), inner: dashes(c.k, r), from: turned(c.k) - Double(joined(game.slot(of: c.k))) * Tank.step,
                                 to: turned(c.k) + (c.live ? liveAngle : 0), steps: c.steps, step: Tank.step)
                        }
                    }
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
                Circle().stroke(page.live, lineWidth: Self.hairline)
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
                        BrimRing(r: r, brim: game.brim, events: game.brimEvents, base: run.brim, colours: rimColours, held: brimHeld,
                                 still: frozenClock == nil && reduceMotion,
                                 paused: !(brimMoving || !game.spilled && game.brim >= Run.room - 1))
                    }
                }
                .keyframeAnimator(initialValue: 0.0, trigger: struck) { ring, o in
                    ring.opacity(o)
                } keyframes: { _ in PictureLayer.strike(calm: reduceMotion || dimFlashing) }
                if game.level.motion != .none {
                    KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                        RimLesson(kind: .tank, r: r, showing: lesson && !game.tankTurned,
                                  pulse: lesson && jammed.map { game.level.kind(of: $0) != .working } == true
                                      ? Self.pulse(frozenShake ?? s) : 0, clock: frozenClock)
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
                    if let c = clocks.first(where: { $0.rod == k }) {
                        KeyframeAnimator(initialValue: Self.ticksDone, trigger: game.tickEvents) { v in
                            // Where this clock's tick stands in the move's turn: before it, it is still to come.
                            let i = tickNow.firstIndex { $0.rod == k }, f = i.map { Self.flight(v, $0) } ?? 1
                            let ride = f < 1 && v >= Double(i ?? 0) ? sin(.pi * f) : 0
                            KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                                ratchet(k, back: c.dir < 0, at: v, of: i, flight: f, pawl: ride, shake: s, core: core,
                                        plate: Self.ratchetReach * r)
                            } keyframes: { _ in Self.jolt }
                        } keyframes: { _ in Self.tickKeys }
                        .position(x: (p.x * scale).rounded() / scale, y: (p.y * scale).rounded() / scale)
                    } else {
                        KeyframeAnimator(initialValue: 1.0, trigger: jams) { s in
                            RodView(angle: turned(k) + (probing == k ? liveAngle : 0) + (jammed == k ? Self.shake(frozenShake ?? s) : 0),
                                    size: core, seized: game.level.kind(of: k) != .working, grabbed: probing == k,
                                    lens: game.level.lenses.contains(game.slot(of: k)), tint: game.level.tint(of: game.slot(of: k)),
                                    channels: game.level.channels(of: game.slot(of: k)))
                        } keyframes: { _ in Self.jolt }
                            .position(x: (p.x * scale).rounded() / scale, y: (p.y * scale).rounded() / scale)
                    }
                }
                // A spilled tank keeps its caps over the murk, and a lost one its clock.
                .opacity(showResult && !game.spilled && !game.lost ? 0 : 1)
                .environment(\.channelLetters, letters || Letters.shown(system: differentiate))
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
                ForEach(clocks, id: \.rod) { c in clockMarks(c.rod, dir: c.dir, at(c.rod), disc: disc(c.rod), size: Self.ratchetSize(core), r: r) }
                if game.lost && shown == nil, let k = game.tick.last?.rod ?? game.pushedClock ?? game.lastStopped {
                    lostMarks(at(k), size: Self.ratchetSize(core), r: r,
                              twisted: Set(game.stack.map(\.rod)).sorted().map { (at($0), disc($0)) })
                }
                if knobLesson && shown == nil && !touching {
                    KnobLesson(centre: at(0), reach: 0.5 * disc(0), clock: frozenClock).transition(.opacity)
                }
                if let since = lensLesson, let k = game.level.lenses.min().map(game.knob(over:)) {
                    LensLesson(knob: at(k), core: core, step: Self.lensPitch * r, since: since, clock: frozenClock)
                        .transition(.opacity)
                }
                if let spillAt {
                    TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !brimMoving || brimHeld != nil)) { timeline in
                        SpillWords(r: r, at: brimHeld ?? timeline.date.timeIntervalSinceReferenceDate - spillAt)
                    }
                }
                if let c = rodCount, c.steps != 0 {
                    countLabel(c.steps).opacity(c.live ? 1 : 0.45)
                        .position(countSpot(at(c.k), reach: countReach(c.k, r), side: side, bounds: bounds, avoid: others))
                }
                if let c = tankCount, c.steps != 0 {
                    countLabel(c.steps).opacity(c.live ? 1 : 0.45).position(countSpot(CGPoint(x: r, y: r), reach: 1.045 * r + 16, side: side, bounds: bounds))
                }
                if let ghost {
                    // Turned with the stir it holds, about its pivot, so it rides the same animation round the arc; on a
                    // lens, carried up and down as a finger drives one.
                    let a = ghost.rim ? held ?? 0 : liveAngle
                    page.finger(diameter: 40)
                        .position(x: r + ghost.at.x * r, y: r + ghost.at.y * r)
                        .frame(width: side, height: side)
                        .rotationEffect(.radians(ghost.lens ? 0 : a), anchor: UnitPoint(x: (ghost.pivot.x + 1) / 2, y: (ghost.pivot.y + 1) / 2))
                        .offset(y: ghost.lens ? -a / Tank.step * Self.lensPitch * r : 0)
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(width: side, height: side)
        .keyframeAnimator(initialValue: 0.0, trigger: waved) { tank, t in
            tank.scaleEffect(1 + (reduceMotion ? 0 : 0.02) * sin(t * .pi))
        } keyframes: { _ in CubicKeyframe(1.0, duration: 0.9) }
        // A level that turns, or swirls, reaches a finger on the bezel or just beyond it.
        .contentShape(Circle().inset(by: game.level.motion == .none && game.level.layout.swirl == nil ? 0 : -25))
        .gesture(twistGesture(r) { k in room(k).map { (steps: $0, joined: joined(game.slot(of: k))) } })
        // UNSTIR_LIVE's held turn is held to the track as a finger's is. Not a real finger's (its `path`, which the
        // harness's seeded touch lacks): a change of pane comes with a change of pose, which lets it go
        // (`letGoOnResize`), and its let-go commits what the track showed.
        .onChange(of: heldRoom, initial: true) {
            guard let k = liveRod, let heldRoom, !settling, path == nil else { return }
            liveAngle = Self.lensCapped(liveAngle, joined: joined(game.slot(of: k)), room: heldRoom)
        }
        .onChange(of: holding) { _, now in if !now, let g = drag { cut(g) } }
        // Not .none: that also switches off the gesture above.
        .simultaneousGesture(spinGesture, including: game.level.motion == .none ? .subviews : .all)
        .haptic(.impact(weight: .light, intensity: 0.7), trigger: grabs)
        .haptic(.selection, trigger: ticks)
        .onChange(of: ticks) { Sound.shared.play(.tick) }
        .haptic(.selection, trigger: misses)
        .onChange(of: tankTicks) { Knock.clunk.play() }
        .haptic(.impact(weight: .heavy), trigger: game.cancels)
        // Only on a new heal: not on a reset's return to 0, nor an undo's step back.
        .onChange(of: game.heals) { was, now in if now > was { Sound.shared.play(.heal(now)) } }
        // Escapement B's reed, a note a move, its place in the motif the moves before it; the solve's is the layer's D.
        .onChange(of: game.moves) { was, now in
            if now > was, game.level.layer == .escapement, !game.solved, !game.demoing { Sound.shared.reed(was) }
        }
        // Another try after a solve wants the layer afresh, for its reed and its next resolution.
        .onChange(of: game.solved) { if !game.solved { Sound.shared.layer(game.level.layer) } }
        .haptic(.warning, trigger: game.pushes)
        // A push that spills a run sounds only as the spill.
        .onChange(of: game.pushes) { if !game.spilled { Sound.shared.play(.push) } }
        .haptic(trigger: felt) { _, now in now?.haptic }
        .onChange(of: game.tickEvents) { sounding = game.tickEvents }
        .task(id: sounding) {
            guard sounding != nil else { return }
            await game.soundTicks { cue in
                // The solving tick's chime and success haptic are the wave's, which lands once however the win came.
                if cue.solves { landSolve(chime: true) } else { felt = Felt(n: (felt?.n ?? 0) + 1, haptic: cue.haptic) }
            }
        }
        .haptic(.success, trigger: waved) { _, waved in waved }
        // One sound for the end, as its card shows it: a solve's lands with the wave.
        .onChange(of: game.finished) { if game.finished && !game.solved { Sound.shared.play(.spilled) } }
        // Keeps texture pixels on device pixels, so the untwisted picture is not blurred by half a pixel.
        .offset(snap)
        .onGeometryChange(for: CGPoint.self) { $0.frame(in: .global).origin } action: { o in
            snap = CGSize(width: (o.x * scale).rounded() / scale - o.x, height: (o.y * scale).rounded() / scale - o.y)
            tankOrigin = o
        }
        .padding(0.045 * r)
    }

    /// Escapement: a move's ticks in flight, 0 up to `ticksDone`: a beat after the lift, then each clock's in turn, one
    /// 30-degree step of its core in `tickTurn`, so the clicks read in order (Jack's call D1, round 9).
    @KeyframesBuilder<Double> private static var tickKeys: some Keyframes<Double> {
        MoveKeyframe(0.0)
        LinearKeyframe(0.0, duration: tickBeat)
        LinearKeyframe(ticksDone, duration: ticksDone * tickTurn)
    }
    /// The most clocks a level has, so the most ticks one move lands.
    private static let ticksDone = 3.0

    /// The `i`th tick's flight, 0 to 1, eased, at `v` of the move's ticks.
    nonisolated private static func flight(_ v: Double, _ i: Int) -> Double {
        let x = min(max(v - Double(i), 0), 1)
        return x * x * (3 - 2 * x)
    }

    /// Escapement: the beat between a lift and its first tick, and each tick's turn.
    nonisolated static let tickBeat = 0.15, tickTurn = 0.3
    /// When a move's `i`th tick lands after its lift.
    nonisolated static func tickAt(_ i: Int) -> Double { tickBeat + tickTurn * Double(i) }

    /// Escapement: the ticks left, a split-flap numeral whose every tick flips it down one as that clock's tick starts
    /// to turn, so a move of three running clocks flips it three times in their order. Escapement has no par (Jack's
    /// call EL1, round 11).
    private var tickBudget: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("ticks")
                .keyframeAnimator(initialValue: 0.0, trigger: game.tickPushes) { [ink = page.ink] text, t in
                    text.foregroundStyle(t > 0.5 ? Color.alarm : ink)
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(0.0, duration: Self.tickBeat)
                    MoveKeyframe(1.0)
                    LinearKeyframe(0.0, duration: 0.8)
                }
            KeyframeAnimator(initialValue: Self.ticksDone, trigger: game.tickEvents) { v in
                let n = game.tick.count, started = (0..<n).filter { v > Double($0) }.count
                let shown = game.budget + n - started
                FlipCounter(value: shown, was: started > 0 ? shown + 1 : shown,
                            fall: started > 0 ? min(v - Double(started - 1), 1) : 1,
                            digits: max(String(game.level.budget).count, 2),
                            still: reduceMotion, out: game.lost)
            } keyframes: { _ in Self.tickKeys }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(game.budget) ticks left")
        .onChange(of: game.tickPushes) { if game.deadTick { AccessibilityNotification.Announcement(game.deadTickWords).post() } } // loc: verbatim localized by Game
    }

    /// Escapement: the ratchet wheel's width, a knob and a half, so its teeth read.
    nonisolated static func ratchetSize(_ core: CGFloat) -> CGFloat { 1.5 * core }

    /// Clock `k`'s ratchet, `flight` of the way through its newest tick's turn, the `i`th of the move's turn at `v`. Its
    /// hub flips as the header does, as its tick starts, so the header is always the hubs' sum; it greys once that tick
    /// has landed, with the stop's amber ring.
    private func ratchet(_ k: Int, back: Bool, at v: Double, of i: Int?, flight f: Double, pawl: Double, shake s: Double,
                         core: CGFloat, plate: CGFloat) -> RatchetView {
        let owed = game.owed(k), started = i.map { v > Double($0) }
        return RatchetView(angle: (Double(game.escapement.ticks[k] ?? 0) - (1 - f)) * Tank.step + (jammed == k ? Self.shake(frozenShake ?? s) : 0),
                           size: Self.ratchetSize(core), plate: plate, pawl: pawl, lit: pressing == k || waitedOn == k,
                           stopped: !game.canTick(k) && f >= 1 && shown == nil && !demoing, back: back,
                           owed: started == false ? owed + 1 : owed, was: started == true ? owed + 1 : nil,
                           fall: started == true ? min(v - Double(i!), 1) : 1, still: reduceMotion)
    }

    /// Escapement: what clock `k` at `c` shows round its ratchet: a red flash for a tick of its own that pushed; while a
    /// pushed tick stands, a ring and its vermilion count, signed as the clock ticks; its disc lighting as it ticks, in
    /// the move's turn; and a ring going out as it stops.
    private func clockMarks(_ k: Int, dir: Int, _ c: CGPoint, disc: CGFloat, size: CGFloat, r: CGFloat) -> some View {
        let overdue = game.overdue(k), showing = shown == nil
        let core = 2 * Tank.plateau * disc
        // Each clock's marks wait for its own tick in the move's turn.
        let delay = Self.tickBeat + Self.tickTurn * Double(game.tick.firstIndex { $0.rod == k } ?? 0)
        let ticked = game.tick.contains { $0.rod == k }, pushed = game.tick.contains { $0.rod == k && $0.pushed }
        return ZStack {
            Circle().stroke(Color.alarm, lineWidth: 2).frame(width: size + 10, height: size + 10)
                .keyframeAnimator(initialValue: 1.0, trigger: game.tickPushes) { ring, t in
                    ring.opacity(t >= 1 || !pushed ? 0 : 1 - t).scaleEffect(1 + 0.25 * t)
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(0.0, duration: delay)
                    LinearKeyframe(1.0, duration: 0.5, timingCurve: .easeOut)
                }
                .position(c)
            if overdue > 0 && showing {
                Circle().stroke(page.accent, lineWidth: 1.5).frame(width: size + 8, height: size + 8).position(c)
                badge(dir > 0 ? "+\(overdue)" : "\u{2212}\(overdue)").position(Self.badgeSpot(c, size: size, r: r))
                    .transition(.opacity)
            }
            // The clock's disc lights as it ticks, so the eye goes where the tick acts.
            Circle().stroke(page.accent, lineWidth: Self.hairline)
                .frame(width: 2 * disc, height: 2 * disc)
                .keyframeAnimator(initialValue: 1.0, trigger: game.tickEvents) { v, t in
                    v.opacity(t >= 1 || !ticked ? 0 : 0.9 * sin(.pi * t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(0.0, duration: delay - 0.15)
                    LinearKeyframe(0.25, duration: 0.15)
                    LinearKeyframe(1.0, duration: 0.6)
                }
                .position(c)
            // A tap off the plate: a ring through the finger closes on the plate's edge, which flares.
            let plate = Self.ratchetReach * r, from = missed?.k == k ? (missed?.by ?? 0) * r : plate
            Circle().stroke(page.live, lineWidth: 1.5)
                .keyframeAnimator(initialValue: 2.0, trigger: misses) { v, t in
                    v.frame(width: 2 * (from + (plate - from) * min(t, 1)), height: 2 * (from + (plate - from) * min(t, 1)))
                        .opacity(missed?.k != k || t >= 2 ? 0 : t < 1 ? 0.5 + 0.4 * t : 0.9 * (2 - t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(1.0, duration: 0.35, timingCurve: .easeIn)
                    LinearKeyframe(2.0, duration: 0.5, timingCurve: .easeOut)
                }
                .position(c)
            Circle().stroke(page.stop, lineWidth: 2)
                .keyframeAnimator(initialValue: 1.0, trigger: game.stops[k] ?? 0) { v, t in
                    // Unseen until the tick that stops it lands, so it goes out with the hub's last flip and its grey.
                    v.frame(width: size + (core - size) * t, height: size + (core - size) * t).opacity(t <= 0 || t >= 1 ? 0 : 0.9 * (1 - t * t))
                } keyframes: { _ in
                    MoveKeyframe(0.0)
                    LinearKeyframe(0.0, duration: delay + 0.15)
                    LinearKeyframe(1.0, duration: 0.7, timingCurve: .easeOut)
                }
                .position(c)
        }
        .allowsHitTesting(false)
    }

    /// Where a clock's count stands: right of its ratchet, or left of one on the tank's right, so it stays on screen;
    /// `r` is the tank's centre.
    private static func badgeSpot(_ c: CGPoint, size: CGFloat, r: CGFloat) -> CGPoint {
        CGPoint(x: c.x + (c.x > 1.2 * r ? -1 : 1) * (size / 2 + 30), y: c.y)
    }

    private func badge(_ text: String) -> some View {
        Text(text).font(.system(size: 20, weight: .bold, design: .serif)) // loc: verbatim localized by the caller, or a number
            .foregroundStyle(page.accent)
            .padding(.horizontal, 7).padding(.vertical, 1)
            .background(Capsule().fill(page.paper ? Color.bone.opacity(0.9) : .black.opacity(0.7)))
            .overlay(Capsule().stroke(page.accent, lineWidth: 1.5))
    }

    /// Escapement: "out of ticks." stamped by clock `k`, the one whose tick spent the last of the budget. A tank whose
    /// clocks all stopped with twists left has no count to stamp beside; what it shows instead is built three ways
    /// (`StopLook`).
    @ViewBuilder private func lostMarks(_ c: CGPoint, size: CGFloat, r: CGFloat, twisted: [(at: CGPoint, disc: CGFloat)])
        -> some View {
        let spot = Self.badgeSpot(c, size: size, r: r), out: CGFloat = spot.x < c.x ? -1 : 1
        let stopped = game.pushedClock == nil
        ZStack {
            if stopped && stopLook == .left {
                let left = game.stack.count
                Circle().stroke(page.accent, lineWidth: 1.5).frame(width: size + 8, height: size + 8).position(c)
                badge(String(localized: "\(left) left", comment: "Escapement's lost tank: twists left on the picture")).position(x: spot.x + 14 * out, y: spot.y - 14)
            }
            if stopped && stopLook == .rings {
                ForEach(twisted.indices, id: \.self) { i in
                    Circle().stroke(page.accent, lineWidth: 2).frame(width: 2 * twisted[i].disc, height: 2 * twisted[i].disc)
                        .position(twisted[i].at)
                }
            }
            LostStamp(size: 30).position(x: spot.x + 20 * out, y: spot.y + 34)
        }
        .allowsHitTesting(false)
    }

    /// Wide enough to read, too thin to hide the picture: 1.5 px on a 3x screen.
    static let hairline: CGFloat = 0.5
    /// How far inside the glass's edge the swirl's push flashes.
    private static let swirlFlash: CGFloat = 5
    /// A drag's count: its dashes, and the trace under them. No glow and no dark band: with them the count hid the picture.
    static let dash: CGFloat = 2, dashTone = 0.85, trace = hairline, traceTone = 0.4
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
                .stroke(page.live.opacity(0.6), lineWidth: Self.hairline)
            Path { $0.move(to: point(origin, radius)); $0.addLine(to: point(origin, radius - 10)) }
                .stroke(page.live.opacity(0.6), lineWidth: Self.hairline)
            Path { arc(&$0, origin, now) }.stroke(page.live.opacity(Self.traceTone), lineWidth: Self.trace)
            dashes.stroke(page.live.opacity(Self.dashTone), lineWidth: Self.dash)
        }
    }

    /// How far a lens's track stands off its knob's edge, and its dashes' spacing: a short track, not the finger's travel.
    nonisolated static let trackGap: CGFloat = 16, trackPitch: CGFloat = 16

    /// A lens's track stands on the side of its knob away from where the finger landed: right for a landing on the
    /// knob's centre or left of it. Any one unit, points or the tank's.
    nonisolated static func trackSide(landing x: Double, knob: Double) -> CGFloat { x > knob ? -1 : 1 }

    /// The steps a lens's track draws inside `bounds` (`PlayLayout.trackBounds`, in the glass's frame), from a knob at
    /// height `y`: down to the lower bound (out) and up to the upper (in), each step's place on the track inside. Nil
    /// without bounds, in the column, where nothing caps a lens.
    nonisolated static func trackRoom(knob y: CGFloat, bounds: CGRect?) -> ClosedRange<Int>? {
        guard let b = bounds else { return nil }
        let down = Int(((b.maxY - y) / trackPitch).rounded(.down)), up = Int(((y - b.minY) / trackPitch).rounded(.down))
        return -max(0, down)...max(0, up)
    }

    /// A lens's turn in hand, `angle`, held so that it and the open stir it joins, `joined` steps, stay in `room`, as
    /// the track counts both. A stir already past it can still turn back.
    nonisolated static func lensCapped(_ angle: Double, joined: Int, room: ClosedRange<Int>?) -> Double {
        guard let room else { return angle }
        let low = Double(min(0, room.lowerBound - joined)), high = Double(max(0, room.upperBound - joined))
        return min(max(angle, low * Tank.step), high * Tank.step)
    }

    /// The track's x, `side` of a knob at `knob`, in points.
    nonisolated static func trackX(knob: CGFloat, core: CGFloat, side: CGFloat) -> CGFloat { knob + side * (core / 2 + trackGap) }

    /// A lens's count, which follows the finger up and down (Jack, 2026-10-26): on a vertical hairline at `x` beside a
    /// disc of `radius` about `c`, the disc's own hairline round it, a long mark level with the knob where the stir
    /// began, a dash per step up for in and down for out, `pitch` apart, over a rail with a mark at `now`
    /// steps, where the drag stands.
    /// The rail, its dashes and its marks stop at `bounds`' top and foot (`PlayLayout.trackBounds`), where the drag
    /// runs long.
    private func track(_ c: CGPoint, _ radius: CGFloat, x: CGFloat, pitch: CGFloat, steps: Int, bounds: CGRect?, now: Double)
        -> some View {
        func held(_ y: CGFloat) -> CGFloat { bounds.map { min(max(y, $0.minY), $0.maxY) } ?? y }
        func y(_ s: Double) -> CGFloat { held(c.y - CGFloat(s) * pitch) }
        let reach = max(3.5, abs(now) + 0.5), dir = steps > 0 ? 1.0 : -1.0, gap = 3 / Double(pitch)
        let dashes = Path { p in
            for i in 0..<abs(steps) {
                let a = y(dir * (Double(i) + gap)), b = y(dir * (Double(i + 1) - gap))
                guard a != b else { continue }
                p.move(to: CGPoint(x: x, y: a))
                p.addLine(to: CGPoint(x: x, y: b))
            }
        }
        return ZStack {
            Path(ellipseIn: CGRect(x: c.x - radius, y: c.y - radius, width: 2 * radius, height: 2 * radius))
                .stroke(page.live.opacity(0.6), lineWidth: Self.hairline)
            Path { $0.move(to: CGPoint(x: x, y: y(-reach))); $0.addLine(to: CGPoint(x: x, y: y(reach))) }
                .stroke(page.live.opacity(Self.traceTone), lineWidth: Self.hairline)
            Path { $0.move(to: CGPoint(x: x - 6, y: y(0))); $0.addLine(to: CGPoint(x: x + 6, y: y(0))) }
                .stroke(page.live.opacity(0.6), lineWidth: Self.hairline)
            Path { $0.move(to: CGPoint(x: x - 3, y: y(now))); $0.addLine(to: CGPoint(x: x + 3, y: y(now))) }
                .stroke(page.live.opacity(Self.dashTone), lineWidth: Self.hairline)
            dashes.stroke(page.live.opacity(Self.dashTone), lineWidth: Self.dash)
        }
    }

    private func countLabel(_ steps: Int) -> some View {
        Text(verbatim: steps > 0 ? "+\(steps)" : "\u{2212}\(-steps)").font(.game(13, .semibold)).foregroundStyle(page.live)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(page.paper ? Color.bone.opacity(0.85) : .black.opacity(0.6)))
    }

    /// Room for a count round its centre: half its width at two digits.
    private static let countRoom: CGFloat = 18
    /// Half a count's height, its capsule round a line of 13 pt mono.
    private static let countHalfHeight: CGFloat = 11

    /// A count's centre `p` moved the least that keeps the count whole inside `bounds`.
    private static func inside(_ bounds: CGRect?, _ p: CGPoint) -> CGPoint {
        guard let b = bounds else { return p }
        return CGPoint(x: min(max(p.x, b.minX + countRoom), b.maxX - countRoom),
                       y: min(max(p.y, b.minY + countHalfHeight), b.maxY - countHalfHeight))
    }

    /// The circle a rod's count's dashes run on: 14 pt inside its disc.
    private func dashes(_ k: Int, _ r: CGFloat) -> CGFloat { min(rods[k].z * r, r - 4) - 14 }

    /// How far from a rod's centre its count sits: off a knob's disc, but inside the swirl's, whose rim is the glass's
    /// edge, clear of its dashes.
    private func countReach(_ k: Int, _ r: CGFloat) -> CGFloat {
        k == game.level.layout.swirl ? dashes(k, r) - 6 - Self.countRoom : rods[k].z * r + 22
    }

    /// Where a turn's count sits: `reach` out from `c` on the far side from the finger, but never below it, where the
    /// hand is, swung the least that keeps it as far from each point in `avoid` as that point asks; kept on the screen,
    /// and whole inside `bounds`, the tank's pane, where it has one.
    private func countSpot(_ c: CGPoint, reach: CGFloat, side: CGFloat, bounds: CGRect? = nil, avoid: [(CGPoint, CGFloat)] = [])
        -> CGPoint {
        let r = side / 2, edge = 0.045 * r
        var d = finger.map { CGVector(dx: c.x - ($0.x + 1) * r, dy: min(c.y - ($0.y + 1) * r, 0)) } ?? CGVector(dx: 0, dy: -1)
        if hypot(d.dx, d.dy) < 1 { d = CGVector(dx: c.x > r ? -1 : 1, dy: 0) }
        let a = atan2(d.dy, d.dx), swings: [CGFloat] = [0] + (1...6).flatMap { [CGFloat($0), -CGFloat($0)] }
        let spots = swings.map { a + $0 * .pi / 12 }.filter { sin($0) < 1e-6 }.map { b in
            Self.inside(bounds, CGPoint(x: min(max(c.x + cos(b) * reach, 4 - edge), side + edge - 4),
                                        y: min(max(c.y + sin(b) * reach, -edge - 20), side + edge + 20)))
        }
        func room(_ p: CGPoint) -> CGFloat { avoid.map { hypot(p.x - $0.0.x, p.y - $0.0.y) - $0.1 }.min() ?? 0 }
        return spots.first { room($0) >= 0 } ?? spots.max { room($0) < room($1) }!
    }

    /// `room`: for a lens's knob in a pane, the steps its track shows and those of the open stir its turn joins.
    private func twistGesture(_ r: CGFloat, room: @escaping (Int) -> (steps: ClosedRange<Int>, joined: Int)?) -> some Gesture {
        func norm(_ p: CGPoint) -> SIMD2<Double> { SIMD2(Double(p.x / r - 1), Double(p.y / r - 1)) }
        return DragGesture(minimumDistance: 0)
            .updating($holding) { _, holding, _ in holding = true }
            .onChanged { v in
                if touchStart != v.startLocation { touchStart = v.startLocation }
                // A touch from the screen's left edge is the back swipe's until it decides; one it passes is taken up
                // from where it landed, before it skips the opening.
                if drag?.start != v.startLocation {
                    edgeTouch = BackSwipe.edge(edgeTouch, start: v.startLocation, origin: tankOrigin, translation: v.translation)
                    if let edge = edgeTouch, edge.call != .pass { return }
                }
                guard !settling, !game.finished, !swipedAway, v.startLocation != deadTouch else { return }
                // A touch skips the opening as it lands, then takes up what it landed on; one that skips the clock's
                // demonstration holds nothing, as the problem has still to wind in.
                if demoing { skip(); deadTouch = v.startLocation; return }
                if shown != nil { skip() }
                let q = norm(v.location)
                let level = game.level
                // Keyed on the start point because a cancelled drag never reaches onEnded; a new touch starts afresh.
                if drag?.start != v.startLocation {
                    // A touch cut off without onEnded keeps the turn it showed; this one is taken up once that settles.
                    if let g = drag, cut(g) { return }
                    endPath()
                    drag = nil; liveRod = nil; liveAngle = 0; pressing = nil
                    // A twist cancelled without onEnded lets go as the lift would; this touch is taken up once that
                    // settles.
                    if spin == nil, spun { letGoSpin(lastSpin); if settling { return } }
                    if spin == nil { liveTurn = nil; endTwist() }
                    // Where it landed: the first change seen can come later, once a release or a reset's stir settles.
                    let landed = norm(v.startLocation)
                    self.landed = landed
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
                    // Travel past the track's end is dropped, so the finger turning back turns the lens back at once.
                    if lens, case .rod(let k) = g.grab, let fit = room(k) {
                        liveAngle = Self.lensCapped(liveAngle, joined: fit.joined, room: fit.steps)
                    }
                    ticks += detent.turn(to: liveAngle)
                } else if let turn = liveTurn {
                    liveTurn = turn + da
                    tankTicks += detent.turn(to: turn + da)
                }
            }
            .onEnded { v in
                if v.startLocation == deadTouch { deadTouch = nil; return }
                // An edge touch never taken up was the back swipe's, or a tap.
                if edgeTouch?.start == v.startLocation {
                    edgeTouch = nil
                    if drag?.start != v.startLocation { return }
                }
                if skip() { return }
                // The lift can carry movement no change reported.
                if let down = path?.down { path!.trail.add(norm(v.location), ms: Self.ms(v.time, since: down)) }
                endPath()
                guard let g = drag else { return }
                drag = nil
                switch g.grab {
                case .rod(let k): release(k)
                case .rim: if !spun { releaseTank() }
                case .ratchet(let k): tapped(k, from: norm(g.start), to: norm(v.location))
                case .seized, .nothing: break
                }
            }
    }

    /// The finger's travel up or down, in tank units, for one step of a lens (Jack, 2026-10-26).
    nonisolated static let lensPitch = 0.15

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
        if case .ratchet(let k)? = drag?.grab { pressing = k; grabs += 1 }
        guard let g = drag, let pivot = pivot(g.grab) else { return }
        let d = point - pivot
        drag!.last = lensHeld(g.grab) ? point.y : atan2(d.y, d.x)
        if case .rod(let k) = g.grab {
            liveRod = k; counted = k; grabs += 1; detent = Detent(step: Tank.step)
        } else {
            liveTurn = 0; counted = Game.tank; detent = Detent(step: game.level.layout.tankStep)
        }
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

    /// Escapement: a touch on the disc of the clock centred at `centre`, landing at `start` and lifting at `end`, waits.
    nonisolated static func waits(from start: SIMD2<Double>, to end: SIMD2<Double>, centre: SIMD2<Double>) -> Bool {
        simd_distance(start, end) < 0.06 && simd_distance(start, centre) < ratchetReach
    }

    /// A touch on clock `k`'s disc let go: a tap on the ratchet's plate waits, a tap elsewhere on the disc points the
    /// finger to the plate, and a drag is refused.
    private func tapped(_ k: Int, from start: SIMD2<Double>, to end: SIMD2<Double>) {
        pressing = nil
        if Self.waits(from: start, to: end, centre: centre(k)) {
            waitMove(on: k)
        } else if simd_distance(start, end) < 0.06 {
            missed = (k, simd_distance(start, centre(k))); misses += 1
        } else {
            jammed = k; jams += 1; Knock.thud.play()
        }
    }

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
                guard !settling, !game.finished, shown == nil, v.startLocation != deadSpin else { return }
                if v.startLocation != spinBase.start { spinBase = (v.startLocation, 0) }
                let rotation = v.rotation.radians - spinBase.rotation
                if !spun { endPath(); twist = (v.time, Trail(gap: 0.05) { abs($0 - $1) }) }
                spun = true
                lastSpin = rotation
                if let down = twist?.down { twist!.trail.add(rotation, ms: Self.ms(v.time, since: down)) }
                if liveTurn == nil {
                    // The rod a first finger held lets go as the lift would, so its turn never snaps back (V26).
                    if case .rod(let k)? = drag?.grab { release(k, now: true) }
                    drag?.grab = .rim; liveRod = nil; liveAngle = 0; liveTurn = 0; counted = Game.tank
                    Log.write("spin \(state)")
                    detent = Detent(step: game.level.layout.tankStep)
                }
                tankTicks += detent.turn(to: liveTurn! + rotation)
            }
            .onEnded { v in
                if v.startLocation == deadSpin { deadSpin = nil; return }
                guard spun else { return }
                let rotation = v.rotation.radians - spinBase.rotation
                if let down = twist?.down { twist!.trail.add(rotation, ms: Self.ms(v.time, since: down)) }
                // The end can carry rotation no change reported, and it commits.
                letGoSpin(rotation)
            }
    }

    private func letGoSpin(_ rotation: Double, now: Bool = false) {
        spun = false
        spinBase.rotation += rotation
        endTwist()
        guard shown == nil, let turn = liveTurn else { return }
        liveTurn = turn + rotation
        tankTicks += detent.turn(to: liveTurn!)
        releaseTank(now: now)
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

    /// `now` lands the let-go without the settle, whose completion waits on a frame.
    private func releaseTank(now: Bool = false) {
        guard !settling, let turn = liveTurn else { return }
        let step = game.level.layout.tankStep, steps = Detent.steps(turn, of: step)
        Log.write("release tank angle=\(turn) steps=\(steps)")
        counted = Game.tank
        func land() {
            liveTurn = nil
            settling = false
            game.turnTank(steps)
        }
        guard !now else { land(); return }
        settling = true
        withAnimation(.snappy(duration: 0.3)) {
            liveTurn = Double(steps) * step
        } completion: { land() }
    }

    /// A drag the system cut off, or a second finger took over, before the lift lets go as the lift would, so a turn
    /// shown whole never snaps back uncommitted (Jack, V26 on the phone, 2026-10-27). True when it has a turn to settle.
    @discardableResult private func cut(_ g: (start: CGPoint, grab: Grab, last: Double), now: Bool = false) -> Bool {
        Log.write("cut \(state)")
        endPath()
        drag = nil
        switch g.grab {
        case .rod(let k): release(k, now: now); return true
        case .rim where !spun && liveTurn != nil: releaseTank(now: now); return true
        case .ratchet: pressing = nil; return false
        default: return false
        }
    }

    /// The window changed pose under the fingers: the tank moved, so what they hold lets go as a lift would (V26), at
    /// once, and each holds nothing more until it lifts.
    private func letGoOnResize() {
        if spun {
            deadSpin = spinBase.start
            letGoSpin(lastSpin, now: true)
        }
        if let g = drag { cut(g, now: true) }
        // Not only a drag: an edge touch the back swipe hasn't decided, or one waiting on a settle, is taken up later
        // from where it landed, in the old frame.
        if holding, let t = touchStart { deadTouch = t }
    }

    /// The drag `Taps` measures on a glass `side` points across: a finger's or a drawn one's turn of a rod or the rim,
    /// once nothing else moves the glass: no opening, settle, card, slide or breath's fade.
    private func tapWindow(side: CGFloat) -> TapWindow? {
        guard phase == .active, struck, shown == nil, !demoing, !game.finished, !settling, swiped == 0, !breathing,
              liveRod != nil || liveTurn != nil, side > 0 else { return nil }
        let held = liveRod.map(game.slot(of:))
        return TapWindow(pixels: Double(side * scale),
                         work: Unstirred.committedWork(stack: bare ? [] : game.stack, masks: game.level.masks,
                                                       fill: game.level.picture.fillEntries, held: held),
                         held: held.map { "rod \($0)" } ?? "rim", picture: game.level.picture.rawValue)
    }

    /// UNSTIR_TAPDRAG=n: once the tank is the player's, n drags of the first working knob through the finger's own
    /// state, each let go a step from where it began, alternately each way, through the real release, so each lands a
    /// move.
    private func tapDrag(_ drags: Int) async {
        while shown != nil || !struck {
            guard (try? await Task.sleep(for: .seconds(0.2))) != nil else { return }
        }
        guard let k = knobs.first(where: { game.level.kind(of: $0) == .working }) else { return }
        for i in 0..<drags {
            guard (try? await Task.sleep(for: .seconds(1.5))) != nil, !game.finished else { return }
            let end = (i % 2 == 0 ? 1.0 : -1.0) * Tank.step
            liveRod = k
            counted = k
            await TapDrive.run(seconds: 4) { t in liveAngle = end * t / 4 + 0.6 * Tank.step * sin(2 * .pi * t) }
            liveAngle = end
            release(k)
        }
        try? await Task.sleep(for: .seconds(1.5))
        Log.write("tapdrag done")
    }

    /// `now` lands the let-go without the settle, whose completion waits on a frame.
    private func release(_ k: Int, now: Bool = false) {
        let steps = Detent.steps(liveAngle, of: Tank.step)
        Log.write("release \(k) angle=\(liveAngle) steps=\(steps)")
        counted = k
        func land() {
            liveRod = nil
            liveAngle = 0
            settling = false
            guard steps != 0 else { return }
            game.commit(rod: k, steps: steps)
        }
        guard !now else { land(); return }
        settling = true
        withAnimation(.snappy(duration: 0.22)) {
            liveAngle = Double(steps) * Tank.step
        } completion: { land() }
    }
}

/// The reset control's two taps (Jack's call C12, round 13): with moves played, a first tap arms it and only a second
/// within `window` resets; with nothing played it resets at once, as that only replays the opening. `held`, under
/// VoiceOver, keeps the arm past the window, until a move or focus leaving the control disarms it.
enum ResetArm {
    static let window: TimeInterval = 2

    static func tap(now: Date, armedAt: Date?, played: Bool, held: Bool = false) -> (reset: Bool, armedAt: Date?) {
        guard played else { return (true, nil) }
        if let armedAt, held || now.timeIntervalSince(armedAt) < window { return (true, nil) }
        return (false, now)
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

/// A turn's clicks: one each time what letting go would commit changes, at every half step, either way. So a rod's
/// haptic and the tank's clunk land with the drag's count, and every step a turn commits has had one.
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

/// Keeps the screen from locking while any level on screen asks it to: the next level can appear before the last
/// has gone.
@MainActor enum Awake {
    private static var holders: Set<UUID> = []

    static func hold(_ id: UUID, _ on: Bool) {
        if on { holders.insert(id) } else { holders.remove(id) }
        UIApplication.shared.isIdleTimerDisabled = !holders.isEmpty
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

    /// Levels on screen that keep the engine warm: the next one can appear before the last has gone.
    private static var holders = 0

    /// Starts the engine ahead of the first knock, whose start would otherwise hitch the frame it lands on.
    static func warm(hold: Bool = true) {
        if hold { holders += 1 }
        guard Settings.haptics, !running, let engine else { return }
        running = (try? engine.start()) != nil
    }

    static func rest() {
        holders = max(holders - 1, 0)
        guard holders == 0, running, let engine else { return }
        engine.stop()
        running = false
    }

    func play() {
        guard Settings.haptics, let engine = Self.engine, let pattern = self == .clunk ? Self.clunkPattern : Self.thudPattern else { return }
        if !Self.running {
            guard (try? engine.start()) != nil else { return }
            Self.running = true
        }
        // A player per knock, since a reset voids the old ones.
        try? engine.makePlayer(with: pattern).start(atTime: CHHapticTimeImmediate)
    }
}

extension Channels {
    /// A knob's tint: the cover's red, green and blue, and each mix their brightest.
    var colour: Color { Color(.sRGB, red: tint.x, green: tint.y, blue: tint.z) }

    /// `colour`'s sRGB components, which a held swatch's channel is drawn in.
    var tint: SIMD3<Double> {
        let parts: [(Channels, SIMD3<Double>)] = [(.red, SIMD3(0xFF, 0x2A, 0x2A)), (.green, SIMD3(0x2A, 0xFF, 0x5A)),
                                                  (.blue, SIMD3(0x3A, 0x6B, 0xFF))]
        return parts.filter { contains($0.0) }.map(\.1).reduce(SIMD3<Double>(0, 0, 0)) { simd_max($0, $1) } / 255
    }
}

extension Level {
    /// A rod's tint on a level with channels, nil on any other.
    func tint(of slot: Int) -> Color? { masks.isEmpty ? nil : (masks[slot] ?? .white).colour }
    /// A rod's channels on a level with channels, nil on any other.
    func channels(of slot: Int) -> Channels? { masks.isEmpty ? nil : masks[slot] ?? .white }
}

extension Channels {
    /// The primaries held, in the swatches' letters: "R", "GB", "RGB".
    var letters: String { zip(Channels.each, ["R", "G", "B"]).filter { contains($0.0) }.map(\.1).joined() }
    /// What VoiceOver calls the primary's swatch, a whole phrase for each.
    var alone: String {
        self == .red ? String(localized: "show red alone", comment: "VoiceOver: Prism's red swatch")
            : self == .green ? String(localized: "show green alone", comment: "VoiceOver: Prism's green swatch")
            : String(localized: "show blue alone", comment: "VoiceOver: Prism's blue swatch")
    }
}

/// The settings' colour letters, stored as `letters`. Absent until the player chooses, so the letters follow
/// Differentiate Without Colour, today's and any later change of it, until then.
enum Letters {
    static var choice: Bool? {
        get {
            if let held = Settings.held.withLock({ $0 }) { return held["letters"] }
            return UserDefaults.standard.object(forKey: "letters") as? Bool
        }
        set {
            if !Settings.keep("letters", newValue) { UserDefaults.standard.set(newValue, forKey: "letters") }
        }
    }

    static func shown(system: Bool) -> Bool { choice ?? system }
}

extension EnvironmentValues {
    /// Prism's knobs spell out their channels: the settings' colour letters, or the harness's UNSTIR_LETTERS.
    @Entry var channelLetters = false
}

/// Prism's swatches, red, green and blue, shown with the colour letters: holding one draws that channel alone in its own
/// colour, the others hidden, so which lines a channel has stirred reads by shape alone; in white under Differentiate
/// Without Colour, where pure red or blue on black can read dark. VoiceOver toggles one instead of holding it.
struct ChannelSwatches: View {
    @Binding var isolated: Channels?

    var body: some View {
        HStack(spacing: 12) {
            ForEach(Channels.each, id: \.rawValue) { c in
                let held = isolated == c
                // Secondary buttons in their channel's colour, filled while held.
                Text(verbatim: c.letters).font(.ui(.button, .semibold))
                    .modifier(ButtonFace(emphasis: .secondary, inset: 0, minWidth: ButtonFace.height, edge: c.colour,
                                         strokeWidth: 1.5, filled: held))
                    .onLongPressGesture(minimumDuration: 0, maximumDistance: 60, perform: {}) { pressing in
                        if pressing { isolated = c } else if isolated == c { isolated = nil }
                    }
                    .accessibilityElement()
                    .accessibilityLabel(c.alone) // loc: verbatim localized by Channels
                    .accessibilityValue(held ? Text("on", comment: "VoiceOver: a switch, on") // loc: verbatim each a key
                                        : Text("off", comment: "VoiceOver: a switch, off"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { isolated = held ? nil : c }
            }
        }
        .padding(.top, 4)
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
