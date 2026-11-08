// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Where the play screen puts the tank. A window taller than wide, every iPhone's, keeps the column: header, tank,
/// caption and controls stacked. One wider than tall, as the iPhone Duo's inner display gives when opened like a book
/// whatever the portrait lock, splits where the fold runs: the tank in the leading half with the header and title
/// above it and the caption and controls below, and the menu beside it in the trailing half (Jack's calls DUOMENU = B
/// and s5-chrome = B, round 16), so folding the phone never puts the fold through the tank. A tall window folded
/// across, the Duo upright on a table, is the tabletop: everything else in the upright half, the tank in the half lying
/// flat.
struct PlayLayout: Equatable {
    enum Kind: Equatable { case column, split, tabletop }

    let kind: Kind
    /// The glass's side in points; the rim adds `rim` round it.
    let side: CGFloat
    /// In the content's own points (inside the 16 pt side margins): the tank's pane and the chrome's. The column's are
    /// both the whole content, and so are the split's leading half.
    let tankPane: CGRect
    let chromePane: CGRect
    /// The split's trailing half, the menu's beside the level, and a result card's over it; nil elsewhere.
    var menuPane: CGRect? = nil
    /// What the level draws round its glass, which the split and the tabletop keep inside the tank's pane.
    var halo = Halo()
    /// What the split's chrome takes above and below the tank.
    var chrome = Chrome()

    /// How far a level draws past the rim, from its shape alone, never its state, so no lesson or spill resizes the
    /// glass. The column leaves all of it to the screen's edges, as every iPhone always has.
    struct Halo: Equatable {
        /// All the way round, as a share of the glass's radius: endless's brim, glow and drops out to `Brim.reach`.
        var ring: CGFloat = 0
        /// Above the rim only, in points: the tank's rim lesson, its arc and ghost finger over twelve o'clock.
        var above: CGFloat = 0
    }

    /// The split's chrome round the tank, in points, from the level's shape and whether Prism's swatches show: colour
    /// letters or Differentiate Without Colour turned on or off mid-level resizes Prism's glass by 30 pt, letting go a
    /// drag as a change of pose does. The play screen's text is fixed in size, so no type size changes it; a result or
    /// lost card goes over the menu.
    /// As the parts measure (`testTheChromesRoomBesideTheMenuIsWhatItsPartsMeasure`): above, the header's 24 pt
    /// (Escapement's split-flap ticks 34) and the title's 36; below, the caption's 48 (two lines of the paper's serif
    /// 50), the swatches' 34 where they show, the column's 12 and the controls' 46.
    struct Chrome: Equatable {
        var above: CGFloat = 60
        var below: CGFloat = 106
    }

    /// The rim sits outside the glass, 0.045 of the radius on each side.
    static let rim: CGFloat = 1.045
    /// The column's room for everything above and below the tank.
    static let reserve: CGFloat = 290
    /// How far "unstirred." stands over the glass's stage, top to top, where there is room for it.
    static let words: CGFloat = 62
    /// The side margin the play screen keeps, and the gap each half keeps from the fold.
    static let margin: CGFloat = 16
    /// The glass's side, in pixels, past which it stops growing, which only the open Duo upright reaches (Jack's call
    /// duocap2 = D). The stack's limits were tuned at about 1137 px (`Tank.tunedPixels`): here the four-tap limit is
    /// 17 (`Tank.fourTaps(pixels:)`), the stack as deep as on a phone, and a deep one on a live picture may run up to
    /// 32% over the frame budget measured, the Duo's GPU unmeasured.
    static let maxPixels: CGFloat = 1471
    /// Narrower or shorter than this, a half can't hold the chrome (the result card's buttons, Escapement's ticks), so
    /// the window keeps the column.
    static let minPane: CGFloat = 300

    /// From what the play screen's GeometryReader measures, outside the side margins: its size, the window's safe-area
    /// insets round it, and the fold, the system's division region in the reader's own space (nil while the phone lies
    /// flat, or where the system has none). One proxy in one pass, so no offset or earlier layout moves the middle.
    static func of(size: CGSize, insets i: EdgeInsets, fold: CGRect? = nil, halo: Halo = Halo(), chrome: Chrome = Chrome(),
                   scale: CGFloat) -> PlayLayout {
        let window = CGSize(width: size.width + i.leading + i.trailing, height: size.height + i.top + i.bottom)
        let middle = window.width / 2 - i.leading - margin
        return of(content: CGSize(width: max(size.width - 2 * margin, 0), height: size.height), window: window,
                  fold: fold?.offsetBy(dx: -margin, dy: 0) ?? CGRect(x: middle, y: 0, width: 0, height: size.height),
                  halo: halo, chrome: chrome, scale: scale)
    }

