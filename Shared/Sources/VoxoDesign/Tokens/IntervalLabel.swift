//
//  IntervalLabel.swift
//  VoxoDesign
//

import SwiftUI

/// Reminder-cadence text as a `LocalizedStringKey`: the number is interpolated into the key and
/// SwiftUI resolves it at render time. Resolving the translation here instead would freeze each
/// row into the language that was active when it was first built.
public enum IntervalLabel {
    /// "Every hour" · "Every 3 hours · custom" · "Every 45 minutes".
    public static func key(minutes: Int, isCustom: Bool) -> LocalizedStringKey {
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
    public static func option(minutes: Int) -> LocalizedStringKey {
        key(minutes: minutes, isCustom: false)
    }
}
