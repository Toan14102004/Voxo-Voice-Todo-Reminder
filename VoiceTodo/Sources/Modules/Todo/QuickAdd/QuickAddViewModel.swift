//
//  QuickAddViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI
import VoxoDesign
import VoxoShared

extension QuickAddView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var title = ""
        @Published var note = ""
        @Published var dueToday = true
        @Published var priority: TodoPriority = .none
        @Published var listId: UUID?
        @Published var repeatRule: RepeatRule?

        var trimmedTitle: String {
            title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var canSubmit: Bool { !trimmedTitle.isEmpty }

        /// The attribute chips under the fields. Each cycles its value; the design's pickers are
        /// not built yet.
        func chips(store: TodoStore) -> [VoxoQuickAddSheet.Chip] {
            [
                .init(icon: VoxoIcon.date, title: "Today", isSelected: dueToday) {
                    self.dueToday.toggle()
                },
                // Shows which level it landed on, not just "selected".
                .init(icon: VoxoIcon.priority, title: priority.chipTitle, isSelected: priority != .none) {
                    self.priority = self.priority.next
                },
                .init(icon: VoxoIcon.repeatRule, title: repeatRule.chipTitle, isSelected: repeatRule != nil) {
                    self.repeatRule = self.repeatRule.next
                }
            ]
        }

        func submit(into store: TodoStore) {
            guard canSubmit else { return }

            let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
            store.add(
                title: trimmedTitle,
                note: cleanNote.isEmpty ? nil : cleanNote,
                priority: priority,
                dueAt: dueToday ? Self.endOfToday() : nil,
                listId: listId,
                repeatRule: repeatRule
            )
        }

        private static func endOfToday() -> Date {
            let calendar = Calendar.current
            let startOfTomorrow = calendar.startOfDay(for: Date().addingTimeInterval(86_400))
            return startOfTomorrow.addingTimeInterval(-1)
        }
    }
}

extension TodoPriority {
    var chipTitle: LocalizedStringKey {
        switch self {
        case .none: "Priority"
        case .low: "Low priority"
        case .medium: "Medium priority"
        case .high: "High priority"
        }
    }
}

extension RepeatRule? {
    var chipTitle: LocalizedStringKey {
        switch self {
        case .none: "Repeat"
        case .daily: "Repeats daily"
        case .weekly: "Repeats weekly"
        }
    }
}

private extension TodoPriority {
    /// none → low → medium → high → none.
    var next: TodoPriority {
        switch self {
        case .none: .low
        case .low: .medium
        case .medium: .high
        case .high: .none
        }
    }
}

private extension RepeatRule? {
    var next: RepeatRule? {
        switch self {
        case .none: .daily
        case .daily: .weekly
        case .weekly: nil
        }
    }
}
