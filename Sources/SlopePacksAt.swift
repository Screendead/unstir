// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Where the overview shows the packs' covers at full size, each one tap from its inside. Three places built for
/// Jack to pick from (2026-11-24); none is chosen, and no Release build has any: the overview then keeps its small
/// hollows in plughole's rock and the packs' line. The dive keeps its hollows in plughole's wall under every one.
enum SlopePacksAt: String {
    /// Glass floats riding the water line beside the bank, their names in the shallows under them.
    case surface = "a"
    /// Lit caves in a spur of the far ridge that reaches across the water between the shallows and plughole.
    case reef = "b"
    /// Lights hanging in the dark under maelstrom's last ledge, over endless.
    case deep = "c"

    /// UNSTIR_PACKSAT=a, the harness's.
    static let chosen: SlopePacksAt? = {
        #if DEBUG
        ProcessInfo.processInfo.environment["UNSTIR_PACKSAT"].flatMap(SlopePacksAt.init(rawValue:))
        #else
        nil
        #endif
    }()

    /// UNSTIR_PACKSHOW=1, the harness's: a scrolling overview opens on the covers.
    static let shows: Bool = {
        #if DEBUG
        ProcessInfo.processInfo.environment["UNSTIR_PACKSHOW"] == "1"
        #else
        false
        #endif
    }()
}

/// The covers' places at the overview for one screen, type size and shelf, measured from the band's own anchor: the
/// water line for the floats, the band's top for the others. Where their names would meet in a row the layout gives
/// way, never the type (docs/slope.md, 1.1).
struct SlopePackBand {
    /// What is written by a cover: its name, whether a glyph follows it, and its line.
    typealias Words = (name: String, mark: Bool, line: String?)

    let at: SlopePacksAt
    let offers: [Offer]
    let side: CGFloat
    let dress: SlopeHollow.Dress
    /// Each cover's middle.
    let seats: [CGPoint]
    /// The room each cover's words have beside it once the row has stacked; nil in a row, where they stand under it.
    let beside: CGFloat?
    /// The names in one line under a row whose covers stand too close for a name under each, and its top.
    let names: String?
    let namesAt: CGFloat
    /// The packs' line, its leading top, its width and how it is set in it.
    let caption: String?
    let captionAt: CGPoint
    let captionWidth: CGFloat
    let captionAlignment: Alignment
    /// How far under its anchor the band reaches.
    let height: CGFloat

