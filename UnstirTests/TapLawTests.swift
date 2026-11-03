// Copyright © 2026 Jack Lusher. All rights reserved.

import XCTest
@testable import Unstir

/// The adaptive four-tap budget's law on synthetic frames, and the priors a glass starts from. Nothing here is timed.
final class TapLawTests: XCTestCase {
    private let period = 1.0 / 120

    /// `n` frames of class `c` into the open window, and every event they raise.
    @discardableResult
    private func feed(_ law: inout TapLaw, _ c: FrameClass, _ n: Int) -> [TapLaw.Event] {
        (0..<n).compactMap { _ in law.count(c) }
    }

    /// A window at `work` with `n` frames of `c`, closed, then the still moment after it.
    @discardableResult
    private func drag(_ law: inout TapLaw, at work: Int, _ c: FrameClass, _ n: Int) -> [TapLaw.Event] {
        law.open(work: work)
        let events = feed(&law, c, n) + [law.close()].compactMap { $0 }
        return events + [law.still()].compactMap { $0 }
    }

    func testAFrameIsLatePastHalfAPeriodAndBlamedByTheMainThreadsShare() {
        let t = period
        XCTAssertEqual(TapLaw.classify(interval: 1.5 * t, period: t, cpu: 0, produced: true), .onTime, "a vsync not yet skipped")
        XCTAssertEqual(TapLaw.classify(interval: 1.5 * t + 1e-6, period: t, cpu: 0, produced: true), .gpuMiss)
        let d = 2 * t
        XCTAssertEqual(TapLaw.classify(interval: d, period: t, cpu: d - t / 2, produced: true), .cpuMiss, "busy all but half a period")
        XCTAssertEqual(TapLaw.classify(interval: d, period: t, cpu: d - t / 2 - 1e-6, produced: true), .ignored)
        XCTAssertEqual(TapLaw.classify(interval: d, period: t, cpu: d / 2, produced: true), .gpuMiss, "idle half the interval")
        XCTAssertEqual(TapLaw.classify(interval: d, period: t, cpu: d / 2 + 1e-6, produced: true), .ignored)
        XCTAssertEqual(TapLaw.classify(interval: 6 * t, period: t, cpu: 0, produced: true), .gpuMiss)
        XCTAssertEqual(TapLaw.classify(interval: 6 * t + 1e-6, period: t, cpu: 0, produced: true), .ignored,
                       "a stall no frame of the shader's makes")
        XCTAssertEqual(TapLaw.classify(interval: 3 * t, period: t, cpu: 0, produced: false), .ignored, "nothing moved")
        XCTAssertEqual(TapLaw.classify(interval: t, period: t, cpu: t, produced: false), .ignored)
        XCTAssertEqual(TapLaw.classify(interval: d, period: t, cpu: d, produced: true, cuts: .unattributed), .gpuMiss,
                       "the fallback blames every late frame")
    }

    func testThreeGPUMissesInThirtyStepDownAndOnlyAStillMomentDrawsIt() {
        var law = TapLaw(start: 30)
        law.open(work: 29)
        XCTAssertEqual(feed(&law, .onTime, 27), [])
        XCTAssertEqual(feed(&law, .gpuMiss, 2), [])
        XCTAssertEqual(feed(&law, .gpuMiss, 1), [.down(from: 30, to: 28, work: 29, misses: 3, of: 30, strike: 1)])
        XCTAssertEqual(law.pending, 28)
        XCTAssertEqual(law.applied, 30, "a drag never changes its own taps")
        XCTAssertNil(law.still(), "not while the window is open")
        XCTAssertNil(law.close())
        XCTAssertEqual(law.still(), .applied(from: 30, to: 28))
        XCTAssertEqual(law.applied, 28)
        XCTAssertNil(law.pending)
        XCTAssertEqual(law.stored(build: "b", os: "o"), .init(applied: 28, cap: 29, strikes: 1, build: "b", os: "o"))
    }

