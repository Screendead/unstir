// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// An offer on the slope (docs/slope.md, 8.1): a round opening in plughole's rock, dark inside, with the offer's cover
/// lit within, held still at its stirred frame, its light spilling on the rock and caught on the opening's lower lip.
/// Under it its name, with a glyph for owned or waiting, and the cover's line: "new", or the free levels solved.
///
/// The view's own frame is the opening's, `side` across, so the menu sets its middle where the geometry says
/// (`SlopeHollow.place`); the words hang under it and are part of its target. At the accessibility sizes (`beside`)
/// the hollow takes a row of its own in the column, the rock bulging out to hold it, and the words stand beside it at
/// the words' x, full size and wrapping.
struct SlopeHollow: View {
    let offer: Offer
    /// The opening's width: 58 in the dive, less while the depth is closing (`SlopeHollow.side`).
    var side: CGFloat = SlopeHollow.full
    /// How much of the name and line shows; they fade in as the depth finishes opening (`SlopeHollow.words`).
    var words = 1.0
    /// The accessibility sizes' row: the words beside the opening, wrapping in this width; nil sets them under it.
    var beside: CGFloat?
    let open: () -> Void
    var store = Store.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let full: CGFloat = 58
    /// The opening's middle, from the screen's leading edge: in the wall, and at the accessibility sizes, where the
    /// slope keeps to the edge, in the bulge.
    static let x: CGFloat = 56, largeX: CGFloat = 48
    /// Where the words start beside it at the accessibility sizes, as a ledge's row's.
    static let wordsX: CGFloat = 96

    /// The hollows the slope shows, in the shelf's order: Triptych I's only while it saves anything, as the dock.
    @MainActor static func shelf(_ store: Store = .shared) -> [Offer] {
        Offer.shelf().filter { $0 != .complete || store.offersComplete }
    }

    /// Whether the slope shows hollows at all, and the packs' caption with them: the dock's rule.
    @MainActor static var shown: Bool { Shop.shown() }

    /// The plughole level whose ledge the hollow lies under, between it and the next.
    static func after(_ offer: Offer) -> Int {
        switch offer {
        case .pack(.firstStir): 2
        case .pack(.lens): 6
        case .pack(.escapement): 11
        case .pack(.prism): 16
        case .complete: 21
        }
    }

    /// The main column's ledge it lies under.
    static func ledge(_ offer: Offer) -> Int { SlopeColumn.ledge(tier: 0, level: after(offer)) }

    /// The room a hollow's own row takes at the accessibility sizes, which the menu adds to its ledge's row
    /// (`SlopeColumn.Stretch.rows`) so the gap under that ledge opens by it: the opening and its light, or its name
    /// over two lines and its line, whichever is taller.
    static func room(at type: DynamicTypeSize) -> CGFloat {
        guard type.isAccessibilitySize else { return 0 }
        return max(full + 44, TypeRole.detail.line(at: type).height * 3 + 28)
    }

    /// The opening's middle in `view`: beside the water's room between its ledge and the next, or at the accessibility
    /// sizes in the row opened under its ledge's own.
    static func place(_ offer: Offer, in view: SlopeView, type: DynamicTypeSize) -> CGPoint {
        let n = ledge(offer), lay = view.lay
        guard type.isAccessibilitySize else { return CGPoint(x: x, y: view.y(lay.between(n))) }
        return CGPoint(x: largeX, y: view.y(lay.tops[n] + lay.drops[n] - room(at: type) / 2 - 8))
    }

    /// The opening's width as the depth opens: 16 at the overview, 58 in the dive.
    static func side(_ lay: SlopeLay) -> CGFloat { 16 + (full - 16) * lay.e }
    /// How much of a hollow shows as the depth opens: none under half way, whole from 0.8.
    static func shows(_ lay: SlopeLay) -> Double { min(max((lay.e - 0.5) / 0.3, 0), 1) }
    /// Its name and line fade in past 0.8.
    static func words(_ lay: SlopeLay) -> Double { min(max((lay.e - 0.8) / 0.2, 0), 1) }

    var body: some View {
        let state = store.state(offer), ready = store.ready
        // Unowned until the launch's first read has finished, so a pack's free levels wait for it.
        let line = offer.pack.flatMap { Marks.line($0, owned: state == .owned || !ready, fits: $0.fits(), played: $0.tastePlayed()) }
        Button(action: open) {
            mouth
                .frame(width: side, height: side)
                .overlay(alignment: beside == nil ? .top : .leading) {
                    caption(state: ready ? state : .unowned, line: line)
                        .opacity(words)
                        .alignmentGuide(.top) { _ in -side - 10 * side / Self.full }
                        .alignmentGuide(.leading) { _ in beside == nil ? 0 : Self.largeX - Self.wordsX - side / 2 }
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
        .accessibilityHint(offer.pitch) // loc: verbatim localized by Offer
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

extension SlopeHollow {
    /// The hollow the menu sets on a spot of its column, the opening's top centre at the spot's point: as big as the
    /// depth has opened it, its words arriving with the dive's.
    @MainActor init(_ offer: Offer, on spot: SlopeSpot, type: DynamicTypeSize, store: Store = .shared, open: @escaping () -> Void) {
        self.init(offer: offer, side: spot.side, words: spot.near,
                  beside: type.isAccessibilitySize ? max(spot.view.size.width - Self.wordsX - 16, 60) : nil, open: open, store: store)
    }
}

/// Every hollow on a view of the main column as the harness shows them, each where it lies, growing from 16 to 58 points as the depth opens and
/// its words fading in last; unseen until the dock's rule shows them (`SlopeHollow.shown`) and the store's first read
/// and price fetch have settled, then fading in once. The menu places each `SlopeHollow`
/// itself (`init(_:on:type:open:)`).
struct SlopeHollows: View {
    let view: SlopeView
    /// The offer, and its opening's middle in the view, for its cover to rise from.
    let open: (Offer, CGPoint) -> Void
    var store = Store.shared

    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let lay = view.lay, shows = SlopeHollow.shows(lay), shelf = SlopeHollow.shelf(store)
        SlopeLayer {
            if SlopeHollow.shown, shows > 0 {
                ForEach(shelf, id: \.self) { offer in
                    let at = SlopeHollow.place(offer, in: view, type: typeSize)
                    SlopeHollow(offer: offer, side: SlopeHollow.side(lay), words: SlopeHollow.words(lay),
                                beside: typeSize.isAccessibilitySize ? max(view.size.width - SlopeHollow.wordsX - 16, 60) : nil,
                                open: { open(offer, at) }, store: store)
                        .slopePlace(at)
                        .transition(.opacity)
                }
            }
        }
        .opacity(shows)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.3), value: shelf)
    }
}
