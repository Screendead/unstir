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

    static func text(day: Int, moves: Int, par: Int, firstTry: Bool, clean: Bool, undos: Int, resets: Int,
                     marks: [Mark], firstDay: Int? = firstDay) -> String {
        let name = number(day, from: firstDay).map { "Unstir #\($0)" }
            ?? String(format: "Unstir %04d-%02d-%02d", day / 10000, day / 100 % 100, day % 100)
        var head = [name]
        if !firstTry { head.append("practice") }
        head.append("\(moves) \(moves == 1 ? "move" : "moves") (par \(par))")
        if clean { head.append("clean") }
        if undos > 0 { head.append("\(undos) \(undos == 1 ? "undo" : "undos")") }
        if resets > 0 { head.append("\(resets) \(resets == 1 ? "reset" : "resets")") }
        var lines = [head.joined(separator: " \u{00B7} ")]
        lines += stride(from: 0, to: marks.count, by: 10).map { marks[$0..<min($0 + 10, marks.count)].map(\.glyph).joined() }
        if !url.isEmpty { lines.append(url) }
        return lines.joined(separator: "\n")
    }
}