    func testTwoMissesMainThreadMissesAndTwoTapMissesStepNothing() {
        var law = TapLaw(start: 30)
        law.open(work: 29)
        feed(&law, .onTime, 28)
        XCTAssertEqual(feed(&law, .gpuMiss, 2), [], "two in thirty")
        XCTAssertEqual(feed(&law, .onTime, 30), [])
        XCTAssertEqual(feed(&law, .cpuMiss, 30), [], "the main thread's own")
        XCTAssertEqual(feed(&law, .ignored, 30), [])
        XCTAssertNil(law.close())
        law.open(work: 31)
        XCTAssertEqual(feed(&law, .gpuMiss, 30), [], "two taps already: a lower budget changes nothing")
        XCTAssertEqual(law.close(), .twoTap(work: 31, misses: 30, of: 30))
        XCTAssertNil(law.still())
        XCTAssertEqual(law.applied, 30)
    }

    func testMissesFarBelowTheBudgetNeedSix() {
        var law = TapLaw(start: 30)
        law.open(work: 26)
        XCTAssertEqual(feed(&law, .gpuMiss, 3).count, 1, "within four of the budget")
        law = TapLaw(start: 30)
        law.open(work: 25)
        XCTAssertEqual(feed(&law, .gpuMiss, 5), [])
        XCTAssertEqual(feed(&law, .gpuMiss, 1), [.down(from: 30, to: 24, work: 25, misses: 6, of: 6, strike: 1)])
        // Six among the last thirty, not since the drag began.
        law = TapLaw(start: 30)
        law.open(work: 25)
        for _ in 0..<5 {
            feed(&law, .gpuMiss, 1)
            feed(&law, .onTime, 6)
        }
        XCTAssertEqual(feed(&law, .gpuMiss, 1), [])
    }

    func testAStepStopsAtTheFloor() {
        var law = TapLaw(start: 13)
        XCTAssertEqual(drag(&law, at: 13, .gpuMiss, 3), [.down(from: 13, to: 12, work: 13, misses: 3, of: 3, strike: 1),
                                                       .applied(from: 13, to: 12)])
        XCTAssertEqual(drag(&law, at: 12, .gpuMiss, 30), [], "the floor holds")
        XCTAssertEqual(law.applied, TapLaw.floor)
        XCTAssertEqual(TapLaw(start: 3).applied, TapLaw.floor)
        XCTAssertEqual(TapLaw(start: 99).applied, TapLaw.ceiling)
        XCTAssertEqual(TapLaw.ceiling, Tank.maxStack + 6, "every stack on every picture, the twin neurons' fill the largest")
    }

    func testSixHundredCleanFramesAtTheEdgeStepUpOne() {
        var law = TapLaw(start: 30)
        law.open(work: 29)
        XCTAssertEqual(feed(&law, .onTime, 599), [])
        XCTAssertEqual(feed(&law, .onTime, 1), [.up(from: 30, to: 31)])
        XCTAssertEqual(law.applied, 30)
        XCTAssertEqual(feed(&law, .onTime, 900), [], "one step until it is drawn")
        XCTAssertNil(law.close())
        XCTAssertEqual(law.still(), .applied(from: 30, to: 31))
        // Evidence counts only at the edge: a frame two below it, or one already at two taps, says nothing.
        XCTAssertEqual(drag(&law, at: 29, .onTime, 2000), [])
        XCTAssertEqual(drag(&law, at: 32, .onTime, 2000), [])
        // Clean frames build over several drags.
        XCTAssertEqual(drag(&law, at: 31, .onTime, 300), [])
        XCTAssertEqual(drag(&law, at: 30, .onTime, 300), [.up(from: 31, to: 32), .applied(from: 31, to: 32)])
        XCTAssertEqual(drag(&law, at: 42, .onTime, 100_000).count, 0)
        var top = TapLaw(start: TapLaw.ceiling)
        XCTAssertEqual(drag(&top, at: TapLaw.ceiling, .onTime, 5000), [], "the ceiling holds")
    }

