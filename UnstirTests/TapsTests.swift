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
        XCTAssertEqual(Taps.mode(env: [:], harnessed: false, simulator: false, built: true), .adapt(from: nil, stores: true),
                       "a plain launch of a build with ADAPTIVE_TAPS")
        XCTAssertEqual(Taps.mode(env: [:], harnessed: false, simulator: false, built: false), .off, "v1's")
        XCTAssertFalse(Taps.built, "off until the phone gate passes")
        XCTAssertEqual(Taps.mode(env: [:], harnessed: true, simulator: false, built: true), .off)
        XCTAssertEqual(Taps.mode(env: [:], harnessed: false, simulator: true, built: true), .off)
        XCTAssertEqual(Taps.mode(env: ["XCTestConfigurationFilePath": "x"], harnessed: false, simulator: false, built: true), .off)
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "24"], harnessed: true, simulator: true, built: false), .pinned(24))
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "watch:42"], harnessed: true, simulator: false, built: false), .watch(42))
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "adapt"], harnessed: false, simulator: false, built: false),
                       .adapt(from: nil, stores: false))
        XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": "adapt:42"], harnessed: true, simulator: true, built: false),
                       .adapt(from: 42, stores: false))
        // A value it can't read never falls through to the law that keeps what it learns.
        for bad in ["watch", "watch:x", "adapt:", "adapt:x", "lots", "", "24:1", "pinned:24"] {
            XCTAssertEqual(Taps.mode(env: ["UNSTIR_TAPS": bad], harnessed: false, simulator: false, built: true), .off, bad)
        }
        // UNSTIR_TAPS leaves a phone's launch a plain one, as UNSTIR_ANALYTICS does.
        XCTAssertFalse(Harness(["UNSTIR_TAPS": "adapt"]).harnessed)
        XCTAssertTrue(Harness(["UNSTIR_TAPS": "30", "UNSTIR_LEVEL": "3"]).harnessed)
    }

    /// The glass draws what its last still moment chose: neither a step decided mid-drag nor a change of the screen's
    /// rate reaches it before the next.
    @MainActor
    func testTheGlassDrawsWhatItsLastStillMomentChose() {
        var hz = 120
        let taps = Taps(rate: { hz })
        taps.use(.adapt(from: 30, stores: false))
        let px = Tank.tunedPixels, period = 1.0 / 120
        let miss = FrameWatch.Frame(interval: 2 * period, period: period, cpu: 0, age: 1, produced: true)
        XCTAssertNil(taps.budget(pixels: px), "the static limit until the level appears")
        taps.still(pixels: px, "open")
        XCTAssertEqual(taps.budget(pixels: px), 30)
        taps.window(TapWindow(pixels: px, work: 29, held: "rod 0", picture: "grid"))
        for _ in 0..<3 { taps.frame(miss) }
        hz = 144
        XCTAssertEqual(taps.budget(pixels: px), 30, "decided, not drawn")
        taps.still(pixels: px, "move")
        XCTAssertEqual(taps.budget(pixels: px), 30, "not while the drag is open")
        taps.window(nil)
        XCTAssertEqual(taps.budget(pixels: px), 30)
        hz = 120
        taps.still(pixels: px, "move")
        XCTAssertEqual(taps.budget(pixels: px), 28)
        // A new top rate keys the glass afresh, at a still moment only; a lower one, as Low Power Mode caps it, never.
        hz = 144
        taps.window(TapWindow(pixels: px, work: 20, held: "rod 0", picture: "grid"))
        taps.window(nil)
        XCTAssertEqual(taps.budget(pixels: px), 28, "a drag on the glass is judged by its own law")
        taps.still(pixels: px, "move")
        XCTAssertEqual(taps.budget(pixels: px), 30, "the 144 Hz glass's own start")
        hz = 60
        taps.still(pixels: px, "move")
        XCTAssertEqual(taps.budget(pixels: px), 30)
    }
}
