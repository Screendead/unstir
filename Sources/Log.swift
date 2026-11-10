// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A flight recorder for bugs seen only on the phone: one line per event in Library/unstir-log.txt, cut back to its
/// newest `keep` bytes, from a whole line, once it passes `cap`. scripts/pull-log.sh copies it off.
@MainActor
enum Log {
    nonisolated static let url = URL.libraryDirectory.appending(path: "unstir-log.txt")
    nonisolated static let cap = 1 << 20, keep = 512 << 10
    /// Opened at the first write, before the first frame; `trim` cuts it back later.
    private static var file: FileHandle? = opened()

    nonisolated private static func opened() -> FileHandle? {
        if !FileManager.default.fileExists(atPath: url.path) { FileManager.default.createFile(atPath: url.path, contents: nil) }
        let file = try? FileHandle(forWritingTo: url)
        _ = try? file?.seekToEnd()
        return file
    }

    /// Cuts the log back once it passes `cap`, after the first frame: the read and the cut off the main actor, then on
    /// it, where no write can land between, the lines written meanwhile added and the file replaced.
    static func trim() async {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > cap else { return }
        guard let done = await Task.detached(priority: .utility, operation: { Log.cut(Log.url) }).value else { return }
        try? file?.close()
        replace(url, with: done.kept, after: done.read)
        file = opened()
    }

    /// The log at `url` cut to its newest `keep` bytes, and how many bytes were read.
    nonisolated static func cut(_ url: URL) -> (kept: Data, read: Int)? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return (trimmed(data), data.count)
    }

    /// Replaces the log at `url` with `kept` and whatever was written past its first `read` bytes. Atomic, so the
    /// file is never left cut short or empty.
    nonisolated static func replace(_ url: URL, with kept: Data, after read: Int) {
        var since = Data()
        if let h = try? FileHandle(forReadingFrom: url) {
            if (try? h.seek(toOffset: UInt64(read))) != nil { since = (try? h.readToEnd()) ?? Data() }
            try? h.close()
        }
        try? (kept + since).write(to: url, options: .atomic)
    }

    /// The newest `keep` bytes of a log, from the first whole line in them.
    nonisolated static func trimmed(_ data: Data) -> Data {
        guard data.count > keep else { return data }
        let tail = data.suffix(keep)
        return tail.firstIndex(of: 0x0A).map { tail[($0 + 1)...] } ?? tail
    }
    private static let clock = {
        let f = DateFormatter()
        // The log is read on the Mac: its stamps never take a locale's digits or calendar.
        f.locale = Locale(identifier: "en_US_POSIX")
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
