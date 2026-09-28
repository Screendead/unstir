import SwiftUI

/// Neon on black. The campaign pictures show which way is up inside every rigid core, or a turned disc looks as
/// plausible as the original: the grid by its colour field, the sunset by its stripes and floor, the city by its rain.
/// Nightmare withholds that on purpose: a turn shows only where its seam shears the cracks.
enum Picture: String, CaseIterable {
    case grid, sunset, city, nightmare
    /// Drawn live by the nightmarePlus shader in PictureLayer, never baked.
    case nightmarePlus = "nightmare+"

    @MainActor
    func render(side: CGFloat, scale: CGFloat) -> UIImage? {
        let r = ImageRenderer(content: Canvas { ctx, size in draw(ctx, r: size.width / 2) }
            .frame(width: side, height: side))
        r.scale = scale
        r.isOpaque = true
        // Float storage, so the glow adds in linear light as the design renders did; 8-bit .linear bands the dark skies.
        r.colorMode = .extendedLinear
        return r.uiImage
    }

    /// The grid's colour at (x, y): hue sweeps cyan to orange left to right, lightness falls top to bottom.
    static func field(_ x: Double, _ y: Double) -> Color {
        let u = min(max((x + 0.9) / 1.8, 0), 1), v = min(max((y + 0.9) / 1.8, 0), 1)
        return oklch(0.72 - 0.20 * v, 0.34, 190 + 240 * u)
    }

    private func draw(_ ctx: GraphicsContext, r: CGFloat) {
        func p(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: r + x * r, y: r + y * r) }
        func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> Path {
            Path(CGRect(x: r + x0 * r, y: r + y0 * r, width: (x1 - x0) * r, height: (y1 - y0) * r))
        }
        func segment(_ ax: Double, _ ay: Double, _ bx: Double, _ by: Double) -> Path {
            Path { $0.move(to: p(ax, ay)); $0.addLine(to: p(bx, by)) }
        }
        func sky(_ stops: [(Double, UInt32)]) -> GraphicsContext.Shading {
            let y0 = stops[0].0, y1 = stops.last!.0
            return .linearGradient(Gradient(stops: stops.map { .init(color: Color($0.1), location: ($0.0 - y0) / (y1 - y0)) }),
                                   startPoint: p(0, y0), endPoint: p(0, y1))
        }
        func city(_ ctx: GraphicsContext, lit: Bool) {
            var rng = SplitMix64(state: 11)
            func random(_ a: Double, _ b: Double) -> Double { .random(in: a..<b, using: &rng) }
            let ground = 0.62, palette: [Color] = [.neonCyan, .magenta, .amber]
            var x = -1.05
            while x < 1.05 {
                let w = random(0.07, 0.16), h = random(0.25, 0.75)
                if !lit { ctx.fill(rect(x, ground - h, x + w, 1), with: .color(Color(0x140A2E))) }
                x += w
            }
            x = -1.05
            while x < 1.05 {
                let w = random(0.14, 0.3), top = ground - random(0.2, 0.62)
                if lit {
                    ctx.stroke(segment(x + 0.006, top, x + w - 0.006, top), with: .color(.neonCyan.opacity(0.8)), lineWidth: 0.005 * r)
                    ctx.stroke(segment(x + w - 0.006, top, x + w - 0.006, 1.2), with: .color(.neonCyan.opacity(0.5)), lineWidth: 0.005 * r)
                } else {
                    ctx.fill(rect(x + 0.006, top, x + w - 0.006, 1), with: .color(.black))
                }
                var windows = Path()
                let colour = palette[rng.below(3)]
                for wy in stride(from: top + 0.04, to: ground + 0.3, by: 0.045) {
                    for wx in stride(from: x + 0.03, to: x + w - 0.03, by: 0.04) where random(0, 1) < 0.35 {
                        windows.addPath(rect(wx - 0.011, wy - 0.007, wx + 0.011, wy + 0.007))
                    }
                }
                if lit { ctx.fill(windows, with: .color(colour.opacity(0.8))) }
                if random(0, 1) < 0.6 {
                    // A vertical sign: frame and a column of plus marks, no glyphs.
                    let sx = x + w * random(0.3, 0.7), sc = palette[rng.below(2)]
                    let y0 = top + 0.05, y1 = y0 + random(0.22, 0.4)
                    var sign = rect(sx - 0.03, y0, sx + 0.03, y1)
                    for dy in stride(from: y0 + 0.04, to: y1 - 0.02, by: 0.05) {
                        sign.addPath(segment(sx - 0.015, dy, sx + 0.015, dy))
                        sign.addPath(segment(sx, dy - 0.012, sx, dy + 0.012))
                    }
                    if lit { ctx.stroke(sign, with: .color(sc), lineWidth: 0.007 * r) }
                }
                x += w
            }
            guard lit else { return }
            // Rain is a direction field over the whole sky: a turned disc shows it slanting the wrong way.
            var rain = Path()
            let slant = 14 * Double.pi / 180
            for _ in 0..<260 {
                let x = random(-1.1, 1.1), y = random(-1.1, 1.0), l = random(0.04, 0.09)
                rain.addPath(segment(x, y, x + l * sin(slant), y + l * cos(slant)))
            }
            ctx.stroke(rain, with: .color(Color(0x7FE8FF).opacity(0.24)), lineWidth: 0.0025 * r)
        }
        ctx.fill(rect(-1, -1, 1, 1), with: .color(.black))

