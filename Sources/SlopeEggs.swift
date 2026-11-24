// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// What the menu's ground may show beyond the slope itself: things a player finds, never told of, that reward
/// nothing (Jack's call of 2026-11-24). Only the menu hands its ground one; every other ground has none, and draws and
/// costs what it did.
///
/// - Still water: left alone for `Power.idleAfter`, the water goes flat and clear and its clock slows to a stop
///   (`Calm`), where any other ground's clock stops at once; a touch brings it back.
/// - The night above: pulled down past the surface, the sky over it holds stars and the moon at `moon`.
/// - Skimming stone: flicked along the water line, a flat stone skips, each touch a ring, and its touches are counted
///   where it goes under (`SlopeSkim`).
/// - The unnumbered pebble: under the main column's last ledge a spur of rock comes back in from the screen's edge
///   (`nook`), and a dull stone on it says the one line of credits (`SlopeUnnumbered`).
/// - The seam: a tier with every level at par has gold in its rock (`seams`).
/// - The sky at the bottom: pulled up past the foot and held, the sky's stars come out upside down in the black.
/// - Meteor nights: on the three nights round the Perseids' and the Geminids' peaks, a few meteors cross the night.
struct SlopeEggs: Equatable {
    var skim: SlopeSkim?
    /// Each tier's rock holds its seam.
    var seams: [Bool] = []
    var meteors = false
    /// The moon: its terminator's place across the disc, 1 new to -1 full, and its lit side, 1 the trailing.
    var moon = SIMD2<Float>(1, 1)

    /// The eggs on `date`, as the player's part of the world sees its sky.
    init(_ date: Date = .now, region: Locale.Region? = Locale.current.region) {
        let south = region.map { Self.southern.contains($0.identifier) } ?? false
        let sun = Self.elongation(date)
        moon = SIMD2(Float(cos(sun)), (sun < .pi) != south ? 1 : -1)
        meteors = Self.shower(date)
    }

    /// A night counts from noon to noon: the three round each shower's peak, the Perseids' on 12 August and the
    /// Geminids' on 13 December.
    static func shower(_ date: Date, calendar: Calendar = .current) -> Bool {
        let night = calendar.dateComponents([.month, .day], from: date.addingTimeInterval(-12 * 3600))
        return night.month == 8 && (11 ... 13).contains(night.day ?? 0) || night.month == 12 && (12 ... 14).contains(night.day ?? 0)
    }

    /// The spur under the main column's last ledge: how far it reaches in from the leading edge, its top's depth, and
    /// where a pebble rests on it. Slope.metal draws it from the first two.
    static func nook(_ lay: SlopeLay) -> (reach: CGFloat, top: CGFloat, seat: CGPoint)? {
        guard lay.column.foot == .dropOff, lay.count > 0 else { return nil }
        let reach: CGFloat = 64, top = lay.tops[lay.count - 1] + 1.3 * lay.pitch, x: CGFloat = 38
        return (reach, top, CGPoint(x: x, y: top + 3 * (x / reach) * (x / reach)))
    }

    /// How far the mirrored sky has come in under a camera `sunk` points past the travel's foot, and from where a
    /// hold counts.
    static let held: CGFloat = 30
    static func deep(sunk: CGFloat) -> Double {
        let x = min(max((sunk - held) / 110, 0), 1)
        return x * x * (3 - 2 * x)
    }
    /// The seconds its lights take to come out.
    static let dawning = 3.2

    /// Where the waxing moon is lit on the left.
    private static let southern: Set<String> = ["AU", "NZ", "ZA", "AR", "CL", "UY", "PY", "BO", "PE", "BR", "NA", "BW", "ZW", "MZ",
                                                "MG", "ZM", "AO", "TZ", "ID", "PG", "FJ", "LS", "SZ", "MW"]

