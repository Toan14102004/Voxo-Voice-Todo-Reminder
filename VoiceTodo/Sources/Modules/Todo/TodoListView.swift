//
//  TodoListView.swift
//  VoiceTodo
//
//  PLAN.md §7: tab 1 "Doing" holds unfinished todos, tab 2 "Done" holds finished ones.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct TodoListView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case doing
        case done

        var id: String { rawValue }

        var title: String {
            switch self {
            case .doing: "Doing"
            case .done: "Done"
            }
        }
    }

    @EnvironmentObject private var store: TodoStore
    @State private var tab: Tab = .doing
    @State private var editing: TodoDTO?
    @State private var isAdding = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                picker
                list
            }
            .voxoScreen()
            .navigationTitle("Voxo")
            .toolbar { toolbar }
            .sheet(isPresented: $isAdding) {
                TodoEditView(mode: .create) { title, interval in
                    store.add(title: title, intervalOverride: interval)
                }
            }
            .sheet(item: $editing) { todo in
                TodoEditView(mode: .edit(todo)) { title, interval in
                    var updated = todo
                    updated.title = title
                    updated.intervalOverride = interval
                    store.update(updated)
                }
            }
            .sheet(isPresented: $showSettings) {
                VoxoSettingsView()
            }
        }
    }

    // MARK: - Pieces

    private var picker: some View {
        Picker("View", selection: $tab) {
            ForEach(Tab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, VoxoSpacing.screenMargin)
        .padding(.bottom, VoxoSpacing.s)
    }

    @ViewBuilder
    private var list: some View {
        let todos = tab == .doing ? store.active : store.completed

        if todos.isEmpty {
            Spacer()
            emptyState
            Spacer()
        } else {
            List {
                ForEach(todos) { todo in
                    row(for: todo)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func row(for todo: TodoDTO) -> some View {
        TodoRow(
            todo: todo,
            subtitle: subtitle(for: todo),
            onToggle: todo.isDone ? nil : { store.complete(todo) }
        )
        .listRowBackground(Color.clear)
        .listRowSeparatorTint(VoxoColor.separator)
        .contentShape(Rectangle())
        .onTapGesture { editing = todo }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.delete(todo)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            if !todo.isDone {
                Button {
                    store.complete(todo)
                } label: {
                    Label("Done", systemImage: "checkmark")
                }
                .tint(VoxoColor.done)
            }
        }
    }

    private var emptyState: some View {
        Group {
            switch tab {
            case .doing:
                VoxoEmptyState(
                    icon: "mic.circle",
                    title: "Nothing to do",
                    message: "Add a task here, or speak one into your Apple Watch."
                )
            case .done:
                VoxoEmptyState(
                    icon: "checkmark.circle",
                    title: "Nothing finished yet",
                    message: "Completed tasks land here and stop reminding you."
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isAdding = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add task")
        }
    }

    /// Reminder cadence for unfinished todos, completion time for finished ones.
    private func subtitle(for todo: TodoDTO) -> String? {
        if todo.isDone {
            guard let completedAt = todo.completedAt else { return nil }
            return "Finished \(completedAt.formatted(date: .abbreviated, time: .shortened))"
        }

        let minutes = store.interval(for: todo)
        let suffix = todo.intervalOverride > 0 ? " · custom" : ""
        return "Every \(minutes.intervalLabel)\(suffix)"
    }
}
