// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import XCTest
@testable import Unstir

final class PlayLayoutTests: XCTestCase {
    /// As the play screen's GeometryReader measures the window: the safe area's size and the insets round it.
    private func layout(window: CGSize, insets: (top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat),
                        scale: CGFloat = 3) -> PlayLayout {
        PlayLayout.of(size: CGSize(width: window.width - insets.leading - insets.trailing,
                                   height: window.height - insets.top - insets.bottom),
                      insets: EdgeInsets(top: insets.top, leading: insets.leading, bottom: insets.bottom, trailing: insets.trailing),
                      scale: scale)
    }

    func testEveryIPhoneKeepsTodaysColumn() {
        // Content sizes measured on each simulator (PR #112): SE, Pro Max, the Duo closed.
        for (window, content, scale) in [(CGSize(width: 375, height: 667), CGSize(width: 343, height: 647), 2.0),
                                         (CGSize(width: 440, height: 956), CGSize(width: 408, height: 860), 3),
                                         (CGSize(width: 466, height: 678), CGSize(width: 350, height: 644), 3)] {
            let l = PlayLayout.of(content: content, window: window, scale: scale)
            XCTAssertEqual(l.kind, .column, "\(window)")
            XCTAssertEqual(l.side, min(content.width, content.height - 290) / 1.045, "\(window): today's formula")
            XCTAssertLessThan(l.side * scale, PlayLayout.maxPixels, "\(window): no phone reaches the cap")
        }
    }

    func testTheOpenDuoSplitsWithTheTankWhollyInTheLeadingHalf() {
        // The inner display opened like a book: the status column on the trailing edge (its width assumed from the
        // closed display's 84 pt), the home indicator below.
        let window = CGSize(width: 951, height: 669)
        let l = layout(window: window, insets: (24, 0, 21, 84))
        XCTAssertEqual(l.kind, .split)
        // In window points: the tank's pane ends short of the fold, the chrome's starts past it.
        let fold = window.width / 2
        XCTAssertLessThanOrEqual(PlayLayout.margin + l.tankPane.maxX, fold - PlayLayout.margin)
        XCTAssertGreaterThanOrEqual(PlayLayout.margin + l.chromePane.minX, fold + PlayLayout.margin)
        XCTAssertGreaterThanOrEqual(l.chromePane.width, PlayLayout.minPane)
        // The glass and its rim fit the pane, near the size the shader's limits were tuned at.
        XCTAssertLessThanOrEqual(l.side * PlayLayout.rim, l.tankPane.width)
        XCTAssertLessThanOrEqual(l.side * PlayLayout.rim, l.tankPane.height - PlayLayout.splitReserve)
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
        XCTAssertEqual(84 + PlayLayout.margin + a.chromePane.minX, 951 / 2 + PlayLayout.margin, accuracy: 0.001)
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
}
