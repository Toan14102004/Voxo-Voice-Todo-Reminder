//
//  TodoRow.swift
//  VoxoDesign
//

import SwiftUI
import VoxoShared

/// One todo in a list, on either device.
///
/// Status is carried by the checkbox shape and by text, never by colour alone (PLAN.md §7).
public struct TodoRow: View {
    private let todo: TodoDTO
    private let subtitle: String?
    private let isOverdue: Bool
    private let onToggle: (() -> Void)?

    public init(todo: TodoDTO, subtitle: String? = nil, isOverdue: Bool = false, onToggle: (() -> Void)? = nil) {
        self.todo = todo
        self.subtitle = subtitle
        self.isOverdue = isOverdue
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(alignment: .top, spacing: VoxoSpacing.m) {
            if let onToggle {
                Button(action: onToggle) { checkbox }
                    .buttonStyle(.plain)
                    .accessibilityLabel(todo.isDone ? "Mark as not done" : "Mark as done")
            } else {
                checkbox
            }

            VStack(alignment: .leading, spacing: VoxoSpacing.xs) {
                Text(todo.title)
                    .font(VoxoFont.body)
                    .foregroundStyle(todo.isDone ? VoxoColor.textTertiary : VoxoColor.textPrimary)
                    .strikethrough(todo.isDone, color: VoxoColor.textTertiary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Label {
                        Text(subtitle)
                    } icon: {
                        // The icon repeats what the colour says, for anyone who cannot see it.
                        Image(systemName: isOverdue ? "exclamationmark.circle" : "bell")
                    }
                    .font(VoxoFont.caption)
                    .foregroundStyle(isOverdue ? VoxoColor.overdue : VoxoColor.textSecondary)
                    .labelStyle(.titleAndIcon)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, VoxoSpacing.s)
        .contentShape(Rectangle())
    }

    private var checkbox: some View {
        Image(systemName: todo.isDone ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(todo.isDone ? VoxoColor.done : VoxoColor.textTertiary)
            .frame(minWidth: 24, minHeight: 24)
    }
}
