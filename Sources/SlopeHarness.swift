// Copyright © 2026 Jack Lusher. All rights reserved.

#if DEBUG
import SwiftUI

/// UNSTIR_SLOPE: the slope's foundation alone, with stand-in pebbles and words where the screens will set their own,
/// for shots and films of the ground (scripts/shots/slope.sh). Debug builds only: no Release build reads the variable.
///
/// - `overview`: the whole main column.
/// - `dive`: the main column scrolled by a finger from the surface to endless, opening on UNSTIR_SLOPEAT: a tier's
///   level by its id (`L14`), or `endless`; the surface when unset.
/// - `zoom`: the overview, then a second and a half in the depth opens onto UNSTIR_SLOPEAT, the scrolling dive takes
///   over where the zoom lands, and four seconds later the depth closes again.
/// - `descent`: the dive scrolled from the surface to the foot in UNSTIR_SLOPESECONDS (16), as a finger would.
/// - `play`: the ground as a level holds it at UNSTIR_SLOPEAT, the shelf drawn aside and the lone terrace up, two
///   stones on it. UNSTIR_SLOPELOOK=paper is Escapement's page, =clear Prism's water, =dim the ground at 0.35 of
///   its light.
/// - `hollow`: the inside of a hollow, lit as Prism's.
/// - `pack`: a pack's own column, five trays of six in pale rock, scrolled.
/// - `stones`: every state of the stone, on open water.
///
/// UNSTIR_SLOPESOLVED=n lights the first n levels' pebbles (13 unset), UNSTIR_CLOCK holds the ground's clock.
struct SlopeHarness: View {
    enum Stage: String { case overview, dive, zoom, descent, play, hollow, pack, stones }

