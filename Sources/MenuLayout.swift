// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Where the menu puts its list and a pack card or the archive. Wherever play splits, the list takes the leading half
/// and a card or the archive opens in the trailing half beside it, not over it, so the fold never runs through either;
/// the list's own 20 pt margins sit inside its half, and its dock under it, as on a phone. A level opened there plays
/// in the leading half, its chrome round the tank, and the list moves to the trailing half (Jack's calls DUOMENU = B
/// and s5-chrome = B, round 16). The tabletop is the split turned on its side: the title, strip and list in the upright
/// half, and the dock, or a card or the archive over it, in the half lying flat. Anywhere else, every iPhone among
/// them, the menu is today's: the card over the whole of it.
struct MenuLayout: Equatable {
    /// In the menu's safe area. Nil in the column.
    let list: CGRect?
    let side: CGRect?
    /// The tabletop's dock, below the fold and apart from the list; nil where the dock sits under the list.
    var dock: CGRect? = nil

    /// A card or the archive opens beside the list, not over it.
    var wide: Bool { list != nil }
    /// A level opened here plays beside the menu.
    var splits: Bool { list != nil && dock == nil }

    static let column = MenuLayout(list: nil, side: nil)

    /// From the menu's GeometryReader, as `PlayLayout.of` takes the play screen's: its size, the window's safe-area
    /// insets round it and the fold in its own space.
    static func of(size: CGSize, insets: EdgeInsets, fold: CGRect? = nil) -> MenuLayout {
        // The split's rule is play's, panes and all; play's are inside its 16 pt side margins, the menu's are not.
        let play = PlayLayout.of(size: size, insets: insets, fold: fold, scale: 1)
        switch play.kind {
        case .column:
            return .column
        case .tabletop:
            // Play's panes run the menu's whole width; only their margins from the fold carry over.
            let lower = CGRect(x: 0, y: play.tankPane.minY, width: size.width, height: play.tankPane.height)
            return MenuLayout(list: CGRect(x: 0, y: 0, width: size.width, height: play.chromePane.maxY), side: lower, dock: lower)
        case .split:
            let m = PlayLayout.margin, leading = (play.menuPane?.minX ?? 0) + m
            return MenuLayout(list: CGRect(x: 0, y: 0, width: play.tankPane.maxX + m, height: size.height),
                              side: CGRect(x: leading, y: 0, width: size.width - leading, height: size.height))
        }
    }

    /// Beside a playing level, in the menu's space: the list in `slot`, the trailing half as the level lays it out, and
    /// a card or the archive over the whole trailing half.
    func beside(_ slot: CGRect) -> MenuLayout {
        MenuLayout(list: slot, side: side)
    }
}
