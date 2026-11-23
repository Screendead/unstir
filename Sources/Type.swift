// Copyright © 2026 Jack Lusher. All rights reserved.

import SwiftUI

/// Every piece of text round the game, by what it does: one scale on Dynamic Type, body at 17 pt and nothing that
/// carries meaning under 13 (Jack's call DESIGN5 = A, the design pass's first change). The play screen caps it at
/// `PlayLayout.typeCap`, as the tank needs its room; every other screen scales to the accessibility sizes.
enum TypeRole {
    /// 34 pt, SF Pro Black Expanded: the wordmark and a pack's or the archive's name.
    case display
    /// 22 pt, SF Pro Black Expanded: TierUp's tier name.
    case displaySmall
    /// 22 pt semibold: "unstirred." over the solved tank (fixed in the tabletop).
    case stamp
    /// 20 pt semibold: the settings sheet's and the consent card's title.
    case title
    /// 17 pt semibold: the level's title line, a status line, the result's verdict.
    case headline
    /// 17 pt: a row's title, the consent card's body.
    case body
    /// 17 pt medium: every button's label.
    case button
    /// 15 pt medium: the tier chips, the one place four buttons must share a screen's width.
    case chip
    /// 15 pt: the header's count, the note under the tank, a card's pitch and facts, a level number in a row (semibold).
    case label
    /// 13 pt: a row's detail, fact keys, section headers (semibold) and their progress, settings' details, small print.
    case detail
    /// 12 pt semibold, tracked and uppercase at the call: "UP A NOTCH" and the like, never alone carrying meaning.
    case eyebrow

    var style: Font.TextStyle {
        switch self {
        case .display: .largeTitle
        case .displaySmall, .stamp: .title2
        case .title: .title3
        case .headline: .headline
        case .body, .button: .body
        case .chip, .label: .subheadline
        case .detail: .footnote
        case .eyebrow: .caption
        }
    }

    var weight: Font.Weight {
        switch self {
        case .display, .displaySmall: .black
        case .title, .stamp, .headline, .eyebrow: .semibold
        case .button, .chip: .medium
        case .body, .label, .detail: .regular
        }
    }
}

extension TypeRole {
    /// The role's size at `size`, as Dynamic Type scales the text style it is set in.
    func points(at size: DynamicTypeSize) -> CGFloat {
        UIFontMetrics(forTextStyle: style.ui).scaledValue(for: base, compatibleWith:
            UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size)))
    }

    /// A line of the role at `size`, and how far its baseline sits under the line's top, as `Text` lays it out: a text
    /// style's font, whose leading grows faster than its size.
    func line(at size: DynamicTypeSize, _ weight: Font.Weight? = nil,
              design: UIFontDescriptor.SystemDesign = .monospaced) -> (height: CGFloat, ascent: CGFloat) {
        let font = font(at: size, weight, design: design)
        return (font.lineHeight, font.ascender)
    }

    /// The width of `text` on one line of the role at `size`.
    func width(of text: String, at size: DynamicTypeSize) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font(at: size, nil, design: .monospaced)]).width
    }

    private func font(at size: DynamicTypeSize, _ weight: Font.Weight?, design: UIFontDescriptor.SystemDesign) -> UIFont {
        let styled = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style.ui, compatibleWith:
            UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size)))
        let weighted = styled.addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: (weight ?? self.weight).ui]])
        return UIFont(descriptor: weighted.withDesign(design) ?? weighted, size: 0)
    }

    /// The text style's size at the default Dynamic Type size.
    private var base: CGFloat {
        switch self {
        case .display: 34
        case .displaySmall, .stamp: 22
        case .title: 20
        case .headline, .body, .button: 17
        case .chip, .label: 15
        case .detail: 13
        case .eyebrow: 12
        }
    }
}

private extension Font.TextStyle {
    var ui: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}

private extension Font.Weight {
    var ui: UIFont.Weight {
        switch self {
        case .ultraLight: .ultraLight
        case .thin: .thin
        case .light: .light
        case .medium: .medium
        case .semibold: .semibold
        case .bold: .bold
        case .heavy: .heavy
        case .black: .black
        default: .regular
        }
    }
}

extension Font {
    /// Text in `role`, at `weight` where the role allows two (a number in a label, a section's name in a detail).
    static func ui(_ role: TypeRole, _ weight: Font.Weight? = nil) -> Font {
        switch role {
        case .display, .displaySmall: .system(role.style, weight: weight ?? role.weight).width(.expanded)
        default: .system(role.style, design: .monospaced, weight: weight ?? role.weight)
        }
    }

    /// The game's own text, fixed in size as the tank and its rim are: a knob's letters, "spilled.", the tabletop's "unstirred.".
    static func game(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// The slope's voices (docs/slope.md, 1.3): who is speaking decides the face, the size its text style. Every one
/// follows Dynamic Type to the largest sizes; nothing on the slope shrinks to fit.
enum SlopeVoice {
    /// The names of places and what the game says: New York italic, light.
    case place
    /// A level's or a pack's name, the wordmark: SF Pro, light.
    case name
    /// Controls, row titles, details, explanations: SF Pro, regular.
    case ui
    /// Numbers and counts: SF Mono, regular.
    case data
}

/// The slope's five sizes, at the default setting.
enum SlopeSize {
    /// 34 pt.
    case display
    /// 28 pt.
    case title
    /// 17 pt.
    case body
    /// 15 pt.
    case label
    /// 13 pt: nothing that means something is under it.
    case detail

    var style: Font.TextStyle {
        switch self {
        case .display: .largeTitle
        case .title: .title
        case .body: .body
        case .label: .subheadline
        case .detail: .footnote
        }
    }
}

extension Font {
    /// Text in one of the slope's voices at one of its sizes; `weight` where a voice takes another (a control that
    /// is the way on is medium, "buy" semibold).
    static func slope(_ voice: SlopeVoice, _ size: SlopeSize, _ weight: Font.Weight? = nil) -> Font {
        switch voice {
        case .place: .system(size.style, design: .serif, weight: weight ?? .light).italic()
        case .name: .system(size.style, design: .default, weight: weight ?? .light)
        case .ui: .system(size.style, design: .default, weight: weight ?? .regular)
        case .data: .system(size.style, design: .monospaced, weight: weight ?? .regular)
        }
    }
}
