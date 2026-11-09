//
//  ListsViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoShared

extension ListsView {
    /// The saved views in "Lọc thông minh" — computed from existing data, so they need no entity.
    enum SmartFilter: String, Identifiable {
        case highPriority
        case nextSevenDays
        case completed

        var id: String { rawValue }

        var title: LocalizedStringKey {
            switch self {
            case .highPriority: "High priority"
            case .nextSevenDays: "Next 7 days"
            case .completed: "Completed"
            }
        }

        func matches(_ todo: TodoDTO, now: Date) -> Bool {
            switch self {
            case .highPriority:
                return !todo.isDone && todo.priority == .high
            case .nextSevenDays:
                guard !todo.isDone, let dueAt = todo.dueAt else { return false }
                return dueAt >= now && dueAt <= now.addingTimeInterval(7 * 86_400)
            case .completed:
                return todo.isDone
            }
        }
    }

    @MainActor
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()
        @Published var isCreating = false

        @Navigation private var navigation

        private let now: () -> Date

        init(now: @escaping () -> Date = Date.init) {
            self.now = now
        }

        func highPriorityCount(_ store: TodoStore) -> Int {
            store.active.filter { SmartFilter.highPriority.matches($0, now: now()) }.count
        }

        func nextSevenDaysCount(_ store: TodoStore) -> Int {
            store.active.filter { SmartFilter.nextSevenDays.matches($0, now: now()) }.count
        }

        func open(_ list: TodoListDTO) {
            navigation.push(Coordinator.Navigation.list(list.id))
        }

        func open(_ filter: SmartFilter) {
            navigation.push(Coordinator.Navigation.filter(filter.rawValue))
        }
    }
}

extension ListsView {
    struct Coordinator: BaseCoordinator {
        enum Navigation: BaseNavigation {
            case list(UUID)
            /// The filter's raw value: routes must be Codable.
            case filter(String)
        }
    }
}