        switch self {
        case .grid:
            // Each line is a gradient through its 11 nodes: two stops wash out the middle rows.
            let nodes = (0...10).map { Double($0) * 0.2 - 1 }
            // A tight bloom, so the cells stay black between the lines.
            neon(ctx, r: r, glows: [(0.022, 0.3), (0.008, 1.0)]) { g in
                for t in nodes {
                    g.stroke(segment(t, -1, t, 1), with: .linearGradient(Gradient(colors: nodes.map { Self.field(t, $0) }),
                                                                          startPoint: p(t, -1), endPoint: p(t, 1)), lineWidth: 0.014 * r)
                    g.stroke(segment(-1, t, 1, t), with: .linearGradient(Gradient(colors: nodes.map { Self.field($0, t) }),
                                                                          startPoint: p(-1, t), endPoint: p(1, t)), lineWidth: 0.014 * r)
                }
            }

        case .sunset:
            let horizon = 0.20
            ctx.fill(rect(-1, -1, 1, horizon), with: sky([(-0.6, 0x000000), (-0.3, 0x04000D), (-0.1, 0x13022B), (0.05, 0x2B0448),
                                                          (0.12, 0x520A64), (0.17, 0x8C158D), (0.20, 0xC120B5)]))
            var rng = SplitMix64(state: 7)
            for _ in 0..<70 {
                let c = p(.random(in: -1..<1, using: &rng), .random(in: -1 ..< -0.05, using: &rng))
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 0.4, y: c.y - 0.4, width: 0.8, height: 0.8)), with: .color(Color(0xCFE8FF)))
            }
            // Stripes thicken downward and run across the whole sun, so the top rod's core shows its turn.
            var stripes = Path()
            for k in 0..<12 {
                let y = -0.54 + 0.068 * Double(k), h = 0.010 + 0.004 * Double(k)
                stripes.addPath(rect(-1, y - h / 2, 1, y + h / 2))
            }
            neon(ctx, r: r, glows: [(0.06, 0.35), (0.01, 0.2)]) { g in
                g.clip(to: rect(-1, -1, 1, horizon))
                g.clip(to: stripes, options: .inverse)
                g.fill(Path(ellipseIn: CGRect(x: r - 0.5 * r, y: r - 0.64 * r, width: r, height: r)),
                       with: .linearGradient(Gradient(colors: [Color(0xFFE45C), Color(0xFF7A1A), Color(0xFF1E8E)]),
                                             startPoint: p(0, -0.64), endPoint: p(0, 0.36)))
            }
            var ridges = Path(), struts = Path()
            for side in [-1.0, 1] {
                let xs = (0..<9).map { side * (0.18 + 0.87 * Double($0) / 8) }
                let hs = (0..<9).map { k in
                    // |N(0.16, 0.08)| by Box-Muller.
                    let n = 0.16 + 0.08 * (-2 * log(1 - .random(in: 0..<1, using: &rng))).squareRoot()
                        * cos(2 * .pi * .random(in: 0..<1, using: &rng))
                    return horizon - abs(n) * sin(0.3 + 2.7 * Double(k) / 8)
                }
                var hill = Path()
                hill.move(to: p(xs[0], horizon))
                for k in 0..<9 { hill.addLine(to: p(xs[k], hs[k])) }
                hill.addLine(to: p(xs[8], horizon))
                ctx.fill(hill, with: .color(.black))
                ridges.addPath(hill)
                for k in 1..<8 { struts.addPath(segment(xs[k], hs[k], 0.9 * xs[k], horizon)) }
            }
            var floor = Path()
            for k in -14...14 { floor.addPath(segment(0.012 * Double(k), horizon, 0.33 * Double(k), 1.2)) }
            for z in 1...13 {
                let y = horizon + 0.9 / pow(0.55 * Double(z) + 0.45, 1.6) - 0.02
                if y > horizon + 0.008 { floor.addPath(segment(-1.2, y, 1.2, y)) }
            }
            neon(ctx, r: r) { g in
                g.stroke(ridges, with: .color(.neonCyan), lineWidth: 0.007 * r)
                g.stroke(struts, with: .color(.neonCyan.opacity(0.45)), lineWidth: 0.007 * r)
                var f = g
                f.clip(to: rect(-1, horizon, 1, 1))
                f.stroke(floor, with: .linearGradient(Gradient(colors: [.magenta.opacity(0.15), .magenta]),
                                                      startPoint: p(0, horizon + 0.0525), endPoint: p(0, 0.55)), lineWidth: 0.010 * r)
                g.stroke(segment(-1, horizon, 1, horizon), with: .color(.neonCyan), lineWidth: 0.010 * r)
            }

        case .city:
            ctx.fill(rect(-1, -1, 1, 1), with: sky([(-1, 0x000000), (-0.3, 0x010004), (0.1, 0x0D011F), (0.4, 0x28033C),
                                                    (0.47, 0x560B56), (0.55, 0xB01D83)]))
            // The horns show which way the moon has turned.
            let moon = Path(ellipseIn: CGRect(x: r + 0.18 * r, y: r - 0.72 * r, width: 0.4 * r, height: 0.4 * r))
                .subtracting(Path(ellipseIn: CGRect(x: r + 0.30 * r, y: r - 0.75 * r, width: 0.34 * r, height: 0.34 * r)))
            neon(ctx, r: r, glows: [(0.045, 0.35), (0.01, 0.4)]) { g in
                g.fill(moon, with: .linearGradient(Gradient(colors: [Color(0x9AF6FF).opacity(0.6), Color(0x9AF6FF)]),
                                                   startPoint: p(0, -0.72), endPoint: p(0, -0.32)))
            }
            // Fills first, then every lit stroke under one glow; both passes replay the same seed.
            city(ctx, lit: false)
            neon(ctx, r: r, glows: [(0.03, 0.35), (0.006, 0.8)]) { g in
                city(g, lit: true)
            }

        case .nightmare:
            var rng = SplitMix64(state: 22)
            let pitch = 0.11, n = 26, h = 3 * pitch
            let seeds = (0..<n * n).map { k in
                SIMD2(-1.1 + (Double(k % n - 3) + .random(in: 0..<1, using: &rng)) * pitch,
                      -1.1 + (Double(k / n - 3) + .random(in: 0..<1, using: &rng)) * pitch)
            }
            var cracks = Path(), scans: [(cell: Path, lines: Path, angle: Double)] = []
            for j in 3..<n - 3 {
                for i in 3..<n - 3 {
                    // Voronoi cell: a square cut by the bisector with every seed in the 7 x 7 block. A cell reaches at most
                    // sqrt(2) pitch from its seed, so a neighbour sits within 2 sqrt(2) pitch: three columns. 5 x 5 overlaps.
                    let a = seeds[j * n + i]
                    var cell = [a + SIMD2(-h, -h), a + SIMD2(h, -h), a + SIMD2(h, h), a + SIMD2(-h, h)]
                    for dj in -3...3 {
                        for di in -3...3 where di != 0 || dj != 0 {
                            let b = seeds[(j + dj) * n + i + di], normal = b - a, c = ((b * b).sum() - (a * a).sum()) / 2
                            var clipped: [SIMD2<Double>] = []
                            for k in cell.indices {
                                let u = cell[k], v = cell[(k + 1) % cell.count]
                                let du = (normal * u).sum() - c, dv = (normal * v).sum() - c
                                if du <= 0 { clipped.append(u) }
                                if (du < 0) != (dv < 0) && du != dv { clipped.append(u + du / (du - dv) * (v - u)) }
                            }
                            cell = clipped
                        }
                    }
                    var outline = Path()
                    outline.addLines(cell.map { p($0.x, $0.y) })
                    outline.closeSubpath()
                    cracks.addPath(outline)
                    let kind = Double.random(in: 0..<1, using: &rng), angle = Double.random(in: 0..<Double.pi, using: &rng)
                    if kind < 0.12 {
                        // Scan lines at the cell's own angle, so no direction repeats across the tank.
                        var lines = Path()
                        let d = SIMD2(cos(angle), sin(angle))
                        for t in stride(from: -h, to: h, by: 0.02) {
                            let m = a + t * SIMD2(-d.y, d.x)
                            lines.addPath(segment(m.x - h * d.x, m.y - h * d.y, m.x + h * d.x, m.y + h * d.y))
                        }
                        scans.append((outline, lines, angle))
                    }
                }
            }
            // A tight bloom, so the cells stay black between the cracks.
            neon(ctx, r: r, glows: [(0.012, 0.25), (0.004, 0.8)]) { g in
                for scan in scans {
                    var s = g
                    s.clip(to: scan.cell)
                    // Dashes restart on every line, so a pane's rows line up into broken data columns.
                    s.stroke(scan.lines, with: .color(.violet), style: StrokeStyle(lineWidth: 0.003 * r, dash: [0.03, 0.008, 0.012, 0.02].map { $0 * r },
                                                                                   dashPhase: scan.angle / .pi * 0.07 * r))
                }
                g.stroke(cracks, with: .color(.blood), style: StrokeStyle(lineWidth: 0.0042 * r, lineJoin: .round))
            }

        case .nightmarePlus:
            break
        }
    }
}

