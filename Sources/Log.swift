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
}

extension Twist: CustomStringConvertible {
    var description: String { String(format: "%d:%+d", rod, steps) }
}