    let stage: Stage
    /// The ledge UNSTIR_SLOPEAT names; nil is the dive's top.
    let at: Int?
    let endless: Bool
    let solved: Int
    let seconds: Double
    let look: String?
    let clock: Double?

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.displayScale) private var scale
    @State private var moved = false
    @State private var landed = false
    @State private var taps = 0

    init?(_ env: [String: String], clock: Double?) {
        guard let stage = env["UNSTIR_SLOPE"].flatMap(Stage.init(rawValue:)) else { return nil }
        self.stage = stage
        self.clock = clock
        solved = env["UNSTIR_SLOPESOLVED"].flatMap(Int.init) ?? 13
        seconds = env["UNSTIR_SLOPESECONDS"].flatMap(Double.init) ?? 16
        look = env["UNSTIR_SLOPELOOK"]
        endless = env["UNSTIR_SLOPEAT"] == "endless"
        at = env["UNSTIR_SLOPEAT"].flatMap { id in Tier.allCases.flatMap(\.levels).first { $0.id == id } }.flatMap(SlopeColumn.ledge(of:))
    }

    var body: some View {
        GeometryReader { geo in
            let size = CGSize(width: geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing,
                              height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom)
            let column = SlopeColumn.main(size: size, type: typeSize, header: TypeRole.body.line(at: typeSize).height * 3.4)
            let deep = SlopeLay(column, z: 1)
            let near = !typeSize.isAccessibilitySize
            // Where the dive holds its target: a level just over the screen's middle, the surface at the travel's top,
            // endless at its foot. A scene holds the same camera by a real ledge and the share that puts it there.
            let aim = at.map { SlopeAim(ledge: $0) } ?? SlopeAim(ledge: endless ? deep.count : 0, share: endless ? 0.5 : 1)
            let focus = min(aim.ledge, deep.count - 1)
            let share = (deep.tops[focus] - deep.rest(aim, height: size.height)) / size.height
            let wide = SlopeScene<EmptyView>.overview(column, holding: focus, height: size.height)
            switch stage {
            case .dive:
                SlopeDive(column: column, aim: aim, clock: clock, near: near) { view in
                    SlopeStandIns(view: view, solved: solved, cull: false, taps: $taps)
                }
            case .overview:
                if typeSize.isAccessibilitySize {
                    // The words keep their size: each stretch grows to hold its own, and the overview scrolls.
                    SlopeDive(column: grown(column, height: size.height), z: 0, clock: clock, near: false) { view in
                        SlopeStandIns(view: view, solved: solved, cull: false, taps: $taps)
                    }
                } else {
                    SlopeScene(column: column, focus: focus, at: wide, z: 0, clock: clock, near: near) { view in
                        SlopeStandIns(view: view, solved: solved, cull: true, taps: $taps)
                    }
                }
            case .zoom:
                // As a menu would: the scene carries the zoom, and the dive takes over where it comes to rest.
                ZStack {
                    if landed {
                        SlopeDive(column: column, aim: aim, clock: clock, near: near) { view in
                            SlopeStandIns(view: view, solved: solved, cull: false, taps: $taps)
                        }
                    } else {
                        SlopeScene(column: column, focus: focus, at: moved ? share : wide, z: moved ? 1 : 0, clock: clock, near: near) { view in
                            SlopeStandIns(view: view, solved: solved, cull: true, taps: $taps)
                        }
                    }
                }
                .task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation(.easeOut(duration: 1.1)) { moved = true }
                    try? await Task.sleep(for: .seconds(1.6))
                    landed = true
                    try? await Task.sleep(for: .seconds(2.4))
                    landed = false
                    try? await Task.sleep(for: .seconds(0.3))
                    withAnimation(.easeOut(duration: 1.1)) { moved = false }
                }
            case .descent:
                // The finger's own path, moved for it: the dive scrolls from the surface to the foot.
                SlopeDive(column: column, aim: moved ? SlopeAim(ledge: deep.count, share: 0.5) : SlopeAim(ledge: 0, share: 1),
                          seconds: seconds, clock: clock, near: near) { view in
                    SlopeStandIns(view: view, solved: solved, cull: false, taps: $taps)
                }
                .task {
                    try? await Task.sleep(for: .seconds(1.5))
                    moved = true
                }
            case .play:
                let paper = look == "paper"
                SlopeScene(column: column, focus: focus, at: share, z: 1, held: true,
                           look: SlopeLook(level: 1, clear: look == "clear" ? 1 : 0, light: look == "dim" ? 0.35 : 1, paper: paper ? 1 : 0,
                                           rock: deep.rocks[focus]),
                           clock: clock, near: false) { _ in
                    SlopeLayer {
                        Stone(Text(verbatim: "undo · 10"), state: .dull, engraved: paper) { taps += 1 } // loc: verbatim a stand-in
                            .rested(at: CGPoint(x: 52, y: SlopeLay.terrace(52, height: size.height)))
                        Stone(Text(verbatim: "reset"), pale: look == "clear", engraved: paper, trailing: true) { taps += 1 } // loc: verbatim a stand-in
                            .rested(at: CGPoint(x: size.width - 52, y: SlopeLay.terrace(size.width - 52, height: size.height)))
                    }
                }
            case .hollow:
                SlopeHollowGround(beams: (SIMD3(1, 0.16, 0.16), SIMD3(0.16, 1, 0.3), SIMD3(0.2, 0.4, 1)))
            case .pack:
                let pack = SlopeColumn(stretches: (0 ..< 5).map { _ in .init(rock: .pale, terraces: [6], header: column.pitch) },
                                       foot: .floor, surface: false, pitch: column.pitch, lip: column.lip, step: column.step, first: nil)
                SlopeDive(column: pack, clock: clock, near: false) { view in
                    SlopeLayer {
                        ForEach(0 ..< view.lay.count, id: \.self) { n in
                            SlopePebble(kind: n < 3 ? .pale : .dull, width: view.lay.half(n < 3 ? .lit : .dull) * 2, lean: SlopePebble.lean(n), dimmed: n >= 3)
                                .seated(at: view.seat(n))
                            Text(verbatim: "\(n + 1)  Specimen").font(.slope(.ui, .body)).ink(n < 3 ? .ink : .ink4) // loc: verbatim a stand-in
                                .slopeLine(CGPoint(x: view.lip(n).x + 18, y: view.seat(n).y - 6))
                        }
                    }
                }
            case .stones:
                SlopeScene(column: column, focus: 12, at: 0.5, z: 1, clock: clock, near: near) { _ in
                    SlopeLayer {
                    VStack(alignment: .leading, spacing: 24) {
                        Stone(Text(verbatim: "lit"), state: .lit) { taps += 1 } // loc: verbatim a stand-in
                        Stone(Text(verbatim: "next ›"), state: .next, glow: Tier.whirlpool.glow) { taps += 1 } // loc: verbatim a stand-in
                        Stone(Text(verbatim: "dull"), state: .dull, refused: taps) { taps += 1 } // loc: verbatim a stand-in
                        Stone(Text(verbatim: "reset? tap again"), state: .armed) { taps += 1 } // loc: verbatim a stand-in
                        Stone(Text(verbatim: "buying…"), state: .pending) { taps += 1 } // loc: verbatim a stand-in
                        Stone(Text(verbatim: "pale"), pale: true) { taps += 1 } // loc: verbatim a stand-in
                        Stone(Text(verbatim: "trailing"), trailing: true) { taps += 1 } // loc: verbatim a stand-in
                    }
                    .slopePlace(CGPoint(x: column.lip + 70, y: size.height * 0.14), anchor: .topLeading)
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

extension SlopeHarness {
    /// The column with each stretch as tall at the overview as the stand-ins' words beside it.
    fileprivate func grown(_ column: SlopeColumn, height: CGFloat) -> SlopeColumn {
        var column = column
        let title = SlopeSize.title.line(at: typeSize), detail = SlopeSize.detail.line(at: typeSize)
        column.stretches[0].height = max(0.1255 * height, 3 * (0.6 * title + 8))
        for s in 1 ..< column.stretches.count { column.stretches[s].height = max(0.125 * height, title + detail + 16) }
        column.under = (title + detail + 4) / 2
        return column
    }
}

/// Stand-ins for what the screens will set on the main column: a pebble on every level's seat, its number, name and
/// facts beside it, each tier's name, hollows, the stone on the bank and endless. Drawn from one view of the column,
/// the overview's words while the depth is closed and the dive's once it has opened.
private struct SlopeStandIns: View {
    let view: SlopeView
    let solved: Int
    /// Leaves out what is off the screen: the scene lays everything out again each frame, the dive once.
    let cull: Bool
    @Binding var taps: Int

    @Environment(\.dynamicTypeSize) private var typeSize

    private var lay: SlopeLay { view.lay }
    /// 1 in the dive, 0 until the depth is nearly open; and 1 at the overview.
    private var near: Double { min(max((lay.e - 0.8) / 0.2, 0), 1) }
    private var wide: Double { 1 - min(lay.e / 0.2, 1) }
    private var large: Bool { lay.column.step < 6 }
    /// Where the dive's words start beside ledge `n`.
    private func words(_ n: Int) -> CGFloat { large ? 96 : view.lip(n).x + 18 }

    private func shown(_ y: CGFloat) -> Bool { !cull || y > -80 && y < view.size.height + 80 }

    var body: some View {
        SlopeLayer {
            surface
            ForEach(Array(Tier.allCases.enumerated()), id: \.offset) { t, tier in
                heading(t, tier)
                ForEach(Array(tier.levels.prefix(27).enumerated()), id: \.offset) { i, level in
                    row(level, number: t * 27 + i + 1, ledge: SlopeColumn.ledge(tier: t, level: i + 1), tier: tier)
                }
            }
            if near > 0, !large { hollows.opacity(near) }
            let deep = view.y(lay.endless)
            if shown(deep) {
                VStack(spacing: 4) {
                    Text(verbatim: "endless").font(.slope(.place, .title)).ink(.ink) // loc: verbatim a stand-in
                    Text(verbatim: "best 9").font(.slope(.data, .detail)).ink(.ink3) // loc: verbatim a stand-in
                }
                .slopePlace(CGPoint(x: view.size.width * 0.57, y: deep))
            }
        }
    }

    /// The wordmark over the water, the stone on the bank, and the daily's and the archive's pebbles in the shallows.
    @ViewBuilder private var surface: some View {
        let bank = view.bank
        if shown(bank.y) {
            Text(verbatim: "UNSTIR").font(.slope(.name, .display)).tracking(9).ink(.ink) // loc: verbatim the wordmark
                .slopePlace(CGPoint(x: 32, y: bank.y - 30), anchor: .bottomLeading)
            Stone(Text(verbatim: "settings").font(.slope(.ui, .detail))) { taps += 1 } // loc: verbatim a stand-in
                .rested(at: view.bankSeat)
        }
        ForEach([SlopeColumn.today, SlopeColumn.archive], id: \.self) { n in
            let seat = view.seat(n), today = n == SlopeColumn.today
            if shown(seat.y) {
                SlopePebble(kind: today ? .next : .dull, width: lay.half(today ? .next : .dull) * 2, breath: today ? 3 : nil).seated(at: seat)
                Text(verbatim: today ? "today" : "Archive").font(.slope(today ? .place : .ui, today ? .title : .body)) // loc: verbatim a stand-in
                    .ink(today ? .ink : .ink2)
                    .slopeLine(CGPoint(x: wide > 0 ? (large ? 96 : 180) : words(n), y: seat.y))
                    .opacity(max(wide, near))
            }
        }
    }

    @ViewBuilder private func heading(_ t: Int, _ tier: Tier) -> some View {
        let first = SlopeColumn.ledge(tier: t, level: 1)
        // Beside the stretch at the overview; over its first ledge in the dive.
        let y = wide > 0 ? view.y(lay.tops[first]) + max(22, SlopeSize.title.line(at: typeSize) / 2 - 4)
            : view.y(lay.headers[t + 1]) + lay.column.stretches[t + 1].header * 0.45
        if shown(y) {
            VStack(alignment: .leading, spacing: 3) {
                Text(tier.word).font(.slope(.place, .title)).ink(.ink)
                Text(verbatim: "\(min(max(solved - t * 27, 0), 27))/27 at par") // loc: verbatim a stand-in
                    .font(.slope(.data, .detail)).ink(.ink3)
            }
            .slopeLine(CGPoint(x: wide > 0 ? (large ? 96 : 180) : words(first), y: y))
            .opacity(max(wide, near))
        }
    }

    @ViewBuilder private func row(_ level: Level, number: Int, ledge n: Int, tier: Tier) -> some View {
        let seat = view.seat(n)
        if shown(seat.y) {
            let next = number == solved + 1, done = number <= solved
            let half = lay.half(done ? .lit : next ? .next : .dull)
            SlopePebble(kind: done ? .lit : next ? .next : .dull, width: half * 2, lean: SlopePebble.lean(number),
                        glow: lay.rocks[n].light, breath: next ? 3 : nil, dimmed: !done && !next)
                .seated(at: seat)
            if near > 0 {
                let x = words(n)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                        Text(level.label).font(.slope(.data, next ? .body : .label)).ink(done || next ? .ink3 : .ink4)
                        Text(level.title).font(next ? .slope(.name, .title) : .slope(.ui, .body)).ink(done || next ? .ink : .ink4)
                    }
                    Text(verbatim: "\(level.layout.rods.count) rods · par \(level.fixedPar ?? level.scramble.count)") // loc: verbatim a stand-in
                        .font(.slope(.data, next ? .label : .detail)).ink(next ? .ink2 : done ? .ink3 : .ink4)
                }
                .frame(maxWidth: max(view.size.width - x - 16, 60), alignment: .leading)
                .slopeLine(CGPoint(x: x, y: seat.y - half * 0.6))
                .opacity(near)
            }
        }
    }

    /// The packs' hollows, dark mouths in plughole's wall with a light inside, centred at x = 56.
    @ViewBuilder private var hollows: some View {
        ForEach(Array(zip(Pack.allCases, [2, 6, 11, 16])), id: \.0) { pack, after in
            let y = view.y(lay.between(SlopeColumn.ledge(tier: 0, level: after)))
            if shown(y) {
                VStack(spacing: 8) {
                    Circle().fill(Color(0x03060A).opacity(0.92))
                        .overlay(Circle().fill(RadialGradient(colors: [pack == .prism ? Color.white.opacity(0.5) : Offer.pack(pack).glow.opacity(0.6), .clear],
                                                              center: .center, startRadius: 0, endRadius: 26)))
                        .frame(width: 68, height: 68)
                    Text(verbatim: pack.name).font(.slope(.ui, .detail)).ink(.ink)
                }
                .slopePlace(CGPoint(x: 56, y: y - 34), anchor: .top)
            }
        }
    }
}
#endif
