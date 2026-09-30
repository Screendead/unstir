// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Gameplay mockups, reached by holding the menu's title. A lab level stores nothing: no best, start, undo bank, refill
/// day or tank flag.
enum Lab: Hashable, Sendable {
    /// Dragging the rim turns the whole tank as one rod, a stir like any other.
    case swirl
    /// The tank is dark but for this many lights the player drops on it, which float on the fluid.
    case glow(Int)
    /// This rod's rigid core is iced: it keeps showing the tank as it opened.
    case frozen(Int)
    /// Five minutes to solve as many tanks as possible, dealt one after another.
    case rush(Rush)
}

struct Rush: Hashable, Sendable {
    /// 0 easy, 1 medium, 2 hard.
    var difficulty: Int
    var deadline: Date
    var solved = 0

    static let names = ["easy", "medium", "hard"]
    static let length: TimeInterval = 5 * 60

    /// Most tanks solved in one rush at this difficulty, on this phone.
    static func best(_ difficulty: Int) -> Int { UserDefaults.standard.integer(forKey: "lab.rush.best.\(difficulty)") }
    static func record(_ difficulty: Int, _ solved: Int) {
        if solved > best(difficulty) { UserDefaults.standard.set(solved, forKey: "lab.rush.best.\(difficulty)") }
    }

    /// A tank from endless's generator: easy deals tanks 0-3 (5-8 stirs), medium 6-9 (12-16), hard 12-15 (20-23).
    var level: Level {
        let tank = [0, 6, 12][difficulty] + Int.random(in: 0...3)
        var level = Level.endless(Run(seed: .random(in: .min ... .max), tank: tank))
        level.run = nil
        level.id = "lab-rush"
        level.label = "r\(solved + 1)"
        level.title = "Rush, \(Rush.names[difficulty])"
        level.note = "No undo. Solve, and the next tank comes."
        level.lab = .rush(self)
        return level
    }

    /// The next tank, one more solved, same clock.
    var next: Level { Rush(difficulty: difficulty, deadline: deadline, solved: solved + 1).level }
    static func start(_ difficulty: Int) -> Level { Rush(difficulty: difficulty, deadline: .now + length).level }
}

/// Tanks solved and the time left, ticking.
struct RushClock: View {
    let rush: Rush

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { t in
            let left = max(Int(rush.deadline.timeIntervalSince(t.date).rounded(.up)), 0)
            Text("solved \(rush.solved) \u{00B7} \(left / 60):\(String(format: "%02d", left % 60))")
                .foregroundStyle(left <= 30 ? Color.alarm : Color.text)
        }
    }
}

/// The rush's end, over the tank.
struct RushOver: View {
    let rush: Rush
    let onExit: () -> Void
    let onNext: (Level) -> Void

    var body: some View {
        VStack(spacing: 18) {
            Text("time.").font(.mono(22, .semibold)).shadow(color: .white.opacity(0.5), radius: 6)
            Text("solved \(rush.solved) \u{00B7} best \(Rush.best(rush.difficulty))").font(.mono(15))
            HStack(spacing: 40) {
                Button("\u{2039} levels", action: onExit).foregroundStyle(Color.text)
                Button("again \u{203A}") { onNext(Rush.start(rush.difficulty)) }.foregroundStyle(Color.amber)
            }
            .font(.mono(15, .medium))
        }
        .padding(28)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.black.opacity(0.85)))
    }
}

/// One row of the lab's list: a new level each time it is picked, so a random one is dealt afresh.
struct LabEntry: Sendable {
    let name: String
    let detail: String
    /// Read afresh each time the list shows.
    var best: @Sendable () -> String? = { nil }
    let level: @Sendable () -> Level
}

