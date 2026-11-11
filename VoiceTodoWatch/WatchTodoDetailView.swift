//
//  WatchTodoDetailView.swift
//  VoiceTodoWatch
//
//  Not in the design — the board has no watch detail frame. Built from PLAN.md §7, then widened
//  on 11/11/2026: once `TaskParser` started setting priority, due date and list from speech, the
//  watch had to be able to correct them. Making the user reach for the phone to fix a guess the
//  watch made is friction the parser itself created.
//
//  Still read-only here: the reminder cadence. PLAN.md §1 makes the phone the only scheduler, so
//  a control here would imply the watch drives something it does not.
//
//  `Menu` does not exist on watchOS. Each editable field is a `Picker` in `.navigationLink`
//  style, which pushes a full-screen list — the right size for a wrist.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct WatchTodoDetailView: View {
    let todoId: UUID
    @ObservedObject var store: WatchTodoStore
    @EnvironmentObject private var session: WatchSessionManager

    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var locale
    @State private var title: String?

    var body: some View {
        Group {
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
        List {
            TextField("Task", text: binding(todo))
                .font(VoxoFont.body)

            if let saved = title, saved.trimmed != todo.title, !saved.trimmed.isEmpty {
                Button("Save") {
                    store.rename(todo, to: saved.trimmed)
                    title = nil
                }
            }

            NavigationLink {
                WatchChoiceView(title: "Priority",
                                choices: WatchChoices.priority(),
                                selection: priorityBinding(todo))
            } label: {
                LabeledContent("Priority") { Text(WatchChoices.key(todo.priority)) }
            }

            NavigationLink {
                WatchDueDateView(current: todo.dueAt) { picked in
                    write(todo) { $0.dueAt = picked }
                }
            } label: {
                LabeledContent("Due") { dueText(todo) }
            }

            NavigationLink {
                WatchChoiceView(title: "List",
                                choices: WatchChoices.lists(store.lists),
                                selection: listBinding(todo))
            } label: {
                LabeledContent("List") { listText(todo) }
            }

            NavigationLink {
                WatchChoiceView(title: "Repeat",
                                choices: WatchChoices.repeatRules(),
                                selection: repeatBinding(todo))
            } label: {
                LabeledContent("Repeat") { Text(WatchChoices.key(todo.repeatRule)) }
            }

            // Read-only: the phone schedules every reminder (PLAN.md §1). The todo's own cycle
            // wins over the shared one — showing the shared figure unconditionally reported the
            // wrong number for any task with an override.
            LabeledContent("Reminder") {
                Text(IntervalLabel.key(minutes: effectiveInterval(todo),
                                       isCustom: todo.intervalOverride > 0))
            }

            Button(todo.isDone ? "Reopen" : "Done") {
                store.toggleDone(todo)
                dismiss()
            }
            .buttonStyle(VoxoPrimaryButtonStyle())
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Bindings
    //
    // Each writes straight through to the store; the outbox carries the whole record, so an edit
    // made here reaches the phone the same way a rename does.

    private func priorityBinding(_ todo: TodoDTO) -> Binding<TodoPriority> {
        Binding(get: { todo.priority }, set: { level in write(todo) { $0.priority = level } })
    }

    private func listBinding(_ todo: TodoDTO) -> Binding<UUID?> {
        Binding(get: { todo.listId }, set: { id in write(todo) { $0.listId = id } })
    }

    private func repeatBinding(_ todo: TodoDTO) -> Binding<RepeatRule?> {
        Binding(get: { todo.repeatRule }, set: { rule in write(todo) { $0.repeatRule = rule } })
    }

    private func write(_ todo: TodoDTO, _ change: (inout TodoDTO) -> Void) {
        var edited = todo
        change(&edited)
        store.update(edited)
    }

    // MARK: - Values


    /// PLAN.md §5 rule 2, same resolution the phone uses.
    private func effectiveInterval(_ todo: TodoDTO) -> Int {
        todo.intervalOverride > 0 ? Int(todo.intervalOverride) : session.globalIntervalMinutes
    }

    private func listText(_ todo: TodoDTO) -> Text {
        guard let list = store.list(id: todo.listId) else { return Text("None") }
        return Text(verbatim: list.name)
    }

    private func dueText(_ todo: TodoDTO) -> Text {
        guard let dueAt = todo.dueAt else { return Text("None") }
        let time = dueAt.formatted(
            .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(locale)
        )
        if Calendar.current.isDateInToday(dueAt) { return Text("Today \(time)") }
        if Calendar.current.isDateInTomorrow(dueAt) { return Text("Tomorrow \(time)") }
        let day = dueAt.formatted(.dateTime.day().month(.defaultDigits).locale(locale))
        return Text(verbatim: "\(day) \(time)")
    }

    /// Edits live in `title` only while they differ; `nil` means "showing what is stored", so a
    /// change arriving from the phone is not overwritten by a stale local copy.
    private func binding(_ todo: TodoDTO) -> Binding<String> {
        Binding(
            get: { title ?? todo.title },
            set: { title = $0 }
        )
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
