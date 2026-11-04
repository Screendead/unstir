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
        XCTAssertEqual(Taps.learnt(in: d, build: "1-5", os: "27.2"), [phone: .init(budget: 28, limit: 40)], "the older build's is gone")
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
        XCTAssertTrue(Taps.built, "on by default (taps-keep = C)")
        XCTAssertEqual(Taps.mode(env: ProcessInfo.processInfo.environment, harnessed: false, simulator: false, built: Taps.built), .off,
                       "the test host draws the static limit in a build with it on")
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
        for _ in 0..<Taps.cuts.near { taps.frame(miss) }
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

    /// A glass keeps only what its own drags decided: a start lowered by a neighbour's step is never stored as learnt,
    /// so once the neighbour climbs back the glass starts from its own static limit again.
    @MainActor
    func testAnInheritedStartIsNeverKept() throws {
        let d = try XCTUnwrap(UserDefaults(suiteName: "TapsKeep"))
        d.removePersistentDomain(forName: "TapsKeep")
        defer { d.removePersistentDomain(forName: "TapsKeep") }
        let ids = Taps(rate: { 120 }, defaults: d)
        let phone = TapKey(hz: 120, pixels: Tank.tunedPixels), duo = TapKey(hz: 120, pixels: 1471), period = 1.0 / 120
        func stored(_ applied: Int) -> TapLaw.Stored {
            .init(applied: applied, cap: nil, strikes: 0, build: ids.build, os: ids.os, limit: 40)
        }
        func drag(_ taps: Taps, work: Int, _ f: FrameWatch.Frame, _ n: Int) {
            taps.window(TapWindow(pixels: 1471, work: work, held: "rod 0", picture: "grid"))
            for _ in 0..<n { taps.frame(f) }
            taps.window(nil)
            taps.still(pixels: 1471, "move")
        }
        let onTime = FrameWatch.Frame(interval: period, period: period, cpu: 0, age: 1, produced: true)
        Taps.save(stored(30), phone, to: d)
        let first = Taps(rate: { 120 }, defaults: d, thermal: { .nominal })
        first.use(.adapt(from: nil, stores: true))
        first.still(pixels: 1471, "open")
        XCTAssertEqual(first.budget(pixels: 1471), 12, "17 lowered as the phone stepped 40 to 30")
        drag(first, work: 10, onTime, 60)
        XCTAssertNil(d.object(forKey: duo.stored), "a drag that decided nothing keeps nothing")
        Taps.save(stored(40), phone, to: d)
        let later = Taps(rate: { 120 }, defaults: d, thermal: { .nominal })
        later.use(.adapt(from: nil, stores: true))
        later.still(pixels: 1471, "open")
        XCTAssertEqual(later.budget(pixels: 1471), 17, "the phone climbed back, so the Duo starts from its own limit")
        // A decision keeps, with the glass's own static limit.
        drag(later, work: 17, FrameWatch.Frame(interval: 2 * period, period: period, cpu: 0, age: 1, produced: true), Taps.cuts.near)
        let kept = try XCTUnwrap(Taps.load(duo, from: d, build: ids.build, os: ids.os))
        XCTAssertEqual([kept.applied, kept.limit], [16, 17])
    }

    /// Heat draws its own budget over an inherited start and gives it back, and neither is kept nor learnt.
    @MainActor
    func testHeatNeverKeepsAnInheritedStart() throws {
        let d = try XCTUnwrap(UserDefaults(suiteName: "TapsHeat"))
        d.removePersistentDomain(forName: "TapsHeat")
        defer { d.removePersistentDomain(forName: "TapsHeat") }
        var state = ProcessInfo.ThermalState.serious
        let taps = Taps(rate: { 120 }, defaults: d, thermal: { state })
        let phone = TapKey(hz: 120, pixels: Tank.tunedPixels), duo = TapKey(hz: 120, pixels: 1471), period = 1.0 / 120
        Taps.save(.init(applied: 35, cap: nil, strikes: 0, build: taps.build, os: taps.os, limit: 40), phone, to: d)
        taps.use(.adapt(from: nil, stores: true))
        taps.still(pixels: 1471, "open")
        XCTAssertEqual(taps.budget(pixels: 1471), 12, "17 lowered to 14 as the phone stepped, then a quarter off, at the floor")
        XCTAssertNil(d.object(forKey: duo.stored), "a hot start drawn at the level's opening keeps nothing")
        // A miss while hot, at the floor, steps nothing.
        taps.window(TapWindow(pixels: 1471, work: 12, held: "rod 0", picture: "grid"))
        for _ in 0..<Taps.cuts.near { taps.frame(FrameWatch.Frame(interval: 2 * period, period: period, cpu: 0, age: 1, produced: true)) }
        taps.window(nil)
        taps.still(pixels: 1471, "move")
        XCTAssertNil(d.object(forKey: duo.stored))
        state = .nominal
        taps.heat(state)
        taps.still(pixels: 1471, "move")
        XCTAssertEqual(taps.budget(pixels: 1471), 14, "the cool start back")
        XCTAssertNil(d.object(forKey: duo.stored), "nor once it cools")
        XCTAssertFalse(taps.summary.contains(duo.name), "nor learnt for this launch: \(taps.summary)")
    }

    /// A step taken back to an inherited start unlearns the glass: the start is never kept as its own.
    @MainActor
    func testARevertToAnInheritedStartUnlearnsTheGlass() throws {
        let d = try XCTUnwrap(UserDefaults(suiteName: "TapsRevert"))
        d.removePersistentDomain(forName: "TapsRevert")
        defer { d.removePersistentDomain(forName: "TapsRevert") }
        let taps = Taps(rate: { 120 }, defaults: d, thermal: { .nominal })
        let phone = TapKey(hz: 120, pixels: Tank.tunedPixels), duo = TapKey(hz: 120, pixels: 1471), period = 1.0 / 120
        let miss = FrameWatch.Frame(interval: 2 * period, period: period, cpu: 0, age: 1, produced: true)
        func stored(_ applied: Int) -> TapLaw.Stored {
            .init(applied: applied, cap: nil, strikes: 0, build: taps.build, os: taps.os, limit: 40)
        }
        func drag(_ t: Taps, work: Int, _ n: Int) {
            t.window(TapWindow(pixels: 1471, work: work, held: "rod 0", picture: "grid"))
            for _ in 0..<n { t.frame(miss) }
            t.window(nil)
            t.still(pixels: 1471, "move")
        }
        Taps.save(stored(35), phone, to: d)
        taps.use(.adapt(from: nil, stores: true))
        taps.still(pixels: 1471, "open")
        XCTAssertEqual(taps.budget(pixels: 1471), 14, "17 lowered as the phone stepped 40 to 35")
        drag(taps, work: 14, Taps.cuts.near)
        XCTAssertEqual(taps.budget(pixels: 1471), 13)
        XCTAssertEqual(Taps.load(duo, from: d, build: taps.build, os: taps.os)?.applied, 13, "a step is the Duo's own")
        drag(taps, work: 14, Taps.cuts.near)
        XCTAssertEqual(taps.budget(pixels: 1471), 14, "two taps missed as often: the step taken back")
        XCTAssertNil(d.object(forKey: duo.stored), "back at the inherited start, nothing of the Duo's is kept")
        XCTAssertFalse(taps.summary.contains(duo.name), "nor learnt: \(taps.summary)")
        Taps.save(stored(40), phone, to: d)
        let later = Taps(rate: { 120 }, defaults: d, thermal: { .nominal })
        later.use(.adapt(from: nil, stores: true))
        later.still(pixels: 1471, "open")
        XCTAssertEqual(later.budget(pixels: 1471), 17)
    }
}
