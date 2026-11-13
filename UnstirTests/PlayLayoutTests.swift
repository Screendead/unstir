// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import XCTest
@testable import Unstir

final class PlayLayoutTests: XCTestCase {
    /// As the play screen's GeometryReader measures the window: the safe area's size and the insets round it.
    private func layout(window: CGSize, insets: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat),
                        fold: CGRect? = nil, halo: PlayLayout.Halo = PlayLayout.Halo(),
                        chrome: PlayLayout.Chrome = PlayLayout.Chrome(), scale: CGFloat = 3) -> PlayLayout {
        PlayLayout.of(size: CGSize(width: window.width - insets.leading - insets.trailing,
                                   height: window.height - insets.top - insets.bottom),
                      insets: EdgeInsets(top: insets.top, leading: insets.leading, bottom: insets.bottom, trailing: insets.trailing),
                      fold: fold.map { $0.offsetBy(dx: -insets.leading, dy: -insets.top) }, halo: halo, chrome: chrome, scale: scale)
    }

    func testEveryIPhoneKeepsTodaysColumn() {
        // Content sizes measured on each simulator (PR #112): SE, Pro Max, the Duo closed.
        for (window, content, scale) in [(CGSize(width: 375, height: 667), CGSize(width: 343, height: 647), 2.0),
                                         (CGSize(width: 440, height: 956), CGSize(width: 408, height: 860), 3),
                                         (CGSize(width: 466, height: 678), CGSize(width: 350, height: 644), 3)] {
            for halo in [PlayLayout.Halo(), .init(ring: 0.23, above: 20)] {
                let l = PlayLayout.of(content: content, window: window, halo: halo, scale: scale)
                XCTAssertEqual(l.kind, .column, "\(window)")
                XCTAssertEqual(l.side, min(content.width, content.height - 290) / 1.045, "\(window): today's formula, whatever is drawn round the glass")
                XCTAssertLessThan(l.side * scale, PlayLayout.maxPixels, "\(window): no phone reaches the cap")
                XCTAssertEqual(Tank.fourTaps(pixels: l.side * scale), Tank.fourTaps, "\(window): a phone's taps as they were")
                XCTAssertNil(l.bounds, "the column's limits are the screen's")
                XCTAssertNil(l.filmFoot)
            }
        }
    }

    func testTheOpenDuoSplitsWithTheTankWhollyInTheLeadingHalf() {
        // The inner display opened like a book: the status column on the trailing edge (its width assumed from the
        // closed display's 84 pt), the home indicator below.
        let window = CGSize(width: 951, height: 669)
        let l = layout(window: window, insets: (24, 0, 21, 84))
        XCTAssertEqual(l.kind, .split)
        // In window points: the tank's pane ends short of the fold, the menu's starts past it.
        let fold = window.width / 2, menu = try! XCTUnwrap(l.menuPane)
        XCTAssertLessThanOrEqual(PlayLayout.margin + l.tankPane.maxX, fold - PlayLayout.margin)
        XCTAssertGreaterThanOrEqual(PlayLayout.margin + menu.minX, fold + PlayLayout.margin)
        XCTAssertGreaterThanOrEqual(menu.width, PlayLayout.minPane)
        // The glass and its rim fit the pane, short of the size past which the four-tap limit shrinks.
        XCTAssertLessThanOrEqual(l.side * PlayLayout.rim, l.tankPane.width)
        XCTAssertLessThanOrEqual(l.chrome.above + PlayStack.gap + l.side * PlayLayout.rim + l.chrome.below, l.tankPane.height + 0.001)
        XCTAssertEqual(l.side, 417, accuracy: 1)
        XCTAssertLessThanOrEqual(l.side * 3, Tank.fourTapsKept)
        XCTAssertEqual(Tank.fourTaps(pixels: l.side * 3), Tank.fourTaps)
    }

    func testTheOpenDuoUprightKeepsTheColumnAtTheCap() {
        let l = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0))
        XCTAssertEqual(l.kind, .column)
        XCTAssertEqual(l.side, PlayLayout.maxPixels / 3, accuracy: 0.001, "about 1630 px uncapped")
        XCTAssertEqual(l.side, 490.333, accuracy: 0.001, "1471 px (Jack's call duocap2 = D)")
        XCTAssertEqual(Tank.fourTaps(pixels: l.side * 3), 23)
        // Endless keeps the column there, its brim drawn out to the screen's edges as on a phone, at the same size.
        let endless = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), halo: .init(ring: 0.229))
        XCTAssertEqual(endless.kind, .column)
        XCTAssertEqual(endless.side, l.side)
    }

    /// The limit the shader runs four taps to, by the glass's side in pixels: every glass up to 1300 px, today's cap
    /// before the upright Duo's grew, keeps the phone's 40; past it the 40 held on the 13 Pro Max's glass plus the one in flight
    /// (`Tank.scaledFrom`) shrink with the area, one kept for the entry in flight, so the Duo keeps 23.
    func testTheFourTapLimitShrinksOnlyPastTheGlassesOfToday() {
        XCTAssertEqual(Tank.tunedPixels, Double(3 * (428 - 2 * PlayLayout.margin) / PlayLayout.rim), accuracy: 0.001,
                       "the 13 Pro Max's column")
        XCTAssertEqual(Tank.tunedPixels, 1136.842, accuracy: 0.001)
        // The SE, the Duo closed, the 13 Pro Max (as measured), the 17 Pro Max (the largest iPhone), the tabletop, the
        // open split, the round 16 pitch's option A, and the cap before the upright Duo's.
        for pixels in [656.5, 1004.8, Tank.tunedPixels, 1171.3, 1194.3, 1272.0, 1279.0, 1300.0] {
            XCTAssertEqual(Tank.fourTaps(pixels: pixels), Tank.fourTaps, "\(pixels) px")
        }
        XCTAssertEqual(Tank.fourTaps(pixels: 1300.5), 30)
        XCTAssertEqual(Tank.fourTaps(pixels: 1334), 28)
        XCTAssertEqual(Tank.fourTaps(pixels: 1471), 23)
        var last = Tank.fourTaps
        let measured = Tank.scaledFrom
        for pixels in stride(from: 1300.5, through: 1471, by: 0.5) {
            let limit = Tank.fourTaps(pixels: pixels), area = (pixels / Tank.tunedPixels) * (pixels / Tank.tunedPixels)
            XCTAssertLessThanOrEqual(limit, last, "\(pixels) px")
            XCTAssertLessThanOrEqual(Double(limit + 1) * area, measured, "\(pixels) px: four taps through the limit and one in flight")
            XCTAssertGreaterThan(Double(limit + 2) * area, measured, "\(pixels) px: the largest limit that fits")
            last = limit
        }
    }

    /// What `Unstirred` hands both shaders: the glass's own limit less the picture's fill.
    func testTheShadersTapBudgetFollowsTheGlass() {
        for picture in Picture.allCases {
            let fill = picture.fillEntries
            XCTAssertEqual(Unstirred.taps(side: 408 / PlayLayout.rim, scale: 3, fill: fill), Tank.fourTaps - fill,
                           "\(picture): the 17 Pro Max's glass as it was")
            XCTAssertEqual(Unstirred.taps(side: PlayLayout.maxPixels / 3, scale: 3, fill: fill), 23 - fill,
                           "\(picture): the upright Duo's glass")
            XCTAssertEqual(Unstirred.taps(side: 120, scale: 3, fill: fill), Tank.fourTaps - fill, "\(picture): a dock cover")
            XCTAssertEqual(Unstirred.taps(side: 320, scale: 3, fill: fill), Tank.fourTaps - fill, "\(picture): a card's clip at its largest")
        }
        XCTAssertEqual(Unstirred.taps(side: 490.333, scale: 3, fill: 0), 23)
    }

    /// The shaders draw four taps where `cost ?? n` is at most the budget less the fill plus what rides in flight,
    /// exactly where the work is at most the budget; and with no budget given, every glass draws as it did.
    func testTheShadersGateIsTheCommittedWorkAgainstTheBudget() {
        var rng = SplitMix64(state: 7)
        let palette: [Channels] = [.white, .red, .green, .blue, .cyan, .magenta, .yellow]
        for trial in 0..<4000 {
            let count = rng.below(40), flight = rng.below(3), fill = rng.below(7)
            let budget = rng.below(48), prism = trial % 2 == 0
            let masks: [Int: Channels] = prism ? Dictionary(uniqueKeysWithValues: (0..<4).map { ($0, palette[rng.below(7)]) }) : [:]
            let stack = (0..<count).map { _ in Twist(rod: rng.below(4), steps: 1) }
            let flown = (0..<flight).map { _ in rng.below(4) }
            let channels = (stack.map(\.rod) + flown).map { Float((masks[$0] ?? .white).rawValue) }
            // As `Unstirred.body` hands the shaders the frame.
            let weight = Unstirred.weigh(channels, inFlight: flight)
            let four = Float(weight.cost ?? channels.count) <= Float(budget - fill + weight.rides)
            let work = Unstirred.work(channels, inFlight: flight, fill: fill)
            XCTAssertEqual(four, Unstirred.drawsFourTaps(work: work, budget: budget), "trial \(trial)")
            // As the body did before the budget: one entry over for anything in flight, Prism's own cost.
            let old = Unstirred.channelCost(channels).map { cost in
                Float(cost) <= Float(budget - fill + (flown.map { Int((masks[$0] ?? .white).rawValue).nonzeroBitCount }.max() ?? 0))
            } ?? (Float(channels.count) <= Float(budget - fill) + (flight > 0 ? 1 : 0))
            XCTAssertEqual(four, old, "trial \(trial)")
            if flight <= 1 {
                XCTAssertEqual(Unstirred.committedWork(stack: stack, masks: masks, fill: fill, held: flown.first), work, "trial \(trial)")
            }
        }
        // A stack of 30 on a still picture keeps four taps at 30 with the drag, not 31.
        let thirty = (0..<30).map { Twist(rod: $0 % 2, steps: 1) }
        XCTAssertTrue(Unstirred.drawsFourTaps(work: Unstirred.committedWork(stack: thirty, masks: [:], fill: 0, held: 0), budget: 30))
        XCTAssertFalse(Unstirred.drawsFourTaps(work: Unstirred.committedWork(stack: thirty + [Twist(rod: 0, steps: 1)], masks: [:], fill: 0, held: 1),
                                               budget: 30))
        // Prism: a white entry costs three, and three over the stack.
        let level = Level.prism[0]
        XCTAssertEqual(Unstirred.committedWork(stack: level.scramble, masks: level.masks, fill: 0),
                       Unstirred.channelCost(level.scramble.map { Float((level.masks[$0.rod] ?? .white).rawValue) }))
        for pixels in [656.5, Tank.tunedPixels, 1471] {
            XCTAssertEqual(Unstirred.taps(side: pixels / 3, scale: 3, fill: 4), Tank.fourTaps(pixels: pixels) - 4)
        }
    }

    func testTheCapBindsTheSplitToo() {
        let l = PlayLayout.of(content: CGSize(width: 1300, height: 1000), window: CGSize(width: 1332, height: 1000), scale: 3)
        XCTAssertEqual(l.kind, .split)
        XCTAssertEqual(l.side, PlayLayout.maxPixels / 3, accuracy: 0.001, "uncapped the half would hold about 607 pt")
    }

    func testANarrowOrSmallWindowKeepsTheColumn() {
        // Split View's half of the open Duo is tall.
        XCTAssertEqual(layout(window: CGSize(width: 475, height: 669), insets: (24, 0, 21, 0)).kind, .column)
        // Wider than tall, but each half too narrow for the chrome.
        XCTAssertEqual(layout(window: CGSize(width: 600, height: 500), insets: (0, 0, 0, 0)).kind, .column)
    }

    func testTheSplitFollowsTheWindowsMiddleNotTheContents() {
        // A status column on the leading edge moves the content, not the fold.
        let a = layout(window: CGSize(width: 951, height: 669), insets: (24, 84, 21, 0))
        XCTAssertEqual(a.kind, .split)
        XCTAssertEqual(84 + PlayLayout.margin + a.tankPane.maxX, 951 / 2 - PlayLayout.margin, accuracy: 0.001)
        XCTAssertEqual(84 + PlayLayout.margin + a.menuPane!.minX, 951 / 2 + PlayLayout.margin, accuracy: 0.001)
        XCTAssertEqual(a.side, 359.5 / PlayLayout.rim, accuracy: 0.001, "the leading half is the narrower now")
    }

    func testTheProxysOwnMeasureSplitsAtTheFold() {
        // What the play screen's GeometryReader reported under UNSTIR_FRAME=951x669 with the trailing column.
        let l = PlayLayout.of(size: CGSize(width: 867, height: 624), insets: EdgeInsets(top: 24, leading: 0, bottom: 21, trailing: 84),
                              scale: 3)
        XCTAssertEqual(l.kind, .split)
        XCTAssertEqual(l.tankPane.width, 951 / 2 - 2 * PlayLayout.margin, accuracy: 0.001)
        let c = PlayLayout.Chrome()
        XCTAssertEqual(l.side, (624 - c.above - c.below - PlayStack.gap) / PlayLayout.rim, accuracy: 0.001)
    }

    // The folds below are in window points, 19 pt across (assumed: no Duo simulator reports one headlessly), as the
    // harness's UNSTIR_FOLD gives them.

    func testABookFoldedSplitsClearOfTheFoldsBand() {
        let fold = CGRect(x: 466, y: 0, width: 19, height: 669)
        let l = layout(window: CGSize(width: 951, height: 669), insets: (24, 0, 21, 84), fold: fold)
        XCTAssertEqual(l.kind, .split)
        XCTAssertEqual(PlayLayout.margin + l.tankPane.maxX, fold.minX - PlayLayout.margin, accuracy: 0.001)
        XCTAssertEqual(PlayLayout.margin + l.menuPane!.minX, fold.maxX + PlayLayout.margin, accuracy: 0.001)
        XCTAssertLessThanOrEqual(l.side * PlayLayout.rim, l.tankPane.width)
        XCTAssertLessThanOrEqual(PlayLayout.margin + l.stage.maxX, fold.minX - PlayLayout.margin)
        // Flat, the same window splits at its middle, so folding the phone moves the tank by a quarter of the band.
        let flat = layout(window: CGSize(width: 951, height: 669), insets: (24, 0, 21, 84))
        XCTAssertEqual(flat.kind, .split)
        XCTAssertEqual(flat.stage.midX - l.stage.midX, (951 / 2 - fold.minX) / 2, accuracy: 0.001)
    }

    func testTheTabletopPutsTheTankWhollyBelowTheFoldAndTheRestAbove() {
        let fold = CGRect(x: 0, y: 466, width: 669, height: 19), top: CGFloat = 59
        let l = layout(window: CGSize(width: 669, height: 951), insets: (top, 0, 34, 0), fold: fold)
        XCTAssertEqual(l.kind, .tabletop)
        // In window points.
        XCTAssertLessThanOrEqual(top + l.chromePane.maxY, fold.minY - PlayLayout.margin)
        XCTAssertGreaterThanOrEqual(top + l.tankPane.minY, fold.maxY + PlayLayout.margin)
        XCTAssertGreaterThanOrEqual(top + l.stage.minY, fold.maxY + PlayLayout.margin - 0.001)
        XCTAssertLessThanOrEqual(l.stage.maxY, l.tankPane.maxY + 0.001)
        XCTAssertLessThanOrEqual(l.side * PlayLayout.rim, l.tankPane.width)
        // The tank fills the half lying flat: about 398 pt, near the Pro Max's 408.
        XCTAssertEqual(l.side, (858 - (fold.maxY - top) - PlayLayout.margin) / PlayLayout.rim, accuracy: 0.001)
        XCTAssertEqual(Tank.fourTaps(pixels: l.side * 3), Tank.fourTaps)
        // "unstirred." stands in the upright half, clear of the fold.
        let wordsTop = top + l.stage.minY - (try! XCTUnwrap(l.words))
        XCTAssertGreaterThanOrEqual(wordsTop, top + l.chromePane.minY)
        XCTAssertLessThanOrEqual(wordsTop + PlayLayout.wordsHeight, fold.minY - PlayLayout.margin + 0.001)
    }

    func testFlatUprightTheDuoKeepsTheColumnAndFoldedTheTabletop() {
        let window = CGSize(width: 669, height: 951)
        XCTAssertEqual(layout(window: window, insets: (59, 0, 34, 0)).kind, .column)
        XCTAssertEqual(layout(window: window, insets: (59, 0, 34, 0), fold: CGRect(x: 0, y: 466, width: 669, height: 19)).kind,
                       .tabletop)
    }

    func testAFoldLeavingAHalfTooSmallKeepsTheColumn() {
        // Folded near the top, the upright part can't hold the chrome; near the leading edge, the tank's half is too narrow.
        XCTAssertEqual(layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0),
                              fold: CGRect(x: 0, y: 300, width: 669, height: 19)).kind, .column)
        XCTAssertEqual(layout(window: CGSize(width: 951, height: 669), insets: (24, 0, 21, 84),
                              fold: CGRect(x: 250, y: 0, width: 19, height: 669)).kind, .column)
    }

    func testTheColumnKeepsItsWordsAndTheSplitsHeadTheCard() {
        XCTAssertEqual(layout(window: CGSize(width: 440, height: 956), insets: (62, 0, 34, 0)).words, 62)
        XCTAssertNil(layout(window: CGSize(width: 951, height: 669), insets: (24, 0, 21, 84)).words,
                     "the title stands over the split's tank, so unstirred. heads the card over the menu")
    }

    func testUnstirredGrowsWithTheTypeAndStillEndsAboveTheRim() {
        XCTAssertEqual(TypeRole.stamp.points(at: .large), 22)
        XCTAssertGreaterThan(TypeRole.stamp.points(at: PlayLayout.typeCap), 22)
        // The widest phone's column at the cap, whose rim reaches furthest above the stage.
        let l = layout(window: CGSize(width: 440, height: 956), insets: (62, 0, 34, 0),
                       chrome: PlayLayout.Chrome(type: PlayLayout.typeCap))
        let words = try! XCTUnwrap(l.words), rim = l.side * (PlayLayout.rim - 1) / 2
        XCTAssertLessThanOrEqual(TypeRole.stamp.line(at: PlayLayout.typeCap).height + rim, words)
        // Where the word clears the title at the stage's top, it stays there: every phone's column at the default size,
        // and the Pro Max's at the cap.
        XCTAssertEqual(PlayLayout.columnWords(over: PlayLayout.words, side: l.side, type: PlayLayout.typeCap).words, words)
        // The SE's column at the cap leaves less over the glass than that (level 05 lays out 49.2 pt), so the
        // word stands lower, wholly below the title line's foot and above the rim, and always at its full size: where
        // the room can't hold its line, however many lines the note takes, the finished tank's top comes down for it.
        let se = PlayLayout.of(content: CGSize(width: 343, height: 647), window: CGSize(width: 375, height: 667),
                               chrome: PlayLayout.Chrome(type: PlayLayout.typeCap), type: PlayLayout.typeCap, scale: 2)
        let seRim = se.side * (PlayLayout.rim - 1) / 2, line = TypeRole.stamp.line(at: PlayLayout.typeCap).height
        for over in Array(stride(from: PlayStack.gap, to: PlayLayout.words, by: 0.5)) + [49.2] {
            let (seWords, drop) = PlayLayout.columnWords(over: over, side: se.side, type: PlayLayout.typeCap)
            XCTAssertLessThanOrEqual(seWords, over + 0.001, "\(over): below the title line")
            XCTAssertGreaterThanOrEqual(seWords + drop, line + seRim - 0.001, "\(over): above the rim, once the tank has come down")
            XCTAssertEqual(drop, max(line + seRim - over, 0).rounded(.up), "\(over): the tank gives the word only what it lacks")
            // The tank shrunk for its card too keeps its top there, so the word stays clear of the rim.
            let stage = se.side * PlayLayout.rim, fit = PlayLayout.finished(card: 300, room: 200, stage: stage, drop: drop)
            XCTAssertEqual(fit.drop, drop)
            XCTAssertEqual(fit.scale, (stage - fit.lift - drop) / stage, accuracy: 0.001, "\(over): the tank between the word and the card")
            XCTAssertGreaterThanOrEqual(fit.scale, PlayLayout.leastFinished)
        }
        XCTAssertEqual(PlayLayout.columnWords(over: 49.2, side: se.side, type: PlayLayout.typeCap).drop, 0)
    }

    // Stage 5: the chrome round the tank beside the menu (Jack's call s5-chrome = B, round 16).

    func testBesideTheMenuTheChromeGoesRoundTheTankInItsHalf() {
        for fold in [nil, book] as [CGRect?] {
            for chrome in [PlayLayout.Chrome(), PlayLayout.Chrome(Level.escapement[0], swatches: false),
                           PlayLayout.Chrome(Level.prism[0], swatches: true)] {
                let l = layout(window: open.window, insets: open.insets, fold: fold, chrome: chrome)
                let what = "\(fold == nil ? "open" : "book") \(chrome)"
                XCTAssertEqual(l.kind, .split, what)
                XCTAssertEqual(l.chromePane, l.tankPane, "\(what): the header, title, caption and controls share the tank's half")
                let menu = try! XCTUnwrap(l.menuPane)
                XCTAssertGreaterThan(menu.minX, l.tankPane.maxX + 2 * PlayLayout.margin - 0.001, what)
                XCTAssertEqual(menu.maxX, open.window.width - open.insets.trailing - 2 * PlayLayout.margin, accuracy: 0.001, what)
                // The header and title above the stage, the column's 12 pt clear of it; the caption, swatches and
                // controls under it, the controls ending at the pane's foot.
                let over = l.stage.minY - l.tankPane.minY - chrome.above, under = l.tankPane.maxY - l.stage.maxY - chrome.below
                XCTAssertGreaterThanOrEqual(over, PlayStack.gap - 0.001, what)
                XCTAssertGreaterThanOrEqual(under, -0.001, what)
                // The spare room goes half over the stage, half over the controls.
                XCTAssertEqual(over - PlayStack.gap, under, accuracy: 0.001, what)
            }
        }
    }

    /// A plain daily and a frost day (`Frost.days`), which seizes two knobs and turns the tank.
    static let plainDay = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 1, hour: 12))!
    static let frostDay = Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 10, day: 15, hour: 12))!

    func testTheTabletopsSpacersShareWhatTheChromeLeaves() {
        XCTAssertEqual(PlayStack.share(624, used: 200, spacers: 2), 212, "centred round the chrome")
        XCTAssertEqual(PlayStack.share(100, used: 200, spacers: 2), 0, "a tall card: the spacers give way")
    }

    func testTheGlassShrinksBesideTheMenuOnlyWhereTheChromeNeedsIt() {
        func side(_ level: Level, swatches: Bool = false) -> CGFloat {
            layout(window: open.window, insets: open.insets, halo: PlayLayout.Halo(level),
                   chrome: PlayLayout.Chrome(level, swatches: swatches)).side
        }
        // A bare glass, as tall as the chrome leaves the leading half with the column's 12 pt over it.
        let plain = PlayLayout.Chrome()
        let bare = layout(window: open.window, insets: open.insets).side
        XCTAssertEqual(bare, (624 - plain.above - plain.below - PlayStack.gap) / PlayLayout.rim, accuracy: 0.001)
        XCTAssertEqual(bare, 417, accuracy: 1)
        // Stage 1's glass, every tier's level, Lens's, and Prism's read by colour: the brim's pin over twelve, under the
        // title, 9 pt less. The rim lesson's arc, on maelstrom and a frost day, reaches no higher.
        let brim = PlayLayout.Halo(Level.plughole[10]).brim, over = PlayLayout.rim + brim / 2
        let stage1 = (624 - plain.above - plain.below) / over
        XCTAssertEqual(bare - stage1, 9, accuracy: 1)
        for level in [Level.plughole[10], Level.whirlpool[0], Level.vortex[0], Level.lens[0], Level.prism[0],
                      Level.daily(Self.plainDay), Level.plughole[0], Level.maelstrom[0], Level.daily(Self.frostDay)] {
            XCTAssertEqual(side(level), stage1, accuracy: 0.001, level.id)
        }
        XCTAssertLessThan(stage1, (624 - plain.above - plain.below - RimLesson.overRim) / PlayLayout.rim, "the lesson's room")
        // Escapement's taller header and two lines of serif: 5 pt less.
        let escapement = PlayLayout.Chrome(Level.escapement[0], swatches: false)
        XCTAssertEqual(side(Level.escapement[0]), (624 - escapement.above - escapement.below) / over, accuracy: 0.001)
        XCTAssertEqual(stage1 - side(Level.escapement[0]), 5, accuracy: 1)
        // Prism read by its letters, the swatches under the caption, a row of buttons: 44 pt less.
        let swatches = 4 + max(ButtonFace.height, 24 + TypeRole.button.line(at: .large).height)
        XCTAssertEqual(side(Level.prism[0], swatches: true), (624 - plain.above - plain.below - swatches) / over, accuracy: 0.5)
        XCTAssertEqual(stage1 - side(Level.prism[0], swatches: true), 44, accuracy: 1)
        // Endless's brim reaches round the glass.
        XCTAssertEqual(side(Level.endless(Run(seed: 7))), 342, accuracy: 1)
        // Every level of a tier or a pack takes one glass, so the tank keeps its size as the list beside it is played on.
        for list in Tier.allCases.map(\.levels) + Pack.allCases.map(\.levels) {
            for swatches in [false, true] {
                XCTAssertEqual(Set(list.map { side($0, swatches: swatches && !$0.masks.isEmpty) }).count, 1, list.first?.id ?? "")
            }
        }
    }

    @MainActor func testEveryCaptionFitsTheChromesTwoLinesBesideTheMenu() {
        // The caption's room under the tank holds two lines at the open Duo's half: the note, or what stands in for it.
        let width = layout(window: open.window, insets: open.insets).tankPane.width
        XCTAssertEqual(TypeRole.label.points(at: .large), 15, "the label role")
        for type in [DynamicTypeSize.large, .xxxLarge] {
            captions(fit: width, type: type)
        }
    }

    @MainActor private func captions(fit width: CGFloat, type: DynamicTypeSize, file: StaticString = #filePath, line: UInt = #line) {
        let size = TypeRole.label.points(at: type)
        let mono = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
        let serif = UIFont.systemFont(ofSize: size).fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) }!
        func lines(_ text: String, _ font: UIFont) -> Int {
            let h = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                    options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil).height
            return Int((h / font.lineHeight).rounded())
        }
        let levels = Tier.allCases.flatMap(\.levels) + Pack.allCases.flatMap(\.levels) + [Level.daily(Self.plainDay), Level.daily(Self.frostDay), Level.endless(Run(seed: 7))]
        for level in levels {
            XCTAssertLessThanOrEqual(lines(level.note, level.page.paper ? serif : mono), 2, "\(level.id) at \(type)", file: file, line: line)
        }
        for text in [LevelView.refills, "Practice: this day's best was set on its day.", "Practice: only the first try counts.",
                     "watch the stir \u{00B7} tap to skip", "the tank is full: undo or reset"] {
            XCTAssertLessThanOrEqual(lines(text, mono), 2, "\(text) at \(type)", file: file, line: line)
        }
        for bank in [0, 1] {
            let words = Game(level: Level.escapement[1], bank: (undos: bank, refilled: nil), storesProgress: false).deadTickWords
            XCTAssertLessThanOrEqual(lines(words, serif), 2, "\(words) at \(type)", file: file, line: line)
        }
        XCTAssertLessThanOrEqual(lines(LevelView.demoWait, serif), 2, "\(LevelView.demoWait) at \(type)", file: file, line: line)
    }

    /// Lays `content` out in a window of `size` with `insets` as its safe area, as `UNSTIR_FRAME` does, for `seconds`.
    @MainActor private func host(_ content: some View, window size: CGSize,
                                 insets i: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat),
                                 fold: CGRect? = nil, seconds: Double = 0.5, settled: (() -> Bool)? = nil) {
        let pose = HarnessWindow.Pose(size: size, insets: EdgeInsets(top: i.top, leading: i.leading, bottom: i.bottom, trailing: i.trailing),
                                      fold: fold)
        let host = UIHostingController(rootView: HarnessWindow(HarnessWindow.Spec(poses: [pose], then: nil), content: content))
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene.map { UIWindow(windowScene: $0) } ?? UIWindow()
        window.frame = CGRect(origin: .zero, size: size)
        window.rootViewController = host
        window.isHidden = false
        host.view.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
        // Then on, a tenth of a second at a time, until `settled` says so, for at most two seconds more.
        if let settled {
            for _ in 0 ..< 20 where !settled() { RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1)) }
        }
        window.isHidden = true
    }

    /// Lays `harness`'s level out in the open Duo's window beside the menu and returns what its chrome measures round
    /// the tank.
    @MainActor private func measuredChrome(_ harness: Harness, type: DynamicTypeSize = .large) -> PlayLayout.Chrome? {
        // Written by the layout pass, on the main thread, and read here after it.
        final class Box: @unchecked Sendable { var chrome: PlayLayout.Chrome? }
        let box = Box()
        let level = LevelView(level: harness.level, harness: harness, onExit: { _ in }, onNext: { _ in }, onLook: { _ in },
                              onOffer: { _ in }, besideMenu: true)
            .environment(\.chromeMeasured) { box.chrome = $0 }
            .dynamicTypeSize(type)
        host(level, window: open.window, insets: open.insets)
        return box.chrome
    }

    @MainActor func testTheChromesRoomBesideTheMenuIsWhatItsPartsMeasure() {
        // PlayLayout.Chrome sizes the glass from fixed heights; the views round the tank must take what it allows, or
        // the title runs into the rim or the caption into the controls with every arithmetic test still green.
        for (env, swatches) in [(["UNSTIR_LEVEL": "11", "UNSTIR_CLOCK": "1"], false),
                                (["UNSTIR_PACK": "escapement", "UNSTIR_LEVEL": "2", "UNSTIR_OWNED": "escapement", "UNSTIR_CLOCK": "1"], false),
                                (["UNSTIR_PACK": "prism", "UNSTIR_LEVEL": "1", "UNSTIR_OWNED": "prism", "UNSTIR_LETTERS": "1",
                                  "UNSTIR_CLOCK": "1"], true)] {
            // The largest size plays capped, as xxxLarge does.
            let pane = layout(window: open.window, insets: open.insets).chromePane.width
            for type in [DynamicTypeSize.large, .xxxLarge, .accessibility5] {
                let harness = Harness(env), what = "\(harness.level.id) at \(type)"
                let budget = PlayLayout.Chrome(harness.level, swatches: swatches, type: type, width: pane)
                let got = try! XCTUnwrap(measuredChrome(harness, type: type), "\(what): laid out beside the menu")
                XCTAssertEqual(got.above, budget.above, accuracy: 1, what)
                // Escapement's note may show one line of its two, or "tap to skip" over the demonstration.
                XCTAssertLessThanOrEqual(got.below, budget.below + 1, what)
                XCTAssertGreaterThanOrEqual(got.below, budget.below - 2.5, what)
            }
        }
    }

    /// Escapement's wait shares undo and reset's row only where all three fit it on a line each; where they don't it
    /// takes a row of its own and the chrome's room grows by it, so no label wraps or shrinks. An SE is 343 pt inside
    /// its margins and the widest phone 408.
    func testTheWaitTakesARowWhereTheRowCantHoldAllThree() {
        let clocks = Level.escapement[1], plain = Level.plughole[0]
        XCTAssertFalse(PlayLayout.waitTakesARow(clocks, width: 343, type: .large))
        XCTAssertTrue(PlayLayout.waitTakesARow(clocks, width: 343, type: .xxxLarge))
        XCTAssertEqual(PlayLayout.waitTakesARow(clocks, width: 343, type: .accessibility5),
                       PlayLayout.waitTakesARow(clocks, width: 343, type: .xxxLarge), "play caps its type at xxxLarge")
        XCTAssertFalse(PlayLayout.waitTakesARow(clocks, width: 408, type: .xxxLarge))
        for type in [DynamicTypeSize.large, .xxxLarge] {
            XCTAssertFalse(PlayLayout.waitTakesARow(plain, width: 100, type: type), "no clock, no wait")
            XCTAssertFalse(PlayLayout.waitTakesARow(nil, width: 100, type: type))
            let shared = PlayLayout.Chrome(clocks, type: type, width: 408), own = PlayLayout.Chrome(clocks, type: type, width: 200)
            let button = max(ButtonFace.height, 24 + TypeRole.button.line(at: type).height)
            XCTAssertEqual(own.below - shared.below, button + LevelView.controlRows, accuracy: 0.34, "\(type)")
            XCTAssertEqual(own.above, shared.above)
            XCTAssertEqual(PlayLayout.Chrome(plain, type: type, width: 200), PlayLayout.Chrome(plain, type: type))
        }
        let labels = ["undo \u{00B7} 10", "wait", "reset"]
        let row = labels.reduce(0) { $0 + TypeRole.button.width(of: $1, at: .large) + 2 * ButtonFace.side }
            + 2 * PlayLayout.controlGap
        XCTAssertFalse(PlayLayout.waitTakesARow(clocks, width: row, type: .large))
        XCTAssertTrue(PlayLayout.waitTakesARow(clocks, width: row - 1, type: .large))
    }

    /// An armed reset has the row to itself where undo can't share it on a line each, so "reset? tap again" never wraps
    /// and the row never grows: an SE (343 pt inside its margins) at every size, the widest phone (408) at the largest.
    func testAnArmedResetHasTheRowWhereUndoCantShareIt() {
        let armed = ["undo \u{00B7} 10", "reset? tap again"]
        XCTAssertFalse(PlayLayout.rowHolds(armed, width: 343, type: .large))
        XCTAssertTrue(PlayLayout.rowHolds(armed, width: 408, type: .large))
        XCTAssertFalse(PlayLayout.rowHolds(armed, width: 408, type: .xxxLarge))
        XCTAssertEqual(PlayLayout.rowHolds(armed, width: 408, type: .accessibility5),
                       PlayLayout.rowHolds(armed, width: 408, type: .xxxLarge), "play caps its type at xxxLarge")
        XCTAssertTrue(PlayLayout.rowHolds(["reset? tap again"], width: 343, type: .accessibility5), "alone it fits an SE")
        // The row is measured on its labels as the buttons set them: each a line of the button role and its sides.
        let row = armed.reduce(0) { $0 + TypeRole.button.width(of: $1, at: .large) + 2 * ButtonFace.side }
            + PlayLayout.controlGap
        XCTAssertTrue(PlayLayout.rowHolds(armed, width: row, type: .large))
        XCTAssertFalse(PlayLayout.rowHolds(armed, width: row - 1, type: .large))
    }

    func testTheChromeGrowsWithTheTypeSizeUpToItsCap() {
        let plain = PlayLayout.Chrome(), large = PlayLayout.Chrome(type: .xxxLarge)
        XCTAssertGreaterThan(large.above, plain.above)
        XCTAssertGreaterThan(large.below, plain.below)
        XCTAssertLessThan(PlayLayout.Chrome(type: .small).below, plain.below)
        XCTAssertEqual(PlayLayout.Chrome(type: .accessibility5), large, "play caps its type at xxxLarge")
        // The column keeps today's room at the default size, and as much more as the chrome grows.
        XCTAssertEqual(PlayLayout.reserve(.large), 290, accuracy: 0.001)
        XCTAssertEqual(PlayLayout.reserve(.xxxLarge), 290 + large.above + large.below - plain.above - plain.below, accuracy: 0.001)
        XCTAssertEqual(PlayLayout.reserve(.accessibility5), PlayLayout.reserve(.xxxLarge))
        // An SE's glass gives way to large type rather than the chrome running off the screen.
        let se = (content: CGSize(width: 343, height: 647), window: CGSize(width: 375, height: 667))
        let side = { (type: DynamicTypeSize) in PlayLayout.of(content: se.content, window: se.window, type: type, scale: 2).side }
        XCTAssertEqual(side(.large), 343 / PlayLayout.rim, accuracy: 0.001, "width-bound, as today")
        XCTAssertEqual(side(.xxxLarge), (647 - PlayLayout.reserve(.xxxLarge)) / PlayLayout.rim, accuracy: 0.001)
        XCTAssertLessThan(side(.xxxLarge), side(.large))
    }

    // The card's room: once a level is finished the tank shrinks for its card, and the text never does (Jack, 2026-11-11).

    func testAFinishedTankGivesItsCardExactlyWhatItLacks() {
        let stage: CGFloat = 343, foot = PlayLayout.cardFoot
        for card in [0, 100, 200 - foot] as [CGFloat] {
            let fit = PlayLayout.finished(card: card, room: 200, stage: stage)
            XCTAssertEqual(fit.scale, 1, "\(card): a card with room leaves the tank as it was played")
            XCTAssertEqual(fit.lift, 0)
            XCTAssertTrue(fit.fits)
        }
        let fit = PlayLayout.finished(card: 250.4, room: 200, stage: stage)
        XCTAssertEqual(fit.lift, (250.4 - 200 + foot).rounded(.up), "what the card lacks, to the next whole point")
        XCTAssertEqual(fit.scale, (stage - fit.lift) / stage, "the tank's foot rises as far as the card does")
        XCTAssertTrue(fit.fits, "the card whole")
        // Past what the tank's least gives, it gives that much and says the card doesn't fit, which no card may reach.
        let tall = PlayLayout.finished(card: 500, room: 200, stage: stage)
        XCTAssertGreaterThanOrEqual(tall.scale, PlayLayout.leastFinished, "never under its least")
        XCTAssertEqual(tall.scale, PlayLayout.leastFinished, accuracy: 1 / stage)
        XCTAssertFalse(tall.fits)
        let deep = PlayLayout.finished(card: 400, room: 200, stage: stage)
        XCTAssertLessThan(deep.scale, 0.55, "the glass gives way past the old least before the card goes short")
        XCTAssertTrue(deep.fits)
    }

    private typealias Phone = (window: CGSize, insets: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat))
    private let se: Phone = (CGSize(width: 375, height: 667), (20, 0, 0, 0))
    private let proMax: Phone = (CGSize(width: 440, height: 956), (62, 0, 34, 0))

    /// Lays the harness's level out in `phone`'s window at `type` and returns what its finished column measured, last,
    /// and how many times: the card's height, its room under the tank as played and how the column gives it room. Nil
    /// where no card came up.
    @MainActor private func measuredCard(_ env: [String: String], _ phone: Phone, type: DynamicTypeSize)
        -> (card: CGFloat, room: CGFloat, fit: PlayLayout.Finished, times: Int)? {
        final class Box: @unchecked Sendable { var last: (CGFloat, CGFloat, PlayLayout.Finished)?; var times = 0 }
        // A harness solve marks its level started for the launch, as registered defaults, which no later test may see.
        let registered = UserDefaults.standard.volatileDomain(forName: UserDefaults.registrationDomain)
        defer { UserDefaults.standard.setVolatileDomain(registered, forName: UserDefaults.registrationDomain) }
        let box = Box(), harness = Harness(env)
        let level = LevelView(level: harness.level, harness: harness, onExit: { _ in }, onNext: { _ in }, onLook: { _ in },
                              onOffer: { _ in })
            .environment(\.finishedMeasured) { box.last = ($0, $1, $2); box.times += 1 }
            .dynamicTypeSize(type)
        // Past the card's arrival, which the shrink keeps time with.
        host(level, window: phone.window, insets: phone.insets, seconds: 1)
        return box.last.map { ($0.0, $0.1, $0.2, box.times) }
    }

    /// A screen the play view runs on: its window, safe area and fold, if folded.
    private struct Screen {
        let name: String, window: CGSize, insets: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat)
        var fold: CGRect? = nil
    }
    /// The smallest iPhone the app supports (iOS 17: the SE's 4.7 inch), a 6.1 inch, the Pro Max, and the Duo closed,
    /// open upright, open beside the menu and folded flat.
    private var screens: [Screen] {
        [Screen(name: "SE", window: se.window, insets: se.insets),
         Screen(name: "6.1 inch", window: CGSize(width: 393, height: 852), insets: (59, 0, 34, 0)),
         Screen(name: "Pro Max", window: proMax.window, insets: proMax.insets),
         Screen(name: "Duo closed", window: CGSize(width: 466, height: 678), insets: (0, 0, 34, 84)),
         Screen(name: "Duo upright", window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0)),
         Screen(name: "Duo beside the menu", window: open.window, insets: open.insets, fold: book),
         Screen(name: "Duo tabletop", window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table)]
    }

    /// Lays the harness's level out on `screen` at `type` and returns the card's frame in the window, last, its height
    /// as laid out and, in the column, its room and fit. Nil where no card came up.
    @MainActor private func placedCard(_ env: [String: String], _ screen: Screen, type: DynamicTypeSize)
        -> (frame: CGRect, card: CGFloat?, room: CGFloat?, fit: PlayLayout.Finished?)? {
        final class Box: @unchecked Sendable { var frame: CGRect?; var seen: CGRect?; var last: (CGFloat, CGFloat, PlayLayout.Finished)? }
        let registered = UserDefaults.standard.volatileDomain(forName: UserDefaults.registrationDomain)
        defer { UserDefaults.standard.setVolatileDomain(registered, forName: UserDefaults.registrationDomain) }
        let box = Box(), harness = Harness(env)
        let level = LevelView(level: harness.level, harness: harness, onExit: { _ in }, onNext: { _ in }, onLook: { _ in },
                              onOffer: { _ in })
            .environment(\.finishedMeasured) { box.last = ($0, $1, $2) }
            .environment(\.cardPlaced) { box.frame = $0 }
            .dynamicTypeSize(type)
        // Past the card's arrival and the tank's shrink, until the card stops moving: its frame the same a tenth apart.
        host(level, window: screen.window, insets: screen.insets, fold: screen.fold, seconds: 1) {
            defer { box.seen = box.frame }
            return box.frame != nil && box.frame == box.seen
        }
        return box.frame.map { ($0, box.last?.0, box.last?.1, box.last?.2) }
    }

    /// The card stands whole on one screen with nothing scrolling (Jack, 2026-11-13): over the safe area's foot, less
    /// what it keeps clear there in the column, and in the tabletop over the fold; at its own height, so no text gave
    /// way; and in the column with the tank at or over its least, having given exactly what the card lacked.
    private func standsWhole(_ p: (frame: CGRect, card: CGFloat?, room: CGFloat?, fit: PlayLayout.Finished?), on screen: Screen,
                             _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        let foot = screen.window.height - screen.insets.bottom - (p.fit == nil ? 0 : PlayLayout.cardFoot)
        XCTAssertGreaterThanOrEqual(p.frame.minY, screen.insets.top - 0.5, "\(what): under the safe area's top", file: file, line: line)
        XCTAssertLessThanOrEqual(p.frame.maxY, foot + 0.5, "\(what): over the foot", file: file, line: line)
        XCTAssertGreaterThanOrEqual(p.frame.minX, -0.5, what, file: file, line: line)
        XCTAssertLessThanOrEqual(p.frame.maxX, screen.window.width + 0.5, what, file: file, line: line)
        if let fold = screen.fold, fold.width > fold.height {
            XCTAssertLessThanOrEqual(p.frame.maxY, fold.minY + 0.5, "\(what): over the fold", file: file, line: line)
        } else if let fold = screen.fold {
            XCTAssertGreaterThanOrEqual(p.frame.minX, fold.maxX - 0.5, "\(what): past the fold, over the menu", file: file, line: line)
        }
        if let fit = p.fit, let card = p.card, let room = p.room {
            XCTAssertTrue(fit.fits, "\(what): whole with the glass at or over its least", file: file, line: line)
            XCTAssertGreaterThanOrEqual(fit.scale, PlayLayout.leastFinished, what, file: file, line: line)
            XCTAssertEqual(fit.lift, max(card - room + PlayLayout.cardFoot, 0).rounded(.up),
                           "\(what): the tank gives up no more than the card lacks", file: file, line: line)
            XCTAssertEqual(p.frame.height, card, accuracy: 0.5, "\(what): at its own height", file: file, line: line)
        }
    }

    /// The fullest card any level shows: plughole 27 replayed at par with a stir undone, against a best of +6, every
    /// other plughole level at par, so its card says what clean takes and the new best, offers again (the best isn't
    /// clean) and goes up a notch to the open tier. As tiers open on solved levels (Jack, 2026-11-13), a closed tier's
    /// longer way up never shows on a tier's last level. Measured 2026-11-13: 311 pt at xxxLarge, the SE's glass at 59%.
    /// The tests measure every candidate rather than trust this.
    private func storeTheFullestCard() {
        for level in Tier.plughole.levels.dropLast() { Best(over: 0, seconds: 60).save(level.id) }
        Best(over: 6, seconds: 60).save(Tier.plughole.levels.last!.id)
    }
    private let fullest = ["UNSTIR_SCREEN": "undone", "UNSTIR_LEVEL": "27", "UNSTIR_CLOCK": "0"]

    @MainActor func testTheTankShrinksUntilTheWholeCardStandsOverTheFoot() {
        // The cards that ran past the foot: the fullest at xxxLarge, the play screen's cap, on the largest phone and the
        // shortest, and on the shortest at the default size the fullest, the daily's with its next daily, and a replay at
        // par with its best. Every screen at every type has its own test.
        let cases: [(String, [String: String], Phone, DynamicTypeSize, () -> Void)] = [
            ("the fullest card at xxxLarge on a Pro Max", fullest, proMax, .xxxLarge, storeTheFullestCard),
            ("the fullest card on an SE", fullest, se, .large, storeTheFullestCard),
            ("the daily's card on an SE", ["UNSTIR_SCREEN": "result", "UNSTIR_MODE": "daily", "UNSTIR_NOW": "17:00"], se, .large, {}),
            ("a replay at par with an undo on an SE", ["UNSTIR_SCREEN": "undone", "UNSTIR_LEVEL": "6"], se, .large,
             { for level in Tier.plughole.levels.prefix(6) { Best(over: 0, seconds: 60).save(level.id) } }),
        ]
        for (what, env, phone, type, store) in cases {
            store()
            let m = try! XCTUnwrap(measuredCard(env, phone, type: type), what)
            print("card fit: \(what): card \(m.card) room \(m.room) lift \(m.fit.lift) scale \(m.fit.scale)")
            XCTAssertTrue(m.fit.fits, "\(what): whole on screen")
            XCTAssertLessThanOrEqual(m.card, m.room - PlayLayout.cardFoot + m.fit.lift, "\(what): the card ends over the foot")
            XCTAssertEqual(m.fit.lift, max(m.card - m.room + PlayLayout.cardFoot, 0).rounded(.up), "\(what): the tank gives up no more than the card lacks")
            XCTAssertGreaterThanOrEqual(m.fit.scale, PlayLayout.leastFinished, what)
            // The room is measured with the tank as played: one that moved with the shrink would never settle.
            XCTAssertLessThan(m.times, 6, "\(what): settles")
        }
    }

    /// Every bit of a level's best and pack progress, so each candidate stores only its own.
    private func forgetEveryBest() {
        for level in Tier.allCases.flatMap(\.levels) + Pack.allCases.flatMap(\.levels) {
            UserDefaults.standard.removeObject(forKey: "best.\(level.id)")
        }
    }

    /// The cards that could be the tallest a player reaches, each with the progress it needs: what the card says grows
    /// with the solve's line, its best's, a completion's, its buttons and a way up.
    private var candidates: [(what: String, env: [String: String], store: () -> Void)] {
        let maelstrom27 = Tier.maelstrom.levels.last!.id
        return [
            ("plughole 27 replayed at par against +6", ["UNSTIR_SCREEN": "clean", "UNSTIR_LEVEL": "27", "UNSTIR_CLOCK": "0"],
             storeTheFullestCard),
            ("plughole 27 replayed over par against +6", ["UNSTIR_SCREEN": "result", "UNSTIR_LEVEL": "27", "UNSTIR_CLOCK": "0"],
             storeTheFullestCard),
            ("plughole 27 replayed at par with an undo against +6", fullest, storeTheFullestCard),
            ("plughole 05 at par with an undo, the last plughole level without a best",
             ["UNSTIR_SCREEN": "undone", "UNSTIR_LEVEL": "5", "UNSTIR_CLOCK": "0"],
             { for (i, level) in Tier.plughole.levels.enumerated() where i != 4 { Best(over: 0, seconds: 60).save(level.id) } }),
            ("the daily at par with an undo", ["UNSTIR_SCREEN": "undone", "UNSTIR_MODE": "daily", "UNSTIR_NOW": "17:00"], {}),
            ("plughole 05 over par, the last plughole level without a best", ["UNSTIR_SCREEN": "result", "UNSTIR_LEVEL": "5",
                                                                               "UNSTIR_CLOCK": "0"],
             { for (i, level) in Tier.plughole.levels.enumerated() where i != 4 { Best(over: 0, seconds: 60).save(level.id) } }),
            ("plughole 05 at par against +6", ["UNSTIR_SCREEN": "clean", "UNSTIR_LEVEL": "5", "UNSTIR_CLOCK": "0"], {
                for level in Tier.plughole.levels { Best(over: 0, seconds: 60).save(level.id) }
                Best(over: 6, seconds: 60).save(Tier.plughole.levels[4].id)
            }),
            ("the daily as practice", ["UNSTIR_SCREEN": "clean", "UNSTIR_MODE": "daily", "UNSTIR_NOW": "17:00",
                                       "UNSTIR_TRIED": Level.dailyID(Date())], {}),
            ("the daily with undos", ["UNSTIR_SCREEN": "result", "UNSTIR_MODE": "daily", "UNSTIR_NOW": "17:00"], {}),
            ("the daily clean", ["UNSTIR_SCREEN": "clean", "UNSTIR_MODE": "daily", "UNSTIR_NOW": "17:00"], {}),
            ("Lens 25 completing Lens on a replay", ["UNSTIR_PACK": "lens", "UNSTIR_LEVEL": "25", "UNSTIR_SCREEN": "clean",
                                                     "UNSTIR_OWNED": "first-stir,lens", "UNSTIR_CLOCK": "0",
                                                     "UNSTIR_TRIED": Pack.lens.levels.last!.id],
             { for level in Pack.lens.levels.dropLast() { Best(over: 0, seconds: 60).save(level.id) } }),
            ("maelstrom 27 unstirring every tier on a replay", ["UNSTIR_SCREEN": "clean", "UNSTIR_TIER": "maelstrom",
                                                                "UNSTIR_LEVEL": "27", "UNSTIR_OWNED": "first-stir",
                                                                "UNSTIR_CLOCK": "0", "UNSTIR_TRIED": maelstrom27],
             { for level in Tier.allCases.flatMap(\.levels) where level.id != maelstrom27 { Best(over: 0, seconds: 60).save(level.id) } }),
            ("maelstrom 27 against +6", ["UNSTIR_SCREEN": "clean", "UNSTIR_TIER": "maelstrom", "UNSTIR_LEVEL": "27",
                                         "UNSTIR_OWNED": "first-stir", "UNSTIR_CLOCK": "0"],
             { Best(over: 6, seconds: 60).save(maelstrom27) }),
        ]
    }

    /// The tallest of `candidates` on `screen` at `type`, by the card's height as laid out, with where it stood.
    @MainActor private func tallestCard(_ screen: Screen, type: DynamicTypeSize)
        -> (what: String, env: [String: String], store: () -> Void,
            p: (frame: CGRect, card: CGFloat?, room: CGFloat?, fit: PlayLayout.Finished?)) {
        var tallest: (String, [String: String], () -> Void, (frame: CGRect, card: CGFloat?, room: CGFloat?, fit: PlayLayout.Finished?))?
        for c in candidates {
            forgetEveryBest()
            c.store()
            let p = try! XCTUnwrap(placedCard(c.env, screen, type: type), "\(screen.name): \(c.what)")
            print("card candidate: \(screen.name) at \(type): \(c.what): \(p.frame.height)")
            if p.frame.height > tallest?.3.frame.height ?? 0 { tallest = (c.what, c.env, c.store, p) }
        }
        forgetEveryBest()
        let t = tallest!
        return (t.0, t.1, t.2, t.3)
    }

    /// The play screen never scrolls (Jack, 2026-11-13: "everything should fit in one screen"). On the shortest and
    /// the largest phone every candidate is measured afresh at the play screen's largest type and the tallest stands
    /// whole; every other screen, and every smaller type on the shortest phone, places the shortest phone's tallest.
    /// `UNSTIR_SLOW_TESTS=1` measures every candidate everywhere (minutes on CI's runner). A taller card added later
    /// becomes the one checked, and one that can't fit even with the glass at its least fails here.
    @MainActor func testEveryCardStandsWholeOnOneScreenOnEveryScreenAtEveryType() {
        let all = ProcessInfo.processInfo.environment["UNSTIR_SLOW_TESTS"] == "1"
        let shortest = screens[0]
        let pick = tallestCard(shortest, type: PlayLayout.typeCap)
        func placed(_ screen: Screen, _ type: DynamicTypeSize) -> (what: String, p: (frame: CGRect, card: CGFloat?, room: CGFloat?, fit: PlayLayout.Finished?)) {
            if all || (screen.name == "Pro Max" && type == PlayLayout.typeCap) {
                let t = tallestCard(screen, type: type)
                return (t.what, t.p)
            }
            if screen.name == shortest.name && type == PlayLayout.typeCap { return (pick.what, pick.p) }
            forgetEveryBest()
            pick.store()
            return (pick.what, try! XCTUnwrap(placedCard(pick.env, screen, type: type)))
        }
        for screen in screens {
            let tallest = placed(screen, PlayLayout.typeCap)
            print("card placed: \(screen.name) at the cap, \(tallest.what): \(tallest.p.frame) scale \(tallest.p.fit?.scale ?? 1)")
            standsWhole(tallest.p, on: screen, "\(screen.name) at the cap: \(tallest.what)")
        }
        // The text keeps its size: the card is taller at the cap than at the default size.
        XCTAssertGreaterThan(pick.p.frame.height, placed(shortest, .large).p.frame.height, "the card's text grows with the type")
        for type in DynamicTypeSize.allCases where type < PlayLayout.typeCap && type != .large {
            let tallest = placed(shortest, type)
            standsWhole(tallest.p, on: shortest, "\(shortest.name) at \(type): \(tallest.what)")
        }
        forgetEveryBest()
        // Past the cap the play screen keeps the cap's size.
        storeTheFullestCard()
        let cap = try! XCTUnwrap(placedCard(fullest, shortest, type: PlayLayout.typeCap))
        storeTheFullestCard()
        let past = try! XCTUnwrap(placedCard(fullest, shortest, type: .accessibility5))
        XCTAssertEqual(past.frame.height, cap.frame.height, accuracy: 0.5)
        standsWhole(past, on: shortest, "\(shortest.name) at accessibility5")
        forgetEveryBest()
    }

    /// No supported phone needs the glass under its old 55% for any card, so the give past it runs through the real
    /// layout on a stand-in: a window 100 pt shorter than the SE's, which no supported iPhone is. The tallest card
    /// there stands whole, the glass simply smaller.
    @MainActor func testOnAWindowShorterThanAnyPhoneTheGlassGivesWayAndTheCardStandsWhole() {
        let short = Screen(name: "the stand-in", window: CGSize(width: 375, height: 567), insets: (20, 0, 0, 0))
        let tallest = tallestCard(short, type: PlayLayout.typeCap)
        print("card placed: the stand-in at the cap, \(tallest.what): \(tallest.p.frame) scale \(tallest.p.fit?.scale ?? 1)")
        standsWhole(tallest.p, on: short, "the stand-in: \(tallest.what)")
        XCTAssertLessThan(try! XCTUnwrap(tallest.p.fit).scale, 0.55, "the glass gave way past the old least")
    }

    @MainActor func testACardWithRoomAndATankInPlayLeaveTheTankAsItIs() {
        // A plain card on the largest phone at the default size, as every card there is.
        let plain = try! XCTUnwrap(measuredCard(["UNSTIR_SCREEN": "result", "UNSTIR_LEVEL": "5"], proMax, type: .large))
        XCTAssertEqual(plain.fit.scale, 1)
        XCTAssertEqual(plain.fit.lift, 0)
        XCTAssertTrue(plain.fit.fits)
        // In play nothing is measured for a card, so the tank is the layout's, on the shortest phone at the largest type too.
        for (phone, type) in [(se, DynamicTypeSize.large), (se, .xxxLarge), (proMax, .xxxLarge)] {
            XCTAssertNil(measuredCard(["UNSTIR_LEVEL": "27", "UNSTIR_CLOCK": "0"], phone, type: type)?.fit, "\(phone.window) at \(type)")
        }
    }

    // Stage 3: what each level draws round its glass, kept inside the tank's pane.

    private let open = (window: CGSize(width: 951, height: 669), insets: (top: CGFloat(24), leading: CGFloat(0), bottom: CGFloat(21), trailing: CGFloat(84)))
    private let book = CGRect(x: 466, y: 0, width: 19, height: 669)
    private let table = CGRect(x: 0, y: 466, width: 669, height: 19)

    /// The stage grown by what `halo` draws round it.
    private func reach(_ l: PlayLayout) -> CGRect {
        let ring = l.halo.ring * l.side / 2
        return CGRect(x: l.stage.minX - ring, y: l.stage.minY - max(ring, l.halo.above),
                      width: l.stage.width + 2 * ring, height: l.stage.height + ring + max(ring, l.halo.above))
    }

    private func inside(_ r: CGRect, _ pane: CGRect, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(r.minX, pane.minX - 0.001, what, file: file, line: line)
        XCTAssertGreaterThanOrEqual(r.minY, pane.minY - 0.001, what, file: file, line: line)
        XCTAssertLessThanOrEqual(r.maxX, pane.maxX + 0.001, what, file: file, line: line)
        XCTAssertLessThanOrEqual(r.maxY, pane.maxY + 0.001, what, file: file, line: line)
    }

    func testEachLevelsHaloIsItsShape() {
        let endless = PlayLayout.Halo(Level.endless(Run(seed: 7)))
        XCTAssertEqual(endless.ring, CGFloat((Brim.rOut + Brim.reach) / Brim.unit) - PlayLayout.rim, accuracy: 1e-9)
        XCTAssertEqual(endless.ring, 0.229, accuracy: 0.001, "the brim's glow and drops, out to Brim.reach")
        XCTAssertEqual(endless.above, 0)
        XCTAssertEqual(endless.brim, 0, "endless's own brim")
        // A level's brim reaches 0.1 of the radius past the rim, which only the split leaves room for.
        let brim = CGFloat((Brim.rOut + Brim.levelReach) / Brim.unit) - PlayLayout.rim
        XCTAssertEqual(brim, 0.1, accuracy: 0.001)
        XCTAssertEqual(PlayLayout.Halo(Level.maelstrom[0]), PlayLayout.Halo(ring: 0, above: RimLesson.overRim, brim: brim), "the rim lesson's arc")
        XCTAssertEqual(PlayLayout.Halo(Level.plughole[10]), PlayLayout.Halo(brim: brim), "the stack's brim round the rim")
        XCTAssertEqual(PlayLayout.Halo(Level.lens[0]), PlayLayout.Halo(brim: brim))
        XCTAssertEqual(PlayLayout.Halo(Level.escapement[1]), PlayLayout.Halo(brim: brim))
    }

    /// The Duo's split shrinks a level's glass just enough for its brim's pin to clear the title; the column, the
    /// tabletop and every phone keep the glass they had.
    func testALevelsBrimTakesRoomOnlyInTheSplit() {
        for level in [Level.plughole[10], Level.maelstrom[26]] {
            let halo = PlayLayout.Halo(level), bare = PlayLayout.Halo(ring: 0, above: halo.above)
            for (pose, fold) in [("open", nil), ("book", book)] as [(String, CGRect?)] {
                let l = layout(window: open.window, insets: open.insets, fold: fold, halo: halo)
                XCTAssertEqual(l.kind, .split, pose)
                XCTAssertEqual(l.halo.ring, 0, pose)
                XCTAssertGreaterThanOrEqual(l.stage.minY - halo.brim * l.side / 2, l.tankPane.minY + l.chrome.above - 0.001,
                                            "\(pose): the pin clear of the title")
                XCTAssertLessThanOrEqual(l.stage.maxY, l.tankPane.maxY - l.chrome.below + 0.001, pose)
                let was = layout(window: open.window, insets: open.insets, fold: fold, halo: bare)
                XCTAssertLessThanOrEqual(l.side, was.side, pose)
                // No smaller than the pin's room needs.
                XCTAssertGreaterThan(l.side, was.side * PlayLayout.rim / (PlayLayout.rim + halo.brim / 2) - 1, pose)
            }
            let upright = (window: CGSize(width: 669, height: 951), insets: (top: CGFloat(59), leading: CGFloat(0), bottom: CGFloat(34), trailing: CGFloat(0)))
            for (pose, window, insets, fold) in [("upright", upright.window, upright.insets, nil), ("tabletop", upright.window, upright.insets, table),
                                                 ("Pro Max", CGSize(width: 440, height: 956), (top: CGFloat(62), leading: CGFloat(0), bottom: CGFloat(34), trailing: CGFloat(0)), nil)]
                as [(String, CGSize, (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat), CGRect?)] {
                let l = layout(window: window, insets: insets, fold: fold, halo: halo)
                XCTAssertEqual(l.side, layout(window: window, insets: insets, fold: fold, halo: bare).side, pose)
                XCTAssertEqual(l.stage, layout(window: window, insets: insets, fold: fold, halo: bare).stage, pose)
            }
        }
    }

    func testEndlesssBrimStaysInsideTheTanksPaneInEveryPose() {
        let halo = PlayLayout.Halo(Level.endless(Run(seed: 7)))
        for (pose, fold) in [("open", nil), ("book", book)] as [(String, CGRect?)] {
            let l = layout(window: open.window, insets: open.insets, fold: fold, halo: halo)
            XCTAssertEqual(l.kind, .split, pose)
            inside(reach(l), l.tankPane, pose)
        }
        let t = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table, halo: halo)
        XCTAssertEqual(t.kind, .tabletop)
        inside(reach(t), t.tankPane, "tabletop")
        XCTAssertEqual(reach(t).height, t.tankPane.height, accuracy: 0.001)
        // Smaller than every other level's glass in the same pose, by the brim's reach.
        XCTAssertEqual(layout(window: open.window, insets: open.insets).side, 417, accuracy: 1)
        XCTAssertEqual(layout(window: open.window, insets: open.insets, halo: halo).side, 342, accuracy: 1)
        XCTAssertEqual(t.side, 326, accuracy: 1)
    }

    func testTheRimLessonStaysAboveTheGlassInsideTheTabletopsLowerHalf() {
        let halo = PlayLayout.Halo(Level.maelstrom[0])
        let l = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table, halo: halo)
        XCTAssertEqual(l.kind, .tabletop)
        inside(reach(l), l.tankPane, "tabletop")
        XCTAssertEqual(l.stage.maxY, l.tankPane.maxY, accuracy: 0.001, "sat on the pane's foot")
        XCTAssertEqual(l.stage.minY - l.tankPane.minY, halo.above, accuracy: 0.001, "the lesson's room above, no more")
        // The split's lesson lies between the title and the glass, which gives it the room over the column's gap.
        let split = layout(window: open.window, insets: open.insets, fold: book, halo: halo)
        XCTAssertLessThanOrEqual(split.side, layout(window: open.window, insets: open.insets, fold: book).side)
        inside(reach(split), split.tankPane, "book")
        for l in [split, layout(window: open.window, insets: open.insets, halo: halo)] {
            XCTAssertGreaterThanOrEqual(l.stage.minY - halo.above, l.tankPane.minY + l.chrome.above - 0.001, "clear of the title")
        }
    }

    func testAHaloLeavesNoRoomItDoesntNeed() {
        // Nothing drawn round the glass: the tabletop's tank still fills its half, as stage 2 laid it out.
        let l = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table)
        XCTAssertEqual(l.stage.minY, l.tankPane.minY, accuracy: 0.001)
        XCTAssertEqual(l.stage.maxY, l.tankPane.maxY, accuracy: 0.001)
    }

    func testBoundsAreTheTanksPaneInTheGlasssFrame() {
        for l in [layout(window: open.window, insets: open.insets, fold: book),
                  layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table, halo: .init(ring: 0, above: 20))] {
            let b = try! XCTUnwrap(l.bounds)
            let glass = CGRect(x: l.stage.midX - l.side / 2, y: l.stage.midY - l.side / 2, width: l.side, height: l.side)
            XCTAssertEqual(b.minX + glass.minX, l.tankPane.minX, accuracy: 0.001)
            XCTAssertEqual(b.minY + glass.minY, l.tankPane.minY, accuracy: 0.001)
            XCTAssertEqual(b.size, l.tankPane.size)
            XCTAssertTrue(b.contains(CGRect(x: 0, y: 0, width: l.side, height: l.side)), "the glass lies inside its pane")
        }
    }

    func testTheNightForwardsLinesEndAboveTheFoldInTheTabletop() {
        let t = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table)
        XCTAssertNotNil(t.filmFoot)
        // The film is centred on the glass, its lines hung from the black's foot and moved by the film's own offset.
        let blackFoot = t.stage.midY + NightForwardsFilm.backing / 2 * t.side
        let lines = blackFoot + NightForwardsFilm.linesOffset(foot: t.filmFoot, side: t.side)
        XCTAssertEqual(lines, t.chromePane.maxY, accuracy: 0.001, "at the foot of the upright half")
        XCTAssertLessThanOrEqual(59 + lines, table.minY - PlayLayout.margin + 0.001)
        // The split has room under the glass, as the column has.
        XCTAssertNil(layout(window: open.window, insets: open.insets).filmFoot)
    }

    func testALensTurnsOnlyAsFarAsItsTrackShowsInThePane() {
        // The column caps nothing, so a phone's lens drag is as it was.
        XCTAssertNil(LevelView.trackRoom(knob: 120, bounds: nil))
        XCTAssertEqual(LevelView.lensCapped(9 * Tank.step, joined: 2, room: nil), 9 * Tank.step)
        // In a pane, each step's place on the track inside it: 40 pt above the knob holds 2, 100 below holds 6.
        let room = try! XCTUnwrap(LevelView.trackRoom(knob: 40, bounds: CGRect(x: -20, y: 0, width: 400, height: 140)))
        XCTAssertEqual(room, -6...2)
        XCTAssertEqual(LevelView.trackRoom(knob: -10, bounds: CGRect(x: 0, y: 0, width: 400, height: 140)), -9...0)
        XCTAssertEqual(LevelView.lensCapped(9 * Tank.step, joined: 0, room: room), 2 * Tank.step)
        XCTAssertEqual(LevelView.lensCapped(-1.3 * Tank.step, joined: 0, room: room), -1.3 * Tank.step)
        // The track counts the open stir the turn joins as well.
        XCTAssertEqual(LevelView.lensCapped(9 * Tank.step, joined: 1, room: room), Tank.step)
        XCTAssertEqual(LevelView.lensCapped(-9 * Tank.step, joined: -4, room: room), -2 * Tank.step)
        // A stir already past the track, from a wider pose, turns back but no further out.
        XCTAssertEqual(LevelView.lensCapped(Tank.step, joined: 4, room: room), 0)
        XCTAssertEqual(LevelView.lensCapped(-3 * Tank.step, joined: 4, room: room), -3 * Tank.step)
    }

    @MainActor func testALensDragStopsAtItsTrackAndTurnsBackAtOnce() {
        // As the twist gesture plays a finger on a lens: each change adds its travel, then caps, and the lift commits
        // the nearest step of what is held.
        let room = -6...2
        var angle = 0.0, y = 0.0
        func move(to next: Double) {
            angle = LevelView.lensCapped(angle + LevelView.lensTurn(from: y, to: next), joined: 0, room: room)
            y = next
        }
        for i in 1...27 { move(to: -Double(i) * LevelView.lensPitch / 3) }
        XCTAssertEqual(angle, 2 * Tank.step, accuracy: 1e-9, "nine steps up hold at the track's top")
        XCTAssertEqual(Detent.steps(angle, of: Tank.step), 2)
        move(to: y + LevelView.lensPitch)
        XCTAssertEqual(Detent.steps(angle, of: Tank.step), 1, "a step back down turns the lens back a step at once")
        // The column caps nothing.
        angle = 0; y = 0
        for i in 1...27 {
            let next = -Double(i) * LevelView.lensPitch / 3
            angle = LevelView.lensCapped(angle + LevelView.lensTurn(from: y, to: next), joined: 0, room: nil)
            y = next
        }
        XCTAssertEqual(Detent.steps(angle, of: Tank.step), 9)
    }

    @MainActor func testEveryLensLevelsUnzoomFitsItsTrackInEveryPose() {
        // Jack's "why" for the cap (d3-lenscap = B, round 16): no level needs a zoom longer than the pane.
        let upright = (window: CGSize(width: 669, height: 951), insets: (top: CGFloat(59), leading: CGFloat(0), bottom: CGFloat(34), trailing: CGFloat(0)))
        for level in Pack.lens.levels {
            for (window, insets, fold) in [(open.window, open.insets, nil), (open.window, open.insets, book),
                                           (upright.window, upright.insets, table)] as [(CGSize, (CGFloat, CGFloat, CGFloat, CGFloat), CGRect?)] {
                let l = layout(window: window, insets: insets, fold: fold, halo: PlayLayout.Halo(level),
                               chrome: PlayLayout.Chrome(level, swatches: false))
                XCTAssertNotEqual(l.kind, .column)
                let r = l.side / 2
                for slot in level.lenses {
                    let net = level.scramble.filter { $0.rod == slot }.reduce(0) { $0 + $1.steps }
                    let room = try! XCTUnwrap(LevelView.trackRoom(knob: r + level.layout.rods[slot].y * r, bounds: l.trackBounds))
                    XCTAssertTrue(room.contains(-net), "\(level.id) lens \(slot) needs \(-net), the pane shows \(room) in \(window)")
                    XCTAssertTrue(room.contains(-3) && room.contains(3), "\(level.id) lens \(slot): \(room) in \(window)")
                }
            }
        }
    }

    @MainActor func testBesideTheMenuALensTrackStopsUnderTheTitle() {
        // A zoom the wrong way never draws through the header's count (Lens 08's top lens held +14 once ran into it).
        for level in Pack.lens.levels {
            for fold in [nil, book] as [CGRect?] {
                let l = layout(window: open.window, insets: open.insets, fold: fold, halo: PlayLayout.Halo(level),
                               chrome: PlayLayout.Chrome(level, swatches: false))
                XCTAssertEqual(l.kind, .split)
                let b = try! XCTUnwrap(l.trackBounds), glass = l.stage.minY + (l.stage.height - l.side) / 2
                XCTAssertEqual(b.minY + glass, l.tankPane.minY + l.chrome.above, accuracy: 0.001, "under the title")
                XCTAssertEqual(b.maxY, try! XCTUnwrap(l.bounds).maxY, "down to the pane's foot, as before")
                let r = l.side / 2
                for slot in level.lenses {
                    let knob = r + level.layout.rods[slot].y * r
                    let room = try! XCTUnwrap(LevelView.trackRoom(knob: knob, bounds: l.trackBounds))
                    XCTAssertGreaterThanOrEqual(knob - CGFloat(room.upperBound) * LevelView.trackPitch, b.minY - 0.001, level.id)
                }
            }
        }
        // No chrome lies in the tabletop's tank pane, so its track keeps the whole pane.
        let t = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table)
        XCTAssertEqual(t.kind, .tabletop)
        XCTAssertEqual(t.trackBounds, t.bounds)
        XCTAssertNil(layout(window: CGSize(width: 440, height: 956), insets: (62, 0, 34, 0)).trackBounds, "the column caps nothing")
    }

    // MARK: The menu (stage 4)

    /// As the menu measures the window: its safe area's size, the insets round it and the fold in its own space.
    private func menu(window: CGSize, insets i: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat),
                      fold: CGRect? = nil) -> MenuLayout {
        MenuLayout.of(size: CGSize(width: window.width - i.leading - i.trailing, height: window.height - i.top - i.bottom),
                      insets: EdgeInsets(top: i.top, leading: i.leading, bottom: i.bottom, trailing: i.trailing),
                      fold: fold.map { $0.offsetBy(dx: -i.leading, dy: -i.top) })
    }

    func testEveryIPhoneKeepsTodaysMenu() {
        // The SE, the Pro Max, the Duo closed, the Duo open upright and flat, and a tall half of Split View.
        for (window, insets) in [(CGSize(width: 375, height: 667), (20.0, 0.0, 0.0, 0.0)), (CGSize(width: 440, height: 956), (62, 0, 34, 0)),
                                 (CGSize(width: 466, height: 678), (0, 0, 34, 84)), (CGSize(width: 669, height: 951), (59, 0, 34, 0)),
                                 (CGSize(width: 475, height: 669), (24, 0, 21, 0))] as [(CGSize, (CGFloat, CGFloat, CGFloat, CGFloat))] {
            let m = menu(window: window, insets: insets)
            XCTAssertEqual(m, .column, "\(window)")
            XCTAssertFalse(m.wide)
            XCTAssertFalse(m.splits, "\(window): a level opened there covers the menu, as on every iPhone")
        }
    }

    func testTheTabletopsMenuKeepsEveryPartOffTheFold() {
        // The Duo upright and folded on a table (d4-table, deferred to stage 5): the title, strip and list in the
        // upright half, the dock, or a card or the archive over it, in the half lying flat.
        let insets = (top: CGFloat(59), leading: CGFloat(0), bottom: CGFloat(34), trailing: CGFloat(0))
        let m = menu(window: CGSize(width: 669, height: 951), insets: insets, fold: table)
        let list = try! XCTUnwrap(m.list), side = try! XCTUnwrap(m.side), dock = try! XCTUnwrap(m.dock)
        // In the menu's space: the fold less the top inset.
        let fold = table.offsetBy(dx: 0, dy: -insets.top)
        XCTAssertEqual(list.minY, 0)
        XCTAssertEqual(list.maxY, fold.minY - PlayLayout.margin, accuracy: 0.001, "the list ends 16 pt above the fold")
        XCTAssertEqual(side.minY, fold.maxY + PlayLayout.margin, accuracy: 0.001, "a card starts 16 pt below it")
        XCTAssertEqual(side.maxY, 951 - insets.top - insets.bottom, accuracy: 0.001)
        XCTAssertEqual(dock, side, "the dock lies in the half a card covers")
        for r in [list, side] {
            XCTAssertEqual(r.minX, 0)
            XCTAssertEqual(r.width, 669, "each runs the window's width")
            XCTAssertGreaterThanOrEqual(r.height, PlayLayout.minPane)
        }
        XCTAssertTrue(m.wide, "a card opens beside the list, not over it")
        XCTAssertFalse(m.splits, "a level opened in the tabletop covers the menu, its tank below the fold")
        // Lying flat, the Duo upright keeps today's menu.
        XCTAssertEqual(menu(window: CGSize(width: 669, height: 951), insets: insets), .column)
    }

    func testBesidePlayTheListTakesTheTrailingHalfAndACardTheSame() {
        for fold in [nil, book] as [CGRect?] {
            let m = menu(window: open.window, insets: open.insets, fold: fold)
            XCTAssertTrue(m.splits, "a level opened on the open Duo plays beside the menu")
            let side = try! XCTUnwrap(m.side)
            // What PlayStack gives the menu's part: the play screen's trailing half, in the menu's space.
            let play = layout(window: open.window, insets: open.insets, fold: fold)
            let slot = try! XCTUnwrap(play.menuPane).offsetBy(dx: PlayLayout.margin, dy: 0)
            XCTAssertEqual(slot.minX, side.minX, accuracy: 0.001, "the list starts where a card does")
            XCTAssertEqual(slot.maxX, side.maxX - PlayLayout.margin, accuracy: 0.001, "inside the play screen's margin")
            XCTAssertEqual(slot.height, side.height, "the whole height: the level's chrome is round its tank")
            let beside = m.beside(slot)
            XCTAssertEqual(beside.list, slot)
            XCTAssertEqual(beside.side, side, "a card or the archive covers the whole trailing half")
            XCTAssertNil(beside.dock, "the dock stays under the list")
            XCTAssertTrue(beside.splits)
        }
    }

    @MainActor func testBesidePlayTheRowOfThePlayingLevelOpensNothing() {
        let l11 = Level.plughole[10], l12 = Level.plughole[11]
        XCTAssertTrue(MenuView.opens(l12, playing: nil))
        XCTAssertTrue(MenuView.opens(l12, playing: l11))
        XCTAssertFalse(MenuView.opens(l11, playing: l11), "the playing level is open already")
        // Endless's row would deal a new run over the one playing; its new run does.
        let run = Level.endless(Run(seed: 7)), other = Level.endless(Run(seed: 8))
        XCTAssertFalse(MenuView.opens(other, playing: run))
        XCTAssertTrue(MenuView.opens(other, playing: run, anew: true))
        XCTAssertTrue(MenuView.opens(run, playing: l11))
    }

    @MainActor func testACardPutAwayBesidePlayReturnsOnlyWithTheLevelItOpened() {
        let lens = Pack.lens.levels[3], prism = Pack.prism.levels[0], tier = Level.plughole[4]
        XCTAssertTrue(RootView.returns(to: (.pack(.lens), false), from: lens))
        XCTAssertFalse(RootView.returns(to: (.pack(.lens), false), from: prism))
        XCTAssertFalse(RootView.returns(to: (.pack(.lens), false), from: tier), "a tier's level picked meanwhile")
        XCTAssertTrue(RootView.returns(to: (.complete, false), from: prism), "the bundle's card opens each of its packs")
        let day = Level.daily(Calendar(identifier: .gregorian).date(byAdding: .day, value: -3, to: .now)!, archived: true)
        XCTAssertTrue(RootView.returns(to: (nil, true), from: day))
        XCTAssertFalse(RootView.returns(to: (nil, true), from: tier))
    }

    func testAPickBesidePlayIsDecidedBeforeThePlayingLevelLeaves() {
        let l11 = Level.plughole[10], l12 = Level.plughole[11], lens4 = Pack.lens.levels[3]
        XCTAssertEqual(RootView.besidePick(l11, playing: l11, gated: false, opens: true), .same)
        XCTAssertEqual(RootView.besidePick(l12, playing: l11, gated: false, opens: true), .switches)
        // Neither leaves the playing level: no quit sent, no finger let go, its try where it is.
        XCTAssertEqual(RootView.besidePick(lens4, playing: l11, gated: true, opens: true), .stays, "a gate opens its card")
        XCTAssertEqual(RootView.besidePick(l12, playing: l11, gated: false, opens: false), .stays, "a withheld level")
    }

    @MainActor func testTheTabletopsSettingsSheetKeepsToTheHalfLyingFlat() {
        // On a phone, sized to what it holds, or past 0.9 of the window scrolling with a large detent: as before.
        XCTAssertEqual(SettingsSheet.detents(content: 528, window: 951, room: nil), [.height(528)])
        XCTAssertEqual(SettingsSheet.detents(content: 900, window: 951, room: nil), [.height(951 * 0.6), .large])
        // The tabletop: no taller than from the window's foot to the dock's top, 16 pt under the fold; it scrolls.
        let insets = (top: CGFloat(59), leading: CGFloat(0), bottom: CGFloat(34), trailing: CGFloat(0))
        let dock = try! XCTUnwrap(menu(window: CGSize(width: 669, height: 951), insets: insets, fold: table).dock)
        let room = dock.height + insets.bottom
        XCTAssertGreaterThanOrEqual(951 - room, table.maxY + PlayLayout.margin - 0.001, "its top stays clear of the fold")
        XCTAssertEqual(SettingsSheet.detents(content: 528, window: 951, room: room), [.height(room)])
        XCTAssertEqual(SettingsSheet.detents(content: 300, window: 951, room: room), [.height(300)])
    }

    func testTheOpenDuosMenuPutsTheListAndTheCardEitherSideOfTheFold() {
        for fold in [nil, book] as [CGRect?] {
            let m = menu(window: open.window, insets: open.insets, fold: fold)
            let list = try! XCTUnwrap(m.list), side = try! XCTUnwrap(m.side)
            // In window points (the leading inset is 0): each half 16 pt clear of the fold, or of the middle.
            let f = fold ?? CGRect(x: open.window.width / 2, y: 0, width: 0, height: open.window.height)
            XCTAssertEqual(list.minX, 0, "the list keeps its own 20 pt margin from the screen's edge")
            XCTAssertEqual(list.maxX, f.minX - PlayLayout.margin, accuracy: 0.001)
            XCTAssertEqual(side.minX, f.maxX + PlayLayout.margin, accuracy: 0.001)
            XCTAssertEqual(side.maxX, open.window.width - open.insets.trailing, accuracy: 0.001, "the card stops at the status column")
            XCTAssertGreaterThanOrEqual(min(list.width, side.width), PlayLayout.minPane)
            XCTAssertEqual(list.height, open.window.height - open.insets.top - open.insets.bottom)
            XCTAssertEqual(side.height, list.height)
            // A readable width, near a phone's: the Pro Max's list is 440 pt across.
            XCTAssertEqual(list.width, 459.5, accuracy: fold == nil ? 0.001 : 10)
        }
    }

    func testTheMenuSplitsWherePlaySplits() {
        // The same rule, so the list and the tank share the leading half wherever either splits.
        for (window, insets, fold) in [(open.window, open.insets, nil), (open.window, open.insets, book),
                                       (CGSize(width: 669, height: 951), (59, 0, 34, 0), table),
                                       (CGSize(width: 600, height: 400), (0, 0, 0, 0), nil),
                                       (CGSize(width: 1000, height: 500), (0, 30, 0, 20), nil)] as [(CGSize, (CGFloat, CGFloat, CGFloat, CGFloat), CGRect?)] {
            let m = menu(window: window, insets: insets, fold: fold), play = layout(window: window, insets: insets, fold: fold)
            XCTAssertEqual(m.splits, play.kind == .split, "\(window)")
            XCTAssertEqual(m.wide, play.kind != .column, "\(window)")
            guard m.splits, let list = m.list, let side = m.side else { continue }
            // Play's panes are inside its 16 pt side margins, the menu's in the whole safe area.
            let tank = play.tankPane.offsetBy(dx: PlayLayout.margin, dy: 0)
            let trailing = try! XCTUnwrap(play.menuPane).offsetBy(dx: PlayLayout.margin, dy: 0)
            XCTAssertLessThanOrEqual(list.minX, tank.minX, "\(window)")
            XCTAssertEqual(list.maxX, tank.maxX, accuracy: 0.001, "the list's half ends where the tank's pane does, \(window)")
            XCTAssertEqual(side.minX, trailing.minX, accuracy: 0.001, "the card's starts where play's trailing half does, \(window)")
            XCTAssertGreaterThan(side.minX - list.maxX, 2 * PlayLayout.margin - 0.001, "\(window)")
        }
    }
}
