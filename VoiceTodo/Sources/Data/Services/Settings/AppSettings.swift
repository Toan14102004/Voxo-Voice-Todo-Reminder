//
//  AppSettings.swift
//  VoiceTodo
//
//  The preferences on the Settings screen (design "VI / 8 Cài đặt"). Device-local: none of them
//  is synced to the Watch, unlike the shared reminder cycle, which lives on `TodoStore`.
//

import Foundation
import SwiftUI

/// The two languages Tidy ships (PLAN.md §0). `LanguageManager.supportedCodes` still lists the
/// template's seventeen; this is the pair the UI actually offers.
enum AppLanguage: String, CaseIterable, Identifiable {
    case vietnamese = "vi"
    case english = "en"

    var id: String { rawValue }

    /// Written in the language itself, so it is readable whichever one you speak.
    var nativeName: String {
        switch self {
        case .vietnamese: "Tiếng Việt"
        case .english: "English"
        }
    }

    static func current() -> AppLanguage {
        AppLanguage(rawValue: LanguageManager.shared.currentLanguageCode) ?? .english
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .system: "Match system"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    /// `nil` hands the choice back to iOS.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum WeekStart: String, CaseIterable, Identifiable {
    case monday
    case sunday

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .monday: "Monday"
        case .sunday: "Sunday"
        }
    }

    /// `Calendar.firstWeekday` is 1-based from Sunday.
    var firstWeekday: Int {
        switch self {
        case .monday: 2
        case .sunday: 1
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var appearance: AppAppearance {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    @Published var weekStart: WeekStart {
        didSet { defaults.set(weekStart.rawValue, forKey: Key.weekStart) }
    }

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Key.sound) }
    }

    private enum Key {
        static let appearance = "settings.appearance"
        static let weekStart = "settings.weekStart"
        static let sound = "settings.soundEnabled"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = AppAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
        weekStart = WeekStart(rawValue: defaults.string(forKey: Key.weekStart) ?? "") ?? .monday
        // Absent means "never set", and a reminder with no sound is easy to miss.
        soundEnabled = defaults.object(forKey: Key.sound) as? Bool ?? true
    }

    /// A calendar honouring the week-start preference, for the Calendar and Stats screens.
    var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStart.firstWeekday
        return calendar
    }

    /// "Tidy 1.0 (12)" for the footer.
    var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
