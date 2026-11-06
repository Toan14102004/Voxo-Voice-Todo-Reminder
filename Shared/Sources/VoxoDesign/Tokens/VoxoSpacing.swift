//
//  VoxoSpacing.swift
//  VoxoDesign
//

import SwiftUI

/// 8pt grid, trimmed down on watchOS where screen width is the binding constraint.
public enum VoxoSpacing {
    #if os(watchOS)
        public static let xs: CGFloat = 2
        public static let s: CGFloat = 4
        public static let m: CGFloat = 8
        public static let l: CGFloat = 12
        public static let xl: CGFloat = 16
        public static let screenMargin: CGFloat = 4
    #else
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let screenMargin: CGFloat = 16
    #endif
}

public enum VoxoRadius {
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
}

/// Apple's minimum comfortable hit target.
public enum VoxoHitTarget {
    public static let minimum: CGFloat = 44
}