    /// The moon's angle from the sun at `date`, 0 new, π full, from 0 to 2π: the mean elongation with the six largest
    /// terms of its phase angle (Meeus, Astronomical Algorithms, 48.4), within a fraction of a degree.
    static func elongation(_ date: Date) -> Double {
        let t = (date.timeIntervalSince1970 / 86400 + 2440587.5 - 2451545) / 36525, rad = Double.pi / 180
        let d = (297.8501921 + 445267.1114034 * t) * rad, m = (357.5291092 + 35999.0502909 * t) * rad
        let n = (134.9633964 + 477198.8675055 * t) * rad
        let more = -6.289 * sin(n) + 2.1 * sin(m) - 1.274 * sin(2 * d - n) - 0.658 * sin(2 * d) - 0.214 * sin(2 * n) - 0.11 * sin(d)
        let angle = (d - more * rad).truncatingRemainder(dividingBy: 2 * .pi)
        return angle < 0 ? angle + 2 * .pi : angle
    }

    /// How far the night has come out over a camera `lift` points above the surface's place.
    static func night(lift: CGFloat) -> Double {
        let x = min(max((lift - 16) / 134, 0), 1)
        return x * x * (3 - 2 * x)
    }

    /// Slope.metal's `SlopeEgg`, in its order.
    func uniforms(calm: Double, night: Double, deep: Double, out: Double, mirror: CGFloat, lay: SlopeLay, at date: Date) -> [Float] {
        let age = skim?.age(date) ?? 0, nook = Self.nook(lay)
        return [Float(night), Float(deep), Float(calm), meteors ? 1 : 0, moon.x, moon.y, Float(mirror), Float(out),
                Float(age), Float(skim?.x ?? 0), Float(skim?.hop ?? 0), Float(skim?.touches ?? 0)]
            + (0 ..< 4).map { $0 < seams.count && seams[$0] ? 1 : 0 } + [Float(nook?.reach ?? 0), Float(nook?.top ?? 0), 0, 0]
    }

    static let none = [Float](repeating: 0, count: 20)
}

/// A flat stone skimmed along the water: thrown from `from` (the screen's x, and how far over the water line), it
/// first touches at `x` and skips `touches` times, each hop a fifth shorter and sooner than the last (Slope.metal's
/// `slopeRings` reads the same times and places for its rings), then goes under and sinks.
struct SlopeSkim: Equatable {
    static let first = 0.36, beat = 0.44, fall = 0.8
    /// How long it sinks, and all it lasts past its last touch.
    static let sinks = 3.6, lingers = 5.0

    let thrown: Date
    /// The harness's: the stone held this many seconds into its throw.
    var held: Double?
    let from: CGPoint
    let x: CGFloat
    let hop: CGFloat
    let touches: Int

    /// A flick let go at `point`, `over` the water line, at `speed` points a second along it (signed), on a screen
    /// `width` wide: harder, it skips more, as far as the water runs; nil where there is no water to skip on.
    init?(from point: CGFloat, over: CGFloat, speed: CGFloat, width: CGFloat, at date: Date = .now, luck: Int = .random(in: -1 ... 1)) {
        let way: CGFloat = speed < 0 ? -1 : 1, fast = min(abs(speed), 3200)
        let x = point + way * (26 + 0.012 * fast)
        // The bank stands in the water's leading end.
        let room = way > 0 ? width - 44 - x : x - 124
        guard fast >= 500, room > 30, x > 124 else { return nil }
        var touches = min(max(Int(1 + (fast - 500) / 300) + luck, 1), 9)
        // A hop under a dozen points is no hop: with little water it skips less.
        while touches > 1, room / Self.run(touches - 1) < 12 { touches -= 1 }
        thrown = date
        from = CGPoint(x: point, y: over)
        self.x = x
        hop = way * min(34 + 0.02 * fast, touches > 1 ? room / Self.run(touches - 1) : 0)
        self.touches = touches
    }

    /// How far `n` hops run, in first hops.
    static func run(_ n: Int) -> CGFloat { (1 - pow(fall, CGFloat(n))) / (1 - fall) }

