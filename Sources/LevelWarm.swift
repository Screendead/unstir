// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The level screen built once, off screen, before any level is picked: the first build of it in a process stops the
/// main thread for a third of a second (the runtime resolving its view types, SwiftUI reading their fields), and a
/// level opened later reuses what that build left. It is measured in a hosting controller that is never put in a
/// window, so none of its appear, task or change handlers run, then let go. Measuring stops at the GeometryReader:
/// what is under it is still built at the first open.
@MainActor enum LevelWarm {
    private(set) static var done = false

    static func run(slope: Bool) {
        guard !done else { return }
        done = true
        #if DEBUG
        let start = CACurrentMediaTime()
        #endif
        let level = Level.plughole[0]
        let game = Game(level: level, storesProgress: false, storesResume: false)
        let view = LevelView(level: level, harness: nil, resumed: game, onExit: { _ in }, onNext: { _ in }, onLook: { _ in },
                             onOffer: { _ in })
            .environment(\.slopeGroundOwned, slope)
            .environment(\.slopeWorld, slope)
            .buttonStyle(Sounding())
        let host = UIHostingController(rootView: view)
        host.view.frame = UIScreen.main.bounds
        _ = host.sizeThatFits(in: UIScreen.main.bounds.size)
        #if DEBUG
        Log.write("level screen warmed in \(Int(((CACurrentMediaTime() - start) * 1000).rounded())) ms")
        #endif
    }
}
