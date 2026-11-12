// Copyright © 2026 Jack Lusher. All rights reserved.

// The framework marks nothing Sendable; its calls are made from the main actor and their results dropped.
@preconcurrency import DeclaredAgeRange
import SwiftUI

/// Apple's Declared Age Range check, which the US states' app store laws ask of every app (Texas now, more states in
/// 2027). Where the system says the law reaches the player, the age range is requested once a launch, while the menu
/// is up, never over a level. Every level is for all ages, so the answer changes nothing and is dropped: nothing of it
/// is kept, logged or sent.
@MainActor
enum AgeCheck {
    static var asked = false
    /// Past the dip into the menu (0.27 s), so a request made as a level is left never lands over the black.
    static let settle = Duration.seconds(0.3)

    /// Whether the range may be requested now. `eligible` is `isEligibleForAgeFeatures`; `menu`, that the menu is up
    /// with nothing over it (a card, the consent question, the settings sheet); `played`, that a person is playing, not
    /// the harness or the test host.
    static func ready(eligible: Bool, menu: Bool, played: Bool) -> Bool {
        eligible && menu && played
    }

    /// Requests the range once a launch. A request whose task is cancelled, before or during it (the menu covered or
    /// left), leaves `asked` false, so the menu asks again when it is next up. One that fails is not retried.
    static func ask(_ request: () async -> Void) async {
        guard !asked else { return }
        try? await Task.sleep(for: settle)
        guard !Task.isCancelled else { return }
        asked = true
        await request()
        if Task.isCancelled { asked = false }
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
        let ready = AgeCheck.ready(eligible: eligible, menu: menu, played: played)
        content
            .task {
                guard played else { return }
                // Apple's docs require the Declared Age Range entitlement, which a build signs only with AGE_RANGE=YES.
                eligible = (try? await AgeRangeService.shared.isEligibleForAgeFeatures) ?? false
            }
            .task(id: ready) {
                guard ready else { return }
                await AgeCheck.ask { _ = try? await requestAgeRange(ageGates: 18) }
            }
    }
}
