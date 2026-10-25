// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// UNSTIR_ICON=n: app-icon candidate n, a 1024-pixel square centred on a black screen for scripts/icon.sh to crop.
/// Drawn from the game's own parts: a picture through the tank's shader, a knob, the bezel.
struct IconView: View {
    let n: Int
    @Environment(\.displayScale) private var scale

    var body: some View {
        let s = 1024 / scale
        ZStack {
            Color.black
            switch n {
            case 2: twin(s)
            case 3: vortex(s)
            default: swirl(s)
            }
        }
        .frame(width: s, height: s)
        .clipped()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
    }

    /// Plughole's grid, zoomed so its lines hold at 60 px, under one rod's swirl.
    private func swirl(_ s: CGFloat) -> some View {
        let zoom = 2.0
        return ZStack {
            stirred(.grid, side: s * zoom, discs: [(0, 0, 0.5 * 0.86, -2.4)], plateau: 0.45)
            knob(s * 0.2)
        }
    }

    /// The glass's twin mid-heartbeat, its gold cells drawn out into one arm, round a knob that fills the middle.
    private func twin(_ s: CGFloat) -> some View {
        let zoom = 3.0
        return ZStack {
            stirred(.glassTwin, side: s * zoom, discs: [(0, 0, 0.92 / zoom, 4)], plateau: 0.38, clock: 0.45)
            knob(s * 0.34)
        }
    }

    /// The whole tank wound into one swirl, in its bezel.
    private func vortex(_ s: CGFloat) -> some View {
        let r = s * 0.45
        return ZStack {
            stirred(.sunset, side: 2 * r, discs: [(0, 0, 1, 3.6)], plateau: 0.08)
                .clipShape(Circle())
            Bezel(r: r).frame(width: 2 * r, height: 2 * r)
            knob(s * 0.2)
        }
    }

    private func knob(_ size: CGFloat) -> some View {
        // Drawn at a knob's size in play and scaled up, so its pointer and ticks keep their weight against it.
        RodView(angle: 0, size: 30).shadow(color: .black.opacity(0.8), radius: 4).scaleEffect(size / 30)
    }

    /// `picture` at `side`, through the tank's shader with these discs (x, y, radius in tank units, radians clockwise).
    private func stirred(_ picture: Picture, side: CGFloat, discs: [(Double, Double, Double, Double)], plateau: Double,
                         clock: Double = 0) -> some View {
        let floats = discs.flatMap { [Float($0.0), Float($0.1), Float($0.2), Float($0.3)] }
        return PictureLayer(picture: picture, side: side, seed: 3, clock: clock)
            .layerEffect(ShaderLibrary.unstir(.float2(side / 2, side / 2), .float(side / 2), .floatArray(floats),
                                              .float(Float(discs.count)), .float(30), .float(Float(plateau)),
                                              .float(Float(scale)), .float(0), .float3(0, 0, -1), .float(0)),
                         maxSampleOffset: CGSize(width: side, height: side))
    }
}
