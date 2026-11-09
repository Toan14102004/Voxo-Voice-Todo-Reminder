//
//  ListDetailView.swift
//  VoiceTodo
//
//  The tasks inside one list, or inside one smart filter.
//

import SwiftUI
import VoxoDesign
import VoxoShared

struct ListDetailView: View {
    enum Source {
        case list(UUID)
        case filter(ListsView.SmartFilter)
    }

    let source: Source

    @EnvironmentObject private var store: TodoStore
    @Navigation private var navigation
    @State private var confirmDeleteList = false

    var body: some View {
        Group {
            if todos.isEmpty {
                VoxoEmptyState(icon: VoxoIcon.Tab.lists, title: "Nothing here",
                               message: "Tasks filed here will show up in this list.")
                    .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(todos) { todo in
                        TodoRow(todo: todo, meta: nil, onToggle: { store.toggleDone(todo) })
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(
                                top: VoxoSpacing.xs, leading: VoxoSpacing.screenMargin,
                                bottom: VoxoSpacing.xs, trailing: VoxoSpacing.screenMargin
                            ))
                            .onTapGesture { navigation.push(TodayView.Coordinator.Navigation.detail(todo.id)) }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(VoxoColor.background)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case let .list(id) = source, let list = store.list(id: id) {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) { confirmDeleteList = true } label: {
                            Label("Delete list", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(VoxoColor.textPrimary)
                    }
                    .accessibilityLabel("More actions")
                    .confirmationDialog(
                        "Delete this list?",
                        isPresented: $confirmDeleteList,
                        titleVisibility: .visible
                    ) {
                        Button("Delete", role: .destructive) {
                            store.deleteList(list)
                            navigation.goBack()
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        // PLAN.md §4: the work survives, only the grouping goes.
                        Text("Tasks in this list are kept; they just stop belonging to a list.")
                    }
                }
            }
        }
    }

    private var todos: [TodoDTO] {
        switch source {
        case let .list(id):
            return store.active.filter { $0.listId == id }
        case let .filter(filter):
            let now = Date()
            let pool = filter == .completed ? store.completed : store.active
            return pool.filter { filter.matches($0, now: now) }
        }
    }

    private var title: String {
        switch source {
        case let .list(id):
            return store.list(id: id)?.name ?? String(localized: "Lists")
        case let .filter(filter):
            return filter.titleText
        }
    }
}

extension ListsView.SmartFilter {
    var titleText: String {
        switch self {
        case .highPriority: "High priority".localizedString
        case .nextSevenDays: "Next 7 days".localizedString
        case .completed: "Completed".localizedString
        }
    }
}
