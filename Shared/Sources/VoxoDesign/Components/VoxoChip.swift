//
//  VoxoChip.swift
//  VoxoDesign
//
//  DS / Components: "Chip" 93×35, "Chip selected" 111×35, "Chip priority" 102×23.
//

import SwiftUI
import VoxoShared

/// Pill with an optional leading icon. Selected chips invert to the brand colour.
public struct VoxoChip: View {
    private let icon: String?
    private let title: LocalizedStringKey
    private let isSelected: Bool
    private let action: (() -> Void)?

    public init(
        icon: String? = nil,
        title: LocalizedStringKey,
        isSelected: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        if let action {
            Button(action: action) { label }.buttonStyle(.plain)
        } else {
            label
        }
    }

    private var label: some View {
        HStack(spacing: VoxoSpacing.xs + 2) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
            }
            Text(title)
                .font(isSelected ? VoxoFont.headline : VoxoFont.bodyEmphasis)
        }
        .foregroundStyle(isSelected ? VoxoColor.textOnAccent : VoxoColor.textSecondary)
        .padding(.horizontal, VoxoSpacing.m)
        .frame(height: 35)
        .background(isSelected ? VoxoColor.primary : VoxoColor.surface)
        .clipShape(Capsule())
        .overlay {
            if !isSelected {
                Capsule().strokeBorder(VoxoColor.border, lineWidth: 1)
            }
        }
    }
}

/// "● Ưu tiên cao" — dot plus name, so the level is never carried by colour alone (PLAN.md §7).
public struct VoxoPriorityChip: View {
    private let priority: TodoPriority

    public init(_ priority: TodoPriority) {
        self.priority = priority
    }

    public var body: some View {
        if priority != .none {
            HStack(spacing: VoxoSpacing.xs) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(name)
                    .font(VoxoFont.overline)
            }
            .foregroundStyle(color)
            .padding(.horizontal, VoxoSpacing.s)
            .frame(height: 23)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.chipSmall, style: .continuous))
        }
    }

    private var color: Color {
        switch priority {
        case .high: VoxoColor.priorityHigh
        case .medium: VoxoColor.priorityMedium
        case .low: VoxoColor.priorityLow
        case .none: VoxoColor.textMuted
        }
    }

    private var name: LocalizedStringKey {
        switch priority {
        case .high: "High priority"
        case .medium: "Medium priority"
        case .low: "Low priority"
        case .none: ""
        }
    }
}
