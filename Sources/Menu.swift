// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

private let neonSweep = LinearGradient(colors: [.neonCyan, .magenta, .amber], startPoint: .leading, endPoint: .trailing)
private let bloodSweep = LinearGradient(colors: [.blood, .magenta, .violet], startPoint: .leading, endPoint: .trailing)

extension Level {
    /// Every twelve levels walk the grid's whole hue sweep, so the first screen shows all of it; past plughole they
    /// walk blood red through magenta to violet. The daily is amber, endless cyan, the sandbox magenta.
    var colour: Color {
        guard let n = Int(label) else { return sandbox ? .magenta : run == nil ? .amber : .neonCyan }
        let t = Double((n - 1) % 12) / 11
        return tier == .plughole ? oklch(0.639, 0.34, 190 + 240 * t) : oklch(0.62, 0.3, 23 - 82 * t)
    }
}

struct MenuView: View {
    /// UNSTIR_UNLOCK: every row open, for screenshots.
    let unlock: Bool
    let onPick: (Level) -> Void
    @AppStorage("tier") private var tier = Tier.plughole

    var body: some View {
        // Daily and endless draw on every layout, so they open after the first hex level.
        let modes = unlock || Best.load(Level.plughole[22].id) != nil
        let plughole = tier == .plughole, levels = tier.levels
        let sweep = plughole ? neonSweep : bloodSweep
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("UNSTIR").font(.system(size: 34, weight: .black).width(.expanded)).tracking(8)
                        .foregroundStyle(sweep).shadow(color: (plughole ? Color.magenta : .blood).opacity(0.6), radius: 12)
                    Spacer()
                    HStack(spacing: 10) {
                        // Whirlpool stays lit under maelstrom. Maelstrom is laid out even on plughole, so turning
                        // whirlpool on doesn't slide it out from under a second tap.
                        toggle(.whirlpool, on: !plughole)
                        toggle(.maelstrom, on: tier == .maelstrom)
                            .opacity(plughole ? 0 : 1).disabled(plughole).accessibilityHidden(plughole)
                    }
                }
                Text("Every stir in this tank has an exact inverse.")
                    .font(.mono(13)).opacity(0.55).padding(.top, 8)
                row(Level.daily(), enabled: modes).padding(.top, 30)
                row(.endless(Run(seed: .random(in: .min ... .max))), detail: "deeper every tank \u{00B7} one over par ends it",
                    best: Best.tanks > 0 ? Text("best \(Best.tanks)") : nil, enabled: modes)
                row(.sandbox, detail: "any picture, any rods \u{00B7} nothing counts", enabled: true)
                Rectangle().fill(sweep).frame(height: 1).padding(.vertical, 6)
                ForEach(Array(levels.enumerated()), id: \.offset) { i, level in
                    row(level, enabled: unlock || i == 0 || Best.load(levels[i - 1].id) != nil)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 28)
        }
        .foregroundStyle(Color.text)
        .background(Color.black)
    }

    /// Off, it picks its tier; on, it drops to the tier below.
    private func toggle(_ tier: Tier, on: Bool) -> some View {
        Button { self.tier = on ? tier.below ?? .plughole : tier } label: {
            Text(tier.name.lowercased()).font(.mono(12)).foregroundStyle(on ? Color.blood : .white.opacity(0.35))
                .shadow(color: .blood.opacity(on ? 0.6 : 0), radius: 8)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? [.isToggle, .isSelected] : .isToggle)
    }

    private func row(_ level: Level, detail: String? = nil, best: Text? = nil, enabled: Bool) -> some View {
        let result = Best.load(level.id)
        return Button { onPick(level) } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                // A locked number stays bright enough that the hue walk still reads on first launch.
                Text(level.label).font(.mono(13, .semibold)).foregroundStyle(level.colour)
                    .shadow(color: enabled ? level.colour : .clear, radius: 4).opacity(enabled ? 1 : 0.7)
                    .frame(width: 34, alignment: .leading)
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title).font(.mono(14)).multilineTextAlignment(.leading)
                    Text(detail ?? "\(level.layout.rods.count) rods \u{00B7} par \(level.par)").font(.mono(11)).opacity(0.32)
                }
                .opacity(enabled ? 1 : 0.38)
                Spacer(minLength: 8)
                Group {
                    if let best {
                        best.opacity(0.55)
                    } else if let result, result.clean == true {
                        Text("clean").fontWeight(.semibold).foregroundStyle(Color.lime).shadow(color: .lime, radius: 3)
                    } else if let result, result.over == 0 && result.hints == 0 {
                        Text("par").foregroundStyle(Color.amber)
                    } else if let result {
                        Text(result.over > 0 ? "+\(result.over)" : "hinted").foregroundStyle(Color.magenta)
                    }
                }
                .font(.mono(11))
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
