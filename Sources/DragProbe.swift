// Copyright © 2026 Jack Lusher. All rights reserved.

import QuartzCore

#if PROBES || DEBUG
@_silgen_name("proc_pid_rusage") private func proc_pid_rusage(_ pid: Int32, _ flavor: Int32, _ buffer: UnsafeMutablePointer<rusage_info_v4>) -> Int32

/// UNSTIR_DRAGCPU=1: what the main thread spends on a frame of a turn in hand, and of a live picture at rest, for
/// `scripts/drag-probe.sh`. Each window of UNSTIR_TAPDRAG's drags, and the rest after them, logs its frames, the main
/// thread's and the process's CPU time a frame, the instructions the process retired a frame (the work itself: CPU
/// time doubles when the Mac moves the thread to a slower core), and how often each part of the play screen was
/// evaluated. A probe: Debug holds it, and a Release build only with PROBES=YES (`Config/Unstir.xcconfig`).
@MainActor enum DragProbe {
    enum Part: Int, CaseIterable {
        /// `LevelView.body`, `LevelView.tank`, the glass's timeline, `PictureLayer.body`, the shader's arguments built
        /// (`Unstirred.shader`), and a held part's own body (`InHand`).
        case level, tank, timeline, picture, shader, leaf, equal
    }

    nonisolated static let on = ProcessInfo.processInfo.environment["UNSTIR_DRAGCPU"] != nil
    nonisolated(unsafe) private static var counts = [Int](repeating: 0, count: Part.allCases.count)
    private static var open: (name: String, main: UInt64, process: UInt64, instructions: UInt64, counts: [Int], frames: Frames)?
    /// What the level's glass last drew, and the most either part moved between two frames since the last line: every
    /// turn's angle summed, which a let-go's landing leaves as it was (the turn in hand becomes an entry of the same
    /// angle), and the glass's turn. A frame drawn with the new stack under the old turn in hand, or the old under the
    /// new, would show as a jump of a whole step.
    nonisolated(unsafe) private static var drawn: (sum: Double, turn: Double)?
    nonisolated(unsafe) private static var jump = (sum: 0.0, turn: 0.0)

    private final class Frames: NSObject {
        var n = 0
        var link: CADisplayLink?
        @objc func tick(_ link: CADisplayLink) { n += 1 }
    }

    nonisolated static func count(_ part: Part) {
        if on { counts[part.rawValue] += 1 }
    }

    /// The level's glass as `HeldUnstirred` last built it, how often it was built again with nothing changed, and
    /// which of its parts had changed when something had.
    private static var held: (rest: Unstirred, angle: Double, turn: Double?)?
    private static var idle = 0
    private static var changed: Set<String> = []

    static func built(_ rest: Unstirred, angle: Double, turn: Double?) {
        guard on else { return }
        if let was = held {
            let a = was.rest, b = rest
            var parts: [String] = []
            if a.stack != b.stack { parts.append("stack") }
            if a.liveRod != b.liveRod { parts.append("liveRod") }
            if a.wind != b.wind { parts.append("wind") }
            if a.side != b.side { parts.append("side") }
            if a.haze != b.haze { parts.append("haze") }
            if a.turn != b.turn { parts.append("turn") }
            if a.wave != b.wave { parts.append("wave") }
            if a.breath?.rod != b.breath?.rod || a.breath?.angle != b.breath?.angle { parts.append("breath") }
            if a.tick?.rod != b.tick?.rod || a.tick?.angle != b.tick?.angle { parts.append("tick") }
            if a.isolate != b.isolate || a.held != b.held || a.hold != b.hold { parts.append("prism") }
            if a.budget != b.budget { parts.append("budget") }
            if a.crisp != b.crisp || a.fine != b.fine { parts.append("lens") }
            if was.angle != angle || was.turn != turn { parts.append("hand") }
            if parts.isEmpty, !a.draws(sameAs: b) { parts.append("other") }
            if parts.isEmpty { idle += 1 } else { changed.formUnion(parts) }
        }
        held = (rest, angle, turn)
    }

    nonisolated static func drew(sum: @autoclosure () -> Double, turn: Double) {
        guard on else { return }
        let sum = sum()
        if let d = drawn { jump = (max(jump.sum, abs(sum - d.sum)), max(jump.turn, abs(turn - d.turn))) }
        drawn = (sum, turn)
    }

    private static func instructions() -> UInt64 {
        var r = rusage_info_v4()
        return proc_pid_rusage(getpid(), 4, &r) == 0 ? r.ri_instructions : 0
    }

    static func begin(_ name: @autoclosure () -> String) {
        guard on else { return }
        let name = name()
        end()
        let frames = Frames()
        let link = CADisplayLink(target: frames, selector: #selector(Frames.tick))
        link.add(to: .main, forMode: .common)
        frames.link = link
        open = (name, clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID), clock_gettime_nsec_np(CLOCK_PROCESS_CPUTIME_ID), instructions(), counts, frames)
    }

    static func end() {
        guard let o = open else { return }
        open = nil
        o.frames.link?.invalidate()
        let n = Double(max(o.frames.n, 1))
        let main = Double(clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID) - o.main) / 1e6 / n
        let process = Double(clock_gettime_nsec_np(CLOCK_PROCESS_CPUTIME_ID) - o.process) / 1e6 / n
        let each = Part.allCases.map { "\($0) \(String(format: "%.2f", Double(counts[$0.rawValue] - o.counts[$0.rawValue]) / n))" }
        let work = Double(instructions() &- o.instructions) / 1e6 / n
        Log.write("dragcpu \(o.name): frames \(o.frames.n), main \(String(format: "%.3f", main)) ms, process \(String(format: "%.3f", process)) ms, "
                  + "instructions \(String(format: "%.2f", work)) M, "
                  + "a frame: " + each.joined(separator: ", ")
                  + String(format: "; glass jumps since the last line: turns %.3f, tank %.3f rad", jump.sum, jump.turn)
                  + "; glass built unchanged \(String(format: "%.2f", Double(idle) / n)) a frame, changed in \(changed.sorted().joined(separator: "+"))")
        jump = (0, 0)
        idle = 0
        changed = []
    }
}
#else
/// A plain Release build holds no probe: each call is nothing.
@MainActor enum DragProbe {
    enum Part { case level, tank, timeline, picture, shader, leaf, equal }
    nonisolated static let on = false
    @inline(__always) nonisolated static func count(_ part: Part) {}
    @inline(__always) static func built(_ rest: Unstirred, angle: Double, turn: Double?) {}
    @inline(__always) nonisolated static func drew(sum: @autoclosure () -> Double, turn: Double) {}
    @inline(__always) static func begin(_ name: @autoclosure () -> String) {}
    @inline(__always) static func end() {}
}
#endif
