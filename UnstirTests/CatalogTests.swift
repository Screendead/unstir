// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class CatalogTests: XCTestCase {
    /// `scripts/loc-lint.sh` in the suite: no line of Sources/ is flagged by scripts/loc-lint/patterns.txt.
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

        for line in found { XCTFail("escape: \(line)") }
        XCTAssertGreaterThan(files.count, 40)
    }

    /// A plural key reads its `one` form at 1, which only its catalog entry gives.
    func testACountOfOneIsSingular() {
        let endless = Level.endless(Run(seed: 7))
        XCTAssertEqual(Spoken.row(endless, result: nil, tanks: 1, detail: nil, enabled: true, needs: nil).value, "best 1 tank")
        XCTAssertEqual(Spoken.row(endless, result: nil, tanks: 1, detail: nil, enabled: true, needs: nil, started: true).value,
                       "run in progress, best 1 tank")
        XCTAssertEqual(String(localized: "\(1) \(Tier.plughole.word) levels short of par", comment: "Short of par"),
                       "1 plughole level short of par")
        XCTAssertEqual(String(localized: "\(2) \(Tier.plughole.word) levels short of par", comment: "Short of par"),
                       "2 plughole levels short of par")
    }

    /// The chrome's words read as the hand-built English they replaced.
    func testChromeReadsItsEnglish() {
        for tier in Tier.allCases { XCTAssertEqual(tier.word, tier.rawValue) }
        XCTAssertEqual(ConsentWords.sends, "If you say yes, the game tells us how you play: which puzzles you finish, how many "
            + "moves and undos they take, which days you play, which packs you buy, and roughly which country you're in. "
            + "It never sends your name, your Apple ID, or anything that tells us who you are. You can change your mind "
            + "any time in settings.")
        XCTAssertEqual(String(localized: ConsentWords.letters), "colour letters")
        XCTAssertEqual(ConsentWords.letters.key, "colour letters")
        XCTAssertEqual(Level.endless(Run(seed: 7)).back, "\u{2039} levels")
        XCTAssertEqual(Offer.pack(.lens).holds, "25 panels in four issues")
        XCTAssertEqual(Offer.countWord(3), "three")
        XCTAssertEqual(PackCard.back(to: PackCard.menu, beside: true).text, "\u{2715} close")
        XCTAssertEqual(PackCard.back(to: PackCard.menu, beside: false).text, "\u{2039} menu")
        XCTAssertEqual(Purchase.revoked.tag(unshared: true)?.word, "no longer shared with you")
        XCTAssertEqual(LevelView.layoutLabel(.quad, named: true), "rods: 4 \u{00B7} quad \u{203A}")
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
