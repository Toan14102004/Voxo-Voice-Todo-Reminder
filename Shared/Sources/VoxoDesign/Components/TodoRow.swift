//
//  TodoRow.swift
//  VoxoDesign
//
//  DS / Components: "Task row" 342×64, radius 14. Two states: open and done.
//

import SwiftUI
import VoxoShared

public struct TodoRow: View {
    private let todo: TodoDTO
    /// "Hôm qua · Cá nhân" — due date and list, already formatted by the caller.
    private let meta: Text?
    private let isOverdue: Bool
    private let onToggle: (() -> Void)?

    public init(
        todo: TodoDTO,
        meta: Text? = nil,
        isOverdue: Bool = false,
        onToggle: (() -> Void)? = nil
    ) {
        self.todo = todo
        self.meta = meta
        self.isOverdue = isOverdue
        self.onToggle = onToggle
    }

    public var body: some View {
        HStack(spacing: VoxoSpacing.m) {
            checkbox

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: todo.title)
                    .font(VoxoFont.bodyEmphasis)
                    .foregroundStyle(todo.isDone ? VoxoColor.textMuted : VoxoColor.textPrimary)
                    // DS / Rules: a checked task is struck through and faded, not just recoloured.
                    .strikethrough(todo.isDone, color: VoxoColor.textMuted)
                    .lineLimit(2)

                if let meta {
                    meta
                        .font(VoxoFont.overline)
                        .foregroundStyle(isOverdue ? VoxoColor.danger : VoxoColor.textSecondary)
                }
            }

            Spacer(minLength: VoxoSpacing.s)

            // The design marks priority on a row with a dot, not a chip; the chip appears on the
            // detail screen where there is room for the word.
            priorityDot
        }
        .padding(.horizontal, VoxoSpacing.l)
        .frame(minHeight: 64)
        .background(VoxoColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.taskRow, style: .continuous))
        .opacity(todo.isDone ? 0.65 : 1)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var priorityDot: some View {
        if todo.priority != .none, !todo.isDone {
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .accessibilityLabel(priorityLabel)
        }
    }

    private var dotColor: Color {
        switch todo.priority {
        case .high: VoxoColor.priorityHigh
        case .medium: VoxoColor.priorityMedium
        case .low: VoxoColor.priorityLow
        case .none: .clear
        }
    }

    /// The dot is colour-only on screen, so the level is spelled out for VoiceOver (DS / Rules).
    private var priorityLabel: LocalizedStringKey {
        switch todo.priority {
        case .high: "High priority"
        case .medium: "Medium priority"
        case .low: "Low priority"
        case .none: ""
        }
    }

    @ViewBuilder
    private var checkbox: some View {
        let shape = Image(systemName: todo.isDone ? VoxoIcon.checked : VoxoIcon.unchecked)
            .font(.system(size: 22, weight: .regular))
            .foregroundStyle(todo.isDone ? VoxoColor.success : VoxoColor.textMuted)
            .frame(minWidth: 28, minHeight: 28)

        if let onToggle {
            Button(action: onToggle) { shape }
                .buttonStyle(.plain)
                .accessibilityLabel(todo.isDone ? "Mark as not done" : "Mark as done")
        } else {
            shape
        }
    }
}