    init?(at: SlopePacksAt?, offers: [Offer], words: [Words], caption: String?, size: CGSize, type: DynamicTypeSize) {
        guard let at, !offers.isEmpty, offers.count == words.count else { return nil }
        self.at = at
        self.offers = offers
        self.caption = caption
        let name = SlopeMeasure.font(.detail, at: type), data = UIFont.monospacedSystemFont(ofSize: name.pointSize, weight: .regular)
        let line = name.lineHeight
        func width(_ text: String, _ font: UIFont) -> CGFloat { ceil((text as NSString).size(withAttributes: [.font: font]).width) }
        let under = words.map { max(width($0.name, name) + ($0.mark ? name.pointSize + 4 : 0), $0.line.map { width($0, data) } ?? 0) }
        let lines: CGFloat = words.contains { $0.line != nil } ? 2 : 1
        let side: CGFloat = at == .surface ? 46 : SlopeHollow.full
        // The floats start clear of the stone on the bank and its word; the reef's caves clear of the slope's wall.
        let from: CGFloat = switch at {
        case .surface: 60 + width(String(localized: "settings"), name) + 16
        case .reef: 56
        case .deep: 24
        }
        let to = size.width - (at == .deep ? 24 : 20), gaps = CGFloat(offers.count - 1)
        // In a row with each name under its cover; where the names would meet, the covers alone with the names in one
        // line under them all; where even those don't fit, or at the largest sizes, stacked.
        let named = under.map { max($0, side) }, bare = under.map { _ in side }
        let fits = [named, bare].first { $0.reduce(0, +) + 10 * gaps <= to - from }
        if !type.isAccessibilitySize, let slots = fits {
            let across = slots.reduce(0, +), gap = gaps > 0 ? min((to - from - across) / gaps, at == .surface ? 22 : 30) : 0
            let run = across + gap * gaps
            // The floats keep to the trailing side; the others stand in the middle of their room.
            let left = at == .surface ? to - run : from + (to - from - run) / 2
            let list = slots == named ? nil : words.map { $0.name.replacingOccurrences(of: " ", with: "\u{00A0}") }.joined(separator: " \u{00B7} ")
            let wide = at == .surface ? min(max(run, 200), to - 20) : at == .reef ? to - left : to - from
            let said = caption.map { SlopeMeasure.height($0, .detail, width: wide, at: type) } ?? 0
            let listed = list.map { SlopeMeasure.height($0, .detail, width: wide, at: type) } ?? 0
            // Over the floats is air, so their line goes under their names; the others' leads them.
            let top = at == .surface ? -side * SlopeHollow.draught : 4 + said + (said > 0 ? 9 : 0)
            var x = left
            var seats: [CGPoint] = []
            for (i, slot) in slots.enumerated() {
                // Floats lie level on the water; caves and lights wander a little, never in a ruled row.
                let wander = at == .surface ? 0 : 4 * (1 + sin(2.1 * CGFloat(i) + 4.2))
                seats.append(CGPoint(x: x + slot / 2, y: top + side / 2 + wander))
                x += slot + gap
            }
            self.seats = seats
            self.side = side
            dress = at == .surface ? .float : at == .reef ? .hollow : .light
            beside = nil
            names = list
            let under = top + side + (at == .surface ? 0 : 8)
            namesAt = under + 8
            let foot = list == nil ? under + 10 * side / SlopeHollow.full + lines * (line + 2) : under + 8 + listed
            captionWidth = wide
            captionAlignment = at == .surface ? .trailing : at == .reef ? .leading : .center
            captionAt = CGPoint(x: at == .surface ? to - wide : at == .reef ? left : from, y: at == .surface ? foot + 5 : 4)
            height = at == .surface ? foot + 5 + said : foot
        } else {
            // Stacked under the anchor, as the dive sets a hollow at the largest sizes: the cover leading, its words
            // beside it, wrapping.
            let room = max(size.width - SlopeHollow.wordsX - 16, 60)
            captionWidth = room
            captionAt = CGPoint(x: SlopeHollow.wordsX, y: 14)
            captionAlignment = .leading
            var y = captionAt.y + (caption.map { SlopeMeasure.height($0, .detail, width: room, at: type) + 12 } ?? 0)
            var seats: [CGPoint] = []
            for word in words {
                let tall = SlopeMeasure.height(word.name, .detail, width: room - (word.mark ? name.pointSize + 4 : 0), at: type)
                    + (word.line.map { SlopeMeasure.height($0, .detail, width: room, at: type) + 2 } ?? 0)
                let row = max(SlopeHollow.full, tall)
                seats.append(CGPoint(x: SlopeHollow.largeX, y: y + SlopeHollow.full / 2))
                y += row + 16
            }
            self.seats = seats
            self.side = SlopeHollow.full
            dress = at == .deep ? .light : .hollow
            beside = room
            names = nil
            namesAt = 0
            height = y - 16
        }
    }

    /// How much further down the overview's first ledge stands for the floats' words: what they reach under the water
    /// line, less the room the shallows already leave over "today", whose first line's middle is 8 pt over the ledge.
    func sinks(lead: CGFloat, title: CGFloat) -> CGFloat { max(height + 12 - (lead - 8 - title / 2), 0) }
}

/// The packs' covers at the overview, in the band the plan has opened for them: each a `SlopeHollow` the menu's own
/// way of making one builds, so a tap opens its inside from where it lies.
struct SlopePackRow: View {
    let band: SlopePackBand
    let view: SlopeView
    /// "Lens is yours" (2.10), which stands in the packs' line's place while it is said.
    var yours: Offer?
    let hollow: (Offer, SlopeSpot) -> AnyView

