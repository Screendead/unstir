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
        // The glass and its rim fit the pane with the chrome round it, near the size the shader's limits were tuned at.
        XCTAssertLessThanOrEqual(l.side * PlayLayout.rim, l.tankPane.width)
        XCTAssertLessThanOrEqual(l.chrome.above + PlayStack.gap + l.side * PlayLayout.rim + l.chrome.below, l.tankPane.height)
        XCTAssertEqual(l.side, 424, accuracy: 1)
        XCTAssertLessThanOrEqual(l.side * 3, PlayLayout.maxPixels)
    }

    func testTheOpenDuoUprightKeepsTheColumnAtTheCap() {
        let l = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0))
        XCTAssertEqual(l.kind, .column)
        XCTAssertEqual(l.side, PlayLayout.maxPixels / 3, accuracy: 0.001, "about 1630 px uncapped")
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
        XCTAssertEqual(l.side, 443.5 / PlayLayout.rim, accuracy: 0.001)
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

    func testTheTabletopsSpacersShareWhatTheChromeLeaves() {
        XCTAssertEqual(PlayStack.share(624, used: 200, spacers: 2), 212, "centred round the chrome")
        XCTAssertEqual(PlayStack.share(100, used: 200, spacers: 2), 0, "a tall card: the spacers give way")
    }

    func testTheGlassShrinksBesideTheMenuOnlyWhereTheChromeNeedsIt() {
        func side(_ level: Level, swatches: Bool = false) -> CGFloat {
            layout(window: open.window, insets: open.insets, halo: PlayLayout.Halo(level),
                   chrome: PlayLayout.Chrome(level, swatches: swatches)).side
        }
        // Stage 1's glass, the width of the leading half: every tier's level, Lens's, and Prism's read by colour.
        let stage1 = layout(window: open.window, insets: open.insets).side
        XCTAssertEqual(stage1, 443.5 / PlayLayout.rim, accuracy: 0.001)
        for level in [Level.plughole[10], Level.whirlpool[0], Level.vortex[0], Level.lens[0], Level.prism[0],
                      Level.daily(.now), Level.plughole[0]] {
            XCTAssertEqual(side(level), stage1, accuracy: 0.001, level.id)
        }
        // Escapement's taller header and two lines of serif: 9 pt less.
        XCTAssertEqual(side(Level.escapement[0]), (624 - 70 - 108 - PlayStack.gap) / PlayLayout.rim, accuracy: 0.001)
        XCTAssertEqual(stage1 - side(Level.escapement[0]), 9, accuracy: 1)
        // Maelstrom's rim lesson over twelve, under the title: 5 pt less.
        XCTAssertEqual(side(Level.maelstrom[0]), (624 - 60 - 106 - RimLesson.overRim) / PlayLayout.rim, accuracy: 0.001)
        XCTAssertEqual(stage1 - side(Level.maelstrom[0]), 5, accuracy: 1)
        // Prism read by its letters, the swatches under the caption: 30 pt less.
        XCTAssertEqual(side(Level.prism[0], swatches: true), (624 - 60 - 140 - PlayStack.gap) / PlayLayout.rim, accuracy: 0.001)
        XCTAssertEqual(stage1 - side(Level.prism[0], swatches: true), 30, accuracy: 1)
        // Endless keeps stage 3's, held by the brim's width.
        XCTAssertEqual(side(Level.endless(Run(seed: 7))), 348, accuracy: 1)
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
        let mono = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let serif = UIFont.systemFont(ofSize: 15).fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: 15) }!
        func lines(_ text: String, _ font: UIFont) -> Int {
            let h = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                    options: [.usesLineFragmentOrigin], attributes: [.font: font], context: nil).height
            return Int((h / font.lineHeight).rounded())
        }
        let levels = Tier.allCases.flatMap(\.levels) + Pack.allCases.flatMap(\.levels) + [Level.daily(.now), Level.endless(Run(seed: 7))]
        for level in levels {
            XCTAssertLessThanOrEqual(lines(level.note, level.page.paper ? serif : mono), 2, level.id)
        }
        for text in [LevelView.refills, "Practice: this day's best was set on its day.", "Practice: only the first try counts.",
                     "watch the stir \u{00B7} tap to skip"] {
            XCTAssertLessThanOrEqual(lines(text, mono), 2, text)
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
        XCTAssertEqual(PlayLayout.Halo(Level.maelstrom[0]), PlayLayout.Halo(ring: 0, above: RimLesson.overRim), "the rim lesson's arc")
        XCTAssertEqual(PlayLayout.Halo(Level.plughole[10]), PlayLayout.Halo(), "drawn wholly on the glass and rim")
        XCTAssertEqual(PlayLayout.Halo(Level.lens[0]), PlayLayout.Halo())
        XCTAssertEqual(PlayLayout.Halo(Level.escapement[1]), PlayLayout.Halo())
    }

    func testEndlesssBrimStaysInsideTheTanksPaneInEveryPose() {
        let halo = PlayLayout.Halo(Level.endless(Run(seed: 7)))
        for (pose, fold) in [("open", nil), ("book", book)] as [(String, CGRect?)] {
            let l = layout(window: open.window, insets: open.insets, fold: fold, halo: halo)
            XCTAssertEqual(l.kind, .split, pose)
            inside(reach(l), l.tankPane, pose)
            XCTAssertEqual(reach(l).width, l.tankPane.width, accuracy: 0.001, "\(pose): as large as the brim allows")
        }
        let t = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table, halo: halo)
        XCTAssertEqual(t.kind, .tabletop)
        inside(reach(t), t.tankPane, "tabletop")
        XCTAssertEqual(reach(t).height, t.tankPane.height, accuracy: 0.001)
        // Smaller than every other level's glass in the same pose, by the brim's reach.
        XCTAssertEqual(layout(window: open.window, insets: open.insets).side, 424, accuracy: 1)
        XCTAssertEqual(layout(window: open.window, insets: open.insets, halo: halo).side, 348, accuracy: 1)
        XCTAssertEqual(t.side, 326, accuracy: 1)
    }

    func testTheRimLessonStaysAboveTheGlassInsideTheTabletopsLowerHalf() {
        let halo = PlayLayout.Halo(Level.maelstrom[0])
        let l = layout(window: CGSize(width: 669, height: 951), insets: (59, 0, 34, 0), fold: table, halo: halo)
        XCTAssertEqual(l.kind, .tabletop)
        inside(reach(l), l.tankPane, "tabletop")
        XCTAssertEqual(l.stage.maxY, l.tankPane.maxY, accuracy: 0.001, "sat on the pane's foot")
        XCTAssertEqual(l.stage.minY - l.tankPane.minY, halo.above, accuracy: 0.001, "the lesson's room above, no more")
        // The split's lesson lies between the title and the glass, held by the folded half's width there.
        let split = layout(window: open.window, insets: open.insets, fold: book, halo: halo)
        XCTAssertEqual(split.side, layout(window: open.window, insets: open.insets, fold: book).side)
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
