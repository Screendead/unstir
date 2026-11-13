// Copyright © 2026 Jack Lusher. All rights reserved.

import Observation
import SwiftUI
import XCTest
@testable import Unstir

final class HandTests: XCTestCase {
    private final class Told: @unchecked Sendable {
        var n = 0
    }

    /// What `LevelView.body` reads of the turn in hand (`steps`, `turnSteps`, `turning`, `spun`) changes only with a
    /// count, so a frame of a drag that crosses none tells the play screen nothing.
    @MainActor func testATurnInHandTellsThePlayScreenOnlyAsACountChanges() {
        let hand = Hand(tankStep: .pi / 3)
        let told = Told()
        func watch() {
            withObservationTracking { _ = (hand.steps, hand.turnSteps, hand.turning, hand.spun) } onChange: { told.n += 1 }
        }
        watch()
        hand.angle = 0.2 * Tank.step
        hand.angle = 0.4 * Tank.step
        hand.finger = SIMD2(0.1, 0.2)
        hand.last = 1
        XCTAssertEqual(told.n, 0)
        hand.angle = 0.6 * Tank.step
        XCTAssertEqual(told.n, 1)
        XCTAssertEqual(hand.steps, 1)

        watch()
        hand.turn = 0.1
        XCTAssertEqual(told.n, 1, "the tank's turn counts only while it is held")
        hand.turning = true
        XCTAssertEqual(told.n, 2)
        watch()
        hand.turn = 0.2
        hand.spin = 0.1
        XCTAssertEqual(told.n, 2)
        XCTAssertEqual(hand.turnSteps, 0)
        hand.turn = 0.6 * .pi / 3
        XCTAssertEqual(told.n, 3)
        XCTAssertEqual(hand.turnSteps, 1)
        XCTAssertEqual(hand.held, 0.6 * .pi / 3)
    }

    /// The parts that draw the turn are told of every change of it, and of none where it is set to what it is.
    @MainActor func testATurnInHandTellsWhatDrawsItOfEveryChange() {
        let hand = Hand(tankStep: .pi / 3)
        let told = Told()
        func watch() {
            withObservationTracking { _ = (hand.angle, hand.held) } onChange: { told.n += 1 }
        }
        watch()
        hand.angle = 0
        XCTAssertEqual(told.n, 0)
        hand.angle = 0.01
        XCTAssertEqual(told.n, 1)
        watch()
        hand.turning = true
        XCTAssertEqual(told.n, 2)
        watch()
        hand.turn = 0.01
        XCTAssertEqual(told.n, 3)
    }

    /// `Unstirred.draws(sameAs:)` lets the level's glass skip a frame's arguments where nothing changed, so it reads
    /// every stored field: a new one changes the count here, and joins the comparison and this list.
    @MainActor func testTheGlassComparesEveryField() throws {
        let fine = try XCTUnwrap(Fine(Halftone.test.detail(64, lenses: [])))
        let glass = Unstirred(stack: [], layout: .tri, liveAngle: 0, side: 100)
        let changes: [(inout Unstirred) -> Void] = [
            { $0.stack = [Twist(rod: 0, steps: 1)] }, { $0.layout = .quad }, { $0.lenses = [0] }, { $0.masks = [0: .red] },
            { $0.liveRod = 0 }, { $0.liveAngle = 1 }, { $0.wind = 0.5 }, { $0.shares = [1] }, { $0.side = 200 },
            { $0.haze = 0.5 }, { $0.turn = 1 }, { $0.wave = SIMD3(0, 0, 1) }, { $0.fillEntries = 4 },
            { $0.breath = (0, 1) }, { $0.tick = (0, 1) }, { $0.isolate = .red }, { $0.whiteIsolate = true },
            { $0.held = .red }, { $0.hold = 1 }, { $0.budget = 30 }, { $0.fine = fine }, { $0.crisp = 1 },
        ]
        // Each field, and the environment's scale.
        XCTAssertEqual(Mirror(reflecting: glass).children.count, changes.count + 1)
        XCTAssertTrue(glass.draws(sameAs: glass))
        for (i, change) in changes.enumerated() {
            var other = glass
            change(&other)
            XCTAssertFalse(glass.draws(sameAs: other), "field \(i)")
        }
    }
}
