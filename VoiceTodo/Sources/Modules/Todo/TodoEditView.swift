//
//  TodoEditView.swift
//  VoiceTodo
//
//  PLAN.md §7: edit the title and the per-todo cycle ("Use shared" or one of the allowed values).
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct TodoEditView: View {
    enum Mode {
        case create
        case edit(TodoDTO)

        var title: String {
            switch self {
            case .create: "New task"
            case .edit: "Edit task"
            }
        }
    }

    let mode: Mode
    let onSave: (String, Int32) -> Void

    @EnvironmentObject private var store: TodoStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var titleFocused: Bool

    @State private var title: String = ""
    /// Zero means "use the shared interval" (PLAN.md §4).
    @State private var intervalOverride: Int32 = 0

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs doing?", text: $title, axis: .vertical)
                        .font(VoxoFont.body)
                        .lineLimit(1...4)
                        .focused($titleFocused)
                        .submitLabel(.done)

                    if trimmedTitle.count > TodoDTO.maxTitleLength {
                        Label(
                            "Only the first \(TodoDTO.maxTitleLength) characters are kept.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(VoxoFont.caption)
                        .foregroundStyle(VoxoColor.overdue)
                    }
                }

                Section {
                    Picker("Reminder", selection: $intervalOverride) {
                        Text("Use shared (\(store.globalIntervalMinutes.intervalLabel))").tag(Int32(0))
                        ForEach(SyncSettings.allowedIntervals, id: \.self) { minutes in
                            Text("Every \(minutes.intervalLabel)").tag(Int32(minutes))
                        }
                    }
                } header: {
                    Text("Cycle")
                } footer: {
                    Text("Reminders repeat until you mark the task done or delete it.")
                        .font(VoxoFont.caption)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(trimmedTitle, intervalOverride)
                        dismiss()
                    }
                    .disabled(trimmedTitle.isEmpty)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        if case let .edit(todo) = mode {
            title = todo.title
            intervalOverride = todo.intervalOverride
        } else {
            titleFocused = true
        }
    }
}
