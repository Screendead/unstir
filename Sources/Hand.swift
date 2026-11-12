// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The turn in hand, which changes on every frame of a drag: kept outside `LevelView`'s own state, so such a frame
/// re-evaluates only the parts that read it in a body of their own (`InHand`: the glass's shader arguments, the held
/// knob, its dial and its count), never `LevelView`. `LevelView.body` reads only what changes with a count: `steps`,
/// `turnSteps`, `turning` and `spun`. A value set to what it already is tells no one, as a view's own state does.
@MainActor @Observable final class Hand {
    @ObservationIgnored private var stored = (angle: 0.0, turn: 0.0, turning: false, spin: 0.0, spun: false, steps: 0, turnSteps: Int?.none)
    @ObservationIgnored private let tankStep: Double

    /// A rod's turn in hand, in radians.
    var angle: Double {
        get { access(keyPath: \.angle); return stored.angle }
        set {
            guard newValue != stored.angle else { return }
            withMutation(keyPath: \.angle) { stored.angle = newValue }
            count()
        }
    }

    /// The tank's turn in hand, in radians clockwise, while `turning`: a finger holds the rim.
    var turn: Double {
        get { access(keyPath: \.turn); return stored.turn }
        set {
            guard newValue != stored.turn else { return }
            withMutation(keyPath: \.turn) { stored.turn = newValue }
            count()
        }
    }

    var turning: Bool {
        get { access(keyPath: \.turning); return stored.turning }
        set {
            guard newValue != stored.turning else { return }
            withMutation(keyPath: \.turning) { stored.turning = newValue }
            count()
        }
    }

    /// Two fingers' twist as last reported, on top of `turn` while `spun`: the twist has the tank.
    var spin: Double {
        get { access(keyPath: \.spin); return stored.spin }
        set {
            guard newValue != stored.spin else { return }
            withMutation(keyPath: \.spin) { stored.spin = newValue }
            count()
        }
    }

    var spun: Bool {
        get { access(keyPath: \.spun); return stored.spun }
        set {
            guard newValue != stored.spun else { return }
            withMutation(keyPath: \.spun) { stored.spun = newValue }
            count()
        }
    }

    /// The finger's latest point in tank units, kept after it lifts so a count left showing stays put.
    var finger: SIMD2<Double>?

    /// The steps letting go of `angle` would commit, and of `held` in the tank's steps: told only as a count changes.
    var steps: Int { access(keyPath: \.steps); return stored.steps }
    var turnSteps: Int? { access(keyPath: \.turnSteps); return stored.turnSteps }

    /// The tank's turn in hand, a twist's on top; nil when it is not held.
    var held: Double? { turning ? turn + (spun ? spin : 0) : nil }

    /// What `TapHooks` watches for a frame the turn moved.
    var motion: [Double] { [angle, turning ? turn : 0, spin] }

    /// The finger's last angle about what it holds, the clicks counted, and the drag's and the twist's paths for the
    /// log: written on every frame of a drag and drawn by nothing.
    @ObservationIgnored var last = 0.0
    @ObservationIgnored var detent = Detent(step: Tank.step)
    @ObservationIgnored var path: (grab: Grab, down: Date, trail: Trail<SIMD2<Double>>)?
    @ObservationIgnored var twist: (down: Date, trail: Trail<Double>)?

    /// UNSTIR_BROADDRAG=1: `LevelView.body` reads the turn itself, so every frame of a drag re-evaluates it as when the
    /// turn was its own state, for `scripts/drag-probe.sh` to time the two in one build. `alt`: UNSTIR_TAPDRAG's drags
    /// take it in turn after the first, which only warms up: as built, broad, broad, as built, so both are timed in
    /// one launch, each turning each way. A probe's switch: a plain Release build has neither (`DragProbe`).
    #if PROBES || DEBUG
    static var broad = ProcessInfo.processInfo.environment["UNSTIR_BROADDRAG"] == "1"
    static let alternates = ProcessInfo.processInfo.environment["UNSTIR_BROADDRAG"] == "alt"
    #else
    static let broad = false, alternates = false
    #endif

    init(tankStep: Double, angle: Double = 0, turn: Double? = nil, finger: SIMD2<Double>? = nil) {
        self.tankStep = tankStep
        self.finger = finger
        stored.angle = angle
        stored.turn = turn ?? 0
        stored.turning = turn != nil
        count()
    }

    private func count() {
        let steps = Detent.steps(stored.angle, of: Tank.step)
        let turnSteps = stored.turning ? Detent.steps(stored.turn + (stored.spun ? stored.spin : 0), of: tankStep) : nil
        if steps != stored.steps { withMutation(keyPath: \.steps) { stored.steps = steps } }
        if turnSteps != stored.turnSteps { withMutation(keyPath: \.turnSteps) { stored.turnSteps = turnSteps } }
    }

    /// Every drawn part of the turn read at once (`broad`).
    func readAll() { _ = (angle, turn, turning, spin, spun, finger) }
}

/// A part of the play screen that follows the turn in hand. It reads `hand` in its own body, so a frame of a drag
/// re-evaluates this part alone.
struct InHand<Content: View>: View {
    let hand: Hand
    @ViewBuilder let content: (Hand) -> Content

    var body: some View {
        let _ = DragProbe.count(.leaf)
        content(hand)
    }
}
