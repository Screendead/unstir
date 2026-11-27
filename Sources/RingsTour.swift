// Copyright © 2026 Jack Lusher. All rights reserved.

#if PROBES || DEBUG
import UIKit

/// The rings moved with no finger, for a trace on the phone. UNSTIR_RINGSTOUR names one motion: `swipe` (down
/// through every ring and back, by the pager's own glide, the path a finger's release takes), `open` (the middle
/// tapped, so its level opens), `pick` (a bead named in the middle and let go), `speak` (what VoiceOver reads, logged,
/// before and after the middle steps to the next ring), `renew` (endless's new run tapped twice, a run saved) or `rest`
/// (six seconds untouched).
/// Each is marked in the flight log as the trace's reader expects ("tour swipe" ... "tour ends"), with what the main
/// thread did meanwhile on a line of its own.
/// UNSTIR_RINGSPOSE holds a still for a shot: `ring:2`, that ring in front; `place:1.5`, a swipe stopped there;
/// `pick:9`, that bead of the ring in front named in the middle (after `ring:n,` to choose the ring).
extension RingsView {
    private static let touring = ProcessInfo.processInfo.environment["UNSTIR_RINGSTOUR"]
    private static let pose = ProcessInfo.processInfo.environment["UNSTIR_RINGSPOSE"]
    /// Once a launch: the root builds the menu again each time a level is left.
    private static var toured = false

    func tour() {
        guard !Self.toured, Self.touring != nil || Self.pose != nil else { return }
        Self.toured = true
        if let pose = Self.pose {
            // Once the launch's layouts have settled, so none builds the menu again at rest.
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                hold(pose)
            }
            return
        }
        guard let motion = Self.touring, let model else { return }
        Task {
            func rest(_ seconds: Double) async { try? await Task.sleep(for: .seconds(seconds)) }
            // The trace's reader takes the seconds before the first mark as the menu at rest.
            await rest(3)
            let mark = RingsCount.all
            Log.write("tour \(motion), ground drawn 0")
            switch motion {
            case "swipe":
                let home = at, last = model.rings.count - 1
                var stops = Array(stride(from: home + 1, through: last, by: 1))
                stops += stride(from: last - 1, through: 0, by: -1)
                stops += stride(from: 1, through: home, by: 1)
                for index in stops {
                    await glide(to: index)
                    await rest(0.35)
                }
            case "open":
                act(.middle)
                await rest(2)
            case "renew":
                // Endless's new run tapped twice inside its window, with a run saved: the second deals a new one.
                go(to: model.rings.count - 1, animated: false)
                act(.renew)
                await rest(0.3)
                act(.renew)
                await rest(1)
            case "speak":
                func said() -> String {
                    (accessibilityElements ?? []).compactMap { $0 as? UIAccessibilityElement }.map {
                        "\($0.accessibilityLabel ?? "")=\($0.accessibilityValue ?? "")"
                    }.joined(separator: " | ")
                }
                Log.write("rings spoken: \(said())")
                let middle = (accessibilityElements ?? []).compactMap { $0 as? UIAccessibilityElement }
                    .first { $0.accessibilityTraits.contains(.adjustable) }
                middle?.accessibilityIncrement()
                await rest(0.5)
                Log.write("rings spoken after a step: \(said())")
            case "pick":
                let way = model.rings[at].way ?? 0
                act(.bead(way == 0 ? 1 : 0))
                await rest(1.5)
                act(.nothing)
                await rest(0.5)
            default:
                await rest(6)
            }
            Log.write("tour ends, ground drawn 0")
            Log.write("rings \(motion): \(RingsCount.since(mark)); art \(RingsArt.shared.count) bitmaps, \(RingsArt.shared.bytes / 1024) KB")
        }
    }

    private func glide(to index: Int) async {
        guard index != at else { return }
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            glided = { [weak self] in
                self?.glided = nil
                done.resume()
            }
            go(to: index)
            // A glide UIKit never reports as ended still lets the tour end.
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                self.glided?()
            }
        }
    }

    private func hold(_ pose: String) {
        for part in pose.split(separator: ",") {
            let words = part.split(separator: ":"), value = words.count > 1 ? Double(words[1]) ?? 0 : 0
            switch words.first {
            case "ring": go(to: Int(value), animated: false)
            case "place": hold(place: CGFloat(value))
            case "pick": act(.bead(Int(value) - 1))
            default: break
            }
        }
        Log.write("rings pose \(pose): \(RingsCount.since([0, 0, 0, 0, 0, 0])); art \(RingsArt.shared.count) bitmaps, \(RingsArt.shared.bytes / 1024) KB")
    }
}
#endif
