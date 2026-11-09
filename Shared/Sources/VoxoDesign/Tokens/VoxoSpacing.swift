//
//  VoxoSpacing.swift
//  VoxoDesign
//
//  Grid and radii from the Figma board, frame DS / Rules.
//

import SwiftUI

/// 8pt grid. The design uses exactly these steps: 4 / 8 / 12 / 16 / 24 / 32.
public enum VoxoSpacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 12
    public static let l: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let xxl: CGFloat = 32

    #if os(watchOS)
        public static let screenMargin: CGFloat = 8
    #else
        /// 24 on iPhone, per DS / Rules.
        public static let screenMargin: CGFloat = 24
    #endif
}

/// Corner radii, one per component class, as written in DS / Rules.
public enum VoxoRadius {
    public static let chip: CGFloat = 18
    public static let chipSmall: CGFloat = 8
    public static let taskRow: CGFloat = 14
    public static let card: CGFloat = 16
    public static let button: CGFloat = 20
    public static let sheet: CGFloat = 28
}

public enum VoxoHitTarget {
    /// DS / Rules: minimum 44pt.
    public static let minimum: CGFloat = 44
}

/// FAB placement from DS / Rules: floats above everything, 14pt clear of the tab bar,
/// with a 30% blue shadow.
public enum VoxoFABMetrics {
    public static let size: CGFloat = 60
    public static let gapAboveTabBar: CGFloat = 14
    public static let shadowOpacity: Double = 0.30
    public static let shadowRadius: CGFloat = 12
}
