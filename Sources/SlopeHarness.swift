// Copyright © 2026 Jack Lusher. All rights reserved.

#if DEBUG
import SwiftUI

/// UNSTIR_SLOPE: the slope alone, with stand-in pebbles and words where the screens will set their own, for shots and
/// films of the ground (scripts/shots/slope.sh). Debug builds only: no Release build reads the variable.
///
/// - `overview`: the whole slope, as the menu will open on it.
/// - `dive`: the slope scrolled by a finger from the surface to endless, opening on UNSTIR_SLOPEAT: a tier's level by
///   its id (`L14`), `top` or `endless`.
/// - `zoom`: the overview, then a second and a half in the camera dives to UNSTIR_SLOPEAT, and four seconds later
///   draws back.
/// - `descent`: the dive's camera carried from the surface to the bottom in UNSTIR_SLOPESECONDS (16).
/// - `play`: the ground as a level holds it at UNSTIR_SLOPEAT, the shelf drawn aside and the terrace up, two stones
///   on it.
///
/// UNSTIR_SLOPESOLVED=n lights the first n levels' pebbles (13 unset), UNSTIR_CLOCK holds the ground's clock.
struct SlopeHarness: View {
    enum Stage: String { case overview, dive, zoom, descent, play }

    let stage: Stage
    /// The ledge UNSTIR_SLOPEAT names; nil is the dive's top.
    let at: Int?
    let solved: Int
    let seconds: Double
    let clock: Double?

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var moved = false
    @State private var taps = 0

    init?(_ env: [String: String], clock: Double?) {
        guard let stage = env["UNSTIR_SLOPE"].flatMap(Stage.init(rawValue:)) else { return nil }
        self.stage = stage
        self.clock = clock
        solved = env["UNSTIR_SLOPESOLVED"].flatMap(Int.init) ?? 13
        seconds = env["UNSTIR_SLOPESECONDS"].flatMap(Double.init) ?? 16
        at = switch env["UNSTIR_SLOPEAT"] {
        case "endless": Slope.count + 4
        case let id?: Tier.allCases.flatMap(\.levels).first { $0.id == id }.flatMap(Slope.ledge(of:))
        case nil: nil
        }
    }

    var body: some View {
        let slope = Slope(typeSize)
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            let target = at.map { SlopeCamera(y: min(slope.y($0), slope.bottom(in: size).y)) } ?? slope.top(in: size)
            switch stage {
            case .dive:
                SlopeDive(slope: slope, start: at.map { min($0, Slope.brink) }, clock: clock) { frame in
                    SlopeStandIns(frame: frame, solved: solved, cull: false, taps: $taps)
                }
            case .overview:
                SlopeScene(slope: slope, camera: slope.overview(in: size), clock: clock) { frame in
                    SlopeStandIns(frame: frame, solved: solved, cull: true, taps: $taps)
                }
            case .zoom:
                SlopeScene(slope: slope, camera: moved ? target : slope.overview(in: size), clock: clock) { frame in
                    SlopeStandIns(frame: frame, solved: solved, cull: true, taps: $taps)
                }
                .task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.easeInOut(duration: 1.6)) { moved = true }
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeInOut(duration: 1.6)) { moved = false }
                }
            case .descent:
                SlopeScene(slope: slope, camera: moved ? slope.bottom(in: size) : slope.top(in: size), clock: clock) { frame in
                    SlopeStandIns(frame: frame, solved: solved, cull: true, taps: $taps)
                }
                .task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.timingCurve(0.3, 0, 0.7, 1, duration: seconds)) { moved = true }
                }
            case .play:
                SlopeScene(slope: slope, camera: target, held: true, play: SlopePlay(level: 1), clock: clock) { _ in
                    let b = SlopeStone.target / 2
                    ZStack(alignment: .topLeading) {
                        SlopeStone(Text(verbatim: "undo · 10"), kind: .dull) { taps += 1 } // loc: verbatim a stand-in
                            .slopePlace(CGPoint(x: 42, y: Slope.terrace(52, height: size.height) - b + 8), anchor: .leading)
                        SlopeStone(Text(verbatim: "reset"), trailing: true) { taps += 1 } // loc: verbatim a stand-in
                            .slopePlace(CGPoint(x: size.width - 42, y: Slope.terrace(size.width - 52, height: size.height) - b + 8), anchor: .trailing)
                    }
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
                }
            }
        }
        .ignoresSafeArea()
        .background(Color.black)
    }
}