extension Picture {
    /// Nightmare+'s cells for the nightmarePlus shader: 22 x 22 cells 0.11 across from (-1.21, -1.21), each a seed wandering
    /// its own circle inside its cell, a breath phase, and a scan pane's angle signed by which way it sweeps, or 0. The
    /// shader searches the 3 x 3 cells around a point, so offsets stay under half a cell: 0.3 of jitter, 0.15 of wander.
    static func cells(seed: Int, t: Double) -> [Float] {
        var rng = SplitMix64(state: UInt64(seed))
        func random(_ a: Double, _ b: Double) -> Double { .random(in: a..<b, using: &rng) }
        let pitch = 0.11, n = 22
        var f: [Float] = []
        f.reserveCapacity(4 * n * n)
        for k in 0..<n * n {
            let jitter = SIMD2(random(-0.3, 0.3), random(-0.3, 0.3)), w = 2 * Double.pi * (random(0, 1) + t / random(7, 13))
            let at = (SIMD2(Double(k % n), Double(k / n)) + 0.5 + jitter + 0.15 * SIMD2(cos(w), sin(w))) * pitch - 1.21
            let pane = random(0, 1) < 0.12 ? random(0.001, .pi) * (random(0, 1) < 0.5 ? 1 : -1) : 0
            f += [Float(at.x), Float(at.y), Float(random(0, 1)), Float(pane)]
        }
        return f
    }
}

