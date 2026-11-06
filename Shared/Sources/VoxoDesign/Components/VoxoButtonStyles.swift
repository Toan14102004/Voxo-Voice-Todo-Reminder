//
//  VoxoButtonStyles.swift
//  VoxoDesign
//

import SwiftUI

/// Filled accent button for the single primary action on a screen.
public struct VoxoPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VoxoFont.headline)
            .foregroundStyle(VoxoColor.textOnAccent)
            .frame(maxWidth: .infinity, minHeight: VoxoHitTarget.minimum)
            .background(VoxoColor.accent)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.medium, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

/// Outlined button for secondary actions sitting next to a primary one.
public struct VoxoSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VoxoFont.headline)
            .foregroundStyle(VoxoColor.accent)
            .frame(maxWidth: .infinity, minHeight: VoxoHitTarget.minimum)
            .background(VoxoColor.accentSoft)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.medium, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.4)
    }
}

public extension View {
    /// Standard page chrome: themed background that ignores safe areas.
    func voxoScreen() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(VoxoColor.background.ignoresSafeArea())
    }
}