/// Stand-ins for what the screens will set on the slope: a pebble on every level's seat, its number, name and facts
/// beside it, each tier's name, hollows, the stone on the bank and endless. Drawn from one frame, the overview's words
/// as the flights stand out and the dive's as they straighten.
private struct SlopeStandIns: View {
    let frame: Slope.Frame
    let solved: Int
    /// Leaves out what is off the screen: the scene lays everything out again each frame, the dive once.
    let cull: Bool
    @Binding var taps: Int

    private var slope: Slope { frame.slope }
    /// 0 in the overview, 1 in the dive.
    private var near: Double { 1 - min(frame.stairs / 0.3, 1) }
    private var wide: Double { max((frame.stairs - 0.7) / 0.3, 0) }

    private func shown(_ y: CGFloat) -> Bool { !cull || y > -80 && y < frame.size.height + 80 }
    private func fathoms(_ k: Int) -> Double { slope.y(k) / slope.pitch }

    var body: some View {
        ZStack(alignment: .topLeading) {
            surface
            ForEach(Array(Tier.allCases.enumerated()), id: \.offset) { t, tier in
                heading(t, tier)
                ForEach(Array(tier.levels.prefix(Slope.levels).enumerated()), id: \.offset) { i, level in
                    row(level, number: t * Slope.levels + i + 1, ledge: Slope.ledge(tier: t, level: i + 1), tier: tier)
                }
            }
            if near > 0 { hollows.opacity(near) }
            let deep = frame.point(CGPoint(x: 0, y: slope.endless))
            if shown(deep.y) {
                VStack(spacing: 4) {
                    Text(verbatim: "endless").font(.slope(.word, .title)).foregroundStyle(Slope.ink(.text, fathoms: 160)) // loc: verbatim a stand-in
                    Text(verbatim: "best 9").font(.slope(.data, .detail)).foregroundStyle(Slope.ink(.text2, fathoms: 160)) // loc: verbatim a stand-in
                }
                .slopePlace(CGPoint(x: frame.size.width * 0.57, y: deep.y))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// The wordmark over the water, the stone on the bank, and the daily's and the archive's pebbles in the shallows.
    @ViewBuilder private var surface: some View {
        let bank = frame.bank
        if shown(bank.y) {
            Text(verbatim: "UNSTIR").font(.slope(.name, .display)).tracking(9).foregroundStyle(Color.text) // loc: verbatim the wordmark
                .slopePlace(CGPoint(x: 32, y: bank.y - 34), anchor: .bottomLeading)
            SlopeStone(Text(verbatim: "settings").font(.slope(.plain, .detail))) { taps += 1 } // loc: verbatim a stand-in
                .slopePlace(CGPoint(x: bank.x - 10, y: bank.y), anchor: UnitPoint(x: 0, y: 0.62))
        }
        ForEach([Slope.daily, Slope.archive], id: \.self) { k in
            let seat = frame.point(frame.seat(k)), daily = k == Slope.daily
            if shown(seat.y) {
                SlopePebble(kind: daily ? .next : .dull, width: frame.length(daily ? 22 : 15, least: daily ? 9 : 6)).seated(at: seat)
                Text(verbatim: daily ? "today" : "archive").font(.slope(daily ? .word : .plain, daily ? .title : .body)) // loc: verbatim a stand-in
                    .foregroundStyle(Slope.ink(daily ? .text : .text2, fathoms: fathoms(k)))
                    .slopeLine(CGPoint(x: wide > 0 ? 180 : frame.point(frame.lip(k)).x + 18, y: seat.y))
                    .opacity(max(wide, near))
            }
        }
    }

    @ViewBuilder private func heading(_ t: Int, _ tier: Tier) -> some View {
        let y = frame.point(CGPoint(x: 0, y: slope.heading(tier: t))).y
        if shown(y) {
            let x = wide > 0 ? 180 : frame.point(CGPoint(x: slope.lip > 100 ? 44 : 34, y: 0)).x
            let depth = Double(slope.heading(tier: t) / slope.pitch)
            VStack(alignment: .leading, spacing: 3) {
                Text(tier.word).font(.slope(.word, .title)).foregroundStyle(Slope.ink(.text, fathoms: depth))
                Text(verbatim: "\(min(max(solved - t * Slope.levels, 0), Slope.levels))/\(Slope.levels) at par") // loc: verbatim a stand-in
                    .font(.slope(.data, .detail)).foregroundStyle(Slope.ink(.text2, fathoms: depth))
            }
            .slopeLine(CGPoint(x: x, y: y + (wide > 0 ? 34 : 0)))
            .opacity(max(wide, near))
        }
    }

    @ViewBuilder private func row(_ level: Level, number: Int, ledge k: Int, tier: Tier) -> some View {
        let seat = frame.point(frame.seat(k))
        if shown(seat.y) {
            let kind: SlopePebble.Kind = number <= solved ? .lit : number == solved + 1 ? .next : .dull
            let width = frame.length(kind == .lit ? 16.8 : kind == .next ? 25 : 13.6, least: kind == .lit ? 5.4 : kind == .next ? 7.4 : 4.6)
            SlopePebble(kind: kind, width: width * (slope.lip > 100 ? 1 : 1.25), lean: SlopePebble.lean(number), glow: tier.light)
                .seated(at: seat)
            if near > 0 {
                let x = frame.point(frame.lip(k)).x + (slope.lip > 100 ? 18 : 14), next = kind == .next, done = kind == .lit
                let depth = fathoms(k)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                        Text(level.label).font(.slope(.data, next ? .body : .label)).foregroundStyle(Slope.ink(done || next ? .text2 : .text3, fathoms: depth))
                        Text(level.title).font(next ? .slope(.name, .title) : .slope(.plain, .body))
                            .foregroundStyle(Slope.ink(done || next ? .text : .text2, fathoms: depth))
                    }
                    Text(verbatim: "\(level.layout.rods.count) rods · par \(level.fixedPar ?? level.scramble.count)") // loc: verbatim a stand-in
                        .font(.slope(.data, next ? .label : .detail)).foregroundStyle(Slope.ink(done || next ? .text2 : .text3, fathoms: depth))
                }
                .frame(maxWidth: max(frame.size.width - x - 10, 60), alignment: .leading)
                .slopeLine(CGPoint(x: x, y: seat.y - width * 0.3))
                .opacity(near)
            }
        }
    }

    /// The packs' hollows, dark mouths in plughole's rock with a light inside.
    @ViewBuilder private var hollows: some View {
        ForEach(Array(zip(Pack.allCases, [2, 6, 11, 16])), id: \.0) { pack, after in
            if let hollow = slope.hollow(tier: 0, after: after) {
                let centre = frame.point(hollow.centre)
                if shown(centre.y) {
                    let depth = Double(hollow.centre.y / slope.pitch)
                    VStack(spacing: 8) {
                        Circle().fill(Color(0x03060A).opacity(0.92))
                            .overlay(Circle().fill(RadialGradient(colors: [Tier.plughole.light.opacity(0.5), .clear], center: .center,
                                                                  startRadius: 0, endRadius: hollow.diameter * 0.45)))
                            .frame(width: hollow.diameter + 10, height: hollow.diameter + 10)
                        Text(verbatim: pack.name).font(.slope(.plain, .detail)).foregroundStyle(Slope.ink(.text2, on: .rock, fathoms: depth))
                    }
                    .slopePlace(CGPoint(x: centre.x, y: centre.y - hollow.diameter / 2 - 5), anchor: .top)
                }
            }
        }
    }
}

private extension View {
    /// Sets words in a top-leading `ZStack`, their leading edge and their first line's middle at `point`.
    func slopeLine(_ point: CGPoint) -> some View {
        alignmentGuide(.leading) { _ in -point.x }
            .alignmentGuide(.top) { $0[.firstTextBaseline] * 0.62 - point.y }
    }
}
#endif
