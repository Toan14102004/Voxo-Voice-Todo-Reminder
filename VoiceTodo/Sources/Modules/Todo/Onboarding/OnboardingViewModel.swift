//
//  OnboardingViewModel.swift
//  VoiceTodo
//

import Foundation
import SwiftUI

extension OnboardingView {
    @MainActor
    final class ViewModel: ObservableObject {
        @Published var selected: AppLanguage

        init() {
            // Preselect whatever the device already uses, so the common case is one tap.
            selected = LanguageManager.resolve(
                Locale.current.language.languageCode?.identifier ?? "en"
            ) == "vi" ? .vietnamese : .english
        }

        func apply() {
            LanguageManager.shared.changeLanguage(selected.rawValue)
            KeychainStorage.shared.currentLanguageCode = selected.rawValue
        }
    }
}

/// Whether onboarding has run. Outside the ViewModel so the root can read it before building.
enum OnboardingState {
    private static let key = "tidy.onboarding.completed"

    static var isComplete: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
