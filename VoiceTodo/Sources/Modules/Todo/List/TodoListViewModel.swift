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

        /// The row's meta line: when it was finished, or how often it nags.
        ///
        /// Resolved to a `String` here because it will later join user data (list name, due date)
        /// in one line. Each localized fragment is looked up explicitly rather than interpolated
        /// into a key, so nothing is left in the build language.
        func meta(for todo: TodoDTO, intervalMinutes: Int) -> String? {
            if todo.isDone {
                guard let completedAt = todo.completedAt else { return nil }
                let format = "Finished %@".localizedString
                return String(format: format, completedAt.formatted(date: .abbreviated, time: .shortened))
            }

            return IntervalLabel.text(minutes: intervalMinutes, isCustom: todo.intervalOverride > 0)
        }

        func apply(_ title: String, interval: Int32, to todo: TodoDTO, in store: TodoStore) {
            var updated = todo
            updated.title = title
            updated.intervalOverride = interval
            store.update(updated)
        }
    }
}
