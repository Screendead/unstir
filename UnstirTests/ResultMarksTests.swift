// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// The result's marks (Jack's calls C9 = B and D3 = A): each stored best fills as many discs as it earned, and
/// VoiceOver says the same result in words.
final class ResultMarksTests: XCTestCase {
    func testEachResultFillsItsMarksAndSaysThem() {
        let level = Level.plughole[0]
        func row(_ best: Best?, started: Bool) -> (filled: Int?, spoken: String) {
            (ResultMarks.filled(Archive.Mark(best, started: started)),
             Spoken.row(level, result: best, tanks: 0, detail: nil, enabled: true, needs: nil, started: started).value)
        }
        let cases: [(Best?, Bool, Int?, String)] = [
            (Best(over: 0, seconds: 9, clean: true), true, 3, "clean"),
            (Best(over: 0, seconds: 9, clean: false), true, 2, "at par"),
            (Best(over: 0, seconds: 9), true, 2, "at par"),
            (Best(over: 2, seconds: 9), true, 1, "solved, 2 over par"),
            (nil, true, 0, "tried"),
            (nil, false, nil, "not played"),
        ]
        for (best, started, filled, spoken) in cases {
            let got = row(best, started: started)
            XCTAssertEqual(got.filled, filled, spoken)
            XCTAssertEqual(got.spoken, spoken)
        }
        // An archived daily's best fills as the day's own would.
        XCTAssertEqual(ResultMarks.filled(Archive.Mark(Best(over: 0, seconds: 9, clean: true, archived: true), started: true)), 3)
    }

    /// The card marks this solve: clean only with nothing wasted on a first try, which `Game.clean` already holds.
    func testTheCardMarksThisSolve() {
        XCTAssertEqual(ResultMarks.filled(clean: true, over: 0), 3)
        XCTAssertEqual(ResultMarks.filled(clean: false, over: 0), 2)
        XCTAssertEqual(ResultMarks.filled(clean: false, over: 3), 1)
    }
}
