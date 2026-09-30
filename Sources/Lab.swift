// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Gameplay mockups, reached by holding the menu's title. A lab level stores nothing: no best, start, undo bank, refill
/// day or tank flag.
enum Lab: Hashable, Sendable {
    /// Dragging the rim turns the whole tank as one rod, a stir like any other.
    case swirl
    /// The tank is dark but for this many lights the player drops on it, which float on the fluid.
    case glow(Int)
}

/// One row of the lab's list: a new level each time it is picked, so a random one is dealt afresh.
struct LabEntry: Sendable {
    let name: String
    let detail: String
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
    ]

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
                            Text(e.detail).font(.mono(11)).opacity(0.45).multilineTextAlignment(.leading)
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
