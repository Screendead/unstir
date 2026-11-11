// Copyright © 2026 Jack Lusher. All rights reserved.

// The framework marks nothing Sendable; every call is made from the main actor.
@preconcurrency import GameKit
import UIKit

/// Game Center's sign-in and achievements (Jack's call F5 = B, round 14), behind the build's GAME_CENTER: NO, v1's
/// until the sign-in overlay test on an iOS 26.2 phone passes, makes no GameKit call. With it YES, a plain launch signs
/// in once, the first time the menu is up with nothing over it, and reports what `Achievement.due` finds as every
/// finish's card shows (`Carded.shown`, so a banner never lands before the card) and on the first turn of the tank or
/// the swirl. The harness and the test host never sign in, so never report.
@MainActor
final class GameCenter {
    static let shared = GameCenter()

    /// Info.plist's `GameCenter`, which the build's GAME_CENTER sets.
    static let built = Bundle.main.object(forInfoDictionaryKey: "GameCenter") as? String == "YES"
    /// Past the dip into the menu, as `AgeCheck.settle`, so the sign-in never lands over the black.
    static let settle = Duration.seconds(0.3)

    /// A plain launch of a build with Game Center: set once, by `RootView`.
    var plays = false
    /// The menu has been up with nothing over it for `settle`: the only time a sign-in sheet is shown.
    var calm = false {
        didSet { present() }
    }
    private var asked = false
    private(set) var signedIn = false
    /// How many reports were asked for, signed in or not, which the tests read.
    private(set) var reports = 0
    /// Each achievement's percent as Game Center last had it, so only a rise is sent.
    private var reported: [String: Double] = [:]
    /// The sign-in sheet GameKit handed over while the menu wasn't calm, held until it is.
    private var sheet: UIViewController?

    func signIn() {
        guard plays, !asked else { return }
        asked = true
        GKAccessPoint.shared.isActive = false
        // GameKit calls this again whenever the player's state changes, a return to the front included.
        GKLocalPlayer.local.authenticateHandler = { controller, _ in
            Task { @MainActor in GameCenter.shared.authenticated(controller) }
        }
    }

    private func authenticated(_ controller: UIViewController?) {
        if let controller {
            sheet = controller
            present()
            return
        }
        let was = signedIn
        signedIn = GKLocalPlayer.local.isAuthenticated
        Log.write("game center: \(signedIn ? "signed in" : "not signed in")")
        guard signedIn, !was else { return }
        Task {
            // An achievement already complete sends no banner again.
            for a in (try? await GKAchievement.loadAchievements()) ?? [] {
                reported[a.identifier] = max(reported[a.identifier] ?? 0, a.percentComplete)
            }
            report()
        }
    }

    private func present() {
        guard calm, let sheet,
              let root = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?
                .rootViewController else { return }
        var top = root
        while let above = top.presentedViewController { top = above }
        self.sheet = nil
        top.present(sheet, animated: true)
    }

    /// Reads the stored state afresh, so a call is cheap to repeat and never counts twice.
    func report() {
        reports += 1
        guard signedIn else { return }
        let due = Achievement.due(.stored(), reported: reported)
        guard !due.isEmpty else { return }
        let before = reported
        let sent = due.map { a, percent in
            reported[a.id] = percent
            let g = GKAchievement(identifier: a.id)
            g.percentComplete = percent
            g.showsCompletionBanner = true
            return g
        }
        Task {
            do {
                try await GKAchievement.report(sent)
            } catch {
                // Sent again on the next report.
                for (a, _) in due { reported[a.id] = before[a.id] }
            }
        }
    }
}
