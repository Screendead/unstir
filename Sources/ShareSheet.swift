// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI
import UIKit

/// The system share sheet, opened by a button of the app's own, which taps as every button does: a ShareLink's tap went
/// unheard on a device (Jack's call SND3 = B, round 16).
enum ShareSheet {
    /// Over whatever is in front, since a root already presenting a sheet (settings') presents nothing more.
    @MainActor static func present(_ items: [Any], animated: Bool = true) {
        guard var top = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?
            .rootViewController else { return }
        while let next = top.presentedViewController, !next.isBeingDismissed { top = next }
        top.present(UIActivityViewController(activityItems: items, applicationActivities: nil), animated: animated)
    }
}

/// An item with a subject line, for the apps that take one, as Mail does.
final class SubjectItem: NSObject, UIActivityItemSource {
    private let item: Any
    private let subject: String

    init(_ item: Any, subject: String) {
        self.item = item
        self.subject = subject
    }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { item }

    func activityViewController(_ controller: UIActivityViewController,
                                itemForActivityType type: UIActivity.ActivityType?) -> Any? { item }

    func activityViewController(_ controller: UIActivityViewController,
                                subjectForActivityType type: UIActivity.ActivityType?) -> String { subject }
}

/// A share button: it taps as it opens the sheet.
struct ShareButton<Label: View>: View {
    let items: () -> [Any]
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button { ShareSheet.present(items()) } label: { label() }.buttonStyle(Sounding())
    }
}
