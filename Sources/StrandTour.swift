// Copyright © 2026 Jack Lusher. All rights reserved.

#if DEBUG
import UIKit

/// The menu moved with no finger, for a trace on the phone. UNSTIR_STRANDTOUR names one motion: `scroll` (the overview
/// down and back up), `dive` (the overview to a tier), `divescroll` (the dive down and back up), `rise`, `rest` (six
/// seconds untouched) or `open` (today's daily tapped). Each is marked in the flight log as the trace's reader
/// expects, with what the main thread did meanwhile on a line of its own.
/// UNSTIR_STRANDPOSE holds a still for a shot: `overview:0.5` or `dive:0.3`, a rest that far down its scroll, or
/// `mid`, a travel stopped halfway.
extension StrandView {
    private static let touring = ProcessInfo.processInfo.environment["UNSTIR_STRANDTOUR"]
    private static let pose = ProcessInfo.processInfo.environment["UNSTIR_STRANDPOSE"]
    /// Once a launch: the root builds the menu again each time a level is left.
    private static var toured = false

    func tour() {
        guard !Self.toured, Self.touring != nil || Self.pose != nil else { return }
        Self.toured = true
        if let pose = Self.pose { return hold(pose) }
        guard let motion = Self.touring, let plan, let overview, let dive else { return }
        Task {
            func rest(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
            var mark = StrandCount.all
            @MainActor func start() {
                mark = StrandCount.all
                Log.write("tour \(motion), ground drawn 0")
            }
            // The trace's reader takes the two seconds before the first mark as the overview at rest.
            await rest(3)
            switch motion {
            case "scroll":
                start()
                await sweep(overview)
            case "dive":
                start()
                go(diving: true, tier: 1)
                await rest(Self.travel + 0.25)
            case "divescroll":
                go(diving: true, tier: 0, animated: false)
                await rest(1.5)
                start()
                await sweep(dive)
            case "rise":
                go(diving: true, tier: 1, animated: false)
                await rest(1.5)
                start()
                rise()
                await rest(Self.travel + 0.25)
            case "open":
                start()
                // Before the daily shows, the way on.
                let picks = plan.overview.hits.compactMap { hit -> (Level, CGPoint)? in
                    switch hit.what {
                    case let .daily(level), let .level(level): (level, hit.from)
                    default: nil
                    }
                }
                if let (level, from) = picks.first { onPick(level, overview.convert(from, to: self)) }
                await rest(2)
            default:
                start()
                await rest(6)
            }
            Log.write("tour ends, ground drawn 0")
            Log.write("strand \(motion): \(StrandCount.since(mark)); art \(StrandArt.shared.count) bitmaps, \(StrandArt.shared.bytes / 1024) KB")
        }
    }

    /// Down a column and back by UIKit's own animated scroll, a hop of most of a screen at a time: the path a
    /// finger's deceleration takes, the scroll view moving its bounds each frame and telling its delegate.
    private func sweep(_ column: StrandColumn) async {
        let end = max(column.rest.height - bounds.height, 0), hop = (bounds.height * 0.8).rounded()
        guard end > 0 else { return }
        var stops = Array(stride(from: hop, to: end, by: hop)) + [end]
        stops += stops.dropLast().reversed() + [0]
        for y in stops where y != column.contentOffset.y {
            await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
                scrolled = { [weak self] in
                    self?.scrolled = nil
                    done.resume()
                }
                column.setContentOffset(CGPoint(x: 0, y: y), animated: true)
                // A hop UIKit never reports as ended still lets the tour end.
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    self.scrolled?()
                }
            }
        }
    }

    private func hold(_ pose: String) {
        guard let overview, let dive else { return }
        let parts = pose.split(separator: ":"), share = parts.count > 1 ? CGFloat(Double(parts[1]) ?? 0) : 0
        switch parts.first {
        case "dive":
            go(diving: true, tier: 0, animated: false)
            dive.contentOffset.y = share * max(dive.rest.height - bounds.height, 0)
        case "mid":
            go(diving: true, tier: 1)
            for layer in [overview.layer, dive.layer] {
                layer.speed = 0
                layer.timeOffset = layer.convertTime(CACurrentMediaTime(), from: nil) + Self.travel * 0.45
            }
        default:
            overview.contentOffset.y = share * max(overview.rest.height - bounds.height, 0)
        }
        Log.write("strand pose \(pose): art \(StrandArt.shared.count) bitmaps, \(StrandArt.shared.bytes / 1024) KB")
    }
}
#endif