    func testAnyGPUMissStartsTheCleanCountAgain() {
        var law = TapLaw(start: 30)
        law.open(work: 30)
        feed(&law, .onTime, 599)
        feed(&law, .gpuMiss, 1)
        XCTAssertEqual(feed(&law, .onTime, 599), [])
        XCTAssertEqual(feed(&law, .onTime, 1), [.up(from: 30, to: 31)])
        // The main thread's own misses don't.
        law = TapLaw(start: 30)
        law.open(work: 30)
        feed(&law, .onTime, 599)
        feed(&law, .cpuMiss, 5)
        XCTAssertEqual(feed(&law, .onTime, 1), [.up(from: 30, to: 31)])
    }

    func testAProvisionalCapIsProbedOnceALaunchConfirmedByASecondMissOrErased() {
        var law = TapLaw(start: 30)
        drag(&law, at: 30, .gpuMiss, 3)
        XCTAssertEqual([law.applied, law.cap, law.strikes], [29, 30, 1])
        // The climb stops short of the cap, bar one probe after twice the evidence.
        XCTAssertEqual(drag(&law, at: 29, .onTime, 1199), [])
        XCTAssertEqual(drag(&law, at: 29, .onTime, 1), [.probe(to: 30), .applied(from: 29, to: 30)])
        var erased = law
        // A second miss there confirms it, and the climb then stops below it for good.
        XCTAssertEqual(drag(&law, at: 30, .gpuMiss, 3), [.down(from: 30, to: 29, work: 30, misses: 3, of: 3, strike: 2),
                                                       .applied(from: 30, to: 29)])
        XCTAssertEqual(drag(&law, at: 29, .onTime, 10_000), [])
        XCTAssertEqual(law.applied, 29)
        // Held clean at it, it was a passing miss.
        XCTAssertEqual(drag(&erased, at: 30, .onTime, 600), [.erased(cap: 30)])
        XCTAssertNil(erased.cap)
        XCTAssertEqual(drag(&erased, at: 30, .onTime, 600), [.up(from: 30, to: 31), .applied(from: 30, to: 31)])
        // Once a launch: a lower cap set after the probe isn't probed again.
        var once = TapLaw(start: 30)
        drag(&once, at: 30, .gpuMiss, 3)
        drag(&once, at: 29, .onTime, 1200)
        drag(&once, at: 29, .gpuMiss, 3)
        XCTAssertEqual([once.applied, once.cap, once.strikes], [28, 29, 1])
        XCTAssertEqual(drag(&once, at: 28, .onTime, 5000), [])
        // A new launch probes again.
        var next = TapLaw(stored: once.stored(build: "b", os: "o"))
        XCTAssertEqual(drag(&next, at: 28, .onTime, 1200), [.probe(to: 29), .applied(from: 28, to: 29)])
    }

    func testAStepThatDidntHelpIsTakenBackAndPausesTheStepsDown() {
        var law = TapLaw(start: 30)
        drag(&law, at: 30, .gpuMiss, 3)
        XCTAssertEqual(law.applied, 29)
        law.open(work: 30)
        XCTAssertEqual(feed(&law, .gpuMiss, 3), [.reverted(from: 29, to: 30, work: 30, misses: 3, of: 3)],
                       "drawn at two taps it still misses: not the shader")
        XCTAssertNil(law.close())
        XCTAssertEqual(law.still(), .applied(from: 29, to: 30))
        XCTAssertNil(law.cap, "the strike goes with it")
        XCTAssertEqual(law.strikes, 0)
        XCTAssertTrue(law.paused)
        XCTAssertEqual(drag(&law, at: 30, .gpuMiss, 60), [], "no more steps down this launch")
        // One that helped is held.
        var held = TapLaw(start: 30)
        drag(&held, at: 30, .gpuMiss, 3)
        XCTAssertEqual(drag(&held, at: 30, .onTime, 30), [.held(work: 30)])
        XCTAssertNil(held.check)
        XCTAssertEqual(drag(&held, at: 30, .gpuMiss, 3), [.twoTap(work: 30, misses: 3, of: 3)], "checked once")
        // Too short a drag to tell leaves the check for the next.
        var short = TapLaw(start: 30)
        drag(&short, at: 30, .gpuMiss, 3)
        XCTAssertEqual(drag(&short, at: 30, .onTime, 29), [])
        XCTAssertNotNil(short.check)
    }

