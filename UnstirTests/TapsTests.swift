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
        XCTAssertEqual(Taps.kept(in: d, build: "1-5", os: "27.2"), [phone: 28], "the older build's is gone")
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

    /// A drag on a glass drawn from its stored map draws four taps whatever the budget, so its misses step nothing.
    @MainActor
    func testADragOverTheMapStepsNothing() {
        let taps = Taps(rate: { 120 })
        taps.use(.adapt(from: 30, stores: false))
        let px = Tank.tunedPixels, period = 1.0 / 120
        let miss = FrameWatch.Frame(interval: 2 * period, period: period, cpu: 0, age: 1, produced: true)
        taps.still(pixels: px, "open")
        taps.window(TapWindow(pixels: px, work: 29, held: "rod 0", picture: "grid", mapped: true))
        for _ in 0..<(4 * Taps.cuts.near) { taps.frame(miss) }
        taps.window(nil)
        taps.still(pixels: px, "move")
        XCTAssertEqual(taps.budget(pixels: px), 30)
        taps.window(TapWindow(pixels: px, work: 29, held: "rod 0", picture: "grid"))
        for _ in 0..<Taps.cuts.near { taps.frame(miss) }
        taps.window(nil)
        taps.still(pixels: px, "move")
        XCTAssertEqual(taps.budget(pixels: px), 28, "the same misses through the chain step it down")
    }

    /// Every new glass starts at its own static limit, whatever other glasses have kept (Jack's call taps-keep = C).
    @MainActor
    func testAFreshGlassStartsAtItsStaticLimitWhateverOthersKept() throws {
        let d = try XCTUnwrap(UserDefaults(suiteName: "TapsFresh"))
        d.removePersistentDomain(forName: "TapsFresh")
        defer { d.removePersistentDomain(forName: "TapsFresh") }
        let taps = Taps(rate: { 120 }, defaults: d, thermal: { .nominal })
        for (px, b) in [(Tank.tunedPixels, 12), (984.0, 12), (1302.0, 12), (1200.0, 42)] {
            Taps.save(.init(applied: b, cap: nil, strikes: 0, build: taps.build, os: taps.os), TapKey(hz: 120, pixels: px), to: d)
        }
        taps.use(.adapt(from: nil, stores: true))
        for (px, b) in [(1471.0, 23), (1171.3, 40), (1334.0, 28), (656.5, 40)] {
            taps.still(pixels: px, "open")
            XCTAssertEqual(taps.budget(pixels: px), b, "\(px) px")
        }
        taps.still(pixels: Tank.tunedPixels, "open")
        XCTAssertEqual(taps.budget(pixels: Tank.tunedPixels), 12, "a glass's own kept budget is its own")
        // Glasses sharing a key start at the lowest static limit among them, whichever comes first: 1450 px alone
        // would have 24, 1460 px 23.
        XCTAssertEqual([Tank.fourTaps(pixels: 1450), Tank.fourTaps(pixels: 1460)], [24, 23])
        XCTAssertEqual(TapKey(hz: 120, pixels: 1450), TapKey(hz: 120, pixels: 1460))
        for order in [[1450.0, 1460], [1460, 1450]] {
            let t = Taps(rate: { 120 }, defaults: d, thermal: { .nominal })
            t.use(.adapt(from: nil, stores: false))
            for px in order {
                t.still(pixels: px, "open")
                XCTAssertEqual(t.budget(pixels: px), 23, "\(order): \(px) px")
            }
        }
    }

    /// A glass keeps what its own drags decide, and only that: a drag that decides nothing writes nothing, a step is
    /// kept and reloaded, and heat over it is drawn but never kept.
    @MainActor
    func testAGlassKeepsAndReloadsItsOwnDecisions() throws {
        let d = try XCTUnwrap(UserDefaults(suiteName: "TapsOwn"))
        d.removePersistentDomain(forName: "TapsOwn")
        defer { d.removePersistentDomain(forName: "TapsOwn") }
        var state = ProcessInfo.ThermalState.nominal
        let duo = TapKey(hz: 120, pixels: 1471), period = 1.0 / 120
        let onTime = FrameWatch.Frame(interval: period, period: period, cpu: 0, age: 1, produced: true)
        let miss = FrameWatch.Frame(interval: 2 * period, period: period, cpu: 0, age: 1, produced: true)
        func drag(_ t: Taps, work: Int, _ f: FrameWatch.Frame, _ n: Int) {
            t.window(TapWindow(pixels: 1471, work: work, held: "rod 0", picture: "grid"))
            for _ in 0..<n { t.frame(f) }
            t.window(nil)
            t.still(pixels: 1471, "move")
        }
        let first = Taps(rate: { 120 }, defaults: d, thermal: { state })
        first.use(.adapt(from: nil, stores: true))
        first.still(pixels: 1471, "open")
        XCTAssertEqual(first.budget(pixels: 1471), 23)
        drag(first, work: 10, onTime, 60)
        XCTAssertNil(d.object(forKey: duo.stored), "a drag that decided nothing keeps nothing")
        drag(first, work: 23, miss, Taps.cuts.near)
        XCTAssertEqual(first.budget(pixels: 1471), 22)
        XCTAssertEqual(Taps.load(duo, from: d, build: first.build, os: first.os)?.applied, 22, "its own step")
        XCTAssertTrue(first.summary.contains("\(duo.name) 22"), first.summary)
        state = .serious
        let later = Taps(rate: { 120 }, defaults: d, thermal: { state })
        later.use(.adapt(from: nil, stores: true))
        later.still(pixels: 1471, "open")
        XCTAssertEqual(later.budget(pixels: 1471), 16, "reloaded at 22, a quarter off while hot")
        XCTAssertEqual(Taps.load(duo, from: d, build: later.build, os: later.os)?.applied, 22, "heat is never kept")
        state = .nominal
        later.heat(state)
        later.still(pixels: 1471, "move")
        XCTAssertEqual(later.budget(pixels: 1471), 22)
        XCTAssertEqual(Taps.load(duo, from: d, build: later.build, os: later.os)?.applied, 22)
    }

    /// A glass first met mid-drag, by a change of pose, draws its law's budget once the drag ends, a let-go that lands
    /// no move included.
    @MainActor
    func testAGlassMetMidDragDrawsItsLawOnceTheDragEnds() throws {
        let d = try XCTUnwrap(UserDefaults(suiteName: "TapsPose"))
        d.removePersistentDomain(forName: "TapsPose")
        defer { d.removePersistentDomain(forName: "TapsPose") }
        let taps = Taps(rate: { 120 }, defaults: d, thermal: { .nominal })
        let duo = TapKey(hz: 120, pixels: 1471)
        Taps.save(.init(applied: 20, cap: nil, strikes: 0, build: taps.build, os: taps.os), duo, to: d)
        taps.use(.adapt(from: nil, stores: true))
        taps.still(pixels: Tank.tunedPixels, "open")
        taps.window(TapWindow(pixels: Tank.tunedPixels, work: 20, held: "rod 0", picture: "grid"))
        // The pose changes under the finger: the hooks hand over the new glass's window, and its still moment returns
        // early, as a drag is open.
        taps.window(TapWindow(pixels: 1471, work: 20, held: "rod 0", picture: "grid"))
        taps.still(pixels: 1471, "pose")
        XCTAssertNil(taps.budget(pixels: 1471), "nothing lands mid-drag")
        taps.window(nil)
        XCTAssertEqual(taps.budget(pixels: 1471), 20, "its kept budget, not the static 23, once the drag is over")
    }
}
