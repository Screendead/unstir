// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// A level's result as three discs, one to three filled (Jack's calls C9 = B and D3 = A, round 13; the design pass's
/// fourth change): none filled tried, one solved, two at par, three clean. The count carries the result, never colour,
/// so it reads under Differentiate Without Colour as it is; VoiceOver reads the result in words (`Spoken`).
struct ResultMarks: View {
    /// 0 to 3.
    let filled: Int
    /// The result card's: 16 pt discs, landing one after another as the card shows. A row's are 8 pt and still.
    var card = false
    /// The proposal's 8 and 16 pt at the default size, scaled with the words beside them, as a fixed disc all but
    /// vanishes next to accessibility-sized text.
    @ScaledMetric(relativeTo: .footnote) private var rowSide = 8.0
    @ScaledMetric(relativeTo: .headline) private var cardSide = 16.0
    @State private var landed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How many a result fills, or nil where there is no result to mark: not played.
    static func filled(_ mark: Archive.Mark) -> Int? {
        switch mark {
        case .clean: 3
        case .par: 2
        case .over: 1
        case .tried: 0
        case .unplayed: nil
        }
    }

    /// This solve's on the result card.
    static func filled(clean: Bool, over: Int) -> Int { clean ? 3 : over == 0 ? 2 : 1 }

    var body: some View {
        let side = card ? cardSide : rowSide
        HStack(spacing: side / 2) {
            ForEach(0 ..< 3, id: \.self) { i in
                Group {
                    if i < filled {
                        Circle().fill(Color.text)
                    } else {
                        Circle().strokeBorder(Color.line, lineWidth: 1)
                    }
                }
                .frame(width: side, height: side)
                .scaleEffect(!card || landed || reduceMotion ? 1 : 0.6)
                .opacity(!card || landed ? 1 : 0)
                .animation(.easeOut(duration: 0.3).delay(Self.land + (reduceMotion ? 0 : 0.12 * Double(i))), value: landed)
            }
        }
        .accessibilityHidden(true)
        .onAppear { landed = true }
    }

    /// The card's reveal waits 0.3 s and lands over 0.4 s (`LevelView.reveal`); the first mark starts 0.2 s after.
    static let land = 0.3 + 0.4 + 0.2
}