    func time(_ i: Int) -> Double { Self.first + Self.beat * Double(Self.run(i)) }
    func place(_ i: Int) -> CGFloat { x + hop * Self.run(i) }
    func age(_ date: Date) -> Double { held ?? date.timeIntervalSince(thrown) }
}

/// The skimmed stone over the ground, drawn in the ground's own frame and on its clock, so it touches the water line
/// where the ground draws it: the stone, a few beads of water thrown up by each touch, and the count of its touches
/// where it went under, shown a couple of seconds.
struct SlopeSkimLayer: View {
    let skim: SlopeSkim
    let date: Date
    /// The water line's place on the screen at x: the ground's, sway and all.
    let water: (CGFloat) -> CGFloat

    var body: some View {
        let skim = skim, date = date, water = water
        Canvas { context, _ in
            let u = skim.age(date), n = skim.touches, way: CGFloat = skim.hop < 0 ? -1 : 1
            func wet(_ i: Int) -> CGFloat { water(skim.place(i)) - 1.2 }
            var at = CGPoint.zero, turn = -0.16 * way, alpha = 1.0
            if u < skim.time(0) {
                // Off the fingertip, low and flat.
                let k = u / skim.time(0)
                at = CGPoint(x: skim.from.x + (skim.x - skim.from.x) * k, y: water(skim.from.x) - skim.from.y * (1 - k * k) - 1.2 * k * k)
            } else if u < skim.time(n - 1) {
                var i = 1
                while u >= skim.time(i) { i += 1 }
                let k = (u - skim.time(i - 1)) / (skim.time(i) - skim.time(i - 1))
                let height = 15 * pow(0.74, CGFloat(i - 1)) * min(abs(skim.hop) / 40, 1)
                at = CGPoint(x: skim.place(i - 1) + (skim.place(i) - skim.place(i - 1)) * k,
                             y: wet(i - 1) + (wet(i) - wet(i - 1)) * k - height * 4 * k * (1 - k))
                turn = (-0.16 + 0.1 * k) * way
            } else {
                // Spent: it goes under and sinks, rocking as a flat stone does.
                let s = u - skim.time(n - 1), k = min(s / SlopeSkim.sinks, 1)
                at = CGPoint(x: skim.place(n - 1) + way * (5 + 5 * sin(s * 3.1) * (0.3 + k)), y: wet(n - 1) + 2 + 132 * (1 - pow(1 - k, 1.6)))
                turn = 0.3 * sin(s * 3.1 + 1.2)
                alpha = 1 - Self.ease((s - 1.2) / 2.2)
            }
            for i in 0 ..< n {
                let s = (u - skim.time(i)) / 0.38
                guard s > 0, s < 1 else { continue }
                for j in 0 ..< 3 {
                    let out = (CGFloat(j) - 0.6) * 9 + 5 * way, up = CGFloat(11 - i) * (0.7 + 0.25 * CGFloat(j)), r = 1.1 - 0.5 * s
                    let bead = CGPoint(x: skim.place(i) + out * s, y: wet(i) - up * 4 * s * (1 - s) - 1)
                    context.fill(Path(ellipseIn: CGRect(x: bead.x - r, y: bead.y - r, width: 2 * r, height: 2 * r)),
                                 with: .color(Color(0xFFF4DC).opacity(0.8 * (1 - s))))
                }
            }
            if alpha > 0 {
                var stone = context
                stone.opacity = alpha
                stone.translateBy(x: at.x, y: at.y)
                stone.rotate(by: .radians(turn))
                let body = CGRect(x: -6.4, y: -2.5, width: 12.8, height: 5)
                stone.fill(Path(ellipseIn: body), with: .radialGradient(
                    Gradient(stops: [.init(color: Color(0xFFFBEE), location: 0), .init(color: Color(0xE8DAC0), location: 0.45),
                                     .init(color: Color(0x968470), location: 1)]),
                    center: CGPoint(x: -1.8, y: -1), startRadius: 0, endRadius: 9.3))
                stone.fill(Path(ellipseIn: CGRect(x: -3.6, y: -1.7, width: 3.3, height: 0.8)), with: .color(.white.opacity(0.75)))
            }
            let s = u - skim.time(n - 1), shown = Self.ease((s - 0.5) / 0.5) * (1 - Self.ease((s - 3) / 0.8))
            if shown > 0 {
                context.opacity = shown
                context.draw(Text(n, format: .number).font(.slope(.data, .detail)).foregroundStyle(SlopeInk.ink.colour),
                             at: CGPoint(x: skim.place(n - 1) + way * 5, y: water(skim.place(n - 1)) - 16))
            }
        }
        .allowsHitTesting(false)
    }

