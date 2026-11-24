// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Where the overview shows the packs' covers at full size, each one tap from its inside. Three places built for
/// Jack to pick from (2026-11-24); none is chosen, and no Release build has any: the overview then keeps its small
/// hollows in plughole's rock and the packs' line. The dive keeps its hollows in plughole's wall under every one.
enum SlopePacksAt: String {
    /// Glass floats riding the water line beside the bank, their names in the shallows under them.
    case surface = "a"

    /// UNSTIR_PACKSAT=a, the harness's.
    static let chosen: SlopePacksAt? = {
        #if DEBUG
        ProcessInfo.processInfo.environment["UNSTIR_PACKSAT"].flatMap(SlopePacksAt.init(rawValue:))
        #else
        nil
        #endif
    }()
}

/// The covers' places at the overview for one screen, type size and shelf, measured from the band's own anchor: the
/// water line for the floats. Where their names would meet in a row, the row stacks and each name stands beside its
/// cover (docs/slope.md, 1.1).
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
    /// The names in one line under a row whose covers stand too close for a name under each; it ends over the packs' line.
    let names: String?
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
        // The floats start clear of the stone on the bank and its word.
        let from: CGFloat = at == .surface ? 60 + width(String(localized: "settings"), name) + 16 : 0
        let to = size.width - 20, gaps = CGFloat(offers.count - 1)
        // In a row with each name under its cover; where the names would meet, the covers alone with the names in one
        // line under them all; where even those don't fit, or at the largest sizes, stacked.
        let named = under.map { max($0, side) }, bare = under.map { _ in side }
        let fits = [named, bare].first { $0.reduce(0, +) + 10 * gaps <= to - from }
        if !type.isAccessibilitySize, let slots = fits {
            let across = slots.reduce(0, +), gap = gaps > 0 ? min((to - from - across) / gaps, 22) : 0
            var x = to - across - gap * gaps
            var seats: [CGPoint] = []
            for slot in slots {
                // The water line crosses a float `draught` of the way down it.
                seats.append(CGPoint(x: x + slot / 2, y: side * (0.5 - SlopeHollow.draught)))
                x += slot + gap
            }
            self.seats = seats
            self.side = side
            dress = .float
            beside = nil
            let wide = min(max(to - seats[0].x + slots[0] / 2, 200), to - 20)
            var foot = side * (1 - SlopeHollow.draught)
            if slots == named {
                names = nil
                foot += 10 * side / SlopeHollow.full + lines * (line + 2)
            } else {
                let list = words.map { $0.name.replacingOccurrences(of: " ", with: "\u{00A0}") }.joined(separator: " \u{00B7} ")
                names = list
                foot += 8 + SlopeMeasure.height(list, .detail, width: wide, at: type)
            }
            captionWidth = wide
            captionAt = CGPoint(x: to - wide, y: foot + 5)
            captionAlignment = .trailing
            height = foot + 5 + (caption.map { SlopeMeasure.height($0, .detail, width: wide, at: type) } ?? 0)
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
            dress = .hollow
            beside = room
            names = nil
            height = y - 16
        }
    }

    /// Where the names' line starts, over the packs' line.
    var namesAt: CGFloat { side * (1 - SlopeHollow.draught) + 8 }

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
            VStack(alignment: band.captionAlignment.horizontal, spacing: 5) {
                if let names = band.names { Text(names).font(.slope(.ui, .detail)).ink(.ink) } // loc: verbatim the packs' names
                if let yours {
                    Text(yours.yours).font(.slope(.place, .body)).foregroundStyle(yours.ink).transition(.opacity) // loc: verbatim localized by Offer
                } else if let caption = band.caption {
                    Text(caption).font(.slope(.ui, .detail)).ink(.ink3).transition(.opacity) // loc: verbatim localized by Menu.packsCaption
                }
            }
            .multilineTextAlignment(band.captionAlignment == .trailing ? .trailing : .leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: band.captionWidth, alignment: band.captionAlignment)
            .shadow(color: Color(0x03060A).opacity(0.7), radius: 3)
            .accessibilityHidden(true)
            .animation(.easeInOut(duration: 0.4), value: yours)
            .offset(x: band.captionAt.x, y: band.names == nil ? band.captionAt.y : band.namesAt)
            ForEach(Array(band.offers.enumerated()), id: \.element) { i, offer in
                let seat = band.seats[i]
                hollow(offer, SlopeSpot(view: view, ledge: 0, point: seat, side: band.side, near: band.names == nil ? 1 : 0, dress: band.dress, beside: band.beside))
                    .offset(x: seat.x - band.side / 2, y: seat.y - band.side / 2)
            }
        }
        .frame(width: view.size.width, height: max(band.height, 1), alignment: .topLeading)
    }
}
