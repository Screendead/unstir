// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The daily archive: every past daily, opened by any purchase (to-do 47). Its days play as the daily they were, from
/// the frozen generator, and keep their bests under their own `daily-yyyymmdd` ids.
enum Archive {
    /// Days back-filled before daily #1, so the archive isn't empty on launch day (Jack's call, round 6).
    static let backFill = 30

    /// The archive's days, oldest first: from `backFill` days before daily #1 (`Share.firstDay`), or before today while
    /// that is unset, to yesterday. Today's daily stays on the menu. Local days on the Gregorian calendar, as the ids are.
    static func days(today: Date = .now, firstDay: Int? = Share.firstDay,
                     calendar: Calendar = Calendar(identifier: .gregorian)) -> [Date] {
        let now = calendar.startOfDay(for: today)
        let launch = firstDay.flatMap { calendar.date(from: DateComponents(year: $0 / 10000, month: $0 / 100 % 100, day: $0 % 100)) }
        // A first day still ahead, as on a build made before launch, back-fills from today.
        guard let first = calendar.date(byAdding: .day, value: -backFill, to: min(launch ?? now, now)) else { return [] }
        var days: [Date] = [], day = first
        while day < now, let next = calendar.date(byAdding: .day, value: 1, to: day) {
            days.append(day)
            day = next
        }
        return days
    }

    /// Any purchase opens it; so does the developer unlock, where it opens a pack's levels (`Pack.access`).
    static func opens(bought: Bool, unlocked: Bool = Best.unlocked, release: Bool = Build.release,
                      playtest: Bool = Build.playtest) -> Bool {
        bought || ((!release || playtest) && unlocked)
    }

    @MainActor static var open: Bool { opens(bought: Store.shared.bought) }

    /// A level's result: the archive's word for it, and how many marks it fills on a row (`ResultMarks.filled`).
    enum Mark: Equatable {
        case clean, par, over(Int), tried, unplayed

        init(_ best: Best?, started: Bool) {
            self = if let best { best.clean == true ? .clean : best.over == 0 ? .par : .over(best.over) }
                else { started ? .tried : .unplayed }
        }

        init(_ id: String) { self.init(Best.load(id), started: Best.started(id)) }

        var word: String {
            switch self {
            case .clean: "clean"
            case .par: "par"
            case let .over(n): "+\(n)"
            case .tried: "tried"
            case .unplayed: ""
            }
        }

        var spoken: String {
            switch self {
            case .clean: "clean"
            case .par: "at par"
            case let .over(n): "\(n) over par"
            case .tried: "tried"
            case .unplayed: "not played"
            }
        }

        var solved: Bool { ![.tried, .unplayed].contains(self) }

        @ViewBuilder var text: some View {
            switch self {
            case .clean: Text(word).fontWeight(.semibold).foregroundStyle(Color.lime).shadow(color: .lime, radius: 3)
            case .par: Text(word).foregroundStyle(Color.amber)
            case .over: Text(word).foregroundStyle(Color.magenta)
            case .tried: Text(word).foregroundStyle(Color.text3)
            case .unplayed: Text(" ")
            }
        }
    }
}

/// The archive's row under today's daily: a quiet lock that says what opens it, never a way to the shop.
struct ArchiveRow: View {
    /// Nil until the store has read what the player owns.
    let open: Bool?
    let days: Int
    let atPar: Int
    let pick: () -> Void
    /// A tap on the locked row: false while a stir is under the finger.
    let refuse: () -> Bool
    @State private var said = false
    @State private var taps = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    /// As a level row's number.
    @ScaledMetric(relativeTo: .subheadline) private var numberWidth = 40.0

