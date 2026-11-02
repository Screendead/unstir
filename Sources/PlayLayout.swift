// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Where the play screen puts the tank. A window taller than wide, every iPhone's, keeps the column: header, tank,
/// caption and controls stacked. One wider than tall, as the iPhone Duo's inner display gives when opened like a book
/// whatever the portrait lock, splits at the window's middle, where the fold runs: the tank alone in the leading half,
/// everything else in the trailing half, so folding the phone never puts the fold through the tank.
struct PlayLayout: Equatable {
    enum Kind: Equatable { case column, split }

    let kind: Kind
    /// The glass's side in points; the rim adds `rim` round it.
    let side: CGFloat
    /// In the content's own points (inside the 16 pt side margins): the tank's pane and the chrome's. The column's are
    /// both the whole content.
    let tankPane: CGRect
    let chromePane: CGRect

    /// The rim sits outside the glass, 0.045 of the radius on each side.
    static let rim: CGFloat = 1.045
    /// The column's room for everything above and below the tank.
    static let reserve: CGFloat = 290
    /// The split's room above the tank for "unstirred.", which stands 62 pt over the glass, and as much below, so the
    /// tank stays centred in its half.
    static let splitReserve: CGFloat = 140
    /// The side margin the play screen keeps, and the gap each half keeps from the window's middle.
    static let margin: CGFloat = 16
    /// The glass's side, in pixels, past which it stops growing: the stack's limits (`Tank.maxStack`, `Tank.fourTaps`)
    /// were tuned at the largest phone's size, and every pixel past it is shader work they never measured.
    static let maxPixels: CGFloat = 1300
    /// Narrower than this, a half can't hold the chrome (the result card's buttons, Escapement's ticks), so the window
    /// keeps the column.
    static let minPane: CGFloat = 300

    /// From what the play screen's GeometryReader measures, outside the side margins: its size and the window's safe-area
    /// insets round it. One proxy in one pass, so no offset or earlier layout moves the middle.
    static func of(size: CGSize, insets i: EdgeInsets, scale: CGFloat) -> PlayLayout {
        let window = CGSize(width: size.width + i.leading + i.trailing, height: size.height + i.top + i.bottom)
        return of(content: CGSize(width: max(size.width - 2 * margin, 0), height: size.height), window: window,
                  middle: window.width / 2 - i.leading - margin, scale: scale)
    }

    /// `content` is the size inside the side margins; `middle` the window's middle line in the content's x, where the
    /// fold runs (the content's own middle if unknown); `window` the whole window's size, safe areas and all; `scale`
    /// the display's pixels per point.
    static func of(content: CGSize, window: CGSize, middle: CGFloat? = nil, scale: CGFloat) -> PlayLayout {
        let cap = maxPixels / max(scale, 1)
        let mid = middle ?? content.width / 2
        let lead = mid - margin, trail = content.width - (mid + margin)
        guard window.width > window.height, min(lead, trail) >= minPane else {
            let whole = CGRect(origin: .zero, size: content)
            return PlayLayout(kind: .column, side: min(min(content.width, content.height - reserve) / rim, cap),
                              tankPane: whole, chromePane: whole)
        }
        let tank = CGRect(x: 0, y: 0, width: lead, height: content.height)
        let chrome = CGRect(x: mid + margin, y: 0, width: trail, height: content.height)
        return PlayLayout(kind: .split, side: min(min(tank.width, tank.height - splitReserve) / rim, cap), tankPane: tank, chromePane: chrome)
    }
}
