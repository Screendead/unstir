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

    /// A plural key reads its `one` form at 1, which only its catalog entry gives.
    func testACountOfOneIsSingular() {
        let endless = Level.endless(Run(seed: 7))
        XCTAssertEqual(Spoken.row(endless, result: nil, tanks: 1, detail: nil, enabled: true, needs: nil).value, "best 1 tank")
        XCTAssertEqual(Spoken.row(endless, result: nil, tanks: 1, detail: nil, enabled: true, needs: nil, started: true).value,
                       "run in progress, best 1 tank")
    }

    /// A table's id-keyed string reads its English default, which the catalog may not hold.
    func testTablesReadTheirEnglish() {
        XCTAssertEqual(Level.plughole[0].title, "Drop")
        XCTAssertEqual(Level.plughole[0].note, "Turn a rod to look. Let go where you started and nothing happens.")
        XCTAssertEqual(Level.maelstrom[26].title, "Abyss")
        XCTAssertEqual(Tier.whirlpool.name, "Whirlpool")
        XCTAssertEqual(Level.lens[0].title, "Keyhole")
        XCTAssertEqual(Level.lens[0].chapter, "Close-up")
        XCTAssertEqual(Level.escapement[0].note, "Unstir in \(Level.escapement[0].budget) ticks. A clock ticks after every move. Each let-go is a move.")
        XCTAssertEqual(Level.escapement[1].note, "Unstir in \(Level.escapement[1].budget) ticks. Tap wait: the clock ticks, nothing turns.")
        XCTAssertEqual(Level.escapement[2].note, "Unstir in \(Level.escapement[2].budget) ticks.")
        XCTAssertEqual(Level.prism[0].chapter, "Two Colours")
        XCTAssertEqual(Level.prism[0].note, "Each rod stirs only its knob's colours.")
    }

    /// A picture's and a layout's display name reads as its raw value did on the sandbox's controls.
    func testDisplayNamesReadAsTheirRawValues() {
        for picture in Picture.allCases { XCTAssertEqual(String(localized: picture.display), picture.rawValue) }
        for layout in Layout.allCases + Layout.swirls { XCTAssertEqual(String(localized: layout.display), layout.rawValue) }
    }
}
