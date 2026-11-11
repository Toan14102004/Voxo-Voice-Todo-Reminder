//
//  IntervalLabel+Text.swift
//  VoiceTodo
//
//  `IntervalLabel` itself lives in VoxoDesign so the Watch can use it too. This resolved variant
//  stays here: `String.localizedString` is an iOS-target helper.
//

import SwiftUI
import VoxoDesign

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
