// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

@MainActor
final class AgeCheckTests: XCTestCase {
    func testTheRangeIsAskedOnlyOnTheMenuWhereTheLawReachesThePlayer() {
        XCTAssertTrue(AgeCheck.ready(eligible: true, menu: true, played: true))
        XCTAssertFalse(AgeCheck.ready(eligible: false, menu: true, played: true), "no law, no question")
        XCTAssertFalse(AgeCheck.ready(eligible: true, menu: false, played: true), "never over a level or card")
        XCTAssertFalse(AgeCheck.ready(eligible: true, menu: true, played: false), "never the harness's")
    }

    @MainActor final class Count { var n = 0 }

    func testACancelledRequestLeavesTheLaunchsAskStanding() async {
        AgeCheck.asked = false
        defer { AgeCheck.asked = false }
        let requests = Count()

        let settling = Task { await AgeCheck.ask { requests.n += 1 } }
        settling.cancel()
        await settling.value
        XCTAssertFalse(AgeCheck.asked, "a menu covered or left as it settles keeps the ask")
        XCTAssertEqual(requests.n, 0)

        let showing = Task { await AgeCheck.ask { requests.n += 1; try? await Task.sleep(for: .seconds(30)) } }
        try? await Task.sleep(for: AgeCheck.settle * 2)
        showing.cancel()
        await showing.value
        XCTAssertFalse(AgeCheck.asked, "a request cut off keeps the ask")
        XCTAssertEqual(requests.n, 1)

        await AgeCheck.ask { requests.n += 1 }
        XCTAssertTrue(AgeCheck.asked)
        await AgeCheck.ask { requests.n += 1 }
        XCTAssertEqual(requests.n, 2, "once a launch")
    }
}