/// Crisp strokes, then bloom and halo added over them, baked once so twisting shears the glow with the lines.
private func neon(_ ctx: GraphicsContext, r: CGFloat, glows: [(blur: Double, opacity: Double)] = [(0.03, 0.4), (0.008, 1.0)],
                  _ draw: (inout GraphicsContext) -> Void) {
    var c = ctx
    draw(&c)
    for (blur, opacity) in glows {
        var g = ctx
        g.addFilter(.blur(radius: blur * r))
        g.opacity = opacity
        g.blendMode = .plusLighter
        g.drawLayer { draw(&$0) }
    }
}

/// Chroma is reduced until the colour fits sRGB, so hue and lightness hold.
func oklch(_ L: Double, _ C: Double, _ h: Double) -> Color {
    func rgb(_ c: Double) -> SIMD3<Double> {
        let a = c * cos(h * .pi / 180), b = c * sin(h * .pi / 180)
        let l = L + 0.3963377774 * a + 0.2158037573 * b, m = L - 0.1055613458 * a - 0.0638541728 * b
        let s = L - 0.0894841775 * a - 1.2914855480 * b
        let (l3, m3, s3) = (l * l * l, m * m * m, s * s * s)
        return SIMD3(4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3,
                     -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3,
                     -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3)
    }
    var lo = 0.0, hi = C
    for _ in 0..<20 {
        let mid = (lo + hi) / 2, v = rgb(mid)
        if v.min() >= 0 && v.max() <= 1 { lo = mid } else { hi = mid }
    }
    let v = rgb(lo)
    return Color(.sRGBLinear, red: v.x, green: v.y, blue: v.z)
}
