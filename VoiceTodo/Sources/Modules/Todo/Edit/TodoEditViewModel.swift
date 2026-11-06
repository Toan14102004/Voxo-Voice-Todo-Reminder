//
//  TodoEditViewModel.swift
//  VoiceTodo
//

import Foundation
import VoxoShared

extension TodoEditView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var title: String = ""
        /// Zero means "use the shared interval" (PLAN.md §4).
        @Published var intervalOverride: Int32 = 0

        var trimmedTitle: String {
            title.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var canSave: Bool { !trimmedTitle.isEmpty }

        /// The repository truncates past the limit, so warn before the user loses text.
        var isOverLimit: Bool { trimmedTitle.count > TodoDTO.maxTitleLength }

        /// Returns true when the field should take focus, i.e. when creating.
        @discardableResult
        func load(_ mode: Mode) -> Bool {
            switch mode {
            case .create:
                return true
            case let .edit(todo):
                title = todo.title
                intervalOverride = todo.intervalOverride
                return false
            }
        }
    }
}
