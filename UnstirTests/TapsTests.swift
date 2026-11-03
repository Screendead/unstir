// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// The adaptive four-tap budget's controller: when frames count, what a phone keeps and when the harness measures.
final class TapsTests: XCTestCase {
    func testFramesTheSystemCappedOrAPoseMovedSayNothing() {
        XCTAssertNil(Taps.frozen(period: 1.0 / 120, hz: 120, sincePose: 5))
        XCTAssertEqual(Taps.frozen(period: 1.0 / 60, hz: 120, sincePose: 5), "granted 60 of 120 Hz")
        XCTAssertNil(Taps.frozen(period: 1.0 / 60, hz: 60, sincePose: 5), "a 60 Hz screen is judged against its own")
        XCTAssertEqual(Taps.frozen(period: 1.0 / 120, hz: 120, sincePose: 0.5), "pose")
    }

    func testAKeptGlassIsDroppedByANewBuildOrOS() throws {
        let d = try XCTUnwrap(UserDefaults(suiteName: "TapsTests"))
        d.removePersistentDomain(forName: "TapsTests")
        defer { d.removePersistentDomain(forName: "TapsTests") }
        let phone = TapKey(hz: 120, pixels: 1137), duo = TapKey(hz: 120, pixels: 1471)
        XCTAssertEqual(phone.stored, "taps.120.1136")
        Taps.save(.init(applied: 28, cap: 29, strikes: 1, build: "1-5", os: "27.2"), phone, to: d)
        Taps.save(.init(applied: 20, cap: nil, strikes: 0, build: "1-4", os: "27.2"), duo, to: d)
        d.set(true, forKey: "taps.unrelated")
        XCTAssertEqual(Taps.load(phone, from: d, build: "1-5", os: "27.2")?.applied, 28)
        XCTAssertEqual(Taps.learnt(in: d, build: "1-5", os: "27.2"), [phone: 28], "the older build's is gone")
        XCTAssertNil(d.object(forKey: duo.stored))
        XCTAssertNil(Taps.load(phone, from: d, build: "1-5", os: "27.3"))
        XCTAssertNil(d.object(forKey: phone.stored), "a new OS drops it")
        XCTAssertNotNil(d.object(forKey: "taps.unrelated"))
        XCTAssertEqual(TapLaw(stored: .init(applied: 28, cap: 29, strikes: 1, build: "", os: "")).applied, 28)
    }

    func testShotsAndTheTestHostDrawTheStaticLimitUnlessPinned() {
        XCTAssertEqual(Taps.mode(env: [:], harnessed: false, simulator: false), .adapt(from: nil, stores: true), "a plain launch")
        XCTAssertEqual(Taps.mode(env: [:], harnessed: true, simulator: false), .off)
        XCTAssertEqual(Taps.mode(env: [:], harnessed: false, simulator: true), .off)
        XCTAssertEqual(Taps.mode(env: ["XCTestConfigurationFilePath": "x"], harnessed: false, simulator: false), .off)
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "24"], harnessed: true, simulator: true), .pinned(24))
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "watch:42"], harnessed: true, simulator: false), .watch(42))
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "watch"], harnessed: true, simulator: false), .off)
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "adapt"], harnessed: false, simulator: false), .adapt(from: nil, stores: false))
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "adapt:42"], harnessed: true, simulator: true), .adapt(from: 42, stores: false))
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "lots"], harnessed: true, simulator: false), .off)
        // UNSTIR_TAPS leaves a phone's launch a plain one, as UNSTIR_ANALYTICS does.
        XCTAssertFalse(Harness(["UNSTIR_TAPS": "adapt"]).harnessed)
        XCTAssertTrue(Harness(["UNSTIR_TAPS": "30", "UNSTIR_LEVEL": "3"]).harnessed)
    }
}
