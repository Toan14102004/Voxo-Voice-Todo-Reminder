//
//  TodoListViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoShared

extension TodoListView {
    @MainActor
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published var tab: Tab = .doing

        @Navigation private var navigation

        // MARK: - Routes

        func openSettings() {
            navigation.push(Coordinator.Navigation.settings)
        }

        func addTodo() {
            navigation.presentSheet(Coordinator.FullScreen.addTodo)
        }

        func edit(_ todo: TodoDTO) {
            navigation.presentSheet(Coordinator.FullScreen.editTodo(todo.id))
        }

        /// Reminder cadence for unfinished todos, completion time for finished ones.
        func subtitle(for todo: TodoDTO, intervalMinutes: Int) -> String? {
            if todo.isDone {
                guard let completedAt = todo.completedAt else { return nil }
                return "Finished \(completedAt.formatted(date: .abbreviated, time: .shortened))"
            }

            let suffix = todo.intervalOverride > 0 ? " · custom" : ""
            return "Every \(intervalMinutes.intervalLabel)\(suffix)"
        }

        func apply(_ title: String, interval: Int32, to todo: TodoDTO, in store: TodoStore) {
            var updated = todo
            updated.title = title
            updated.intervalOverride = interval
            store.update(updated)
        }
    }
}
