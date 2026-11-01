// Copyright © 2026 Jack Lusher. All rights reserved.

// The framework marks nothing Sendable; its calls are made from the main actor and their results dropped.
@preconcurrency import DeclaredAgeRange
import SwiftUI

/// Apple's Declared Age Range check, which the US states' app store laws ask of every app (Texas now, more states in
/// 2027). Where the system says the law reaches the player, the age range is requested once a launch, while the menu
/// is up, never over a level. Every level is for all ages, so the answer changes nothing and is dropped: nothing of it
/// is kept, logged or sent.
enum AgeCheck {
    @MainActor static var asked = false

    /// Whether to request the range now. `eligible` is `isEligibleForAgeFeatures`; `menu`, that the menu is up with
    /// no card over it; `played`, that a person is playing, not the harness or the test host.
    static func due(eligible: Bool, asked: Bool, menu: Bool, played: Bool) -> Bool {
        eligible && !asked && menu && played
    }
}

struct AgeChecked: ViewModifier {
    let menu: Bool
    let played: Bool

    func body(content: Content) -> some View {
        if #available(iOS 26.2, *) {
            content.modifier(AgeRequest(menu: menu, played: played))
        } else {
            content
        }
    }
}

@available(iOS 26.2, *)
private struct AgeRequest: ViewModifier {
    let menu: Bool
    let played: Bool
    @Environment(\.requestAgeRange) private var requestAgeRange
    @State private var eligible = false

    func body(content: Content) -> some View {
        let due = AgeCheck.due(eligible: eligible, asked: AgeCheck.asked, menu: menu, played: played)
        content
            .task {
                guard played else { return }
                // Apple's docs require the Declared Age Range entitlement, which waits for the paid team's signing.
                eligible = (try? await AgeRangeService.shared.isEligibleForAgeFeatures) ?? false
            }
            .task(id: due) {
                guard due else { return }
                AgeCheck.asked = true
                _ = try? await requestAgeRange(ageGates: 18)
            }
    }
}
