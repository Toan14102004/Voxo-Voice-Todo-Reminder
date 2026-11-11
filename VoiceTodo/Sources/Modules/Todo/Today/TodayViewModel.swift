//
//  TodayViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoDesign
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

        /// "Thứ Ba, 10 tháng 11" — in the app's language, per DS / Rules.
        ///
        /// The locale is a parameter, read from the view's environment. Taken from
        /// `LanguageManager` here instead, this line rendered in whatever language was active
        /// when the row was first built: `Text(verbatim:)` does not depend on `\.locale`, so
        /// switching language never invalidated the view.
        func dateLine(_ locale: Locale) -> String {
            now().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(locale))
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
        ///
        /// A `Text`, not a `String`: the line mixes user data with translated words, and resolving
        /// those words here would freeze the row into one language.
        func meta(for todo: TodoDTO, store: TodoStore, locale: Locale) -> Text? {
            var parts: [Text] = []

            if todo.isDone, let completedAt = todo.completedAt {
                parts.append(Text("Finished \(time(completedAt, locale))"))
            } else if let dueAt = todo.dueAt {
                parts.append(Text(verbatim: time(dueAt, locale)))
            }

            if let listId = todo.listId, let list = store.list(id: listId) {
                parts.append(Text(verbatim: list.name))
            }

            if let rule = todo.repeatRule {
                let key: LocalizedStringKey = rule == .daily ? "Repeats daily" : "Repeats weekly"
                parts.append(Text(key))
            }

            if parts.isEmpty {
                parts.append(Text(IntervalLabel.key(minutes: store.interval(for: todo),
                                                    isCustom: todo.intervalOverride > 0)))
            }

            guard let first = parts.first else { return nil }
            return parts.dropFirst().reduce(first) { $0 + Text(verbatim: " · ") + $1 }
        }

        private func time(_ date: Date, _ locale: Locale) -> String {
            date.formatted(.dateTime.hour().minute().locale(locale))
        }

        // MARK: - Routes

        func addTodo() {
            navigation.presentSheet(Coordinator.FullScreen.quickAdd)
        }

        func open(_ todo: TodoDTO) {
            navigation.push(Coordinator.Navigation.detail(todo.id))
        }

        func openSettings() {
            navigation.push(Coordinator.Navigation.settings)
        }
    }
}
