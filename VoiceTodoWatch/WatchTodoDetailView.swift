//
//  WatchTodoDetailView.swift
//  VoiceTodoWatch
//

import SwiftUI
import VoxoDesign
import VoxoShared

/// PLAN.md §7: tap a todo to read it and edit its title.
///
/// Takes the id, not the record: a `TodoDTO` captured when the row was tapped is a snapshot, and
/// toggling done here would leave the screen showing the old state.
struct WatchTodoDetailView: View {
    let todoId: UUID
    @ObservedObject var store: WatchTodoStore

    @Environment(\.dismiss) private var dismiss
    @State private var title: String?

    var body: some View {
        ScrollView {
            if let todo = store.todo(id: todoId) {
                content(todo)
            } else {
                Text("This task is gone")
                    .font(VoxoFont.caption)
                    .foregroundStyle(VoxoColor.textSecondary)
            }
        }
        .navigationTitle("Task")
    }

    private func content(_ todo: TodoDTO) -> some View {
        VStack(alignment: .leading, spacing: VoxoSpacing.m) {
            TextField("Task", text: binding(todo))
                .font(VoxoFont.body)

            if let meta = meta(todo) {
                Text(verbatim: meta)
                    .font(VoxoFont.caption)
                    .foregroundStyle(VoxoColor.textSecondary)
            }

            Button(todo.isDone ? "Reopen" : "Done") {
                store.toggleDone(todo)
                dismiss()
            }
            .buttonStyle(VoxoPrimaryButtonStyle())

            if let saved = title, saved.trimmed != todo.title, !saved.trimmed.isEmpty {
                Button("Save") {
                    store.rename(todo, to: saved.trimmed)
                    title = nil
                }
                .buttonStyle(VoxoSecondaryButtonStyle())
            }
        }
        .padding(.horizontal, VoxoSpacing.screenMargin)
    }

    /// Edits live in `title` only while they differ; `nil` means "showing what is stored", so a
    /// change arriving from the phone is not overwritten by a stale local copy.
    private func binding(_ todo: TodoDTO) -> Binding<String> {
        Binding(
            get: { title ?? todo.title },
            set: { title = $0 }
        )
    }

    /// Everything the watch shows but cannot edit: the phone owns priority, due date and list.
    private func meta(_ todo: TodoDTO) -> String? {
        var parts: [String] = []
        if let dueAt = todo.dueAt {
            parts.append(dueAt.formatted(date: .omitted, time: .shortened))
        }
        if let list = store.list(id: todo.listId) {
            parts.append(list.name)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
