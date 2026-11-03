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

    func testALaunchEndedBeforeTheStillMomentKeepsTheStep() {
        var law = TapLaw(start: 30)
        law.open(work: 29)
        feed(&law, .gpuMiss, 3)
        XCTAssertNil(law.close())
        XCTAssertEqual(law.applied, 30, "killed here, before the next move")
        let kept = law.stored(build: "b", os: "o")
        XCTAssertEqual(kept, .init(applied: 28, cap: 29, strikes: 1, build: "b", os: "o"))
        var next = TapLaw(stored: kept)
        XCTAssertEqual([next.applied, next.cap], [28, 29])
        XCTAssertEqual(drag(&next, at: 28, .onTime, 1200), [.probe(to: 29), .applied(from: 28, to: 29)], "and can climb again")
    }

    func testACapTheStartMeetsIsDroppedBarAProbes() {
        XCTAssertNil(TapLaw(start: 12, cap: 8, strikes: 1).cap, "under the floor, no budget acts on it")
        XCTAssertNil(TapLaw(stored: .init(applied: 30, cap: 29, strikes: 1, build: "", os: "")).cap)
        XCTAssertNil(TapLaw(start: 29, cap: 29, strikes: 2).cap)
        XCTAssertEqual(TapLaw(start: 29, cap: 29, strikes: 1).cap, 29, "a probe at it")
        XCTAssertEqual(TapLaw(start: 28, cap: 29, strikes: 2).cap, 29)
        var probing = TapLaw(start: 29, cap: 29, strikes: 1)
        XCTAssertEqual(drag(&probing, at: 29, .onTime, 600), [.erased(cap: 29)])
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

    func testMissesFarBelowTheBudgetStepOnlyWhileHotAndNeedSix() {
        var law = TapLaw(start: 30)
        law.open(work: 26)
        XCTAssertEqual(feed(&law, .gpuMiss, 3).count, 1, "within four of the budget")
        law = TapLaw(start: 30)
        XCTAssertEqual(drag(&law, at: 25, .gpuMiss, 300), [], "cool, a passing miss")
        XCTAssertEqual([law.applied, law.cap], [30, nil])
        _ = law.heat(.serious)
        _ = law.still()
        XCTAssertEqual(law.applied, 22)
        law.open(work: 17)
        XCTAssertEqual(feed(&law, .gpuMiss, 5), [])
        XCTAssertEqual(feed(&law, .gpuMiss, 1), [.down(from: 22, to: 16, work: 17, misses: 6, of: 6, strike: nil)])
        // Six among the last thirty, not since the drag began.
        law = TapLaw(start: 30)
        _ = law.heat(.serious)
        _ = law.still()
        law.open(work: 17)
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
        // A miss at the floor or under it draws four taps whatever the budget: no step changes it.
        var shallow = TapLaw(start: 14)
        XCTAssertEqual(drag(&shallow, at: 12, .gpuMiss, 300), [])
        XCTAssertEqual(drag(&shallow, at: 11, .gpuMiss, 300), [])
        XCTAssertEqual([shallow.applied, shallow.cap], [14, nil])
        _ = shallow.heat(.critical)
        _ = shallow.still()
        XCTAssertEqual(drag(&shallow, at: 8, .gpuMiss, 300), [], "nor while hot")
        _ = shallow.heat(.nominal)
        XCTAssertEqual(shallow.still(), .applied(from: 12, to: 14))
        XCTAssertNil(shallow.cap)
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
        // One that helped is held, on two-tap frames at its work or a few over.
        var held = TapLaw(start: 30)
        drag(&held, at: 30, .gpuMiss, 3)
        XCTAssertEqual(drag(&held, at: 31, .onTime, 60), [])
        XCTAssertEqual(held.checks.count, 1, "too few to tell: the next drag adds to them")
        XCTAssertEqual(drag(&held, at: 34, .onTime, 60), [.held(work: 34)])
        XCTAssertTrue(held.checks.isEmpty)
        XCTAssertEqual(drag(&held, at: 30, .gpuMiss, 3), [.twoTap(work: 30, misses: 3, of: 3)], "checked once")
        // Frames well over it cost more than those that missed: they say nothing of it.
        var over = TapLaw(start: 30)
        drag(&over, at: 30, .gpuMiss, 3)
        XCTAssertEqual(drag(&over, at: 35, .gpuMiss, 30), [.twoTap(work: 35, misses: 30, of: 30)])
        XCTAssertEqual(over.applied, 29)
        // The commit that lands a step usually changes the work: a later drag a push over it still checks it.
        var pushed = TapLaw(start: 30)
        drag(&pushed, at: 26, .gpuMiss, 3)
        drag(&pushed, at: 25, .onTime, 10)
        XCTAssertEqual(pushed.applied, 25)
        XCTAssertEqual(drag(&pushed, at: 27, .gpuMiss, 3), [.reverted(from: 25, to: 30, work: 27, misses: 3, of: 3),
                                                           .applied(from: 25, to: 30)])
    }

    func testTwoStepsAtDifferentWorkAreTakenBackTogether() {
        var law = TapLaw(start: 30)
        XCTAssertEqual(drag(&law, at: 29, .gpuMiss, 3).first, .down(from: 30, to: 28, work: 29, misses: 3, of: 3, strike: 1))
        XCTAssertEqual(drag(&law, at: 27, .gpuMiss, 3).first, .down(from: 28, to: 26, work: 27, misses: 3, of: 3, strike: 1))
        XCTAssertEqual(law.checks.map(\.work), [29, 27])
        // Two-tap frames at 28, which both steps drew at two taps, miss as the four-tap ones did: neither helped.
        XCTAssertEqual(drag(&law, at: 28, .gpuMiss, 30), [.reverted(from: 26, to: 30, work: 28, misses: 3, of: 3),
                                                         .applied(from: 26, to: 30)])
        XCTAssertEqual([law.applied, law.cap], [30, nil])
        XCTAssertTrue(law.checks.isEmpty)
        XCTAssertTrue(law.paused)
    }

    func testAPassingMissNearTheEdgeCostsAFewEntriesAndIsClimbedBack() {
        var law = TapLaw(start: 30)
        drag(&law, at: 26, .gpuMiss, 3)
        XCTAssertEqual([law.applied, law.cap], [25, 26], "at most the edge and one")
        XCTAssertEqual(drag(&law, at: 27, .onTime, 120), [.held(work: 27)])
        var frames = 0
        while law.applied < 30, frames < 10_000 {
            drag(&law, at: law.applied, .onTime, 100)
            frames += 100
        }
        XCTAssertEqual(law.applied, 30)
        XCTAssertNil(law.cap)
        XCTAssertLessThanOrEqual(frames, 4200, "a probe, an erase and four climbs: about 35 s of drags at the edge")
    }

    /// Random drags, heat, launches ended before their still moment and relaunches: the budget moves only at a still
    /// moment, each step draws the missed work with two taps, a cap never bars every way up, and clean play at the
    /// edge always climbs back to the ceiling or under a confirmed cap.
    func testNoStreamOfFramesLocksTheBudget() {
        let classes: [FrameClass] = [.onTime, .onTime, .onTime, .gpuMiss, .cpuMiss, .ignored]
        let states: [ProcessInfo.ThermalState] = [.nominal, .fair, .serious, .critical]
        func sound(_ law: TapLaw) -> Bool {
            (TapLaw.floor...TapLaw.ceiling).contains(law.applied) && law.cap.map { $0 > law.want || $0 == law.want && law.strikes == 1 } ?? true
        }
        // The climb's evidence cut tenfold, so the climb back runs in moments: the law's shape is the same.
        var cuts = TapCuts.attributed
        (cuts.climb, cuts.probe, cuts.hold) = (60, 120, 12)
        seeds: for seed in 0..<100 {
            var rng = SplitMix64(state: UInt64(seed))
            var law = TapLaw(start: TapLaw.floor + rng.below(TapLaw.ceiling - TapLaw.floor + 1), cuts: cuts)
            for _ in 0..<80 {
                let before = law.applied
                if rng.below(8) == 0 { _ = law.heat(states[rng.below(4)]) }
                let work = rng.below(2) == 0 ? max(1, law.applied - 6 + rng.below(12)) : 1 + rng.below(TapLaw.ceiling + 4)
                law.open(work: work)
                let burst = rng.below(3)
                for _ in 0..<rng.below(240) {
                    let c = burst == 0 && rng.below(3) == 0 ? .gpuMiss : classes[rng.below(classes.count)]
                    let e = law.count(c)
                    if case let .down(_, to, w, _, _, _) = e, to >= w { XCTFail("seed \(seed): \(String(describing: e))"); continue seeds }
                    if e != nil, !sound(law) { XCTFail("seed \(seed): \(String(describing: e))"); continue seeds }
                }
                _ = law.close()
                XCTAssertEqual(law.applied, before, "only a still moment draws a change, seed \(seed)")
                if rng.below(5) > 0 { _ = law.still() }
                if rng.below(15) == 0 { law = TapLaw(stored: law.stored(build: "", os: ""), cuts: cuts) }
                guard sound(law) else { XCTFail("seed \(seed)"); continue seeds }
            }
            _ = law.heat(.nominal)
            _ = law.still()
            // A probe spent in this launch comes back in the next.
            for _ in 0..<2 {
                for _ in 0..<40 {
                    if drag(&law, at: law.applied, .onTime, 120).isEmpty { break }
                }
                law = TapLaw(stored: law.stored(build: "", os: ""), cuts: cuts)
            }
            XCTAssertTrue(law.applied == TapLaw.ceiling || law.cap == law.applied + 1 && law.strikes == 2,
                          "seed \(seed): \(law.applied), cap \(String(describing: law.cap)) strikes \(law.strikes)")
        }
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
        XCTAssertTrue(law.checks.isEmpty, "a hot step's check goes with the heat")
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
