// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// The daily's share line.
enum Share {
    /// Empty until the domain is set.
    static let url = ""
    /// Daily #1, as `Level.daily`'s yyyymmdd: launch day, unset until it is known, and until then the line names the
    /// date.
    static let firstDay: Int? = nil

    /// What one move did to the stack, in the colour of the flash it showed.
    enum Mark: Equatable, Sendable {
        case healed, pushed, merged, tank

        var glyph: String {
            switch self {
            case .healed: "\u{1F7EA}"
            case .pushed: "\u{1F7E5}"
            case .merged: "\u{2B1C}"
            case .tank: "\u{1F504}"
            }
        }
    }

    /// The daily's number, counted in whole calendar days from `firstDay`, so a clock change never skips or repeats
    /// one; nil before it or while it is unset.
    static func number(_ ymd: Int, from firstDay: Int? = firstDay) -> Int? {
        guard let firstDay else { return nil }
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        func date(_ v: Int) -> Date? { utc.date(from: DateComponents(year: v / 10000, month: v / 100 % 100, day: v % 100)) }
        guard let from = date(firstDay), let to = date(ymd), let days = utc.dateComponents([.day], from: from, to: to).day,
              days >= 0 else { return nil }
        return days + 1
    }

    /// The day of a daily's id, `daily-yyyymmdd`.
    static func day(of id: String) -> Int? {
        id.hasPrefix("daily-") ? Int(id.dropFirst(6)) : nil
    }

    /// The supporter mark's glyph, after the daily's name, as the menu draws it after the title.
    static let supporter = "\u{2726}"

    static func text(day: Int, moves: Int, par: Int, firstTry: Bool, clean: Bool, undos: Int, resets: Int,
                     marks: [Mark], supporter: Bool = false, firstDay: Int? = firstDay) -> String {
        let name = (number(day, from: firstDay).map { "Unstir #\($0)" }
            ?? String(format: "Unstir %04d-%02d-%02d", day / 10000, day / 100 % 100, day % 100))
            + (supporter ? " \(Self.supporter)" : "")
        // The words follow the device (Jack's call CAT5 = A); the name and the grid never change.
        var head = [name]
        if !firstTry { head.append(String(localized: "practice",
                                          comment: "Share line: a daily played after its first try")) }
        let moved = String(localized: "\(moves) moves", comment: "Moves played")
        head.append(String(localized: "\(moved) (par \(par))",
                           comment: "Share line: moves played, then the daily's par"))
        if clean { head.append(String(localized: "clean", comment: "Share line: solved with nothing wasted")) }
        if undos > 0 { head.append(String(localized: "\(undos) undos", comment: "Share line: undos taken")) }
        if resets > 0 { head.append(String(localized: "\(resets) resets", comment: "Share line: resets taken")) }
        var lines = [head.joined(separator: " \u{00B7} ")]
        lines += stride(from: 0, to: marks.count, by: 10).map { marks[$0..<min($0 + 10, marks.count)].map(\.glyph).joined() }
        if !url.isEmpty { lines.append(url) }
        return lines.joined(separator: "\n")
    }
}
