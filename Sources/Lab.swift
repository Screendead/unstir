// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Gameplay mockups, reached by holding the menu's title. A lab level stores nothing: no best, start, undo bank, refill
/// day or tank flag.
enum Lab: Hashable, Sendable {
}

/// One row of the lab's list: a new level each time it is picked, so a random one is dealt afresh.
struct LabEntry: Sendable {
    let name: String
    let detail: String
    let level: @Sendable () -> Level
}

extension Lab {
    static let entries: [LabEntry] = []

    /// UNSTIR_LAB=name: the entry of that name, for the harness.
    static func level(named name: String) -> Level? {
        entries.first { $0.name == name }?.level()
    }
}

struct LabList: View {
    let pick: (Level) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("LAB").font(.system(size: 28, weight: .black).width(.expanded)).tracking(6)
                    .foregroundStyle(Color.amber).shadow(color: .amber.opacity(0.6), radius: 10)
                Text("Mockups. Nothing here is saved.").font(.mono(12)).opacity(0.55).padding(.top, 8)
                ForEach(Lab.entries.indices, id: \.self) { i in
                    let e = Lab.entries[i]
                    Button { pick(e.level()) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(e.name).font(.mono(15, .medium))
                            Text(e.detail).font(.mono(11)).opacity(0.45).multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 10)
            }
            .padding(20)
        }
        .foregroundStyle(Color.text)
        .background(Color.black)
    }
}
