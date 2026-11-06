//
//  TodoListViewCoordinator.swift
//  VoiceTodo
//

import Foundation

extension TodoListView {
    struct Coordinator: BaseCoordinator {
        enum Navigation: BaseNavigation {
            case settings
        }

        /// Routes carry the todo's id, not the whole `TodoDTO`: a route has to stay `Hashable` and
        /// `Codable`, and the destination should read the current record rather than a snapshot
        /// taken when the route was pushed.
        enum FullScreen: BaseFullScreen {
            case addTodo
            case editTodo(UUID)
        }
    }
}