    var body: some View {
        let open = open ?? true, known = self.open != nil
        return Button { open ? pick() : tapped() } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("past").font(.ui(.label, .semibold)).foregroundStyle(Color.amber)
                    .shadow(color: open ? .amber : .clear, radius: 4).opacity(open ? 1 : 0.7)
                    .frame(width: typeSize.isAccessibilitySize ? nil : numberWidth, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Archive").font(.ui(.body)).foregroundStyle(open ? Color.text : Color.text3)
                    if said {
                        Text("unlocked by purchasing any pack").font(.ui(.detail)).foregroundStyle(Color.amber).transition(.opacity)
                    } else {
                        Text(!known ? "\(days) past dailies" : open ? "\(days) past dailies \u{00B7} \(atPar) at par"
                             : "\(days) past dailies \u{00B7} comes with any pack")
                            .font(.ui(.detail)).foregroundStyle(Color.text2).transition(.opacity)
                    }
                }
                .animation(.easeOut(duration: 0.2), value: said)
                Spacer(minLength: 8)
                if known && !open { Image(systemName: "lock").font(.ui(.detail)).foregroundStyle(Color.text4) }
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
            .keyframeAnimator(initialValue: 0.0, trigger: taps) { row, x in
                row.offset(x: reduceMotion ? 0 : x)
            } keyframes: { _ in
                LinearKeyframe(-5.0, duration: 0.06)
                LinearKeyframe(4.0, duration: 0.08)
                LinearKeyframe(-2.0, duration: 0.07)
                LinearKeyframe(0.0, duration: 0.07)
            }
        }
        // Plain: `pick` taps, as a row does.
        .buttonStyle(.plain)
        .disabled(!known)
        .modifier(Speech(Spoken.archiveRow(open: open, days: days, atPar: atPar)))
    }

    private func tapped() {
        guard refuse() else { return }
        taps += 1
        said = true
        let tap = taps
        Task {
            try? await Task.sleep(for: .seconds(2))
            if taps == tap { said = false }
        }
    }
}

/// The calendar of past dailies over the menu, a month to a block, each day's number over its result.
struct ArchiveView: View {
    /// The day just left, which it opens on with its ring lit once.
    var focus: String?
    let onBack: () -> Void
    let onPlay: (Level) -> Void
    /// Beside the menu's list in a wide window, not over it, so VoiceOver reaches both.
    let beside: Bool
    /// The archive's days dealt, oldest first.
    let days: [(date: Date, level: Level)]
    private let calendar: Calendar
    private let today: Date
    @State private var lit = 0.0
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(days: [(date: Date, level: Level)], today: Date = .now, focus: String? = nil, beside: Bool = false,
         onBack: @escaping () -> Void, onPlay: @escaping (Level) -> Void) {
        self.focus = focus
        self.beside = beside
        self.onBack = onBack
        self.onPlay = onPlay
        self.days = days
        // Laid out on the player's week, keyed on the Gregorian days the ids use.
        var c = Calendar(identifier: .gregorian)
        c.locale = .current
        c.firstWeekday = Calendar.current.firstWeekday
        calendar = c
        self.today = c.startOfDay(for: today)
    }

