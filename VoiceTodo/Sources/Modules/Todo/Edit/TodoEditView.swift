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
    @Navigation private var navigation
    @StateObject private var viewModel = ViewModel()
    @FocusState private var titleFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    TextField("What needs doing?", text: $viewModel.title, axis: .vertical)
                        .font(VoxoFont.body)
                        .lineLimit(1...4)
                        .focused($titleFocused)
                        .submitLabel(.done)

                    if viewModel.isOverLimit {
                        Label(
                            "Only the first \(TodoDTO.maxTitleLength) characters are kept.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(VoxoFont.caption)
                        .foregroundStyle(VoxoColor.overdue)
                    }
                }

                Section {
                    Picker("Reminder", selection: $viewModel.intervalOverride) {
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
                    Button("Cancel") { navigation.goBack() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(viewModel.trimmedTitle, viewModel.intervalOverride)
                        navigation.goBack()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
            .onAppear { titleFocused = viewModel.load(mode) }
        }
    }
}