    /// `content` is the size inside the side margins; `fold` where the window divides, in the content's space: a band
    /// the system reports, or else a line down the window's middle (the content's own middle if nil); `window` the
    /// whole window's size, safe areas and all; `halo` what the level draws past the rim; `chrome` what the split's
    /// chrome takes round it; `scale` the display's pixels per point.
    static func of(content: CGSize, window: CGSize, fold: CGRect? = nil, halo h: Halo = Halo(), chrome c: Chrome = Chrome(),
                   scale: CGFloat) -> PlayLayout {
        let cap = maxPixels / max(scale, 1)
        let whole = CGRect(origin: .zero, size: content)
        let column = PlayLayout(kind: .column, side: min(min(content.width, content.height - reserve) / rim, cap),
                                tankPane: whole, chromePane: whole)
        let f = fold ?? CGRect(x: content.width / 2, y: 0, width: 0, height: content.height)
        if f.width > f.height {
            let chrome = CGRect(x: 0, y: 0, width: content.width, height: f.minY - margin)
            let tank = CGRect(x: 0, y: f.maxY + margin, width: content.width, height: content.height - f.maxY - margin)
            guard min(chrome.height, tank.height) >= minPane else { return column }
            // The ring below the stage, and above it the ring or the lesson, whichever reaches further.
            let side = min(tank.width / (rim + h.ring), tank.height / (rim + h.ring), (tank.height - h.above) / (rim + h.ring / 2))
            return PlayLayout(kind: .tabletop, side: min(side, cap), tankPane: tank, chromePane: chrome, halo: h)
        }
        let tank = CGRect(x: 0, y: 0, width: f.minX - margin, height: content.height)
        let menu = CGRect(x: f.maxX + margin, y: 0, width: content.width - f.maxX - margin, height: content.height)
        // A band the system reports is a fold whatever the window's shape; the window's middle splits only a wide one.
        guard window.width > window.height || f.width > 0, min(tank.width, menu.width) >= minPane else { return column }
        // Between the title and the caption, with the column's 12 pt over the stage, or what reaches further there; the
        // ring reaches below it too.
        let side = min(tank.width / (rim + h.ring), (tank.height - c.above - c.below - max(PlayStack.gap, h.above)) / (rim + h.ring))
        return PlayLayout(kind: .split, side: min(side, cap), tankPane: tank, chromePane: tank, menuPane: menu, halo: h, chrome: c)
    }

    /// Where the glass and its rim stand in the split and the tabletop, in the content's space. The split's is centred
    /// in what its chrome leaves, so the spare room goes half over the stage and half over the controls; the
    /// tabletop's sits on its pane's foot less the ring, so what reaches above has the room left over.
    var stage: CGRect {
        let s = side * Self.rim, ring = halo.ring * side / 2
        let y: CGFloat
        switch kind {
        case .tabletop:
            y = tankPane.maxY - ring - s
        case .split:
            let top = chrome.above + max(PlayStack.gap, halo.above, ring)
            y = tankPane.minY + top + max(0, tankPane.height - top - s - ring - chrome.below) / 2
        case .column:
            y = tankPane.midY - s / 2
        }
        return CGRect(x: tankPane.midX - s / 2, y: y, width: s, height: s)
    }

    /// The tank's pane in the glass's own frame, its origin at the glass's top left: what is drawn round the glass
    /// keeps inside it. Nil in the column, whose limits are the screen's.
    var bounds: CGRect? {
        guard kind != .column else { return nil }
        let inset = (stage.width - side) / 2
        return tankPane.offsetBy(dx: -(stage.minX + inset), dy: -(stage.minY + inset))
    }

    /// Where a lens's track runs, in the glass's frame: `bounds`, less the split's header and title, so a zoom the wrong
    /// way never draws through the count.
    var trackBounds: CGRect? {
        guard let b = bounds, kind == .split else { return bounds }
        return CGRect(x: b.minX, y: b.minY + chrome.above, width: b.width, height: b.height - chrome.above)
    }

    /// Where the night forwards' lines end, down from the glass's top: nil under the glass, where the column and the
    /// split have room; in the tabletop, whose glass fills its half, at the foot of the upright half, as "unstirred.".
    var filmFoot: CGFloat? {
        kind == .tabletop ? chromePane.maxY - (stage.minY + (stage.width - side) / 2) : nil
    }

