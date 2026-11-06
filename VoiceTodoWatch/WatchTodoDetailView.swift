//
//  WatchTodoDetailView.swift
//  VoiceTodoWatch
//

import SwiftUI
import VoxoDesign
import VoxoShared

/// PLAN.md §7: tap a todo to view and edit its title.
struct WatchTodoDetailView: View {
    let todo: TodoDTO
    let store: WatchTodoStore

    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    init(todo: TodoDTO, store: WatchTodoStore) {
        self.todo = todo
        self.store = store
        _title = State(initialValue: todo.title)
    }

    private var trimmed: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: VoxoSpacing.m) {
                TextField("Task", text: $title)
                    .font(VoxoFont.body)

                Button("Save") {
                    store.rename(todo, to: trimmed)
                    dismiss()
                }
                .buttonStyle(VoxoPrimaryButtonStyle())
                .disabled(trimmed.isEmpty || trimmed == todo.title)

                Button("Done") {
                    store.complete(todo)
                    dismiss()
                }
                .buttonStyle(VoxoSecondaryButtonStyle())
            }
            .padding(.horizontal, VoxoSpacing.screenMargin)
        }
        .navigationTitle("Task")
    }
}
