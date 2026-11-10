//
//  WatchTodoListView.swift
//  VoiceTodoWatch
//
//  Design: frame "Watch / Apple / 2 Hôm nay".
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct WatchTodoListView: View {
    @StateObject private var store: WatchTodoStore
    @EnvironmentObject private var session: WatchSessionManager
    @State private var isAdding = false

    init(store: WatchTodoStore) {
        _store = StateObject(wrappedValue: store)
    }

    var body: some View {
        NavigationStack {
            List {
                VoxoWatchAddButton(title: "Speak a task") { isAdding = true }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                ForEach(store.active) { todo in
                    row(todo)
                }

                if store.active.isEmpty {
                    Text("Nothing left for today")
                        .font(VoxoFont.caption)
                        .foregroundStyle(VoxoColor.textSecondary)
                        .listRowBackground(Color.clear)
                }

                ForEach(store.doneToday) { todo in
                    row(todo)
                }

                syncStatus
            }
            .listStyle(.plain)
            .navigationTitle(Text("Today · \(store.active.count)"))
            .sheet(isPresented: $isAdding) {
                WatchAddTodoView { title in store.add(title: title) }
            }
        }
        .tint(VoxoColor.Watch.accent)
    }

    private func row(_ todo: TodoDTO) -> some View {
        NavigationLink {
            WatchTodoDetailView(todoId: todo.id, store: store)
        } label: {
            VoxoWatchTaskRow(
                title: todo.title,
                subtitle: subtitle(todo),
                tint: tint(todo),
                isDone: todo.isDone
            ) {
                store.toggleDone(todo)
            }
            .accessibilityValue(accessibilityValue(todo))
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing) {
            Button {
                store.toggleDone(todo)
            } label: {
                Label(todo.isDone ? "Reopen" : "Done",
                      systemImage: todo.isDone ? "arrow.uturn.backward" : VoxoIcon.check)
            }
            .tint(todo.isDone ? VoxoColor.textSecondary : VoxoColor.success)
        }
    }

    /// "10:00 · Công việc" while open, "Xong lúc 07:40" once finished — the design swaps the
    /// whole line rather than appending to it.
    ///
    /// A `Text`, not a `String`: the finished line is a translated key with a time interpolated
    /// into it, which has to stay a key so SwiftUI resolves it at render time.
    private func subtitle(_ todo: TodoDTO) -> Text? {
        if todo.isDone {
            guard let completedAt = todo.completedAt else { return nil }
            return Text("Finished at \(time(completedAt))")
        }

        var parts: [String] = []
        if let dueAt = todo.dueAt { parts.append(time(dueAt)) }
        if let list = store.list(id: todo.listId) { parts.append(list.name) }
        return parts.isEmpty ? nil : Text(verbatim: parts.joined(separator: " · "))
    }

    /// 24-hour, as on the phone's Calendar tab.
    private func time(_ date: Date) -> String {
        date.formatted(
            .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).locale(session.locale)
        )
    }

    /// The ring takes the priority colour; a task without one takes the list's, and the brand
    /// colour when it has neither.
    private func tint(_ todo: TodoDTO) -> Color {
        switch todo.priority {
        case .high: VoxoColor.priorityHigh
        case .medium: VoxoColor.priorityMedium
        case .low: VoxoColor.priorityLow
        case .none:
            store.list(id: todo.listId).map { Color(hexString: $0.colorHex) } ?? VoxoColor.Watch.accent
        }
    }

    /// The ring is colour-only, so the state it carries is spelled out for VoiceOver.
    private func accessibilityValue(_ todo: TodoDTO) -> Text {
        if todo.isDone { return Text("Done") }
        return switch todo.priority {
        case .high: Text("High priority")
        case .medium: Text("Medium priority")
        case .low: Text("Low priority")
        case .none: Text("No priority")
        }
    }

    @ViewBuilder
    private var syncStatus: some View {
        // Only shown when something is actually waiting, so a healthy state stays quiet.
        if session.pendingOpCount > 0 {
            Label("Waiting to sync: \(session.pendingOpCount)", systemImage: "arrow.triangle.2.circlepath")
                .font(VoxoFont.caption)
                .foregroundStyle(VoxoColor.textSecondary)
                .listRowBackground(Color.clear)
        }
    }
}