    /// How far "unstirred." stands above the stage's top, top to top. The tabletop's tank fills its half, so the word
    /// stands at the foot of the upright half instead, as far from the fold as the panes are; the split's title stands
    /// over its tank, so the word heads the card over the menu instead (nil).
    var words: CGFloat? {
        switch kind {
        case .column: Self.words
        case .tabletop: stage.minY - chromePane.maxY + Self.wordsHeight
        case .split: nil
        }
    }

    /// The height "unstirred." takes, 22 pt mono, give or take its line's leading.
    static let wordsHeight: CGFloat = 28
}

extension PlayLayout {
    /// The fold while the phone is folded, in `geo`'s own space: the harness's (in window points), else the system's
    /// division region.
    static func fold(_ geo: GeometryProxy, harness: CGRect?) -> CGRect? {
        if let f = harness { return f.offsetBy(dx: -geo.safeAreaInsets.leading, dy: -geo.safeAreaInsets.top) }
        // The iOS 27.1 SDK's SwiftUI (8.1) brought the regions; CI's Xcode has an older one.
        #if canImport(SwiftUI, _version: 8.1)
        guard #available(iOS 27.1, *) else { return nil }
        return geo.reservedRegions(kind: .division).first { $0.isActive }?.frame
        #else
        return nil
        #endif
    }
}

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

/// What each part of the play screen is to `PlayStack`; a spacer is untagged. `menu` is the split's trailing half, the
/// menu's beside play.
enum PlayPart: LayoutValueKey {
    case spacer, stage, chrome, menu
    static let defaultValue = PlayPart.spacer

    /// A part tagged for `PlayStack`, read by VoiceOver as one group at `read`: the higher, the sooner.
    struct Tagged: ViewModifier {
        let part: PlayPart
        let read: Double

        func body(content: Content) -> some View {
            content.accessibilityElement(children: .contain).accessibilitySortPriority(read)
                .layoutValue(key: PlayPart.self, value: part)
        }
    }

    static func chrome(read: Double) -> Tagged { Tagged(part: .chrome, read: read) }
    static func stage(read: Double) -> Tagged { Tagged(part: .stage, read: read) }
}

