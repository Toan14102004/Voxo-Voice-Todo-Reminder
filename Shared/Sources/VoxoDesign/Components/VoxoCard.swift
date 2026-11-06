//
//  VoxoCard.swift
//  VoxoDesign
//

import SwiftUI

/// Grouped container used for rows and settings blocks.
public struct VoxoCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(.horizontal, VoxoSpacing.m)
            .background(VoxoColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.medium, style: .continuous))
    }
}

public struct VoxoSectionHeader: View {
    private let title: String

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(VoxoFont.caption)
            .textCase(.uppercase)
            .foregroundStyle(VoxoColor.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Shown when a list has nothing in it.
public struct VoxoEmptyState: View {
    private let icon: String
    private let title: String
    private let message: String

    public init(icon: String, title: String, message: String) {
        self.icon = icon
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: VoxoSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(VoxoColor.textTertiary)

            Text(title)
                .font(VoxoFont.headline)
                .foregroundStyle(VoxoColor.textPrimary)

            Text(message)
                .font(VoxoFont.callout)
                .foregroundStyle(VoxoColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(VoxoSpacing.l)
    }
}
