// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The archive's ledge on the menu's slope (docs/slope.md, 2.5): its pebble and the words beside it, for the menu to
/// set with the pebble's centre on the shallows' third seat. The whole row is the target. Shut, a tap rocks the pebble
/// and says for 2 s what opens it; it never opens a hollow.
struct ArchiveLedge: View {
    /// Nil until the store has read what the player owns: drawn shut, with only the count.
    let open: Bool?
    let days: Int
    let atPar: Int
    /// The pebble's width at this zoom (`SlopeLay.half(.lit)` doubled), and the gap from its centre to the words.
    var pebble: CGFloat = 16.8
    var gap: CGFloat = 48
    let pick: () -> Void
    /// A tap on the shut ledge: false while a stir is under the finger.
    let refuse: () -> Bool
    @State private var said = false
    @State private var refused = 0

    var body: some View {
        let open = self.open == true, known = self.open != nil
        Button { open ? pick() : tapped() } label: {
            HStack(alignment: .center, spacing: 0) {
                SlopePebble(kind: open ? .lit : .dull, width: pebble * (open ? 1 : 0.81), lean: SlopePebble.lean(2), dimmed: !open)
                    .keyframeAnimator(initialValue: 0.0, trigger: refused) { stone, degrees in
                        stone.rotationEffect(.degrees(degrees), anchor: .bottom)
                    } keyframes: { _ in
                        CubicKeyframe(6, duration: 0.05)
                        CubicKeyframe(-6, duration: 0.08)
                        CubicKeyframe(6, duration: 0.07)
                        CubicKeyframe(-6, duration: 0.06)
                        CubicKeyframe(0, duration: 0.04)
                    }
                    .frame(width: pebble)
                    .padding(.trailing, max(gap - pebble / 2, 0))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Archive", comment: "The archive's ledge on the menu").font(.slope(.ui, .body)).ink(open ? .ink : .ink4)
                    Group {
                        if said {
                            Text("unlocked by purchasing any pack", comment: "The archive's ledge, tapped while shut").ink(.ink)
                        } else if !known {
                            Text("\(days) past dailies", comment: "The archive's ledge before purchases are read").ink(.ink3)
                        } else if open {
                            Text("\(days) past dailies \u{00B7} \(atPar) at par",
                                 comment: "The archive's ledge, open. Past dailies, then how many are at par").ink(.ink2)
                        } else {
                            Text("\(days) past dailies \u{00B7} comes with any pack",
                                 comment: "The archive's ledge, shut until a purchase. Past dailies").ink(.ink3)
                        }
                    }
                    .font(.slope(.ui, .detail))
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
                }
                .animation(.easeOut(duration: 0.2), value: said)
                Spacer(minLength: 0)
            }
            .frame(minHeight: SlopePebble.target)
            .contentShape(Rectangle())
        }
        .buttonStyle(Sounding(presses: true))
        .disabled(!known)
        .onChange(of: refused) { Sound.shared.play(.seized) }
        .modifier(Speech(Spoken.archiveRow(open: open == true, days: days, atPar: atPar)))
    }

    /// Set on the menu's slope: the pebble's centre on the archive's seat, the words starting at `words`.
    static func seated(_ spot: SlopeSpot, words: CGFloat, open: Bool?, days: Int, atPar: Int, pick: @escaping () -> Void,
                       refuse: @escaping () -> Bool) -> some View {
        let side = spot.side / 0.81
        return ArchiveLedge(open: open, days: days, atPar: atPar, pebble: side, gap: words - spot.point.x, pick: pick, refuse: refuse)
            .frame(width: spot.view.size.width - 16 - (spot.point.x - side / 2))
            .slopePlace(CGPoint(x: spot.point.x - side / 2, y: spot.point.y - side * 0.36), anchor: .leading)
    }

    private func tapped() {
        guard refuse() else { return }
        refused += 1
        said = true
        let tap = refused
        Task {
            try? await Task.sleep(for: .seconds(2))
            if refused == tap { said = false }
        }
    }
}

/// The archive's calendar on its own stretch of the shallows (docs/slope.md, 7): a month to a stretch, a week to a
/// terrace of seven seats, each day's number over its pebble and its result under the ledge. At the accessibility sizes
/// a ledge a day, newest first.
struct SlopeArchive: View {
    let days: [(date: Date, level: Level)]
    /// The day just left, whose pebble is the way on once.
    var focus: String?
    /// In a wide window, where "✕ close" stands beside the way back.
    var beside = false
    var clock: Double?
    let onBack: () -> Void
    var onClose: (() -> Void)?
    let onPlay: (Level) -> Void

