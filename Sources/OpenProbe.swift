// Copyright © 2026 Jack Lusher. All rights reserved.

import QuartzCore

#if DEBUG
/// How long a level takes to show after its pick, logged once its first frames are up: ms from the pick to the level
/// screen's first body pass, to its onAppear, and to each of the display link's first frames, with the longest gap
/// between them. A link added at the pick first fires once the main thread has finished the pass that builds the level,
/// so its first frame's ms is the freeze.
@MainActor enum OpenProbe {
    private static var start: CFTimeInterval?
    private static var body: Double?
    private static var appear: Double?
    private static var opens = 0
    private static var marks: [String] = []
    private static var frames: Frames?
    /// The open level's way back, for the tour.
    static var leave: (() -> Void)?

    private final class Frames: NSObject {
        var times: [CFTimeInterval] = []
        var link: CADisplayLink?
        @objc func tick(_ link: CADisplayLink) {
            times.append(CACurrentMediaTime())
            if times.count == 12 { MainActor.assumeIsolated { OpenProbe.report() } }
        }
    }

    private static func ms(_ t: CFTimeInterval) -> Double { ((t - (start ?? t)) * 1000).rounded() }

    static func picked() {
        frames?.link?.invalidate()
        start = CACurrentMediaTime()
        body = nil
        appear = nil
        marks = []
        opens += 1
        let f = Frames()
        f.link = CADisplayLink(target: f, selector: #selector(Frames.tick))
        f.link?.add(to: .main, forMode: .common)
        frames = f
    }

    static func bodyRan() {
        guard start != nil, body == nil else { return }
        body = ms(CACurrentMediaTime())
    }

    /// A step of the open, the first time it is reached after the pick.
    static func mark(_ name: String) {
        guard start != nil, !marks.contains(where: { $0.hasPrefix(name + " ") }) else { return }
        marks.append("\(name) \(Int(ms(CACurrentMediaTime())))")
    }

    static func appeared() {
        guard start != nil, appear == nil else { return }
        appear = ms(CACurrentMediaTime())
    }

    fileprivate static func report() {
        guard let f = frames else { return }
        f.link?.invalidate()
        frames = nil
        let at = f.times.map(ms)
        let gap = zip(at, at.dropFirst()).map { $1 - $0 }.max() ?? 0
        Log.write("open probe \(opens): body \(body.map { "\(Int($0))" } ?? "-") ms, appear \(appear.map { "\(Int($0))" } ?? "-") ms, "
                  + "first frame \(Int(at.first ?? 0)) ms, then longest gap \(Int(gap)) ms, frames \(at.map { "\(Int($0))" }.joined(separator: " ")); \(marks.joined(separator: ", "))")
        start = nil
    }
}
#else
@MainActor enum OpenProbe {
    static var leave: (() -> Void)? { get { nil } set {} }
    @inline(__always) static func picked() {}
    @inline(__always) static func bodyRan() {}
    @inline(__always) static func appeared() {}
    @inline(__always) static func mark(_ name: String) {}
}
#endif
