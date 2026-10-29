// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// First Stir's scenes, one per level. Each rod in `vignettes` holds one vignette in its rigid core, drawn in two states:
/// held back (later in the night) and played (earlier). A vignette is named by its rod, and every one of the scramble's
/// entries on that rod holds it back, so it plays once its core is still.
enum Story: Hashable, Sendable {
    /// Chapter 1, Dawn After: scenes 1 to 5.
    case dawn(Dawn)
    /// Chapter 2, The Rescue: scenes 6 to 10.
    case rescue(Rescue)
    /// Chapter 3, The Flood: scenes 11 to 15.
    case flood(Flood)
    /// Chapter 4, The Storm: scenes 16 to 20, the first of them the lab's harbour.
    case storm(Storm)
    /// Chapter 5, Dusk Before: scenes 21 to 25.
    case dusk(Dusk)

    var vignettes: Set<Int> {
        switch self {
        case .dawn(let scene): scene.vignettes
        case .rescue(let scene): scene.vignettes
        case .flood(let scene): scene.vignettes
        case .storm(let scene): scene.vignettes
        case .dusk(let scene): scene.vignettes
        }
    }
}

extension Level {
    /// The pack's scenes in the outline's order, the night told backwards, numbered by place as `Pack.levels` reads
    /// them. A scene's caption is its time.
    static let firstStir: [Level] = (dawn + rescue + flood + storm + dusk).enumerated().map { i, level in
        var level = level
        level.id = Pack.firstStir.id(i + 1)
        level.label = String(format: "%02d", i + 1)
        return level
    }

    /// Chapter 1, Dawn After (FirstStirDawn.swift).
    private static let dawn: [Level] = [
        // Tri's rods all overlap, so its stack orders every heal: the cottage's doorway lies in the boat's disc, so the
        // cottage's one entry is the bottom.
        Level(id: "", pack: .firstStir, label: "", title: "Sunrise", note: "", layout: .tri,
              scramble: .parse("2:+5,1:-4,0:+3,1:+2", in: .tri), story: .dawn(.sunrise)),
        Level(id: "", pack: .firstStir, label: "", title: "The gallery", note: "", layout: .quad,
              scramble: .parse("3:+4,0:-3,1:+5,2:-2", in: .quad), story: .dawn(.gallery)),
        // The child kneels in the dog's disc, so the pool's bottom entry lies under both of the dog's.
        Level(id: "", pack: .firstStir, label: "", title: "The rock pool", note: "", layout: .tri,
              scramble: .parse("1:+4,2:-3,0:+5,1:-2,2:+3", in: .tri), story: .dawn(.rockPool)),
        Level(id: "", pack: .firstStir, label: "", title: "Righting the boat", note: "", layout: .eye,
              scramble: .parse("0:+3,1:-4,2:+5,3:-2,1:+2", in: .eye), story: .dawn(.righting)),
        Level(id: "", pack: .firstStir, label: "", title: "Tea on the quay", note: "", layout: .quad,
              scramble: .parse("2:+4,3:-3,1:+5,0:-2,3:+2,2:-5", in: .quad), story: .dawn(.tea)),
    ]
}

/// What the pack's scenes share: the line, the fades and the memory budget the lab's harbour first set.
enum Harbour {
    /// Every stroke's width, in tank radii.
    static let line = 0.0075
    /// How long a vignette takes to fade in as it plays.
    static let fade = 0.4
    /// How long the night takes to wind back after a heal, the rain climbing back up its slant all the while.
    static let rewind = 1.6

    /// ponytail: not measured on the phone. Four tank-sized float images (two skies, the scene held back and played)
    /// at 3x on the largest phone come to about 51 MB; past this the layers bake at a lower scale.
    static let budget = 64 << 20
}