    private let calendar: Calendar
    private let today: Date
    @Environment(\.dynamicTypeSize) private var typeSize

    init(days: [(date: Date, level: Level)], today: Date = .now, focus: String? = nil, beside: Bool = false, clock: Double? = nil,
         onBack: @escaping () -> Void, onClose: (() -> Void)? = nil, onPlay: @escaping (Level) -> Void) {
        self.days = days
        self.focus = focus
        self.beside = beside
        self.clock = clock
        self.onBack = onBack
        self.onClose = onClose
        self.onPlay = onPlay
        // Laid out on the player's week, keyed on the Gregorian days the ids use.
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        c.firstWeekday = Calendar.current.firstWeekday
        calendar = c
        self.today = c.startOfDay(for: today)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing
            ZStack {
                ground(CGSize(width: width, height: geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom))
                    .ignoresSafeArea()
                ScrollViewReader { reader in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            head
                            if typeSize.isAccessibilitySize {
                                dive
                            } else {
                                ForEach(months, id: \.self) { month(month: $0, width: geo.size.width) }
                            }
                        }
                        .padding(.bottom, 40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .defaultScrollAnchor(typeSize.isAccessibilitySize ? .top : .bottom)
                    .onAppear {
                        guard let focus, days.contains(where: { $0.level.id == focus }) else { return }
                        DispatchQueue.main.async { reader.scrollTo(focus, anchor: .center) }
                    }
                }
            }
        }
        .background(Color.black)
        .accessibilityAddTraits(beside ? [] : .isModal)
        .accessibilityAction(.escape, onBack)
    }

    /// The shallows' still water with no ledge of the menu's in sight: its one ledge stands far over the screen.
    private func ground(_ size: CGSize) -> some View {
        let column = SlopeColumn(stretches: [.init(terraces: [1])], foot: .floor, surface: false, first: nil, still: 2)
        let lay = SlopeLay(column, z: 1)
        return SlopeGround(view: SlopeView(lay: lay, top: lay.foot + 400, size: size), clock: clock, near: false)
    }

    private var head: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 24) {
                Button(action: onBack) {
                    Text("\u{2191} menu", comment: "The archive's way back, up to the menu").font(.slope(.ui, .body)).ink(.ink)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading).contentShape(Rectangle())
                }
                .buttonStyle(Sounding())
                .accessibilityLabel(Text("Back to the menu", comment: "VoiceOver: the archive's way back"))
                if beside, let onClose {
                    Button(action: onClose) {
                        Text("\u{2715} close", comment: "The archive's close, in a wide window").font(.slope(.ui, .body)).ink(.ink3)
                            .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(Sounding())
                }
            }
            Text("Archive", comment: "The archive's title").font(.slope(.name, .display)).ink(.ink)
                .padding(.top, 10)
                .accessibilityAddTraits(.isHeader)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    // MARK: The calendar

    /// The first of each month the archive reaches, oldest first.
    private var months: [Date] {
        var seen: [Date] = []
        for d in days {
            let m = calendar.date(from: calendar.dateComponents([.year, .month], from: d.date))!
            if seen.last != m { seen.append(m) }
        }
        // Today's month too, when the archive ends with the last: today's seat stands in it.
        let now = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        if seen.last != now { seen.append(now) }
        return seen
    }

    /// A week of the calendar: seven dates from its first weekday, each nil where it falls outside `month`.
    private func weeks(_ month: Date) -> [[Date?]] {
        let length = calendar.range(of: .day, in: .month, for: month)!.count
        let lead = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
        let cells: [Date?] = Array(repeating: nil, count: lead)
            + (0 ..< length).map { calendar.date(byAdding: .day, value: $0, to: month) }
        return stride(from: 0, to: cells.count, by: 7).compactMap { start in
            let week = (start ..< start + 7).map { $0 < cells.count ? cells[$0] : nil }
            // A week with neither an archived day nor today holds nothing to draw.
            return week.contains { $0.map { d in d == today || index(of: d) != nil } ?? false } ? week : nil
        }
    }

    private func index(of date: Date) -> Int? { days.firstIndex { calendar.isDate($0.date, inSameDayAs: date) } }

    @ViewBuilder private func month(month: Date, width: CGFloat) -> some View {
        let rows = weeks(month)
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                // Named on the Gregorian calendar its days are laid out on.
                Text(verbatim: month.formatted(Date.FormatStyle(calendar: calendar).month(.wide)))
                    .font(.slope(.place, .title)).ink(.ink)
                    .padding(.horizontal, 24)
                    .padding(.top, 34)
                    .padding(.bottom, 4)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(rows.enumerated()), id: \.offset) { n, week in
                    terrace(week, width: width, seed: calendar.component(.month, from: month) * 7 + n)
                }
            }
        }
    }

    /// Seats 52 pt apart, or a sixth of what leaves 31 pt each side.
    private func pitch(_ width: CGFloat) -> CGFloat { min(52, (width - 63) / 6) }

    private func terrace(_ week: [Date?], width: CGFloat, seed: Int) -> some View {
        let pitch = pitch(width), first = width / 2 - 3 * pitch
        let number = TypeRole.label.line(at: typeSize).height, result = TypeRole.detail.line(at: typeSize).height
        // The number, a pebble's room, the ledge's thickness, the result; at least 72.
        let top = number + 18, height = max(72, top + 14 + result + 8)
        return ZStack(alignment: .topLeading) {
            WeekLedge(top: top, from: first - pitch * 0.62, to: first + 6.62 * pitch, seed: seed)
            ForEach(0 ..< 7, id: \.self) { k in
                if let date = week[k] {
                    seat(date, top: top, number: number)
                        .frame(width: pitch, height: height)
                        .offset(x: first + CGFloat(k) * pitch - pitch / 2)
                }
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }

    @ViewBuilder private func seat(_ date: Date, top: CGFloat, number: CGFloat) -> some View {
        let day = calendar.component(.day, from: date)
        if let i = index(of: date) {
            let level = days[i].level, mark = Archive.Mark(level.id), next = level.id == focus
            Button { onPlay(level) } label: {
                VStack(spacing: 0) {
                    Text(day, format: .number).font(.slope(.data, .label)).ink(mark == .unplayed ? .ink2 : .ink)
                        .frame(height: number)
                    SlopePebble(kind: next ? .next : mark.solved ? .lit : .dull,
                                width: next ? 25 : mark.solved ? 16.8 : 13.6, lean: SlopePebble.lean(day),
                                breath: next ? 3 : nil)
                        .frame(height: top - number, alignment: .bottom)
                        .offset(y: 3)
                    Text(verbatim: mark.word.isEmpty ? " " : mark.word).font(.slope(.data, .detail)).ink(.ink2)
                        .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .contentShape(Rectangle())
            }
            .buttonStyle(Sounding(presses: true))
            .id(level.id)
            .modifier(Speech(Spoken.archiveDay(date, level: level, mark: mark)))
        } else if date == today {
            // Today's own seat stays bare: its daily is on the menu.
            VStack(spacing: 0) {
                Text(day, format: .number).font(.slope(.data, .label)).ink(.ink3).frame(height: number)
                Text("today", comment: "The archive: today's seat, whose daily is on the menu")
                    .font(.slope(.place, .detail)).ink(.ink3).fixedSize()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Today. Its daily is on the menu.", comment: "VoiceOver: the archive's grid, on today"))
        }
    }

    // MARK: The dive, at the accessibility sizes

    private var dive: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(days.indices.reversed(), id: \.self) { i in
                let (date, level) = days[i], mark = Archive.Mark(level.id), next = level.id == focus
                Button { onPlay(level) } label: {
                    ZStack(alignment: .topLeading) {
                        WeekLedge(top: 30, from: -20, to: 62, seed: i)
                        SlopePebble(kind: next ? .next : mark.solved ? .lit : .dull,
                                    width: next ? 25 : mark.solved ? 16.8 : 13.6, lean: SlopePebble.lean(i), breath: next ? 3 : nil)
                            .offset(x: 44 - (next ? 12.5 : 8.4), y: 30 - (next ? 18 : 12) + 3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                                .font(.slope(.ui, .body)).ink(.ink)
                            if !mark.word.isEmpty {
                                Text(verbatim: mark.word).font(.slope(.data, .detail)).ink(.ink2)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 96).padding(.trailing, 16).padding(.top, 14)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
                    .padding(.bottom, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(Sounding(presses: true))
                .id(level.id)
                .modifier(Speech(Spoken.archiveDay(date, level: level, mark: mark)))
            }
        }
        .padding(.top, 24)
    }
}

/// A week's ledge of sandstone: a bowed top lit from above, its rounded nose at each end, the rock cutting back
/// under it. Drawn here, as the ground's ledges step out from the wall a pitch apart and can't seat seven across.
private struct WeekLedge: View {
    /// The top's depth, and its ends.
    let top: CGFloat
    let from: CGFloat
    let to: CGFloat
    let seed: Int

    var body: some View {
        Canvas { context, _ in
            let phase = CGFloat(seed) * 1.3
            func crest(_ x: CGFloat) -> CGFloat { top + 3.6 * sin(x * 0.019 + phase) + 0.012 * (x - from) }
            let span = to - from
            var rock = Path()
            rock.move(to: CGPoint(x: from, y: crest(from) + 4))
            for i in 0 ... 40 {
                let x = from + span * CGFloat(i) / 40
                rock.addLine(to: CGPoint(x: x, y: crest(x)))
            }
            // The nose, then the underside cutting back in a long curve.
            rock.addQuadCurve(to: CGPoint(x: to - 10, y: crest(to) + 13), control: CGPoint(x: to + 7, y: crest(to) + 5))
            rock.addCurve(to: CGPoint(x: from + 8, y: crest(from) + 12),
                          control1: CGPoint(x: to - span * 0.35, y: crest(to) + 6),
                          control2: CGPoint(x: from + span * 0.3, y: crest(from) + 20))
            rock.addQuadCurve(to: CGPoint(x: from, y: crest(from) + 4), control: CGPoint(x: from - 6, y: crest(from) + 9))
            rock.closeSubpath()
            context.fill(rock, with: .linearGradient(
                Gradient(stops: [.init(color: Color(0xD8C29A), location: 0), .init(color: Color(0x9C8466), location: 0.25),
                                 .init(color: Color(0x2F4A4E), location: 1)]),
                startPoint: CGPoint(x: 0, y: top - 4), endPoint: CGPoint(x: 0, y: top + 18)))
            // The light along the top, fading off at each end.
            var lip = Path()
            for i in 0 ... 40 {
                let x = from + 6 + (span - 12) * CGFloat(i) / 40, p = CGPoint(x: x, y: crest(x) + 0.6)
                if i == 0 { lip.move(to: p) } else { lip.addLine(to: p) }
            }
            context.stroke(lip, with: .linearGradient(
                Gradient(colors: [Color(0xFFF2D8).opacity(0), Color(0xFFF2D8).opacity(0.55), Color(0xFFF2D8).opacity(0)]),
                startPoint: CGPoint(x: from, y: 0), endPoint: CGPoint(x: to, y: 0)), lineWidth: 1.2)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#if DEBUG
/// UNSTIR_SLOPEARCHIVE: the archive's screens alone, for shots. `calendar` is the calendar, a day focused when
/// UNSTIR_SLOPEAT names one (`daily-yyyymmdd`); `ledge` the ledge shut, open and unread on open water.
struct SlopeArchiveHarness: View {
    let stage: String
    let focus: String?
    let clock: Double?

    init?(_ env: [String: String], clock: Double?) {
        guard let stage = env["UNSTIR_SLOPEARCHIVE"] else { return nil }
        self.stage = stage
        focus = env["UNSTIR_SLOPEAT"]
        self.clock = clock
    }

    var body: some View {
        if stage == "ledge" {
            ZStack {
                Color(0x14363C).ignoresSafeArea()
                VStack(alignment: .leading, spacing: 40) {
                    ArchiveLedge(open: false, days: 30, atPar: 0, pick: {}, refuse: { true })
                    ArchiveLedge(open: true, days: 30, atPar: 12, pick: {}, refuse: { true })
                    ArchiveLedge(open: nil, days: 30, atPar: 0, pick: {}, refuse: { true })
                }
                .padding(.leading, 140).padding(.trailing, 16)
            }
        } else {
            let days = Archive.days().map { (date: $0, level: Level.daily($0, archived: true)) }
            SlopeArchive(days: days, focus: focus, clock: clock, onBack: {}, onPlay: { _ in })
        }
    }
}
#endif