    func testHeatTakesAQuarterOffUntilItCoolsAndIsNeverKept() {
        var law = TapLaw(start: 30)
        XCTAssertEqual(law.heat(.fair), nil)
        XCTAssertEqual(law.heat(.serious), .hot(from: 30, to: 22))
        XCTAssertEqual(law.applied, 30, "drawn at the next still moment")
        XCTAssertEqual(law.still(), .applied(from: 30, to: 22))
        // Misses while hot lower only the hot budget, and nothing climbs.
        XCTAssertEqual(drag(&law, at: 22, .gpuMiss, 3), [.down(from: 22, to: 21, work: 22, misses: 3, of: 3, strike: nil),
                                                       .applied(from: 22, to: 21)])
        XCTAssertEqual(drag(&law, at: 21, .onTime, 5000), [])
        XCTAssertEqual(law.stored(build: "b", os: "o"), .init(applied: 30, cap: nil, strikes: 0, build: "b", os: "o"))
        XCTAssertEqual(law.heat(.critical), .hot(from: 21, to: TapLaw.floor))
        XCTAssertEqual(law.heat(.nominal), .cool(from: TapLaw.floor, to: 30))
        XCTAssertEqual(law.still(), .applied(from: 21, to: 30))
        XCTAssertNil(law.check, "a hot step's check goes with the heat")
    }

    func testNoApplyLandsWhileADragIsOpen() {
        var law = TapLaw(start: 30)
        drag(&law, at: 29, .onTime, 600)
        law.open(work: 29)
        feed(&law, .gpuMiss, 3)
        XCTAssertNil(law.still())
        XCTAssertEqual(law.applied, 31)
        _ = law.close()
        XCTAssertEqual(law.still(), .applied(from: 31, to: 28))
        XCTAssertEqual(law.heat(.serious), .hot(from: 28, to: 21))
        law.open(work: 10)
        XCTAssertNil(law.still(), "nor the heat's")
        _ = law.close()
        XCTAssertEqual(law.still(), .applied(from: 28, to: 21))
    }


    func testAGlassStartsFromTheStaticLimitOrTheNearestOneLearnt() {
        // Every phone's glass, the open split, the tabletop and the upright Duo's.
        for pixels in [656.5, 1004.8, Tank.tunedPixels, 1171.3, 1194.3, 1272.0, 1471] {
            let key = TapKey(hz: 120, pixels: pixels)
            XCTAssertEqual(TapLaw.prior(key, pixels: pixels, learnt: [:]).budget, Tank.fourTaps(pixels: pixels), "\(pixels) px")
        }
        XCTAssertEqual(TapLaw.prior(TapKey(hz: 120, pixels: 1471), pixels: 1471, learnt: [:]).budget, 17)
        let phone = TapKey(hz: 120, pixels: Tank.tunedPixels)
        XCTAssertEqual(phone.px, 1136)
        let zoomed = TapKey(hz: 120, pixels: 1171.3)
        let scaled = TapLaw.prior(zoomed, pixels: 1171.3, learnt: [phone: 28, TapKey(hz: 120, pixels: 656.5): 40])
        XCTAssertEqual(scaled.from, phone, "the nearest")
        XCTAssertEqual(scaled.budget, Int((29 * pow(1136.0 / 1168, 2)).rounded()) - 1)
        XCTAssertEqual(scaled.budget, 26)
        XCTAssertNil(TapLaw.prior(zoomed, pixels: 1171.3, learnt: [TapKey(hz: 60, pixels: 1171.3): 20]).from, "another rate's")
        XCTAssertEqual(TapLaw.prior(TapKey(hz: 120, pixels: 1471), pixels: 1471, learnt: [phone: 12]).budget, TapLaw.floor)
    }
}
