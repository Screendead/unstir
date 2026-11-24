// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// The thank-you for a purchase (Jack's call M6, round 14): a four-pointed glint in hairline after the title, in the
/// tier's sweep, the glyph the daily's share line carries. It never moves or asks for anything.
struct SupporterMark: View {
    let sweep: LinearGradient
    let glow: Color

    var body: some View {
        Sparkle().stroke(sweep, lineWidth: 1).frame(width: 13, height: 13)
            .shadow(color: glow.opacity(0.7), radius: 3)
    }
}

/// Four points joined by curves bowed in to the centre.
private struct Sparkle: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY), r = min(rect.width, rect.height) / 2
        let tips = [CGPoint(x: c.x, y: c.y - r), CGPoint(x: c.x + r, y: c.y), CGPoint(x: c.x, y: c.y + r),
                    CGPoint(x: c.x - r, y: c.y)]
        var p = Path()
        p.move(to: tips[0])
        for k in 1...4 { p.addQuadCurve(to: tips[k % 4], control: c) }
        p.closeSubpath()
        return p
    }
}