/// The split's and the tabletop's arrangement of the play screen's parts. The tabletop's: the stage alone in the
/// tank's pane, the rest stacked in the chrome's pane as the column stacks them, its spacers sharing what is left. The
/// split's: the chrome round the stage in the leading half (`placeRound`), the menu's part over the trailing half. The
/// column is a plain `VStackLayout`, and all go through one `AnyLayout`, so every part keeps its identity, and so its
/// state and animations, as the window changes between them.
struct PlayStack: SwiftUI.Layout {
    let layout: PlayLayout
    /// Handed what the split's chrome measures round the stage, which `PlayLayout.Chrome` must hold.
    var measured: (@Sendable (PlayLayout.Chrome) -> Void)? = nil

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        if layout.kind == .split { return placeRound(in: bounds, subviews: subviews) }
        let pane = layout.chromePane.offsetBy(dx: bounds.minX, dy: bounds.minY)
        let across = ProposedViewSize(width: pane.width, height: nil)
        var used: CGFloat = 0, spacers = 0
        for s in subviews {
            switch s[PlayPart.self] {
            case .chrome: used += s.sizeThatFits(across).height
            case .spacer: spacers += 1
            case .stage, .menu: break
            }
        }
        let gap = Self.share(pane.height, used: used, spacers: spacers)
        var y = pane.minY
        for s in subviews {
            switch s[PlayPart.self] {
            case .stage:
                let r = layout.stage.offsetBy(dx: bounds.minX, dy: bounds.minY)
                s.place(at: CGPoint(x: r.midX, y: r.midY), anchor: .center, proposal: ProposedViewSize(r.size))
            case .spacer:
                s.place(at: CGPoint(x: pane.midX, y: y), anchor: .top, proposal: ProposedViewSize(width: pane.width, height: gap))
                y += gap
            case .chrome:
                let h = s.sizeThatFits(across).height
                s.place(at: CGPoint(x: pane.midX, y: y), anchor: .top, proposal: ProposedViewSize(width: pane.width, height: h))
                y += h
            case .menu: break
            }
        }
    }

    /// The split: the parts before the stage down from the pane's top, the spacer among them filling to the stage; those
    /// after it down from under the stage and its ring as far as the next spacer; the rest up from the pane's foot, the
    /// spacer filling between; and the menu's part over the trailing half.
    private func placeRound(in bounds: CGRect, subviews: LayoutSubviews) {
        let pane = layout.tankPane.offsetBy(dx: bounds.minX, dy: bounds.minY)
        let stage = layout.stage.offsetBy(dx: bounds.minX, dy: bounds.minY)
        let across = ProposedViewSize(width: pane.width, height: nil)
        let parts = subviews.map { $0[PlayPart.self] }
        guard let s = parts.firstIndex(of: .stage) else { return }
        let foot = parts[(s + 1)...].firstIndex(of: .spacer) ?? parts.endIndex
        func put(_ i: Int, _ y: CGFloat, _ h: CGFloat) {
            subviews[i].place(at: CGPoint(x: pane.midX, y: y), anchor: .top, proposal: ProposedViewSize(width: pane.width, height: h))
        }
        var y = pane.minY, above: CGFloat = 0, below = Self.gap
        for i in parts.indices[..<s] {
            let h = parts[i] == .spacer ? max(0, stage.minY - y) : subviews[i].sizeThatFits(across).height
            if parts[i] == .chrome { above += h }
            put(i, y, h)
            y += h
        }
        subviews[s].place(at: CGPoint(x: stage.midX, y: stage.midY), anchor: .center, proposal: ProposedViewSize(stage.size))
        y = stage.maxY + layout.halo.ring * layout.side / 2
        for i in parts.indices[(s + 1)..<foot] where parts[i] == .chrome {
            let h = subviews[i].sizeThatFits(across).height
            below += h
            put(i, y, h)
            y += h
        }
        var bottom = pane.maxY
        for i in parts.indices[foot...].reversed() where parts[i] == .chrome {
            let h = subviews[i].sizeThatFits(across).height
            below += h
            bottom -= h
            put(i, bottom, h)
        }
        measured?(PlayLayout.Chrome(above: above, below: below))
        if foot < parts.endIndex { put(foot, y, max(0, bottom - y)) }
        if let menu = layout.menuPane?.offsetBy(dx: bounds.minX, dy: bounds.minY) {
            for i in parts.indices where parts[i] == .menu {
                subviews[i].place(at: menu.origin, anchor: .topLeading, proposal: ProposedViewSize(menu.size))
            }
        }
    }

    /// The column's 12 pt between parts.
    nonisolated static let gap: CGFloat = 12

    /// What each of the tabletop's spacers takes of a pane `height` tall whose chrome needs `used`: the rest shared, so
    /// the chrome is centred round it; where there is no rest (a tall card, large type), they give way before the
    /// chrome runs past its pane.
    nonisolated static func share(_ height: CGFloat, used: CGFloat, spacers: Int) -> CGFloat {
        max(0, height - used) / CGFloat(max(spacers, 1))
    }
}

/// The tank, laid out at its new side at once (its picture, rings and knobs all drawn for it), scaled from the side it
/// had: animated, it glides from one pose's size to the other's.
struct Glide: ViewModifier, Animatable {
    var shown: CGFloat
    let side: CGFloat

    init(side: CGFloat) {
        shown = side
        self.side = side
    }

    nonisolated var animatableData: CGFloat {
        get { shown }
        set { shown = newValue }
    }

    func body(content: Content) -> some View {
        content.scaleEffect(side > 0 && shown > 0 ? shown / side : 1)
    }
}

extension PlayLayout.Chrome {
    /// What `level`'s chrome takes in the split: Escapement's split-flap ticks and two lines of its serif note, and the
    /// colour swatches where `swatches` shows them.
    init(_ level: Level, swatches: Bool) {
        above = level.ratchets.isEmpty ? 60 : 70
        below = (level.page.paper ? 50 : 48) + (swatches ? 34 : 0) + PlayStack.gap + 46
    }
}

extension PlayLayout.Halo {
    /// What `level` draws past the rim: endless's brim all round, and over twelve the rim lesson of a level whose rim
    /// turns the tank.
    init(_ level: Level) {
        ring = level.run == nil ? 0 : CGFloat((Brim.rOut + Brim.reach) / Brim.unit) - PlayLayout.rim
        above = level.motion == .none ? 0 : RimLesson.overRim
    }
}

extension EnvironmentValues {
    /// Handed to the split's `PlayStack` as `measured`.
    @Entry var chromeMeasured: (@Sendable (PlayLayout.Chrome) -> Void)? = nil
}
