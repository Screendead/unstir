// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

final class AgeCheckTests: XCTestCase {
    func testTheRangeIsAskedOnceOnTheMenuWhereTheLawReachesThePlayer() {
        XCTAssertTrue(AgeCheck.due(eligible: true, asked: false, menu: true, played: true))
        XCTAssertFalse(AgeCheck.due(eligible: false, asked: false, menu: true, played: true), "no law, no question")
        XCTAssertFalse(AgeCheck.due(eligible: true, asked: true, menu: true, played: true), "once a launch")
        XCTAssertFalse(AgeCheck.due(eligible: true, asked: false, menu: false, played: true), "never over a level or card")
        XCTAssertFalse(AgeCheck.due(eligible: true, asked: false, menu: true, played: false), "never the harness's")
    }
}
