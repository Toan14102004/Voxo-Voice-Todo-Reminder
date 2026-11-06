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
    @StateObject private var viewModel = ViewModel()

    var body: some View {
        VStack(spacing: 0) {
            picker
            list
        }
        .voxoScreen()
        .navigationTitle("Voxo")
        .toolbar { toolbar }
    }

    // MARK: - Pieces

    private var picker: some View {
        Picker("View", selection: $viewModel.tab) {
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
        let todos = viewModel.tab == .doing ? store.active : store.completed

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
        .onTapGesture { viewModel.edit(todo) }
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
            switch viewModel.tab {
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
                viewModel.openSettings()
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                viewModel.addTodo()
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add task")
        }
    }

    private func subtitle(for todo: TodoDTO) -> String? {
        viewModel.subtitle(for: todo, intervalMinutes: store.interval(for: todo))
    }
}