    var body: some View {
        ZStack(alignment: .topLeading) {
            if band.at == .reef, band.beside == nil, let first = band.seats.first {
                SlopeReef(nose: first.x - band.side / 2 - 40, top: (band.seats.map(\.y).min() ?? 0) - band.side / 2 - 13,
                          foot: (band.seats.map(\.y).max() ?? 0) + band.side / 2 + 13)
                    .fill(LinearGradient(colors: [Color(0x04121A).opacity(0.3), Color(0x04121A).opacity(0.55)], startPoint: .leading, endPoint: .trailing))
                    .accessibilityHidden(true)
            }
            if let names = band.names {
                words(Text(names).font(.slope(.ui, .detail)).foregroundStyle(SlopeInk.ink.colour), at: band.namesAt) // loc: verbatim the packs' names
            }
            Group {
                if let yours {
                    Text(yours.yours).font(.slope(.place, .body)).foregroundStyle(yours.ink).transition(.opacity) // loc: verbatim localized by Offer
                } else if let caption = band.caption {
                    Text(caption).font(.slope(.ui, .detail)).ink(.ink3).transition(.opacity) // loc: verbatim localized by Menu.packsCaption
                }
            }
            .modifier(Lined(band: band, y: band.captionAt.y))
            .animation(.easeInOut(duration: 0.4), value: yours)
            ForEach(Array(band.offers.enumerated()), id: \.element) { i, offer in
                let seat = band.seats[i]
                hollow(offer, SlopeSpot(view: view, ledge: 0, point: seat, side: band.side, near: band.names == nil ? 1 : 0, dress: band.dress, beside: band.beside))
                    .offset(x: seat.x - band.side / 2, y: seat.y - band.side / 2)
            }
        }
        .frame(width: view.size.width, height: max(band.height, 1), alignment: .topLeading)
    }

    private func words(_ text: Text, at y: CGFloat) -> some View { text.modifier(Lined(band: band, y: y)) }

    /// A line of the band's own words, set in its width with the water's shade under it.
    private struct Lined: ViewModifier {
        let band: SlopePackBand
        let y: CGFloat

        func body(content: Content) -> some View {
            content
                .multilineTextAlignment(band.captionAlignment == .trailing ? .trailing : band.captionAlignment == .center ? .center : .leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(width: band.captionWidth, alignment: band.captionAlignment)
                .shadow(color: Color(0x03060A).opacity(0.7), radius: 3)
                .accessibilityHidden(true)
                .offset(x: band.captionAt.x, y: y)
        }
    }
}

/// A spur of the far ridge reaching across the water from the trailing edge to a blunt nose: a flat shape in the far
/// ridges' tone, its top and foot wandering, for the reef's caves to open in.
struct SlopeReef: Shape {
    let nose: CGFloat
    let top: CGFloat
    let foot: CGFloat

    func path(in rect: CGRect) -> Path {
        let middle = (top + foot) / 2, half = (foot - top) / 2
        // Thin at the nose, whole within 90 pt of it.
        func swell(_ x: CGFloat) -> CGFloat { sqrt(min(max((x - nose) / 90, 0), 1)) }
        func upper(_ x: CGFloat) -> CGFloat { middle - half * swell(x) + 5 * sin(x * 0.023 + 1.1) + 2.5 * sin(x * 0.061) }
        func lower(_ x: CGFloat) -> CGFloat { middle + half * swell(x) + 6 * sin(x * 0.019 + 2.7) + 2.5 * sin(x * 0.047 + 0.8) }
        let end = rect.maxX + 4
        var path = Path()
        path.move(to: CGPoint(x: nose, y: (upper(nose) + lower(nose)) / 2))
        for x in stride(from: nose, through: end, by: 4) { path.addLine(to: CGPoint(x: x, y: upper(x))) }
        for x in stride(from: end, through: nose, by: -4) { path.addLine(to: CGPoint(x: x, y: lower(x))) }
        path.closeSubpath()
        return path
    }
}
