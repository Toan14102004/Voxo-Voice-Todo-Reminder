//
//  VoxoFont.swift
//  VoxoDesign
//

import SwiftUI

/// Type scale.
///
/// Every size is declared `relativeTo` a system text style, so Dynamic Type scales the whole app
/// — a hard requirement in PLAN.md §7. Fixed-point fonts would silently break that.
///
/// iPhone uses Mulish (bundled by the app target). watchOS uses the system font: Mulish is not in
/// the Watch bundle, and SF is simply more legible at watch sizes.
public enum VoxoFont {
    public static var largeTitle: Font { scaled(weight: .bold, size: 30, relativeTo: .largeTitle) }
    public static var title: Font { scaled(weight: .bold, size: 22, relativeTo: .title2) }
    public static var headline: Font { scaled(weight: .semiBold, size: 17, relativeTo: .headline) }
    public static var body: Font { scaled(weight: .regular, size: 16, relativeTo: .body) }
    public static var callout: Font { scaled(weight: .regular, size: 15, relativeTo: .callout) }
    public static var subheadline: Font { scaled(weight: .medium, size: 14, relativeTo: .subheadline) }
    public static var footnote: Font { scaled(weight: .regular, size: 13, relativeTo: .footnote) }
    public static var caption: Font { scaled(weight: .medium, size: 12, relativeTo: .caption) }

    public enum Weight: String {
        case regular = "Mulish-Regular"
        case medium = "Mulish-Medium"
        case semiBold = "Mulish-SemiBold"
        case bold = "Mulish-Bold"

        var system: Font.Weight {
            switch self {
            case .regular: .regular
            case .medium: .medium
            case .semiBold: .semibold
            case .bold: .bold
            }
        }
    }

    private static func scaled(weight: Weight, size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        #if os(watchOS)
            return .system(style, design: .rounded).weight(weight.system)
        #else
            return .custom(weight.rawValue, size: size, relativeTo: style)
        #endif
    }
}
