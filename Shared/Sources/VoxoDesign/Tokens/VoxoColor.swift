//
//  VoxoColor.swift
//  VoxoDesign
//
//  Palette from the Figma board "Tidy – Todo App", frame DS / Colors.
//  See PLAN.md §0 — these are the designer's hex values, not sampled pixels.
//
//  Do not take tokens from the host Figma file's variables: the board lives inside another
//  project's file whose brand is cyan, and those variables are not Tidy's.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

public enum VoxoColor {
    // MARK: - Brand

    /// #1E6FD0 — WCAG AA 4.95:1 on white.
    public static let primary = dynamic(light: 0x1E6FD0, dark: 0x4D9AF0)
    /// #EEF5FE — tinted fill behind selected chips and accent surfaces.
    public static let primaryTint = dynamic(light: 0xEEF5FE, dark: 0x16263A)

    // MARK: - Surfaces

    public static let background = dynamic(light: 0xFAFAF9, dark: 0x0C0A09)
    /// Cards and task rows.
    public static let surface = dynamic(light: 0xFFFFFF, dark: 0x1C1917)
    public static let surfaceRaised = dynamic(light: 0xFFFFFF, dark: 0x292524)

    // MARK: - Text

    /// "Ink" in the design.
    public static let textPrimary = dynamic(light: 0x1C1917, dark: 0xFAFAF9)
    public static let textSecondary = dynamic(light: 0x78716C, dark: 0xA8A29E)
    public static let textMuted = dynamic(light: 0xA8A29E, dark: 0x78716C)
    public static let textOnAccent = dynamic(light: 0xFFFFFF, dark: 0xFFFFFF)

    // MARK: - Priority (DS / Colors)

    public static let priorityHigh = dynamic(light: 0xEF4444, dark: 0xF87171)
    public static let priorityMedium = dynamic(light: 0xF59E0B, dark: 0xFBBF24)
    public static let priorityLow = dynamic(light: 0x3B82F6, dark: 0x60A5FA)

    // MARK: - Status

    public static let success = dynamic(light: 0x16A34A, dark: 0x4ADE80)
    public static let danger = dynamic(light: 0xEF4444, dark: 0xF87171)

    // MARK: - Lines

    public static let border = dynamic(light: 0xE7E5E4, dark: 0x292524)
    public static let separator = dynamic(light: 0xE7E5E4, dark: 0x292524)

    // MARK: - Resolution

    /// watchOS has no light appearance, and the design gives the watch its own brighter accents on
    /// pure black, so the dark value is the only one that applies there.
    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(watchOS)
            return Color(hex: dark)
        #elseif canImport(UIKit)
            return Color(UIColor { trait in
                UIColor(Color(hex: trait.userInterfaceStyle == .dark ? dark : light))
            })
        #else
            return Color(hex: light)
        #endif
    }
}

public extension VoxoColor {
    /// Watch-specific accents from the design: brighter, for contrast on absolute black.
    enum Watch {
        /// Titles and rings: the brighter blue, for contrast on absolute black.
        public static let accent = Color(hex: 0x4D9AF0)
        public static let accentSoft = Color(hex: 0x8CC0F7)
        /// Filled surfaces behind white text — the design keeps the deeper brand blue there,
        /// where the brighter accent would drop below WCAG AA.
        public static let accentStrong = Color(hex: 0x1E6FD0)
        public static let background = Color(hex: 0x000000)
    }
}

public extension Color {
    /// "RRGGBB" as stored on a list. Falls back to the brand colour rather than crashing on a
    /// value written by an older or newer build.
    init(hexString: String) {
        let cleaned = hexString.hasPrefix("#") ? String(hexString.dropFirst()) : hexString
        self.init(hex: UInt32(cleaned, radix: 16) ?? 0x1E6FD0)
    }

    /// 0xRRGGBB.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
