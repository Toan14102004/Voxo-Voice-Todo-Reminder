//
//  IntervalLabel.swift
//  VoiceTodo
//

import SwiftUI

/// Reminder-cadence text as a `LocalizedStringKey`: the number is interpolated into the key and
/// SwiftUI resolves it at render time. Resolving the translation here instead would freeze each
/// row into the language that was active when it was first built.
enum IntervalLabel {
    /// "Every hour" · "Every 3 hours · custom" · "Every 45 minutes".
    static func key(minutes: Int, isCustom: Bool) -> LocalizedStringKey {
        switch minutes {
        case 60:
            return isCustom ? "Every hour · custom" : "Every hour"
        case 1440:
            return isCustom ? "Every day · custom" : "Every day"
        case let value where value % 60 == 0:
            let hours = value / 60
            return isCustom ? "Every \(hours) hours · custom" : "Every \(hours) hours"
        default:
            return isCustom ? "Every \(minutes) minutes · custom" : "Every \(minutes) minutes"
        }
    }

    /// Same wording without the "custom" suffix, for pickers that list the choices.
    static func option(minutes: Int) -> LocalizedStringKey {
        key(minutes: minutes, isCustom: false)
    }
}

extension IntervalLabel {
    /// Resolved now, for callers that must build a longer line out of several pieces.
    static func text(minutes: Int, isCustom: Bool) -> String {
        let (format, value): (String, Int?) = switch minutes {
        case 60: (isCustom ? "Every hour · custom" : "Every hour", nil)
        case 1440: (isCustom ? "Every day · custom" : "Every day", nil)
        case let m where m % 60 == 0: (isCustom ? "Every %lld hours · custom" : "Every %lld hours", m / 60)
        default: (isCustom ? "Every %lld minutes · custom" : "Every %lld minutes", minutes)
        }

        let localized = format.localizedString
        guard let value else { return localized }
        return String(format: localized, value)
    }
}
