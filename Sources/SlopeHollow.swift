// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// An offer on the slope (docs/slope.md, 8.1): a round opening in plughole's rock, dark inside, with the offer's cover
/// lit within, held still at its stirred frame, its light spilling on the rock and caught on the opening's lower lip.
/// Under it its name, with a glyph for owned or waiting, and the cover's line: "new", or the free levels solved.
///
/// The view's own frame is the opening's, `side` across, which the menu sets by its top centre (`init(_:on:type:open:)`);
/// the words hang under it and are part of its target. At the accessibility sizes (`beside`)
/// the hollow takes a row of its own in the column, the rock bulging out to hold it, and the words stand beside it at
/// the words' x, full size and wrapping.
struct SlopeHollow: View {
    let offer: Offer
    /// The opening's width: 58 in the dive, less while the depth is closing.
    var side: CGFloat = SlopeHollow.full
    /// How much of the name and line shows; they fade in as the depth finishes opening.
    var words = 1.0
    /// The accessibility sizes' row: the words beside the opening, wrapping in this width; nil sets them under it.
    var beside: CGFloat?
    /// A tap, with the opening's middle on the screen, which its cover rises out of (`SlopePack.from`).
    let open: (CGPoint) -> Void
    var store = Store.shared
    @State private var middle = CGPoint.zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let full: CGFloat = 58
    /// The opening's middle at the accessibility sizes, from the screen's leading edge, where the menu sets it.
    static let largeX: CGFloat = 48
    /// Where the words start beside it at the accessibility sizes, as a ledge's row's.
    static let wordsX: CGFloat = 96