    var body: some View {
        let marks = days.map { Archive.Mark($0.level.id) }
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    let back = PackCard.back(to: PackCard.menu, beside: beside)
                    Button(action: onBack) { Text(back.text).font(.ui(.button)).hit() }
                        .buttonStyle(Sounding()).padding(.top, 18)
                        .accessibilityLabel(back.spoken)
                    Text("PAST DAILIES").font(.ui(.eyebrow)).tracking(2).foregroundStyle(Color.text3).padding(.top, 26)
                    Text("Archive").font(.ui(.display)).tracking(2)
                        .foregroundStyle(Tier.plughole.sweep).shadow(color: Color.amber.opacity(0.55), radius: 10)
                        .padding(.top, 6)
                        .accessibilityAddTraits(.isHeader)
                    Text("Every daily as it was dealt. A best here is its own: only a daily solved on its day adds to the days running.")
                        .font(.ui(.label)).foregroundStyle(Color.text2).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
                    Text("done \(marks.filter { $0 == .clean || $0 == .par }.count)/\(days.count) at par")
                        .font(.ui(.detail)).foregroundStyle(Color.text3).padding(.top, 14)
                    ForEach(months, id: \.self) { month in
                        block(month, marks: marks).padding(.top, 30)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollBounceBehavior(.basedOnSize)
            // Scrolled words fade out at the safe area's top rather than run on under the status bar's clock, as on a
            // pack's card.
            .mask {
                VStack(spacing: 0) {
                    LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom).frame(height: 12)
                    Color.black
                }
                .padding(.bottom, -80)
            }
            .onAppear {
                // The day just left, else the newest, at the bottom.
                let id = focus.flatMap { f in days.contains { $0.level.id == f } ? f : nil } ?? days.last?.level.id
                if let id { DispatchQueue.main.async { reader.scrollTo(id, anchor: .center) } }
                guard focus != nil, !reduceMotion else { return }
                lit = 1
                withAnimation(.easeOut(duration: 1.4).delay(0.35)) { lit = 0 }
            }
        }
        .foregroundStyle(Color.text)
        .background(Color.black.ignoresSafeArea())
        .accessibilityAddTraits(beside ? [] : .isModal)
        .accessibilityAction(.escape, onBack)
    }

    /// The first of each month the archive reaches, oldest first.
    private var months: [Date] {
        var seen: [Date] = []
        for d in days {
            let m = calendar.date(from: calendar.dateComponents([.year, .month], from: d.date))!
            if seen.last != m { seen.append(m) }
        }
        return seen
    }

    /// A month's name over its days, on a week grid; at accessibility sizes a list, as seven columns no longer fit.
    @ViewBuilder private func block(_ month: Date, marks: [Archive.Mark]) -> some View {
        let inMonth = days.indices.filter { calendar.isDate(days[$0].date, equalTo: month, toGranularity: .month) }
        VStack(alignment: .leading, spacing: 10) {
            // Named on the Gregorian calendar its days are laid out on, whatever calendar the phone reads dates in.
            Text(month.formatted(Date.FormatStyle(calendar: calendar).month(.wide).year()).uppercased())
                .font(.ui(.detail, .semibold)).tracking(2).foregroundStyle(Color.text3)
                .accessibilityAddTraits(.isHeader)
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(inMonth, id: \.self) { i in listRow(i, mark: marks[i]) }
                }
            } else {
                grid(month, inMonth: inMonth, marks: marks)
            }
        }
    }

    private func grid(_ month: Date, inMonth: [Int], marks: [Archive.Mark]) -> some View {
        // Today's month ends at today: the days after it hold nothing yet.
        let full = calendar.range(of: .day, in: .month, for: month)!.count
        let length = calendar.isDate(today, equalTo: month, toGranularity: .month) ? calendar.component(.day, from: today) : full
        let lead = (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(0 ..< 7, id: \.self) { k in
                Text(symbols[(k + calendar.firstWeekday - 1) % 7]).font(.ui(.detail)).foregroundStyle(Color.text3)
                    .accessibilityHidden(true)
            }
            ForEach(0 ..< lead, id: \.self) { _ in Color.clear.frame(height: 1).accessibilityHidden(true) }
            ForEach(1 ... length, id: \.self) { d in
                let date = calendar.date(byAdding: .day, value: d - 1, to: month)!
                if let i = inMonth.first(where: { calendar.isDate(days[$0].date, inSameDayAs: date) }) {
                    cell(i, mark: marks[i])
                } else {
                    // Outside the archive: today, whose daily is on the menu, or a day it doesn't reach.
                    let isToday = calendar.isDate(date, inSameDayAs: today)
                    VStack(spacing: 3) {
                        Text("\(d)").font(.ui(.label)).foregroundStyle(isToday ? Color.text3 : Color.text4)
                        Text(isToday ? "today" : " ").font(.ui(.detail)).foregroundStyle(Color.amber).opacity(0.5)
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(isToday ? "Today. Its daily is on the menu." : "")
                    .accessibilityHidden(!isToday)
                }
            }
        }
    }

    private func cell(_ i: Int, mark: Archive.Mark) -> some View {
        let (date, level) = days[i]
        return Button { onPlay(level) } label: {
            VStack(spacing: 3) {
                Text("\(calendar.component(.day, from: date))").font(.ui(.label, mark == .unplayed ? .regular : .medium))
                    .opacity(mark == .unplayed ? 0.8 : 1)
                mark.text.font(.ui(.detail)).lineLimit(1).minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background {
                // The day just left, lit once.
                Circle().stroke(Color.amber, lineWidth: 0.5).frame(width: 44, height: 44)
                    .shadow(color: .amber, radius: 3).opacity(level.id == focus ? lit : 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(Sounding())
        .id(level.id)
        .modifier(Speech(Spoken.archiveDay(date, level: level, mark: mark)))
    }

    private func listRow(_ i: Int, mark: Archive.Mark) -> some View {
        let (date, level) = days[i]
        return Button { onPlay(level) } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))).font(.ui(.body))
                Spacer(minLength: 8)
                mark.text.font(.ui(.detail))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(Sounding())
        .id(level.id)
        .rowHairline(.amber, level.id == focus ? lit : 0)
        .modifier(Speech(Spoken.archiveDay(date, level: level, mark: mark)))
    }
}
