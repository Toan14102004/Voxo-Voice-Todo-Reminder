//
//  VoxoFont.swift
//  VoxoDesign
//
//  Type scale from the Figma board, frame DS / Typography.
//

import SwiftUI

/// Be Vietnam Pro, bundled in both targets (SIL Open Font License).
///
/// Every size is declared `relativeTo` a system text style so Dynamic Type scales the whole app.
/// Fixed-point fonts would silently break accessibility, which the design's WCAG AA rule rules out.
public enum VoxoFont {
    /// 28 Bold — "Hôm nay / Today".
    public static var display: Font { scaled(.bold, 28, relativeTo: .largeTitle) }
    /// 24 Bold — screen and task titles.
    public static var title: Font { scaled(.bold, 24, relativeTo: .title2) }
    /// 17 SemiBold — section titles.
    public static var headline: Font { scaled(.semiBold, 17, relativeTo: .headline) }
    /// 16 Medium — emphasised body.
    public static var bodyEmphasis: Font { scaled(.medium, 16, relativeTo: .body) }
    /// 15 Regular — task text, notes.
    public static var body: Font { scaled(.regular, 15, relativeTo: .body) }
    /// 13 Regular — meta: time, list name.
    public static var caption: Font { scaled(.regular, 13, relativeTo: .caption) }
    /// 12 SemiBold, uppercase at the call site — section labels.
    public static var overline: Font { scaled(.semiBold, 12, relativeTo: .caption2) }

    public enum Weight: String {
        case regular = "BeVietnamPro-Regular"
        case medium = "BeVietnamPro-Medium"
        case semiBold = "BeVietnamPro-SemiBold"
        case bold = "BeVietnamPro-Bold"
    }

    private static func scaled(_ weight: Weight, _ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        #if os(watchOS)
            // The design floors watch text at 13pt for legibility on a small, always-dark screen.
            .custom(weight.rawValue, size: max(size - 2, 13), relativeTo: style)
        #else
            .custom(weight.rawValue, size: size, relativeTo: style)
        #endif
    }
}
