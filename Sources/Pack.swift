// Copyright © 2026 Jack Lusher. All rights reserved.

import Foundation

/// A paid set of levels, outside the tier ladder: no pack best ever opens a tier. The raw value is the pack's level-id
/// prefix and `productID` is what StoreKit sells it as; bests and purchases are kept under both, so neither ever
/// changes (UnstirTests pins them).
enum Pack: String, CaseIterable, Sendable {
    case firstStir = "first-stir", lens, escapement

    var name: String {
        switch self {
        case .firstStir: "First Stir"
        case .lens: "Lens"
        case .escapement: "Escapement"
        }
    }

    var prefix: String { rawValue }

    var productID: String {
        switch self {
        case .firstStir: "com.screendead.Unstir.pack.firststir"
        case .lens: "com.screendead.Unstir.pack.lens"
        case .escapement: "com.screendead.Unstir.pack.escapement"
        }
    }

    /// Grants every pack. A later pack joins it, so an older Complete owns it too.
    static let completeID = "com.screendead.Unstir.complete"

    static var productIDs: [String] { allCases.map(\.productID) + [completeID] }

    /// Levels 1 to `taste` play without the pack.
    var taste: Int { 3 }

    /// Numbered from 1 by place, each the pack's own `id`; empty until the pack's content lands.
    var levels: [Level] {
        switch self {
        case .firstStir: Level.firstStir
        case .lens: Level.lens
        case .escapement: Level.escapement
        }
    }

    func id(_ number: Int) -> String { "\(prefix)-\(number)" }

    /// The 1-based number in an id of this pack, or nil for any other id.
    func number(of id: String) -> Int? {
        guard id.hasPrefix(prefix + "-") else { return nil }
        return Int(id.dropFirst(prefix.count + 1)).flatMap { $0 > 0 ? $0 : nil }
    }

    enum Access: Equatable { case taste, owned, needsCard }

    /// Whether `number` plays. `owned` is what StoreKit grants; the developer unlock and the harness's packs count only
    /// outside Release, so a shipped build opens a pack past its taste for nothing but a purchase.
    func access(_ number: Int, owned: Set<Pack>, unlocked: Bool = Best.unlocked, harness: Set<Pack> = [],
                release: Bool = Build.release) -> Access {
        if number <= taste { return .taste }
        if owned.contains(self) || (!release && (unlocked || harness.contains(self))) { return .owned }
        return .needsCard
    }

    #if DEBUG
    /// A stand-in for level `number`, for the harness to open before the pack has levels.
    func placeholder(_ number: Int) -> Level {
        Level(id: id(number), pack: self, label: String(format: "%02d", number), title: "\(name) placeholder",
              layout: .tri, scramble: .parse("0:+4", in: .tri))
    }
    #endif
}

extension Level {
    static let firstStir: [Level] = []
    static let lens: [Level] = []
    /// Each problem's par is the prover's optimum (`Solver.escapement`), and its note the stipulation.
    static let escapement: [Level] = [
        // The packs mock-up's problem: rod 2 +4, a wait, rod 1 -3. Any other first move's tick pushes on the clock.
        Level(id: Pack.escapement.id(1), pack: .escapement, label: "01", title: "The clock", note: "Unstir in 3.",
              layout: .tri, scramble: .parse("0:-1,1:+3,0:-2,2:-4", in: .tri), ratchets: [0],
              // A heal hands the clock its seam and it ticks; a wait, and it ticks again.
              demo: .parse("0:-3,1:+2", in: .tri), fixedPar: 3),
    ]

    /// A pack's level keeps a best and its started flag only once it is one of the pack's own, so a harness placeholder
    /// never leaves progress under an id a real level will take.
    var keepsProgress: Bool { pack.map { p in p.levels.contains { $0.id == id } } ?? true }
}

enum Build {
    static let release: Bool = {
        #if DEBUG
        false
        #else
        true
        #endif
    }()
}