    var body: some View {
        let state = store.state(offer), ready = store.ready
        // Unowned until the launch's first read has finished, so a pack's free levels wait for it.
        let line = offer.pack.flatMap { Marks.line($0, owned: state == .owned || !ready, fits: $0.fits(), played: $0.tastePlayed()) }
        Button { open(middle) } label: {
            mouth
                .frame(width: side, height: side)
                .onGeometryChange(for: CGPoint.self) { geo in
                    let frame = geo.frame(in: .global)
                    return CGPoint(x: frame.midX, y: frame.midY)
                } action: { middle = $0 }
                .overlay(alignment: beside == nil ? .top : .leading) {
                    caption(state: ready ? state : .unowned, line: line)
                        .opacity(words)
                        .alignmentGuide(.top) { _ in -side - 10 * side / Self.full }
                        .alignmentGuide(.leading) { _ in beside == nil ? 0 : Self.largeX - Self.wordsX - side / 2 }
                        // Beside the opening the words stand level with its middle, or, taller than it, from its top
                        // down, inside the row the menu opens for it.
                        .alignmentGuide(VerticalAlignment.center) { $0.height > side ? side / 2 : $0[VerticalAlignment.center] }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(Sounding(presses: true))
        // Unseen until the launch's read of what is owned and its price fetch have settled, then fading in once, so
        // neither its glyph nor Triptych I's hollow changes in sight (the dock's rule).
        .opacity(store.shelved ? 1 : 0)
        .animation(reduceMotion ? nil : .easeIn(duration: 0.25), value: store.shelved)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(offer.pack == nil // loc: verbatim names alone, or a key
            ? Text(verbatim: "\(offer.name), \(Pack.named(Pack.bundled))")
            : Text("\(offer.name), pack", comment: "VoiceOver: a pack's cover. Its name"))
        .accessibilityValue([(ready ? state.tag(unshared: offer.pack.map(store.unshared) ?? false)?.word : nil) // loc: verbatim localized by Purchase and Marks
                             ?? store.price(offer.productID), line?.spoken].compactMap { $0 }.joined(separator: ", "))
        .accessibilityHint(offer.pitch ?? "") // loc: verbatim localized by Offer
    }

    /// The rock's bulge at the accessibility sizes, the cover's light on the rock, the dark mouth, the cover, the
    /// rock's own thickness round the mouth and the light on its lower lip.
    private var mouth: some View {
        let k = side / Self.full, light = offer == .pack(.prism) ? Color(0xE2ECFF) : offer.glow
        return ZStack {
            if beside != nil {
                // Sandstone in shade, as the slope's own wall, swelling from the leading edge round the opening.
                Ellipse()
                    .fill(RadialGradient(stops: [.init(color: Color(red: 0.52, green: 0.39, blue: 0.29), location: 0),
                                                 .init(color: Color(red: 0.40, green: 0.30, blue: 0.24), location: 0.8),
                                                 .init(color: Color(red: 0.33, green: 0.25, blue: 0.21).opacity(0), location: 1)],
                                         center: UnitPoint(x: 0.42, y: 0.3), startRadius: 0, endRadius: 84))
                    .frame(width: 150, height: 124)
                    .offset(x: -26)
            }
            Circle().fill(RadialGradient(colors: [light.opacity(beside == nil ? 0.26 : 0.14), light.opacity(0)], center: .center, startRadius: side * 0.3,
                                         endRadius: side * 1.25))
                .frame(width: side * 2.5, height: side * 2.5)
            Circle().fill(Color(0x03060A).opacity(0.92)).frame(width: side + 10 * k, height: side + 10 * k)
            // Laid out at full size and scaled, so a closing depth never bakes the cover anew.
            PackTank(offer: offer, side: Self.full).scaleEffect(k)
            Circle().strokeBorder(RadialGradient(colors: [Color(0x03060A).opacity(0), Color(0x03060A).opacity(0.85)], center: .center,
                                                 startRadius: side / 2, endRadius: side / 2 + 6 * k), lineWidth: 6 * k)
                .frame(width: side + 12 * k, height: side + 12 * k)
            Circle().trim(from: 0.06, to: 0.44)
                .stroke(LinearGradient(colors: [light.opacity(0), light.opacity(0.55)], startPoint: UnitPoint(x: 0.5, y: 0.7), endPoint: .bottom),
                        style: StrokeStyle(lineWidth: 1.6 * k, lineCap: .round))
                .frame(width: side + 10.8 * k, height: side + 10.8 * k)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }

    /// The name, with the state's glyph after it, over the cover's line.
    private func caption(state: Purchase, line: (words: String, spoken: String, new: Bool)?) -> some View {
        VStack(alignment: beside == nil ? .center : .leading, spacing: 2) {
            // A glyph, so the state reads without its colour; a revocation is the inside's to say.
            (Text(verbatim: offer.name)
             + (state.mark.map { Text(verbatim: "\u{00A0}") + Text(Image(systemName: $0)).font(.system(.caption2, weight: .bold))
                 .foregroundStyle(state.tag()?.colour ?? .text) } ?? Text(verbatim: "")))
                .font(.slope(.ui, .detail)).ink(.ink)
            if let line {
                Text(line.words).font(.slope(.data, .detail)).foregroundStyle(line.new ? offer.ink : SlopeInk.ink3.colour) // loc: verbatim localized by Marks
            }
        }
        .multilineTextAlignment(beside == nil ? .center : .leading)
        .fixedSize(horizontal: beside == nil, vertical: true)
        .frame(width: beside, alignment: .leading)
        // The cover's light and the rock's are under the words: the water's shade keeps them read.
        .shadow(color: Color(0x03060A).opacity(0.8), radius: 3)
    }
}

extension Offer {
    /// The slope's shelf: `shelf()` less a pack that doesn't ship, which a build outside Release keeps on the dock.
    /// First Stir has no hollow in any build (Jack, 2026-11-24).
    static func hollows() -> [Offer] { shelf().filter { $0.pack?.ships ?? true } }
}

extension Pack {
    /// The packs the slope sells: `sold()` less one that doesn't ship.
    static func hollowed() -> [Pack] { sold().filter(\.ships) }
}

extension SlopeHollow {
    /// The hollow the menu sets on a spot of its column, the opening's top centre at the spot's point: as big as the
    /// depth has opened it, its words arriving with the dive's.
    @MainActor init(_ offer: Offer, on spot: SlopeSpot, type: DynamicTypeSize, store: Store = .shared, open: @escaping (CGPoint) -> Void) {
        self.init(offer: offer, side: spot.side, words: spot.near,
                  beside: type.isAccessibilitySize ? max(spot.view.size.width - Self.wordsX - 16, 60) : nil, open: open, store: store)
    }
}