    private static func ease(_ x: Double) -> Double {
        let x = min(max(x, 0), 1)
        return x * x * (3 - 2 * x)
    }
}

/// The unnumbered pebble: a dull stone that says who made the game, for four seconds, when it is tapped. VoiceOver
/// reads it as a button named by its line.
struct SlopeUnnumbered: View {
    @State private var said = false

    var body: some View {
        let line = String(localized: "made by screendead",
                          comment: "The slope's menu: the one line of credits, said by a hidden pebble. screendead is the maker's name, never translated")
        Stone(state: .dull, action: { said = true }) {
            Text(line).font(.slope(.place, .body)).opacity(said ? 1 : 0) // loc: verbatim localized above
        }
        .accessibilityLabel(line) // loc: verbatim localized above
        .animation(.easeInOut(duration: 0.6), value: said)
        .task(id: said) {
            guard said, (try? await Task.sleep(for: .seconds(4))) != nil else { return }
            #if DEBUG
            if SlopeEggHarness.wanted == .pebble { return }
            #endif
            said = false
        }
        #if DEBUG
        .task {
            // The harness's tap, whose line stays for its shot.
            guard SlopeEggHarness.wanted == .pebble,
                  (try? await Task.sleep(for: .seconds(SlopeEggHarness.posed ? 0 : 1.5))) != nil else { return }
            said = true
        }
        #endif
    }
}

extension EnvironmentValues {
    /// The menu's water has gone still (`Calm`): what breathes on it holds.
    @Entry var slopeStill = false
}

#if DEBUG
/// UNSTIR_EGG: an egg shown without its finger, for shots and films (scripts/shots/slope-eggs.sh). Debug builds only.
///
/// - `still`: the menu idles two seconds in, not twenty.
/// - `night`: a second in, the overview is pulled down past the surface, held five seconds and let go.
/// - `skim`: a second in, a stone is skimmed from beside the bank; UNSTIR_EGGSPEED is the flick's (1900 points a second),
///   and UNSTIR_EGGAT holds it that many seconds into its throw, for a still.
/// - `pebble`: the dive goes to its foot, and a second and a half on the unnumbered pebble is tapped; its line stays.
/// - `seam`: a second and a half in, the camera sinks into plughole.
/// - `deep`: a second in, the overview is pulled up past its foot and held six seconds.
enum SlopeEggHarness: String {
    case still, night, skim, pebble, seam, deep

    static let speed = ProcessInfo.processInfo.environment["UNSTIR_EGGSPEED"].flatMap(Double.init) ?? 1900
    static let held = ProcessInfo.processInfo.environment["UNSTIR_EGGAT"].flatMap(Double.init)
    /// UNSTIR_CLOCK holds the ground's clock for a still: the egg is then shown at its end from the first frame.
    static let posed = ProcessInfo.processInfo.environment["UNSTIR_CLOCK"] != nil

    static let wanted = ProcessInfo.processInfo.environment["UNSTIR_EGG"].flatMap(SlopeEggHarness.init(rawValue:))

    @MainActor static func start() {
        guard wanted == .still else { return }
        Power.shared.idleSooner = .seconds(2)
        Power.shared.touched()
    }
}
#endif
