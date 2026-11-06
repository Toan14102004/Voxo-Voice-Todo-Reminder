//
//  VoxoColor.swift
//  VoxoDesign
//
//  One palette for both apps.
//
//  The BaseSource template shipped 46 single-appearance colorsets while forcing
//  `.colorScheme(.dark)` and hardcoding black backgrounds, so its tokens never actually drove the
//  look. These do: every token resolves light/dark at runtime.
//

import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

public enum VoxoColor {
    // MARK: - Surfaces

    /// Page background.
    public static let background = dynamic(light: 0xFFFFFF, dark: 0x0B0B0F)
    /// Cards, rows, grouped content sitting on `background`.
    public static let surface = dynamic(light: 0xF5F5F8, dark: 0x17171C)
    /// A surface that needs to read as lifted off `surface` (sheets, selected rows).
    public static let surfaceRaised = dynamic(light: 0xFFFFFF, dark: 0x22222A)

    // MARK: - Text

    public static let textPrimary = dynamic(light: 0x16161A, dark: 0xF5F5F7)
    public static let textSecondary = dynamic(light: 0x5C5C66, dark: 0xA0A0AC)
    public static let textTertiary = dynamic(light: 0x8E8E99, dark: 0x6E6E7A)
    /// Text drawn on top of `accent`.
    public static let textOnAccent = dynamic(light: 0xFFFFFF, dark: 0x0B0B0F)

    // MARK: - Brand

    /// Voxo's accent: an indigo that stays legible on both grounds and is distinct from the
    /// green/red used for status, so colour is never the only signal (PLAN.md §7).
    public static let accent = dynamic(light: 0x4F46E5, dark: 0x8B84FF)
    /// Tinted fill for accent-coloured chips and selected states.
    public static let accentSoft = dynamic(light: 0xEBEAFD, dark: 0x252043)

    // MARK: - Status

    public static let done = dynamic(light: 0x1F8A4C, dark: 0x4ADE80)
    public static let doneSoft = dynamic(light: 0xE4F6EB, dark: 0x16301F)
    /// A reminder that is past due.
    public static let overdue = dynamic(light: 0xC2410C, dark: 0xFB923C)
    public static let overdueSoft = dynamic(light: 0xFDEEE4, dark: 0x33200F)
    public static let danger = dynamic(light: 0xC02626, dark: 0xF87171)

    // MARK: - Lines

    public static let separator = dynamic(light: 0xE4E4EA, dark: 0x2A2A33)
    public static let border = dynamic(light: 0xD3D3DC, dark: 0x3A3A45)

    // MARK: - Resolution

    /// watchOS has no light appearance, so the dark value is the only one that can apply.
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

public extension Color {
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
