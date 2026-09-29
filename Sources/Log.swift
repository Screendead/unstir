// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A flight recorder for bugs seen only on the phone: one line per event in Library/unstir-log.txt, the last 3000
/// kept across launches. scripts/pull-log.sh copies it off.
@MainActor
enum Log {
    private static let file: FileHandle? = {
        let url = URL.libraryDirectory.appending(path: "unstir-log.txt")
        let kept = ((try? String(contentsOf: url, encoding: .utf8)) ?? "").split(separator: "\n").suffix(3000)
        FileManager.default.createFile(atPath: url.path, contents: Data(kept.map { $0 + "\n" }.joined().utf8))
        let file = try? FileHandle(forWritingTo: url)
        _ = try? file?.seekToEnd()
        return file
    }()
    private static let clock = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm:ss.SSS"
        return f
    }()

    static func write(_ line: String) {
        try? file?.write(contentsOf: Data("\(clock.string(from: .now)) \(line)\n".utf8))
    }

    static func opt(_ v: Int?) -> String { v.map(String.init) ?? "nil" }

    /// A point in tank units.
    nonisolated static func point(_ p: SIMD2<Double>) -> String { String(format: "%.3f,%.3f", p.x, p.y) }
}

/// A drag's path for the log, thinned as it comes in so a drag stays one line: the landing, a point each time the drag
/// has gone `gap` from the last one kept (a third of that for the first few, so the first millimetre of a touch shows),
/// and the latest. At `cap` points it drops every other one after the first few and doubles the gap.
struct Trail<Point> {
    static var cap: Int { 24 }
    /// Points kept after the landing at a third of the gap.
    static var early: Int { 4 }
    private(set) var gap: Double
    private let apart: (Point, Point) -> Double
    private var kept: [(ms: Int, at: Point)] = []
    private var latest: (ms: Int, at: Point)?

    init(gap: Double, apart: @escaping (Point, Point) -> Double) {
        self.gap = gap
        self.apart = apart
    }

    /// `ms` since the drag began.
    mutating func add(_ point: Point, ms: Int) {
        guard let last = kept.last else { kept = [(ms, point)]; return }
        guard apart(last.at, point) >= (kept.count > Self.early ? gap : gap / 3) else { latest = (ms, point); return }
        kept.append((ms, point))
        latest = nil
        guard kept.count == Self.cap else { return }
        let rest = kept[(Self.early + 1)...]
        // Counted from the newest, so the point the next gap is measured from stays.
        kept = kept[...Self.early] + rest.enumerated().filter { (rest.count - 1 - $0.offset) % 2 == 0 }.map(\.element)
        gap *= 2
    }

    var points: [(ms: Int, at: Point)] { kept + (latest.map { [$0] } ?? []) }

    /// Each point as `ms:point`.
    func line(_ show: (Point) -> String) -> String { points.map { "\($0.ms):\(show($0.at))" }.joined(separator: " ") }
}

extension Twist: CustomStringConvertible {
    var description: String { String(format: "%d:%+d", rod, steps) }
}
