// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// L1's lesson: a ghost finger, as the rim's, rocking round knob 0 halfway out its disc, the turn the level asks for.
struct KnobLesson: View {
    /// The knob's centre and the finger's distance from it, in points.
    let centre: CGPoint
    let reach: CGFloat
    /// Holds the finger this many seconds in.
    let clock: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Seconds of the tank untouched before it shows.
    static let wait = 4.0
    private static let sweep = 40 * Double.pi / 180, period = 2.4, rest = Double.pi / 4

    /// Where the finger is `t` seconds in: rocking either side of up and to the right of the knob.
    static func finger(centre: CGPoint, reach: CGFloat, at t: Double) -> CGPoint {
        let a = rest + sweep * sin(2 * .pi * t / period)
        return CGPoint(x: centre.x + reach * sin(a), y: centre.y - reach * cos(a))
    }

    var body: some View {
        // Reduce Motion holds it at 0 s, mid-sweep.
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: clock != nil || reduceMotion)) { timeline in
            GhostFinger().position(Self.finger(centre: centre, reach: reach,
                                               at: clock ?? (reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate)))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Lens 01's lesson: a ghost finger on the lens's knob riding down beside its track, as far as a drag that undoes the
/// level's zoom, over the track's rail drawn faintly where that drag draws its count.
struct LensLesson: View {
    /// The knob's centre, its core's width and the finger's travel for one of the lens's steps, in points.
    let knob: CGPoint
    let core: CGFloat
    let step: CGFloat
    /// When this showing began, so it rides from the top.
    let since: Date
    /// Holds the finger this many seconds in.
    let clock: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Lens 01 deals `0:+2`.
    nonisolated static let steps = 2.0
    private nonisolated static let period = 2.2, ride = 1.6, fade = 0.4
    /// Halfway down: where Reduce Motion holds it.
    nonisolated static let middle = ride / 2

    /// Until the level is solved, and in each game while no lens's stir is in `history` (slots, as `lenses` holds):
    /// an undo that takes the stir back brings it back.
    nonisolated static func shows(level: Level, history: [Twist], best: Best?) -> Bool {
        level.id == Pack.lens.levels.first?.id && best == nil && !history.contains { level.lenses.contains($0.rod) }
    }

    /// The finger's x: the knob's left edge, so a finger landing where it shows draws its track on the rail.
    nonisolated static func landing(knob: CGPoint, core: CGFloat) -> CGFloat { knob.x - core / 2 }

    /// The rail's x: the track a drag landing at the finger draws.
    nonisolated static func rail(knob: CGPoint, core: CGFloat) -> CGFloat {
        LevelView.trackX(knob: knob.x, core: core, side: LevelView.trackSide(landing: landing(knob: knob, core: core), knob: knob.x))
    }

    /// Where the finger is `t` seconds into a showing, and how strongly it shows: eased down from the knob's height,
    /// faded out at its foot and faded in again at the top.
    nonisolated static func finger(knob: CGPoint, core: CGFloat, step: CGFloat, at t: Double) -> (at: CGPoint, opacity: Double) {
        let t = t.truncatingRemainder(dividingBy: period) + (t < 0 ? period : 0)
        let u = min(t / ride, 1), down = u * u * (3 - 2 * u)
        let opacity = t < ride ? 1 : t < ride + fade ? 1 - (t - ride) / fade : max(0, t - ride - fade) / (period - ride - fade)
        return (CGPoint(x: landing(knob: knob, core: core), y: knob.y + CGFloat(t < ride + fade ? down * steps : 0) * step), opacity)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: clock != nil || reduceMotion)) { timeline in
            let f = Self.finger(knob: knob, core: core, step: step,
                                at: clock ?? (reduceMotion ? Self.middle : timeline.date.timeIntervalSince(since)))
            let x = Self.rail(knob: knob, core: core), pitch = LevelView.trackPitch
            ZStack {
                Path { $0.move(to: CGPoint(x: x, y: knob.y - 3.5 * pitch)); $0.addLine(to: CGPoint(x: x, y: knob.y + 3.5 * pitch)) }
                    .stroke(Color.live.opacity(LevelView.traceTone / 2), lineWidth: LevelView.hairline)
                GhostFinger().position(f.at).opacity(f.opacity)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Every lesson's fingertip.
struct GhostFinger: View {
    var body: some View {
        Circle().fill(Color.live.opacity(0.22))
            .overlay(Circle().stroke(Color.live.opacity(0.6), lineWidth: 1.5))
            .shadow(color: .live.opacity(0.4), radius: 6)
            .frame(width: 30, height: 30)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// The ghost finger's path, as a fraction of the glass's radius.
    var reach = 1.0225
    private static let span = 34 * Double.pi / 180, sweep = 26 * Double.pi / 180, period = 3.6
    /// The arc's stroke at the height of its pulse. Nothing of it, arrowheads included, lies further than this from its line.
    static let width: CGFloat = 14
    /// How far the tank's lesson reaches over the rim at twelve: its arc's line 10 pt out, half its stroke, and the
    /// ghost finger's glow, which rides just inside the line.
    static let overRim: CGFloat = 10 + width / 2 + 3
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
                // Under Reduce Motion it rests mid-sweep, where the arc's arrows show the way.
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: clock != nil || reduceMotion)) { timeline in
                    let a = Self.notch(kind) + Self.sweep * sin(2 * .pi * (clock ?? (reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate)) / Self.period)
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
