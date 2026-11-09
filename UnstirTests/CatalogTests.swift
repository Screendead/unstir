// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class CatalogTests: XCTestCase {
    /// `scripts/loc-lint.sh` in the suite: every line of Sources/ that scripts/loc-lint/patterns.txt flags is in
    /// scripts/loc-lint/baseline.txt, and every baseline line is still flagged, so a fix takes its line out.
    func testNoPlayerStringEscapesTheCatalog() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let lint = root.appending(path: "scripts/loc-lint")
        var call: [String] = [], allow: [String] = [], any: [String] = []
        for line in try String(contentsOf: lint.appending(path: "patterns.txt"), encoding: .utf8).split(separator: "\n")
        where !line.hasPrefix("#") {
            let (kind, re) = (line.prefix { $0 != " " }, String(line.drop { $0 != " " }.dropFirst()))
            switch kind {
            case "call": call.append(re)
            case "allow": allow.append(re)
            case "any": any.append(re)
            default: XCTFail("bad line: \(line)")
            }
        }
        let calls = "(?:\(call.joined(separator: "|")))(?!\(allow.joined(separator: "|")))"
        let flag = try NSRegularExpression(pattern: ([calls] + any).joined(separator: "|"))

        let sources = root.appending(path: "Sources")
        let files = try FileManager.default.contentsOfDirectory(atPath: sources.path).filter { $0.hasSuffix(".swift") }.sorted()
        var found: [String] = []
        for file in files {
            for raw in try String(contentsOf: sources.appending(path: file), encoding: .utf8).split(separator: "\n",
                                                                                                     omittingEmptySubsequences: false) {
                let line = raw.trimmingCharacters(in: .whitespaces)
                guard !line.hasPrefix("//"), !line.contains("// loc: verbatim") else { continue }
                if flag.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil { found.append("\(file): \(line)") }
            }
        }

        var left: [String: Int] = [:]
        for line in try String(contentsOf: lint.appending(path: "baseline.txt"), encoding: .utf8).split(separator: "\n")
        where !line.hasPrefix("#") {
            left[String(line), default: 0] += 1
        }
        for line in found {
            if let n = left[line], n > 0 { left[line] = n - 1 } else { XCTFail("escape: \(line)") }
        }
        for (line, n) in left where n > 0 { XCTFail("fixed, take it out of the baseline: \(line)") }
        XCTAssertGreaterThan(files.count, 40)
    }

}
