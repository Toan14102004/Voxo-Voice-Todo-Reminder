//
//  String+Localization.swift
//  VoiceTodo
//
//  Created by Assistant on 9/23/25.
//

import Foundation
import SwiftUI

extension String {
    /// Converts a dynamic string (e.g. from a model) into a LocalizedStringKey
    /// so `Text(...)` re-localizes and updates when the app locale changes.
    var localizedKey: LocalizedStringKey { LocalizedStringKey(self) }

    /// Converts a localization key to its localized string value
    /// for use in TextField bindings - uses app's current language
    var localizedString: String {
        let currentLanguage = LanguageManager.shared.currentLanguageCode
        return localizedString(for: currentLanguage)
    }

    /// Converts a localization key to its localized string value for a specific language
    private func localizedString(for languageCode: String) -> String {
        // Use the matching .lproj bundle for any supported language; unknown codes fall back to English.
        let bundleLanguageCode = LanguageManager.resolve(languageCode)

        guard let path = Bundle.main.path(forResource: bundleLanguageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // For English variants or when bundle not found, return the key itself as default value
            if languageCode.hasPrefix("en") {
                return self
            }
            // For other languages, fallback to NSLocalizedString
            return NSLocalizedString(self, comment: "")
        }

        let localizedValue = bundle.localizedString(forKey: self, value: nil, table: nil)

        // If localized value is the same as key (meaning no translation found), return key for English
        if localizedValue == self, languageCode.hasPrefix("en") {
            return self
        }

        return localizedValue
    }
}
