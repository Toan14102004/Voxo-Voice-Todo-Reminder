//
//  TodayViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoShared

extension TodayView {
    @MainActor
    final class ViewModel: BaseViewModel {
        @Published var coordinator = Coordinator()

        @Navigation private var navigation

        private let now: () -> Date

        init(now: @escaping () -> Date = Date.init) {
            self.now = now
        }

        // MARK: - Header

        /// "Thứ Bảy, 7 tháng 11" — formatted in the app's language, per DS / Rules.
        var dateLine: String {
            now().formatted(
                .dateTime.weekday(.wide).day().month(.wide)
                    .locale(Locale(identifier: LanguageManager.shared.currentLanguageCode))
            )
        }

        var greeting: LocalizedStringKey {
            switch Calendar.current.component(.hour, from: now()) {
            case 5..<12: "Good morning"
            case 12..<18: "Good afternoon"
            default: "Good evening"
            }
        }

        /// Avatar letter. No account system yet, so it is a fixed placeholder.
        var initial: String { "T" }

        // MARK: - Content

        func items(in section: TodaySection, store: TodoStore) -> [TodoDTO] {
            TodaySection.group(store.active, completed: store.completed, now: now())[section] ?? []
        }

        func totalToday(_ store: TodoStore) -> Int {
            store.active.count + store.completed.count
        }

        /// "07:00 · Sức khỏe · Lặp lại hằng ngày" — time, list, repeat, joined with "·".
        func meta(for todo: TodoDTO, store: TodoStore) -> String? {
            var parts: [String] = []

            if todo.isDone, let completedAt = todo.completedAt {
                parts.append(String(format: "Finished %@".localizedString,
                                    completedAt.formatted(date: .omitted, time: .shortened)))
            } else if let dueAt = todo.dueAt {
                parts.append(dueAt.formatted(date: .omitted, time: .shortened))
            }

            if let listId = todo.listId, let list = store.list(id: listId) {
                parts.append(list.name)
            }

            if let rule = todo.repeatRule {
                parts.append(rule == .daily ? "Repeats daily".localizedString
                                            : "Repeats weekly".localizedString)
            }

            if parts.isEmpty {
                parts.append(IntervalLabel.text(minutes: store.interval(for: todo),
                                                isCustom: todo.intervalOverride > 0))
            }

            return parts.joined(separator: " · ")
        }

        // MARK: - Routes

        func addTodo() {
            navigation.presentSheet(Coordinator.FullScreen.quickAdd)
        }

        func open(_ todo: TodoDTO) {
            navigation.push(Coordinator.Navigation.detail(todo.id))
        }
    }
}