extension Lab {
    static let entries: [LabEntry] = [
        LabEntry(name: "swirl", detail: "drag the rim: the whole tank is one more rod") {
            Level(id: "lab-swirl", label: "sw", title: "Swirl", note: "Drag the rim to swirl the whole tank.",
                  layout: .quadSwirl, scramble: .parse("0:+3,4:+2,2:-4,1:+3,4:-3,3:+5", in: .quadSwirl), lab: .swirl)
        },
        LabEntry(name: "swirl-random", detail: "swirl, 7 stirs dealt at random") {
            var rng = SplitMix64(state: .random(in: .min ... .max))
            return Level(id: "lab-swirl-random", label: "sw", title: "Swirl, dealt", note: "Drag the rim to swirl the whole tank.",
                         layout: .quadSwirl, scramble: Layout.quadSwirl.scramble(depth: 7, inversions: 1, rng: &rng), lab: .swirl)
        },
        LabEntry(name: "glow", detail: "lights off: drop 3 lights that float on the stir") {
            Level(id: "lab-glow", label: "gl", title: "Lights off", note: "Tap light, then the tank, to drop one. They ride the stirs.",
                  layout: .quad, scramble: .parse("0:+4,2:-4,3:-5,1:-4,2:+6", in: .quad), lab: .glow(3))
        },
        LabEntry(name: "frozen", detail: "one rod's core is iced: it shows the tank as it opened") {
            Level(id: "lab-frozen", label: "fr", title: "Frozen rod", note: "The top rod's core is iced. Read it from the rest.",
                  layout: .tri, scramble: .parse("2:+2,0:-4,1:+5,2:-6", in: .tri), lab: .frozen(0))
        },
    ] + (0..<3).map { d in
        LabEntry(name: "rush-\(Rush.names[d])", detail: "5 minutes, as many \(Rush.names[d]) tanks as you can, no undo",
                 best: { "best \(Rush.best(d))" }) { Rush.start(d) }
    }

    /// UNSTIR_LAB=name: the entry of that name, for the harness.
    static func level(named name: String) -> Level? {
        entries.first { $0.name == name }?.level()
    }
}

extension Layout {
    /// Where the fluid at `p` on the clean picture sits once `word` has stirred it, bottom first, the last one
    /// (`live`) turned by a fractional angle.
    func forward(_ p: SIMD2<Double>, through word: [Twist], scale: Double = 1, live: (rod: Int, angle: Double)? = nil)
        -> SIMD2<Double> {
        let q = word.reduce(p) { Tank.twist($0, rod: rods[$1.rod], angle: Double($1.steps) * Tank.step * scale) }
        return live.map { Tank.twist(q, rod: rods[$0.rod], angle: $0.angle) } ?? q
    }

    /// The point of the clean picture that `word` has stirred to `p`.
    func back(_ p: SIMD2<Double>, through word: [Twist]) -> SIMD2<Double> {
        word.reversed().reduce(p) { Tank.twist($0, rod: rods[$1.rod], angle: -Double($1.steps) * Tank.step) }
    }
}

/// Black over the tank but for a soft pool of light round each point.
struct Darkness: View {
    let points: [CGPoint]
    let radius: CGFloat

    var body: some View {
        ZStack {
            Color.black
            ForEach(points.indices, id: \.self) { i in
                Circle()
                    .fill(RadialGradient(stops: [.init(color: .white, location: 0), .init(color: .white.opacity(0.85), location: 0.35),
                                                 .init(color: .white.opacity(0.3), location: 0.7), .init(color: .clear, location: 1)],
                                         center: .center, startRadius: 0, endRadius: radius))
                    .frame(width: 2 * radius, height: 2 * radius)
                    .position(points[i])
                    .blendMode(.destinationOut)
            }
        }
        .compositingGroup()
        .overlay {
            ForEach(points.indices, id: \.self) { i in
                Circle().fill(Color.lime).frame(width: 5, height: 5).shadow(color: .lime, radius: 4).position(points[i])
            }
        }
    }
}

/// A frozen core's edge: a pale rim with a faint frost creeping in from it.
struct Frost: View {
    let radius: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [.clear, Color(0xCFEFFF).opacity(0.22)], center: .center,
                                         startRadius: 0.7 * radius, endRadius: radius))
            Circle().stroke(Color(0xCFEFFF).opacity(0.6), style: StrokeStyle(lineWidth: 0.75, dash: [5, 2, 1, 2]))
        }
        .frame(width: 2 * radius, height: 2 * radius)
    }
}

struct LabList: View {
    let pick: (Level) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("LAB").font(.system(size: 28, weight: .black).width(.expanded)).tracking(6)
                    .foregroundStyle(Color.amber).shadow(color: .amber.opacity(0.6), radius: 10)
                Text("Mockups. Nothing here is saved.").font(.mono(12)).opacity(0.55).padding(.top, 8)
                ForEach(Lab.entries.indices, id: \.self) { i in
                    let e = Lab.entries[i]
                    Button { pick(e.level()) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.name).font(.mono(15, .medium))
                            Text(e.detail + (e.best().map { " \u{00B7} \($0)" } ?? "")).font(.mono(11)).opacity(0.45)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 10)
            }
            .padding(20)
        }
        .foregroundStyle(Color.text)
        .background(Color.black)
    }
}
