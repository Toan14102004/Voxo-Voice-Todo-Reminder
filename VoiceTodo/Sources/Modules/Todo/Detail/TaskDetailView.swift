//
//  TaskDetailView.swift
//  VoiceTodo
//
//  Design: frame "VI / 4 Chi tiết task".
//
//  The design's "VIỆC CON" (subtasks) card is left out: subtasks need an entity PLAN.md §4
//  does not have.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct TaskDetailView: View {
    /// The id, not the record: a `TodoDTO` captured when the route was pushed is a snapshot, and
    /// edits made here would not appear until the screen was reopened.
    let todoId: UUID
    /// Name of the screen we came from — the design labels the back button "‹ Hôm nay".
    var backTitle: LocalizedStringKey = "Today"

    @EnvironmentObject private var store: TodoStore
    @Navigation private var navigation
    @State private var confirmDelete = false

    var body: some View {
        Group {
            if let todo = store.todo(id: todoId) {
                content(todo)
            } else {
                missing
            }
        }
        .background(VoxoColor.background)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Content

    private func content(_ todo: TodoDTO) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoxoSpacing.xl) {
                titleBlock(todo)
                if let note = todo.note, !note.isEmpty { noteCard(note) }
                detailsBlock(todo)
                deleteButton
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
            .padding(.vertical, VoxoSpacing.l)
        }
        .toolbar { toolbar(todo) }
        .confirmationDialog("Delete this task?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.delete(todo)
                navigation.goBack()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var missing: some View {
        VoxoEmptyState(
            icon: "trash",
            title: "Task not found",
            message: "It may have been deleted on another device."
        )
        .frame(maxHeight: .infinity)
        .toolbar { backButton }
    }

    private func titleBlock(_ todo: TodoDTO) -> some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.m) {
            HStack(alignment: .top, spacing: VoxoSpacing.m) {
                Button {
                    // Stays on screen: unlike the list, there is nowhere to go back to that
                    // would show the result.
                    store.toggleDone(todo)
                } label: {
                    Image(systemName: todo.isDone ? VoxoIcon.checked : VoxoIcon.unchecked)
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(todo.isDone ? VoxoColor.success : tint(todo.priority))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(todo.isDone ? "Mark as not done" : "Mark as done")

                Text(verbatim: todo.title)
                    .font(VoxoFont.title)
                    .foregroundStyle(VoxoColor.textPrimary)
            }

            HStack(spacing: VoxoSpacing.s) {
                VoxoPriorityChip(todo.priority)
                if let listId = todo.listId, let list = store.list(id: listId) {
                    VoxoChip(icon: VoxoIcon.list, title: LocalizedStringKey(list.name))
                }
            }
        }
    }

    private func noteCard(_ note: String) -> some View {
        Text(verbatim: note)
            .font(VoxoFont.body)
            .foregroundStyle(VoxoColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(VoxoSpacing.l)
            .background(VoxoColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: VoxoRadius.card, style: .continuous))
    }

    private func detailsBlock(_ todo: TodoDTO) -> some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.m) {
            VoxoSectionHeader("Details")

            VoxoDetailsCard {
                priorityRow(todo)
                separator
                VoxoDetailRow(icon: VoxoIcon.date, label: "Due", value: dueText(todo))
                separator
                VoxoDetailRow(icon: VoxoIcon.alarm, label: "Reminder", value: reminderText(todo))
                separator
                repeatRow(todo)
                separator
                listRow(todo)
            }
        }
    }

    private var separator: some View {
        Divider().padding(.leading, VoxoSpacing.xl + VoxoSpacing.l)
    }

    /// Priority is editable here: the only screen with room for all four levels.
    private func priorityRow(_ todo: TodoDTO) -> some View {
        Menu {
            ForEach(TodoPriority.pickerOrder, id: \.self) { level in
                Button { update(todo) { $0.priority = level } } label: {
                    if level == todo.priority {
                        Label(level.rowTitle, systemImage: VoxoIcon.check)
                    } else {
                        Text(level.rowTitle)
                    }
                }
            }
        } label: {
            VoxoDetailRow(icon: VoxoIcon.priority, label: "Priority",
                          value: todo.priority.rowText, showsChevron: true)
        }
    }

    private func repeatRow(_ todo: TodoDTO) -> some View {
        Menu {
            Button("None") { update(todo) { $0.repeatRule = nil } }
            Button("Repeats daily") { update(todo) { $0.repeatRule = .daily } }
            Button("Repeats weekly") { update(todo) { $0.repeatRule = .weekly } }
        } label: {
            VoxoDetailRow(icon: VoxoIcon.repeatRule, label: "Repeat",
                          value: repeatText(todo), showsChevron: true)
        }
    }

    private func listRow(_ todo: TodoDTO) -> some View {
        Menu {
            ForEach(store.lists) { list in
                Button { update(todo) { $0.listId = list.id } } label: {
                    if list.id == todo.listId {
                        Label(list.name, systemImage: VoxoIcon.check)
                    } else {
                        Label(list.name, systemImage: list.icon)
                    }
                }
            }

            if !store.lists.isEmpty { Divider() }

            Button("None") { update(todo) { $0.listId = nil } }
        } label: {
            VoxoDetailRow(icon: VoxoIcon.list, label: "List",
                          value: listText(todo), showsChevron: true)
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            confirmDelete = true
        } label: {
            Label("Delete this task", systemImage: "trash")
                .font(VoxoFont.headline)
                .foregroundStyle(VoxoColor.danger)
                .frame(maxWidth: .infinity, minHeight: VoxoHitTarget.minimum)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                navigation.goBack()
            } label: {
                HStack(spacing: 2) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                    Text(backTitle)
                        .font(VoxoFont.bodyEmphasis)
                }
                .foregroundStyle(VoxoColor.primary)
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbar(_ todo: TodoDTO) -> some ToolbarContent {
        backButton

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    store.toggleDone(todo)
                } label: {
                    Label(todo.isDone ? "Mark as not done" : "Mark as done",
                          systemImage: todo.isDone ? "arrow.uturn.backward" : VoxoIcon.check)
                }

                Button(role: .destructive) { confirmDelete = true } label: {
                    Label("Delete this task", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(VoxoColor.textPrimary)
            }
            .accessibilityLabel("More actions")
        }
    }

    // MARK: - Values

    private func update(_ todo: TodoDTO, _ change: (inout TodoDTO) -> Void) {
        var updated = todo
        change(&updated)
        store.update(updated)
    }

    private func tint(_ priority: TodoPriority) -> Color {
        switch priority {
        case .high: VoxoColor.priorityHigh
        case .medium: VoxoColor.priorityMedium
        case .low: VoxoColor.priorityLow
        case .none: VoxoColor.textMuted
        }
    }

    private func dueText(_ todo: TodoDTO) -> String {
        guard let dueAt = todo.dueAt else { return "None".localizedString }
        return dueAt.formatted(date: .abbreviated, time: .shortened)
    }

    private func reminderText(_ todo: TodoDTO) -> String {
        IntervalLabel.text(minutes: store.interval(for: todo), isCustom: todo.intervalOverride > 0)
    }

    private func repeatText(_ todo: TodoDTO) -> String {
        switch todo.repeatRule {
        case .daily: "Repeats daily".localizedString
        case .weekly: "Repeats weekly".localizedString
        case nil: "None".localizedString
        }
    }

    private func listText(_ todo: TodoDTO) -> String {
        guard let listId = todo.listId, let list = store.list(id: listId) else {
            return "None".localizedString
        }
        return list.name
    }
}

extension TodoPriority {
    /// One catalog key for both the picker label and the row value, so they cannot drift.
    var rowKey: String {
        switch self {
        case .none: "None"
        case .low: "Low priority"
        case .medium: "Medium priority"
        case .high: "High priority"
        }
    }

    var rowTitle: LocalizedStringKey { LocalizedStringKey(rowKey) }

    /// `VoxoDetailRow.value` takes a `String` because it usually carries user data.
    var rowText: String { rowKey.localizedString }
}
